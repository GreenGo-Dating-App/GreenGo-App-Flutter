import 'package:equatable/equatable.dart';

import '../../domain/entities/game_room.dart';

/// Language Games BLoC Events
///
/// All events that can be dispatched to the LanguageGamesBloc.
/// Each event carries the data needed for its operation explicitly,
/// avoiding hidden state dependencies.
abstract class LanguageGamesEvent extends Equatable {
  const LanguageGamesEvent();

  @override
  List<Object?> get props => [];
}

/// Load available rooms for the lobby browser.
///
/// Optionally filter by [targetLanguage] and/or [gameType].
class LoadAvailableRooms extends LanguageGamesEvent {
  const LoadAvailableRooms({this.targetLanguage, this.gameType});

  final String? targetLanguage;
  final GameType? gameType;

  @override
  List<Object?> get props => [targetLanguage, gameType];
}

/// Create a new game room and become the host.
class CreateRoom extends LanguageGamesEvent {
  const CreateRoom({
    required this.gameType,
    required this.targetLanguage,
    required this.hostUserId,
    required this.hostDisplayName,
    this.hostPhotoUrl,
    this.maxPlayers = 4,
    this.difficulty = 1,
    this.friendGroupId,
    this.totalRounds,
  });

  final GameType gameType;
  final String targetLanguage;
  final String hostUserId;
  final String hostDisplayName;
  final String? hostPhotoUrl;
  final int maxPlayers;
  final int difficulty;
  final String? friendGroupId;
  final int? totalRounds;

  @override
  List<Object?> get props => [
        gameType,
        targetLanguage,
        hostUserId,
        hostDisplayName,
        hostPhotoUrl,
        maxPlayers,
        difficulty,
        friendGroupId,
        totalRounds,
      ];
}

/// Join an existing game room.
class JoinRoom extends LanguageGamesEvent {
  const JoinRoom({
    required this.roomId,
    required this.userId,
    required this.displayName,
    this.photoUrl,
  });

  final String roomId;
  final String userId;
  final String displayName;
  final String? photoUrl;

  @override
  List<Object?> get props => [roomId, userId, displayName, photoUrl];
}

/// Leave a game room.
class LeaveRoom extends LanguageGamesEvent {
  const LeaveRoom({
    required this.roomId,
    required this.userId,
  });

  final String roomId;
  final String userId;

  @override
  List<Object?> get props => [roomId, userId];
}

/// Toggle the player's ready status in the lobby.
class ToggleReady extends LanguageGamesEvent {
  const ToggleReady({
    required this.roomId,
    required this.userId,
  });

  final String roomId;
  final String userId;

  @override
  List<Object?> get props => [roomId, userId];
}

/// Start the game (host-only action).
class StartGame extends LanguageGamesEvent {
  const StartGame({required this.roomId});

  final String roomId;

  @override
  List<Object?> get props => [roomId];
}

/// Submit an answer for the current round.
class SubmitAnswer extends LanguageGamesEvent {
  const SubmitAnswer({
    required this.roomId,
    required this.userId,
    required this.answer,
  });

  final String roomId;
  final String userId;
  final String answer;

  @override
  List<Object?> get props => [roomId, userId, answer];
}

/// Quick play -- find an existing room or create one automatically.
///
/// Emits a matchmaking state while searching, then transitions
/// to an in-room state once a room is found or created.
class QuickPlay extends LanguageGamesEvent {
  const QuickPlay({
    required this.gameType,
    required this.targetLanguage,
    required this.userId,
    required this.displayName,
    this.photoUrl,
    this.difficulty = 1,
  });

  final GameType gameType;
  final String targetLanguage;
  final String userId;
  final String displayName;
  final String? photoUrl;
  final int difficulty;

  @override
  List<Object?> get props => [
        gameType,
        targetLanguage,
        userId,
        displayName,
        photoUrl,
        difficulty,
      ];
}

/// Subscribe to real-time room updates via Firestore stream.
///
/// Each update emits a new LanguageGamesInRoom state.
class ListenToRoom extends LanguageGamesEvent {
  const ListenToRoom({required this.roomId});

  final String roomId;

  @override
  List<Object?> get props => [roomId];
}

/// Subscribe to real-time round updates via Firestore stream.
///
/// Round updates are merged into the current LanguageGamesInRoom state.
class ListenToRound extends LanguageGamesEvent {
  const ListenToRound({required this.roomId});

  final String roomId;

  @override
  List<Object?> get props => [roomId];
}

/// Cancel all active stream subscriptions (room, round, chat, live counts).
class StopListening extends LanguageGamesEvent {
  const StopListening();
}

/// Send a chat message within a game room.
class SendChatMessage extends LanguageGamesEvent {
  const SendChatMessage({
    required this.roomId,
    required this.userId,
    required this.text,
  });

  final String roomId;
  final String userId;
  final String text;

  @override
  List<Object?> get props => [roomId, userId, text];
}

/// Subscribe to live player counts per game type / language.
///
/// Used in the lobby to show how many players are currently active.
class LoadLiveCounts extends LanguageGamesEvent {
  const LoadLiveCounts();
}

/// Advance to the next round (host-only action).
class AdvanceRound extends LanguageGamesEvent {
  const AdvanceRound({required this.roomId});

  final String roomId;

  @override
  List<Object?> get props => [roomId];
}

/// Advance to the next turn in turn-based games (host-only action).
class AdvanceTurn extends LanguageGamesEvent {
  const AdvanceTurn({required this.roomId});

  final String roomId;

  @override
  List<Object?> get props => [roomId];
}

/// End the game and calculate final results.
class EndGame extends LanguageGamesEvent {
  const EndGame({required this.roomId});

  final String roomId;

  @override
  List<Object?> get props => [roomId];
}

/// Send a game invite to another user by nickname.
class SendGameInvite extends LanguageGamesEvent {
  const SendGameInvite({
    required this.roomId,
    required this.invitedUserId,
    required this.hostNickname,
    required this.hostPhotoUrl,
  });

  final String roomId;
  final String invitedUserId;
  final String hostNickname;
  final String? hostPhotoUrl;

  @override
  List<Object?> get props => [roomId, invitedUserId, hostNickname, hostPhotoUrl];
}

/// Respond to a game invite (accept or decline).
class RespondToGameInvite extends LanguageGamesEvent {
  const RespondToGameInvite({
    required this.inviteId,
    required this.accepted,
    this.roomId,
    this.userId,
    this.displayName,
  });

  final String inviteId;
  final bool accepted;
  final String? roomId;
  final String? userId;
  final String? displayName;

  @override
  List<Object?> get props => [inviteId, accepted, roomId, userId, displayName];
}

/// Word Bomb timeout — current player ran out of time.
/// Removes a life and advances the turn atomically.
class WordBombTimeout extends LanguageGamesEvent {
  const WordBombTimeout({
    required this.roomId,
    required this.userId,
  });

  final String roomId;
  final String userId;

  @override
  List<Object?> get props => [roomId, userId];
}

/// Vocabulary Chain timeout — current player ran out of time.
/// Removes a life and advances the turn atomically.
class VocabularyChainTimeout extends LanguageGamesEvent {
  const VocabularyChainTimeout({
    required this.roomId,
    required this.userId,
  });

  final String roomId;
  final String userId;

  @override
  List<Object?> get props => [roomId, userId];
}

/// Language Snaps timeout — current player ran out of time.
/// Just advances the turn (no life loss for memory game).
class SnapTimeout extends LanguageGamesEvent {
  const SnapTimeout({required this.roomId});

  final String roomId;

  @override
  List<Object?> get props => [roomId];
}

/// Language Tapples timeout — current player ran out of time.
/// Removes a life and advances the turn.
class TapplesTimeout extends LanguageGamesEvent {
  const TapplesTimeout({
    required this.roomId,
    required this.userId,
  });

  final String roomId;
  final String userId;

  @override
  List<Object?> get props => [roomId, userId];
}

/// Submit a clue for Picture Guess game (describer only).
class SubmitClue extends LanguageGamesEvent {
  const SubmitClue({
    required this.roomId,
    required this.clue,
  });

  final String roomId;
  final String clue;

  @override
  List<Object?> get props => [roomId, clue];
}

/// Report a word as incorrect or inappropriate.
class ReportWord extends LanguageGamesEvent {
  const ReportWord({
    required this.word,
    required this.reportedBy,
    required this.roomId,
    required this.reason,
  });

  final String word;
  final String reportedBy;
  final String roomId;
  final String reason;

  @override
  List<Object?> get props => [word, reportedBy, roomId, reason];
}
