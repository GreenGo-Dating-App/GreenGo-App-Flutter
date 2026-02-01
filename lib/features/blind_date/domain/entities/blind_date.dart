import 'package:equatable/equatable.dart';

/// Blind Date Profile Entity
/// Match on personality first, reveal photos after threshold
class BlindDateProfile extends Equatable {
  final String id;
  final String odldid;
  final bool isActive;
  final bool photosRevealed;
  final int messageCount;
  final DateTime createdAt;
  final DateTime? revealedAt;

  const BlindDateProfile({
    required this.id,
    required this.odldid,
    this.isActive = true,
    this.photosRevealed = false,
    this.messageCount = 0,
    required this.createdAt,
    this.revealedAt,
  });

  @override
  List<Object?> get props => [
        id,
        odldid,
        isActive,
        photosRevealed,
        messageCount,
        createdAt,
        revealedAt,
      ];

  /// Check if reveal threshold is met
  bool get canReveal => messageCount >= BlindDateConfig.revealThreshold;

  /// Progress towards reveal (0.0 - 1.0)
  double get revealProgress =>
      (messageCount / BlindDateConfig.revealThreshold).clamp(0.0, 1.0);

  /// Messages remaining until reveal
  int get messagesUntilReveal =>
      (BlindDateConfig.revealThreshold - messageCount).clamp(0, BlindDateConfig.revealThreshold);
}

/// Blind Match - a match between two blind profiles
class BlindMatch extends Equatable {
  final String id;
  final String profile1Id;
  final String profile2Id;
  final String user1Id;
  final String user2Id;
  final int messageCount;
  final bool isRevealed;
  final DateTime matchedAt;
  final DateTime? revealedAt;
  final String? conversationId;

  const BlindMatch({
    required this.id,
    required this.profile1Id,
    required this.profile2Id,
    required this.user1Id,
    required this.user2Id,
    this.messageCount = 0,
    this.isRevealed = false,
    required this.matchedAt,
    this.revealedAt,
    this.conversationId,
  });

  @override
  List<Object?> get props => [
        id,
        profile1Id,
        profile2Id,
        user1Id,
        user2Id,
        messageCount,
        isRevealed,
        matchedAt,
        revealedAt,
        conversationId,
      ];

  /// Check if reveal threshold is met
  bool get canReveal => messageCount >= BlindDateConfig.revealThreshold;

  /// Progress towards reveal (0.0 - 1.0)
  double get revealProgress =>
      (messageCount / BlindDateConfig.revealThreshold).clamp(0.0, 1.0);

  /// Messages remaining until reveal
  int get messagesUntilReveal =>
      (BlindDateConfig.revealThreshold - messageCount).clamp(0, BlindDateConfig.revealThreshold);

  /// Get the other user's ID
  String getOtherUserId(String currentUserId) {
    return currentUserId == user1Id ? user2Id : user1Id;
  }
}

/// Blind Date Configuration
class BlindDateConfig {
  /// Number of messages before photo reveal
  static const int revealThreshold = 20;

  /// Cost for instant reveal (coins)
  static const int instantRevealCost = 100;

  /// Maximum active blind profiles per user
  static const int maxActiveProfiles = 1;

  /// Blind profile validity (days)
  static const int profileValidityDays = 30;
}

/// Blind Profile View Model (for UI display)
class BlindProfileView extends Equatable {
  final String odldid;
  final String displayName;
  final int age;
  final String? bio;
  final List<String> interests;
  final String? occupation;
  final String? education;
  final double? distance;
  final bool isVerified;

  // Photos are only shown after reveal
  final List<String>? photos;
  final bool isRevealed;

  const BlindProfileView({
    required this.odldid,
    required this.displayName,
    required this.age,
    this.bio,
    this.interests = const [],
    this.occupation,
    this.education,
    this.distance,
    this.isVerified = false,
    this.photos,
    this.isRevealed = false,
  });

  @override
  List<Object?> get props => [
        odldid,
        displayName,
        age,
        bio,
        interests,
        occupation,
        education,
        distance,
        isVerified,
        photos,
        isRevealed,
      ];

  /// Get visible photos (empty if not revealed)
  List<String> get visiblePhotos => isRevealed ? (photos ?? []) : [];

  /// Check if has photos available for reveal
  bool get hasPhotosToReveal => !isRevealed && (photos?.isNotEmpty ?? false);
}

/// Blind Date Like Result
enum BlindLikeResult {
  liked,
  matched,
  passed,
}

/// Reveal Type
enum RevealType {
  threshold, // Natural reveal after message threshold
  instant,   // Paid instant reveal
  mutual,    // Both users agreed to reveal
}
