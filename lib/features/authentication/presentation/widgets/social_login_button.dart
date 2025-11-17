import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

class SocialLoginButton extends StatelessWidget {
  final String icon;
  final VoidCallback? onPressed;
  final String? label;

  const SocialLoginButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    if (label != null) {
      // Full width button with label
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, AppDimensions.buttonHeightM),
          side: const BorderSide(color: AppColors.divider, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          backgroundColor: AppColors.backgroundCard,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              icon,
              width: 24,
              height: 24,
              errorBuilder: (context, error, stackTrace) {
                // Fallback to an icon if image fails to load
                return const Icon(
                  Icons.account_circle,
                  size: 24,
                  color: AppColors.richGold,
                );
              },
            ),
            const SizedBox(width: 12),
            Text(
              label!,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // Circular icon button
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.divider, width: 1.5),
        color: AppColors.backgroundCard,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(28),
          child: Center(
            child: Image.asset(
              icon,
              width: 24,
              height: 24,
              errorBuilder: (context, error, stackTrace) {
                // Fallback to an icon if image fails to load
                return const Icon(
                  Icons.account_circle,
                  size: 24,
                  color: AppColors.richGold,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
