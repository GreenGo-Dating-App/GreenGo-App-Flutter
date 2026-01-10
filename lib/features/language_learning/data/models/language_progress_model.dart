import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/language_progress.dart';

class LanguageProgressModel extends LanguageProgress {
  const LanguageProgressModel({
    required super.userId,
    required super.languageCode,
    required super.languageName,
    super.wordsLearned,
    super.phrasesLearned,
    super.totalXpEarned,
    super.proficiency,
    super.learnedPhraseIds,
    super.favoritesPhraseIds,
    super.translationsCount,
    super.quizzesTaken,
    super.quizzesPerfect,
    super.lastPracticeDate,
    super.startedLearningAt,
  });

  factory LanguageProgressModel.fromJson(Map<String, dynamic> json) {
    return LanguageProgressModel(
      userId: json['userId'] as String,
      languageCode: json['languageCode'] as String,
      languageName: json['languageName'] as String,
      wordsLearned: json['wordsLearned'] as int? ?? 0,
      phrasesLearned: json['phrasesLearned'] as int? ?? 0,
      totalXpEarned: json['totalXpEarned'] as int? ?? 0,
      proficiency: LanguageProficiency.values.firstWhere(
        (e) => e.name == json['proficiency'],
        orElse: () => LanguageProficiency.beginner,
      ),
      learnedPhraseIds: (json['learnedPhraseIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      favoritesPhraseIds: (json['favoritesPhraseIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      translationsCount: json['translationsCount'] as int? ?? 0,
      quizzesTaken: json['quizzesTaken'] as int? ?? 0,
      quizzesPerfect: json['quizzesPerfect'] as int? ?? 0,
      lastPracticeDate: json['lastPracticeDate'] != null
          ? (json['lastPracticeDate'] as Timestamp).toDate()
          : null,
      startedLearningAt: json['startedLearningAt'] != null
          ? (json['startedLearningAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'languageCode': languageCode,
      'languageName': languageName,
      'wordsLearned': wordsLearned,
      'phrasesLearned': phrasesLearned,
      'totalXpEarned': totalXpEarned,
      'proficiency': proficiency.name,
      'learnedPhraseIds': learnedPhraseIds,
      'favoritesPhraseIds': favoritesPhraseIds,
      'translationsCount': translationsCount,
      'quizzesTaken': quizzesTaken,
      'quizzesPerfect': quizzesPerfect,
      'lastPracticeDate': lastPracticeDate != null
          ? Timestamp.fromDate(lastPracticeDate!)
          : null,
      'startedLearningAt': startedLearningAt != null
          ? Timestamp.fromDate(startedLearningAt!)
          : null,
    };
  }

  factory LanguageProgressModel.fromEntity(LanguageProgress entity) {
    return LanguageProgressModel(
      userId: entity.userId,
      languageCode: entity.languageCode,
      languageName: entity.languageName,
      wordsLearned: entity.wordsLearned,
      phrasesLearned: entity.phrasesLearned,
      totalXpEarned: entity.totalXpEarned,
      proficiency: entity.proficiency,
      learnedPhraseIds: entity.learnedPhraseIds,
      favoritesPhraseIds: entity.favoritesPhraseIds,
      translationsCount: entity.translationsCount,
      quizzesTaken: entity.quizzesTaken,
      quizzesPerfect: entity.quizzesPerfect,
      lastPracticeDate: entity.lastPracticeDate,
      startedLearningAt: entity.startedLearningAt,
    );
  }
}
