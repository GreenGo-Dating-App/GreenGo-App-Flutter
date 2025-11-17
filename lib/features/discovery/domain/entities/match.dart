/// Match Entity
///
/// Represents a mutual match between two users
class Match {
  final String matchId;
  final String userId1;
  final String userId2;
  final DateTime matchedAt;
  final bool isActive;
  final DateTime? lastMessageAt;
  final String? lastMessage;
  final int unreadCount;
  final bool user1Seen;
  final bool user2Seen;

  const Match({
    required this.matchId,
    required this.userId1,
    required this.userId2,
    required this.matchedAt,
    this.isActive = true,
    this.lastMessageAt,
    this.lastMessage,
    this.unreadCount = 0,
    this.user1Seen = false,
    this.user2Seen = false,
  });

  /// Get the other user's ID given the current user's ID
  String getOtherUserId(String currentUserId) {
    return currentUserId == userId1 ? userId2 : userId1;
  }

  /// Check if the current user has seen this match
  bool hasUserSeen(String currentUserId) {
    return currentUserId == userId1 ? user1Seen : user2Seen;
  }

  /// Check if this is a new match (not seen by current user)
  bool isNewMatch(String currentUserId) {
    return !hasUserSeen(currentUserId);
  }

  /// Get time since match
  Duration get timeSinceMatch => DateTime.now().difference(matchedAt);

  /// Get formatted time since match
  String get timeSinceMatchText {
    final duration = timeSinceMatch;
    if (duration.inMinutes < 1) return 'Just now';
    if (duration.inMinutes < 60) return '${duration.inMinutes}m ago';
    if (duration.inHours < 24) return '${duration.inHours}h ago';
    if (duration.inDays < 7) return '${duration.inDays}d ago';
    if (duration.inDays < 30) return '${(duration.inDays / 7).floor()}w ago';
    return '${(duration.inDays / 30).floor()}mo ago';
  }

  /// Copy with updated fields
  Match copyWith({
    String? matchId,
    bool? isActive,
    DateTime? lastMessageAt,
    String? lastMessage,
    int? unreadCount,
    bool? user1Seen,
    bool? user2Seen,
  }) {
    return Match(
      matchId: matchId ?? this.matchId,
      userId1: userId1,
      userId2: userId2,
      matchedAt: matchedAt,
      isActive: isActive ?? this.isActive,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      user1Seen: user1Seen ?? this.user1Seen,
      user2Seen: user2Seen ?? this.user2Seen,
    );
  }
}
