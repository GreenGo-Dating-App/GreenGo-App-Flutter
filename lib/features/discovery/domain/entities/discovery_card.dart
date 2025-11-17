import '../../../matching/domain/entities/match_candidate.dart';

/// Discovery Card Entity
///
/// Represents a profile card in the discovery stack
class DiscoveryCard {
  final MatchCandidate candidate;
  final int position; // Position in the stack
  final bool isFocused; // Currently visible card

  const DiscoveryCard({
    required this.candidate,
    required this.position,
    this.isFocused = false,
  });

  /// Get profile from candidate
  String get userId => candidate.profile.userId;
  String get displayName => candidate.profile.displayName;
  int get age => candidate.age;
  String? get primaryPhoto => candidate.primaryPhotoUrl;
  String get distanceText => candidate.distanceText;
  String get matchPercentage => candidate.matchScore.matchPercentageText;
  bool get isRecommended => candidate.isRecommended;

  /// Get bio preview (first 100 characters)
  String get bioPreview {
    final bio = candidate.profile.bio;
    if (bio.length <= 100) return bio;
    return '${bio.substring(0, 100)}...';
  }

  /// Copy with updated fields
  DiscoveryCard copyWith({
    int? position,
    bool? isFocused,
  }) {
    return DiscoveryCard(
      candidate: candidate,
      position: position ?? this.position,
      isFocused: isFocused ?? this.isFocused,
    );
  }
}
