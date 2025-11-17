import 'dart:math' as math;
import '../../../profile/domain/entities/profile.dart';
import '../entities/user_vector.dart';

/// Feature Engineer
///
/// Transforms user profiles into feature vectors for ML matching.
/// Implements feature engineering extracting user vectors from:
/// - Location (latitude/longitude + geohashing)
/// - Age (normalized)
/// - Interests (one-hot encoding)
/// - Personality traits (Big 5)
/// - Activity patterns (placeholder for future implementation)
class FeatureEngineer {
  // Standard interest vocabulary (must match across all users)
  static const List<String> INTEREST_VOCABULARY = [
    'Travel', 'Photography', 'Music', 'Fitness', 'Cooking',
    'Reading', 'Movies', 'Gaming', 'Art', 'Dance',
    'Yoga', 'Hiking', 'Swimming', 'Cycling', 'Running',
    'Sports', 'Fashion', 'Technology', 'Writing', 'Coffee',
    'Wine', 'Beer', 'Food', 'Vegetarian', 'Vegan',
    'Pets', 'Dogs', 'Cats', 'Nature', 'Beach',
    'Mountains', 'Camping', 'Surfing', 'Skiing', 'Snowboarding',
    'Meditation', 'Spirituality', 'Volunteering', 'Environment', 'Politics',
    'Science', 'History', 'Languages', 'Teaching',
  ];

  /// Create user vector from profile
  UserVector createVector(Profile profile) {
    return UserVector(
      userId: profile.userId,
      locationVector: _extractLocationVector(profile),
      ageNormalized: _normalizeAge(profile.age),
      interestVector: _extractInterestVector(profile.interests),
      personalityVector: _extractPersonalityVector(profile.personalityTraits),
      activityPatternVector: _extractActivityPatternVector(profile),
      additionalFeatures: _extractAdditionalFeatures(profile),
    );
  }

  /// Extract location vector [lat_normalized, lon_normalized, geohash_features]
  List<double> _extractLocationVector(Profile profile) {
    final lat = profile.location.latitude;
    final lon = profile.location.longitude;

    // Normalize latitude (-90 to 90) and longitude (-180 to 180) to 0-1
    final latNorm = (lat + 90) / 180;
    final lonNorm = (lon + 180) / 360;

    // Geohash-like features (divide world into grid cells)
    final latCell = (latNorm * 10).floor() / 10;
    final lonCell = (lonNorm * 10).floor() / 10;

    return [latNorm, lonNorm, latCell, lonCell];
  }

  /// Normalize age to 0-1 scale (18-100 years)
  double _normalizeAge(int age) {
    const minAge = 18;
    const maxAge = 100;
    return ((age - minAge) / (maxAge - minAge)).clamp(0.0, 1.0);
  }

  /// Extract interest vector using one-hot encoding
  /// Returns a binary vector of length INTEREST_VOCABULARY.length
  List<double> _extractInterestVector(List<String> userInterests) {
    return INTEREST_VOCABULARY.map((interest) {
      return userInterests.contains(interest) ? 1.0 : 0.0;
    }).toList();
  }

  /// Extract personality vector from Big 5 traits
  /// Normalize each trait (1-5) to 0-1 scale
  List<double> _extractPersonalityVector(dynamic personalityTraits) {
    if (personalityTraits == null) {
      return List.filled(5, 0.5); // Default to neutral
    }

    return [
      (personalityTraits.openness - 1) / 4,
      (personalityTraits.conscientiousness - 1) / 4,
      (personalityTraits.extraversion - 1) / 4,
      (personalityTraits.agreeableness - 1) / 4,
      (personalityTraits.neuroticism - 1) / 4,
    ];
  }

  /// Extract activity pattern vector
  /// TODO: In production, this would analyze:
  /// - Peak usage hours (hourly distribution 0-23)
  /// - Days of week active
  /// - Average session length
  /// - Response time patterns
  ///
  /// For now, returns placeholder uniform distribution
  List<double> _extractActivityPatternVector(Profile profile) {
    // 24-hour distribution (placeholder)
    // In production: query user activity logs and create hourly histogram
    return List.filled(24, 1.0 / 24);
  }

  /// Extract additional features
  Map<String, double> _extractAdditionalFeatures(Profile profile) {
    return {
      'hasVoiceRecording': profile.voiceRecordingUrl != null ? 1.0 : 0.0,
      'photoCount': (profile.photoUrls.length / 6).clamp(0.0, 1.0),
      'bioLength': (profile.bio.length / 500).clamp(0.0, 1.0),
      'languageCount': (profile.languages.length / 5).clamp(0.0, 1.0),
      'profileCompleteness': profile.isComplete ? 1.0 : 0.5,
    };
  }

  /// Calculate Haversine distance between two locations (in km)
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final lat1Rad = _degreesToRadians(lat1);
    final lat2Rad = _degreesToRadians(lat2);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.sin(dLon / 2) *
            math.sin(dLon / 2) *
            math.cos(lat1Rad) *
            math.cos(lat2Rad);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  /// Calculate interest overlap percentage
  double calculateInterestOverlap(List<String> interests1, List<String> interests2) {
    if (interests1.isEmpty && interests2.isEmpty) return 0.0;
    if (interests1.isEmpty || interests2.isEmpty) return 0.0;

    final set1 = interests1.toSet();
    final set2 = interests2.toSet();

    final intersection = set1.intersection(set2).length;
    final union = set1.union(set2).length;

    // Jaccard similarity
    return (intersection / union) * 100;
  }

  /// Calculate age compatibility score
  double calculateAgeCompatibility(int age1, int age2) {
    final ageDiff = (age1 - age2).abs();

    if (ageDiff == 0) return 100.0;
    if (ageDiff <= 2) return 95.0;
    if (ageDiff <= 5) return 80.0;
    if (ageDiff <= 10) return 60.0;
    if (ageDiff <= 15) return 40.0;
    if (ageDiff <= 20) return 20.0;

    return 0.0;
  }

  /// Calculate personality compatibility using Big 5 similarity
  double calculatePersonalityCompatibility(
    dynamic traits1,
    dynamic traits2,
  ) {
    if (traits1 == null || traits2 == null) return 50.0; // Neutral

    // Calculate Euclidean distance between personality vectors
    final diff1 = (traits1.openness - traits2.openness).abs();
    final diff2 = (traits1.conscientiousness - traits2.conscientiousness).abs();
    final diff3 = (traits1.extraversion - traits2.extraversion).abs();
    final diff4 = (traits1.agreeableness - traits2.agreeableness).abs();
    final diff5 = (traits1.neuroticism - traits2.neuroticism).abs();

    final totalDiff = diff1 + diff2 + diff3 + diff4 + diff5;
    final maxDiff = 5 * 4; // Maximum possible difference

    // Convert to similarity score (0-100)
    return ((maxDiff - totalDiff) / maxDiff) * 100;
  }
}
