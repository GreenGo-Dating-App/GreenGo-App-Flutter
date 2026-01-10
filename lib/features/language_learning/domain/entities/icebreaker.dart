import 'package:equatable/equatable.dart';

/// Represents a cultural icebreaker suggestion
class Icebreaker extends Equatable {
  final String id;
  final String phrase;
  final String translation;
  final String languageCode;
  final String languageName;
  final String? pronunciation;
  final String? audioUrl;
  final String countryCode;
  final String countryName;
  final String culturalContext;
  final IcebreakerType type;
  final int xpReward;
  final bool isUsed;
  final DateTime? usedAt;

  const Icebreaker({
    required this.id,
    required this.phrase,
    required this.translation,
    required this.languageCode,
    required this.languageName,
    this.pronunciation,
    this.audioUrl,
    required this.countryCode,
    required this.countryName,
    required this.culturalContext,
    required this.type,
    this.xpReward = 15,
    this.isUsed = false,
    this.usedAt,
  });

  Icebreaker copyWith({
    String? id,
    String? phrase,
    String? translation,
    String? languageCode,
    String? languageName,
    String? pronunciation,
    String? audioUrl,
    String? countryCode,
    String? countryName,
    String? culturalContext,
    IcebreakerType? type,
    int? xpReward,
    bool? isUsed,
    DateTime? usedAt,
  }) {
    return Icebreaker(
      id: id ?? this.id,
      phrase: phrase ?? this.phrase,
      translation: translation ?? this.translation,
      languageCode: languageCode ?? this.languageCode,
      languageName: languageName ?? this.languageName,
      pronunciation: pronunciation ?? this.pronunciation,
      audioUrl: audioUrl ?? this.audioUrl,
      countryCode: countryCode ?? this.countryCode,
      countryName: countryName ?? this.countryName,
      culturalContext: culturalContext ?? this.culturalContext,
      type: type ?? this.type,
      xpReward: xpReward ?? this.xpReward,
      isUsed: isUsed ?? this.isUsed,
      usedAt: usedAt ?? this.usedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        phrase,
        translation,
        languageCode,
        languageName,
        pronunciation,
        audioUrl,
        countryCode,
        countryName,
        culturalContext,
        type,
        xpReward,
        isUsed,
        usedAt,
      ];

  /// Pre-defined icebreakers for various countries
  static List<Icebreaker> getIcebreakersForCountry(String countryCode) {
    return _allIcebreakers
        .where((ib) => ib.countryCode.toLowerCase() == countryCode.toLowerCase())
        .toList();
  }

  static const List<Icebreaker> _allIcebreakers = [
    // Spanish (Spain)
    Icebreaker(
      id: 'es_greeting_1',
      phrase: '¡Hola! ¿Qué tal?',
      translation: 'Hello! How are you?',
      languageCode: 'es',
      languageName: 'Spanish',
      pronunciation: 'OH-lah keh TAHL',
      countryCode: 'ES',
      countryName: 'Spain',
      culturalContext: 'Casual greeting, shows friendliness',
      type: IcebreakerType.greeting,
    ),
    Icebreaker(
      id: 'es_compliment_1',
      phrase: 'Tienes una sonrisa muy bonita',
      translation: 'You have a very beautiful smile',
      languageCode: 'es',
      languageName: 'Spanish',
      pronunciation: 'tee-EH-nehs OO-nah sohn-REE-sah mwee boh-NEE-tah',
      countryCode: 'ES',
      countryName: 'Spain',
      culturalContext: 'A sincere compliment that\'s well-received in Spanish culture',
      type: IcebreakerType.compliment,
    ),

    // French (France)
    Icebreaker(
      id: 'fr_greeting_1',
      phrase: 'Salut! Comment ça va?',
      translation: 'Hi! How\'s it going?',
      languageCode: 'fr',
      languageName: 'French',
      pronunciation: 'sah-LOO koh-mohn sah VAH',
      countryCode: 'FR',
      countryName: 'France',
      culturalContext: 'Informal greeting, good for casual conversations',
      type: IcebreakerType.greeting,
    ),
    Icebreaker(
      id: 'fr_interest_1',
      phrase: 'Tu aimes voyager?',
      translation: 'Do you like to travel?',
      languageCode: 'fr',
      languageName: 'French',
      pronunciation: 'too ehm vwah-yah-ZHAY',
      countryCode: 'FR',
      countryName: 'France',
      culturalContext: 'French people love discussing travel experiences',
      type: IcebreakerType.interest,
    ),

    // Japanese (Japan)
    Icebreaker(
      id: 'ja_greeting_1',
      phrase: 'はじめまして!',
      translation: 'Nice to meet you!',
      languageCode: 'ja',
      languageName: 'Japanese',
      pronunciation: 'hah-jee-meh-MASH-teh',
      countryCode: 'JP',
      countryName: 'Japan',
      culturalContext: 'Standard polite first greeting, shows respect',
      type: IcebreakerType.greeting,
    ),
    Icebreaker(
      id: 'ja_interest_1',
      phrase: '趣味は何ですか?',
      translation: 'What are your hobbies?',
      languageCode: 'ja',
      languageName: 'Japanese',
      pronunciation: 'shoo-mee wah nahn DEHS-kah',
      countryCode: 'JP',
      countryName: 'Japan',
      culturalContext: 'Common conversation starter in Japanese dating',
      type: IcebreakerType.interest,
    ),

    // Korean (South Korea)
    Icebreaker(
      id: 'ko_greeting_1',
      phrase: '안녕하세요!',
      translation: 'Hello!',
      languageCode: 'ko',
      languageName: 'Korean',
      pronunciation: 'ahn-nyeong-hah-SEH-yo',
      countryCode: 'KR',
      countryName: 'South Korea',
      culturalContext: 'Polite greeting appropriate for first conversations',
      type: IcebreakerType.greeting,
    ),
    Icebreaker(
      id: 'ko_compliment_1',
      phrase: '너무 예뻐요',
      translation: 'You\'re so pretty',
      languageCode: 'ko',
      languageName: 'Korean',
      pronunciation: 'nuh-moo yeh-PPUH-yo',
      countryCode: 'KR',
      countryName: 'South Korea',
      culturalContext: 'Direct compliments are appreciated in Korean dating culture',
      type: IcebreakerType.compliment,
    ),

    // German (Germany)
    Icebreaker(
      id: 'de_greeting_1',
      phrase: 'Hallo! Wie geht\'s?',
      translation: 'Hello! How are you?',
      languageCode: 'de',
      languageName: 'German',
      pronunciation: 'HAH-loh vee GAYTS',
      countryCode: 'DE',
      countryName: 'Germany',
      culturalContext: 'Casual greeting, Germans appreciate directness',
      type: IcebreakerType.greeting,
    ),
    Icebreaker(
      id: 'de_interest_1',
      phrase: 'Was machst du gerne in deiner Freizeit?',
      translation: 'What do you like to do in your free time?',
      languageCode: 'de',
      languageName: 'German',
      pronunciation: 'vahs MAHKHST doo GEHR-neh in DYE-nehr FRY-tsyt',
      countryCode: 'DE',
      countryName: 'Germany',
      culturalContext: 'Germans value meaningful conversations about interests',
      type: IcebreakerType.interest,
    ),

    // Italian (Italy)
    Icebreaker(
      id: 'it_greeting_1',
      phrase: 'Ciao! Come stai?',
      translation: 'Hi! How are you?',
      languageCode: 'it',
      languageName: 'Italian',
      pronunciation: 'CHOW KOH-meh STYE',
      countryCode: 'IT',
      countryName: 'Italy',
      culturalContext: 'Warm, friendly greeting typical of Italian culture',
      type: IcebreakerType.greeting,
    ),
    Icebreaker(
      id: 'it_compliment_1',
      phrase: 'Hai degli occhi bellissimi',
      translation: 'You have beautiful eyes',
      languageCode: 'it',
      languageName: 'Italian',
      pronunciation: 'eye DEH-lyee OH-kee beh-LEE-see-mee',
      countryCode: 'IT',
      countryName: 'Italy',
      culturalContext: 'Italians are expressive and appreciate romantic compliments',
      type: IcebreakerType.compliment,
    ),

    // Portuguese (Brazil)
    Icebreaker(
      id: 'pt_greeting_1',
      phrase: 'Oi! Tudo bem?',
      translation: 'Hi! Everything good?',
      languageCode: 'pt-BR',
      languageName: 'Brazilian Portuguese',
      pronunciation: 'oy TOO-doo beng',
      countryCode: 'BR',
      countryName: 'Brazil',
      culturalContext: 'Brazilians are warm and friendly, this is a casual greeting',
      type: IcebreakerType.greeting,
    ),
    Icebreaker(
      id: 'pt_interest_1',
      phrase: 'Você gosta de música?',
      translation: 'Do you like music?',
      languageCode: 'pt-BR',
      languageName: 'Brazilian Portuguese',
      pronunciation: 'voh-SEH GOHSH-tah jee MOO-zee-kah',
      countryCode: 'BR',
      countryName: 'Brazil',
      culturalContext: 'Music is central to Brazilian culture, great conversation starter',
      type: IcebreakerType.interest,
    ),

    // Chinese (China)
    Icebreaker(
      id: 'zh_greeting_1',
      phrase: '你好! 很高兴认识你',
      translation: 'Hello! Nice to meet you',
      languageCode: 'zh',
      languageName: 'Chinese',
      pronunciation: 'nee-HOW hern gow-shing ren-shih nee',
      countryCode: 'CN',
      countryName: 'China',
      culturalContext: 'Polite introduction, shows respect for the other person',
      type: IcebreakerType.greeting,
    ),
    Icebreaker(
      id: 'zh_interest_1',
      phrase: '你喜欢什么美食?',
      translation: 'What kind of food do you like?',
      languageCode: 'zh',
      languageName: 'Chinese',
      pronunciation: 'nee shee-hwahn shuh-muh may-shih',
      countryCode: 'CN',
      countryName: 'China',
      culturalContext: 'Food is important in Chinese culture, great conversation topic',
      type: IcebreakerType.interest,
    ),

    // Arabic (Saudi Arabia/UAE)
    Icebreaker(
      id: 'ar_greeting_1',
      phrase: 'مرحبا! كيف حالك؟',
      translation: 'Hello! How are you?',
      languageCode: 'ar',
      languageName: 'Arabic',
      pronunciation: 'MAR-ha-ba keyf HAH-lak',
      countryCode: 'SA',
      countryName: 'Saudi Arabia',
      culturalContext: 'Warm greeting, Arabic culture values hospitality',
      type: IcebreakerType.greeting,
    ),
    Icebreaker(
      id: 'ar_compliment_1',
      phrase: 'ما شاء الله',
      translation: 'God has willed it (expressing admiration)',
      languageCode: 'ar',
      languageName: 'Arabic',
      pronunciation: 'mah shah AH-lah',
      countryCode: 'SA',
      countryName: 'Saudi Arabia',
      culturalContext: 'Used to express admiration while avoiding evil eye, culturally appropriate',
      type: IcebreakerType.compliment,
    ),

    // Russian (Russia)
    Icebreaker(
      id: 'ru_greeting_1',
      phrase: 'Привет! Как дела?',
      translation: 'Hi! How are you?',
      languageCode: 'ru',
      languageName: 'Russian',
      pronunciation: 'pree-VYET kahk dee-LAH',
      countryCode: 'RU',
      countryName: 'Russia',
      culturalContext: 'Casual greeting, expect an honest answer in Russian culture',
      type: IcebreakerType.greeting,
    ),
    Icebreaker(
      id: 'ru_interest_1',
      phrase: 'Чем ты увлекаешься?',
      translation: 'What are you passionate about?',
      languageCode: 'ru',
      languageName: 'Russian',
      pronunciation: 'chem tee oo-vle-KAH-yesh-sya',
      countryCode: 'RU',
      countryName: 'Russia',
      culturalContext: 'Russians appreciate deep, meaningful conversations',
      type: IcebreakerType.interest,
    ),
  ];
}

enum IcebreakerType {
  greeting,
  compliment,
  interest,
  question,
  cultural,
}

extension IcebreakerTypeExtension on IcebreakerType {
  String get displayName {
    switch (this) {
      case IcebreakerType.greeting:
        return 'Greeting';
      case IcebreakerType.compliment:
        return 'Compliment';
      case IcebreakerType.interest:
        return 'Interest Question';
      case IcebreakerType.question:
        return 'Question';
      case IcebreakerType.cultural:
        return 'Cultural';
    }
  }

  String get icon {
    switch (this) {
      case IcebreakerType.greeting:
        return '👋';
      case IcebreakerType.compliment:
        return '💫';
      case IcebreakerType.interest:
        return '❓';
      case IcebreakerType.question:
        return '💭';
      case IcebreakerType.cultural:
        return '🌍';
    }
  }
}
