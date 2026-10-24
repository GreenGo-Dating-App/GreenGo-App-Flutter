import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../generated/app_localizations.dart';
import '../../domain/buddy_catalog.dart';
import '../../domain/buddy_exception.dart';
import '../../domain/repositories/buddies_repository.dart';
import '../bloc/buddy_builder_cubit.dart';
import '../buddy_labels.dart';
import '../widgets/buddy_avatar.dart';
import '../widgets/buddy_prompts.dart';
import '../widgets/buddy_topic_picker.dart';

/// The 3-step Buddy builder: (1) category + language, (2) tone,
/// (3) name + picture -> Create. Pops the new Buddy id.
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
        final titles = [l10n.buddyTopicPrompt, l10n.buddyToneStepTitle, l10n.buddyNamePrompt];
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
            BuddyCategoryField(selected: s.topic, onSelected: cubit.selectTopic),
            const SizedBox(height: 24),
            _label(l10n.buddyLanguagePrompt),
            _chips(
              [for (final c in BuddyCatalog.languages) (c, buddyLanguageLabel(l10n, c))],
              s.language,
              cubit.selectLanguage,
              'buddy-lang',
            ),
            const SizedBox(height: 8),
            Text(l10n.buddyLanguageOnlyNote,
                style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
          ],
        );
      case 1:
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _chips(
              [for (final t in BuddyCatalog.tones) (t, buddyToneLabel(l10n, t))],
              s.tone,
              cubit.selectTone,
              'buddy-tone',
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

  Widget _chips(List<(String, String)> options, String? selected, ValueChanged<String> onPick,
          String keyPrefix) =>
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final (value, label) in options)
            ChoiceChip(
              key: ValueKey('$keyPrefix-$value'),
              label: Text(label),
              selected: selected == value,
              onSelected: (_) => onPick(value),
              selectedColor: AppColors.richGold,
              backgroundColor: AppColors.backgroundCard,
              labelStyle:
                  TextStyle(color: selected == value ? AppColors.deepBlack : AppColors.textPrimary),
            ),
        ],
      );
}
