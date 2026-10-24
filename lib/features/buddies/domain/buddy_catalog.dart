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

  /// Legacy drawn avatars `buddy_01` .. `buddy_24` (Buddies created before
  /// 2026-10-24, and the fallback when the pictures can not be loaded).
  /// New Buddies use a `buddy_avatars` picture id.
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

  /// True for a legacy drawn avatar id (`buddy_01` .. `buddy_24`).
  static bool isLegacyAvatar(String avatarId) => avatars.contains(avatarId);

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
