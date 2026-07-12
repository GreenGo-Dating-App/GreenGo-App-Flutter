import 'package:flutter/material.dart';

import '../../../../core/theme/app_glass.dart';

/// A single headline statistic rendered as a colored glass card.
@immutable
class StatItem {
  const StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;

  /// Distinct accent colour used for the icon, tint, border and glow.
  final Color accent;
}

/// A curated, dark-theme-friendly palette for the headline stat cards.
///
/// Soft, tasteful hues (gold, teal, violet, coral, emerald, sky) that read as
/// gentle tints on the dark glass background rather than harsh fills.
abstract final class StatColors {
  static const Color gold = Color(0xFFD4AF37);
  static const Color teal = Color(0xFF2DD4BF);
  static const Color violet = Color(0xFF9B8CFF);
  static const Color coral = Color(0xFFFF7A6B);
  static const Color emerald = Color(0xFF34D399);
  static const Color sky = Color(0xFF56B6F7);
}

/// Responsive 3×2 grid of colored [StatItem] cards.
///
/// Renders 3 columns on normal widths and gracefully drops to 2 columns on
/// narrow screens so cards never overflow. It shrink-wraps and disables its own
/// scrolling so it can headline a parent [SingleChildScrollView]. No animation
/// is used, so it is inherently friendly to reduced-motion preferences.
class StatGrid extends StatelessWidget {
  const StatGrid({required this.items, super.key});

  final List<StatItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Drop to 2 columns on narrow screens so labels/values never overflow.
        final crossAxisCount = constraints.maxWidth < 360 ? 2 : 3;
        // Slightly taller cards when we have fewer, wider columns.
        final aspect = crossAxisCount == 2 ? 0.92 : 0.86;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: aspect,
          children: [
            for (final item in items) _StatCard(item: item),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.item});

  final StatItem item;

  @override
  Widget build(BuildContext context) {
    final accent = item.accent;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppGlass.radiusCard),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withOpacity(0.20),
            accent.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: accent.withOpacity(0.30)),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.14),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: accent, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    item.value,
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 12,
                    height: 1.15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
