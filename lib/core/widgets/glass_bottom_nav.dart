import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../theme/app_glass.dart';

/// A single entry in a [GlassBottomNav].
class GlassNavItem {
  const GlassNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount = 0,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;

  /// Unread count rendered as a small red badge at the icon's top-right.
  /// A value of 0 (or less) hides the badge. Values above 99 render as "99+".
  final int badgeCount;
}

/// A floating, frosted-glass bottom navigation bar.
///
/// Renders a blurred glass pill containing icon + label entries. The selected
/// entry gets a soft gold pill background and gold tint. This is a standalone,
/// presentational widget — it is not wired into the app shell.
class GlassBottomNav extends StatelessWidget {
  const GlassBottomNav({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final List<GlassNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const String _fontFamily = 'Poppins';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: RepaintBoundary(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppGlass.radiusPill),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: AppGlass.blurSigma,
                sigmaY: AppGlass.blurSigma,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppGlass.surface,
                  borderRadius: BorderRadius.circular(AppGlass.radiusPill),
                  border: Border.all(color: AppGlass.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Expanded(
                        child: _NavButton(
                          item: items[i],
                          selected: i == currentIndex,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            onTap(i);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final GlassNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color tint = selected ? AppColors.richGold : Colors.white70;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppGlass.pressDuration,
        curve: AppGlass.spring,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.richGold.withOpacity(0.13)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppGlass.radiusPill),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _IconWithBadge(
              icon: selected ? item.activeIcon : item.icon,
              tint: tint,
              badgeCount: item.badgeCount,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: GlassBottomNav._fontFamily,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: tint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nav icon with an optional small red unread badge at the top-right corner.
class _IconWithBadge extends StatelessWidget {
  const _IconWithBadge({
    required this.icon,
    required this.tint,
    required this.badgeCount,
  });

  final IconData icon;
  final Color tint;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(this.icon, color: tint, size: 22);
    if (badgeCount <= 0) return icon;

    final label = badgeCount > 99 ? '99+' : '$badgeCount';
    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          right: -6,
          top: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.errorRed,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppGlass.surface, width: 1.5),
            ),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
