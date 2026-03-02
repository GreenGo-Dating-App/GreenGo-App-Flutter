import '../../domain/entities/safety_quiz.dart';

/// Firestore data model for [SafetyQuiz]
class SafetyQuizModel extends SafetyQuiz {
  const SafetyQuizModel({
    required super.id,
    required super.lessonId,
    required super.questions,
    super.passingScore,
  });

  factory SafetyQuizModel.fromMap(Map<String, dynamic> map) {
    return SafetyQuizModel(
      id: map['id'] as String? ?? '',
      lessonId: map['lessonId'] as String? ?? '',
      questions: _parseQuestions(map['questions']),
      passingScore: map['passingScore'] as int? ?? 80,
    );
  }

  factory SafetyQuizModel.fromEntity(SafetyQuiz entity) {
    return SafetyQuizModel(
      id: entity.id,
      lessonId: entity.lessonId,
      questions: entity.questions,
      passingScore: entity.passingScore,
    );
  }

  static List<QuizQuestion> _parseQuestions(dynamic raw) {
    if (raw == null) return [];
    if (raw is! List) return [];

    return raw.map((q) {
      final map = q as Map<String, dynamic>;
      return QuizQuestion(
        question: map['question'] as String? ?? '',
        options: (map['options'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        correctIndex: map['correctIndex'] as int? ?? 0,
        explanation: map['explanation'] as String? ?? '',
      );
    }).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lessonId': lessonId,
      'questions': questions
          .map((q) => {
                'question': q.question,
                'options': q.options,
                'correctIndex': q.correctIndex,
                'explanation': q.explanation,
              })
          .toList(),
      'passingScore': passingScore,
    };
  }
}
