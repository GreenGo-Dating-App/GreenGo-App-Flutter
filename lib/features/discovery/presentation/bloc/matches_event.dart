/// Matches Events
abstract class MatchesEvent {
  const MatchesEvent();
}

/// Load user's matches
class MatchesLoadRequested extends MatchesEvent {
  final String userId;
  final bool activeOnly;

  const MatchesLoadRequested({
    required this.userId,
    this.activeOnly = true,
  });
}

/// Refresh matches
class MatchesRefreshRequested extends MatchesEvent {
  final String userId;

  const MatchesRefreshRequested(this.userId);
}

/// Mark match as seen
class MatchMarkedAsSeen extends MatchesEvent {
  final String matchId;
  final String userId;

  const MatchMarkedAsSeen({
    required this.matchId,
    required this.userId,
  });
}

/// Unmatch with user
class MatchUnmatchRequested extends MatchesEvent {
  final String matchId;
  final String userId;

  const MatchUnmatchRequested({
    required this.matchId,
    required this.userId,
  });
}
