import '../../../profile/domain/entities/profile.dart';
import 'match_score.dart';

/// Match Candidate Entity
///
/// Represents a potential match for a user, including their profile
/// and compatibility score.
class MatchCandidate {
  final Profile profile;
  final MatchScore matchScore;
  final double distance; // Distance in kilometers
  final DateTime suggestedAt;
  final bool isSuperLike; // If this is a premium super-like suggestion

  const MatchCandidate({
    required this.profile,
    required this.matchScore,
    required this.distance,
    required this.suggestedAt,
    this.isSuperLike = false,
  });

  /// Get formatted distance string
  String get distanceText {
    if (distance < 1) {
      return '${(distance * 1000).toStringAsFixed(0)}m away';
    } else if (distance < 100) {
      return '${distance.toStringAsFixed(1)}km away';
    } else {
      return '${distance.toStringAsFixed(0)}km away';
    }
  }

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
