import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/flashcard.dart';
import '../../domain/entities/language_phrase.dart';
import 'language_phrase_model.dart';

class FlashcardModel extends Flashcard {
  const FlashcardModel({
    required super.id,
    required super.phrase,
    super.status,
    super.reviewCount,
    super.correctCount,
    super.incorrectCount,
    super.lastReviewedAt,
    super.nextReviewAt,
    super.streak,
    super.easeFactor,
  });

  factory FlashcardModel.fromJson(Map<String, dynamic> json) {
    return FlashcardModel(
      id: json['id'] as String,
      phrase: LanguagePhraseModel.fromJson(json['phrase'] as Map<String, dynamic>),
      status: FlashcardStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => FlashcardStatus.newCard,
      ),
      reviewCount: json['reviewCount'] as int? ?? 0,
      correctCount: json['correctCount'] as int? ?? 0,
      incorrectCount: json['incorrectCount'] as int? ?? 0,
      lastReviewedAt: json['lastReviewedAt'] != null
          ? (json['lastReviewedAt'] as Timestamp).toDate()
          : null,
      nextReviewAt: json['nextReviewAt'] != null
          ? (json['nextReviewAt'] as Timestamp).toDate()
          : null,
      streak: json['streak'] as int? ?? 0,
      easeFactor: (json['easeFactor'] as num?)?.toDouble() ?? 2.5,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phrase': (phrase is LanguagePhraseModel)
          ? (phrase as LanguagePhraseModel).toJson()
          : LanguagePhraseModel.fromEntity(phrase).toJson(),
      'status': status.name,
      'reviewCount': reviewCount,
      'correctCount': correctCount,
      'incorrectCount': incorrectCount,
      'lastReviewedAt': lastReviewedAt != null
          ? Timestamp.fromDate(lastReviewedAt!)
          : null,
      'nextReviewAt': nextReviewAt != null
          ? Timestamp.fromDate(nextReviewAt!)
          : null,
      'streak': streak,
      'easeFactor': easeFactor,
    };
  }

  factory FlashcardModel.fromEntity(Flashcard entity) {
    return FlashcardModel(
      id: entity.id,
      phrase: entity.phrase,
      status: entity.status,
      reviewCount: entity.reviewCount,
      correctCount: entity.correctCount,
      incorrectCount: entity.incorrectCount,
      lastReviewedAt: entity.lastReviewedAt,
      nextReviewAt: entity.nextReviewAt,
      streak: entity.streak,
      easeFactor: entity.easeFactor,
    );
  }
}

class FlashcardDeckModel extends FlashcardDeck {
  const FlashcardDeckModel({
    required super.id,
    required super.name,
    required super.description,
    required super.languageCode,
    required super.category,
    super.cards,
    super.isPremium,
    super.coinPrice,
    super.isOwned,
    super.purchasedAt,
  });

  factory FlashcardDeckModel.fromJson(Map<String, dynamic> json) {
    return FlashcardDeckModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      languageCode: json['languageCode'] as String,
      category: PhraseCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => PhraseCategory.greetings,
      ),
      cards: (json['cards'] as List<dynamic>?)
              ?.map((e) => FlashcardModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isPremium: json['isPremium'] as bool? ?? false,
      coinPrice: json['coinPrice'] as int? ?? 0,
      isOwned: json['isOwned'] as bool? ?? false,
      purchasedAt: json['purchasedAt'] != null
          ? (json['purchasedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'languageCode': languageCode,
      'category': category.name,
      'cards': cards
          .map((c) => c is FlashcardModel
              ? c.toJson()
              : FlashcardModel.fromEntity(c).toJson())
          .toList(),
      'isPremium': isPremium,
      'coinPrice': coinPrice,
      'isOwned': isOwned,
      'purchasedAt':
          purchasedAt != null ? Timestamp.fromDate(purchasedAt!) : null,
    };
  }

  factory FlashcardDeckModel.fromEntity(FlashcardDeck entity) {
    return FlashcardDeckModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      languageCode: entity.languageCode,
      category: entity.category,
      cards: entity.cards,
      isPremium: entity.isPremium,
      coinPrice: entity.coinPrice,
      isOwned: entity.isOwned,
      purchasedAt: entity.purchasedAt,
    );
  }
}
