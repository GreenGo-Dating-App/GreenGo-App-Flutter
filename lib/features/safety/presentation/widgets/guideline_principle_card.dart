import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_glass.dart';

/// A single, icon-led community-guideline principle rendered as a frosted glass
/// card: a gold-tinted circular icon badge on the left, a bold one-line title
/// and a short supporting description on the right.
///
/// Used on the [CommunityGuidelinesScreen] to turn the plain guidelines text
/// into a set of scannable, welcoming principles.
class GuidelinePrincipleCard extends StatelessWidget {
  const GuidelinePrincipleCard({
    required this.icon,
    required this.title,
    required this.description,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppGlass.radiusCard);

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppGlass.blurSigma,
            sigmaY: AppGlass.blurSigma,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppGlass.surface,
              borderRadius: radius,
              border: Border.all(color: AppGlass.border),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.0),
                ],
                stops: const [0.0, 0.4],
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _GoldIconBadge(icon: icon),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Gold-tinted circular glass badge holding a single material icon.
class _GoldIconBadge extends StatelessWidget {
  const _GoldIconBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.richGold.withOpacity(0.28),
            AppColors.richGold.withOpacity(0.08),
          ],
        ),
        border: Border.all(color: AppColors.richGold.withOpacity(0.45)),
        boxShadow: [
          BoxShadow(
            color: AppColors.richGold.withOpacity(0.18),
            blurRadius: 14,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: Icon(icon, color: AppColors.accentGold, size: 24),
    );
  }
}

/// Wraps [child] in a staggered fade + slide entrance driven by [animation].
///
/// Each item animates in on a short [index]-based interval so the cards cascade
/// into view. When [reduceMotion] is true the entrance is skipped entirely and
/// the child is shown immediately (respecting `MediaQuery.disableAnimations`).
class StaggeredEntrance extends StatelessWidget {
  const StaggeredEntrance({
    required this.animation,
    required this.index,
    required this.child,
    this.itemCount = 8,
    this.reduceMotion = false,
    super.key,
  });

  final Animation<double> animation;
  final int index;
  final int itemCount;
  final bool reduceMotion;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion) return child;

    // Spread each item's window across the timeline with a small overlap so the
    // cards cascade (~40ms stagger feel) rather than all appearing at once.
    final double slot = 1.0 / (itemCount + 2);
    final double start = (index * slot).clamp(0.0, 0.85);
    final double end = (start + 0.45).clamp(0.0, 1.0);

    final curved = CurvedAnimation(
      parent: animation,
      curve: Interval(start, end, curve: AppGlass.spring),
    );

    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        final t = curved.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 18),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
