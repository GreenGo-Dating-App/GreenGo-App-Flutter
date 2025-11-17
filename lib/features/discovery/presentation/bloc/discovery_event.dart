import '../../domain/entities/match_preferences.dart';
import '../../domain/entities/swipe_action.dart';

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

  const DiscoverySwipeRecorded({
    required this.userId,
    required this.targetUserId,
    required this.actionType,
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
