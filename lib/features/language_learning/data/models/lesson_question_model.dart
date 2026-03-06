import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/lesson_question.dart';

class LessonQuestionModel extends LessonQuestion {
  const LessonQuestionModel({
    required super.id,
    required super.languageSource,
    required super.languageTarget,
    required super.unit,
    required super.lesson,
    required super.questionNumber,
    required super.questionType,
    required super.question,
    required super.answers,
    required super.rightAnswer,
    super.hint,
    super.media,
    super.quickHint,
  });

  factory LessonQuestionModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return LessonQuestionModel(
      id: doc.id,
      languageSource: d['languageSource'] as String? ?? '',
      languageTarget: d['languageTarget'] as String? ?? '',
      unit: d['unit'] as int? ?? 1,
      lesson: d['lesson'] as int? ?? 1,
      questionNumber: d['questionNumber'] as int? ?? 0,
      questionType: d['questionType'] as String? ?? 'multiple_choice',
      question: d['question'] as String? ?? '',
      answers: d['answers'] as String? ?? '',
      rightAnswer: d['rightAnswer'] as String? ?? '',
      hint: d['hint'] as String? ?? '',
      media: d['media'] as String? ?? '',
      quickHint: d['quickHint'] as String? ?? '',
    );
  }

  factory LessonQuestionModel.fromJson(Map<String, dynamic> json) {
    return LessonQuestionModel(
      id: json['id'] as String? ?? '',
      languageSource: json['languageSource'] as String? ?? '',
      languageTarget: json['languageTarget'] as String? ?? '',
      unit: json['unit'] as int? ?? 1,
      lesson: json['lesson'] as int? ?? 1,
      questionNumber: json['questionNumber'] as int? ?? 0,
      questionType: json['questionType'] as String? ?? 'multiple_choice',
      question: json['question'] as String? ?? '',
      answers: json['answers'] as String? ?? '',
      rightAnswer: json['rightAnswer'] as String? ?? '',
      hint: json['hint'] as String? ?? '',
      media: json['media'] as String? ?? '',
      quickHint: json['quickHint'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'languageSource': languageSource,
      'languageTarget': languageTarget,
      'unit': unit,
      'lesson': lesson,
      'questionNumber': questionNumber,
      'questionType': questionType,
      'question': question,
      'answers': answers,
      'rightAnswer': rightAnswer,
      'hint': hint,
      'media': media,
      'quickHint': quickHint,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'languageSource': languageSource,
      'languageTarget': languageTarget,
      'unit': unit,
      'lesson': lesson,
      'questionNumber': questionNumber,
      'questionType': questionType,
      'question': question,
      'answers': answers,
      'rightAnswer': rightAnswer,
      'hint': hint,
      'media': media,
      'quickHint': quickHint,
    };
  }
}
