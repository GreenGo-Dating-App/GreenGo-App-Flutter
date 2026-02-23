import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/candidate_pool_service.dart';
import '../../../profile/data/models/profile_model.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../domain/entities/match_candidate.dart';
import '../../domain/entities/match_preferences.dart';
import '../../domain/entities/match_score.dart';
import '../../domain/entities/user_vector.dart';
import '../../domain/repositories/matching_repository.dart';
import '../../domain/usecases/compatibility_scorer.dart';
import '../../domain/usecases/feature_engineer.dart';
import '../models/match_preferences_model.dart';
import '../models/user_vector_model.dart';

/// Matching Remote Data Source
///
/// Handles all Firestore operations for matching feature
abstract class MatchingRemoteDataSource {
  /// Get potential matches for a user
  Future<List<MatchCandidate>> getMatchCandidates({
    required String userId,
    required MatchPreferences preferences,
    int limit = 20,
  });

  /// Get user vector from Firestore
  Future<UserVector> getUserVector(String userId);

  /// Save user vector to Firestore
  Future<void> saveUserVector(UserVector vector);

  /// Get match preferences
  Future<MatchPreferences> getMatchPreferences(String userId);

  /// Save match preferences
  Future<void> saveMatchPreferences(MatchPreferences preferences);

  /// Record user interaction
  Future<void> recordInteraction({
    required String userId,
    required String targetUserId,
    required InteractionType interactionType,
  });

  /// Get collaborative filtering score
  Future<double> getCollaborativeScore(String userId, String targetUserId);
}

/// Implementation of Matching Remote Data Source
class MatchingRemoteDataSourceImpl implements MatchingRemoteDataSource {
  final FirebaseFirestore firestore;
  final FeatureEngineer featureEngineer;
  final CompatibilityScorer compatibilityScorer;
  final CandidatePoolService? candidatePoolService;

  MatchingRemoteDataSourceImpl({
    required this.firestore,
    FeatureEngineer? featureEngineer,
    CompatibilityScorer? compatibilityScorer,
    this.candidatePoolService,
  })  : featureEngineer = featureEngineer ?? FeatureEngineer(),
        compatibilityScorer = compatibilityScorer ?? CompatibilityScorer();

  @override
  Future<List<MatchCandidate>> getMatchCandidates({
    required String userId,
    required MatchPreferences preferences,
    int limit = 20,
  }) async {
    // Get current user's profile
    final userDoc = await firestore.collection('profiles').doc(userId).get();
    if (!userDoc.exists) throw Exception('User profile not found');

    final userProfile = ProfileModel.fromFirestore(userDoc);
    final userLoc = userProfile.effectiveLocation;
    final isCurrentUserAdmin = userProfile.isAdmin || userProfile.isSupport;

    // Try pre-computed pools first for targeted candidate fetch
    final poolCandidateIds = await _getPoolCandidateIds(
      userProfile: userProfile,
      preferences: preferences,
    );

    List<QueryDocumentSnapshot<Map<String, dynamic>>> profileDocs;

    if (poolCandidateIds != null && poolCandidateIds.isNotEmpty) {
      // Pool path: fetch only the profiles we know match the criteria
      debugPrint('[Matching] Using pool: ${poolCandidateIds.length} candidate IDs');
      profileDocs = await _fetchProfilesByIds(poolCandidateIds);
    } else {
      // Fallback: full scan (pools unavailable, stale, or empty)
      debugPrint('[Matching] Pool unavailable, falling back to full scan');
      final querySnapshot = await firestore
          .collection('profiles')
          .limit(500)
          .get();
      profileDocs = querySnapshot.docs;
    }

    final candidates = <MatchCandidate>[];
    final now = DateTime.now();

    for (final doc in profileDocs) {
      // Skip self
      if (doc.id == userId) continue;

      try {
        final candidateProfile = ProfileModel.fromFirestore(doc);

        // Skip explicitly suspended/banned/deleted profiles
        final status = candidateProfile.accountStatus.toLowerCase();
        if (status == 'suspended' || status == 'banned' || status == 'deleted') {
          continue;
        }

        // Admin/support profiles bypass all filters — always visible
        final isPrivileged = candidateProfile.isAdmin || candidateProfile.isSupport;

        // Admin users see ALL profiles (bypass verification, photo, age, gender, distance filters)
        if (isCurrentUserAdmin) {
          // Admin sees everyone — skip all filters
        } else {
          // Verification filter: only show verified profiles (skip for admin/support candidates)
          if (!isPrivileged && !candidateProfile.isVerified) continue;

          // Must have at least one photo (skip for admin/support candidates)
          if (!isPrivileged && candidateProfile.photoUrls.isEmpty) continue;

          // Apply age filter (skip for admin/support candidates)
          final age = candidateProfile.age;
          if (!isPrivileged && age > 0 && (age < preferences.minAge || age > preferences.maxAge)) {
            continue;
          }

          // Apply gender filter (skip for admin/support candidates)
          if (!isPrivileged && preferences.preferredGenders.isNotEmpty) {
            final gender = candidateProfile.gender;
            if (gender.isNotEmpty &&
                !preferences.preferredGenders
                    .map((g) => g.toLowerCase())
                    .contains(gender.toLowerCase())) {
              continue;
            }
          }
        }

        // Apply distance filter (skip for admin/support candidates and admin users)
        final candidateLoc = candidateProfile.effectiveLocation;
        double distance = 0.0;
        if (!isPrivileged && !isCurrentUserAdmin &&
            userLoc.latitude != 0 &&
            userLoc.longitude != 0 &&
            candidateLoc.latitude != 0 &&
            candidateLoc.longitude != 0) {
          distance = featureEngineer.calculateDistance(
            userLoc.latitude,
            userLoc.longitude,
            candidateLoc.latitude,
            candidateLoc.longitude,
          );

          if (distance > preferences.maxDistance) {
            continue;
          }
        }

        // Apply deal-breaker interests (skip for admin/support and admin users)
        if (!isPrivileged && !isCurrentUserAdmin && preferences.dealBreakerInterests.isNotEmpty) {
          final hasAllDealBreakers = preferences.dealBreakerInterests.every(
            (interest) => candidateProfile.interests.contains(interest),
          );
          if (!hasAllDealBreakers) continue;
        }

        // Calculate compatibility score
        // Admin/support candidates always show 100% compatibility
        MatchScore matchScore;
        if (isPrivileged) {
          matchScore = MatchScore(
            userId1: userId,
            userId2: candidateProfile.userId,
            overallScore: 100.0,
            breakdown: const ScoreBreakdown(
              locationScore: 100.0,
              ageCompatibilityScore: 100.0,
              interestOverlapScore: 100.0,
              languageScore: 100.0,
            ),
            calculatedAt: now,
          );
        } else {
          try {
            matchScore = compatibilityScorer.calculateScore(
              profile1: userProfile,
              profile2: candidateProfile,
            );
          } catch (_) {
            // If scoring fails, use a default neutral score
            matchScore = MatchScore(
              userId1: userId,
              userId2: candidateProfile.userId,
              overallScore: 50.0,
              breakdown: const ScoreBreakdown(
                locationScore: 50.0,
                ageCompatibilityScore: 50.0,
                interestOverlapScore: 50.0,
                languageScore: 50.0,
              ),
              calculatedAt: now,
            );
          }
        }

        candidates.add(MatchCandidate(
          profile: candidateProfile,
          matchScore: matchScore,
          distance: distance,
          suggestedAt: now,
          isSuperLike: matchScore.overallScore >= 80.0,
        ));
      } catch (e) {
        print('[Discovery] Error parsing profile ${doc.id}: $e');
        continue;
      }
    }

    print('[Discovery] Final candidate count: ${candidates.length}');

    // Shuffle candidates randomly so users see a different order each time
    candidates.shuffle(Random());

    // Return ALL candidates (no limit) for endless scrolling
    return candidates;
  }

  /// Try to get candidate user IDs from pre-computed pools.
  /// Returns null if pools are unavailable or stale.
  Future<List<String>?> _getPoolCandidateIds({
    required Profile userProfile,
    required MatchPreferences preferences,
  }) async {
    if (candidatePoolService == null) return null;

    try {
      final country = userProfile.effectiveLocation.country;
      if (country.isEmpty || country == 'Unknown') return null;

      final poolCandidates = await candidatePoolService!.getCandidatesFromPools(
        country: country,
        genders: preferences.preferredGenders,
        minAge: preferences.minAge,
        maxAge: preferences.maxAge,
      );

      if (poolCandidates == null || poolCandidates.isEmpty) return null;

      // Pre-filter by distance using pool metadata (avoids fetching distant profiles)
      final userLoc = userProfile.effectiveLocation;
      final filtered = <String>[];

      for (final pc in poolCandidates) {
        // Skip candidates with no location
        if (pc.lat == 0 && pc.lng == 0) {
          filtered.add(pc.userId);
          continue;
        }
        // Skip if user has no location
        if (userLoc.latitude == 0 && userLoc.longitude == 0) {
          filtered.add(pc.userId);
          continue;
        }

        final distance = featureEngineer.calculateDistance(
          userLoc.latitude,
          userLoc.longitude,
          pc.lat,
          pc.lng,
        );

        if (distance <= preferences.maxDistance) {
          filtered.add(pc.userId);
        }
      }

      debugPrint('[Matching] Pool pre-filter: ${poolCandidates.length} → ${filtered.length} (distance)');
      return filtered.isEmpty ? null : filtered;
    } catch (e) {
      debugPrint('[Matching] Pool lookup failed, falling back: $e');
      return null;
    }
  }

  /// Fetch profile documents by a list of user IDs in parallel batches of 10.
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _fetchProfilesByIds(
    List<String> userIds,
  ) async {
    if (userIds.isEmpty) return [];

    // Cap at 500 to match previous behavior
    final idsToFetch = userIds.length > 500 ? userIds.sublist(0, 500) : userIds;

    final futures = <Future<QuerySnapshot<Map<String, dynamic>>>>[];
    for (var i = 0; i < idsToFetch.length; i += 10) {
      final batch = idsToFetch.sublist(
        i,
        i + 10 > idsToFetch.length ? idsToFetch.length : i + 10,
      );
      futures.add(
        firestore
            .collection('profiles')
            .where(FieldPath.documentId, whereIn: batch)
            .get(),
      );
    }

    final results = await Future.wait(futures);
    return results.expand((snapshot) => snapshot.docs).toList();
  }

  @override
  Future<UserVector> getUserVector(String userId) async {
    final doc = await firestore.collection('user_vectors').doc(userId).get();

    if (!doc.exists) {
      throw Exception('User vector not found for user: $userId');
    }

    return UserVectorModel.fromFirestore(doc);
  }

  @override
  Future<void> saveUserVector(UserVector vector) async {
    final model = UserVectorModel.fromEntity(vector);
    await firestore
        .collection('user_vectors')
        .doc(vector.userId)
        .set(model.toFirestore());
  }

  @override
  Future<MatchPreferences> getMatchPreferences(String userId) async {
    final doc =
        await firestore.collection('match_preferences').doc(userId).get();

    if (!doc.exists) {
      // Return default preferences
      return MatchPreferences.defaultFor(userId);
    }

    return MatchPreferencesModel.fromFirestore(doc);
  }

  @override
  Future<void> saveMatchPreferences(MatchPreferences preferences) async {
    final model = MatchPreferencesModel.fromEntity(preferences);
    await firestore
        .collection('match_preferences')
        .doc(preferences.userId)
        .set(model.toFirestore());
  }

  @override
  Future<void> recordInteraction({
    required String userId,
    required String targetUserId,
    required InteractionType interactionType,
  }) async {
    await firestore.collection('user_interactions').add({
      'userId': userId,
      'targetUserId': targetUserId,
      'interactionType': interactionType.toString().split('.').last,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<double> getCollaborativeScore(
    String userId,
    String targetUserId,
  ) async {
    // TODO: Implement actual collaborative filtering using:
    // 1. Matrix factorization (SVD)
    // 2. Item-based collaborative filtering
    // 3. User-based collaborative filtering
    //
    // For now, return placeholder score based on simple heuristics

    try {
      // Get interactions for current user
      final userInteractions = await firestore
          .collection('user_interactions')
          .where('userId', isEqualTo: userId)
          .limit(500)
          .get();

      if (userInteractions.docs.isEmpty) {
        return 50.0; // Neutral score for new users
      }

      // Count positive interactions
      int positiveCount = 0;
      for (final doc in userInteractions.docs) {
        final type = doc.data()['interactionType'] as String;
        if (type == 'like' || type == 'superLike' || type == 'match') {
          positiveCount++;
        }
      }

      // Simple heuristic: more positive interactions = higher base score
      final baseScore = (positiveCount / userInteractions.docs.length) * 100;

      return baseScore.clamp(0.0, 100.0);
    } catch (e) {
      return 50.0; // Default to neutral on error
    }
  }
}
