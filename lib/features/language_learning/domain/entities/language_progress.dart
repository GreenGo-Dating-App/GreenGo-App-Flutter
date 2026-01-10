import 'package:equatable/equatable.dart';
import 'language_phrase.dart';

/// Tracks user's progress in learning a specific language
class LanguageProgress extends Equatable {
  final String userId;
  final String languageCode;
  final String languageName;
  final int wordsLearned;
  final int phrasesLearned;
  final int totalXpEarned;
  final LanguageProficiency proficiency;
  final List<String> learnedPhraseIds;
  final List<String> favoritesPhraseIds;
  final int translationsCount;
  final int quizzesTaken;
  final int quizzesPerfect;
  final DateTime? lastPracticeDate;
  final DateTime? startedLearningAt;

  const LanguageProgress({
    required this.userId,
    required this.languageCode,
    required this.languageName,
    this.wordsLearned = 0,
    this.phrasesLearned = 0,
    this.totalXpEarned = 0,
    this.proficiency = LanguageProficiency.beginner,
    this.learnedPhraseIds = const [],
    this.favoritesPhraseIds = const [],
    this.translationsCount = 0,
    this.quizzesTaken = 0,
    this.quizzesPerfect = 0,
    this.lastPracticeDate,
    this.startedLearningAt,
  });

  LanguageProgress copyWith({
    String? userId,
    String? languageCode,
    String? languageName,
    int? wordsLearned,
    int? phrasesLearned,
    int? totalXpEarned,
    LanguageProficiency? proficiency,
    List<String>? learnedPhraseIds,
    List<String>? favoritesPhraseIds,
    int? translationsCount,
    int? quizzesTaken,
    int? quizzesPerfect,
    DateTime? lastPracticeDate,
    DateTime? startedLearningAt,
  }) {
    return LanguageProgress(
      userId: userId ?? this.userId,
      languageCode: languageCode ?? this.languageCode,
      languageName: languageName ?? this.languageName,
      wordsLearned: wordsLearned ?? this.wordsLearned,
      phrasesLearned: phrasesLearned ?? this.phrasesLearned,
      totalXpEarned: totalXpEarned ?? this.totalXpEarned,
      proficiency: proficiency ?? this.proficiency,
      learnedPhraseIds: learnedPhraseIds ?? this.learnedPhraseIds,
      favoritesPhraseIds: favoritesPhraseIds ?? this.favoritesPhraseIds,
      translationsCount: translationsCount ?? this.translationsCount,
      quizzesTaken: quizzesTaken ?? this.quizzesTaken,
      quizzesPerfect: quizzesPerfect ?? this.quizzesPerfect,
      lastPracticeDate: lastPracticeDate ?? this.lastPracticeDate,
      startedLearningAt: startedLearningAt ?? this.startedLearningAt,
    );
  }

  /// Calculate proficiency based on words learned
  static LanguageProficiency calculateProficiency(int wordsLearned) {
    if (wordsLearned >= 1000) return LanguageProficiency.fluent;
    if (wordsLearned >= 500) return LanguageProficiency.advanced;
    if (wordsLearned >= 100) return LanguageProficiency.intermediate;
    return LanguageProficiency.beginner;
  }

  @override
  List<Object?> get props => [
        userId,
        languageCode,
        languageName,
        wordsLearned,
        phrasesLearned,
        totalXpEarned,
        proficiency,
        learnedPhraseIds,
        favoritesPhraseIds,
        translationsCount,
        quizzesTaken,
        quizzesPerfect,
        lastPracticeDate,
        startedLearningAt,
      ];
}

enum LanguageProficiency {
  beginner,
  intermediate,
  advanced,
  fluent,
}

extension LanguageProficiencyExtension on LanguageProficiency {
  String get displayName {
    switch (this) {
      case LanguageProficiency.beginner:
        return 'Beginner';
      case LanguageProficiency.intermediate:
        return 'Intermediate';
      case LanguageProficiency.advanced:
        return 'Advanced';
      case LanguageProficiency.fluent:
        return 'Fluent';
    }
  }

  String get emoji {
    switch (this) {
      case LanguageProficiency.beginner:
        return '🌱';
      case LanguageProficiency.intermediate:
        return '🌿';
      case LanguageProficiency.advanced:
        return '🌳';
      case LanguageProficiency.fluent:
        return '🏆';
    }
  }

  String get badgeName {
    switch (this) {
      case LanguageProficiency.beginner:
        return 'Language Seedling';
      case LanguageProficiency.intermediate:
        return 'Growing Linguist';
      case LanguageProficiency.advanced:
        return 'Language Tree';
      case LanguageProficiency.fluent:
        return 'Language Champion';
    }
  }

  int get requiredWords {
    switch (this) {
      case LanguageProficiency.beginner:
        return 0;
      case LanguageProficiency.intermediate:
        return 25;
      case LanguageProficiency.advanced:
        return 100;
      case LanguageProficiency.fluent:
        return 500;
    }
  }
}
