import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/game_room.dart';
import '../../domain/entities/game_round.dart';
import '../../domain/repositories/language_games_repository.dart';
import '../datasources/language_games_remote_datasource.dart';

/// Language Games Repository Implementation
///
/// Bridges the domain layer with the remote data source.
/// Every datasource call is wrapped in try-catch returning Either<Failure, T>.
/// Stream methods pass through directly from the datasource.
///
/// All game data is static from GameContent -- no AI API calls.
class LanguageGamesRepositoryImpl implements LanguageGamesRepository {
  final LanguageGamesRemoteDataSource remoteDataSource;
  final FirebaseFirestore firestore;

  LanguageGamesRepositoryImpl({
    required this.remoteDataSource,
    required this.firestore,
  });

  // ---------------------------------------------------------------
  //  BASE MEMBERSHIP CHECK
  // ---------------------------------------------------------------

  /// Checks if a user has an active base membership.
  /// Returns true if the user has `hasBaseMembership: true` in Firestore.
  Future<bool> checkBaseMembership(String userId) async {
    try {
      final userDoc =
          await firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        debugPrint('[LanguageGames] checkBaseMembership: '
            'user $userId not found');
        return false;
      }
      final data = userDoc.data() as Map<String, dynamic>? ?? {};
      final hasMembership = data['hasBaseMembership'] as bool? ?? false;
      debugPrint('[LanguageGames] checkBaseMembership: '
          'user=$userId | hasBaseMembership=$hasMembership');
      return hasMembership;
    } catch (e) {
      debugPrint('[LanguageGames] checkBaseMembership ERROR: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------
  //  CREATE ROOM
  // ---------------------------------------------------------------

  @override
  Future<Either<Failure, GameRoom>> createRoom({
    required GameType gameType,
    required String targetLanguage,
    required String hostUserId,
    required String hostDisplayName,
    String? hostPhotoUrl,
    required int maxPlayers,
    int difficulty = 1,
  }) async {
    try {
      final room = await remoteDataSource.createRoom(
        gameType: gameType,
        targetLanguage: targetLanguage,
        hostUserId: hostUserId,
        hostDisplayName: hostDisplayName,
        hostPhotoUrl: hostPhotoUrl,
        maxPlayers: maxPlayers,
        difficulty: difficulty,
      );
      return Right(room);
    } catch (e) {
      debugPrint('[LanguageGamesRepo] createRoom ERROR: $e');
      return Left(ServerFailure('Failed to create room: ${e.toString()}'));
    }
  }

  // ---------------------------------------------------------------
  //  JOIN ROOM
  // ---------------------------------------------------------------

  @override
  Future<Either<Failure, GameRoom>> joinRoom({
    required String roomId,
    required String userId,
    required String displayName,
    String? photoUrl,
  }) async {
    try {
      final room = await remoteDataSource.joinRoom(
        roomId: roomId,
        userId: userId,
        displayName: displayName,
        photoUrl: photoUrl,
      );
      return Right(room);
    } catch (e) {
      debugPrint('[LanguageGamesRepo] joinRoom ERROR: $e');
      return Left(ServerFailure('Failed to join room: ${e.toString()}'));
    }
  }

  // ---------------------------------------------------------------
  //  LEAVE ROOM
  // ---------------------------------------------------------------

  @override
  Future<Either<Failure, void>> leaveRoom({
    required String roomId,
    required String userId,
  }) async {
    try {
      await remoteDataSource.leaveRoom(roomId: roomId, userId: userId);
      return const Right(null);
    } catch (e) {
      debugPrint('[LanguageGamesRepo] leaveRoom ERROR: $e');
      return Left(ServerFailure('Failed to leave room: ${e.toString()}'));
    }
  }

  // ---------------------------------------------------------------
  //  TOGGLE READY
  // ---------------------------------------------------------------

  @override
  Future<Either<Failure, void>> toggleReady({
    required String roomId,
    required String userId,
  }) async {
    try {
      await remoteDataSource.toggleReady(roomId: roomId, userId: userId);
      return const Right(null);
    } catch (e) {
      debugPrint('[LanguageGamesRepo] toggleReady ERROR: $e');
      return Left(
          ServerFailure('Failed to toggle ready: ${e.toString()}'));
    }
  }

  // ---------------------------------------------------------------
  //  START GAME
  // ---------------------------------------------------------------

  @override
  Future<Either<Failure, void>> startGame({
    required String roomId,
  }) async {
    try {
      await remoteDataSource.startGame(roomId);
      return const Right(null);
    } catch (e) {
      debugPrint('[LanguageGamesRepo] startGame ERROR: $e');
      return Left(
          ServerFailure('Failed to start game: ${e.toString()}'));
    }
  }

  // ---------------------------------------------------------------
  //  SUBMIT ANSWER
  // ---------------------------------------------------------------

  @override
  Future<Either<Failure, GameAnswer>> submitAnswer({
    required String roomId,
    required String userId,
    required String answer,
  }) async {
    try {
      final gameAnswer = await remoteDataSource.submitAnswer(
        roomId: roomId,
        userId: userId,
        answer: answer,
      );
      return Right(gameAnswer);
    } catch (e) {
      debugPrint('[LanguageGamesRepo] submitAnswer ERROR: $e');
      return Left(
          ServerFailure('Failed to submit answer: ${e.toString()}'));
    }
  }

  // ---------------------------------------------------------------
  //  STREAMS (pass-through)
  // ---------------------------------------------------------------

  @override
  Stream<GameRoom> getRoomStream(String roomId) {
    return remoteDataSource.getRoomStream(roomId);
  }

  @override
  Stream<GameRound?> getCurrentRoundStream(String roomId) {
    return remoteDataSource.getCurrentRoundStream(roomId);
  }

  @override
  Stream<List<GameChatMessage>> getChatStream(String roomId) {
    return remoteDataSource.getChatStream(roomId);
  }

  // ---------------------------------------------------------------
  //  GET AVAILABLE ROOMS
  // ---------------------------------------------------------------

  @override
  Future<Either<Failure, List<GameRoom>>> getAvailableRooms({
    String? targetLanguage,
    GameType? gameType,
  }) async {
    try {
      final rooms = await remoteDataSource.getAvailableRooms(
        targetLanguage: targetLanguage,
        gameType: gameType,
      );
      return Right(rooms);
    } catch (e) {
      debugPrint('[LanguageGamesRepo] getAvailableRooms ERROR: $e');
      return Left(
          ServerFailure('Failed to get rooms: ${e.toString()}'));
    }
  }

  // ---------------------------------------------------------------
  //  END GAME
  // ---------------------------------------------------------------

  @override
  Future<Either<Failure, void>> endGame({
    required String roomId,
  }) async {
    try {
      await remoteDataSource.endGame(roomId);
      return const Right(null);
    } catch (e) {
      debugPrint('[LanguageGamesRepo] endGame ERROR: $e');
      return Left(ServerFailure('Failed to end game: ${e.toString()}'));
    }
  }

  // ---------------------------------------------------------------
  //  ADVANCE ROUND
  // ---------------------------------------------------------------

  @override
  Future<Either<Failure, void>> advanceRound({
    required String roomId,
  }) async {
    try {
      await remoteDataSource.advanceRound(roomId);
      return const Right(null);
    } catch (e) {
      debugPrint('[LanguageGamesRepo] advanceRound ERROR: $e');
      return Left(
          ServerFailure('Failed to advance round: ${e.toString()}'));
    }
  }

  // ---------------------------------------------------------------
  //  ADVANCE TURN
  // ---------------------------------------------------------------

  @override
  Future<Either<Failure, void>> advanceTurn({
    required String roomId,
  }) async {
    try {
      await remoteDataSource.advanceTurn(roomId);
      return const Right(null);
    } catch (e) {
      debugPrint('[LanguageGamesRepo] advanceTurn ERROR: $e');
      return Left(
          ServerFailure('Failed to advance turn: ${e.toString()}'));
    }
  }

  // ---------------------------------------------------------------
  //  REMOVE LIFE
  // ---------------------------------------------------------------

  @override
  Future<Either<Failure, void>> removeLife({
    required String roomId,
    required String userId,
  }) async {
    try {
      await remoteDataSource.removeLife(roomId: roomId, userId: userId);
      return const Right(null);
    } catch (e) {
      debugPrint('[LanguageGamesRepo] removeLife ERROR: $e');
      return Left(
          ServerFailure('Failed to remove life: ${e.toString()}'));
    }
  }

  // ---------------------------------------------------------------
  //  SEND CHAT MESSAGE
  // ---------------------------------------------------------------

  @override
  Future<Either<Failure, void>> sendChatMessage({
    required String roomId,
    required String userId,
    required String text,
  }) async {
    try {
      // Look up user display name from the room's player data
      String displayName = '';
      try {
        final roomSnapshot =
            await firestore.collection('game_rooms').doc(roomId).get();
        if (roomSnapshot.exists) {
          final data =
              roomSnapshot.data() as Map<String, dynamic>? ?? {};
          final players =
              data['players'] as Map<String, dynamic>? ?? {};
          final playerData =
              players[userId] as Map<String, dynamic>?;
          displayName =
              playerData?['displayName'] as String? ?? '';
        }
      } catch (e) {
        debugPrint('[LanguageGamesRepo] sendChatMessage: '
            'could not resolve displayName: $e');
      }

      await remoteDataSource.sendChatMessage(
        roomId: roomId,
        userId: userId,
        displayName: displayName,
        text: text,
      );
      return const Right(null);
    } catch (e) {
      debugPrint('[LanguageGamesRepo] sendChatMessage ERROR: $e');
      return Left(
          ServerFailure('Failed to send message: ${e.toString()}'));
    }
  }

  // ---------------------------------------------------------------
  //  QUICK PLAY
  // ---------------------------------------------------------------

  @override
  Future<Either<Failure, GameRoom>> quickPlay({
    required GameType gameType,
    required String targetLanguage,
    required String userId,
    required String displayName,
    String? photoUrl,
    int difficulty = 1,
  }) async {
    try {
      final room = await remoteDataSource.quickPlay(
        gameType: gameType,
        targetLanguage: targetLanguage,
        userId: userId,
        displayName: displayName,
        photoUrl: photoUrl,
        difficulty: difficulty,
      );
      return Right(room);
    } catch (e) {
      debugPrint('[LanguageGamesRepo] quickPlay ERROR: $e');
      return Left(ServerFailure('Quick play failed: ${e.toString()}'));
    }
  }

  // ---------------------------------------------------------------
  //  GAME INVITES
  // ---------------------------------------------------------------

  @override
  Future<Either<Failure, void>> sendGameInvite({
    required String roomId,
    required String invitedUserId,
    required String hostUserId,
    required String hostNickname,
    String? hostPhotoUrl,
    required String gameType,
    required String gameName,
    required String targetLanguage,
  }) async {
    try {
      await remoteDataSource.sendGameInvite(
        roomId: roomId,
        invitedUserId: invitedUserId,
        hostUserId: hostUserId,
        hostNickname: hostNickname,
        hostPhotoUrl: hostPhotoUrl,
        gameType: gameType,
        gameName: gameName,
        targetLanguage: targetLanguage,
      );
      return const Right(null);
    } catch (e) {
      debugPrint('[LanguageGamesRepo] sendGameInvite ERROR: $e');
      return Left(ServerFailure('${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> respondToInvite({
    required String inviteId,
    required bool accepted,
  }) async {
    try {
      await remoteDataSource.respondToInvite(
        inviteId: inviteId,
        accepted: accepted,
      );
      return const Right(null);
    } catch (e) {
      debugPrint('[LanguageGamesRepo] respondToInvite ERROR: $e');
      return Left(
          ServerFailure('Failed to respond to invite: ${e.toString()}'));
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> getInviteStream(String userId) {
    return remoteDataSource.getInviteStream(userId);
  }
}
