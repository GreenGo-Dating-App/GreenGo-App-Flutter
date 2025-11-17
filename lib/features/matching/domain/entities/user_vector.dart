/// User Vector Entity
///
/// Represents a user's profile as a feature vector for ML matching.
/// This is used by the matching algorithm to compute compatibility scores.
class UserVector {
  final String userId;
  final List<double> locationVector; // [latitude, longitude, normalized]
  final double ageNormalized; // Age normalized to 0-1 scale
  final List<double> interestVector; // One-hot encoded interests
  final List<double> personalityVector; // Big 5 personality traits
  final List<double> activityPatternVector; // Activity patterns (hourly distribution)
  final Map<String, double> additionalFeatures; // Extensible features

  const UserVector({
    required this.userId,
    required this.locationVector,
    required this.ageNormalized,
    required this.interestVector,
    required this.personalityVector,
    required this.activityPatternVector,
    this.additionalFeatures = const {},
  });

  /// Compute cosine similarity between two user vectors
  double cosineSimilarity(UserVector other) {
    final combined1 = _combineVectors();
    final combined2 = other._combineVectors();

    double dotProduct = 0.0;
    double magnitude1 = 0.0;
    double magnitude2 = 0.0;

    for (int i = 0; i < combined1.length && i < combined2.length; i++) {
      dotProduct += combined1[i] * combined2[i];
      magnitude1 += combined1[i] * combined1[i];
      magnitude2 += combined2[i] * combined2[i];
    }

    if (magnitude1 == 0 || magnitude2 == 0) return 0.0;

    return dotProduct / (magnitude1.sqrt() * magnitude2.sqrt());
  }

  /// Combine all feature vectors into a single vector
  List<double> _combineVectors() {
    return [
      ...locationVector,
      ageNormalized,
      ...interestVector,
      ...personalityVector,
      ...activityPatternVector,
      ...additionalFeatures.values,
    ];
  }

  /// Get the complete feature vector
  List<double> getFeatureVector() => _combineVectors();

  /// Get vector dimensions for debugging
  Map<String, int> getDimensions() {
    return {
      'location': locationVector.length,
      'age': 1,
      'interests': interestVector.length,
      'personality': personalityVector.length,
      'activityPattern': activityPatternVector.length,
      'additional': additionalFeatures.length,
      'total': _combineVectors().length,
    };
  }
}

/// Extension for math operations
extension on double {
  double sqrt() => this < 0 ? 0 : this > 0 ? (this as num).toDouble() : 0.0;
}
