import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/group_chat_repository.dart';
import '../../domain/usecases/get_group_messages.dart';
import '../../domain/usecases/group_membership.dart';
import '../../domain/usecases/mark_group_read.dart';
import '../../domain/usecases/send_group_message.dart';
import 'group_chat_event.dart';
import 'group_chat_state.dart';

/// Group Chat BLoC (single group).
///
/// Subscribes to the group's message stream (newest first, paginated) and
/// performs actions through use cases. Sends are a single Firestore write; the
/// server-side fan-out updates inboxes/unread/notifications, and the message
/// stream reflects the change — so action handlers don't emit message state
/// themselves.
class GroupChatBloc extends Bloc<GroupChatEvent, GroupChatState> {
  GroupChatBloc({
    required this.getGroupMessages,
    required this.sendGroupMessage,
    required this.markGroupRead,
    required this.addGroupMembers,
    required this.removeGroupMember,
    required this.leaveGroup,
    required this.updateGroupInfo,
    required this.changeGroupRole,
    required this.repository,
  }) : super(const GroupChatInitial()) {
    on<GroupChatStarted>(_onStarted);
    on<GroupChatMessageSent>(_onMessageSent);
    on<GroupChatMarkedRead>(_onMarkedRead);
    on<GroupChatReactionAdded>(_onReactionAdded);
    on<GroupChatReactionRemoved>(_onReactionRemoved);
    on<GroupChatMembersAdded>(_onMembersAdded);
    on<GroupChatMemberRemoved>(_onMemberRemoved);
    on<GroupChatLeft>(_onLeft);
    on<GroupChatInfoUpdated>(_onInfoUpdated);
    on<GroupChatRoleChanged>(_onRoleChanged);
  }

  final GetGroupMessages getGroupMessages;
  final SendGroupMessage sendGroupMessage;
  final MarkGroupRead markGroupRead;
  final AddGroupMembers addGroupMembers;
  final RemoveGroupMember removeGroupMember;
  final LeaveGroup leaveGroup;
  final UpdateGroupInfo updateGroupInfo;
  final ChangeGroupRole changeGroupRole;
  final GroupChatRepository repository;

  String _groupId = '';
  String _userId = '';

  Future<void> _onStarted(
    GroupChatStarted event,
    Emitter<GroupChatState> emit,
  ) async {
    _groupId = event.groupId;
    _userId = event.userId;
    emit(const GroupChatLoading());

    // Mark read on open (fire-and-forget — own write).
    await markGroupRead(
      MarkGroupReadParams(groupId: _groupId, userId: _userId),
    );

    await emit.forEach(
      getGroupMessages(GetGroupMessagesParams(groupId: _groupId)),
      onData: (result) => result.fold(
        (failure) => GroupChatError(failure.message),
        (messages) => GroupChatLoaded(
          groupId: _groupId,
          userId: _userId,
          messages: messages,
        ),
      ),
      onError: (error, _) => GroupChatError('$error'),
    );
  }

  Future<void> _onMessageSent(
    GroupChatMessageSent event,
    Emitter<GroupChatState> emit,
  ) async {
    final result = await sendGroupMessage(
      SendGroupMessageParams(
        groupId: _groupId,
        senderId: _userId,
        content: event.content,
        type: event.type,
        metadata: event.metadata,
        detectedLanguage: event.detectedLanguage,
      ),
    );
    result.fold(
      (failure) => emit(GroupChatActionFailure(failure.message)),
      (_) {},
    );
  }

  Future<void> _onMarkedRead(
    GroupChatMarkedRead event,
    Emitter<GroupChatState> emit,
  ) async {
    await markGroupRead(
      MarkGroupReadParams(groupId: _groupId, userId: _userId),
    );
  }

  Future<void> _onReactionAdded(
    GroupChatReactionAdded event,
    Emitter<GroupChatState> emit,
  ) async {
    await repository.addReaction(
      groupId: _groupId,
      messageId: event.messageId,
      userId: _userId,
      emoji: event.emoji,
    );
  }

  Future<void> _onReactionRemoved(
    GroupChatReactionRemoved event,
    Emitter<GroupChatState> emit,
  ) async {
    await repository.removeReaction(
      groupId: _groupId,
      messageId: event.messageId,
      userId: _userId,
    );
  }

  Future<void> _onMembersAdded(
    GroupChatMembersAdded event,
    Emitter<GroupChatState> emit,
  ) async {
    final result = await addGroupMembers(
      groupId: _groupId,
      actorId: _userId,
      memberIds: event.memberIds,
    );
    result.fold(
      (failure) => emit(GroupChatActionFailure(failure.message)),
      (_) {},
    );
  }

  Future<void> _onMemberRemoved(
    GroupChatMemberRemoved event,
    Emitter<GroupChatState> emit,
  ) async {
    final result = await removeGroupMember(
      groupId: _groupId,
      actorId: _userId,
      memberId: event.memberId,
    );
    result.fold(
      (failure) => emit(GroupChatActionFailure(failure.message)),
      (_) {},
    );
  }

  Future<void> _onLeft(
    GroupChatLeft event,
    Emitter<GroupChatState> emit,
  ) async {
    final result = await leaveGroup(groupId: _groupId, userId: _userId);
    result.fold(
      (failure) => emit(GroupChatActionFailure(failure.message)),
      (_) => emit(const GroupChatLeftSuccess()),
    );
  }

  Future<void> _onInfoUpdated(
    GroupChatInfoUpdated event,
    Emitter<GroupChatState> emit,
  ) async {
    final result = await updateGroupInfo(
      groupId: _groupId,
      name: event.name,
      photoUrl: event.photoUrl,
      description: event.description,
      language: event.language,
    );
    result.fold(
      (failure) => emit(GroupChatActionFailure(failure.message)),
      (_) {},
    );
  }

  Future<void> _onRoleChanged(
    GroupChatRoleChanged event,
    Emitter<GroupChatState> emit,
  ) async {
    final result = await changeGroupRole(
      groupId: _groupId,
      actorId: _userId,
      memberId: event.memberId,
      role: event.role,
    );
    result.fold(
      (failure) => emit(GroupChatActionFailure(failure.message)),
      (_) {},
    );
  }
}
