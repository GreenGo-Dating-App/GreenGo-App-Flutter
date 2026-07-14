import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Enhancement #2: Verified Badge
/// Shows a verification checkmark for verified users
class VerifiedBadge extends StatelessWidget {

  const VerifiedBadge({
    super.key,
    this.size = 16,
    this.isPremium = false,
  });
  final double size;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isPremium ? AppColors.richGold : AppColors.infoBlue,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.check,
        size: size * 0.7,
        color: isPremium ? AppColors.deepBlack : Colors.white,
      ),
    );
  }
}

/// Business account badge — a gold "Business" pill shown on business profiles.
/// The [label] is passed in so the text stays localized.
class BusinessBadge extends StatelessWidget {
  const BusinessBadge({required this.label, super.key, this.size = 20});
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.storefront, size: size * 0.75, color: AppColors.deepBlack),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.deepBlack,
              fontSize: size * 0.6,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Premium/Gold member badge
class PremiumBadge extends StatelessWidget {

  const PremiumBadge({
    super.key,
    this.size = 20,
  });
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium,
            size: size * 0.8,
            color: AppColors.deepBlack,
          ),
          const SizedBox(width: 2),
          Text(
            'PRO',
            style: TextStyle(
              color: AppColors.deepBlack,
              fontSize: size * 0.6,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
