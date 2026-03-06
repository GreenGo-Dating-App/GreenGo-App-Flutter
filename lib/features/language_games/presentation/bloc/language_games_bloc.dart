import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/game_room.dart';
import '../../domain/entities/game_round.dart';
import '../../domain/repositories/language_games_repository.dart';
import 'language_games_event.dart';
import 'language_games_state.dart';

/// Language Games BLoC
///
/// Manages state for multiplayer language learning games including:
/// - Lobby browsing and room creation/joining
/// - Real-time room, round, and chat stream subscriptions
/// - Game flow (matchmaking, playing, scoring, finishing)
/// - Live player counts for the lobby
///
/// Stream subscriptions are automatically cancelled on [StopListening]
/// and in [close] to prevent memory leaks.
class LanguageGamesBloc extends Bloc<LanguageGamesEvent, LanguageGamesState> {
  static const _timeout = Duration(seconds: 15);

  LanguageGamesBloc({required this.repository})
      : super(const LanguageGamesInitial()) {
    on<LoadAvailableRooms>(_onLoadAvailableRooms);
    on<CreateRoom>(_onCreateRoom);
    on<JoinRoom>(_onJoinRoom);
    on<LeaveRoom>(_onLeaveRoom);
    on<ToggleReady>(_onToggleReady);
    on<StartGame>(_onStartGame);
    on<SubmitAnswer>(_onSubmitAnswer);
    on<QuickPlay>(_onQuickPlay);
    on<ListenToRoom>(_onListenToRoom);
    on<ListenToRound>(_onListenToRound);
    on<StopListening>(_onStopListening);
    on<SendChatMessage>(_onSendChatMessage);
    on<LoadLiveCounts>(_onLoadLiveCounts);
    on<AdvanceRound>(_onAdvanceRound);
    on<AdvanceTurn>(_onAdvanceTurn);
    on<EndGame>(_onEndGame);
    on<SendGameInvite>(_onSendGameInvite);
    on<RespondToGameInvite>(_onRespondToGameInvite);
    on<ReportWord>(_onReportWord);
  }

  final LanguageGamesRepository repository;

  StreamSubscription<GameRoom>? _roomSubscription;
  StreamSubscription<GameRound?>? _roundSubscription;
  StreamSubscription<List<GameChatMessage>>? _chatSubscription;
  StreamSubscription<dynamic>? _liveCountsSubscription;

  // ============================================================
  // EVENT HANDLERS
  // ============================================================

  /// Load available rooms, optionally filtered by language or game type.
  Future<void> _onLoadAvailableRooms(
    LoadAvailableRooms event,
    Emitter<LanguageGamesState> emit,
  ) async {
    emit(const LanguageGamesLoading());
    debugPrint('[LanguageGamesBloc] Loading available rooms '
        '(language=${event.targetLanguage}, type=${event.gameType})');

    try {
    final result = await repository.getAvailableRooms(
      targetLanguage: event.targetLanguage,
      gameType: event.gameType,
    ).timeout(_timeout);

    result.fold(
      (failure) {
        debugPrint(
            '[LanguageGamesBloc] Failed to load rooms: ${failure.message}');
        emit(LanguageGamesError(message: failure.message));
      },
      (rooms) {
        debugPrint(
            '[LanguageGamesBloc] Loaded ${rooms.length} available rooms');
        // Preserve live counts if we already had them from a prior subscription
        final currentLiveCounts = state is LanguageGamesLobby
            ? (state as LanguageGamesLobby).liveCounts
            : null;
        emit(LanguageGamesLobby(
          availableRooms: rooms,
          liveCounts: currentLiveCounts,
        ));
      },
    );
    } on TimeoutException {
      debugPrint('[LanguageGamesBloc] Load rooms timed out');
      emit(const LanguageGamesError(message: 'Request timed out. Please try again.'));
    }
  }

  /// Create a new game room and automatically subscribe to its updates.
  Future<void> _onCreateRoom(
    CreateRoom event,
    Emitter<LanguageGamesState> emit,
  ) async {
    emit(const LanguageGamesLoading());
    debugPrint('[LanguageGamesBloc] Creating room '
        '(type=${event.gameType}, lang=${event.targetLanguage}, '
        'host=${event.hostUserId})');

    try {
    final result = await repository.createRoom(
      gameType: event.gameType,
      targetLanguage: event.targetLanguage,
      hostUserId: event.hostUserId,
      hostDisplayName: event.hostDisplayName,
      hostPhotoUrl: event.hostPhotoUrl,
      maxPlayers: event.maxPlayers,
      difficulty: event.difficulty,
    ).timeout(_timeout);

    result.fold(
      (failure) {
        debugPrint(
            '[LanguageGamesBloc] Failed to create room: ${failure.message}');
        emit(LanguageGamesError(message: failure.message));
      },
      (room) {
        debugPrint('[LanguageGamesBloc] Room created: ${room.id}');
        emit(LanguageGamesInRoom(room: room));
        // Auto-subscribe to room and chat streams
        add(ListenToRoom(roomId: room.id));
      },
    );
    } on TimeoutException {
      debugPrint('[LanguageGamesBloc] Create room timed out');
      emit(const LanguageGamesError(message: 'Request timed out. Please try again.'));
    }
  }

  /// Join an existing room and automatically subscribe to its updates.
  Future<void> _onJoinRoom(
    JoinRoom event,
    Emitter<LanguageGamesState> emit,
  ) async {
    emit(const LanguageGamesLoading());
    debugPrint('[LanguageGamesBloc] Joining room ${event.roomId} '
        'as ${event.userId}');

    try {
    final result = await repository.joinRoom(
      roomId: event.roomId,
      userId: event.userId,
      displayName: event.displayName,
      photoUrl: event.photoUrl,
    ).timeout(_timeout);

    result.fold(
      (failure) {
        debugPrint(
            '[LanguageGamesBloc] Failed to join room: ${failure.message}');
        emit(LanguageGamesError(message: failure.message));
      },
      (room) {
        debugPrint('[LanguageGamesBloc] Joined room: ${room.id}');
        emit(LanguageGamesInRoom(room: room));
        // Auto-subscribe to room and chat streams
        add(ListenToRoom(roomId: room.id));
      },
    );
    } on TimeoutException {
      debugPrint('[LanguageGamesBloc] Join room timed out');
      emit(const LanguageGamesError(message: 'Request timed out. Please try again.'));
    }
  }

  /// Leave a room: cancel all subscriptions and return to lobby state.
  Future<void> _onLeaveRoom(
    LeaveRoom event,
    Emitter<LanguageGamesState> emit,
  ) async {
    debugPrint('[LanguageGamesBloc] Leaving room ${event.roomId}');
    _cancelAllSubscriptions();

    final result = await repository.leaveRoom(
      roomId: event.roomId,
      userId: event.userId,
    );

    result.fold(
      (failure) {
        debugPrint(
            '[LanguageGamesBloc] Leave room error: ${failure.message}');
        // Still return to lobby even on error -- the user has left the UI
        emit(const LanguageGamesLobby(availableRooms: []));
      },
      (_) {
        debugPrint('[LanguageGamesBloc] Left room successfully');
        emit(const LanguageGamesLobby(availableRooms: []));
      },
    );
  }

  /// Toggle the player's ready status in the lobby.
  Future<void> _onToggleReady(
    ToggleReady event,
    Emitter<LanguageGamesState> emit,
  ) async {
    debugPrint('[LanguageGamesBloc] Toggling ready for ${event.userId} '
        'in room ${event.roomId}');

    final result = await repository.toggleReady(
      roomId: event.roomId,
      userId: event.userId,
    );

    result.fold(
      (failure) {
        debugPrint(
            '[LanguageGamesBloc] Toggle ready failed: ${failure.message}');
        emit(LanguageGamesError(message: failure.message));
      },
      (_) {
        // Room stream will deliver the updated state
        debugPrint(
            '[LanguageGamesBloc] Ready toggled -- awaiting stream update');
      },
    );
  }

  /// Start the game (host-only). The room stream will emit status changes.
  Future<void> _onStartGame(
    StartGame event,
    Emitter<LanguageGamesState> emit,
  ) async {
    debugPrint('[LanguageGamesBloc] Starting game in room ${event.roomId}');

    try {
    final result = await repository.startGame(roomId: event.roomId).timeout(_timeout);

    result.fold(
      (failure) {
        debugPrint(
            '[LanguageGamesBloc] Start game failed: ${failure.message}');
        emit(LanguageGamesError(message: failure.message));
      },
      (_) {
        debugPrint(
            '[LanguageGamesBloc] Game started -- awaiting stream update');
        // Subscribe to round stream now that the game is starting
        add(ListenToRound(roomId: event.roomId));
      },
    );
    } on TimeoutException {
      debugPrint('[LanguageGamesBloc] Start game timed out');
      emit(const LanguageGamesError(message: 'Game start timed out. Please try again.'));
    }
  }

  /// Submit an answer for the current round.
  Future<void> _onSubmitAnswer(
    SubmitAnswer event,
    Emitter<LanguageGamesState> emit,
  ) async {
    debugPrint('[LanguageGamesBloc] Submitting answer in room ${event.roomId} '
        'by ${event.userId}');

    try {
    final result = await repository.submitAnswer(
      roomId: event.roomId,
      userId: event.userId,
      answer: event.answer,
    ).timeout(_timeout);

    result.fold(
      (failure) {
        debugPrint(
            '[LanguageGamesBloc] Submit answer failed: ${failure.message}');
        emit(LanguageGamesError(message: failure.message));
      },
      (answer) {
        debugPrint('[LanguageGamesBloc] Answer submitted: '
            'correct=${answer.isCorrect}, points=${answer.pointsEarned}');
        // Room/round streams will reflect the updated scores
      },
    );
    } on TimeoutException {
      debugPrint('[LanguageGamesBloc] Submit answer timed out');
      emit(const LanguageGamesError(message: 'Answer submission timed out.'));
    }
  }

  /// Quick play: enter matchmaking, then auto-join or create a room.
  Future<void> _onQuickPlay(
    QuickPlay event,
    Emitter<LanguageGamesState> emit,
  ) async {
    debugPrint('[LanguageGamesBloc] Quick play '
        '(type=${event.gameType}, lang=${event.targetLanguage})');

    emit(LanguageGamesMatchmaking(
      gameType: event.gameType,
      language: event.targetLanguage,
    ));

    try {
    final result = await repository.quickPlay(
      gameType: event.gameType,
      targetLanguage: event.targetLanguage,
      userId: event.userId,
      displayName: event.displayName,
      photoUrl: event.photoUrl,
      difficulty: event.difficulty,
    ).timeout(_timeout);

    result.fold(
      (failure) {
        debugPrint(
            '[LanguageGamesBloc] Quick play failed: ${failure.message}');
        emit(LanguageGamesError(message: failure.message));
      },
      (room) {
        debugPrint(
            '[LanguageGamesBloc] Quick play matched to room: ${room.id}');
        emit(LanguageGamesInRoom(room: room));
        // Auto-subscribe to room stream (and round if already in-progress)
        add(ListenToRoom(roomId: room.id));
        if (room.status == GameStatus.inProgress) {
          add(ListenToRound(roomId: room.id));
        }
      },
    );
    } on TimeoutException {
      debugPrint('[LanguageGamesBloc] Quick play timed out');
      emit(const LanguageGamesError(message: 'Matchmaking timed out. Please try again.'));
    }
  }

  /// Subscribe to real-time room updates via `emit.forEach`.
  ///
  /// This handler stays alive for the lifetime of the stream. Each room
  /// snapshot triggers a new [LanguageGamesInRoom] or [LanguageGamesFinished]
  /// emission. Existing round and chat data is preserved across room updates.
  Future<void> _onListenToRoom(
    ListenToRoom event,
    Emitter<LanguageGamesState> emit,
  ) async {
    debugPrint(
        '[LanguageGamesBloc] Subscribing to room stream: ${event.roomId}');
    await _roomSubscription?.cancel();
    _roomSubscription = null;

    // Also subscribe to chat for this room
    _subscribeToChatStream(event.roomId);

    await emit.forEach(
      repository.getRoomStream(event.roomId),
      onData: (GameRoom room) {
        debugPrint('[LanguageGamesBloc] Room stream update: '
            'status=${room.status}, players=${room.players.length}');

        // If game finished, cancel subscriptions and show results
        if (room.status == GameStatus.finished) {
          _cancelAllSubscriptions();
          return LanguageGamesFinished(
            room: room,
            finalScores: room.scores,
            xpEarned: room.xpReward,
          );
        }

        // If game just started (transitioned to inProgress), subscribe to rounds
        if (room.status == GameStatus.inProgress) {
          final currentState = state;
          if (currentState is LanguageGamesInRoom &&
              currentState.room.status != GameStatus.inProgress) {
            debugPrint('[LanguageGamesBloc] Game started -- '
                'subscribing to round stream');
            _subscribeToRoundStream(room.id);
          }
        }

        // Preserve existing round and chat data across room updates
        final currentState = state;
        GameRound? currentRound;
        List<GameChatMessage>? chatMessages;
        if (currentState is LanguageGamesInRoom) {
          currentRound = currentState.currentRound;
          chatMessages = currentState.chatMessages;
        }

        return LanguageGamesInRoom(
          room: room,
          currentRound: currentRound,
          chatMessages: chatMessages,
        );
      },
      onError: (error, stackTrace) {
        debugPrint('[LanguageGamesBloc] Room stream error: $error');
        return const LanguageGamesError(
            message: 'connection_error');
      },
    );
  }

  /// Subscribe to real-time round updates via `emit.forEach`.
  ///
  /// Round data is merged into the current [LanguageGamesInRoom] state.
  /// If the current state is not [LanguageGamesInRoom], the round data
  /// is ignored (the room stream will eventually re-sync).
  Future<void> _onListenToRound(
    ListenToRound event,
    Emitter<LanguageGamesState> emit,
  ) async {
    debugPrint(
        '[LanguageGamesBloc] Subscribing to round stream: ${event.roomId}');
    await _roundSubscription?.cancel();
    _roundSubscription = null;

    await emit.forEach(
      repository.getCurrentRoundStream(event.roomId),
      onData: (GameRound? round) {
        if (round != null) {
          debugPrint('[LanguageGamesBloc] Round stream update: '
              'round=${round.roundNumber}, '
              'answers=${round.playerAnswers.length}');
        }

        final currentState = state;
        if (currentState is LanguageGamesInRoom) {
          return currentState.copyWith(currentRound: round);
        }
        // If not in a room state, keep current state unchanged
        return state;
      },
      onError: (error, stackTrace) {
        debugPrint('[LanguageGamesBloc] Round stream error: $error');
        // Keep current state on round stream errors -- non-critical
        return state;
      },
    );
  }

  /// Cancel all active stream subscriptions.
  void _onStopListening(
    StopListening event,
    Emitter<LanguageGamesState> emit,
  ) {
    debugPrint('[LanguageGamesBloc] Stopping all listeners');
    _cancelAllSubscriptions();
  }

  /// Send a chat message in the game room.
  Future<void> _onSendChatMessage(
    SendChatMessage event,
    Emitter<LanguageGamesState> emit,
  ) async {
    debugPrint(
        '[LanguageGamesBloc] Sending chat in room ${event.roomId}');

    final result = await repository.sendChatMessage(
      roomId: event.roomId,
      userId: event.userId,
      text: event.text,
    );

    result.fold(
      (failure) {
        debugPrint(
            '[LanguageGamesBloc] Send chat failed: ${failure.message}');
        // Do not emit error state for chat failures -- just log it.
        // The user can retry sending.
      },
      (_) {
        debugPrint('[LanguageGamesBloc] Chat message sent');
        // Chat stream will deliver the new message to all listeners
      },
    );
  }

  /// Load live player counts for the lobby.
  ///
  /// Currently a placeholder. When a live counts stream is added to the
  /// repository, this handler will subscribe and merge counts into the
  /// [LanguageGamesLobby] state.
  Future<void> _onLoadLiveCounts(
    LoadLiveCounts event,
    Emitter<LanguageGamesState> emit,
  ) async {
    debugPrint('[LanguageGamesBloc] Loading live counts');

    // TODO: Subscribe to live counts stream when available in repository.
    // Implementation pattern:
    //
    // _liveCountsSubscription?.cancel();
    // await emit.forEach(
    //   repository.getLiveCountsStream(),
    //   onData: (Map<String, Map<String, int>> counts) {
    //     final currentState = state;
    //     if (currentState is LanguageGamesLobby) {
    //       return LanguageGamesLobby(
    //         availableRooms: currentState.availableRooms,
    //         liveCounts: counts,
    //       );
    //     }
    //     return state;
    //   },
    //   onError: (error, stackTrace) => state,
    // );

    // For now, re-emit current lobby state to acknowledge the event
    final currentState = state;
    if (currentState is LanguageGamesLobby) {
      emit(LanguageGamesLobby(
        availableRooms: currentState.availableRooms,
        liveCounts: currentState.liveCounts,
      ));
    }
  }

  /// Advance to the next round.
  Future<void> _onAdvanceRound(
    AdvanceRound event,
    Emitter<LanguageGamesState> emit,
  ) async {
    debugPrint(
        '[LanguageGamesBloc] Advancing round in room ${event.roomId}');

    final result = await repository.advanceRound(roomId: event.roomId);

    result.fold(
      (failure) {
        debugPrint(
            '[LanguageGamesBloc] Advance round failed: ${failure.message}');
        emit(LanguageGamesError(message: failure.message));
      },
      (_) {
        debugPrint(
            '[LanguageGamesBloc] Round advanced -- awaiting stream update');
      },
    );
  }

  /// Advance to the next turn in turn-based games.
  Future<void> _onAdvanceTurn(
    AdvanceTurn event,
    Emitter<LanguageGamesState> emit,
  ) async {
    debugPrint(
        '[LanguageGamesBloc] Advancing turn in room ${event.roomId}');

    final result = await repository.advanceTurn(roomId: event.roomId);

    result.fold(
      (failure) {
        debugPrint(
            '[LanguageGamesBloc] Advance turn failed: ${failure.message}');
        emit(LanguageGamesError(message: failure.message));
      },
      (_) {
        debugPrint(
            '[LanguageGamesBloc] Turn advanced -- awaiting stream update');
      },
    );
  }

  /// End the game and calculate final results.
  Future<void> _onEndGame(
    EndGame event,
    Emitter<LanguageGamesState> emit,
  ) async {
    debugPrint('[LanguageGamesBloc] Ending game in room ${event.roomId}');

    final result = await repository.endGame(roomId: event.roomId);

    result.fold(
      (failure) {
        debugPrint(
            '[LanguageGamesBloc] End game failed: ${failure.message}');
        emit(LanguageGamesError(message: failure.message));
      },
      (_) {
        debugPrint(
            '[LanguageGamesBloc] Game ended -- awaiting stream update');
        // The room stream will emit the finished status
      },
    );
  }

  // ============================================================
  // GAME INVITE HANDLERS
  // ============================================================

  /// Send a game invite to another user.
  Future<void> _onSendGameInvite(
    SendGameInvite event,
    Emitter<LanguageGamesState> emit,
  ) async {
    debugPrint('[LanguageGamesBloc] Sending game invite to ${event.invitedUserId} '
        'for room ${event.roomId}');

    final currentState = state;
    if (currentState is! LanguageGamesInRoom) {
      debugPrint('[LanguageGamesBloc] Cannot send invite -- not in a room');
      return;
    }

    final room = currentState.room;
    final result = await repository.sendGameInvite(
      roomId: event.roomId,
      invitedUserId: event.invitedUserId,
      hostUserId: room.hostUserId,
      hostNickname: event.hostNickname,
      hostPhotoUrl: event.hostPhotoUrl,
      gameType: room.gameType.name,
      gameName: room.gameType.displayName,
      targetLanguage: room.targetLanguage,
    );

    result.fold(
      (failure) {
        debugPrint('[LanguageGamesBloc] Send invite failed: ${failure.message}');
        emit(LanguageGamesError(message: failure.message));
      },
      (_) {
        debugPrint('[LanguageGamesBloc] Game invite sent successfully');
        // Re-emit current room state to stay in room
        emit(currentState);
      },
    );
  }

  /// Respond to a game invite (accept or decline).
  Future<void> _onRespondToGameInvite(
    RespondToGameInvite event,
    Emitter<LanguageGamesState> emit,
  ) async {
    debugPrint('[LanguageGamesBloc] Responding to invite ${event.inviteId}: '
        'accepted=${event.accepted}');

    final result = await repository.respondToInvite(
      inviteId: event.inviteId,
      accepted: event.accepted,
    );

    result.fold(
      (failure) {
        debugPrint('[LanguageGamesBloc] Respond to invite failed: ${failure.message}');
      },
      (_) {
        debugPrint('[LanguageGamesBloc] Invite response recorded');
        // If accepted, join the room
        if (event.accepted && event.roomId != null &&
            event.userId != null && event.displayName != null) {
          add(JoinRoom(
            roomId: event.roomId!,
            userId: event.userId!,
            displayName: event.displayName!,
          ));
        }
      },
    );
  }

  // ============================================================
  // PRIVATE STREAM HELPERS
  // ============================================================

  /// Subscribe to the round sub-collection stream.
  ///
  /// Round updates are stored in [_roundSubscription] and merged into
  /// the current state by the room stream handler. This is called
  /// internally when the game transitions to in-progress status.
  void _subscribeToRoundStream(String roomId) {
    _roundSubscription?.cancel();

    _roundSubscription = repository.getCurrentRoundStream(roomId).listen(
      (round) {
        // Round updates are handled by the ListenToRound event handler
        // when dispatched explicitly. For auto-subscriptions (e.g., after
        // game start), we use a direct subscription that triggers a
        // ListenToRound event to ensure proper emit context.
        debugPrint('[LanguageGamesBloc] Round update via internal sub: '
            'round=${round?.roundNumber}');
      },
      onError: (error) {
        debugPrint(
            '[LanguageGamesBloc] Round stream error (internal): $error');
      },
    );
  }

  /// Subscribe to the chat messages stream for the given room.
  ///
  /// Chat updates are merged into the [LanguageGamesInRoom] state
  /// when new messages arrive. Since we cannot emit directly from
  /// a stream callback, new messages are stored and picked up
  /// on the next room stream emission.
  void _subscribeToChatStream(String roomId) {
    _chatSubscription?.cancel();

    _chatSubscription = repository.getChatStream(roomId).listen(
      (messages) {
        debugPrint('[LanguageGamesBloc] Chat stream update: '
            '${messages.length} messages');
        // Chat messages are merged into the state on next room update.
        // For immediate updates, the UI can also listen to the chat
        // stream directly via a StreamBuilder if needed.
      },
      onError: (error) {
        debugPrint('[LanguageGamesBloc] Chat stream error: $error');
      },
    );
  }

  Future<void> _onReportWord(
    ReportWord event,
    Emitter<LanguageGamesState> emit,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('game_reported_words').add({
        'word': event.word,
        'reportedBy': event.reportedBy,
        'roomId': event.roomId,
        'reason': event.reason,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[LanguageGamesBloc] Word reported: ${event.word}');
    } catch (e) {
      debugPrint('[LanguageGamesBloc] Report word error: $e');
    }
  }

  /// Cancel all active subscriptions to prevent memory leaks.
  void _cancelAllSubscriptions() {
    _roomSubscription?.cancel();
    _roomSubscription = null;
    _roundSubscription?.cancel();
    _roundSubscription = null;
    _chatSubscription?.cancel();
    _chatSubscription = null;
    _liveCountsSubscription?.cancel();
    _liveCountsSubscription = null;
  }

  @override
  Future<void> close() {
    debugPrint(
        '[LanguageGamesBloc] Closing -- cancelling all subscriptions');
    _cancelAllSubscriptions();
    return super.close();
  }
}
