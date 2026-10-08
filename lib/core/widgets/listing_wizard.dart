import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../generated/app_localizations.dart';
import '../constants/app_colors.dart';

/// One step of a [ListingWizard].
class WizardStep {
  const WizardStep({
    required this.title,
    required this.icon,
    required this.builder,
    this.error,
    this.summary,
    this.skip = false,
  });

  final String title;
  final IconData icon;
  final WidgetBuilder builder;

  /// Why the step cannot be left yet (null = valid). Shown inline; Next is
  /// disabled while non-null.
  final String? Function()? error;

  /// One line for the edit-mode overview ("Edit" per section).
  final String Function()? summary;

  /// Not shown at all (e.g. the payment step of a free listing).
  final bool skip;
}

/// Step-by-step create / edit flow for events and experiences.
///
///  * progress "Step 2 of 5" + a labelled stepper; Back / Next, with Next
///    disabled until the step is valid (inline error);
///  * phones: one step per screen with a bottom Next bar; wide screens
///    (>= 900 px): vertical stepper on the left, content centred (max 720);
///  * every step stays MOUNTED (offstage) so the caller's Form validators and
///    controllers keep working exactly as before;
///  * edit mode opens an overview with "Edit" per section that jumps there.
class ListingWizard extends StatefulWidget {
  const ListingWizard({
    super.key,
    required this.steps,
    this.editMode = false,
    this.onStepChanged,
    this.controller,
  });

  final List<WizardStep> steps;
  final bool editMode;
  final ValueChanged<int>? onStepChanged;
  final ListingWizardController? controller;

  @override
  State<ListingWizard> createState() => ListingWizardState();
}

/// Lets the caller jump (e.g. "Fix" links on the review step).
class ListingWizardController {
  ListingWizardState? _state;
  void goTo(int visibleIndex) => _state?._go(visibleIndex);
  int get current => _state?._index ?? 0;
}

class ListingWizardState extends State<ListingWizard> {
  int _index = 0;
  bool _overview = false;

  List<WizardStep> get _visible => [for (final s in widget.steps) if (!s.skip) s];

  @override
  void initState() {
    super.initState();
    _overview = widget.editMode;
    widget.controller?._state = this;
  }

  @override
  void didUpdateWidget(covariant ListingWizard oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.controller?._state = this;
    final n = _visible.length;
    if (_index >= n) _index = n - 1;
  }

  void _go(int i) {
    final n = _visible.length;
    setState(() {
      _overview = false;
      _index = i.clamp(0, n - 1);
    });
    widget.onStepChanged?.call(_index);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final steps = _visible;
    final wide = MediaQuery.sizeOf(context).width >= 900;
    if (_overview) return _overviewView(l, steps);
    final step = steps[_index];
    final err = step.error?.call();
    final last = _index == steps.length - 1;

    final content = Stack(children: [
      for (var i = 0; i < steps.length; i++)
        Offstage(
          offstage: i != _index,
          child: TickerMode(
            enabled: i == _index,
            child: ListView(
              key: PageStorageKey('wizard-step-$i'),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(16),
              children: [
                Semantics(
                  header: true,
                  child: Text(steps[i].title,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 12),
                steps[i].builder(context),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
    ]);

    final nav = SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        decoration: const BoxDecoration(
          color: AppColors.backgroundCard,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (err != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(err,
                  key: const ValueKey('wizard-step-error'),
                  style: const TextStyle(color: AppColors.warningAmber, fontSize: 12.5)),
            ),
          Row(children: [
            if (_index > 0)
              TextButton.icon(
                key: const ValueKey('wizard-back'),
                onPressed: () => _go(_index - 1),
                icon: const Icon(Icons.arrow_back),
                label: Text(l.wzBack),
              ),
            const Spacer(),
            if (!last)
              ElevatedButton.icon(
                key: const ValueKey('wizard-next'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.richGold, foregroundColor: AppColors.deepBlack),
                onPressed: err == null ? () => _go(_index + 1) : null,
                icon: const Icon(Icons.arrow_forward),
                label: Text(l.wzNext),
              ),
          ]),
        ]),
      ),
    );

    final progress = Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(l.wzStepOf(_index + 1, steps.length),
            key: const ValueKey('wizard-progress'),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: (_index + 1) / steps.length,
          color: AppColors.richGold,
          backgroundColor: AppColors.backgroundInput,
        ),
        if (!wide) ...[
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (var i = 0; i < steps.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    key: ValueKey('wizard-chip-$i'),
                    label: Text('${i + 1}. ${steps[i].title}'),
                    selected: i == _index,
                    onSelected: i < _index || _canReach(i) ? (_) => _go(i) : null,
                  ),
                ),
            ]),
          ),
        ],
      ]),
    );

    if (!wide) {
      return Column(children: [progress, Expanded(child: content), nav]);
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        width: 260,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          for (var i = 0; i < steps.length; i++)
            ListTile(
              key: ValueKey('wizard-side-$i'),
              selected: i == _index,
              selectedTileColor: AppColors.richGold.withValues(alpha: 0.12),
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: i <= _index ? AppColors.richGold : AppColors.backgroundInput,
                child: Text('${i + 1}', style: TextStyle(color: i <= _index ? AppColors.deepBlack : AppColors.textSecondary, fontSize: 12)),
              ),
              title: Text(steps[i].title, style: const TextStyle(color: AppColors.textPrimary)),
              onTap: i < _index || _canReach(i) ? () => _go(i) : null,
            ),
        ]),
      ),
      const VerticalDivider(width: 1, color: AppColors.divider),
      Expanded(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(children: [progress, Expanded(child: content), nav]),
          ),
        ),
      ),
    ]);
  }

  /// Forward jumps only across valid steps.
  bool _canReach(int target) {
    final steps = _visible;
    for (var i = 0; i < target; i++) {
      if (steps[i].error?.call() != null) return false;
    }
    return true;
  }

  Widget _overviewView(AppLocalizations l, List<WizardStep> steps) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Text(l.wzOverviewTitle, style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            for (var i = 0; i < steps.length; i++)
              Card(
                color: AppColors.backgroundCard,
                child: ListTile(
                  key: ValueKey('wizard-overview-$i'),
                  leading: Icon(steps[i].icon, color: AppColors.richGold),
                  title: Text(steps[i].title, style: const TextStyle(color: AppColors.textPrimary)),
                  subtitle: steps[i].summary == null
                      ? null
                      : Text(steps[i].summary!(), maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                  trailing: TextButton(
                    key: ValueKey('wizard-edit-$i'),
                    onPressed: () => _go(i),
                    child: Text(l.wzEdit),
                  ),
                ),
              ),
          ]),
        ),
      );
}

/// Local autosave of a wizard draft (one per user + kind), so a create flow
/// can be resumed after the app was closed. Never contains secrets.
class WizardDraftStore {
  const WizardDraftStore(this.key);
  final String key;

  Future<Map<String, dynamic>?> read() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(key);
      if (raw == null) return null;
      final m = jsonDecode(raw);
      return m is Map<String, dynamic> && m.isNotEmpty ? m : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> write(Map<String, dynamic> draft) async {
    try {
      await (await SharedPreferences.getInstance()).setString(key, jsonEncode(draft));
    } catch (_) {}
  }

  Future<void> clear() async {
    try {
      await (await SharedPreferences.getInstance()).remove(key);
    } catch (_) {}
  }

  /// "Resume your draft?" — true = restore, false = start over (draft cleared).
  static Future<bool> askResume(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final r = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(l.wzResumeTitle, style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(l.wzResumeBody, style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(key: const ValueKey('wizard-start-over'), onPressed: () => Navigator.pop(ctx, false), child: Text(l.wzStartOver)),
          TextButton(key: const ValueKey('wizard-resume'), onPressed: () => Navigator.pop(ctx, true), child: Text(l.wzResume)),
        ],
      ),
    );
    return r == true;
  }
}

/// Review step helper: "missing / warnings" checklist with "Fix" links.
class WizardChecklist extends StatelessWidget {
  const WizardChecklist({super.key, required this.items});

  /// (text, isBlocking, stepIndexToFix or null).
  final List<(String, bool, VoidCallback?)> items;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (items.isEmpty) {
      return Row(children: [
        const Icon(Icons.check_circle, color: AppColors.successGreen),
        const SizedBox(width: 8),
        Expanded(child: Text(l.wzAllGood, style: const TextStyle(color: AppColors.textSecondary))),
      ]);
    }
    return Column(children: [
      for (final (text, blocking, fix) in items)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(blocking ? Icons.error_outline : Icons.warning_amber,
              color: blocking ? AppColors.errorRed : AppColors.warningAmber),
          title: Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          trailing: fix == null ? null : TextButton(onPressed: fix, child: Text(l.wzFix)),
        ),
    ]);
  }
}
