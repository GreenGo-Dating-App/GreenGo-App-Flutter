import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/game_player.dart';
import '../../domain/entities/game_room.dart';
import 'game_player_model.dart';

/// Game Room Firestore Model
class GameRoomModel extends GameRoom {
  const GameRoomModel({
    required super.id,
    required super.gameType,
    required super.targetLanguage,
    required super.hostUserId,
    required super.players,
    required super.maxPlayers,
    required super.status,
    required super.createdAt,
    super.currentRound,
    super.totalRounds,
    super.currentTurnUserId,
    super.scores,
    super.lives,
    super.usedWords,
    super.currentPrompt,
    super.turnStartedAt,
    super.turnDurationSeconds,
    super.winnerId,
    super.currentDescriberId,
    super.roundTheme,
    super.roundCategories,
    super.difficulty,
    super.friendGroupId,
    super.xpReward,
  });

  /// Create from Firestore document
  factory GameRoomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final playersMap = data['players'] as Map<String, dynamic>? ?? {};
    final players = playersMap.entries
        .map((e) => GamePlayerModel.fromMap(e.key, e.value as Map<String, dynamic>))
        .toList();

    final scoresRaw = data['scores'] as Map<String, dynamic>? ?? {};
    final scores = scoresRaw.map((k, v) => MapEntry(k, (v as num).toInt()));

    final livesRaw = data['lives'] as Map<String, dynamic>? ?? {};
    final lives = livesRaw.map((k, v) => MapEntry(k, (v as num).toInt()));

    final usedWords = (data['usedWords'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return GameRoomModel(
      id: doc.id,
      gameType: _parseGameType(data['gameType'] as String? ?? 'wordBomb'),
      targetLanguage: data['targetLanguage'] as String? ?? 'es',
      hostUserId: data['hostUserId'] as String? ?? '',
      players: players,
      maxPlayers: (data['maxPlayers'] as num?)?.toInt() ?? 4,
      status: _parseGameStatus(data['status'] as String? ?? 'waiting'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      currentRound: (data['currentRound'] as num?)?.toInt() ?? 0,
      totalRounds: (data['totalRounds'] as num?)?.toInt() ?? 10,
      currentTurnUserId: data['currentTurnUserId'] as String?,
      scores: scores,
      lives: lives,
      usedWords: usedWords,
      currentPrompt: data['currentPrompt'] as String?,
      turnStartedAt: (data['turnStartedAt'] as Timestamp?)?.toDate(),
      turnDurationSeconds: (data['turnDurationSeconds'] as num?)?.toInt() ?? 15,
      winnerId: data['winnerId'] as String?,
      currentDescriberId: data['currentDescriberId'] as String?,
      roundTheme: data['roundTheme'] as String?,
      roundCategories: data['roundCategories'] != null
          ? List<String>.from(data['roundCategories'] as List)
          : null,
      difficulty: (data['difficulty'] as num?)?.toInt() ?? 1,
      friendGroupId: data['friendGroupId'] as String?,
      xpReward: (data['xpReward'] as num?)?.toInt() ?? 0,
    );
  }

  /// Convert to Firestore JSON
  Map<String, dynamic> toJson() {
    final playersMap = <String, dynamic>{};
    for (final player in players) {
      playersMap[player.userId] = {
        'displayName': player.displayName,
        'photoUrl': player.photoUrl,
        'score': player.score,
        'lives': player.lives,
        'isReady': player.isReady,
        'isConnected': player.isConnected,
        'languages': player.languages,
      };
    }

    return {
      'gameType': gameType.name,
      'targetLanguage': targetLanguage,
      'hostUserId': hostUserId,
      'players': playersMap,
      'maxPlayers': maxPlayers,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'currentRound': currentRound,
      'totalRounds': totalRounds,
      'currentTurnUserId': currentTurnUserId,
      'scores': scores,
      'lives': lives,
      'usedWords': usedWords,
      'currentPrompt': currentPrompt,
      'turnStartedAt':
          turnStartedAt != null ? Timestamp.fromDate(turnStartedAt!) : null,
      'turnDurationSeconds': turnDurationSeconds,
      'winnerId': winnerId,
      'currentDescriberId': currentDescriberId,
      'roundTheme': roundTheme,
      'roundCategories': roundCategories,
      'difficulty': difficulty,
      'friendGroupId': friendGroupId,
      'xpReward': xpReward,
    };
  }

  /// Create from entity for creating new rooms
  factory GameRoomModel.fromEntity(GameRoom room) {
    return GameRoomModel(
      id: room.id,
      gameType: room.gameType,
      targetLanguage: room.targetLanguage,
      hostUserId: room.hostUserId,
      players: room.players,
      maxPlayers: room.maxPlayers,
      status: room.status,
      createdAt: room.createdAt,
      currentRound: room.currentRound,
      totalRounds: room.totalRounds,
      currentTurnUserId: room.currentTurnUserId,
      scores: room.scores,
      lives: room.lives,
      usedWords: room.usedWords,
      currentPrompt: room.currentPrompt,
      turnStartedAt: room.turnStartedAt,
      turnDurationSeconds: room.turnDurationSeconds,
      winnerId: room.winnerId,
      currentDescriberId: room.currentDescriberId,
      roundTheme: room.roundTheme,
      roundCategories: room.roundCategories,
      difficulty: room.difficulty,
      friendGroupId: room.friendGroupId,
      xpReward: room.xpReward,
    );
  }

  static GameType _parseGameType(String value) {
    switch (value) {
      case 'wordBomb':
        return GameType.wordBomb;
      case 'translationRace':
        return GameType.translationRace;
      case 'pictureGuess':
        return GameType.pictureGuess;
      case 'grammarDuel':
        return GameType.grammarDuel;
      case 'vocabularyChain':
        return GameType.vocabularyChain;
      case 'languageSnaps':
        return GameType.languageSnaps;
      case 'languageTapples':
        return GameType.languageTapples;
      case 'categories':
        return GameType.categories;
      default:
        return GameType.wordBomb;
    }
  }

  static GameStatus _parseGameStatus(String value) {
    switch (value) {
      case 'waiting':
        return GameStatus.waiting;
      case 'starting':
        return GameStatus.starting;
      case 'inProgress':
        return GameStatus.inProgress;
      case 'finished':
        return GameStatus.finished;
      default:
        return GameStatus.waiting;
    }
  }
}
