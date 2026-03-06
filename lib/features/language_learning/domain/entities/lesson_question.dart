import 'package:equatable/equatable.dart';

/// Flat entity representing a single question in the `lessons` Firestore
/// collection.  Uses the @/# encoding schema:
///   • `@word`  → tappable gold-underlined word with quick-hint tooltip
///   • `#`      → answer slot (chip selector or text input)
class LessonQuestion extends Equatable {
  final String id;
  final String languageSource; // e.g. "IT"
  final String languageTarget; // e.g. "EN"
  final int unit;
  final int lesson;
  final int questionNumber;

  /// Matches [ExerciseType] enum name, e.g. "multiple_choice"
  final String questionType;

  /// Question text with optional @/# encoding
  final String question;

  /// Pipe-separated answer options  (e.g. "Hello|Goodbye|Thanks|Please")
  final String answers;

  /// The correct answer string
  final String rightAnswer;

  /// Pipe-separated hint lines
  final String hint;

  /// Optional media URL (audio / image)
  final String media;

  /// Pipe-separated quick hints that map to each @word in [question]
  final String quickHint;

  const LessonQuestion({
    required this.id,
    required this.languageSource,
    required this.languageTarget,
    required this.unit,
    required this.lesson,
    required this.questionNumber,
    required this.questionType,
    required this.question,
    required this.answers,
    required this.rightAnswer,
    this.hint = '',
    this.media = '',
    this.quickHint = '',
  });

  @override
  List<Object?> get props => [
        id,
        languageSource,
        languageTarget,
        unit,
        lesson,
        questionNumber,
        questionType,
        question,
        answers,
        rightAnswer,
        hint,
        media,
        quickHint,
      ];
}
