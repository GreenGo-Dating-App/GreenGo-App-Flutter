import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/utils/language_flags.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/buddy_catalog.dart';
import '../../domain/buddy_exception.dart';
import '../../domain/repositories/buddies_repository.dart';
import '../bloc/buddy_builder_cubit.dart';
import '../buddy_labels.dart';
import '../widgets/buddy_avatar.dart';
import '../widgets/buddy_prompts.dart';

/// The 2-step Buddy builder (owner 2026-10-24): (1) four selects: main
/// category, topic of that category, language, chat translation language,
/// tone; (2) name + picture ->
/// Create. Pops the new Buddy id.
class BuddyBuilderScreen extends StatelessWidget {
  const BuddyBuilderScreen({
    required this.userId,
    this.repository,
    this.prompts = const BuddyPrompts(),
    this.buddyLimit,
    this.tier,
    super.key,
  });

  final String userId;
  final BuddiesRepository? repository;
  final BuddyPrompts prompts;

  /// For the upgrade prompt when the server says the plan limit is reached.
  final int? buddyLimit;
  final String? tier;

  @override
  Widget build(BuildContext context) {
    final repo = repository ?? di.sl<BuddiesRepository>();
    final locale = Localizations.localeOf(context);
    return BuddyAvatarScope(
      repository: repo,
      child: BlocProvider(
        create: (_) => BuddyBuilderCubit(
          repository: repo,
          language: BuddyCatalog.languageForLocale(locale.languageCode, locale.countryCode),
        ),
        child:
            _BuddyBuilderView(userId: userId, prompts: prompts, buddyLimit: buddyLimit, tier: tier),
      ),
    );
  }
}

class _BuddyBuilderView extends StatefulWidget {
  const _BuddyBuilderView({
    required this.userId,
    required this.prompts,
    this.buddyLimit,
    this.tier,
  });

  final String userId;
  final BuddyPrompts prompts;
  final int? buddyLimit;
  final String? tier;

  @override
  State<_BuddyBuilderView> createState() => _BuddyBuilderViewState();
}

class _BuddyBuilderViewState extends State<_BuddyBuilderView> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// Runs again whenever the [BuddyAvatarScope] finishes loading (this
  /// state depends on it through [BuddyAvatarScope.maybeOf]).
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncDefaultAvatar();
  }

  /// First picture preselected; the legacy drawn avatar when none loads
  /// (the server still accepts it), so creating is never blocked.
  void _syncDefaultAvatar() {
    final catalog = BuddyAvatarScope.maybeOf(context);
    if (catalog == null || catalog.loading) return;
    final cubit = context.read<BuddyBuilderCubit>();
    final current = cubit.state.avatar;
    if (catalog.options.isNotEmpty) {
      if (current == null || BuddyCatalog.isLegacyAvatar(current)) {
        cubit.selectAvatar(catalog.options.first.id);
      }
    } else {
      cubit.defaultAvatar(BuddyCatalog.avatars.first);
    }
  }

  Future<void> _next(BuddyBuilderState s) async {
    final cubit = context.read<BuddyBuilderCubit>();
    FocusScope.of(context).unfocus();
    if (!s.isLastStep) {
      cubit.next();
      return;
    }
    try {
      final id = await cubit.create();
      if (id != null && mounted) Navigator.of(context).pop(id);
    } on BuddyException catch (err) {
      if (!mounted) return;
      if (err.kind == BuddyErrorKind.tierRequired) {
        await widget.prompts.showUpgrade(context,
            uid: widget.userId, limit: err.limit ?? widget.buddyLimit ?? 1, tier: widget.tier);
      } else {
        await widget.prompts.showError(context, err);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<BuddyBuilderCubit, BuddyBuilderState>(
      builder: (context, s) {
        final titles = [l10n.buddyTopicPrompt, l10n.buddyNamePrompt];
        return PopScope(
          canPop: s.step == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) context.read<BuddyBuilderCubit>().back();
          },
          child: Scaffold(
            backgroundColor: AppColors.backgroundDark,
            appBar: AppBar(
              backgroundColor: AppColors.backgroundDark,
              foregroundColor: AppColors.textPrimary,
              title: Text(l10n.buddyBuilderTitle),
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.buddyStepOf(s.step + 1, BuddyBuilderState.steps),
                          style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: (s.step + 1) / BuddyBuilderState.steps,
                        color: AppColors.richGold,
                        backgroundColor: AppColors.backgroundCard,
                      ),
                      const SizedBox(height: 12),
                      Text(titles[s.step],
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Expanded(child: _body(context, l10n, s)),
                _footer(context, l10n, s),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Back + Next/Create. Both buttons are Expanded: the app theme gives
  /// ElevatedButton an infinite minimum width, which inside a Row next to
  /// a Spacer could not be laid out, so Next never appeared (the
  /// "stuck at step 2" bug).
  Widget _footer(BuildContext context, AppLocalizations l10n, BuddyBuilderState s) {
    const shape = Size(0, 48);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            if (s.step > 0) ...[
              Expanded(
                child: TextButton(
                  key: const ValueKey('buddy-builder-back'),
                  style: TextButton.styleFrom(minimumSize: shape),
                  onPressed: s.saving ? null : () => context.read<BuddyBuilderCubit>().back(),
                  child: Text(l10n.buddyBack),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: 2,
              child: ElevatedButton(
                key: const ValueKey('buddy-builder-next'),
                style: ElevatedButton.styleFrom(
                  minimumSize: shape,
                  backgroundColor: AppColors.richGold,
                  foregroundColor: AppColors.deepBlack,
                ),
                onPressed: s.canNext ? () => _next(s) : null,
                child: s.saving
                    ? const SizedBox.square(
                        dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(s.isLastStep ? l10n.buddyCreate : l10n.buddyNext,
                        overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, AppLocalizations l10n, BuddyBuilderState s) {
    final cubit = context.read<BuddyBuilderCubit>();
    switch (s.step) {
      case 0:
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _select(
              key: const ValueKey('buddy-macro'),
              label: l10n.buddyMacroCategoryLabel,
              // Nothing preselected: a placeholder until a category is chosen.
              hint: l10n.buddyChooseCategory,
              value: s.group,
              options: [for (final g in kBuddyTopicGroups) (g, buddyTopicGroupLabel(l10n, g))],
              onChanged: cubit.selectGroup,
            ),
            const SizedBox(height: 16),
            _select(
              // Rebuilt per category: its list (and choice) belong to it.
              key: const ValueKey('buddy-micro'),
              label: l10n.buddyMicroCategoryLabel,
              // Disabled (with the same placeholder) until a category is chosen.
              hint: l10n.buddyChooseSubcategory,
              value: s.topic,
              options: [for (final t in s.groupTopics) (t.id, buddyTopicLabel(l10n, t.id))],
              onChanged: s.group == null ? null : cubit.selectTopic,
            ),
            const SizedBox(height: 16),
            _select(
              key: const ValueKey('buddy-language'),
              label: l10n.buddyLanguagePrompt,
              value: s.language,
              // Same flags as "Translate this chat into".
              options: [
                for (final c in BuddyCatalog.languages)
                  (c, '${languageFlagEmoji(c)} ${buddyLanguageLabel(l10n, c)}'),
              ],
              onChanged: cubit.selectLanguage,
            ),
            const SizedBox(height: 6),
            Text(l10n.buddyLanguageOnlyNote,
                style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
            const SizedBox(height: 16),
            // Owner 2026-10-25: the three languages, in reading order: the
            // Buddy writes in, you write in, both translated into.
            _select(
              key: const ValueKey('buddy-user-language'),
              label: l10n.buddyUserLanguagePrompt,
              value: s.userLanguage,
              options: [
                for (final c in BuddyCatalog.languages)
                  (c, '${languageFlagEmoji(c)} ${buddyLanguageLabel(l10n, c)}'),
              ],
              onChanged: cubit.selectUserLanguage,
            ),
            const SizedBox(height: 6),
            Text(l10n.buddyUserLanguageNote,
                style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
            const SizedBox(height: 16),
            // What the server translates the chat into, once per message.
            _select(
              key: const ValueKey('buddy-chat-language'),
              label: l10n.buddyChatLanguagePrompt,
              value: s.chatLanguage,
              options: [
                for (final c in BuddyCatalog.languages)
                  (c, '${languageFlagEmoji(c)} ${buddyLanguageLabel(l10n, c)}'),
              ],
              onChanged: cubit.selectChatLanguage,
            ),
            const SizedBox(height: 6),
            Text(l10n.buddyChatLanguageNote,
                style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
            const SizedBox(height: 16),
            _select(
              key: const ValueKey('buddy-tone'),
              label: l10n.buddyToneStepTitle,
              value: s.tone,
              options: [for (final t in BuddyCatalog.tones) (t, buddyToneLabel(l10n, t))],
              onChanged: cubit.selectTone,
            ),
          ],
        );
      default:
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (s.avatar != null)
              Center(child: BuddyAvatar(avatarId: s.avatar!, size: 88, showAiBadge: true)),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('buddy-name-field'),
              controller: _name,
              maxLength: BuddyCatalog.maxNameChars,
              textInputAction: TextInputAction.done,
              style: const TextStyle(color: AppColors.textPrimary),
              onChanged: cubit.setName,
              decoration: InputDecoration(
                labelText: l10n.buddySettingName,
                hintText: l10n.buddyNameHint,
                errorText: s.showNameError ? l10n.buddyNameInvalid : null,
                errorMaxLines: 3,
                labelStyle: const TextStyle(color: AppColors.textTertiary),
                hintStyle: const TextStyle(color: AppColors.textTertiary),
                filled: true,
                fillColor: AppColors.backgroundCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),
            _label(l10n.buddyAvatarPrompt),
            BuddyAvatarGrid(selected: s.avatar, onSelected: cubit.selectAvatar),
          ],
        );
    }
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 14)),
      );

  /// One select box: a labelled dropdown. Its items are keyed
  /// `<key>-<value>`; [onChanged] null = disabled (shows [hint]).
  Widget _select({
    required ValueKey<String> key,
    required String label,
    required String? value,
    required List<(String, String)> options,
    required ValueChanged<String>? onChanged,
    String? hint,
  }) {
    final known = value != null && options.any((o) => o.$1 == value);
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textTertiary),
        filled: true,
        fillColor: AppColors.backgroundCard,
        contentPadding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          key: key,
          value: known ? value : null,
          isExpanded: true,
          dropdownColor: AppColors.backgroundCard,
          menuMaxHeight: 360,
          borderRadius: BorderRadius.circular(14),
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
          hint: Text(hint ?? '', style: const TextStyle(color: AppColors.textTertiary)),
          disabledHint:
              Text(hint ?? '', style: const TextStyle(color: AppColors.textTertiary)),
          items: [
            for (final (v, text) in options)
              DropdownMenuItem<String>(
                key: ValueKey('${key.value}-$v'),
                value: v,
                child: Text(text, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: onChanged == null
              ? null
              : (v) {
                  if (v != null) onChanged(v);
                },
        ),
      ),
    );
  }
}
