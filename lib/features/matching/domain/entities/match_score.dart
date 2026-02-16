/// Match Score Entity
///
/// Represents the compatibility score between two users.
/// Includes overall score and breakdown by different factors.
class MatchScore {
  final String userId1;
  final String userId2;
  final double overallScore; // 0-100%
  final ScoreBreakdown breakdown;
  final DateTime calculatedAt;

  const MatchScore({
    required this.userId1,
    required this.userId2,
    required this.overallScore,
    required this.breakdown,
    required this.calculatedAt,
  });

  /// Check if this is a high-quality match (>70%)
  bool get isHighQualityMatch => overallScore >= 70.0;

  /// Check if this is a good match (>50%)
  bool get isGoodMatch => overallScore >= 50.0;

  /// Get match quality category
  MatchQuality get quality {
    if (overallScore >= 80.0) return MatchQuality.excellent;
    if (overallScore >= 70.0) return MatchQuality.great;
    if (overallScore >= 50.0) return MatchQuality.good;
    if (overallScore >= 30.0) return MatchQuality.fair;
    return MatchQuality.poor;
  }

  /// Get human-readable match percentage
  String get matchPercentageText => '${overallScore.toStringAsFixed(0)}%';
}

/// Detailed breakdown of match score components
class ScoreBreakdown {
  final double locationScore; // 0-100
  final double ageCompatibilityScore; // 0-100
  final double interestOverlapScore; // 0-100
  final double languageScore; // 0-100
  final Map<String, double> additionalScores; // Extensible

  const ScoreBreakdown({
    required this.locationScore,
    required this.ageCompatibilityScore,
    required this.interestOverlapScore,
    this.languageScore = 0.0,
    // Keep old params for backward compat but ignore them
    double personalityCompatibilityScore = 0.0,
    double activityPatternScore = 0.0,
    double collaborativeFilteringScore = 0.0,
    this.additionalScores = const {},
  });

  /// Get the top 3 compatibility factors
  List<CompatibilityFactor> getTopFactors() {
    final factors = [
      CompatibilityFactor('Distance', locationScore),
      CompatibilityFactor('Age', ageCompatibilityScore),
      CompatibilityFactor('Passions', interestOverlapScore),
      CompatibilityFactor('Languages', languageScore),
      ...additionalScores.entries
          .map((e) => CompatibilityFactor(e.key, e.value)),
    ];

    factors.sort((a, b) => b.score.compareTo(a.score));
    return factors.take(3).toList();
  }

  /// Get weighted average score (4 factors)
  double getWeightedScore({
    double locationWeight = 0.25,
    double ageWeight = 0.25,
    double interestWeight = 0.30,
    double languageWeight = 0.20,
  }) {
    return (locationScore * locationWeight) +
        (ageCompatibilityScore * ageWeight) +
        (interestOverlapScore * interestWeight) +
        (languageScore * languageWeight);
  }
}

/// Individual compatibility factor
class CompatibilityFactor {
  final String name;
  final double score;

  const CompatibilityFactor(this.name, this.score);

  String get scoreText => '${score.toStringAsFixed(0)}%';
}

/// Match quality categories
enum MatchQuality {
  excellent, // 80-100%
  great, // 70-79%
  good, // 50-69%
  fair, // 30-49%
  poor, // 0-29%
}
