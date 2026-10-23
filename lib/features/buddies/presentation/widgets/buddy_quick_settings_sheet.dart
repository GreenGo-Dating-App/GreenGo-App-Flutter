import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/buddy_catalog.dart';
import '../../domain/buddy_exception.dart';
import '../../domain/entities/buddy.dart';
import '../../domain/repositories/buddies_repository.dart';
import '../bloc/buddy_chat_bloc.dart';
import '../buddy_labels.dart';
import 'buddy_avatar.dart';
import 'buddy_prompts.dart';
import 'buddy_topic_picker.dart';

/// Quick settings of a Buddy: role, tone, topic, level, language (+ CEFR),
/// check-ins, what it remembers, clear chat, delete. Reads the live Buddy
/// from the surrounding [BuddyChatBloc]; every change is a callable.
class BuddyQuickSettingsSheet extends StatefulWidget {
  const BuddyQuickSettingsSheet({
    required this.buddyId,
    required this.repository,
    required this.prompts,
    required this.onDeleted,
    super.key,
  });

  final String buddyId;
  final BuddiesRepository repository;
  final BuddyPrompts prompts;
  final VoidCallback onDeleted;

  @override
  State<BuddyQuickSettingsSheet> createState() => _BuddyQuickSettingsSheetState();
}

class _BuddyQuickSettingsSheetState extends State<BuddyQuickSettingsSheet> {
  bool _busy = false;

  Future<bool> _run(Future<void> Function() action, {bool savedToast = true}) async {
    if (_busy) return false;
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await action();
      if (savedToast) messenger?.showSnackBar(SnackBar(content: Text(l10n.buddySaved)));
      return true;
    } catch (e) {
      if (mounted) await widget.prompts.showError(context, BuddyException.from(e));
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _update(Map<String, Object?> patch) =>
      _run(() => widget.repository.updateBuddy(widget.buddyId, patch));

  Future<String?> _pick(String title, List<(String, String)> options, String? current) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
        children: [
          for (final (value, label) in options)
            SimpleDialogOption(
              key: ValueKey('buddy-option-$value'),
              onPressed: () => Navigator.of(ctx).pop(value),
              child: Row(
                children: [
                  Expanded(
                    child: Text(label, style: const TextStyle(color: AppColors.textPrimary)),
                  ),
                  if (value == current) const Icon(Icons.check, color: AppColors.richGold, size: 18),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<bool> _confirm(String body, String action, {Widget? extra}) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(body, style: const TextStyle(color: AppColors.textSecondary)),
            if (extra != null) extra,
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.cancel)),
          TextButton(
            key: const ValueKey('buddy-confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(action, style: const TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _clearChat(Buddy b) async {
    final l10n = AppLocalizations.of(context)!;
    var forget = false;
    final ok = await _confirm(
      l10n.buddyClearChatConfirm(b.name),
      l10n.buddyClear,
      extra: StatefulBuilder(
        builder: (ctx, set) => CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: forget,
          onChanged: (v) => set(() => forget = v ?? false),
          title: Text(l10n.buddyClearChatAlsoForget(b.name),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        ),
      ),
    );
    if (!ok || !mounted) return;
    final bloc = context.read<BuddyChatBloc>();
    final done = await _run(() => widget.repository.clearChat(b.id, forgetMemory: forget),
        savedToast: false);
    if (done) bloc.add(const BuddyChatCleared());
  }

  Future<void> _delete(Buddy b) async {
    final l10n = AppLocalizations.of(context)!;
    if (!await _confirm(l10n.buddyDeleteConfirm(b.name), l10n.delete)) return;
    if (!mounted) return;
    final nav = Navigator.of(context);
    final done = await _run(() => widget.repository.deleteBuddy(b.id), savedToast: false);
    if (done) {
      nav.pop();
      widget.onDeleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<BuddyChatBloc, BuddyChatState>(
      buildWhen: (a, b) => a.buddy != b.buddy,
      builder: (context, state) {
        final b = state.buddy;
        if (b == null) {
          return const SizedBox(
              height: 160, child: Center(child: CircularProgressIndicator(color: AppColors.richGold)));
        }
        final s = b.settings;
        final languageTopic = BuddyCatalog.isLanguageTopic(s.topic);
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          builder: (context, controller) => AbsorbPointer(
            absorbing: _busy,
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.textTertiary, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    BuddyAvatar(avatarId: s.avatar, size: 48, showAiBadge: true),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(b.name,
                          style: const TextStyle(
                              color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    if (_busy)
                      const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.richGold)),
                  ],
                ),
                const SizedBox(height: 8),
                _row(
                  key: 'role',
                  label: l10n.buddySettingRole,
                  value: buddyRoleLabel(l10n, s.role),
                  onTap: () async {
                    final v = await _pick(l10n.buddySettingRole,
                        [for (final r in BuddyCatalog.roles) (r, buddyRoleLabel(l10n, r))], s.role);
                    if (v != null && v != s.role) await _update({'role': v});
                  },
                ),
                _row(
                  key: 'tone',
                  label: l10n.buddySettingTone,
                  value: buddyToneLabel(l10n, s.tone),
                  onTap: () async {
                    final v = await _pick(l10n.buddySettingTone,
                        [for (final t in BuddyCatalog.tones) (t, buddyToneLabel(l10n, t))], s.tone);
                    if (v != null && v != s.tone) await _update({'tone': v});
                  },
                ),
                _row(
                  key: 'topic',
                  label: l10n.buddySettingTopic,
                  value: buddyTopicLabel(l10n, s.topic),
                  onTap: () async {
                    final v = await Navigator.of(context).push<String>(MaterialPageRoute(
                        builder: (_) => BuddyTopicPickerScreen(selected: s.topic)));
                    if (v == null || v == s.topic) return;
                    await _update({
                      'topic': v,
                      if (!BuddyCatalog.isLanguageTopic(v) && s.cefr != null) 'cefr': null,
                    });
                  },
                ),
                _row(
                  key: 'level',
                  label: l10n.buddySettingLevel,
                  value: buddyLevelLabel(l10n, s.level),
                  onTap: () async {
                    final v = await _pick(l10n.buddySettingLevel,
                        [for (final x in BuddyCatalog.levels) (x, buddyLevelLabel(l10n, x))], s.level);
                    if (v != null && v != s.level) await _update({'level': v});
                  },
                ),
                _row(
                  key: 'language',
                  label: l10n.buddySettingLanguage,
                  value: buddyLanguageLabel(l10n, s.language),
                  onTap: () async {
                    final v = await _pick(
                        l10n.buddySettingLanguage,
                        [for (final x in BuddyCatalog.languages) (x, buddyLanguageLabel(l10n, x))],
                        s.language);
                    if (v != null && v != s.language) await _update({'language': v});
                  },
                ),
                if (languageTopic)
                  _row(
                    key: 'cefr',
                    label: l10n.buddySettingCefr,
                    value: s.cefr ?? l10n.buddyCefrNone,
                    onTap: () async {
                      final v = await _pick(l10n.buddySettingCefr,
                          [('', l10n.buddyCefrNone), for (final c in BuddyCatalog.cefrLevels) (c, c)],
                          s.cefr ?? '');
                      if (v == null || v == (s.cefr ?? '')) return;
                      await _update({'cefr': v.isEmpty ? null : v});
                    },
                  ),
                SwitchListTile(
                  key: const ValueKey('buddy-setting-checkins'),
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AppColors.richGold,
                  title: Text(l10n.buddySettingCheckIns,
                      style: const TextStyle(color: AppColors.textPrimary)),
                  subtitle: Text(l10n.buddySettingCheckInsSubtitle(b.name),
                      style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                  value: s.checkInsEnabled,
                  onChanged: (v) => _update({'checkInsEnabled': v}),
                ),
                const Divider(height: 28),
                Text(l10n.buddyMemoryTitle(b.name),
                    style: const TextStyle(
                        color: AppColors.richGold, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 6),
                if (b.memory.isEmpty)
                  Text(l10n.buddyMemoryEmpty(b.name),
                      key: const ValueKey('buddy-memory-empty'),
                      style: const TextStyle(color: AppColors.textTertiary, fontSize: 13))
                else ...[
                  for (final f in b.memory)
                    ListTile(
                      key: ValueKey('buddy-memory-${f.id}'),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: const Icon(Icons.bookmark_border, color: AppColors.textTertiary, size: 20),
                      title: Text(f.text, style: const TextStyle(color: AppColors.textSecondary)),
                      trailing: IconButton(
                        tooltip: l10n.buddyMemoryForget,
                        icon: const Icon(Icons.close, size: 18, color: AppColors.textTertiary),
                        onPressed: () =>
                            _run(() => widget.repository.forgetMemory(b.id, factId: f.id)),
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: const ValueKey('buddy-memory-forget-all'),
                      onPressed: () async {
                        if (await _confirm(
                            l10n.buddyMemoryForgetAllConfirm(b.name), l10n.buddyMemoryForgetAll)) {
                          await _run(() => widget.repository.forgetMemory(b.id));
                        }
                      },
                      icon: const Icon(Icons.delete_sweep_outlined),
                      label: Text(l10n.buddyMemoryForgetAll),
                    ),
                  ),
                ],
                const Divider(height: 28),
                ListTile(
                  key: const ValueKey('buddy-clear-chat'),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.cleaning_services_outlined, color: AppColors.textSecondary),
                  title: Text(l10n.buddyClearChat, style: const TextStyle(color: AppColors.textPrimary)),
                  onTap: () => _clearChat(b),
                ),
                ListTile(
                  key: const ValueKey('buddy-delete'),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.delete_outline, color: AppColors.errorRed),
                  title: Text(l10n.buddyDelete, style: const TextStyle(color: AppColors.errorRed)),
                  onTap: () => _delete(b),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _row({
    required String key,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) =>
      ListTile(
        key: ValueKey('buddy-setting-$key'),
        contentPadding: EdgeInsets.zero,
        title: Text(label, style: const TextStyle(color: AppColors.textTertiary, fontSize: 13)),
        subtitle: Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
        onTap: onTap,
      );
}
