import '../../domain/entities/match_preferences.dart';
import '../../domain/entities/swipe_action.dart';
import '../../../membership/domain/entities/membership.dart';

/// Discovery Events
abstract class DiscoveryEvent {
  const DiscoveryEvent();
}

/// Load discovery stack
class DiscoveryStackLoadRequested extends DiscoveryEvent {
  final String userId;
  final MatchPreferences preferences;
  final int limit;

  const DiscoveryStackLoadRequested({
    required this.userId,
    required this.preferences,
    this.limit = 20,
  });
}

/// Record a swipe action
class DiscoverySwipeRecorded extends DiscoveryEvent {
  final String userId;
  final String targetUserId;
  final SwipeActionType actionType;
  final MembershipRules? membershipRules;
  final MembershipTier? membershipTier;

  const DiscoverySwipeRecorded({
    required this.userId,
    required this.targetUserId,
    required this.actionType,
    this.membershipRules,
    this.membershipTier,
  });
}

/// Record a swipe action from grid mode (does NOT advance currentIndex)
class DiscoveryGridSwipeRecorded extends DiscoveryEvent {
  final String userId;
  final String targetUserId;
  final SwipeActionType actionType;
  final MembershipRules? membershipRules;
  final MembershipTier? membershipTier;

  const DiscoveryGridSwipeRecorded({
    required this.userId,
    required this.targetUserId,
    required this.actionType,
    this.membershipRules,
    this.membershipTier,
  });
}

/// Refresh discovery stack
class DiscoveryStackRefreshRequested extends DiscoveryEvent {
  final String userId;
  final MatchPreferences preferences;

  const DiscoveryStackRefreshRequested({
    required this.userId,
    required this.preferences,
  });
}

/// Load more candidates
class DiscoveryMoreCandidatesRequested extends DiscoveryEvent {
  final String userId;
  final MatchPreferences preferences;

  const DiscoveryMoreCandidatesRequested({
    required this.userId,
    required this.preferences,
  });
}

/// Rewind (undo) the last swipe
class DiscoveryRewindRequested extends DiscoveryEvent {
  final String userId;
  final MembershipRules? membershipRules;
  final MembershipTier? membershipTier;

  const DiscoveryRewindRequested({
    required this.userId,
    this.membershipRules,
    this.membershipTier,
  });
}

/// Prefetch more profiles in background (triggered automatically when queue is low)
class DiscoveryPrefetchRequested extends DiscoveryEvent {
  final String userId;
  final MatchPreferences preferences;

  const DiscoveryPrefetchRequested({
    required this.userId,
    required this.preferences,
  });
}
