import 'package:equatable/equatable.dart';
import 'language_phrase.dart';

/// Represents a flashcard for learning phrases
class Flashcard extends Equatable {
  final String id;
  final LanguagePhrase phrase;
  final FlashcardStatus status;
  final int reviewCount;
  final int correctCount;
  final int incorrectCount;
  final DateTime? lastReviewedAt;
  final DateTime? nextReviewAt;
  final int streak;
  final double easeFactor;

  const Flashcard({
    required this.id,
    required this.phrase,
    this.status = FlashcardStatus.newCard,
    this.reviewCount = 0,
    this.correctCount = 0,
    this.incorrectCount = 0,
    this.lastReviewedAt,
    this.nextReviewAt,
    this.streak = 0,
    this.easeFactor = 2.5,
  });

  Flashcard copyWith({
    String? id,
    LanguagePhrase? phrase,
    FlashcardStatus? status,
    int? reviewCount,
    int? correctCount,
    int? incorrectCount,
    DateTime? lastReviewedAt,
    DateTime? nextReviewAt,
    int? streak,
    double? easeFactor,
  }) {
    return Flashcard(
      id: id ?? this.id,
      phrase: phrase ?? this.phrase,
      status: status ?? this.status,
      reviewCount: reviewCount ?? this.reviewCount,
      correctCount: correctCount ?? this.correctCount,
      incorrectCount: incorrectCount ?? this.incorrectCount,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      streak: streak ?? this.streak,
      easeFactor: easeFactor ?? this.easeFactor,
    );
  }

  /// Calculate accuracy percentage
  double get accuracy {
    final total = correctCount + incorrectCount;
    if (total == 0) return 0.0;
    return correctCount / total;
  }

  /// Check if card is due for review
  bool get isDueForReview {
    if (nextReviewAt == null) return true;
    return DateTime.now().isAfter(nextReviewAt!);
  }

  /// Calculate next review date using spaced repetition (SM-2 algorithm simplified)
  DateTime calculateNextReview(FlashcardAnswer answer) {
    final now = DateTime.now();
    int intervalDays;

    switch (answer) {
      case FlashcardAnswer.again:
        intervalDays = 1;
        break;
      case FlashcardAnswer.hard:
        intervalDays = streak <= 1 ? 1 : (streak * 1.2).round();
        break;
      case FlashcardAnswer.good:
        intervalDays = streak <= 1 ? 1 : (streak * easeFactor).round();
        break;
      case FlashcardAnswer.easy:
        intervalDays = streak <= 1 ? 4 : (streak * easeFactor * 1.3).round();
        break;
    }

    return now.add(Duration(days: intervalDays));
  }

  @override
  List<Object?> get props => [
        id,
        phrase,
        status,
        reviewCount,
        correctCount,
        incorrectCount,
        lastReviewedAt,
        nextReviewAt,
        streak,
        easeFactor,
      ];
}

enum FlashcardStatus {
  newCard,
  learning,
  reviewing,
  mastered,
}

extension FlashcardStatusExtension on FlashcardStatus {
  String get displayName {
    switch (this) {
      case FlashcardStatus.newCard:
        return 'New';
      case FlashcardStatus.learning:
        return 'Learning';
      case FlashcardStatus.reviewing:
        return 'Reviewing';
      case FlashcardStatus.mastered:
        return 'Mastered';
    }
  }

  String get color {
    switch (this) {
      case FlashcardStatus.newCard:
        return '#2196F3'; // Blue
      case FlashcardStatus.learning:
        return '#FF9800'; // Orange
      case FlashcardStatus.reviewing:
        return '#4CAF50'; // Green
      case FlashcardStatus.mastered:
        return '#9C27B0'; // Purple
    }
  }
}

enum FlashcardAnswer {
  again,
  hard,
  good,
  easy,
}

extension FlashcardAnswerExtension on FlashcardAnswer {
  String get displayName {
    switch (this) {
      case FlashcardAnswer.again:
        return 'Again';
      case FlashcardAnswer.hard:
        return 'Hard';
      case FlashcardAnswer.good:
        return 'Good';
      case FlashcardAnswer.easy:
        return 'Easy';
    }
  }

  String get color {
    switch (this) {
      case FlashcardAnswer.again:
        return '#F44336'; // Red
      case FlashcardAnswer.hard:
        return '#FF9800'; // Orange
      case FlashcardAnswer.good:
        return '#4CAF50'; // Green
      case FlashcardAnswer.easy:
        return '#2196F3'; // Blue
    }
  }

  int get xpReward {
    switch (this) {
      case FlashcardAnswer.again:
        return 1;
      case FlashcardAnswer.hard:
        return 3;
      case FlashcardAnswer.good:
        return 5;
      case FlashcardAnswer.easy:
        return 7;
    }
  }
}

/// Represents a deck of flashcards
class FlashcardDeck extends Equatable {
  final String id;
  final String name;
  final String description;
  final String languageCode;
  final PhraseCategory category;
  final List<Flashcard> cards;
  final bool isPremium;
  final int coinPrice;
  final bool isOwned;
  final DateTime? purchasedAt;

  const FlashcardDeck({
    required this.id,
    required this.name,
    required this.description,
    required this.languageCode,
    required this.category,
    this.cards = const [],
    this.isPremium = false,
    this.coinPrice = 0,
    this.isOwned = false,
    this.purchasedAt,
  });

  int get totalCards => cards.length;
  int get newCards => cards.where((c) => c.status == FlashcardStatus.newCard).length;
  int get learningCards => cards.where((c) => c.status == FlashcardStatus.learning).length;
  int get masteredCards => cards.where((c) => c.status == FlashcardStatus.mastered).length;
  int get dueCards => cards.where((c) => c.isDueForReview).length;

  double get masteryProgress =>
      totalCards > 0 ? masteredCards / totalCards : 0.0;

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        languageCode,
        category,
        cards,
        isPremium,
        coinPrice,
        isOwned,
        purchasedAt,
      ];
}
