import '../../../profile/domain/entities/profile.dart';
import '../entities/match_score.dart';
import '../entities/user_vector.dart';
import 'feature_engineer.dart';

/// Compatibility Scorer
///
/// Implements compatibility scoring system (0-100%) based on multiple weighted factors:
/// - Location proximity (20%)
/// - Age compatibility (15%)
/// - Interest overlap (25%)
/// - Personality compatibility (20%)
/// - Activity pattern alignment (10%)
/// - Collaborative filtering score (10%)
class CompatibilityScorer {
  final FeatureEngineer _featureEngineer;

  // Scoring weights (must sum to 1.0)
  static const double LOCATION_WEIGHT = 0.20;
  static const double AGE_WEIGHT = 0.15;
  static const double INTEREST_WEIGHT = 0.25;
  static const double PERSONALITY_WEIGHT = 0.20;
  static const double ACTIVITY_WEIGHT = 0.10;
  static const double COLLABORATIVE_WEIGHT = 0.10;

  CompatibilityScorer({FeatureEngineer? featureEngineer})
      : _featureEngineer = featureEngineer ?? FeatureEngineer();

  /// Calculate comprehensive compatibility score between two profiles
  MatchScore calculateScore({
    required Profile profile1,
    required Profile profile2,
    double collaborativeScore = 50.0, // From collaborative filtering
  }) {
    // Calculate individual component scores
    final locationScore = _calculateLocationScore(profile1, profile2);
    final ageScore = _calculateAgeScore(profile1, profile2);
    final interestScore = _calculateInterestScore(profile1, profile2);
    final personalityScore = _calculatePersonalityScore(profile1, profile2);
    final activityScore = _calculateActivityScore(profile1, profile2);

    // Create score breakdown
    final breakdown = ScoreBreakdown(
      locationScore: locationScore,
      ageCompatibilityScore: ageScore,
      interestOverlapScore: interestScore,
      personalityCompatibilityScore: personalityScore,
      activityPatternScore: activityScore,
      collaborativeFilteringScore: collaborativeScore,
    );

    // Calculate weighted overall score
    final overallScore = _calculateWeightedScore(
      locationScore: locationScore,
      ageScore: ageScore,
      interestScore: interestScore,
      personalityScore: personalityScore,
      activityScore: activityScore,
      collaborativeScore: collaborativeScore,
    );

    return MatchScore(
      userId1: profile1.userId,
      userId2: profile2.userId,
      overallScore: overallScore,
      breakdown: breakdown,
      calculatedAt: DateTime.now(),
    );
  }

  /// Calculate location-based score with bonus for proximity
  double _calculateLocationScore(Profile profile1, Profile profile2) {
    final distance = _featureEngineer.calculateDistance(
      profile1.location.latitude,
      profile1.location.longitude,
      profile2.location.latitude,
      profile2.location.longitude,
    );

    // Score based on distance with diminishing returns
    if (distance < 1) return 100.0; // Same location
    if (distance < 5) return 95.0; // Very close
    if (distance < 10) return 85.0; // Close
    if (distance < 25) return 75.0; // Nearby
    if (distance < 50) return 60.0; // Same city
    if (distance < 100) return 40.0; // Same region
    if (distance < 250) return 20.0; // Far

    return 5.0; // Very far
  }

  /// Calculate age compatibility score
  double _calculateAgeScore(Profile profile1, Profile profile2) {
    return _featureEngineer.calculateAgeCompatibility(
      profile1.age,
      profile2.age,
    );
  }

  /// Calculate interest overlap score with bonus for rare interests
  double _calculateInterestScore(Profile profile1, Profile profile2) {
    final overlap = _featureEngineer.calculateInterestOverlap(
      profile1.interests,
      profile2.interests,
    );

    // Bonus for rare/specific shared interests
    final sharedInterests = profile1.interests
        .toSet()
        .intersection(profile2.interests.toSet());

    // Add bonus points for niche interests (weighted higher)
    final nicheInterests = [
      'Volunteering', 'Environment', 'Meditation', 'Spirituality',
      'Surfing', 'Skiing', 'Snowboarding', 'Languages', 'Teaching'
    ];

    double bonus = 0.0;
    for (final interest in sharedInterests) {
      if (nicheInterests.contains(interest)) {
        bonus += 5.0; // +5% for each shared niche interest
      }
    }

    return (overlap + bonus).clamp(0.0, 100.0);
  }

  /// Calculate personality compatibility score
  double _calculatePersonalityScore(Profile profile1, Profile profile2) {
    return _featureEngineer.calculatePersonalityCompatibility(
      profile1.personalityTraits,
      profile2.personalityTraits,
    );
  }

  /// Calculate activity pattern alignment score
  /// TODO: In production, analyze:
  /// - Peak usage time overlap
  /// - Response time similarity
  /// - Session length patterns
  double _calculateActivityScore(Profile profile1, Profile profile2) {
    // Placeholder: Return neutral score
    // In production: analyze activity logs for synchronous connection potential

    // For now, give bonus if both have voice recordings (shows engagement)
    final bothHaveVoice = profile1.voiceRecordingUrl != null &&
        profile2.voiceRecordingUrl != null;

    // Both have completed profiles
    final bothComplete = profile1.isComplete && profile2.isComplete;

    double score = 50.0; // Base score
    if (bothHaveVoice) score += 25.0;
    if (bothComplete) score += 25.0;

    return score.clamp(0.0, 100.0);
  }

  /// Calculate weighted overall score
  double _calculateWeightedScore({
    required double locationScore,
    required double ageScore,
    required double interestScore,
    required double personalityScore,
    required double activityScore,
    required double collaborativeScore,
  }) {
    return (locationScore * LOCATION_WEIGHT) +
        (ageScore * AGE_WEIGHT) +
        (interestScore * INTEREST_WEIGHT) +
        (personalityScore * PERSONALITY_WEIGHT) +
        (activityScore * ACTIVITY_WEIGHT) +
        (collaborativeScore * COLLABORATIVE_WEIGHT);
  }

  /// Calculate score using user vectors (ML-based approach)
  MatchScore calculateScoreFromVectors({
    required UserVector vector1,
    required UserVector vector2,
    required Profile profile1,
    required Profile profile2,
    double collaborativeScore = 50.0,
  }) {
    // Use cosine similarity for overall vector similarity
    final vectorSimilarity = vector1.cosineSimilarity(vector2);
    final vectorScore = vectorSimilarity * 100;

    // Calculate component scores
    final locationScore = _calculateLocationScore(profile1, profile2);
    final ageScore = _calculateAgeScore(profile1, profile2);
    final interestScore = _calculateInterestScore(profile1, profile2);
    final personalityScore = _calculatePersonalityScore(profile1, profile2);
    final activityScore = _calculateActivityScore(profile1, profile2);

    final breakdown = ScoreBreakdown(
      locationScore: locationScore,
      ageCompatibilityScore: ageScore,
      interestOverlapScore: interestScore,
      personalityCompatibilityScore: personalityScore,
      activityPatternScore: activityScore,
      collaborativeFilteringScore: collaborativeScore,
      additionalScores: {
        'VectorSimilarity': vectorScore,
      },
    );

    // Hybrid: Combine weighted score with vector similarity
    final weightedScore = _calculateWeightedScore(
      locationScore: locationScore,
      ageScore: ageScore,
      interestScore: interestScore,
      personalityScore: personalityScore,
      activityScore: activityScore,
      collaborativeScore: collaborativeScore,
    );

    // 70% weighted, 30% ML vector similarity
    final overallScore = (weightedScore * 0.7) + (vectorScore * 0.3);

    return MatchScore(
      userId1: profile1.userId,
      userId2: profile2.userId,
      overallScore: overallScore,
      breakdown: breakdown,
      calculatedAt: DateTime.now(),
    );
  }
}
