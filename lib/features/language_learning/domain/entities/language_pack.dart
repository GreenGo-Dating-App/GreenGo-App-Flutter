import 'package:equatable/equatable.dart';
import 'language_phrase.dart';

/// Represents a purchasable language pack
class LanguagePack extends Equatable {
  final String id;
  final String name;
  final String description;
  final String languageCode;
  final String languageName;
  final PhraseCategory category;
  final int phraseCount;
  final int coinPrice;
  final bool isPurchased;
  final DateTime? purchasedAt;
  final String iconEmoji;
  final List<String> previewPhrases;
  final PackTier tier;

  const LanguagePack({
    required this.id,
    required this.name,
    required this.description,
    required this.languageCode,
    required this.languageName,
    required this.category,
    required this.phraseCount,
    required this.coinPrice,
    this.isPurchased = false,
    this.purchasedAt,
    required this.iconEmoji,
    this.previewPhrases = const [],
    this.tier = PackTier.standard,
  });

  LanguagePack copyWith({
    String? id,
    String? name,
    String? description,
    String? languageCode,
    String? languageName,
    PhraseCategory? category,
    int? phraseCount,
    int? coinPrice,
    bool? isPurchased,
    DateTime? purchasedAt,
    String? iconEmoji,
    List<String>? previewPhrases,
    PackTier? tier,
  }) {
    return LanguagePack(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      languageCode: languageCode ?? this.languageCode,
      languageName: languageName ?? this.languageName,
      category: category ?? this.category,
      phraseCount: phraseCount ?? this.phraseCount,
      coinPrice: coinPrice ?? this.coinPrice,
      isPurchased: isPurchased ?? this.isPurchased,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      previewPhrases: previewPhrases ?? this.previewPhrases,
      tier: tier ?? this.tier,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        languageCode,
        languageName,
        category,
        phraseCount,
        coinPrice,
        isPurchased,
        purchasedAt,
        iconEmoji,
        previewPhrases,
        tier,
      ];

  /// Pre-defined language packs available in the shop
  static List<LanguagePack> get availablePacks => [
    // Romantic Phrases Packs
    const LanguagePack(
      id: 'romantic_spanish',
      name: 'Romantic Spanish',
      description: 'Express your feelings in the language of passion',
      languageCode: 'es',
      languageName: 'Spanish',
      category: PhraseCategory.romantic,
      phraseCount: 50,
      coinPrice: 100,
      iconEmoji: '❤️',
      previewPhrases: ['Te quiero', 'Eres hermosa', 'Mi amor'],
      tier: PackTier.standard,
    ),
    const LanguagePack(
      id: 'romantic_french',
      name: 'Romantic French',
      description: 'Learn the language of love',
      languageCode: 'fr',
      languageName: 'French',
      category: PhraseCategory.romantic,
      phraseCount: 50,
      coinPrice: 100,
      iconEmoji: '💕',
      previewPhrases: ['Je t\'aime', 'Tu es belle', 'Mon amour'],
      tier: PackTier.standard,
    ),
    const LanguagePack(
      id: 'romantic_italian',
      name: 'Romantic Italian',
      description: 'Speak amore like a true Italian',
      languageCode: 'it',
      languageName: 'Italian',
      category: PhraseCategory.romantic,
      phraseCount: 50,
      coinPrice: 100,
      iconEmoji: '💖',
      previewPhrases: ['Ti amo', 'Sei bellissima', 'Amore mio'],
      tier: PackTier.standard,
    ),

    // Video Date Vocabulary Packs
    const LanguagePack(
      id: 'videodate_japanese',
      name: 'Video Date Japanese',
      description: 'Impress your Japanese match on video calls',
      languageCode: 'ja',
      languageName: 'Japanese',
      category: PhraseCategory.videoCall,
      phraseCount: 40,
      coinPrice: 150,
      iconEmoji: '📹',
      previewPhrases: ['こんにちは', 'かわいい', 'また話しましょう'],
      tier: PackTier.premium,
    ),
    const LanguagePack(
      id: 'videodate_korean',
      name: 'Video Date Korean',
      description: 'Connect with Korean speakers on video',
      languageCode: 'ko',
      languageName: 'Korean',
      category: PhraseCategory.videoCall,
      phraseCount: 40,
      coinPrice: 150,
      iconEmoji: '🎥',
      previewPhrases: ['안녕하세요', '예뻐요', '다시 이야기해요'],
      tier: PackTier.premium,
    ),

    // Travel & Culture Packs
    const LanguagePack(
      id: 'travel_german',
      name: 'German Explorer',
      description: 'Navigate Germany, Austria, and Switzerland',
      languageCode: 'de',
      languageName: 'German',
      category: PhraseCategory.travelCulture,
      phraseCount: 60,
      coinPrice: 200,
      iconEmoji: '✈️',
      previewPhrases: ['Guten Tag', 'Wo ist...?', 'Prost!'],
      tier: PackTier.premium,
    ),
    const LanguagePack(
      id: 'travel_portuguese',
      name: 'Portuguese Adventure',
      description: 'Explore Brazil and Portugal with confidence',
      languageCode: 'pt',
      languageName: 'Portuguese',
      category: PhraseCategory.travelCulture,
      phraseCount: 60,
      coinPrice: 200,
      iconEmoji: '🌴',
      previewPhrases: ['Olá', 'Obrigado', 'Onde fica...?'],
      tier: PackTier.premium,
    ),

    // Flirty Phrases Packs
    const LanguagePack(
      id: 'flirty_spanish',
      name: 'Flirty Spanish',
      description: 'Playful phrases to spark romance',
      languageCode: 'es',
      languageName: 'Spanish',
      category: PhraseCategory.flirty,
      phraseCount: 45,
      coinPrice: 120,
      iconEmoji: '😏',
      previewPhrases: ['¿Tienes un mapa?', 'Me encantas', 'Eres increíble'],
      tier: PackTier.standard,
    ),
    const LanguagePack(
      id: 'flirty_french',
      name: 'Flirty French',
      description: 'Charm your way in French',
      languageCode: 'fr',
      languageName: 'French',
      category: PhraseCategory.flirty,
      phraseCount: 45,
      coinPrice: 120,
      iconEmoji: '😘',
      previewPhrases: ['Tu as de beaux yeux', 'Je pense à toi', 'Tu me manques'],
      tier: PackTier.standard,
    ),

    // Conversation Starters
    const LanguagePack(
      id: 'conversation_chinese',
      name: 'Chinese Icebreakers',
      description: 'Start conversations with Mandarin speakers',
      languageCode: 'zh',
      languageName: 'Chinese',
      category: PhraseCategory.conversationStarters,
      phraseCount: 35,
      coinPrice: 180,
      iconEmoji: '💬',
      previewPhrases: ['你好', '你是哪里人？', '很高兴认识你'],
      tier: PackTier.premium,
    ),
    const LanguagePack(
      id: 'conversation_arabic',
      name: 'Arabic Connections',
      description: 'Connect with Arabic speakers warmly',
      languageCode: 'ar',
      languageName: 'Arabic',
      category: PhraseCategory.conversationStarters,
      phraseCount: 35,
      coinPrice: 180,
      iconEmoji: '🗣️',
      previewPhrases: ['مرحبا', 'كيف حالك؟', 'تشرفت بمعرفتك'],
      tier: PackTier.premium,
    ),

    // Idioms & Slang Packs
    const LanguagePack(
      id: 'idioms_english',
      name: 'English Idioms',
      description: 'Sound like a native English speaker',
      languageCode: 'en',
      languageName: 'English',
      category: PhraseCategory.idioms,
      phraseCount: 40,
      coinPrice: 100,
      iconEmoji: '🎭',
      previewPhrases: ['Break the ice', 'Hit it off', 'On cloud nine'],
      tier: PackTier.standard,
    ),
    const LanguagePack(
      id: 'idioms_spanish',
      name: 'Spanish Idioms',
      description: 'Master colorful Spanish expressions',
      languageCode: 'es',
      languageName: 'Spanish',
      category: PhraseCategory.idioms,
      phraseCount: 40,
      coinPrice: 100,
      iconEmoji: '🎪',
      previewPhrases: ['Estar en las nubes', 'Tirar la casa por la ventana'],
      tier: PackTier.standard,
    ),

    // Complete Language Bundles
    const LanguagePack(
      id: 'bundle_japanese_complete',
      name: 'Complete Japanese',
      description: 'All Japanese content in one bundle',
      languageCode: 'ja',
      languageName: 'Japanese',
      category: PhraseCategory.casual,
      phraseCount: 200,
      coinPrice: 500,
      iconEmoji: '🇯🇵',
      previewPhrases: ['すみません', 'ありがとう', '大好き'],
      tier: PackTier.bundle,
    ),
    const LanguagePack(
      id: 'bundle_korean_complete',
      name: 'Complete Korean',
      description: 'All Korean content in one bundle',
      languageCode: 'ko',
      languageName: 'Korean',
      category: PhraseCategory.casual,
      phraseCount: 200,
      coinPrice: 500,
      iconEmoji: '🇰🇷',
      previewPhrases: ['감사합니다', '사랑해요', '잘 지내요?'],
      tier: PackTier.bundle,
    ),
  ];
}

enum PackTier {
  standard,
  premium,
  bundle,
}

extension PackTierExtension on PackTier {
  String get displayName {
    switch (this) {
      case PackTier.standard:
        return 'Standard';
      case PackTier.premium:
        return 'Premium';
      case PackTier.bundle:
        return 'Bundle';
    }
  }

  String get badgeColor {
    switch (this) {
      case PackTier.standard:
        return '#4CAF50'; // Green
      case PackTier.premium:
        return '#FFD700'; // Gold
      case PackTier.bundle:
        return '#9C27B0'; // Purple
    }
  }
}
