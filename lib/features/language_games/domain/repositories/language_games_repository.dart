import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/game_player.dart';
import '../entities/game_room.dart';
import '../entities/game_round.dart';

/// Language Games Repository Interface
///
/// Defines operations for multiplayer language learning games
abstract class LanguageGamesRepository {
  /// Create a new game room
  Future<Either<Failure, GameRoom>> createRoom({
    required GameType gameType,
    required String targetLanguage,
    required String hostUserId,
    required String hostDisplayName,
    String? hostPhotoUrl,
    required int maxPlayers,
    int difficulty = 1,
  });

  /// Join an existing game room
  Future<Either<Failure, GameRoom>> joinRoom({
    required String roomId,
    required String userId,
    required String displayName,
    String? photoUrl,
  });

  /// Leave a game room
  Future<Either<Failure, void>> leaveRoom({
    required String roomId,
    required String userId,
  });

  /// Toggle ready status in lobby
  Future<Either<Failure, void>> toggleReady({
    required String roomId,
    required String userId,
  });

  /// Start the game (host only)
  Future<Either<Failure, void>> startGame({
    required String roomId,
  });

  /// Submit an answer for the current round
  Future<Either<Failure, GameAnswer>> submitAnswer({
    required String roomId,
    required String userId,
    required String answer,
  });

  /// Stream real-time game room updates
  Stream<GameRoom> getRoomStream(String roomId);

  /// Stream real-time round updates
  Stream<GameRound?> getCurrentRoundStream(String roomId);

  /// Get available rooms to join
  Future<Either<Failure, List<GameRoom>>> getAvailableRooms({
    String? targetLanguage,
    GameType? gameType,
  });

  /// End the game and calculate final results
  Future<Either<Failure, void>> endGame({
    required String roomId,
  });

  /// Advance to next round
  Future<Either<Failure, void>> advanceRound({
    required String roomId,
  });

  /// Advance to next turn (for turn-based games)
  Future<Either<Failure, void>> advanceTurn({
    required String roomId,
  });

  /// Remove a life from a player
  Future<Either<Failure, void>> removeLife({
    required String roomId,
    required String userId,
  });

  /// Send a chat message in the game room
  Future<Either<Failure, void>> sendChatMessage({
    required String roomId,
    required String userId,
    required String text,
  });

  /// Stream chat messages
  Stream<List<GameChatMessage>> getChatStream(String roomId);

  /// Quick play - find or create a room
  Future<Either<Failure, GameRoom>> quickPlay({
    required GameType gameType,
    required String targetLanguage,
    required String userId,
    required String displayName,
    String? photoUrl,
    int difficulty = 1,
  });

  /// Send a game invite to another user
  Future<Either<Failure, void>> sendGameInvite({
    required String roomId,
    required String invitedUserId,
    required String hostUserId,
    required String hostNickname,
    String? hostPhotoUrl,
    required String gameType,
    required String gameName,
    required String targetLanguage,
  });

  /// Respond to a game invite
  Future<Either<Failure, void>> respondToInvite({
    required String inviteId,
    required bool accepted,
  });

  /// Stream of pending invites for a user
  Stream<List<Map<String, dynamic>>> getInviteStream(String userId);
}

/// Chat message within a game room
class GameChatMessage {
  final String id;
  final String userId;
  final String displayName;
  final String text;
  final DateTime sentAt;
  final bool isSystemMessage;

  const GameChatMessage({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.text,
    required this.sentAt,
    this.isSystemMessage = false,
  });
}
