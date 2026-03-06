import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for pre-built Translation Race questions.
/// Each question has a word, correct answer, and 11 wrong options.
class TranslationRaceQuestionModel {
  final String id;
  final String word;
  final String sourceLang;
  final String targetLang;
  final String correctAnswer;
  final List<String> wrongOptions;
  final int difficulty;
  final String category;

  const TranslationRaceQuestionModel({
    required this.id,
    required this.word,
    required this.sourceLang,
    required this.targetLang,
    required this.correctAnswer,
    required this.wrongOptions,
    required this.difficulty,
    required this.category,
  });

  /// All 12 options (1 correct + 11 wrong), shuffled.
  List<String> get allOptions {
    final options = [correctAnswer, ...wrongOptions];
    options.shuffle();
    return options;
  }

  factory TranslationRaceQuestionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TranslationRaceQuestionModel(
      id: doc.id,
      word: data['word'] as String? ?? '',
      sourceLang: data['sourceLang'] as String? ?? '',
      targetLang: data['targetLang'] as String? ?? '',
      correctAnswer: data['correctAnswer'] as String? ?? '',
      wrongOptions: List<String>.from(data['wrongOptions'] as List? ?? []),
      difficulty: data['difficulty'] as int? ?? 1,
      category: data['category'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'word': word,
        'sourceLang': sourceLang,
        'targetLang': targetLang,
        'correctAnswer': correctAnswer,
        'wrongOptions': wrongOptions,
        'difficulty': difficulty,
        'category': category,
      };
}
