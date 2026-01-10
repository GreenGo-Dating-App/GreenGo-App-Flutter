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

    // Build Firestore query with filters
    Query query = firestore.collection('profiles');

    // Filter: Not self
    // Note: Firestore doesn't support != operator, so we'll filter in code

    // Filter: Age range
    final birthYearMin = DateTime.now().year - preferences.maxAge;
    final birthYearMax = DateTime.now().year - preferences.minAge;
    query = query
        .where('dateOfBirth',
            isGreaterThanOrEqualTo:
                Timestamp.fromDate(DateTime(birthYearMin, 1, 1)))
        .where('dateOfBirth',
            isLessThanOrEqualTo: Timestamp.fromDate(DateTime(birthYearMax, 12, 31)));

    // Filter: Gender preferences
    if (preferences.preferredGenders.isNotEmpty) {
      query = query.where('gender', whereIn: preferences.preferredGenders);
    }

    // Note: We filter by photos in code to avoid Firestore inequality filter limitation
    // Firestore doesn't allow inequality filters on multiple fields

    // Execute query with limit
    final querySnapshot = await query.limit(limit * 3).get(); // Get more for filtering

    final candidates = <MatchCandidate>[];

    for (final doc in querySnapshot.docs) {
      // Skip self
      if (doc.id == userId) continue;

      // Filter: Only with photos if required (done in code to avoid Firestore limitation)
      final photoUrls = doc.data() is Map ? (doc.data() as Map)['photoUrls'] as List? : null;
      if (preferences.showOnlyWithPhotos && (photoUrls == null || photoUrls.isEmpty)) {
        continue;
      }

      try {
        final candidateProfile = ProfileModel.fromFirestore(doc);

        // Calculate distance
        final distance = featureEngineer.calculateDistance(
          userProfile.location.latitude,
          userProfile.location.longitude,
          candidateProfile.location.latitude,
          candidateProfile.location.longitude,
        );

        // Filter by distance
        if (distance > preferences.maxDistance) continue;

        // Check deal-breaker interests
        if (preferences.dealBreakerInterests.isNotEmpty) {
          final hasAllDealBreakers = preferences.dealBreakerInterests.every(
            (interest) => candidateProfile.interests.contains(interest),
          );
          if (!hasAllDealBreakers) continue;
        }

        // Get collaborative filtering score (placeholder for now)
        final collaborativeScore = await getCollaborativeScore(
          userId,
          candidateProfile.userId,
        );

        // Calculate compatibility score
        final matchScore = compatibilityScorer.calculateScore(
          profile1: userProfile,
          profile2: candidateProfile,
          collaborativeScore: collaborativeScore,
        );

        // Only include if score is reasonable (>30%)
        if (matchScore.overallScore < 30.0) continue;

        // Create match candidate
        final candidate = MatchCandidate(
          profile: candidateProfile,
          matchScore: matchScore,
          distance: distance,
          suggestedAt: DateTime.now(),
          isSuperLike: matchScore.overallScore >= 80.0,
        );

        candidates.add(candidate);

        // Stop if we have enough candidates
        if (candidates.length >= limit) break;
      } catch (e) {
        // Skip invalid profiles
        continue;
      }
    }

    // Sort by compatibility score (highest first)
    candidates.sort((a, b) => b.matchScore.overallScore
        .compareTo(a.matchScore.overallScore));

    return candidates.take(limit).toList();
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
