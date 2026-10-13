import 'package:shared_preferences/shared_preferences.dart';

/// Chat display settings in SharedPreferences: global keys `chat_<name>` and,
/// for a chat saved with "this chat only", `chat_<matchId>_<name>` plus
/// `chat_<matchId>_hasCustomSettings`.
class ChatSettingsPrefs {
  ChatSettingsPrefs._();

  /// Every per-chat setting name (the chat's language is NOT one of them:
  /// it stays per chat on purpose).
  static const List<String> names = [
    'showOriginalText',
    'showDifficultyBadge',
    'showGrammarCheck',
    'showCulturalTips',
    'showIcebreakers',
    'showSentences',
    'showPronunciation',
    'ttsReadTranslated',
    'showLanguageFlags',
    'showXpBar',
    'showPhraseOfDay',
  ];

  static const String _customFlag = 'hasCustomSettings';

  /// "Save for all chats": writes the global values AND removes every chat's
  /// own override, otherwise a chat once saved with "this chat only" would
  /// keep ignoring the global settings.
  static Future<void> saveForAllChats(SharedPreferences prefs, Map<String, bool> values) async {
    for (final e in values.entries) {
      await prefs.setBool('chat_${e.key}', e.value);
    }
    final flags = prefs.getKeys().where((k) => k.startsWith('chat_') && k.endsWith('_$_customFlag')).toList();
    for (final flag in flags) {
      final prefix = flag.substring(0, flag.length - _customFlag.length); // chat_<matchId>_
      for (final n in names) {
        await prefs.remove('$prefix$n');
      }
      await prefs.remove(flag);
    }
  }

  /// "Save for this chat": the values under the chat's own prefix.
  static Future<void> saveForChat(SharedPreferences prefs, String matchId, Map<String, bool> values) async {
    final prefix = 'chat_${matchId}_';
    for (final e in values.entries) {
      await prefs.setBool('$prefix${e.key}', e.value);
    }
    await prefs.setBool('$prefix$_customFlag', true);
  }

  /// The prefix to read for [matchId]: its own when saved for this chat,
  /// else the global one.
  static String readPrefix(SharedPreferences prefs, String matchId) {
    final own = 'chat_${matchId}_';
    return (prefs.getBool('$own$_customFlag') ?? false) ? own : 'chat_';
  }
}
