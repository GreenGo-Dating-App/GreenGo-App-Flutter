import 'package:equatable/equatable.dart';

/// Conversation Expiry Configuration
class ExpiryConfig {
  /// Default expiry duration in hours
  static const int defaultExpiryHours = 72;

  /// Extension duration in hours
  static const int extensionHours = 24;

  /// Cost to extend conversation (coins)
  static const int extensionCost = 25;

  /// Maximum extensions allowed
  static const int maxExtensions = 5;

  /// Warning threshold (hours before expiry)
  static const int warningThresholdHours = 12;
}

/// Conversation Expiry Entity
class ConversationExpiry extends Equatable {
  final String id;
  final String matchId;
  final String conversationId;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isExpired;
  final bool hasActivity;
  final int extensionCount;
  final DateTime? lastExtendedAt;
  final String? extendedByUserId;

  const ConversationExpiry({
    required this.id,
    required this.matchId,
    required this.conversationId,
    required this.createdAt,
    required this.expiresAt,
    this.isExpired = false,
    this.hasActivity = false,
    this.extensionCount = 0,
    this.lastExtendedAt,
    this.extendedByUserId,
  });

  @override
  List<Object?> get props => [
        id,
        matchId,
        conversationId,
        createdAt,
        expiresAt,
        isExpired,
        hasActivity,
        extensionCount,
        lastExtendedAt,
        extendedByUserId,
      ];

  /// Get time remaining until expiry
  Duration get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) return Duration.zero;
    return expiresAt.difference(now);
  }

  /// Get hours remaining
  int get hoursRemaining => timeRemaining.inHours;

  /// Get minutes remaining
  int get minutesRemaining => timeRemaining.inMinutes;

  /// Check if within warning threshold
  bool get isWarning =>
      hoursRemaining <= ExpiryConfig.warningThresholdHours && !isExpired;

  /// Check if critical (less than 1 hour)
  bool get isCritical => hoursRemaining < 1 && !isExpired;

  /// Check if can extend
  bool get canExtend => extensionCount < ExpiryConfig.maxExtensions && !isExpired;

  /// Get remaining extensions
  int get remainingExtensions =>
      ExpiryConfig.maxExtensions - extensionCount;

  /// Format time remaining as string
  String get formattedTimeRemaining {
    if (isExpired) return 'Expired';
    if (timeRemaining.inDays > 0) {
      return '${timeRemaining.inDays}d ${timeRemaining.inHours % 24}h';
    }
    if (timeRemaining.inHours > 0) {
      return '${timeRemaining.inHours}h ${timeRemaining.inMinutes % 60}m';
    }
    if (timeRemaining.inMinutes > 0) {
      return '${timeRemaining.inMinutes}m';
    }
    return 'Less than a minute';
  }

  /// Get progress (0.0 - 1.0, 1.0 = expired)
  double get expiryProgress {
    final totalDuration = expiresAt.difference(createdAt);
    final elapsed = DateTime.now().difference(createdAt);
    return (elapsed.inMilliseconds / totalDuration.inMilliseconds).clamp(0.0, 1.0);
  }

  /// Copy with extension
  ConversationExpiry copyWithExtension(String userId) {
    return ConversationExpiry(
      id: id,
      matchId: matchId,
      conversationId: conversationId,
      createdAt: createdAt,
      expiresAt: expiresAt.add(
        const Duration(hours: ExpiryConfig.extensionHours),
      ),
      isExpired: false,
      hasActivity: hasActivity,
      extensionCount: extensionCount + 1,
      lastExtendedAt: DateTime.now(),
      extendedByUserId: userId,
    );
  }
}

/// Expiry Status for UI
enum ExpiryStatus {
  active,    // Normal, plenty of time
  warning,   // Within warning threshold
  critical,  // Less than 1 hour
  expired,   // Conversation expired
}

extension ExpiryStatusExtension on ConversationExpiry {
  ExpiryStatus get status {
    if (isExpired) return ExpiryStatus.expired;
    if (isCritical) return ExpiryStatus.critical;
    if (isWarning) return ExpiryStatus.warning;
    return ExpiryStatus.active;
  }
}

/// Expiry Extension Result
class ExtensionResult extends Equatable {
  final bool success;
  final ConversationExpiry? expiry;
  final int? coinsSpent;
  final String? errorMessage;

  const ExtensionResult({
    required this.success,
    this.expiry,
    this.coinsSpent,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [success, expiry, coinsSpent, errorMessage];
}
