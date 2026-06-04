/// Matches Events
abstract class MatchesEvent {
  const MatchesEvent();
}

/// Load user's matches
class MatchesLoadRequested extends MatchesEvent {

  const MatchesLoadRequested({
    required this.userId,
    this.activeOnly = true,
  });
  final String userId;
  final bool activeOnly;
}

/// Refresh matches
class MatchesRefreshRequested extends MatchesEvent {

  const MatchesRefreshRequested(this.userId);
  final String userId;
}

/// Mark match as seen
class MatchMarkedAsSeen extends MatchesEvent {

  const MatchMarkedAsSeen({
    required this.matchId,
    required this.userId,
  });
  final String matchId;
  final String userId;
}

/// Unmatch with user
class MatchUnmatchRequested extends MatchesEvent {

  const MatchUnmatchRequested({
    required this.matchId,
    required this.userId,
  });
  final String matchId;
  final String userId;
}

/// Internal event: matches stream detected new data
class MatchesStreamUpdated extends MatchesEvent {

  const MatchesStreamUpdated(this.userId);
  final String userId;
}
