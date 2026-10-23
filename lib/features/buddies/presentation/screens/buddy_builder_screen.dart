import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../generated/app_localizations.dart';
import '../../domain/buddy_catalog.dart';
import '../../domain/buddy_exception.dart';
import '../../domain/entities/buddy.dart';
import '../../domain/repositories/buddies_repository.dart';
import '../buddy_labels.dart';
import '../widgets/buddy_avatar.dart';
import '../widgets/buddy_prompts.dart';
import '../widgets/buddy_topic_picker.dart';

/// Localized label of a ready-made suggestion.
String buddySuggestionLabel(AppLocalizations l10n, String id) {
  switch (id) {
    case 'italian_teacher':
      return l10n.buddySuggestItalianTeacher;
    case 'english_partner':
      return l10n.buddySuggestEnglishPartner;
    case 'running_coach':
      return l10n.buddySuggestRunningCoach;
    case 'movie_buddy':
      return l10n.buddySuggestMovieBuddy;
    case 'travel_planner':
      return l10n.buddySuggestTravelPlanner;
    case 'cooking_friend':
      return l10n.buddySuggestCookingFriend;
    case 'interview_coach':
      return l10n.buddySuggestInterviewCoach;
    case 'debate_partner':
      return l10n.buddySuggestDebatePartner;
    default:
      return id;
  }
}

/// The 4-step Buddy builder: topic -> role -> language + level (+ CEFR for
/// language practice) -> name, look, tone. Pops the new Buddy id.
class BuddyBuilderScreen extends StatefulWidget {
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
  State<BuddyBuilderScreen> createState() => _BuddyBuilderScreenState();
}

class _BuddyBuilderScreenState extends State<BuddyBuilderScreen> {
  static const int _steps = 4;
  int _step = 0;
  String? _topic;
  String _role = 'friend';
  String? _language;
  String _level = 'beginner';
  String? _cefr;
  String _avatar = BuddyCatalog.avatars.first;
  String _tone = 'warm';
  final _name = TextEditingController();
  bool _saving = false;
  bool _nameTouched = false;

  BuddiesRepository get _repo => widget.repository ?? di.sl<BuddiesRepository>();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String _defaultLanguage(BuildContext context) {
    final l = Localizations.localeOf(context);
    return BuddyCatalog.languageForLocale(l.languageCode, l.countryCode);
  }

  void _pickTopic(String id) {
    setState(() {
      _topic = id;
      final practice = BuddyCatalog.practiceLanguage(id);
      if (practice != null) _language = practice;
      if (!BuddyCatalog.isLanguageTopic(id)) _cefr = null;
      _step = 1;
    });
  }

  void _applySuggestion(BuddySuggestion s) {
    setState(() {
      _topic = s.topic;
      _role = s.role;
      _tone = s.tone;
      _avatar = s.avatar;
      _level = s.level;
      _language = s.language ?? _language;
      _cefr = null;
      _step = 1;
    });
  }

  bool get _canNext {
    switch (_step) {
      case 0:
        return _topic != null;
      case 3:
        return BuddyCatalog.cleanName(_name.text) != null;
      default:
        return true;
    }
  }

  Future<void> _create() async {
    final name = BuddyCatalog.cleanName(_name.text);
    if (name == null || _topic == null || _saving) {
      setState(() => _nameTouched = true);
      return;
    }
    setState(() => _saving = true);
    final settings = BuddySettings(
      name: name,
      avatar: _avatar,
      topic: _topic!,
      role: _role,
      tone: _tone,
      language: _language ?? _defaultLanguage(context),
      level: _level,
      cefr: BuddyCatalog.isLanguageTopic(_topic!) ? _cefr : null,
    );
    try {
      final id = await _repo.createBuddy(settings);
      if (mounted) Navigator.of(context).pop(id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      final err = BuddyException.from(e);
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
    _language ??= _defaultLanguage(context);
    final titles = [
      l10n.buddyTopicPrompt,
      l10n.buddyRolePrompt,
      l10n.buddyLanguagePrompt,
      l10n.buddyNamePrompt,
    ];
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _step--);
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
                  Text(l10n.buddyStepOf(_step + 1, _steps),
                      style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: (_step + 1) / _steps,
                    color: AppColors.richGold,
                    backgroundColor: AppColors.backgroundCard,
                  ),
                  const SizedBox(height: 12),
                  Text(titles[_step],
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(child: _body(l10n)),
            if (_step > 0) _footer(l10n),
          ],
        ),
      ),
    );
  }

  Widget _footer(AppLocalizations l10n) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              TextButton(
                onPressed: _saving ? null : () => setState(() => _step--),
                child: Text(l10n.buddyBack),
              ),
              const Spacer(),
              ElevatedButton(
                key: const ValueKey('buddy-builder-next'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.richGold,
                  foregroundColor: AppColors.deepBlack,
                ),
                onPressed: !_canNext || _saving
                    ? null
                    : () {
                        if (_step < _steps - 1) {
                          setState(() => _step++);
                        } else {
                          _create();
                        }
                      },
                child: _saving
                    ? const SizedBox.square(
                        dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_step < _steps - 1 ? l10n.buddyNext : l10n.buddyCreate),
              ),
            ],
          ),
        ),
      );

  Widget _body(AppLocalizations l10n) {
    switch (_step) {
      case 0:
        return BuddyTopicPicker(
          selected: _topic,
          onSelected: _pickTopic,
          header: _suggestions(l10n),
        );
      case 1:
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final r in BuddyCatalog.roles)
              _OptionTile(
                key: ValueKey('buddy-role-$r'),
                title: buddyRoleLabel(l10n, r),
                subtitle: buddyRoleDescription(l10n, r),
                selected: _role == r,
                onTap: () => setState(() => _role = r),
              ),
          ],
        );
      case 2:
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _chips(
              [for (final c in BuddyCatalog.languages) (c, buddyLanguageLabel(l10n, c))],
              _language,
              (v) => setState(() => _language = v),
              'buddy-lang',
            ),
            const SizedBox(height: 20),
            _label(l10n.buddyLevelPrompt),
            _chips(
              [for (final c in BuddyCatalog.levels) (c, buddyLevelLabel(l10n, c))],
              _level,
              (v) => setState(() => _level = v),
              'buddy-level',
            ),
            if (_topic != null && BuddyCatalog.isLanguageTopic(_topic!)) ...[
              const SizedBox(height: 20),
              _label(l10n.buddyCefrPrompt),
              _chips(
                [('', l10n.buddyCefrNone), for (final c in BuddyCatalog.cefrLevels) (c, c)],
                _cefr ?? '',
                (v) => setState(() => _cefr = v.isEmpty ? null : v),
                'buddy-cefr',
              ),
            ],
          ],
        );
      default:
        final nameError = _nameTouched && BuddyCatalog.cleanName(_name.text) == null
            ? l10n.buddyNameInvalid
            : null;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(child: BuddyAvatar(avatarId: _avatar, size: 96, showAiBadge: true)),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('buddy-name-field'),
              controller: _name,
              maxLength: BuddyCatalog.maxNameChars,
              style: const TextStyle(color: AppColors.textPrimary),
              onChanged: (_) => setState(() => _nameTouched = true),
              decoration: InputDecoration(
                labelText: l10n.buddyNamePrompt,
                hintText: l10n.buddyNameHint,
                errorText: nameError,
                labelStyle: const TextStyle(color: AppColors.textTertiary),
                hintStyle: const TextStyle(color: AppColors.textTertiary),
                filled: true,
                fillColor: AppColors.backgroundCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),
            _label(l10n.buddyAvatarPrompt),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final a in BuddyCatalog.avatars)
                  GestureDetector(
                    key: ValueKey('buddy-avatar-$a'),
                    onTap: () => setState(() => _avatar = a),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _avatar == a ? AppColors.richGold : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: BuddyAvatar(avatarId: a, size: 46),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            _label(l10n.buddyTonePrompt),
            _chips(
              [for (final t in BuddyCatalog.tones) (t, buddyToneLabel(l10n, t))],
              _tone,
              (v) => setState(() => _tone = v),
              'buddy-tone',
            ),
          ],
        );
    }
  }

  Widget _suggestions(AppLocalizations l10n) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label(l10n.buddySuggestionsTitle),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: BuddySuggestion.all.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final s = BuddySuggestion.all[i];
                  return InkWell(
                    key: ValueKey('buddy-suggestion-${s.id}'),
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _applySuggestion(s),
                    child: Container(
                      width: 128,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundCard,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          BuddyAvatar(avatarId: s.avatar, size: 36),
                          const SizedBox(height: 6),
                          Expanded(
                            child: Text(
                              buddySuggestionLabel(l10n, s.id),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: AppColors.textPrimary, fontSize: 12, height: 1.2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );

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
              labelStyle: TextStyle(
                  color: selected == value ? AppColors.deepBlack : AppColors.textPrimary),
            ),
        ],
      );
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: selected ? AppColors.richGold.withValues(alpha: 0.15) : AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(14),
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: selected ? AppColors.richGold : Colors.transparent),
            ),
            onTap: onTap,
            title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
            subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textTertiary)),
            trailing: selected ? const Icon(Icons.check_circle, color: AppColors.richGold) : null,
          ),
        ),
      );
}
