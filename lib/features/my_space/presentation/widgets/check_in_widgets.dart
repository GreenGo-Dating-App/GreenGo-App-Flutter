import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import 'space_widgets.dart';

/// Shared pieces of the two check-in checklists (event attendees and
/// experience session guests).

enum CheckInFilter { all, pending, checkedIn }

/// Big "12 / 20 checked in" summary with a progress bar and the Scan action.
class CheckInSummaryCard extends StatelessWidget {
  const CheckInSummaryCard({
    super.key,
    required this.checkedIn,
    required this.total,
    required this.onScan,
    this.subtitle,
  });

  final int checkedIn;
  final int total;
  final VoidCallback onScan;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final value = total <= 0 ? 0.0 : (checkedIn / total).clamp(0.0, 1.0);
    final done = total > 0 && checkedIn >= total;
    return SpaceCard(
      highlight: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(
              child: Semantics(
                label: l.msCheckedInProgress(checkedIn, total),
                excludeSemantics: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(
                          text: '$checkedIn',
                          style: TextStyle(
                            color: done
                                ? AppColors.successGreen
                                : AppColors.richGold,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextSpan(
                          text: ' / $total',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ]),
                    ),
                    Text(
                      l.eventCheckedIn,
                      style: const TextStyle(
                          color: AppColors.textTertiary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            FilledButton.icon(
              key: const ValueKey('checklist-scan'),
              onPressed: onScan,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.richGold,
                foregroundColor: AppColors.deepBlack,
                minimumSize: const Size(48, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.qr_code_scanner),
              label: Text(l.msScan,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ]),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.textTertiary, fontSize: 12.5)),
          ],
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: AppColors.textTertiary.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(
                  done ? AppColors.successGreen : AppColors.richGold),
            ),
          ),
        ],
      ),
    );
  }
}

/// Search field + All / Not here yet / Checked in chips.
class CheckInFilterBar extends StatelessWidget {
  const CheckInFilterBar({
    super.key,
    required this.controller,
    required this.filter,
    required this.onFilter,
    required this.onQuery,
  });

  final TextEditingController controller;
  final CheckInFilter filter;
  final ValueChanged<CheckInFilter> onFilter;
  final ValueChanged<String> onQuery;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    Widget chip(CheckInFilter f, String label) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            key: ValueKey('checklist-filter-${f.name}'),
            label: Text(label),
            selected: filter == f,
            onSelected: (_) => onFilter(f),
            showCheckmark: false,
            materialTapTargetSize: MaterialTapTargetSize.padded,
            backgroundColor: AppColors.backgroundCard,
            selectedColor: AppColors.richGold,
            side: BorderSide(color: AppColors.richGold.withValues(alpha: 0.35)),
            labelStyle: TextStyle(
              color:
                  filter == f ? AppColors.deepBlack : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const ValueKey('checklist-search'),
          controller: controller,
          onChanged: onQuery,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: l.msCheckInSearchHint,
            hintStyle:
                TextStyle(color: AppColors.textTertiary.withValues(alpha: 0.7)),
            prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary),
            filled: true,
            fillColor: AppColors.backgroundCard,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.richGold),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Wraps (never scrolls sideways): every filter stays visible at 320 px.
        Wrap(runSpacing: 4, children: [
          chip(CheckInFilter.all, l.msFilterAll),
          chip(CheckInFilter.pending, l.eventNotCheckedIn),
          chip(CheckInFilter.checkedIn, l.eventCheckedIn),
        ]),
      ],
    );
  }
}

/// One checklist row: who + a big check toggle (48 px target).
class CheckInRow extends StatelessWidget {
  const CheckInRow({
    super.key,
    required this.toggleKey,
    required this.name,
    required this.who,
    required this.checkedIn,
    required this.busy,
    required this.onToggle,
    this.detail,
  });

  final Key toggleKey;

  /// Plain name for the toggle's Semantics label.
  final String name;

  /// The visual "who" (avatar + name).
  final Widget who;
  final String? detail;
  final bool checkedIn;
  final bool busy;

  /// Null = not allowed (e.g. undo of a booking check-in).
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
      decoration: BoxDecoration(
        color: checkedIn
            ? Color.alphaBlend(AppColors.successGreen.withValues(alpha: 0.07),
                AppColors.backgroundCard)
            : AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: checkedIn
              ? AppColors.successGreen.withValues(alpha: 0.4)
              : AppColors.richGold.withValues(alpha: 0.14),
        ),
      ),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              who,
              if (detail != null) ...[
                const SizedBox(height: 2),
                Text(detail!,
                    style: const TextStyle(
                        color: AppColors.textTertiary, fontSize: 12)),
              ],
            ],
          ),
        ),
        Semantics(
          button: true,
          checked: checkedIn,
          enabled: onToggle != null && !busy,
          label:
              checkedIn ? '${l.eventCheckedIn}: $name' : l.msCheckInGuest(name),
          excludeSemantics: true,
          child: InkResponse(
            key: toggleKey,
            onTap: busy ? null : onToggle,
            radius: 28,
            child: SizedBox(
              width: 52,
              height: 52,
              child: Center(
                child: busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: AppColors.richGold))
                    : AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: checkedIn
                              ? AppColors.successGreen
                              : Colors.transparent,
                          border: Border.all(
                            color: checkedIn
                                ? AppColors.successGreen
                                : AppColors.textTertiary,
                            width: 2,
                          ),
                        ),
                        child: checkedIn
                            ? const Icon(Icons.check_rounded,
                                size: 20, color: AppColors.deepBlack)
                            : null,
                      ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

/// Confirm dialog used before a manual check-in / undo. True = go.
Future<bool> confirmCheckInChange(
  BuildContext context, {
  required String title,
  required String body,
  required String action,
  Color color = AppColors.richGold,
}) async {
  final l = AppLocalizations.of(context)!;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.backgroundCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
      content:
          Text(body, style: const TextStyle(color: AppColors.textSecondary)),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
        TextButton(
          key: const ValueKey('checklist-confirm'),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(action,
              style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
  return ok == true;
}
