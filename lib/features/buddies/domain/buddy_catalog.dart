import 'buddy_topics.dart';

export 'buddy_topics.dart';

/// GreenGo Buddies enums and limits. Mirrors functions/src/buddies/model.ts:
/// the server validates every value, so an id that is not listed here is
/// refused there too.
class BuddyCatalog {
  BuddyCatalog._();

  static const List<String> roles = <String>[
    'friend',
    'expert',
    'teacher',
    'coach',
    'conversation_partner',
    'debate_partner',
  ];

  static const List<String> tones = <String>[
    'warm',
    'funny',
    'calm',
    'direct',
    'formal',
    'playful',
  ];

  static const List<String> levels = <String>['beginner', 'intermediate', 'expert'];

  static const List<String> cefrLevels = <String>['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

  static const List<String> languages = <String>['en', 'de', 'es', 'fr', 'it', 'pt', 'pt_BR'];

  /// Drawn avatars (never photos): `buddy_01` .. `buddy_24`.
  static final List<String> avatars = List<String>.unmodifiable(
    List<String>.generate(24, (i) => 'buddy_${(i + 1).toString().padLeft(2, '0')}'),
  );

  /// Max characters of one message to a Buddy (server USER_MESSAGE_MAX).
  static const int maxMessageChars = 500;

  /// Max characters of a Buddy name (server cleanName).
  static const int maxNameChars = 24;

  static final RegExp _nameChars = RegExp(r"^[\p{L}\p{N} .'\-]+$", unicode: true);

  /// The name as the server stores it (trimmed, single spaces), or null when
  /// the server would refuse it (1-24 letters / digits / space . ' -).
  static String? cleanName(String raw) {
    final s = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (s.isEmpty || s.runes.length > maxNameChars || !_nameChars.hasMatch(s)) {
      return null;
    }
    return s;
  }

  static final Map<String, BuddyTopic> _byId = {
    for (final t in kBuddyTopics) t.id: t,
  };

  static BuddyTopic? topicById(String id) => _byId[id];

  static bool isKnownTopic(String id) => _byId.containsKey(id);

  /// Topics where a CEFR level (A1..C2) makes sense: language practice.
  static bool isLanguageTopic(String topicId) =>
      topicId.startsWith('practice_') ||
      topicId == 'pronunciation' ||
      topicId == 'slang_idioms' ||
      topicId == 'travel_phrases';

  /// The language a practice topic is about (the Buddy should speak it).
  static String? practiceLanguage(String topicId) {
    switch (topicId) {
      case 'practice_english':
        return 'en';
      case 'practice_italian':
        return 'it';
      case 'practice_spanish':
        return 'es';
      case 'practice_french':
        return 'fr';
      case 'practice_german':
        return 'de';
      case 'practice_portuguese':
        return 'pt';
      default:
        return null;
    }
  }

  /// Avatar index 0..23 of an avatar id (unknown ids fall back to 0).
  static int avatarIndex(String avatarId) {
    final i = avatars.indexOf(avatarId);
    return i < 0 ? 0 : i;
  }

  /// The Buddy language closest to an app locale (`pt_BR` stays Brazilian).
  static String languageForLocale(String languageCode, [String? countryCode]) {
    if (languageCode == 'pt') return countryCode == 'BR' ? 'pt_BR' : 'pt';
    return languages.contains(languageCode) ? languageCode : 'en';
  }
}

/// A ready-made Buddy in the builder ("Italian teacher", "Running coach").
class BuddySuggestion {
  const BuddySuggestion({
    required this.id,
    required this.topic,
    required this.role,
    required this.tone,
    required this.avatar,
    this.language,
    this.level = 'beginner',
  });

  /// Stable id; the label comes from `buddySuggest<Id>` (see buddy_labels).
  final String id;
  final String topic;
  final String role;
  final String tone;
  final String avatar;

  /// Fixed Buddy language (language practice), or null = the app language.
  final String? language;
  final String level;

  static const List<BuddySuggestion> all = <BuddySuggestion>[
    BuddySuggestion(
        id: 'italian_teacher',
        topic: 'practice_italian',
        role: 'teacher',
        tone: 'warm',
        avatar: 'buddy_03',
        language: 'it'),
    BuddySuggestion(
        id: 'english_partner',
        topic: 'practice_english',
        role: 'conversation_partner',
        tone: 'playful',
        avatar: 'buddy_07',
        language: 'en',
        level: 'intermediate'),
    BuddySuggestion(
        id: 'running_coach', topic: 'running', role: 'coach', tone: 'direct', avatar: 'buddy_11'),
    BuddySuggestion(
        id: 'movie_buddy', topic: 'movies', role: 'friend', tone: 'funny', avatar: 'buddy_15'),
    BuddySuggestion(
        id: 'travel_planner',
        topic: 'budget_travel',
        role: 'expert',
        tone: 'warm',
        avatar: 'buddy_19'),
    BuddySuggestion(
        id: 'cooking_friend', topic: 'cooking', role: 'friend', tone: 'playful', avatar: 'buddy_05'),
    BuddySuggestion(
        id: 'interview_coach',
        topic: 'job_interviews',
        role: 'coach',
        tone: 'formal',
        avatar: 'buddy_22',
        level: 'intermediate'),
    BuddySuggestion(
        id: 'debate_partner',
        topic: 'debate_partner',
        role: 'debate_partner',
        tone: 'calm',
        avatar: 'buddy_09',
        level: 'intermediate'),
  ];
}
