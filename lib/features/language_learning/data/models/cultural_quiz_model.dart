import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/cultural_quiz.dart';

class CulturalQuizModel extends CulturalQuiz {
  const CulturalQuizModel({
    required super.id,
    required super.title,
    required super.description,
    required super.languageCode,
    required super.countryCode,
    required super.countryName,
    required super.questions,
    super.timeLimit,
    super.minXpReward,
    super.maxXpReward,
    super.perfectScoreCoins,
    super.perfectScoreBadge,
    super.difficulty,
  });

  factory CulturalQuizModel.fromJson(Map<String, dynamic> json) {
    return CulturalQuizModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      languageCode: json['languageCode'] as String,
      countryCode: json['countryCode'] as String,
      countryName: json['countryName'] as String,
      questions: (json['questions'] as List<dynamic>)
          .map((e) => QuizQuestionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      timeLimit: json['timeLimit'] as int? ?? 300,
      minXpReward: json['minXpReward'] as int? ?? 20,
      maxXpReward: json['maxXpReward'] as int? ?? 100,
      perfectScoreCoins: json['perfectScoreCoins'] as int? ?? 50,
      perfectScoreBadge: json['perfectScoreBadge'] as String?,
      difficulty: QuizDifficulty.values.firstWhere(
        (e) => e.name == json['difficulty'],
        orElse: () => QuizDifficulty.medium,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'languageCode': languageCode,
      'countryCode': countryCode,
      'countryName': countryName,
      'questions': questions
          .map((q) => q is QuizQuestionModel
              ? q.toJson()
              : QuizQuestionModel.fromEntity(q).toJson())
          .toList(),
      'timeLimit': timeLimit,
      'minXpReward': minXpReward,
      'maxXpReward': maxXpReward,
      'perfectScoreCoins': perfectScoreCoins,
      'perfectScoreBadge': perfectScoreBadge,
      'difficulty': difficulty.name,
    };
  }

  factory CulturalQuizModel.fromEntity(CulturalQuiz entity) {
    return CulturalQuizModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      languageCode: entity.languageCode,
      countryCode: entity.countryCode,
      countryName: entity.countryName,
      questions: entity.questions,
      timeLimit: entity.timeLimit,
      minXpReward: entity.minXpReward,
      maxXpReward: entity.maxXpReward,
      perfectScoreCoins: entity.perfectScoreCoins,
      perfectScoreBadge: entity.perfectScoreBadge,
      difficulty: entity.difficulty,
    );
  }
}

class QuizQuestionModel extends QuizQuestion {
  const QuizQuestionModel({
    required super.id,
    required super.question,
    required super.options,
    required super.correctOptionIndex,
    super.explanation,
    super.imageUrl,
  });

  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) {
    return QuizQuestionModel(
      id: json['id'] as String,
      question: json['question'] as String,
      options:
          (json['options'] as List<dynamic>).map((e) => e as String).toList(),
      correctOptionIndex: json['correctOptionIndex'] as int,
      explanation: json['explanation'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correctOptionIndex': correctOptionIndex,
      'explanation': explanation,
      'imageUrl': imageUrl,
    };
  }

  factory QuizQuestionModel.fromEntity(QuizQuestion entity) {
    return QuizQuestionModel(
      id: entity.id,
      question: entity.question,
      options: entity.options,
      correctOptionIndex: entity.correctOptionIndex,
      explanation: entity.explanation,
      imageUrl: entity.imageUrl,
    );
  }
}

class QuizResultModel extends QuizResult {
  const QuizResultModel({
    required super.odUserId,
    required super.quizId,
    required super.correctAnswers,
    required super.totalQuestions,
    required super.xpEarned,
    required super.coinsEarned,
    required super.isPerfect,
    required super.timeTaken,
    required super.completedAt,
    super.questionResults,
  });

  factory QuizResultModel.fromJson(Map<String, dynamic> json) {
    return QuizResultModel(
      odUserId: json['odUserId'] as String,
      quizId: json['quizId'] as String,
      correctAnswers: json['correctAnswers'] as int,
      totalQuestions: json['totalQuestions'] as int,
      xpEarned: json['xpEarned'] as int,
      coinsEarned: json['coinsEarned'] as int,
      isPerfect: json['isPerfect'] as bool,
      timeTaken: Duration(seconds: json['timeTakenSeconds'] as int),
      completedAt: (json['completedAt'] as Timestamp).toDate(),
      questionResults: (json['questionResults'] as List<dynamic>?)
              ?.map((e) =>
                  QuestionResultModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'odUserId': odUserId,
      'quizId': quizId,
      'correctAnswers': correctAnswers,
      'totalQuestions': totalQuestions,
      'xpEarned': xpEarned,
      'coinsEarned': coinsEarned,
      'isPerfect': isPerfect,
      'timeTakenSeconds': timeTaken.inSeconds,
      'completedAt': Timestamp.fromDate(completedAt),
      'questionResults': questionResults
          .map((r) => r is QuestionResultModel
              ? r.toJson()
              : QuestionResultModel.fromEntity(r).toJson())
          .toList(),
    };
  }

  factory QuizResultModel.fromEntity(QuizResult entity) {
    return QuizResultModel(
      odUserId: entity.odUserId,
      quizId: entity.quizId,
      correctAnswers: entity.correctAnswers,
      totalQuestions: entity.totalQuestions,
      xpEarned: entity.xpEarned,
      coinsEarned: entity.coinsEarned,
      isPerfect: entity.isPerfect,
      timeTaken: entity.timeTaken,
      completedAt: entity.completedAt,
      questionResults: entity.questionResults,
    );
  }
}

class QuestionResultModel extends QuestionResult {
  const QuestionResultModel({
    required super.questionId,
    required super.selectedOptionIndex,
    required super.isCorrect,
  });

  factory QuestionResultModel.fromJson(Map<String, dynamic> json) {
    return QuestionResultModel(
      questionId: json['questionId'] as String,
      selectedOptionIndex: json['selectedOptionIndex'] as int,
      isCorrect: json['isCorrect'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'selectedOptionIndex': selectedOptionIndex,
      'isCorrect': isCorrect,
    };
  }

  factory QuestionResultModel.fromEntity(QuestionResult entity) {
    return QuestionResultModel(
      questionId: entity.questionId,
      selectedOptionIndex: entity.selectedOptionIndex,
      isCorrect: entity.isCorrect,
    );
  }
}
