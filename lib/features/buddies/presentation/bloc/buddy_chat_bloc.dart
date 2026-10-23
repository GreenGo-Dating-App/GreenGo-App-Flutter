import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/buddy_catalog.dart';
import '../../domain/buddy_exception.dart';
import '../../domain/entities/buddy.dart';
import '../../domain/entities/buddy_message.dart';
import '../../domain/entities/buddy_status.dart';
import '../../domain/repositories/buddies_repository.dart';

// ---------------------------------------------------------------- events

sealed class BuddyChatEvent extends Equatable {
  const BuddyChatEvent();
  @override
  List<Object?> get props => [];
}

class BuddyChatStarted extends BuddyChatEvent {
  const BuddyChatStarted({required this.uid, required this.buddyId, this.locked = false});
  final String uid;
  final String buddyId;

  /// Known locked on the current plan (from the Buddies list).
  final bool locked;
  @override
  List<Object?> get props => [uid, buddyId, locked];
}

/// Scrolled to the top: load the previous page.
class BuddyChatOlderRequested extends BuddyChatEvent {
  const BuddyChatOlderRequested();
}

class BuddyChatSendPressed extends BuddyChatEvent {
  const BuddyChatSendPressed(this.text);
  final String text;
  @override
  List<Object?> get props => [text];
}

/// Send a failed message again (same requestId: never charged twice).
class BuddyChatRetryPressed extends BuddyChatEvent {
  const BuddyChatRetryPressed(this.localId);
  final String localId;
  @override
  List<Object?> get props => [localId];
}

/// The chat was cleared on the server.
class BuddyChatCleared extends BuddyChatEvent {
  const BuddyChatCleared();
}

class _ServerMessages extends BuddyChatEvent {
  const _ServerMessages(this.messages);
  final List<BuddyMessage> messages;
  @override
  List<Object?> get props => [messages];
}

class _BuddyChanged extends BuddyChatEvent {
  const _BuddyChanged(this.buddy);
  final Buddy? buddy;
  @override
  List<Object?> get props => [buddy];
}

class _StatusLoaded extends BuddyChatEvent {
  const _StatusLoaded(this.status);
  final BuddyStatus status;
  @override
  List<Object?> get props => [status];
}

// ----------------------------------------------------------------- state

class BuddyChatState extends Equatable {
  const BuddyChatState({
    this.buddy,
    this.buddyDeleted = false,
    this.server = const <BuddyMessage>[],
    this.local = const <BuddyMessage>[],
    this.loading = true,
    this.loadError,
    this.loadingOlder = false,
    this.hasMore = false,
    this.waitingReply = false,
    this.locked = false,
    this.freeRepliesLeft,
    this.coinsPerReply = 1,
    this.status,
    this.error,
    this.errorLocalId,
    this.errorSeq = 0,
    this.replySeq = 0,
  });

  final Buddy? buddy;

  /// The Buddy doc disappeared (deleted on another device).
  final bool buddyDeleted;

  /// Messages read from Firestore, oldest first.
  final List<BuddyMessage> server;

  /// Messages of this session not (yet) seen in Firestore: what the user
  /// typed (sending / failed) and replies already returned by the callable.
  final List<BuddyMessage> local;

  final bool loading;
  final Object? loadError;
  final bool loadingOlder;
  final bool hasMore;

  /// Typing indicator: a reply is on its way.
  final bool waitingReply;

  /// This Buddy is beyond the plan limit (input replaced by an upgrade hint).
  final bool locked;

  final int? freeRepliesLeft;
  final int coinsPerReply;

  /// Plan status (limit + tier for the upgrade prompt), when loaded.
  final BuddyStatus? status;

  /// Last send failure; [errorSeq] changes on every new one (listeners).
  final BuddyException? error;
  final String? errorLocalId;
  final int errorSeq;

  /// Changes each time a reply arrived after a send (sounds).
  final int replySeq;

  /// Everything to show, oldest first.
  List<BuddyMessage> get messages => [...server, ...local];

  BuddyChatState copyWith({
    Buddy? Function()? buddy,
    bool? buddyDeleted,
    List<BuddyMessage>? server,
    List<BuddyMessage>? local,
    bool? loading,
    Object? Function()? loadError,
    bool? loadingOlder,
    bool? hasMore,
    bool? waitingReply,
    bool? locked,
    int? freeRepliesLeft,
    int? coinsPerReply,
    BuddyStatus? status,
    BuddyException? error,
    String? errorLocalId,
    int? errorSeq,
    int? replySeq,
  }) =>
      BuddyChatState(
        buddy: buddy != null ? buddy() : this.buddy,
        buddyDeleted: buddyDeleted ?? this.buddyDeleted,
        server: server ?? this.server,
        local: local ?? this.local,
        loading: loading ?? this.loading,
        loadError: loadError != null ? loadError() : this.loadError,
        loadingOlder: loadingOlder ?? this.loadingOlder,
        hasMore: hasMore ?? this.hasMore,
        waitingReply: waitingReply ?? this.waitingReply,
        locked: locked ?? this.locked,
        freeRepliesLeft: freeRepliesLeft ?? this.freeRepliesLeft,
        coinsPerReply: coinsPerReply ?? this.coinsPerReply,
        status: status ?? this.status,
        error: error ?? this.error,
        errorLocalId: errorLocalId ?? this.errorLocalId,
        errorSeq: errorSeq ?? this.errorSeq,
        replySeq: replySeq ?? this.replySeq,
      );

  @override
  List<Object?> get props => [
        buddy,
        buddyDeleted,
        server,
        local,
        loading,
        loadError,
        loadingOlder,
        hasMore,
        waitingReply,
        locked,
        freeRepliesLeft,
        coinsPerReply,
        status,
        error,
        errorLocalId,
        errorSeq,
        replySeq,
      ];
}

/// Merges [incoming] server messages into [server] (by id, oldest first).
List<BuddyMessage> mergeServerMessages(List<BuddyMessage> server, List<BuddyMessage> incoming) {
  final byId = <String, BuddyMessage>{for (final m in server) m.id: m};
  for (final m in incoming) {
    byId[m.id] = m;
  }
  return byId.values.toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
}

/// Matches [incoming] server messages with the local ones they replace (same
/// role + text; each server message consumes at most one local message that
/// is already delivered). Returns the local messages still to show and the
/// server messages that matched nothing yet. Pure; tested.
({List<BuddyMessage> local, List<BuddyMessage> unmatched}) reconcileLocal(
    List<BuddyMessage> local, List<BuddyMessage> incoming) {
  final remaining = [...local];
  final unmatched = <BuddyMessage>[];
  for (final m in incoming) {
    final i = remaining.indexWhere((l) =>
        l.delivery == BuddyDelivery.sent && l.role == m.role && l.text.trim() == m.text.trim());
    if (i >= 0) {
      remaining.removeAt(i);
    } else {
      unmatched.add(m);
    }
  }
  return (local: remaining, unmatched: unmatched);
}

// ------------------------------------------------------------------ bloc

/// One Buddy chat: paginated history (newest page first, older on scroll),
/// live new messages of this session, and sending with retry.
class BuddyChatBloc extends Bloc<BuddyChatEvent, BuddyChatState> {
  BuddyChatBloc({required BuddiesRepository repository, this.pageSize = 30})
      : _repo = repository,
        super(const BuddyChatState()) {
    on<BuddyChatStarted>(_onStarted);
    on<BuddyChatOlderRequested>(_onOlder);
    on<BuddyChatSendPressed>(_onSend);
    on<BuddyChatRetryPressed>(_onRetry);
    on<BuddyChatCleared>(_onCleared);
    on<_ServerMessages>(_onServerMessages);
    on<_BuddyChanged>(_onBuddyChanged);
    on<_StatusLoaded>(_onStatus);
  }

  final BuddiesRepository _repo;
  final int pageSize;
  String? _uid;
  String? _buddyId;
  StreamSubscription<List<BuddyMessage>>? _newSub;
  StreamSubscription<Buddy?>? _buddySub;

  /// Server messages of this session no local message matched yet (e.g. the
  /// listener was faster than the callable's answer).
  List<BuddyMessage> _unmatched = const <BuddyMessage>[];

  Future<void> _onStarted(BuddyChatStarted event, Emitter<BuddyChatState> emit) async {
    _uid = event.uid;
    _buddyId = event.buddyId;
    emit(BuddyChatState(locked: event.locked));
    await _buddySub?.cancel();
    _buddySub = _repo.watchBuddy(event.uid, event.buddyId).listen(
          (b) => add(_BuddyChanged(b)),
          onError: (_) {},
        );
    unawaited(_loadStatus());
    try {
      final page = await _repo.latestMessages(event.uid, event.buddyId, limit: pageSize);
      emit(state.copyWith(
        server: page.messages,
        hasMore: page.hasMore,
        loading: false,
        loadError: () => null,
      ));
      final newest = page.messages.isEmpty ? null : page.messages.last.createdAt;
      await _newSub?.cancel();
      _newSub = _repo.watchNewMessages(event.uid, event.buddyId, after: newest).listen(
            (list) => add(_ServerMessages(list)),
            onError: (_) {},
          );
    } catch (e) {
      emit(state.copyWith(loading: false, loadError: () => e));
    }
  }

  Future<void> _loadStatus() async {
    try {
      final s = await _repo.getStatus();
      if (!isClosed) add(_StatusLoaded(s));
    } catch (_) {
      // Informative only.
    }
  }

  void _onStatus(_StatusLoaded event, Emitter<BuddyChatState> emit) {
    emit(state.copyWith(
      freeRepliesLeft: event.status.freeRepliesLeft,
      coinsPerReply: event.status.coinsPerReply,
      status: event.status,
    ));
  }

  Future<void> _onOlder(BuddyChatOlderRequested event, Emitter<BuddyChatState> emit) async {
    final uid = _uid, id = _buddyId;
    if (uid == null || id == null) return;
    if (state.loadingOlder || !state.hasMore || state.server.isEmpty) return;
    emit(state.copyWith(loadingOlder: true));
    try {
      final page = await _repo.olderMessages(uid, id,
          before: state.server.first.createdAt, limit: pageSize);
      emit(state.copyWith(
        server: mergeServerMessages(state.server, page.messages),
        hasMore: page.hasMore,
        loadingOlder: false,
      ));
    } catch (_) {
      emit(state.copyWith(loadingOlder: false));
    }
  }

  void _onServerMessages(_ServerMessages event, Emitter<BuddyChatState> emit) {
    final known = {for (final m in state.server) m.id};
    final fresh = event.messages.where((m) => !known.contains(m.id)).toList();
    final r = reconcileLocal(state.local, fresh);
    _unmatched = [..._unmatched, ...r.unmatched];
    emit(state.copyWith(
      server: mergeServerMessages(state.server, event.messages),
      local: r.local,
    ));
  }

  void _onBuddyChanged(_BuddyChanged event, Emitter<BuddyChatState> emit) {
    emit(state.copyWith(
      buddy: () => event.buddy ?? state.buddy,
      buddyDeleted: event.buddy == null && !state.loading,
    ));
  }

  Future<void> _onSend(BuddyChatSendPressed event, Emitter<BuddyChatState> emit) async {
    final text = event.text.trim();
    if (text.isEmpty || text.runes.length > BuddyCatalog.maxMessageChars) return;
    if (state.waitingReply || state.locked || _buddyId == null) return;
    final requestId = _repo.newRequestId();
    final msg = BuddyMessage(
      id: 'local_$requestId',
      role: BuddyMessageRole.user,
      text: text,
      createdAt: DateTime.now(),
      delivery: BuddyDelivery.sending,
      requestId: requestId,
    );
    emit(state.copyWith(local: [...state.local, msg]));
    await _deliver(msg, emit);
  }

  Future<void> _onRetry(BuddyChatRetryPressed event, Emitter<BuddyChatState> emit) async {
    if (state.waitingReply) return;
    final i = state.local.indexWhere((m) => m.id == event.localId);
    if (i < 0 || state.local[i].delivery != BuddyDelivery.failed) return;
    final msg = state.local[i].copyWith(delivery: BuddyDelivery.sending);
    final local = [...state.local]..[i] = msg;
    emit(state.copyWith(local: local));
    await _deliver(msg, emit);
  }

  List<BuddyMessage> _replace(String id, BuddyMessage Function(BuddyMessage) f) =>
      [for (final m in state.local) m.id == id ? f(m) : m];

  Future<void> _deliver(BuddyMessage msg, Emitter<BuddyChatState> emit) async {
    emit(state.copyWith(waitingReply: true));
    try {
      final r = await _repo.sendMessage(
        buddyId: _buddyId!,
        text: msg.text,
        requestId: msg.requestId!,
      );
      final reply = BuddyMessage(
        id: 'local_reply_${msg.requestId}',
        role: BuddyMessageRole.buddy,
        text: r.reply,
        kind: BuddyMessage.kindFrom(r.kind),
        charged: r.charged,
        createdAt: DateTime.now(),
      );
      // The Firestore listener may already have delivered both messages.
      final local = _replace(msg.id, (m) => m.copyWith(delivery: BuddyDelivery.sent));
      final rec = reconcileLocal([...local, reply], _unmatched);
      _unmatched = rec.unmatched;
      emit(state.copyWith(
        local: rec.local,
        waitingReply: false,
        freeRepliesLeft: r.freeRepliesLeft,
        replySeq: state.replySeq + 1,
      ));
    } catch (e) {
      final err = BuddyException.from(e);
      emit(state.copyWith(
        local: _replace(msg.id, (m) => m.copyWith(delivery: BuddyDelivery.failed)),
        waitingReply: false,
        locked: err.kind == BuddyErrorKind.tierRequired ? true : null,
        freeRepliesLeft: err.kind == BuddyErrorKind.insufficientCoins ? 0 : null,
        error: err,
        errorLocalId: msg.id,
        errorSeq: state.errorSeq + 1,
      ));
    }
  }

  void _onCleared(BuddyChatCleared event, Emitter<BuddyChatState> emit) {
    _unmatched = const <BuddyMessage>[];
    emit(state.copyWith(server: const [], local: const [], hasMore: false));
  }

  @override
  Future<void> close() async {
    await _newSub?.cancel();
    await _buddySub?.cancel();
    return super.close();
  }
}
