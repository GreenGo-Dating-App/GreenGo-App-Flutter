import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/game_round.dart';

/// Game Round Firestore Model
class GameRoundModel extends GameRound {
  const GameRoundModel({
    required super.roundNumber,
    required super.prompt,
    super.correctAnswer,
    super.options,
    super.playerAnswers,
    required super.startedAt,
    super.durationSeconds,
    super.winnerId,
    super.clues,
  });

  /// Create from Firestore document
  factory GameRoundModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final answersMap = data['playerAnswers'] as Map<String, dynamic>? ?? {};
    final playerAnswers = answersMap.map(
      (key, value) => MapEntry(
        key,
        GameAnswerModel.fromMap(key, value as Map<String, dynamic>),
      ),
    );

    final options = (data['options'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    final clues = (data['clues'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return GameRoundModel(
      roundNumber: (data['roundNumber'] as num?)?.toInt() ?? 0,
      prompt: data['prompt'] as String? ?? '',
      correctAnswer: data['correctAnswer'] as String?,
      options: options,
      playerAnswers: playerAnswers,
      startedAt: (data['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      durationSeconds: (data['durationSeconds'] as num?)?.toInt() ?? 15,
      winnerId: data['winnerId'] as String?,
      clues: clues,
    );
  }

  /// Convert to Firestore JSON
  Map<String, dynamic> toJson() {
    final answersJson = playerAnswers.map(
      (key, value) {
        final answer = value;
        return MapEntry(key, {
          'answer': answer.answer,
          'answeredAt': Timestamp.fromDate(answer.answeredAt),
          'isCorrect': answer.isCorrect,
          'pointsEarned': answer.pointsEarned,
        });
      },
    );

    return {
      'roundNumber': roundNumber,
      'prompt': prompt,
      'correctAnswer': correctAnswer,
      'options': options,
      'playerAnswers': answersJson,
      'startedAt': Timestamp.fromDate(startedAt),
      'durationSeconds': durationSeconds,
      'winnerId': winnerId,
      'clues': clues,
    };
  }

  /// Create from entity
  factory GameRoundModel.fromEntity(GameRound round) {
    return GameRoundModel(
      roundNumber: round.roundNumber,
      prompt: round.prompt,
      correctAnswer: round.correctAnswer,
      options: round.options,
      playerAnswers: round.playerAnswers,
      startedAt: round.startedAt,
      durationSeconds: round.durationSeconds,
      winnerId: round.winnerId,
      clues: round.clues,
    );
  }
}

/// Game Answer Firestore Model
class GameAnswerModel extends GameAnswer {
  const GameAnswerModel({
    required super.userId,
    required super.answer,
    required super.answeredAt,
    super.isCorrect,
    super.pointsEarned,
  });

  /// Create from Firestore map data
  factory GameAnswerModel.fromMap(String userId, Map<String, dynamic> data) {
    return GameAnswerModel(
      userId: userId,
      answer: data['answer'] as String? ?? '',
      answeredAt:
          (data['answeredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isCorrect: data['isCorrect'] as bool? ?? false,
      pointsEarned: (data['pointsEarned'] as num?)?.toInt() ?? 0,
    );
  }

  /// Convert to Firestore JSON
  Map<String, dynamic> toJson() {
    return {
      'answer': answer,
      'answeredAt': Timestamp.fromDate(answeredAt),
      'isCorrect': isCorrect,
      'pointsEarned': pointsEarned,
    };
  }
}
