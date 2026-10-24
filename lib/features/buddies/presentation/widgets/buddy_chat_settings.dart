import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../../chat/data/chat_settings_prefs.dart';
import '../buddy_labels.dart';

/// The chat display settings of a Buddy chat: the same settings, keys and
/// storage as the 1:1 chat ([ChatSettingsPrefs]; this chat's id is
/// `buddy_<buddyId>`), limited to the ones that make sense with an AI
/// Buddy (no grammar check, XP bar or phrase of the day). The language the
/// chat is translated into is the Buddy's `chatLanguage` (server, fixed).
class BuddyChatSettings {
  const BuddyChatSettings({this.values = const {}});

  /// The settings a Buddy chat offers, in the 1:1 chat's order.
  static const List<String> names = [
    'showOriginalText',
    'showLanguageFlags',
    'showCulturalTips',
    'showIcebreakers',
    'showSentences',
    'showPronunciation',
    'ttsReadTranslated',
    'highlightMatches',
  ];

  final Map<String, bool> values;

  bool _v(String n) => values[n] ?? true;
  bool get showOriginalText => _v('showOriginalText');
  bool get showLanguageFlags => _v('showLanguageFlags');
  bool get showCulturalTips => _v('showCulturalTips');
  bool get showIcebreakers => _v('showIcebreakers');
  bool get showSentences => _v('showSentences');
  bool get showPronunciation => _v('showPronunciation');
  bool get ttsReadTranslated => _v('ttsReadTranslated');

  /// Colour matching chunks of a message and its translation (Buddy only).
  bool get highlightMatches => _v('highlightMatches');

  Map<String, bool> get all => {for (final n in names) n: _v(n)};

  BuddyChatSettings copyWith({Map<String, bool>? values}) =>
      BuddyChatSettings(values: values ?? this.values);

  BuddyChatSettings toggled(String name, bool value) =>
      copyWith(values: {...all, name: value});

  static String chatId(String buddyId) => 'buddy_$buddyId';

  /// This chat's settings (its own when saved for this chat, else the
  /// global chat settings). Defaults when storage is unavailable.
  static Future<BuddyChatSettings> load(String buddyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = chatId(buddyId);
      final p = ChatSettingsPrefs.readPrefix(prefs, id);
      return BuddyChatSettings(
        values: {for (final n in names) n: prefs.getBool('$p$n') ?? true},
      );
    } catch (_) {
      return const BuddyChatSettings();
    }
  }

  Future<void> saveForThisChat(String buddyId) async {
    final prefs = await SharedPreferences.getInstance();
    await ChatSettingsPrefs.saveForChat(prefs, chatId(buddyId), all);
  }

  Future<void> saveForAllChats() async {
    final prefs = await SharedPreferences.getInstance();
    await ChatSettingsPrefs.saveForAllChats(prefs, all);
  }
}

/// The 1:1 chat's "Languages" menu: what the chat is translated into
/// (read-only: the Buddy's fixed `chatLanguage`) + chat settings.
Future<void> showBuddyChatLanguagesMenu(
  BuildContext context, {
  required String chatLanguage,
  required VoidCallback onSettings,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.backgroundCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.translate, color: AppColors.richGold),
                const SizedBox(width: 8),
                Text(l10n.chatLanguages,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            // Info only: chosen when the Buddy was created, never changed.
            ListTile(
              key: const ValueKey('buddy-chat-language-info'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.language, color: AppColors.textSecondary),
              title: Text(buddyTranslatedIntoLabel(l10n, chatLanguage),
                  style: const TextStyle(color: AppColors.textSecondary)),
              trailing: const Icon(Icons.lock_outline, size: 18, color: AppColors.textTertiary),
            ),
            ListTile(
              key: const ValueKey('buddy-chat-settings'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.tune, color: AppColors.textPrimary),
              title: Text(l10n.chatSettingsTitle,
                  style: const TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(sheet);
                onSettings();
              },
            ),
          ],
        ),
      ),
    ),
  );
}

/// The 1:1 chat's settings sheet (same labels, same "this chat / all chats"
/// saving), with the settings a Buddy chat offers. [onChanged] applies a
/// toggle at once.
Future<void> showBuddyChatSettingsSheet(
  BuildContext context, {
  required String buddyId,
  required BuddyChatSettings settings,
  required ValueChanged<BuddyChatSettings> onChanged,
}) {
  final l10n = AppLocalizations.of(context)!;
  var current = settings;
  final rows = <(String, IconData, String, String)>[
    ('showOriginalText', Icons.text_fields, l10n.chatSettingShowOriginal,
        l10n.chatSettingShowOriginalDesc),
    ('showLanguageFlags', Icons.flag, l10n.chatSettingLanguageFlags,
        l10n.chatSettingLanguageFlagsDesc),
    ('showCulturalTips', Icons.lightbulb_outline, l10n.chatSettingCulturalTips,
        l10n.chatSettingCulturalTipsDesc),
    ('showIcebreakers', Icons.waving_hand_outlined, l10n.chatSettingIcebreakers,
        l10n.chatSettingIcebreakersDesc),
    ('showSentences', Icons.format_quote_outlined, l10n.chatSettingSentences,
        l10n.chatSettingSentencesDesc),
    ('showPronunciation', Icons.volume_up, l10n.chatSettingPronunciation,
        l10n.chatSettingPronunciationDesc),
    ('ttsReadTranslated', Icons.record_voice_over, l10n.chatSettingTtsTranslation,
        l10n.chatSettingTtsTranslationDesc),
    ('highlightMatches', Icons.format_color_text, l10n.buddyChatSettingHighlightMatches,
        l10n.buddyChatSettingHighlightMatchesDesc),
  ];
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.backgroundCard,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) {
        Future<void> save(Future<void> Function() write, String done) async {
          final messenger = ScaffoldMessenger.of(context);
          await write();
          if (ctx.mounted) Navigator.pop(ctx);
          messenger.showSnackBar(SnackBar(content: Text(done)));
        }

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              key: const ValueKey('buddy-chat-settings-sheet'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tune, color: AppColors.richGold),
                    const SizedBox(width: 8),
                    Text(l10n.chatSettingsTitle,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(l10n.chatSettingsSubtitle,
                    style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                const SizedBox(height: 16),
                for (final (name, icon, label, subtitle) in rows)
                  SwitchListTile(
                    key: ValueKey('buddy-chat-setting-$name'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    secondary: Icon(icon,
                        size: 20,
                        color: current.all[name]! ? AppColors.richGold : AppColors.textTertiary),
                    title: Text(label,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                    subtitle: Text(subtitle,
                        style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                    value: current.all[name]!,
                    activeThumbColor: AppColors.richGold,
                    onChanged: (v) {
                      setSheet(() => current = current.toggled(name, v));
                      onChanged(current);
                    },
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    key: const ValueKey('buddy-chat-settings-save-chat'),
                    onPressed: () => save(
                        () => current.saveForThisChat(buddyId), l10n.chatSettingsSavedThisChat),
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: Text(l10n.chatSettingsSaveThisChat),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.richGold,
                      side: const BorderSide(color: AppColors.richGold),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    key: const ValueKey('buddy-chat-settings-save-all'),
                    onPressed: () =>
                        save(current.saveForAllChats, l10n.chatSettingsSavedAllChats),
                    icon: const Icon(Icons.save, size: 18),
                    label: Text(l10n.chatSettingsSaveAllChats),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.richGold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
