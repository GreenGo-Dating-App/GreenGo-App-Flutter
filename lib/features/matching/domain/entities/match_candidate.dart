import '../../../profile/domain/entities/profile.dart';
import 'match_score.dart';

/// Match Candidate Entity
///
/// Represents a potential match for a user, including their profile
/// and compatibility score.
class MatchCandidate { // If this is a premium super-like suggestion

  const MatchCandidate({
    required this.profile,
    required this.matchScore,
    required this.distance,
    required this.suggestedAt,
    this.isSuperLike = false,
  });
  final Profile profile;
  final MatchScore matchScore;
  final double distance; // Distance in kilometers
  final DateTime suggestedAt;
  final bool isSuperLike;

  /// Whether distance is valid (both users have real locations)
  bool get hasValidDistance => distance > 0 || profile.location.latitude != 0.0 || profile.location.longitude != 0.0;

  // Distances to other people are shown as approximate buckets only:
  // core/utils/distance_bucket.dart `distanceLabel(l10n, distance)`.

  /// Get age from profile
  int get age => profile.age;

  /// Get display name
  String get displayName => profile.displayName;

  /// Get primary photo URL
  String? get primaryPhotoUrl =>
      profile.photoUrls.isNotEmpty ? profile.photoUrls.first : null;

  /// Check if this is a recommended match
  bool get isRecommended => matchScore.isHighQualityMatch;

  /// Get match quality
  MatchQuality get matchQuality => matchScore.quality;
}
