import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

class AuthButton extends StatelessWidget {
  const AuthButton({
    required this.text,
    super.key,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.height = AppDimensions.buttonHeightM,
    this.gradient,
    this.borderRadius = AppDimensions.radiusM,
  });
  /// Optional fill gradient (login's liquid-gold button). Replaces the solid
  /// [backgroundColor] for the filled variant.
  final Gradient? gradient;
  final double borderRadius;
  /// Minimum button height (login uses a slightly taller 52).
  final double height;
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: Size(double.infinity, height),
          side: BorderSide(
            color: backgroundColor ?? AppColors.richGold,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: _buildChild(context),
      );
    }

    final radius = BorderRadius.circular(borderRadius);
    final g = gradient;
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: g != null
            ? Colors.transparent
            : (backgroundColor ?? AppColors.richGold),
        disabledBackgroundColor: g != null ? Colors.transparent : null,
        shadowColor: g != null ? Colors.transparent : null,
        foregroundColor: textColor ?? AppColors.deepBlack,
        minimumSize: Size(double.infinity, height),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: radius),
        backgroundBuilder: g == null
            ? null
            : (context, states, child) => DecoratedBox(
                  decoration: BoxDecoration(gradient: g, borderRadius: radius),
                  child: child,
                ),
      ),
      child: _buildChild(context),
    );
  }

  Widget _buildChild(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.deepBlack),
        ),
      );
    }

    if (icon != null) {
      return Row(
        // Shrink-wrap and let the label flex: a full-width button on a 320pt
        // phone leaves ~224pt for this row, and a longer label overflowed it,
        // clipping the label instead of ellipsising.
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isOutlined
                    ? (textColor ?? AppColors.richGold)
                    : (textColor ?? AppColors.deepBlack),
              ),
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isOutlined
            ? (textColor ?? AppColors.richGold)
            : (textColor ?? AppColors.deepBlack),
      ),
    );
  }
}
