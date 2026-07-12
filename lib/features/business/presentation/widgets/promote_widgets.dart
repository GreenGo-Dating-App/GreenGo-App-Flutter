import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_glass.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/services/promotion_service.dart';

/// A tappable glass card describing a promotion option (business / event).
class PromoteOptionCard extends StatelessWidget {
  const PromoteOptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    super.key,
    this.statusLabel,
    this.active = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  /// Optional active-status line (e.g. "Promoted until 12 Aug").
  final String? statusLabel;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      active: active,
      padding: const EdgeInsets.all(18),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.richGold.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.richGold),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                if (statusLabel != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star,
                          color: AppColors.richGold, size: 15),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          statusLabel!,
                          style: const TextStyle(
                            color: AppColors.richGold,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

/// Whether a duration sheet is picking cost for a business or an event, so the
/// correct per-option cost is shown.
enum PromoteTarget { business, event }

/// Presents a glass bottom sheet of [kPromoteDurationOptions] and returns the
/// picked option (null if dismissed). The gold CTA reflects the selected cost.
Future<PromoteDurationOption?> showPromoteDurationSheet(
  BuildContext context, {
  required PromoteTarget target,
  required String heading,
}) {
  return showModalBottomSheet<PromoteDurationOption>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _PromoteDurationSheet(target: target, heading: heading),
  );
}

class _PromoteDurationSheet extends StatefulWidget {
  const _PromoteDurationSheet({required this.target, required this.heading});

  final PromoteTarget target;
  final String heading;

  @override
  State<_PromoteDurationSheet> createState() => _PromoteDurationSheetState();
}

class _PromoteDurationSheetState extends State<_PromoteDurationSheet> {
  PromoteDurationOption _selected = kPromoteDurationOptions.first;

  int _costOf(PromoteDurationOption o) => widget.target == PromoteTarget.business
      ? o.businessCost
      : o.eventCost;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          top: 8,
        ),
        child: GlassContainer(
          borderRadius: AppGlass.radiusSheet,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.heading,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.promoteChooseDuration,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              ...kPromoteDurationOptions.map((o) {
                final isSel = o.days == _selected.days;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassContainer(
                    active: isSel,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selected = o);
                    },
                    child: Row(
                      children: [
                        Icon(
                          isSel
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: isSel
                              ? AppColors.richGold
                              : AppColors.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.promoteDurationDays(o.days),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          l10n.promoteCostLabel(_costOf(o)),
                          style: const TextStyle(
                            color: AppColors.richGold,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              _GoldCta(
                label:
                    '${l10n.promoteConfirmCta} · ${l10n.promoteCostLabel(_costOf(_selected))}',
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context, _selected);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Primary gold CTA button used across the promote flow.
class _GoldCta extends StatelessWidget {
  const _GoldCta({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppGlass.goldGlow,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.richGold,
          foregroundColor: AppColors.backgroundDark,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
