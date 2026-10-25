import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../data/chat_constants.dart';
import '../../data/datasources/chat_message_cache.dart';
import '../../domain/entities/message_page.dart';
import '../../domain/message_window.dart';
import '../../domain/repositories/group_chat_repository.dart';
import '../../domain/usecases/get_group_messages.dart';
import '../../domain/usecases/group_membership.dart';
import '../../domain/usecases/mark_group_read.dart';
import '../../domain/usecases/send_group_message.dart';
import 'group_chat_event.dart';
import 'group_chat_state.dart';

/// Group Chat BLoC (single group).
///
/// Paints the device copy of the group's latest messages first, then listens
/// to the newest [kChatPageSize] messages only; older pages are read once on
/// scroll ([GroupChatOlderRequested]). Performs actions through use cases. Sends are a single Firestore write; the
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
    ChatMessageCache? messageCache,
  })  : _messageCache = messageCache ?? JsonChatMessageCache.instance,
        super(const GroupChatInitial()) {
    on<GroupChatStarted>(_onStarted);
    on<GroupChatOlderRequested>(_onOlderRequested);
    on<_GroupMessagesUpdated>(_onMessagesUpdated);
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

  final ChatMessageCache _messageCache;

  String _groupId = '';
  String _userId = '';
  // Live window size = older page size (owner 2026-10-24: newest 20, then
  // pages of 20 on scroll).
  int _pageSize = kChatPageSize;
  bool _hasLoadedOnce = false;

  /// The ONE live-window subscription (re-starting replaces it; scrolling
  /// never adds listeners).
  StreamSubscription<Either<Failure, MessagePage>>? _messagesSub;
  final MessageWindow _window = MessageWindow();
  bool _loadingOlder = false;

  /// Newest message seen, to mark read when a new one arrives while open.
  String? _newestId;
  bool _markingRead = false;

  Future<void> _onStarted(
    GroupChatStarted event,
    Emitter<GroupChatState> emit,
  ) async {
    _groupId = event.groupId;
    _userId = event.userId;
    if (event.limit != null) _pageSize = event.limit!;
    _window.reset();
    _loadingOlder = false;
    _newestId = null;
    // Only show the spinner on the first load.
    if (!_hasLoadedOnce) emit(const GroupChatLoading());
    _hasLoadedOnce = true;

    // Mark read on open — fire-and-forget (own write), never blocks the list.
    _markRead();

    // CACHE FIRST (owner 2026-10-24): the device copy of the latest messages
    // paints before any network read (a Hive read, bounded).
    final groupId = _groupId;
    final cached = await _readCache(groupId);
    if (groupId == _groupId &&
        cached != null &&
        _window.showCached(cached.messages)) {
      emit(_loaded());
    }

    await _messagesSub?.cancel();
    _messagesSub = getGroupMessages.latest(_params()).listen(
      (result) => add(_GroupMessagesUpdated(groupId, result)),
      onError: (Object e) => debugPrint('[GroupChat] stream error: $e'),
    );
  }

  GetGroupMessagesParams _params() =>
      GetGroupMessagesParams(groupId: _groupId, limit: _pageSize);

  GroupChatLoaded _loaded() => GroupChatLoaded(
        groupId: _groupId,
        userId: _userId,
        messages: _window.messages,
        hasMore: _window.hasMore,
        loadingOlder: _loadingOlder,
      );

  Future<CachedChat?> _readCache(String groupId) async {
    try {
      return await _messageCache
          .load(ChatMessageCache.group(groupId))
          .timeout(const Duration(milliseconds: 400), onTimeout: () => null);
    } catch (_) {
      return null;
    }
  }

  void _markRead() {
    if (_markingRead || _groupId.isEmpty) return;
    _markingRead = true;
    unawaited(markGroupRead(
      MarkGroupReadParams(groupId: _groupId, userId: _userId),
    ).then((_) {}, onError: (Object _) {}).whenComplete(() {
      _markingRead = false;
    }));
  }

  void _onMessagesUpdated(
    _GroupMessagesUpdated event,
    Emitter<GroupChatState> emit,
  ) {
    if (event.groupId != _groupId) return;
    event.result.fold(
      (failure) {
        // Messages already on screen (cache / earlier snapshots) stay.
        if (_window.messages.isEmpty) {
          emit(GroupChatError(failure.message));
        } else {
          debugPrint('[GroupChat] live window failed: ${failure.message}');
        }
      },
      (page) {
        if (!_window.applyLive(page)) return;
        final newest = page.messages.isEmpty ? null : page.messages.first;
        // A new message from someone else while the chat is open: read.
        if (!page.fromCache &&
            newest != null &&
            _newestId != null &&
            newest.messageId != _newestId &&
            newest.senderId != _userId) {
          _markRead();
        }
        if (!page.fromCache) _newestId = newest?.messageId;
        emit(_loaded());
        if (!page.fromCache && _window.messages.isNotEmpty) {
          unawaited(_messageCache.save(
              ChatMessageCache.group(_groupId), _window.messages));
        }
      },
    );
  }

  Future<void> _onOlderRequested(
    GroupChatOlderRequested event,
    Emitter<GroupChatState> emit,
  ) async {
    if (_loadingOlder || !_window.hasMore || !_window.liveLoaded) return;
    final before = _window.nextCursor;
    if (before == null) return;
    _loadingOlder = true;
    emit(_loaded());
    final result = await getGroupMessages.older(_params(), before: before);
    _loadingOlder = false;
    result.fold(
      (failure) => debugPrint('[GroupChat] older page failed: ${failure.message}'),
      _window.applyOlder,
    );
    emit(_loaded());
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

  @override
  Future<void> close() {
    _messagesSub?.cancel();
    return super.close();
  }
}

/// Internal: a live-window snapshot of [groupId].
class _GroupMessagesUpdated extends GroupChatEvent {
  const _GroupMessagesUpdated(this.groupId, this.result);
  final String groupId;
  final Either<Failure, MessagePage> result;
}
