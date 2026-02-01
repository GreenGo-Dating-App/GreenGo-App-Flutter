import 'package:equatable/equatable.dart';

/// Second Chance Configuration
class SecondChanceConfig {
  /// Free second chances per day
  static const int freePerDay = 3;

  /// Cost for unlimited second chances (coins)
  static const int unlimitedCost = 50;

  /// How long a second chance profile stays available (hours)
  static const int availabilityHours = 48;
}

/// Second Chance Pool Entry
class SecondChanceEntry extends Equatable {
  final String id;
  final String userId;
  final String skippedUserId;
  final DateTime skippedAt;
  final DateTime availableUntil;
  final bool isUsed;
  final DateTime? usedAt;
  final SecondChanceAction? action;

  const SecondChanceEntry({
    required this.id,
    required this.userId,
    required this.skippedUserId,
    required this.skippedAt,
    required this.availableUntil,
    this.isUsed = false,
    this.usedAt,
    this.action,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        skippedUserId,
        skippedAt,
        availableUntil,
        isUsed,
        usedAt,
        action,
      ];

  /// Check if entry is still available
  bool get isAvailable => !isUsed && DateTime.now().isBefore(availableUntil);

  /// Time remaining until expiry
  Duration get timeRemaining {
    if (!isAvailable) return Duration.zero;
    return availableUntil.difference(DateTime.now());
  }

  /// Format time remaining
  String get formattedTimeRemaining {
    if (!isAvailable) return 'Expired';
    final hours = timeRemaining.inHours;
    if (hours > 24) {
      return '${timeRemaining.inDays}d ${hours % 24}h';
    }
    return '${hours}h ${timeRemaining.inMinutes % 60}m';
  }
}

/// Action taken on a second chance
enum SecondChanceAction {
  liked,
  passed,
  expired,
}

/// Second Chance Profile View
class SecondChanceProfile extends Equatable {
  final String odldid;
  final String name;
  final int age;
  final List<String> photos;
  final String? bio;
  final List<String> interests;
  final double? distance;
  final bool isVerified;
  final DateTime likedYouAt;
  final SecondChanceEntry entry;

  const SecondChanceProfile({
    required this.odldid,
    required this.name,
    required this.age,
    required this.photos,
    this.bio,
    this.interests = const [],
    this.distance,
    this.isVerified = false,
    required this.likedYouAt,
    required this.entry,
  });

  @override
  List<Object?> get props => [
        odldid,
        name,
        age,
        photos,
        bio,
        interests,
        distance,
        isVerified,
        likedYouAt,
        entry,
      ];

  /// Get primary photo
  String? get primaryPhoto => photos.isNotEmpty ? photos.first : null;

  /// Format "liked you" time
  String get likedYouAgo {
    final diff = DateTime.now().difference(likedYouAt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return 'Recently';
  }
}

/// Second Chance Action Result
class SecondChanceResult extends Equatable {
  final bool success;
  final bool isMatch;
  final String? matchId;
  final String? errorMessage;

  const SecondChanceResult({
    required this.success,
    this.isMatch = false,
    this.matchId,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [success, isMatch, matchId, errorMessage];
}

/// Daily Second Chance Usage
class SecondChanceUsage extends Equatable {
  final String odldid;
  final DateTime date;
  final int freeUsed;
  final bool hasUnlimited;
  final DateTime? unlimitedExpiresAt;

  const SecondChanceUsage({
    required this.odldid,
    required this.date,
    this.freeUsed = 0,
    this.hasUnlimited = false,
    this.unlimitedExpiresAt,
  });

  @override
  List<Object?> get props => [
        odldid,
        date,
        freeUsed,
        hasUnlimited,
        unlimitedExpiresAt,
      ];

  /// Free uses remaining today
  int get freeRemaining =>
      (SecondChanceConfig.freePerDay - freeUsed).clamp(0, SecondChanceConfig.freePerDay);

  /// Can use second chance
  bool get canUse => hasUnlimited || freeRemaining > 0;

  /// Is same day as today
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
