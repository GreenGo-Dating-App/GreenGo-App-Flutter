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
    this.description,
    this.requirements,
    this.note,
    this.error,
    this.summary,
    this.skip = false,
  });

  final String title;
  final IconData icon;
  final WidgetBuilder builder;

  /// Short "what to do here" text, shown in the step's header card and in the
  /// stepper (wide side list / phone "Steps" sheet).
  final String? description;

  /// Which fields are required on this step ("Required: title and …").
  final String? requirements;

  /// Extra hint shown under the step in the stepper and in its header card
  /// (e.g. "The Payment step appears when the price is above 0").
  final String? note;

  /// Why the step is not complete yet (null = valid). Shown inline above the
  /// Next button (Next is disabled while non-null) and, once the step was
  /// visited, as the "needs attention" reason in the stepper.
  final String? Function()? error;

  /// One line for the edit-mode overview ("Edit" per section).
  final String Function()? summary;

  /// Not shown at all (e.g. the payment step of a free listing).
  final bool skip;
}

/// Status of a step in the stepper.
enum WizardStepStatus { current, done, attention, todo }

/// Step-by-step create / edit flow for events and experiences.
///
///  * every step opens with a highlighted header card: "Step 2 of 5", the
///    title, what to do here and which fields are required;
///  * a stepper is always visible: wide screens (>= 900 px) get a vertical
///    list on the left (number, title, description, status); phones get a
///    compact horizontal stepper that follows the current step, plus a
///    "Steps" button opening a sheet with every step, status and description;
///  * step status: current (gold), done (green check), needs attention (amber
///    "!" + reason, once visited), not started (grey);
///  * free navigation: any step can be opened at any time from the stepper;
///    "Next: <step>" is the guided path and stays disabled (with the reason)
///    while the current step is invalid;
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

  /// Visited steps, by index in `widget.steps` (stable while Payment toggles).
  final Set<int> _visited = {};
  final ScrollController _strip = ScrollController();
  List<GlobalKey> _stripKeys = const [];
  int _scrolledTo = -1;

  List<int> get _visibleIdx => [
        for (var i = 0; i < widget.steps.length; i++)
          if (!widget.steps[i].skip) i
      ];
  List<WizardStep> get _visible => [for (final i in _visibleIdx) widget.steps[i]];

  @override
  void initState() {
    super.initState();
    _overview = widget.editMode;
    if (widget.editMode) {
      _visited.addAll([for (var i = 0; i < widget.steps.length; i++) i]);
    }
    widget.controller?._state = this;
  }

  @override
  void didUpdateWidget(covariant ListingWizard oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.controller?._state = this;
    final n = _visible.length;
    if (_index >= n) _index = n - 1;
  }

  @override
  void dispose() {
    _strip.dispose();
    super.dispose();
  }

  void _go(int i) {
    final idx = _visibleIdx;
    final n = idx.length;
    setState(() {
      if (!_overview && _index < n) _visited.add(idx[_index]);
      _overview = false;
      _index = i.clamp(0, n - 1);
    });
    widget.onStepChanged?.call(_index);
  }

  WizardStepStatus _status(int i) {
    if (i == _index) return WizardStepStatus.current;
    final idx = _visibleIdx;
    if (!_visited.contains(idx[i])) return WizardStepStatus.todo;
    return widget.steps[idx[i]].error?.call() == null ? WizardStepStatus.done : WizardStepStatus.attention;
  }

  static Color _statusColor(WizardStepStatus s) => switch (s) {
        WizardStepStatus.current => AppColors.richGold,
        WizardStepStatus.done => AppColors.successGreen,
        WizardStepStatus.attention => AppColors.warningAmber,
        WizardStepStatus.todo => AppColors.textTertiary,
      };

  static String _statusText(AppLocalizations l, WizardStepStatus s) => switch (s) {
        WizardStepStatus.current => l.wzStatusCurrent,
        WizardStepStatus.done => l.wzStatusDone,
        WizardStepStatus.attention => l.wzStatusAttention,
        WizardStepStatus.todo => l.wzStatusTodo,
      };

  String _semantics(AppLocalizations l, int i, int n, WizardStep step, WizardStepStatus s) {
    var status = _statusText(l, s);
    if (s == WizardStepStatus.attention) status = '$status: ${step.error?.call() ?? ''}';
    return l.wzStepSemantics(i + 1, n, step.title, status);
  }

  /// Numbered circle: number (current / not started), check (done), "!" (needs attention).
  Widget _circle(int i, WizardStepStatus s, {double size = 28}) {
    final Widget inner = switch (s) {
      WizardStepStatus.done => Icon(Icons.check, size: size * 0.6, color: AppColors.deepBlack),
      WizardStepStatus.attention => Icon(Icons.priority_high, size: size * 0.6, color: AppColors.deepBlack),
      _ => Text('${i + 1}',
          style: TextStyle(
            color: s == WizardStepStatus.current ? AppColors.deepBlack : AppColors.textTertiary,
            fontSize: size * 0.45,
            fontWeight: FontWeight.w700,
          )),
    };
    return Container(
      key: ValueKey('wizard-status-$i-${s.name}'),
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: s == WizardStepStatus.todo ? AppColors.backgroundInput : _statusColor(s),
        border: Border.all(
          color: s == WizardStepStatus.todo ? AppColors.divider : _statusColor(s),
          width: 1.5,
        ),
        boxShadow: s == WizardStepStatus.current
            ? [BoxShadow(color: AppColors.richGold.withValues(alpha: 0.45), blurRadius: 8)]
            : null,
      ),
      child: inner,
    );
  }

  /// One row of the vertical stepper (wide side list and phone "Steps" sheet).
  Widget _stepTile(AppLocalizations l, List<WizardStep> steps, int i,
      {required Key key, required VoidCallback onTap}) {
    final step = steps[i];
    final s = _status(i);
    final selected = s == WizardStepStatus.current;
    final reason = s == WizardStepStatus.attention ? step.error?.call() : null;
    return Semantics(
      key: key,
      button: true,
      selected: selected,
      label: _semantics(l, i, steps.length, step, s),
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: selected ? AppColors.richGold.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: selected ? AppColors.richGold.withValues(alpha: 0.7) : Colors.transparent),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _circle(i, s),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(step.title,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14.5,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      )),
                  if (step.description != null) ...[
                    const SizedBox(height: 2),
                    Text(step.description!,
                        maxLines: selected ? 3 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                  ],
                  const SizedBox(height: 4),
                  if (reason != null)
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.error_outline, size: 14, color: AppColors.warningAmber),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(reason,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.warningAmber, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ])
                  else
                    Text(_statusText(l, s),
                        style: TextStyle(color: _statusColor(s), fontSize: 11.5, fontWeight: FontWeight.w600)),
                  if (step.note != null) ...[
                    const SizedBox(height: 4),
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.info_outline, size: 14, color: AppColors.infoBlue),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(step.note!,
                            style: const TextStyle(color: AppColors.textTertiary, fontSize: 11.5, fontStyle: FontStyle.italic)),
                      ),
                    ]),
                  ],
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _openStepsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        final l = AppLocalizations.of(ctx)!;
        final steps = _visible;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.85),
            child: ListView(
              key: const ValueKey('wizard-steps-sheet'),
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(l.wzAllStepsTitle,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 2, 6, 8),
                  child: Text(l.wzStepsHint, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12.5)),
                ),
                for (var i = 0; i < steps.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: _stepTile(l, steps, i, key: ValueKey('wizard-sheet-$i'), onTap: () {
                      Navigator.pop(ctx);
                      _go(i);
                    }),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _scrollStripToCurrent() {
    if (_scrolledTo == _index) return;
    _scrolledTo = _index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _index >= _stripKeys.length) return;
      final ctx = _stripKeys[_index].currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(ctx, alignment: 0.5, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  /// Phone: compact horizontal stepper + "Steps" button + thin progress bar.
  Widget _phoneStepper(AppLocalizations l, List<WizardStep> steps) {
    if (_stripKeys.length != steps.length) {
      _stripKeys = [for (var i = 0; i < steps.length; i++) GlobalKey()];
      _scrolledTo = -1;
    }
    _scrollStripToCurrent();
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundCard,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _strip,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (var i = 0; i < steps.length; i++) ...[
                  if (i > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 13),
                      child: Container(
                        width: 14,
                        height: 2,
                        color: _status(i - 1) == WizardStepStatus.done ? AppColors.successGreen : AppColors.divider,
                      ),
                    ),
                  KeyedSubtree(key: _stripKeys[i], child: _stripItem(l, steps, i)),
                ],
              ]),
            ),
          ),
          TextButton.icon(
            key: const ValueKey('wizard-steps-button'),
            onPressed: _openStepsSheet,
            style: TextButton.styleFrom(foregroundColor: AppColors.richGold, padding: const EdgeInsets.symmetric(horizontal: 8)),
            icon: const Icon(Icons.format_list_numbered, size: 20),
            label: Text(l.wzSteps),
          ),
        ]),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: (_index + 1) / steps.length,
          minHeight: 3,
          color: AppColors.richGold,
          backgroundColor: AppColors.backgroundInput,
        ),
      ]),
    );
  }

  Widget _stripItem(AppLocalizations l, List<WizardStep> steps, int i) {
    final s = _status(i);
    final selected = s == WizardStepStatus.current;
    return Semantics(
      key: ValueKey('wizard-chip-$i'),
      button: true,
      selected: selected,
      label: _semantics(l, i, steps.length, steps[i], s),
      onTap: () => _go(i),
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _go(i),
        child: SizedBox(
          width: 76,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _circle(i, s),
              const SizedBox(height: 4),
              Text(steps[i].title,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? AppColors.richGold : (s == WizardStepStatus.todo ? AppColors.textTertiary : AppColors.textSecondary),
                    fontSize: 11,
                    height: 1.15,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  )),
            ]),
          ),
        ),
      ),
    );
  }

  /// Highlighted "Step 2 of 5 · title · what to do here · required" card.
  Widget _header(AppLocalizations l, List<WizardStep> steps, int i) {
    final step = steps[i];
    final isCurrent = i == _index;
    return Container(
      key: isCurrent ? const ValueKey('wizard-step-header') : null,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.richGold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.richGold.withValues(alpha: 0.55)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: AppColors.richGold.withValues(alpha: 0.18), shape: BoxShape.circle),
          child: Icon(step.icon, color: AppColors.richGold, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.wzStepOf(i + 1, steps.length),
                key: isCurrent ? const ValueKey('wizard-progress') : null,
                style: const TextStyle(color: AppColors.richGold, fontSize: 12.5, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
            const SizedBox(height: 2),
            Semantics(
              header: true,
              child: Text(step.title,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
            ),
            if (step.description != null) ...[
              const SizedBox(height: 6),
              Text(step.description!,
                  key: isCurrent ? const ValueKey('wizard-step-description') : null,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.35)),
            ],
            if (step.requirements != null) ...[
              const SizedBox(height: 8),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.task_alt, size: 16, color: AppColors.richGold),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(step.requirements!,
                      style: const TextStyle(color: AppColors.textTertiary, fontSize: 12.5, fontWeight: FontWeight.w600)),
                ),
              ]),
            ],
            if (step.note != null) ...[
              const SizedBox(height: 6),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.info_outline, size: 16, color: AppColors.infoBlue),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(step.note!, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12.5)),
                ),
              ]),
            ],
          ]),
        ),
      ]),
    );
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
                _header(l, steps, i),
                const SizedBox(height: 16),
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
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: const BoxDecoration(
          color: AppColors.backgroundCard,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (err != null && !last)
            Semantics(
              liveRegion: true,
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.warningAmber.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.warningAmber.withValues(alpha: 0.7)),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: AppColors.warningAmber, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(err,
                        key: const ValueKey('wizard-step-error'),
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
            ),
          Row(children: [
            if (_index > 0)
              OutlinedButton.icon(
                key: const ValueKey('wizard-back'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.divider),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onPressed: () => _go(_index - 1),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: Text(l.wzBack),
              ),
            const SizedBox(width: 10),
            if (!last)
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    key: const ValueKey('wizard-next'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.richGold,
                      foregroundColor: AppColors.deepBlack,
                      disabledBackgroundColor: AppColors.backgroundInput,
                      disabledForegroundColor: AppColors.textTertiary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: err == null ? () => _go(_index + 1) : null,
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: Text(l.wzNextTo(steps[_index + 1].title),
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
          ]),
        ]),
      ),
    );

    if (!wide) {
      return Column(children: [_phoneStepper(l, steps), Expanded(child: content), nav]);
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        width: 300,
        child: ListView(padding: const EdgeInsets.fromLTRB(12, 16, 12, 16), children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(l.wzAllStepsTitle,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 2, 6, 10),
            child: Text(l.wzStepsHint, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
          ),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _stepTile(l, steps, i, key: ValueKey('wizard-side-$i'), onTap: () => _go(i)),
            ),
        ]),
      ),
      const VerticalDivider(width: 1, color: AppColors.divider),
      Expanded(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: LinearProgressIndicator(
                  value: (_index + 1) / steps.length,
                  minHeight: 3,
                  color: AppColors.richGold,
                  backgroundColor: AppColors.backgroundInput,
                ),
              ),
              Expanded(child: content),
              nav,
            ]),
          ),
        ),
      ),
    ]);
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
                      ? (steps[i].description == null
                          ? null
                          : Text(steps[i].description!, maxLines: 2, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.textTertiary, fontSize: 12.5)))
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
