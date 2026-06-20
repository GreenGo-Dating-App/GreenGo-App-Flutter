/// Groups list events.
abstract class GroupsEvent {
  const GroupsEvent();
}

/// Start streaming the current user's groups (Culture Circles).
class GroupsLoadRequested extends GroupsEvent {
  const GroupsLoadRequested(this.userId);
  final String userId;
}

/// Re-subscribe / refresh the groups stream.
class GroupsRefreshRequested extends GroupsEvent {
  const GroupsRefreshRequested();
}
