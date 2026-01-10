import 'package:equatable/equatable.dart';

/// Represents a phrase or word in the language learning system
class LanguagePhrase extends Equatable {
  final String id;
  final String phrase;
  final String translation;
  final String languageCode;
  final String languageName;
  final String? pronunciation;
  final String? audioUrl;
  final PhraseCategory category;
  final PhraseDifficulty difficulty;
  final int requiredLevel;
  final bool isPremium;
  final DateTime? createdAt;

  const LanguagePhrase({
    required this.id,
    required this.phrase,
    required this.translation,
    required this.languageCode,
    required this.languageName,
    this.pronunciation,
    this.audioUrl,
    required this.category,
    required this.difficulty,
    this.requiredLevel = 1,
    this.isPremium = false,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        phrase,
        translation,
        languageCode,
        languageName,
        pronunciation,
        audioUrl,
        category,
        difficulty,
        requiredLevel,
        isPremium,
        createdAt,
      ];
}

enum PhraseCategory {
  greetings,
  compliments,
  flirty,
  conversationStarters,
  datePlanning,
  videoCall,
  travelCulture,
  romantic,
  casual,
  idioms,
}

extension PhraseCategoryExtension on PhraseCategory {
  String get displayName {
    switch (this) {
      case PhraseCategory.greetings:
        return 'Greetings';
      case PhraseCategory.compliments:
        return 'Compliments';
      case PhraseCategory.flirty:
        return 'Flirty Phrases';
      case PhraseCategory.conversationStarters:
        return 'Conversation Starters';
      case PhraseCategory.datePlanning:
        return 'Date Planning';
      case PhraseCategory.videoCall:
        return 'Video Call';
      case PhraseCategory.travelCulture:
        return 'Travel & Culture';
      case PhraseCategory.romantic:
        return 'Romantic';
      case PhraseCategory.casual:
        return 'Casual Chat';
      case PhraseCategory.idioms:
        return 'Idioms & Slang';
    }
  }

  String get icon {
    switch (this) {
      case PhraseCategory.greetings:
        return '👋';
      case PhraseCategory.compliments:
        return '💫';
      case PhraseCategory.flirty:
        return '😏';
      case PhraseCategory.conversationStarters:
        return '💬';
      case PhraseCategory.datePlanning:
        return '📅';
      case PhraseCategory.videoCall:
        return '📹';
      case PhraseCategory.travelCulture:
        return '✈️';
      case PhraseCategory.romantic:
        return '❤️';
      case PhraseCategory.casual:
        return '🗣️';
      case PhraseCategory.idioms:
        return '🎭';
    }
  }
}

enum PhraseDifficulty {
  beginner,
  intermediate,
  advanced,
  fluent,
}

extension PhraseDifficultyExtension on PhraseDifficulty {
  String get displayName {
    switch (this) {
      case PhraseDifficulty.beginner:
        return 'Beginner';
      case PhraseDifficulty.intermediate:
        return 'Intermediate';
      case PhraseDifficulty.advanced:
        return 'Advanced';
      case PhraseDifficulty.fluent:
        return 'Fluent';
    }
  }

  String get emoji {
    switch (this) {
      case PhraseDifficulty.beginner:
        return '🌱';
      case PhraseDifficulty.intermediate:
        return '🌿';
      case PhraseDifficulty.advanced:
        return '🌳';
      case PhraseDifficulty.fluent:
        return '🏆';
    }
  }

  int get requiredWordsLearned {
    switch (this) {
      case PhraseDifficulty.beginner:
        return 0;
      case PhraseDifficulty.intermediate:
        return 25;
      case PhraseDifficulty.advanced:
        return 100;
      case PhraseDifficulty.fluent:
        return 500;
    }
  }
}
