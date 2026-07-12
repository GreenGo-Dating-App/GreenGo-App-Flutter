/// Privacy-safe audience charts (fl_chart) for the business analytics surface.
///
/// Every widget here consumes ALREADY-AGGREGATED, k-anonymized maps
/// (`label -> count`) produced by `AnalyticsService`. They render counts and
/// percentages only — never an individual user. Theming is gold-on-dark glass
/// to match the rest of the app. All charts honor reduced-motion by disabling
/// animation when `animate == false`.
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/services/analytics_service.dart';

/// Gold-forward categorical palette used across every audience chart so the
/// visualizations read as one system in both the aggregate and per-event views.
const List<Color> kAudienceChartPalette = <Color>[
  Color(0xFFD4AF37), // richGold
  Color(0xFFFFD700), // accentGold
  Color(0xFFF0C75E),
  Color(0xFFE8B923),
  Color(0xFFBF9B30),
  Color(0xFFF5E1A4),
  Color(0xFFC9A227),
  Color(0xFFEACD76),
];

Color _paletteAt(int i) => kAudienceChartPalette[i % kAudienceChartPalette.length];

/// Glass card wrapper giving every chart a title + consistent padding.
class AudienceChartCard extends StatelessWidget {
  const AudienceChartCard({
    required this.title,
    required this.icon,
    required this.child,
    super.key,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.richGold, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

/// Glass "not enough data yet" state, shown when k-anonymity leaves nothing to
/// safely display.
class ChartInsufficientData extends StatelessWidget {
  const ChartInsufficientData({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.richGold.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_outline,
                color: AppColors.richGold, size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Vertical BAR chart of age-range buckets (18-24 … 55+).
class AgeBarChart extends StatelessWidget {
  const AgeBarChart({required this.data, this.animate = true, super.key});

  /// age-range label -> count (already k-anonymized).
  final Map<String, int> data;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final labels = data.keys.toList();
    final values = data.values.toList();
    final maxV = values.fold<int>(0, (m, v) => v > m ? v : m).toDouble();
    final maxY = (maxV <= 0 ? 1.0 : maxV) * 1.25;

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.charcoal,
              getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                '${labels[group.x]}\n',
                const TextStyle(
                  color: AppColors.richGold,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                children: [
                  TextSpan(
                    text: '${rod.toY.round()}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: (maxY / 4).ceilToDouble().clamp(1, double.infinity),
                getTitlesWidget: (value, _) => Text(
                  value.round().toString(),
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, _) {
                  final i = value.toInt();
                  if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      labels[i],
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < values.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: values[i].toDouble(),
                    width: 22,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        _paletteAt(i).withOpacity(0.55),
                        _paletteAt(i),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
        duration: animate
            ? const Duration(milliseconds: 550)
            : Duration.zero,
      ),
    );
  }
}

/// Donut (pie) chart of top countries with a percentage legend.
class CountryDonutChart extends StatelessWidget {
  const CountryDonutChart({required this.data, this.animate = true, super.key});

  /// country -> count (already k-anonymized, top slice).
  final Map<String, int> data;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();
    final total = entries.fold<int>(0, (s, e) => s + e.value);
    if (total == 0) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 44,
              sections: [
                for (var i = 0; i < entries.length; i++)
                  PieChartSectionData(
                    value: entries[i].value.toDouble(),
                    color: _paletteAt(i),
                    radius: 38,
                    title:
                        '${((entries[i].value / total) * 100).round()}%',
                    titleStyle: const TextStyle(
                      color: AppColors.deepBlack,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
            duration: animate
                ? const Duration(milliseconds: 550)
                : Duration.zero,
          ),
        ),
        const SizedBox(height: 16),
        // Legend
        Wrap(
          spacing: 14,
          runSpacing: 8,
          children: [
            for (var i = 0; i < entries.length; i++)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _paletteAt(i),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${entries[i].key} (${entries[i].value})',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

/// Horizontal bar chart of top interests — proportional gold bars with counts.
class InterestBarChart extends StatelessWidget {
  const InterestBarChart({required this.data, this.animate = true, super.key});

  /// interest -> count (already k-anonymized, top slice).
  final Map<String, int> data;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();
    final maxV =
        entries.fold<int>(0, (m, e) => e.value > m ? e.value : m).toDouble();
    if (maxV <= 0) return const SizedBox.shrink();

    return Column(
      children: [
        for (var i = 0; i < entries.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == entries.length - 1 ? 0 : 14),
            child: Row(
              children: [
                SizedBox(
                  width: 96,
                  child: Text(
                    entries[i].key,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final fraction = entries[i].value / maxV;
                      return Stack(
                        children: [
                          Container(
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          AnimatedContainer(
                            duration: animate
                                ? const Duration(milliseconds: 550)
                                : Duration.zero,
                            curve: Curves.easeOutCubic,
                            height: 16,
                            width: (c.maxWidth * fraction).clamp(4.0, c.maxWidth),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _paletteAt(i).withOpacity(0.6),
                                  _paletteAt(i),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 28,
                  child: Text(
                    '${entries[i].value}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Compact horizontal-bar breakdown of ticket tiers (per-event view).
class TierBreakdownChart extends StatelessWidget {
  const TierBreakdownChart({required this.data, this.animate = true, super.key});

  final Map<String, int> data;
  final bool animate;

  @override
  Widget build(BuildContext context) =>
      InterestBarChart(data: data, animate: animate);
}

/// Shared helper: renders a labelled chart section, or an inline
/// insufficient-data note when the k-anon map is empty.
class AudienceChartSection extends StatelessWidget {
  const AudienceChartSection({
    required this.title,
    required this.icon,
    required this.isEmpty,
    required this.emptyMessage,
    required this.chart,
    super.key,
  });

  final String title;
  final IconData icon;
  final bool isEmpty;
  final String emptyMessage;
  final Widget chart;

  @override
  Widget build(BuildContext context) {
    return AudienceChartCard(
      title: title,
      icon: icon,
      child: isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                emptyMessage,
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            )
          : chart,
    );
  }
}

/// Small spacer constant re-exported for screens composing chart lists.
const double kChartGap = AppDimensions.paddingL;

/// Builds the shared audience-insights chart stack (age bars, country donut,
/// interest bars) from an already-k-anonymized [AudienceAggregate]. Reused by
/// both the aggregate business dashboard and the per-event dashboard.
///
/// Honors reduced-motion: chart animations are disabled when the platform
/// requests `MediaQuery.disableAnimations`.
List<Widget> buildAudienceCharts(
  BuildContext context,
  AudienceAggregate audience,
  AppLocalizations l10n,
) {
  final animate = !MediaQuery.of(context).disableAnimations;

  // Section header with the privacy disclaimer.
  final header = Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.audienceSectionTitle,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.shield_outlined,
                color: AppColors.textTertiary, size: 14),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                l10n.audiencePrivacyNote,
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  if (!audience.hasData) {
    return [
      header,
      ChartInsufficientData(message: l10n.audienceNotEnoughData),
    ];
  }

  return [
    header,
    AudienceChartSection(
      title: l10n.audienceAgeTitle,
      icon: Icons.cake_outlined,
      isEmpty: audience.ageBuckets.isEmpty,
      emptyMessage: l10n.audienceNotEnoughData,
      chart: AgeBarChart(data: audience.ageBuckets, animate: animate),
    ),
    const SizedBox(height: kChartGap),
    AudienceChartSection(
      title: l10n.audienceCountriesTitle,
      icon: Icons.public,
      isEmpty: audience.topCountries.isEmpty,
      emptyMessage: l10n.audienceNotEnoughData,
      chart: CountryDonutChart(data: audience.topCountries, animate: animate),
    ),
    const SizedBox(height: kChartGap),
    AudienceChartSection(
      title: l10n.audienceInterestsTitle,
      icon: Icons.interests_outlined,
      isEmpty: audience.topInterests.isEmpty,
      emptyMessage: l10n.audienceNotEnoughData,
      chart: InterestBarChart(data: audience.topInterests, animate: animate),
    ),
  ];
}
