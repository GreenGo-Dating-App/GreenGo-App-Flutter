import 'package:equatable/equatable.dart';

/// Represents a cultural quiz about a country/language
class CulturalQuiz extends Equatable {
  final String id;
  final String title;
  final String description;
  final String languageCode;
  final String countryCode;
  final String countryName;
  final List<QuizQuestion> questions;
  final int timeLimit; // in seconds
  final int minXpReward;
  final int maxXpReward;
  final int perfectScoreCoins;
  final String? perfectScoreBadge;
  final QuizDifficulty difficulty;

  const CulturalQuiz({
    required this.id,
    required this.title,
    required this.description,
    required this.languageCode,
    required this.countryCode,
    required this.countryName,
    required this.questions,
    this.timeLimit = 300, // 5 minutes default
    this.minXpReward = 20,
    this.maxXpReward = 100,
    this.perfectScoreCoins = 50,
    this.perfectScoreBadge,
    this.difficulty = QuizDifficulty.medium,
  });

  int calculateXpReward(int correctAnswers) {
    if (questions.isEmpty) return 0;
    final percentage = correctAnswers / questions.length;
    return (minXpReward + (maxXpReward - minXpReward) * percentage).round();
  }

  bool isPerfectScore(int correctAnswers) => correctAnswers == questions.length;

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        languageCode,
        countryCode,
        countryName,
        questions,
        timeLimit,
        minXpReward,
        maxXpReward,
        perfectScoreCoins,
        perfectScoreBadge,
        difficulty,
      ];
}

class QuizQuestion extends Equatable {
  final String id;
  final String question;
  final List<String> options;
  final int correctOptionIndex;
  final String? explanation;
  final String? imageUrl;

  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctOptionIndex,
    this.explanation,
    this.imageUrl,
  });

  String get correctAnswer => options[correctOptionIndex];

  bool isCorrect(int selectedIndex) => selectedIndex == correctOptionIndex;

  @override
  List<Object?> get props => [
        id,
        question,
        options,
        correctOptionIndex,
        explanation,
        imageUrl,
      ];
}

class QuizResult extends Equatable {
  final String odUserId;
  final String quizId;
  final int correctAnswers;
  final int totalQuestions;
  final int xpEarned;
  final int coinsEarned;
  final bool isPerfect;
  final Duration timeTaken;
  final DateTime completedAt;
  final List<QuestionResult> questionResults;

  const QuizResult({
    required this.odUserId,
    required this.quizId,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.xpEarned,
    required this.coinsEarned,
    required this.isPerfect,
    required this.timeTaken,
    required this.completedAt,
    this.questionResults = const [],
  });

  double get scorePercentage =>
      totalQuestions > 0 ? correctAnswers / totalQuestions * 100 : 0;

  String get grade {
    final percentage = scorePercentage;
    if (percentage >= 90) return 'A';
    if (percentage >= 80) return 'B';
    if (percentage >= 70) return 'C';
    if (percentage >= 60) return 'D';
    return 'F';
  }

  @override
  List<Object?> get props => [
        odUserId,
        quizId,
        correctAnswers,
        totalQuestions,
        xpEarned,
        coinsEarned,
        isPerfect,
        timeTaken,
        completedAt,
        questionResults,
      ];
}

class QuestionResult extends Equatable {
  final String questionId;
  final int selectedOptionIndex;
  final bool isCorrect;

  const QuestionResult({
    required this.questionId,
    required this.selectedOptionIndex,
    required this.isCorrect,
  });

  @override
  List<Object?> get props => [questionId, selectedOptionIndex, isCorrect];
}

enum QuizDifficulty {
  easy,
  medium,
  hard,
}

extension QuizDifficultyExtension on QuizDifficulty {
  String get displayName {
    switch (this) {
      case QuizDifficulty.easy:
        return 'Easy';
      case QuizDifficulty.medium:
        return 'Medium';
      case QuizDifficulty.hard:
        return 'Hard';
    }
  }

  int get xpMultiplier {
    switch (this) {
      case QuizDifficulty.easy:
        return 1;
      case QuizDifficulty.medium:
        return 2;
      case QuizDifficulty.hard:
        return 3;
    }
  }
}
