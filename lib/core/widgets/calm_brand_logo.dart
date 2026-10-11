import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'gold_shimmer.dart';

/// Static brand logo with a soft, subtle glow behind it — no sparkles, no
/// twinkle, no pulse. Used by the calm auth screens (login, waiting).
class CalmBrandLogo extends StatelessWidget {
  const CalmBrandLogo({
    required this.assetPath,
    super.key,
    this.size = 112,
    this.shimmer = false,
  });

  final String assetPath;
  final double size;

  /// Slow gold light sweep across the mark every ~9 s (login).
  final bool shimmer;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) => Center(
        child: Text(
          'G',
          style: TextStyle(
            fontSize: size * 0.45,
            fontWeight: FontWeight.w600,
            color: AppColors.richGold,
          ),
        ),
      ),
    );
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // One wide, very low-alpha halo: reads as "lit", not "glittery".
          gradient: RadialGradient(
            colors: [
              AppColors.richGold.withValues(alpha: 0.10),
              AppColors.richGold.withValues(alpha: 0.0),
            ],
            stops: const [0.25, 1.0],
          ),
        ),
        // Shimmer only the mark, not the halo behind it.
        child: shimmer ? GoldShimmer(child: image) : image,
      ),
    );
  }
}
