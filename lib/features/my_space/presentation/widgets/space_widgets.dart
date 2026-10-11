import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Shared building blocks of My Space and the booking dashboard cards:
/// dark cards with a subtle gold edge, gold-tinted icon badges, count pills.
/// Every tappable surface is at least 48 px tall and carries a Semantics label.

const double kSpaceRadius = 16;

/// Rounded, gold-tinted square holding an icon.
class SpaceIconBadge extends StatelessWidget {
  const SpaceIconBadge({
    super.key,
    required this.icon,
    this.size = 44,
    this.color = AppColors.richGold,
    this.filled = false,
  });

  final IconData icon;
  final double size;
  final Color color;

  /// Solid badge (on a gold surface) instead of the tinted one.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        gradient: filled
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.26),
                  color.withValues(alpha: 0.08),
                ],
              ),
        color: filled ? AppColors.deepBlack.withValues(alpha: 0.18) : null,
        border: Border.all(
            color: filled
                ? AppColors.deepBlack.withValues(alpha: 0.2)
                : color.withValues(alpha: 0.35)),
      ),
      child: Icon(icon,
          size: size * 0.5, color: filled ? AppColors.deepBlack : color),
    );
  }
}

/// A count pill ("3"). [urgent] = amber, to draw the eye.
class SpaceCountBadge extends StatelessWidget {
  const SpaceCountBadge({super.key, required this.count, this.urgent = false});

  final int count;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final bg = urgent ? AppColors.warningAmber : AppColors.richGold;
    return Container(
      constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(color: bg.withValues(alpha: 0.35), blurRadius: 8),
        ],
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: AppColors.deepBlack,
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// The dark card surface with a soft gold edge.
class SpaceCard extends StatelessWidget {
  const SpaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.highlight = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Stronger gold edge (something needs attention).
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kSpaceRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.backgroundCard,
            Color.alphaBlend(AppColors.richGold.withValues(alpha: 0.05),
                AppColors.backgroundCard),
          ],
        ),
        border: Border.all(
          color: AppColors.richGold.withValues(alpha: highlight ? 0.55 : 0.18),
        ),
      ),
      child: child,
    );
  }
}

/// A tappable dashboard card: icon badge, title, live subtitle, optional
/// count pill, chevron, ink ripple. Used by My Space and My experiences.
class SpaceDashboardCard extends StatelessWidget {
  const SpaceDashboardCard({
    super.key,
    this.inkKey,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.badgeCount = 0,
    this.urgent = false,
    this.loading = false,
  });

  /// Key of the tappable area (tests tap it).
  final Key? inkKey;
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  /// Shown as a pill when > 0.
  final int badgeCount;

  /// Something to act on: amber pill + stronger edge.
  final bool urgent;

  /// Subtitle still loading (a short shimmer bar instead).
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final label =
        [title, if (subtitle != null && !loading) subtitle!].join('. ');
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: inkKey,
          onTap: onTap,
          borderRadius: BorderRadius.circular(kSpaceRadius),
          splashColor: AppColors.richGold.withValues(alpha: 0.12),
          highlightColor: AppColors.richGold.withValues(alpha: 0.06),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kSpaceRadius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.backgroundCard,
                  Color.alphaBlend(
                      AppColors.richGold.withValues(alpha: urgent ? 0.1 : 0.05),
                      AppColors.backgroundCard),
                ],
              ),
              border: Border.all(
                color: urgent
                    ? AppColors.warningAmber.withValues(alpha: 0.7)
                    : AppColors.richGold.withValues(alpha: 0.25),
              ),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 72),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                child: Row(children: [
                  SpaceIconBadge(icon: icon, size: 42),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (loading)
                          Container(
                            width: 64,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppColors.textTertiary
                                  .withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          )
                        else if (subtitle != null)
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: urgent
                                  ? AppColors.warningAmber
                                  : AppColors.textTertiary,
                              fontSize: 12.5,
                              fontWeight:
                                  urgent ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (badgeCount > 0) ...[
                    const SizedBox(width: 6),
                    SpaceCountBadge(count: badgeCount, urgent: urgent),
                  ],
                  const Icon(Icons.chevron_right,
                      color: AppColors.textTertiary, size: 22),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Two widgets side by side, stacked vertically when the space is too narrow
/// for both to read well (phones at 320 px, split views).
class SpacePair extends StatelessWidget {
  const SpacePair({
    super.key,
    required this.first,
    required this.second,
    this.breakpoint = 360,
    this.gap = 10,
  });

  final Widget first;
  final Widget second;
  final double breakpoint;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth < breakpoint) {
        return Column(children: [first, SizedBox(height: gap), second]);
      }
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: first),
            SizedBox(width: gap),
            Expanded(child: second),
          ],
        ),
      );
    });
  }
}

/// Small uppercase section label with an optional trailing action.
class SpaceSectionHeader extends StatelessWidget {
  const SpaceSectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.trailing,
  });

  final String title;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 0, 8),
      child: Row(children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: AppColors.richGold),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

/// "12 / 20 checked in" + a gold progress bar.
class SpaceProgress extends StatelessWidget {
  const SpaceProgress({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;

  /// 0..1; null = unknown (indeterminate, while counting).
  final double? value;

  @override
  Widget build(BuildContext context) {
    final done = value != null && value! >= 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [
          Icon(done ? Icons.check_circle : Icons.how_to_reg_outlined,
              size: 15,
              color: done ? AppColors.successGreen : AppColors.richGold),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 6,
            backgroundColor: AppColors.textTertiary.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation(
                done ? AppColors.successGreen : AppColors.richGold),
          ),
        ),
      ],
    );
  }
}

/// A compact date block (MON / 14) used in event & session rows.
class SpaceDateBlock extends StatelessWidget {
  const SpaceDateBlock({
    super.key,
    required this.weekday,
    required this.day,
    this.today = false,
  });

  final String weekday;
  final String day;
  final bool today;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: today
            ? AppColors.richGold
            : AppColors.richGold.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.richGold.withValues(alpha: 0.35)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(
          weekday.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: TextStyle(
            color: today ? AppColors.deepBlack : AppColors.richGold,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        Text(
          day,
          style: TextStyle(
            color: today ? AppColors.deepBlack : AppColors.textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
      ]),
    );
  }
}

/// Centers [child] and caps its width on tablets / desktop / web.
class SpaceMaxWidth extends StatelessWidget {
  const SpaceMaxWidth({super.key, required this.child, this.maxWidth = 760});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}
