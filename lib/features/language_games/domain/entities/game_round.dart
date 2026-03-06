import 'package:equatable/equatable.dart';

/// Game Round Entity
///
/// Represents a single round within a language game
class GameRound extends Equatable {
  final int roundNumber;
  final String prompt;
  final String? correctAnswer;
  final List<String> options;
  final Map<String, GameAnswer> playerAnswers;
  final DateTime startedAt;
  final int durationSeconds;
  final String? winnerId;

  const GameRound({
    required this.roundNumber,
    required this.prompt,
    this.correctAnswer,
    this.options = const [],
    this.playerAnswers = const {},
    required this.startedAt,
    this.durationSeconds = 15,
    this.winnerId,
  });

  /// Check if a player has already answered
  bool hasPlayerAnswered(String userId) => playerAnswers.containsKey(userId);

  /// Get the number of correct answers
  int get correctAnswerCount =>
      playerAnswers.values.where((a) => a.isCorrect).length;

  /// Check if round time has expired
  bool get isExpired {
    final elapsed = DateTime.now().difference(startedAt).inSeconds;
    return elapsed >= durationSeconds;
  }

  /// Get remaining seconds
  int get remainingSeconds {
    final elapsed = DateTime.now().difference(startedAt).inSeconds;
    return (durationSeconds - elapsed).clamp(0, durationSeconds);
  }

  GameRound copyWith({
    int? roundNumber,
    String? prompt,
    String? correctAnswer,
    List<String>? options,
    Map<String, GameAnswer>? playerAnswers,
    DateTime? startedAt,
    int? durationSeconds,
    String? winnerId,
  }) {
    return GameRound(
      roundNumber: roundNumber ?? this.roundNumber,
      prompt: prompt ?? this.prompt,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      options: options ?? this.options,
      playerAnswers: playerAnswers ?? this.playerAnswers,
      startedAt: startedAt ?? this.startedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      winnerId: winnerId ?? this.winnerId,
    );
  }

  @override
  List<Object?> get props => [
        roundNumber,
        prompt,
        correctAnswer,
        options,
        playerAnswers,
        startedAt,
        durationSeconds,
        winnerId,
      ];
}

/// Individual player answer within a round
class GameAnswer extends Equatable {
  final String userId;
  final String answer;
  final DateTime answeredAt;
  final bool isCorrect;
  final int pointsEarned;

  const GameAnswer({
    required this.userId,
    required this.answer,
    required this.answeredAt,
    this.isCorrect = false,
    this.pointsEarned = 0,
  });

  /// Time taken to answer in milliseconds
  int timeToAnswerMs(DateTime roundStartedAt) =>
      answeredAt.difference(roundStartedAt).inMilliseconds;

  GameAnswer copyWith({
    String? userId,
    String? answer,
    DateTime? answeredAt,
    bool? isCorrect,
    int? pointsEarned,
  }) {
    return GameAnswer(
      userId: userId ?? this.userId,
      answer: answer ?? this.answer,
      answeredAt: answeredAt ?? this.answeredAt,
      isCorrect: isCorrect ?? this.isCorrect,
      pointsEarned: pointsEarned ?? this.pointsEarned,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        answer,
        answeredAt,
        isCorrect,
        pointsEarned,
      ];
}
