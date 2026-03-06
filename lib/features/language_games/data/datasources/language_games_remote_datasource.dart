import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/game_room.dart';
import '../../domain/entities/game_round.dart';
import '../../domain/repositories/language_games_repository.dart';
import '../models/game_room_model.dart';
import '../models/game_round_model.dart';
import '../content/game_content.dart';

/// Language Games Remote Data Source
///
/// Handles all Firestore operations for multiplayer language games.
///
/// Firestore Collections:
///   - game_rooms/{roomId}              -- game room documents
///   - game_rooms/{roomId}/rounds/{n}   -- round documents
///   - game_rooms/{roomId}/chat/{id}    -- chat messages
///   - game_matchmaking/{gameType}_{language}_{difficulty} -- matchmaking queue
///   - game_stats/live                  -- live player counts per game type
abstract class LanguageGamesRemoteDataSource {
  Future<GameRoomModel> createRoom({
    required GameType gameType,
    required String targetLanguage,
    required String hostUserId,
    required String hostDisplayName,
    String? hostPhotoUrl,
    required int maxPlayers,
    int difficulty,
  });

  Future<GameRoomModel> joinRoom({
    required String roomId,
    required String userId,
    required String displayName,
    String? photoUrl,
  });

  Future<void> leaveRoom({
    required String roomId,
    required String userId,
  });

  Future<void> toggleReady({
    required String roomId,
    required String userId,
  });

  Future<void> startGame(String roomId);

  Future<GameAnswer> submitAnswer({
    required String roomId,
    required String userId,
    required String answer,
  });

  Stream<GameRoomModel> getRoomStream(String roomId);

  Stream<GameRoundModel?> getCurrentRoundStream(String roomId);

  Future<List<GameRoomModel>> getAvailableRooms({
    String? targetLanguage,
    GameType? gameType,
  });

  Future<void> endGame(String roomId);

  Future<void> advanceRound(String roomId);

  Future<void> advanceTurn(String roomId);

  Future<void> removeLife({
    required String roomId,
    required String userId,
  });

  Future<void> sendChatMessage({
    required String roomId,
    required String userId,
    required String displayName,
    required String text,
  });

  Stream<List<GameChatMessage>> getChatStream(String roomId);

  /// Quick play -- find or create a room via the matchmaking queue
  Future<GameRoomModel> quickPlay({
    required GameType gameType,
    required String targetLanguage,
    required String userId,
    required String displayName,
    String? photoUrl,
    int difficulty,
  });

  /// Create a private friend-group room with an invite code
  Future<GameRoomModel> createFriendGroup({
    required GameType gameType,
    required String targetLanguage,
    required String hostUserId,
    required String hostDisplayName,
    String? hostPhotoUrl,
    required int maxPlayers,
    int difficulty,
  });

  /// Join a room via its 6-character invite code
  Future<GameRoomModel> joinByInviteCode({
    required String inviteCode,
    required String userId,
    required String displayName,
    String? photoUrl,
  });

  /// Increment / decrement live player counters atomically
  Future<void> updateLiveCount({
    required GameType gameType,
    required String field, // 'waiting' or 'playing'
    required int delta, // +1 or -1
  });

  /// Real-time stream of {gameType: {waiting: X, playing: Y}}
  Stream<Map<String, Map<String, int>>> getLiveCountsStream();

  /// Send a game invite to another user
  Future<void> sendGameInvite({
    required String roomId,
    required String invitedUserId,
    required String hostUserId,
    required String hostNickname,
    String? hostPhotoUrl,
    required String gameType,
    required String gameName,
    required String targetLanguage,
  });

  /// Respond to a game invite (accept or decline)
  Future<void> respondToInvite({
    required String inviteId,
    required bool accepted,
  });

  /// Stream of pending invites for a user
  Stream<List<Map<String, dynamic>>> getInviteStream(String userId);
}

// ================================================================
//  IMPLEMENTATION
// ================================================================

class LanguageGamesRemoteDataSourceImpl
    implements LanguageGamesRemoteDataSource {
  final FirebaseFirestore firestore;

  LanguageGamesRemoteDataSourceImpl({required this.firestore});

  // ---------------------------------------------------------------
  //  Collection references
  // ---------------------------------------------------------------

  CollectionReference get _roomsCollection =>
      firestore.collection('game_rooms');

  CollectionReference get _matchmakingCollection =>
      firestore.collection('game_matchmaking');

  DocumentReference get _liveStatsDoc =>
      firestore.collection('game_stats').doc('live');

  // ---------------------------------------------------------------
  //  XP Constants
  // ---------------------------------------------------------------

  static const int _baseXp = 25;
  static const int _winnerBonusXp = 50;
  static const int _streakBonusXp = 10;
  static const int _perfectRoundBonusXp = 25;

  // ---------------------------------------------------------------
  //  CREATE ROOM
  // ---------------------------------------------------------------

  @override
  Future<GameRoomModel> createRoom({
    required GameType gameType,
    required String targetLanguage,
    required String hostUserId,
    required String hostDisplayName,
    String? hostPhotoUrl,
    required int maxPlayers,
    int difficulty = 5,
  }) async {
    debugPrint('[LanguageGames] createRoom: $gameType | lang=$targetLanguage '
        '| host=$hostUserId | max=$maxPlayers | difficulty=$difficulty');

    final docRef = _roomsCollection.doc();
    final int totalRounds = _getTotalRounds(gameType);
    final int turnDuration = _getTurnDuration(gameType, difficulty);
    final int defaultLives = _getDefaultLives(gameType);
    final String inviteCode = _generateInviteCode();

    final roomData = {
      'gameType': gameType.name,
      'targetLanguage': targetLanguage,
      'hostUserId': hostUserId,
      'maxPlayers': maxPlayers,
      'status': GameStatus.waiting.name,
      'createdAt': FieldValue.serverTimestamp(),
      'currentRound': 0,
      'totalRounds': totalRounds,
      'currentTurnUserId': null,
      'scores': {hostUserId: 0},
      'lives': {hostUserId: defaultLives},
      'usedWords': <String>[],
      'currentPrompt': null,
      'turnStartedAt': null,
      'turnDurationSeconds': turnDuration,
      'winnerId': null,
      'currentDescriberId': null,
      'roundTheme': null,
      'difficulty': difficulty.clamp(1, 10),
      'inviteCode': inviteCode,
      'friendGroupId': null,
      'players': {
        hostUserId: {
          'displayName': hostDisplayName,
          'photoUrl': hostPhotoUrl,
          'score': 0,
          'lives': defaultLives,
          'isReady': false,
          'isConnected': true,
          'languages': <String>[],
        },
      },
    };

    await docRef.set(roomData);

    // Update live count -- one player waiting
    await updateLiveCount(
      gameType: gameType,
      field: 'waiting',
      delta: 1,
    );

    final snapshot = await docRef.get();
    debugPrint('[LanguageGames] createRoom: created ${docRef.id}');
    return GameRoomModel.fromFirestore(snapshot);
  }

  // ---------------------------------------------------------------
  //  JOIN ROOM
  // ---------------------------------------------------------------

  @override
  Future<GameRoomModel> joinRoom({
    required String roomId,
    required String userId,
    required String displayName,
    String? photoUrl,
  }) async {
    debugPrint('[LanguageGames] joinRoom: room=$roomId | user=$userId');

    final docRef = _roomsCollection.doc(roomId);

    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) throw Exception('Room not found');

      final room = GameRoomModel.fromFirestore(snapshot);
      if (room.isFull) throw Exception('Room is full');
      if (room.status != GameStatus.waiting) {
        throw Exception('Game already started');
      }

      final defaultLives = _getDefaultLives(room.gameType);

      transaction.update(docRef, {
        'players.$userId': {
          'displayName': displayName,
          'photoUrl': photoUrl,
          'score': 0,
          'lives': defaultLives,
          'isReady': false,
          'isConnected': true,
          'languages': <String>[],
        },
        'scores.$userId': 0,
        'lives.$userId': defaultLives,
      });
    });

    // Update live count -- one more player waiting
    final snapshot = await docRef.get();
    final room = GameRoomModel.fromFirestore(snapshot);
    await updateLiveCount(
      gameType: room.gameType,
      field: 'waiting',
      delta: 1,
    );

    debugPrint('[LanguageGames] joinRoom: user $userId joined $roomId');
    return room;
  }

  // ---------------------------------------------------------------
  //  LEAVE ROOM
  // ---------------------------------------------------------------

  @override
  Future<void> leaveRoom({
    required String roomId,
    required String userId,
  }) async {
    debugPrint('[LanguageGames] leaveRoom: room=$roomId | user=$userId');

    final docRef = _roomsCollection.doc(roomId);

    GameType? gameType;
    GameStatus? previousStatus;

    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final room = GameRoomModel.fromFirestore(snapshot);
      gameType = room.gameType;
      previousStatus = room.status;

      // If host leaves and game hasn't started, delete room
      if (room.hostUserId == userId && room.status == GameStatus.waiting) {
        transaction.delete(docRef);

        // Also clean up matchmaking queue entry if any
        _cleanupMatchmaking(room);
        return;
      }

      // If host leaves during game, assign new host
      if (room.hostUserId == userId && room.status == GameStatus.inProgress) {
        final remainingPlayers =
            room.players.where((p) => p.userId != userId).toList();
        if (remainingPlayers.isNotEmpty) {
          transaction.update(docRef, {
            'hostUserId': remainingPlayers.first.userId,
          });
          debugPrint('[LanguageGames] leaveRoom: new host = '
              '${remainingPlayers.first.userId}');
        }
      }

      // Remove player from maps
      transaction.update(docRef, {
        'players.$userId': FieldValue.delete(),
        'scores.$userId': FieldValue.delete(),
        'lives.$userId': FieldValue.delete(),
      });

      // If only one player left in an active game, end it
      if (room.players.length <= 2 && room.status == GameStatus.inProgress) {
        final remainingPlayer =
            room.players.firstWhere((p) => p.userId != userId);
        transaction.update(docRef, {
          'status': GameStatus.finished.name,
          'winnerId': remainingPlayer.userId,
        });
      }
    });

    // Decrement live count
    if (gameType != null) {
      final field = previousStatus == GameStatus.inProgress
          ? 'playing'
          : 'waiting';
      await updateLiveCount(
        gameType: gameType!,
        field: field,
        delta: -1,
      );
    }

    debugPrint('[LanguageGames] leaveRoom: user $userId left $roomId');
  }

  // ---------------------------------------------------------------
  //  TOGGLE READY
  // ---------------------------------------------------------------

  @override
  Future<void> toggleReady({
    required String roomId,
    required String userId,
  }) async {
    debugPrint('[LanguageGames] toggleReady: room=$roomId | user=$userId');

    final docRef = _roomsCollection.doc(roomId);
    final snapshot = await docRef.get();
    if (!snapshot.exists) return;

    final room = GameRoomModel.fromFirestore(snapshot);
    final player = room.getPlayer(userId);
    if (player == null) return;

    await docRef.update({
      'players.$userId.isReady': !player.isReady,
    });
  }

  // ---------------------------------------------------------------
  //  START GAME
  // ---------------------------------------------------------------

  @override
  Future<void> startGame(String roomId) async {
    debugPrint('[LanguageGames] startGame: room=$roomId');

    final docRef = _roomsCollection.doc(roomId);

    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) throw Exception('Room not found');

      final room = GameRoomModel.fromFirestore(snapshot);
      if (!room.allPlayersReady) {
        throw Exception('Not all players are ready');
      }

      final difficulty = _getRoomDifficulty(snapshot);

      // Generate first prompt based on difficulty
      final firstPrompt = _generatePrompt(
        room.gameType,
        room.targetLanguage,
        difficulty,
      );
      final firstTurnPlayer = room.players.first.userId;
      final theme = room.gameType == GameType.vocabularyChain
          ? GameContent.getRandomTheme()
          : null;

      final updates = <String, dynamic>{
        'status': GameStatus.starting.name,
        'currentRound': 1,
        'currentPrompt': firstPrompt,
        'currentTurnUserId': firstTurnPlayer,
        'turnStartedAt': FieldValue.serverTimestamp(),
        'roundTheme': theme,
      };

      // For picture guess, set first describer
      if (room.gameType == GameType.pictureGuess) {
        updates['currentDescriberId'] = firstTurnPlayer;
      }

      // Create first round document
      final roundRef = docRef.collection('rounds').doc('1');
      transaction.set(roundRef, {
        'roundNumber': 1,
        'prompt': firstPrompt,
        'correctAnswer': _getCorrectAnswer(
          room.gameType,
          room.targetLanguage,
          firstPrompt,
        ),
        'options': _generateOptions(
          room.gameType,
          room.targetLanguage,
          firstPrompt,
        ),
        'playerAnswers': {},
        'startedAt': FieldValue.serverTimestamp(),
        'durationSeconds': room.turnDurationSeconds,
        'winnerId': null,
      });

      transaction.update(docRef, updates);
    });

    // Remove from matchmaking queue when game starts
    final snapshot = await docRef.get();
    if (snapshot.exists) {
      final room = GameRoomModel.fromFirestore(snapshot);
      await _removeFromMatchmaking(room);

      // Shift live counts from waiting -> playing for all players
      final playerCount = room.players.length;
      await updateLiveCount(
        gameType: room.gameType,
        field: 'waiting',
        delta: -playerCount,
      );
      await updateLiveCount(
        gameType: room.gameType,
        field: 'playing',
        delta: playerCount,
      );
    }

    // Brief delay then mark as in progress
    await Future.delayed(const Duration(seconds: 3));
    await docRef.update({'status': GameStatus.inProgress.name});

    debugPrint('[LanguageGames] startGame: game started in $roomId');
  }

  // ---------------------------------------------------------------
  //  SUBMIT ANSWER (with speed + difficulty scoring)
  // ---------------------------------------------------------------

  @override
  Future<GameAnswer> submitAnswer({
    required String roomId,
    required String userId,
    required String answer,
  }) async {
    debugPrint('[LanguageGames] submitAnswer: room=$roomId | user=$userId '
        '| answer=$answer');

    final docRef = _roomsCollection.doc(roomId);
    final snapshot = await docRef.get();
    if (!snapshot.exists) throw Exception('Room not found');

    final room = GameRoomModel.fromFirestore(snapshot);
    final difficulty = _getRoomDifficulty(snapshot);
    final roundRef =
        docRef.collection('rounds').doc('${room.currentRound}');
    final roundSnapshot = await roundRef.get();

    bool isCorrect = false;
    int points = 0;

    // Base points per game type (before multipliers)
    switch (room.gameType) {
      case GameType.wordBomb:
        isCorrect = GameContent.isValidWordBombWord(
          answer,
          room.currentPrompt ?? '',
          room.targetLanguage,
        );
        if (isCorrect && !room.usedWords.contains(answer.toLowerCase())) {
          points = 10;
          await docRef.update({
            'usedWords': FieldValue.arrayUnion([answer.toLowerCase()]),
          });
        } else {
          isCorrect = false;
        }
        break;

      case GameType.translationRace:
        if (roundSnapshot.exists) {
          final round = GameRoundModel.fromFirestore(roundSnapshot);
          final result = GameContent.checkTranslation(
            answer,
            round.correctAnswer ?? '',
          );
          isCorrect = result.isExact || result.isClose;

          // Speed-based scoring: first correct gets most points
          final correctCount = round.playerAnswers.values
              .where((a) => a.isCorrect)
              .length;

          if (result.isExact) {
            points = correctCount == 0 ? 3 : (correctCount == 1 ? 2 : 1);
          } else if (result.isClose) {
            final fullPoints =
                correctCount == 0 ? 3 : (correctCount == 1 ? 2 : 1);
            points = (fullPoints / 2).ceil();
          }
        }
        break;

      case GameType.pictureGuess:
        if (roundSnapshot.exists) {
          final round = GameRoundModel.fromFirestore(roundSnapshot);
          final result = GameContent.checkTranslation(
            answer,
            round.correctAnswer ?? '',
          );
          isCorrect = result.isExact || result.isClose;
          if (isCorrect) points = 10;
        }
        break;

      case GameType.grammarDuel:
        if (roundSnapshot.exists) {
          final round = GameRoundModel.fromFirestore(roundSnapshot);
          // Compare answer text directly (screen sends option text, not index)
          final correctAnswer = round.correctAnswer ?? '';
          // Support both: text comparison (new) and index comparison (legacy)
          final correctIdx = int.tryParse(correctAnswer);
          if (correctIdx != null) {
            // Legacy: correctAnswer is an index — compare with options list
            final options = round.options;
            isCorrect = correctIdx >= 0 &&
                correctIdx < options.length &&
                answer.toLowerCase().trim() ==
                    options[correctIdx].toLowerCase().trim();
          } else {
            // New: correctAnswer is text — direct comparison
            isCorrect = answer.toLowerCase().trim() ==
                correctAnswer.toLowerCase().trim();
          }
          if (isCorrect) points = 10;
        }
        break;

      case GameType.vocabularyChain:
        final lastWord =
            room.usedWords.isNotEmpty ? room.usedWords.last : '';
        final lastLetter =
            lastWord.isNotEmpty ? GameContent.getLastLetter(lastWord) : '';
        isCorrect = GameContent.isValidChainWord(
          answer,
          lastLetter,
          room.targetLanguage,
          room.roundTheme ?? 'animals',
          room.usedWords,
        );
        if (isCorrect) {
          points = 10;
          await docRef.update({
            'usedWords': FieldValue.arrayUnion([answer.toLowerCase()]),
          });
        }
        break;

      case GameType.languageSnaps:
        // Snaps matching handled client-side; server validates pairs
        isCorrect = true;
        points = 5;
        break;

      case GameType.languageTapples:
        // answer format: "LETTER:word" from game_play_screen
        final tapplesWord = answer.contains(':')
            ? answer.substring(answer.indexOf(':') + 1)
            : answer;
        final tapplesLetter = answer.contains(':')
            ? answer.substring(0, answer.indexOf(':'))
            : (room.currentPrompt ?? 'A');
        isCorrect = GameContent.isValidTapplesWord(
          tapplesWord,
          room.targetLanguage,
          room.roundTheme ?? 'Animals',
          tapplesLetter,
        );
        if (isCorrect && !room.usedWords.contains(tapplesWord.toLowerCase())) {
          points = 10;
          await docRef.update({
            'usedWords': FieldValue.arrayUnion([tapplesWord.toLowerCase()]),
          });
        } else {
          isCorrect = false;
        }
        break;

      case GameType.categories:
        // Categories answers validated client-side (scoring: unique=10, shared=5)
        isCorrect = answer.trim().isNotEmpty;
        points = isCorrect ? 10 : 0;
        break;
    }

    // Apply speed bonus for correct answers (faster = more points)
    if (isCorrect && points > 0 && roundSnapshot.exists) {
      final roundData =
          roundSnapshot.data() as Map<String, dynamic>? ?? {};
      final startedAt =
          (roundData['startedAt'] as Timestamp?)?.toDate();
      if (startedAt != null) {
        final elapsedMs =
            DateTime.now().difference(startedAt).inMilliseconds;
        final durationMs = room.turnDurationSeconds * 1000;
        // Speed bonus: up to 50% extra points if answered in first quarter
        if (elapsedMs < durationMs ~/ 4) {
          points = (points * 1.5).round();
        } else if (elapsedMs < durationMs ~/ 2) {
          points = (points * 1.25).round();
        }
      }
    }

    // Apply difficulty multiplier: difficulty * 5 / 10 as a multiplier boost
    // e.g. difficulty 10 => points * 1.5, difficulty 1 => points * 1.05
    if (isCorrect && points > 0) {
      final difficultyBonus = (difficulty * 5) / 100.0;
      points = (points * (1.0 + difficultyBonus)).round();
    }

    final gameAnswer = GameAnswer(
      userId: userId,
      answer: answer,
      answeredAt: DateTime.now(),
      isCorrect: isCorrect,
      pointsEarned: points,
    );

    // Record the answer in the round document
    await roundRef.update({
      'playerAnswers.$userId': {
        'answer': answer,
        'answeredAt': Timestamp.now(),
        'isCorrect': isCorrect,
        'pointsEarned': points,
      },
    });

    // Update player score
    if (points > 0) {
      await docRef.update({
        'scores.$userId': FieldValue.increment(points),
        'players.$userId.score': FieldValue.increment(points),
      });
    }

    debugPrint('[LanguageGames] submitAnswer: correct=$isCorrect '
        '| points=$points | difficulty=$difficulty');

    return gameAnswer;
  }

  // ---------------------------------------------------------------
  //  ROOM STREAM
  // ---------------------------------------------------------------

  @override
  Stream<GameRoomModel> getRoomStream(String roomId) {
    debugPrint('[LanguageGames] getRoomStream: room=$roomId');
    return _roomsCollection.doc(roomId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        throw Exception('Room not found');
      }
      return GameRoomModel.fromFirestore(snapshot);
    });
  }

  // ---------------------------------------------------------------
  //  CURRENT ROUND STREAM
  // ---------------------------------------------------------------

  @override
  Stream<GameRoundModel?> getCurrentRoundStream(String roomId) {
    debugPrint('[LanguageGames] getCurrentRoundStream: room=$roomId');
    return _roomsCollection
        .doc(roomId)
        .snapshots()
        .asyncMap((roomSnapshot) async {
      if (!roomSnapshot.exists) return null;
      final room = GameRoomModel.fromFirestore(roomSnapshot);
      if (room.currentRound <= 0) return null;

      final roundSnapshot = await _roomsCollection
          .doc(roomId)
          .collection('rounds')
          .doc('${room.currentRound}')
          .get();

      if (!roundSnapshot.exists) return null;
      return GameRoundModel.fromFirestore(roundSnapshot);
    });
  }

  // ---------------------------------------------------------------
  //  GET AVAILABLE ROOMS
  // ---------------------------------------------------------------

  @override
  Future<List<GameRoomModel>> getAvailableRooms({
    String? targetLanguage,
    GameType? gameType,
  }) async {
    debugPrint('[LanguageGames] getAvailableRooms: '
        'lang=$targetLanguage | type=$gameType');

    try {
      // Two separate queries to avoid compound index / whereIn + orderBy issues.
      // Fetch waiting rooms (joinable) and inProgress rooms (for live counts).
      final waitingSnapshot = await _roomsCollection
          .where('status', isEqualTo: 'waiting')
          .limit(50)
          .get();

      final playingSnapshot = await _roomsCollection
          .where('status', isEqualTo: 'inProgress')
          .limit(50)
          .get();

      var rooms = [
        ...waitingSnapshot.docs.map((doc) => GameRoomModel.fromFirestore(doc)),
        ...playingSnapshot.docs.map((doc) => GameRoomModel.fromFirestore(doc)),
      ];

      // Client-side filtering (avoids composite index requirement)
      if (targetLanguage != null) {
        rooms = rooms
            .where((r) => r.targetLanguage == targetLanguage)
            .toList();
      }
      if (gameType != null) {
        rooms = rooms
            .where((r) => r.gameType == gameType)
            .toList();
      }

      // Sort by creation date, most recent first
      rooms.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Limit to 20
      if (rooms.length > 20) {
        rooms = rooms.sublist(0, 20);
      }

      debugPrint('[LanguageGames] getAvailableRooms: found ${rooms.length}');
      return rooms;
    } catch (e) {
      // Collection may not exist yet — that's fine, return empty list
      debugPrint('[LanguageGames] getAvailableRooms error (likely no collection yet): $e');
      return [];
    }
  }

  // ---------------------------------------------------------------
  //  END GAME (with XP reward calculation)
  // ---------------------------------------------------------------

  @override
  Future<void> endGame(String roomId) async {
    debugPrint('[LanguageGames] endGame: room=$roomId');

    final docRef = _roomsCollection.doc(roomId);
    final snapshot = await docRef.get();
    if (!snapshot.exists) return;

    final room = GameRoomModel.fromFirestore(snapshot);
    final difficulty = _getRoomDifficulty(snapshot);
    final sortedScores = room.sortedScores;
    final winnerId =
        sortedScores.isNotEmpty ? sortedScores.first.key : null;

    // Calculate XP rewards per player
    final xpRewards = <String, int>{};
    for (final player in room.players) {
      int xp = _baseXp;

      // Winner bonus
      if (player.userId == winnerId) {
        xp += _winnerBonusXp;
      }

      // Difficulty bonus: difficulty * 5
      xp += difficulty * 5;

      // Streak bonus: check consecutive correct answers
      final streakBonus = await _calculateStreakBonus(
        roomId,
        player.userId,
        room.currentRound,
      );
      xp += streakBonus;

      // Perfect round bonus
      final perfectBonus = await _calculatePerfectRoundBonus(
        roomId,
        player.userId,
        room.currentRound,
      );
      xp += perfectBonus;

      xpRewards[player.userId] = xp;
    }

    // Update room with final state and XP
    await docRef.update({
      'status': GameStatus.finished.name,
      'winnerId': winnerId,
      'xpRewards': xpRewards,
    });

    // Shift live counts from playing -> 0
    final playerCount = room.players.length;
    await updateLiveCount(
      gameType: room.gameType,
      field: 'playing',
      delta: -playerCount,
    );

    debugPrint('[LanguageGames] endGame: winner=$winnerId '
        '| xpRewards=$xpRewards');
  }

  // ---------------------------------------------------------------
  //  ADVANCE ROUND
  // ---------------------------------------------------------------

  @override
  Future<void> advanceRound(String roomId) async {
    debugPrint('[LanguageGames] advanceRound: room=$roomId');

    final docRef = _roomsCollection.doc(roomId);

    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final room = GameRoomModel.fromFirestore(snapshot);
      final difficulty = _getRoomDifficulty(snapshot);
      final nextRound = room.currentRound + 1;

      if (nextRound > room.totalRounds) {
        // Game over
        final sortedScores = room.sortedScores;
        final winnerId =
            sortedScores.isNotEmpty ? sortedScores.first.key : null;
        transaction.update(docRef, {
          'status': GameStatus.finished.name,
          'winnerId': winnerId,
        });
        debugPrint('[LanguageGames] advanceRound: game over (round limit)');
        return;
      }

      final nextPrompt = _generatePrompt(
        room.gameType,
        room.targetLanguage,
        difficulty,
      );
      final nextTheme = room.gameType == GameType.vocabularyChain
          ? GameContent.getRandomTheme()
          : room.roundTheme;

      // Rotate turns
      final playerIds = room.players.map((p) => p.userId).toList();
      final currentIdx =
          playerIds.indexOf(room.currentTurnUserId ?? '');
      final nextTurnIdx = (currentIdx + 1) % playerIds.length;
      final nextTurnUserId = playerIds[nextTurnIdx];

      // Create round document
      final roundRef = docRef.collection('rounds').doc('$nextRound');
      transaction.set(roundRef, {
        'roundNumber': nextRound,
        'prompt': nextPrompt,
        'correctAnswer': _getCorrectAnswer(
          room.gameType,
          room.targetLanguage,
          nextPrompt,
        ),
        'options': _generateOptions(
          room.gameType,
          room.targetLanguage,
          nextPrompt,
        ),
        'playerAnswers': {},
        'startedAt': FieldValue.serverTimestamp(),
        'durationSeconds': room.turnDurationSeconds,
        'winnerId': null,
      });

      transaction.update(docRef, {
        'currentRound': nextRound,
        'currentPrompt': nextPrompt,
        'currentTurnUserId': nextTurnUserId,
        'turnStartedAt': FieldValue.serverTimestamp(),
        'roundTheme': nextTheme,
        if (room.gameType == GameType.pictureGuess)
          'currentDescriberId': nextTurnUserId,
      });
    });

    debugPrint('[LanguageGames] advanceRound: done');
  }

  // ---------------------------------------------------------------
  //  ADVANCE TURN
  // ---------------------------------------------------------------

  @override
  Future<void> advanceTurn(String roomId) async {
    debugPrint('[LanguageGames] advanceTurn: room=$roomId');

    final docRef = _roomsCollection.doc(roomId);

    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final room = GameRoomModel.fromFirestore(snapshot);

      // Get alive players for turn-based games
      List<String> eligiblePlayerIds;
      if (room.gameType == GameType.wordBomb ||
          room.gameType == GameType.vocabularyChain) {
        eligiblePlayerIds =
            room.alivePlayers.map((p) => p.userId).toList();
      } else {
        eligiblePlayerIds =
            room.players.map((p) => p.userId).toList();
      }

      if (eligiblePlayerIds.length <= 1) {
        // Game over -- last player wins
        final winnerId = eligiblePlayerIds.isNotEmpty
            ? eligiblePlayerIds.first
            : null;
        transaction.update(docRef, {
          'status': GameStatus.finished.name,
          'winnerId': winnerId,
        });
        debugPrint(
            '[LanguageGames] advanceTurn: game over, winner=$winnerId');
        return;
      }

      final currentIdx =
          eligiblePlayerIds.indexOf(room.currentTurnUserId ?? '');
      final nextIdx = (currentIdx + 1) % eligiblePlayerIds.length;

      // For Word Bomb, generate new prompt occasionally
      String? newPrompt;
      if (room.gameType == GameType.wordBomb) {
        newPrompt =
            GameContent.getRandomWordBombPrompt(room.targetLanguage);
      }

      transaction.update(docRef, {
        'currentTurnUserId': eligiblePlayerIds[nextIdx],
        'turnStartedAt': FieldValue.serverTimestamp(),
        if (newPrompt != null) 'currentPrompt': newPrompt,
      });
    });
  }

  // ---------------------------------------------------------------
  //  REMOVE LIFE
  // ---------------------------------------------------------------

  @override
  Future<void> removeLife({
    required String roomId,
    required String userId,
  }) async {
    debugPrint('[LanguageGames] removeLife: room=$roomId | user=$userId');

    final docRef = _roomsCollection.doc(roomId);

    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final room = GameRoomModel.fromFirestore(snapshot);
      final currentLives = room.lives[userId] ?? 0;
      final newLives = (currentLives - 1).clamp(0, 3);

      transaction.update(docRef, {
        'lives.$userId': newLives,
        'players.$userId.lives': newLives,
      });

      // Check if game should end (only one player left alive)
      if (newLives <= 0) {
        final alivePlayers = room.players
            .where((p) =>
                p.userId != userId &&
                (room.lives[p.userId] ?? 0) > 0)
            .toList();

        if (alivePlayers.length <= 1) {
          final winnerId = alivePlayers.isNotEmpty
              ? alivePlayers.first.userId
              : null;
          transaction.update(docRef, {
            'status': GameStatus.finished.name,
            'winnerId': winnerId,
          });
          debugPrint('[LanguageGames] removeLife: game over, '
              'winner=$winnerId');
        }
      }
    });
  }

  // ---------------------------------------------------------------
  //  CHAT
  // ---------------------------------------------------------------

  @override
  Future<void> sendChatMessage({
    required String roomId,
    required String userId,
    required String displayName,
    required String text,
  }) async {
    debugPrint('[LanguageGames] sendChatMessage: room=$roomId | '
        'user=$userId | text=$text');

    await _roomsCollection.doc(roomId).collection('chat').add({
      'userId': userId,
      'displayName': displayName,
      'text': text,
      'sentAt': FieldValue.serverTimestamp(),
      'isSystemMessage': false,
    });
  }

  @override
  Stream<List<GameChatMessage>> getChatStream(String roomId) {
    debugPrint('[LanguageGames] getChatStream: room=$roomId');
    return _roomsCollection
        .doc(roomId)
        .collection('chat')
        .orderBy('sentAt', descending: false)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return GameChatMessage(
          id: doc.id,
          userId: data['userId'] as String? ?? '',
          displayName: data['displayName'] as String? ?? '',
          text: data['text'] as String? ?? '',
          sentAt:
              (data['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isSystemMessage:
              data['isSystemMessage'] as bool? ?? false,
        );
      }).toList();
    });
  }

  // ---------------------------------------------------------------
  //  QUICK PLAY (matchmaking queue)
  // ---------------------------------------------------------------

  @override
  Future<GameRoomModel> quickPlay({
    required GameType gameType,
    required String targetLanguage,
    required String userId,
    required String displayName,
    String? photoUrl,
    int difficulty = 5,
  }) async {
    debugPrint('[LanguageGames] quickPlay: $gameType | lang=$targetLanguage '
        '| user=$userId | difficulty=$difficulty');

    final clampedDifficulty = difficulty.clamp(1, 10);
    final queueKey =
        '${gameType.name}_${targetLanguage}_$clampedDifficulty';
    final queueRef = _matchmakingCollection.doc(queueKey);

    // Check matchmaking queue for an existing room
    final queueSnapshot = await queueRef.get();
    if (queueSnapshot.exists) {
      final queueData =
          queueSnapshot.data() as Map<String, dynamic>? ?? {};
      final roomId = queueData['roomId'] as String?;

      if (roomId != null) {
        // Verify the room still exists and has space
        final roomSnapshot = await _roomsCollection.doc(roomId).get();
        if (roomSnapshot.exists) {
          final room = GameRoomModel.fromFirestore(roomSnapshot);
          if (!room.isFull && room.status == GameStatus.waiting) {
            debugPrint('[LanguageGames] quickPlay: joining existing '
                'room $roomId from queue');
            final joinedRoom = await joinRoom(
              roomId: roomId,
              userId: userId,
              displayName: displayName,
              photoUrl: photoUrl,
            );

            // If room is now full, remove from queue
            if (joinedRoom.isFull) {
              await queueRef.delete();
              debugPrint('[LanguageGames] quickPlay: room full, '
                  'removed from queue');
            }

            return joinedRoom;
          } else {
            // Room is stale -- remove from queue and fall through
            await queueRef.delete();
            debugPrint('[LanguageGames] quickPlay: stale room in queue, '
                'removing');
          }
        } else {
          // Room was deleted -- clean up queue
          await queueRef.delete();
        }
      }
    }

    // No matching room found -- create a new one
    final newRoom = await createRoom(
      gameType: gameType,
      targetLanguage: targetLanguage,
      hostUserId: userId,
      hostDisplayName: displayName,
      hostPhotoUrl: photoUrl,
      maxPlayers: gameType.maxPlayers,
      difficulty: clampedDifficulty,
    );

    // Add to matchmaking queue
    await queueRef.set({
      'roomId': newRoom.id,
      'gameType': gameType.name,
      'targetLanguage': targetLanguage,
      'difficulty': clampedDifficulty,
      'createdAt': FieldValue.serverTimestamp(),
      'hostUserId': userId,
    });

    debugPrint('[LanguageGames] quickPlay: created room ${newRoom.id} '
        'and added to queue');
    return newRoom;
  }

  // ---------------------------------------------------------------
  //  FRIEND GROUPS
  // ---------------------------------------------------------------

  @override
  Future<GameRoomModel> createFriendGroup({
    required GameType gameType,
    required String targetLanguage,
    required String hostUserId,
    required String hostDisplayName,
    String? hostPhotoUrl,
    required int maxPlayers,
    int difficulty = 5,
  }) async {
    debugPrint('[LanguageGames] createFriendGroup: $gameType | '
        'host=$hostUserId');

    final docRef = _roomsCollection.doc();
    final int totalRounds = _getTotalRounds(gameType);
    final int turnDuration = _getTurnDuration(
      gameType,
      difficulty.clamp(1, 10),
    );
    final int defaultLives = _getDefaultLives(gameType);
    final String inviteCode = _generateInviteCode();
    final String friendGroupId = docRef.id; // use room id as group id

    final roomData = {
      'gameType': gameType.name,
      'targetLanguage': targetLanguage,
      'hostUserId': hostUserId,
      'maxPlayers': maxPlayers,
      'status': GameStatus.waiting.name,
      'createdAt': FieldValue.serverTimestamp(),
      'currentRound': 0,
      'totalRounds': totalRounds,
      'currentTurnUserId': null,
      'scores': {hostUserId: 0},
      'lives': {hostUserId: defaultLives},
      'usedWords': <String>[],
      'currentPrompt': null,
      'turnStartedAt': null,
      'turnDurationSeconds': turnDuration,
      'winnerId': null,
      'currentDescriberId': null,
      'roundTheme': null,
      'difficulty': difficulty.clamp(1, 10),
      'inviteCode': inviteCode,
      'friendGroupId': friendGroupId,
      'isPrivate': true,
      'players': {
        hostUserId: {
          'displayName': hostDisplayName,
          'photoUrl': hostPhotoUrl,
          'score': 0,
          'lives': defaultLives,
          'isReady': false,
          'isConnected': true,
          'languages': <String>[],
        },
      },
    };

    await docRef.set(roomData);

    await updateLiveCount(
      gameType: gameType,
      field: 'waiting',
      delta: 1,
    );

    final snapshot = await docRef.get();
    debugPrint('[LanguageGames] createFriendGroup: created ${docRef.id} '
        '| inviteCode=$inviteCode');
    return GameRoomModel.fromFirestore(snapshot);
  }

  @override
  Future<GameRoomModel> joinByInviteCode({
    required String inviteCode,
    required String userId,
    required String displayName,
    String? photoUrl,
  }) async {
    debugPrint('[LanguageGames] joinByInviteCode: code=$inviteCode '
        '| user=$userId');

    // Find room by invite code
    final querySnapshot = await _roomsCollection
        .where('inviteCode', isEqualTo: inviteCode.toUpperCase())
        .where('status', isEqualTo: GameStatus.waiting.name)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      throw Exception(
          'No room found with invite code $inviteCode or game already started');
    }

    final roomDoc = querySnapshot.docs.first;
    final roomId = roomDoc.id;

    debugPrint(
        '[LanguageGames] joinByInviteCode: found room $roomId');

    return joinRoom(
      roomId: roomId,
      userId: userId,
      displayName: displayName,
      photoUrl: photoUrl,
    );
  }

  // ---------------------------------------------------------------
  //  LIVE PLAYER COUNTS
  // ---------------------------------------------------------------

  @override
  Future<void> updateLiveCount({
    required GameType gameType,
    required String field,
    required int delta,
  }) async {
    try {
      await _liveStatsDoc.set(
        {
          gameType.name: {
            field: FieldValue.increment(delta),
          },
        },
        SetOptions(merge: true),
      );
      debugPrint('[LanguageGames] updateLiveCount: '
          '${gameType.name}.$field += $delta');
    } catch (e) {
      // Non-critical -- log and continue
      debugPrint('[LanguageGames] updateLiveCount ERROR: $e');
    }
  }

  @override
  Stream<Map<String, Map<String, int>>> getLiveCountsStream() {
    debugPrint('[LanguageGames] getLiveCountsStream: subscribing');
    return _liveStatsDoc.snapshots().map((snapshot) {
      if (!snapshot.exists) return <String, Map<String, int>>{};

      final data = snapshot.data() as Map<String, dynamic>? ?? {};
      final result = <String, Map<String, int>>{};

      for (final entry in data.entries) {
        if (entry.value is Map) {
          final inner = entry.value as Map<String, dynamic>;
          result[entry.key] = {
            'waiting': (inner['waiting'] as num?)?.toInt() ?? 0,
            'playing': (inner['playing'] as num?)?.toInt() ?? 0,
          };
        }
      }

      return result;
    });
  }

  // ============================================================
  //  PRIVATE HELPERS
  // ============================================================

  /// Read difficulty from a room snapshot, defaulting to 5
  int _getRoomDifficulty(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>? ?? {};
    return (data['difficulty'] as num?)?.toInt() ?? 5;
  }

  /// Generate a random 6-character uppercase invite code
  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no I/O/0/1
    final random = Random.secure();
    return List.generate(
      6,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  /// Remove a room from the matchmaking queue
  Future<void> _removeFromMatchmaking(GameRoomModel room) async {
    try {
      final data =
          (await _roomsCollection.doc(room.id).get()).data()
              as Map<String, dynamic>? ??
          {};
      final difficulty = (data['difficulty'] as num?)?.toInt() ?? 5;
      final queueKey =
          '${room.gameType.name}_${room.targetLanguage}_$difficulty';
      await _matchmakingCollection.doc(queueKey).delete();
      debugPrint('[LanguageGames] _removeFromMatchmaking: '
          'removed $queueKey');
    } catch (e) {
      debugPrint('[LanguageGames] _removeFromMatchmaking ERROR: $e');
    }
  }

  /// Clean up matchmaking entry when host deletes room
  Future<void> _cleanupMatchmaking(GameRoomModel room) async {
    try {
      // We don't have difficulty on the model yet, query by roomId
      final querySnapshot = await _matchmakingCollection
          .where('roomId', isEqualTo: room.id)
          .limit(1)
          .get();
      for (final doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
      debugPrint('[LanguageGames] _cleanupMatchmaking: '
          'cleaned up for room ${room.id}');
    } catch (e) {
      debugPrint('[LanguageGames] _cleanupMatchmaking ERROR: $e');
    }
  }

  /// Calculate streak bonus XP for a player across rounds
  Future<int> _calculateStreakBonus(
    String roomId,
    String userId,
    int totalRounds,
  ) async {
    int bonus = 0;
    int consecutiveCorrect = 0;

    try {
      for (int i = 1; i <= totalRounds; i++) {
        final roundSnapshot = await _roomsCollection
            .doc(roomId)
            .collection('rounds')
            .doc('$i')
            .get();

        if (!roundSnapshot.exists) continue;

        final roundData =
            roundSnapshot.data() as Map<String, dynamic>? ?? {};
        final answers =
            roundData['playerAnswers'] as Map<String, dynamic>? ?? {};
        final playerAnswer =
            answers[userId] as Map<String, dynamic>?;

        if (playerAnswer != null &&
            playerAnswer['isCorrect'] == true) {
          consecutiveCorrect++;
          if (consecutiveCorrect >= 3) {
            bonus += _streakBonusXp;
          }
        } else {
          consecutiveCorrect = 0;
        }
      }
    } catch (e) {
      debugPrint('[LanguageGames] _calculateStreakBonus ERROR: $e');
    }

    return bonus;
  }

  /// Calculate perfect round bonus (all answers correct in a round)
  Future<int> _calculatePerfectRoundBonus(
    String roomId,
    String userId,
    int totalRounds,
  ) async {
    int bonus = 0;

    try {
      for (int i = 1; i <= totalRounds; i++) {
        final roundSnapshot = await _roomsCollection
            .doc(roomId)
            .collection('rounds')
            .doc('$i')
            .get();

        if (!roundSnapshot.exists) continue;

        final roundData =
            roundSnapshot.data() as Map<String, dynamic>? ?? {};
        final answers =
            roundData['playerAnswers'] as Map<String, dynamic>? ?? {};
        final playerAnswer =
            answers[userId] as Map<String, dynamic>?;

        if (playerAnswer != null &&
            playerAnswer['isCorrect'] == true) {
          // Check if ALL answers in this round are correct
          final allCorrect = answers.values.every((a) {
            final answer = a as Map<String, dynamic>? ?? {};
            return answer['isCorrect'] == true;
          });
          if (allCorrect && answers.isNotEmpty) {
            bonus += _perfectRoundBonusXp;
          }
        }
      }
    } catch (e) {
      debugPrint(
          '[LanguageGames] _calculatePerfectRoundBonus ERROR: $e');
    }

    return bonus;
  }

  int _getTotalRounds(GameType type) {
    switch (type) {
      case GameType.wordBomb:
        return 20; // Lives-based, not round-based
      case GameType.translationRace:
        return 15;
      case GameType.pictureGuess:
        return 5;
      case GameType.grammarDuel:
        return 10;
      case GameType.vocabularyChain:
        return 20; // Lives-based
      case GameType.languageSnaps:
        return 10;
      case GameType.languageTapples:
        return 10;
      case GameType.categories:
        return 5;
    }
  }

  /// Turn duration adjusted by difficulty:
  /// higher difficulty = shorter time (more pressure)
  int _getTurnDuration(GameType type, [int difficulty = 5]) {
    int base;
    switch (type) {
      case GameType.wordBomb:
        base = 10;
        break;
      case GameType.translationRace:
        base = 15;
        break;
      case GameType.pictureGuess:
        base = 60;
        break;
      case GameType.grammarDuel:
        base = 15;
        break;
      case GameType.vocabularyChain:
        base = 15;
        break;
      case GameType.languageSnaps:
        base = 60; // Memory game, needs more time
        break;
      case GameType.languageTapples:
        base = 15;
        break;
      case GameType.categories:
        base = 120; // Fill all categories, needs time
        break;
    }
    // Reduce time by 0.5s per difficulty level above 5
    final adjustment = ((difficulty - 5) * 0.5).round();
    return (base - adjustment).clamp(5, 120);
  }

  int _getDefaultLives(GameType type) {
    switch (type) {
      case GameType.wordBomb:
        return 3;
      case GameType.translationRace:
        return 0; // Score-based, no lives
      case GameType.pictureGuess:
        return 0;
      case GameType.grammarDuel:
        return 0;
      case GameType.vocabularyChain:
        return 3;
      case GameType.languageSnaps:
        return 0; // Score-based
      case GameType.languageTapples:
        return 3;
      case GameType.categories:
        return 0; // Score-based
    }
  }

  String _generatePrompt(
    GameType type,
    String language, [
    int difficulty = 5,
  ]) {
    switch (type) {
      case GameType.wordBomb:
        return GameContent.getRandomWordBombPrompt(language);
      case GameType.translationRace:
        final pair = GameContent.getRandomTranslationPair(language);
        return pair.key; // English word to translate
      case GameType.pictureGuess:
        final pair = GameContent.getRandomTranslationPair(language);
        return pair.value; // Word in target language to describe
      case GameType.grammarDuel:
        final question =
            GameContent.getRandomGrammarQuestion(language);
        return question.question;
      case GameType.vocabularyChain:
        return ''; // Chain starts fresh
      case GameType.languageSnaps:
        return ''; // Cards dealt client-side
      case GameType.languageTapples:
        final category = GameContent.getTapplesCategory(language);
        return category;
      case GameType.categories:
        // Random letter for the round
        const letters = 'ABCDEFGHILMNOPRSTV';
        return letters[Random().nextInt(letters.length)];
    }
  }

  String? _getCorrectAnswer(
    GameType type,
    String language,
    String prompt,
  ) {
    switch (type) {
      case GameType.translationRace:
        final pairs = GameContent.translationPairs[language] ?? {};
        return pairs[prompt];
      case GameType.pictureGuess:
        return prompt; // The word itself is the answer
      case GameType.grammarDuel:
        final questions =
            GameContent.grammarQuestions[language] ?? [];
        final question = questions.firstWhere(
          (q) => q.question == prompt,
          orElse: () => questions.first,
        );
        return '${question.correctIndex}';
      default:
        return null;
    }
  }

  List<String> _generateOptions(
    GameType type,
    String language,
    String prompt,
  ) {
    if (type != GameType.grammarDuel) return [];

    final questions =
        GameContent.grammarQuestions[language] ?? [];
    final question = questions.firstWhere(
      (q) => q.question == prompt,
      orElse: () => questions.first,
    );
    return question.options;
  }

  // ---------------------------------------------------------------
  //  GAME INVITES
  // ---------------------------------------------------------------

  CollectionReference get _invitesCollection =>
      firestore.collection('game_invites');

  @override
  Future<void> sendGameInvite({
    required String roomId,
    required String invitedUserId,
    required String hostUserId,
    required String hostNickname,
    String? hostPhotoUrl,
    required String gameType,
    required String gameName,
    required String targetLanguage,
  }) async {
    debugPrint('[LanguageGames] sendGameInvite: '
        'room=$roomId, invitedUser=$invitedUserId');

    // Check for existing pending invite for same user + room
    final existing = await _invitesCollection
        .where('roomId', isEqualTo: roomId)
        .where('invitedUserId', isEqualTo: invitedUserId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('Invite already sent to this player');
    }

    final now = DateTime.now();
    await _invitesCollection.add({
      'roomId': roomId,
      'gameType': gameType,
      'gameName': gameName,
      'targetLanguage': targetLanguage,
      'hostUserId': hostUserId,
      'hostNickname': hostNickname,
      'hostPhotoUrl': hostPhotoUrl,
      'invitedUserId': invitedUserId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(now.add(const Duration(minutes: 2))),
    });

    debugPrint('[LanguageGames] sendGameInvite: invite created');
  }

  @override
  Future<void> respondToInvite({
    required String inviteId,
    required bool accepted,
  }) async {
    debugPrint('[LanguageGames] respondToInvite: '
        'id=$inviteId, accepted=$accepted');

    await _invitesCollection.doc(inviteId).update({
      'status': accepted ? 'accepted' : 'declined',
    });
  }

  @override
  Stream<List<Map<String, dynamic>>> getInviteStream(String userId) {
    debugPrint('[LanguageGames] getInviteStream: userId=$userId');
    return _invitesCollection
        .where('invitedUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['inviteId'] = doc.id;
        return data;
      }).toList();
    });
  }
}
