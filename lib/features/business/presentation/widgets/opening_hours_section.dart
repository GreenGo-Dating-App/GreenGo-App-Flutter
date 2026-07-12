import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../profile/domain/entities/profile.dart';

/// Read-only opening-hours block for the public storefront.
///
/// Renders one row per weekday (Mon…Sun, localised weekday names via `intl`),
/// showing either the open/close window or a "Closed" chip. Days without an
/// explicit entry are treated as closed. Weekday names are derived from the
/// device locale so no extra l10n keys are required.
class OpeningHoursSection extends StatelessWidget {
  const OpeningHoursSection({
    required this.hours,
    required this.closedLabel,
    super.key,
  });

  /// Structured hours from `Profile.openingHours`.
  final List<OpeningHours> hours;

  /// Localised "Closed" label (passed in so this widget stays l10n-agnostic).
  final String closedLabel;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    // Map weekday (1..7) → entry for quick lookup.
    final byDay = <int, OpeningHours>{
      for (final h in hours) h.weekday: h,
    };

    return Column(
      children: List.generate(7, (i) {
        final weekday = i + 1; // 1 = Monday … 7 = Sunday
        // 2024-01-01 is a Monday, so DateTime(2024, 1, weekday) → the right day.
        final dayName = DateFormat.EEEE(locale).format(DateTime(2024, 1, weekday));
        final entry = byDay[weekday];
        final isClosed = entry == null ||
            entry.isClosed ||
            (entry.open == null || entry.close == null);
        final valueText = isClosed
            ? closedLabel
            : '${entry!.open} – ${entry.close}';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dayName,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isClosed
                      ? AppColors.backgroundCard
                      : AppColors.richGold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Text(
                  valueText,
                  style: TextStyle(
                    color:
                        isClosed ? AppColors.textTertiary : AppColors.richGold,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
