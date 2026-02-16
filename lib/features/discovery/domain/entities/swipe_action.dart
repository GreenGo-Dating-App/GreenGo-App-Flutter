/// Swipe Action Type
enum SwipeActionType {
  like,       // Swipe right
  pass,       // Swipe left (hidden for 90 days)
  superLike,  // Swipe up (premium feature)
  skip,       // Swipe down (queued for next session)
}

/// Swipe Action Entity
///
/// Represents a user's action on another user's profile
class SwipeAction {
  final String userId;
  final String targetUserId;
  final SwipeActionType actionType;
  final DateTime timestamp;
  final bool createdMatch;

  const SwipeAction({
    required this.userId,
    required this.targetUserId,
    required this.actionType,
    required this.timestamp,
    this.createdMatch = false,
  });

  /// Check if this is a positive action (like or super like)
  bool get isPositive =>
      actionType == SwipeActionType.like ||
      actionType == SwipeActionType.superLike;

  /// Check if this is a super like
  bool get isSuperLike => actionType == SwipeActionType.superLike;

  /// Get action type as string
  String get actionTypeString {
    switch (actionType) {
      case SwipeActionType.like:
        return 'like';
      case SwipeActionType.pass:
        return 'pass';
      case SwipeActionType.superLike:
        return 'superLike';
      case SwipeActionType.skip:
        return 'skip';
    }
  }
}
