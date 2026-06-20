import '../../domain/entities/conversation.dart';

/// Groups list states.
abstract class GroupsState {
  const GroupsState();
}

class GroupsInitial extends GroupsState {
  const GroupsInitial();
}

class GroupsLoading extends GroupsState {
  const GroupsLoading();
}

class GroupsLoaded extends GroupsState {
  const GroupsLoaded({required this.groups});
  final List<Conversation> groups;
}

class GroupsEmpty extends GroupsState {
  const GroupsEmpty();
}

class GroupsError extends GroupsState {
  const GroupsError(this.message);
  final String message;
}
