import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/chat/data/chat_settings_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('save for all chats overrides chats saved for "this chat only"', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    // Chat A was saved for itself with cultural tips on.
    await ChatSettingsPrefs.saveForChat(prefs, 'A', {'showCulturalTips': true, 'showIcebreakers': true});
    await prefs.setString('chat_A_language', 'it'); // per-chat language stays
    expect(ChatSettingsPrefs.readPrefix(prefs, 'A'), 'chat_A_');

    // Now "save for all chats" with them off.
    await ChatSettingsPrefs.saveForAllChats(prefs, {'showCulturalTips': false, 'showIcebreakers': false});

    for (final chat in ['A', 'B']) {
      final p = ChatSettingsPrefs.readPrefix(prefs, chat);
      expect(p, 'chat_', reason: chat);
      expect(prefs.getBool('${p}showCulturalTips'), isFalse);
      expect(prefs.getBool('${p}showIcebreakers'), isFalse);
    }
    expect(prefs.getBool('chat_A_showCulturalTips'), isNull);
    expect(prefs.getString('chat_A_language'), 'it');
  });

  test('save for this chat only touches that chat', () async {
    SharedPreferences.setMockInitialValues({'chat_showSentences': true});
    final prefs = await SharedPreferences.getInstance();
    await ChatSettingsPrefs.saveForChat(prefs, 'A', {'showSentences': false});
    expect(prefs.getBool('${ChatSettingsPrefs.readPrefix(prefs, 'A')}showSentences'), isFalse);
    expect(prefs.getBool('${ChatSettingsPrefs.readPrefix(prefs, 'B')}showSentences'), isTrue);
  });
}
