import 'package:equatable/equatable.dart';

/// A single quiz question with multiple choice answers
class QuizQuestion extends Equatable {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  @override
  List<Object?> get props => [question, options, correctIndex, explanation];
}

/// Safety Academy Quiz Entity
///
/// An optional quiz attached to the end of a safety lesson.
/// Users must achieve the passing score to complete the lesson with full XP.
class SafetyQuiz extends Equatable {
  final String id;
  final String lessonId;
  final List<QuizQuestion> questions;
  final int passingScore;

  const SafetyQuiz({
    required this.id,
    required this.lessonId,
    required this.questions,
    this.passingScore = 80,
  });

  @override
  List<Object?> get props => [id, lessonId, questions, passingScore];
}
