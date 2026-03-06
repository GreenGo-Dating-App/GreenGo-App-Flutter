import 'package:equatable/equatable.dart';

import '../../domain/entities/game_room.dart';
import '../../domain/entities/game_round.dart';
import '../../domain/repositories/language_games_repository.dart';

/// Language Games BLoC States
///
/// Represents every possible UI state for the language games feature.
/// Each state carries all data the UI needs to render -- no hidden fields.
abstract class LanguageGamesState extends Equatable {
  const LanguageGamesState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any action has been taken.
class LanguageGamesInitial extends LanguageGamesState {
  const LanguageGamesInitial();
}

/// Generic loading state (room list loading, joining, creating, etc.).
class LanguageGamesLoading extends LanguageGamesState {
  const LanguageGamesLoading();
}

/// Main lobby showing available rooms and optional live player counts.
///
/// [liveCounts] is a nested map: `{ gameType: { language: playerCount } }`.
/// Example: `{ "wordBomb": { "es": 12, "fr": 5 } }`.
class LanguageGamesLobby extends LanguageGamesState {
  const LanguageGamesLobby({
    required this.availableRooms,
    this.liveCounts,
  });

  final List<GameRoom> availableRooms;
  final Map<String, Map<String, int>>? liveCounts;

  @override
  List<Object?> get props => [availableRooms, liveCounts];
}

/// Player is inside a game room (either waiting in lobby or actively playing).
///
/// The [room] object contains the current game status, players, scores, etc.
/// [currentRound] is populated once the game is in progress.
/// [chatMessages] contains in-game chat history.
class LanguageGamesInRoom extends LanguageGamesState {
  const LanguageGamesInRoom({
    required this.room,
    this.currentRound,
    this.chatMessages,
  });

  final GameRoom room;
  final GameRound? currentRound;
  final List<GameChatMessage>? chatMessages;

  /// Convenience: create a copy with updated fields.
  LanguageGamesInRoom copyWith({
    GameRoom? room,
    GameRound? currentRound,
    List<GameChatMessage>? chatMessages,
  }) {
    return LanguageGamesInRoom(
      room: room ?? this.room,
      currentRound: currentRound ?? this.currentRound,
      chatMessages: chatMessages ?? this.chatMessages,
    );
  }

  @override
  List<Object?> get props => [room, currentRound, chatMessages];
}

/// Player is in the matchmaking queue waiting for a room.
///
/// [estimatedWait] is an optional server-provided estimate in seconds.
class LanguageGamesMatchmaking extends LanguageGamesState {
  const LanguageGamesMatchmaking({
    required this.gameType,
    required this.language,
    this.estimatedWait,
  });

  final GameType gameType;
  final String language;
  final int? estimatedWait;

  @override
  List<Object?> get props => [gameType, language, estimatedWait];
}

/// Game has ended -- showing final results screen.
///
/// [finalScores] maps userId to their final score.
/// [xpEarned] is the XP reward for the current player.
class LanguageGamesFinished extends LanguageGamesState {
  const LanguageGamesFinished({
    required this.room,
    required this.finalScores,
    this.xpEarned = 0,
  });

  final GameRoom room;
  final Map<String, int> finalScores;
  final int xpEarned;

  @override
  List<Object?> get props => [room, finalScores, xpEarned];
}

/// Error state with a human-readable message.
class LanguageGamesError extends LanguageGamesState {
  const LanguageGamesError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
