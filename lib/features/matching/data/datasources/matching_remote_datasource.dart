import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
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

  MatchingRemoteDataSourceImpl({
    required this.firestore,
    FeatureEngineer? featureEngineer,
    CompatibilityScorer? compatibilityScorer,
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

    // Fetch ALL profiles from Firestore (no server-side filters to avoid
    // composite index issues). All filtering is done in code for reliability.
    final querySnapshot = await firestore
        .collection('profiles')
        .get();

    final candidates = <MatchCandidate>[];
    final now = DateTime.now();

    for (final doc in querySnapshot.docs) {
      // Skip self
      if (doc.id == userId) continue;

      try {
        final candidateProfile = ProfileModel.fromFirestore(doc);

        // MANDATORY: Only show verified profiles
        if (!candidateProfile.isVerified) continue;

        // MANDATORY: Only show active profiles (skip suspended/banned/deleted)
        if (candidateProfile.accountStatus != 'active') continue;

        // Must have at least one photo
        if (candidateProfile.photoUrls.isEmpty) continue;

        // Apply age filter
        final age = candidateProfile.age;
        if (age > 0 && (age < preferences.minAge || age > preferences.maxAge)) {
          continue;
        }

        // Apply gender filter
        if (preferences.preferredGenders.isNotEmpty) {
          final gender = candidateProfile.gender;
          if (gender.isNotEmpty &&
              !preferences.preferredGenders
                  .map((g) => g.toLowerCase())
                  .contains(gender.toLowerCase())) {
            continue;
          }
        }

        // Apply distance filter (skip if either user has no location data)
        double distance = 0.0;
        if (userProfile.location.latitude != 0 &&
            userProfile.location.longitude != 0 &&
            candidateProfile.location.latitude != 0 &&
            candidateProfile.location.longitude != 0) {
          distance = featureEngineer.calculateDistance(
            userProfile.location.latitude,
            userProfile.location.longitude,
            candidateProfile.location.latitude,
            candidateProfile.location.longitude,
          );

          if (preferences.maxDistance < 1000 && distance > preferences.maxDistance) {
            continue;
          }
        }

        // Apply deal-breaker interests
        if (preferences.dealBreakerInterests.isNotEmpty) {
          final hasAllDealBreakers = preferences.dealBreakerInterests.every(
            (interest) => candidateProfile.interests.contains(interest),
          );
          if (!hasAllDealBreakers) continue;
        }

        // Calculate compatibility score
        MatchScore matchScore;
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

        candidates.add(MatchCandidate(
          profile: candidateProfile,
          matchScore: matchScore,
          distance: distance,
          suggestedAt: now,
          isSuperLike: matchScore.overallScore >= 80.0,
        ));
      } catch (e) {
        // Skip invalid profiles
        continue;
      }
    }

    // Shuffle candidates randomly so users see a different order each time
    candidates.shuffle(Random());

    // Return ALL candidates (no limit) for endless scrolling
    return candidates;
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

    // Update interaction counts (for collaborative filtering)
    await firestore.collection('interaction_matrix').doc(userId).set({
      targetUserId: {
        'type': interactionType.toString().split('.').last,
        'timestamp': FieldValue.serverTimestamp(),
      }
    }, SetOptions(merge: true));
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
