import '../../../membership/domain/entities/membership.dart';
import '../../domain/entities/match_preferences.dart';
import '../../domain/entities/swipe_action.dart';

/// Discovery Events
abstract class DiscoveryEvent {
  const DiscoveryEvent();
}

/// Load discovery stack
class DiscoveryStackLoadRequested extends DiscoveryEvent {

  const DiscoveryStackLoadRequested({
    required this.userId,
    required this.preferences,
    this.limit = 20,
  });
  final String userId;
  final MatchPreferences preferences;
  final int limit;
}

/// Record a swipe action
class DiscoverySwipeRecorded extends DiscoveryEvent {

  const DiscoverySwipeRecorded({
    required this.userId,
    required this.targetUserId,
    required this.actionType,
    this.membershipRules,
    this.membershipTier,
  });
  final String userId;
  final String targetUserId;
  final SwipeActionType actionType;
  final MembershipRules? membershipRules;
  final MembershipTier? membershipTier;
}

/// Record a swipe action from grid mode (does NOT advance currentIndex)
class DiscoveryGridSwipeRecorded extends DiscoveryEvent {

  const DiscoveryGridSwipeRecorded({
    required this.userId,
    required this.targetUserId,
    required this.actionType,
    this.membershipRules,
    this.membershipTier,
  });
  final String userId;
  final String targetUserId;
  final SwipeActionType actionType;
  final MembershipRules? membershipRules;
  final MembershipTier? membershipTier;
}

/// Refresh discovery stack
class DiscoveryStackRefreshRequested extends DiscoveryEvent {

  const DiscoveryStackRefreshRequested({
    required this.userId,
    required this.preferences,
  });
  final String userId;
  final MatchPreferences preferences;
}

/// Load more candidates
class DiscoveryMoreCandidatesRequested extends DiscoveryEvent {

  const DiscoveryMoreCandidatesRequested({
    required this.userId,
    required this.preferences,
  });
  final String userId;
  final MatchPreferences preferences;
}

/// Rewind (undo) the last swipe
class DiscoveryRewindRequested extends DiscoveryEvent {

  const DiscoveryRewindRequested({
    required this.userId,
    this.membershipRules,
    this.membershipTier,
  });
  final String userId;
  final MembershipRules? membershipRules;
  final MembershipTier? membershipTier;
}

/// Prefetch more profiles in background (triggered automatically when queue is low)
class DiscoveryPrefetchRequested extends DiscoveryEvent {

  const DiscoveryPrefetchRequested({
    required this.userId,
    required this.preferences,
  });
  final String userId;
  final MatchPreferences preferences;
}
