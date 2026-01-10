import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/language_phrase.dart';

class LanguagePhraseModel extends LanguagePhrase {
  const LanguagePhraseModel({
    required super.id,
    required super.phrase,
    required super.translation,
    required super.languageCode,
    required super.languageName,
    super.pronunciation,
    super.audioUrl,
    required super.category,
    required super.difficulty,
    super.requiredLevel,
    super.isPremium,
    super.createdAt,
  });

  factory LanguagePhraseModel.fromJson(Map<String, dynamic> json) {
    return LanguagePhraseModel(
      id: json['id'] as String,
      phrase: json['phrase'] as String,
      translation: json['translation'] as String,
      languageCode: json['languageCode'] as String,
      languageName: json['languageName'] as String,
      pronunciation: json['pronunciation'] as String?,
      audioUrl: json['audioUrl'] as String?,
      category: PhraseCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => PhraseCategory.greetings,
      ),
      difficulty: PhraseDifficulty.values.firstWhere(
        (e) => e.name == json['difficulty'],
        orElse: () => PhraseDifficulty.beginner,
      ),
      requiredLevel: json['requiredLevel'] as int? ?? 1,
      isPremium: json['isPremium'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phrase': phrase,
      'translation': translation,
      'languageCode': languageCode,
      'languageName': languageName,
      'pronunciation': pronunciation,
      'audioUrl': audioUrl,
      'category': category.name,
      'difficulty': difficulty.name,
      'requiredLevel': requiredLevel,
      'isPremium': isPremium,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }

  factory LanguagePhraseModel.fromEntity(LanguagePhrase entity) {
    return LanguagePhraseModel(
      id: entity.id,
      phrase: entity.phrase,
      translation: entity.translation,
      languageCode: entity.languageCode,
      languageName: entity.languageName,
      pronunciation: entity.pronunciation,
      audioUrl: entity.audioUrl,
      category: entity.category,
      difficulty: entity.difficulty,
      requiredLevel: entity.requiredLevel,
      isPremium: entity.isPremium,
      createdAt: entity.createdAt,
    );
  }
}
