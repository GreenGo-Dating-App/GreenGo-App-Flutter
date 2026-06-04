import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Enhancement #24: Custom Pull to Refresh
/// Custom refresh indicator with GreenGo branding
class CustomRefreshIndicator extends StatelessWidget {

  const CustomRefreshIndicator({
    required this.child, required this.onRefresh, super.key,
    this.color,
    this.backgroundColor,
  });
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: color ?? AppColors.richGold,
      backgroundColor: backgroundColor ?? AppColors.backgroundCard,
      strokeWidth: 3,
      displacement: 60,
      child: child,
    );
  }
}

/// Custom refresh header with logo
class GreenGoRefreshHeader extends StatelessWidget {

  const GreenGoRefreshHeader({
    required this.onRefresh, required this.child, super.key,
    this.refreshTriggerPullDistance = 100.0,
    this.refreshIndicatorExtent = 60.0,
  });
  final double refreshTriggerPullDistance;
  final double refreshIndicatorExtent;
  final RefreshCallback onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomRefreshIndicator(
      onRefresh: onRefresh,
      child: child,
    );
  }
}

/// Pull instruction hint
class PullToRefreshHint extends StatelessWidget {

  const PullToRefreshHint({
    super.key,
    this.message = 'Pull to refresh',
  });
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.arrow_downward,
            size: 16,
            color: AppColors.textTertiary,
          ),
          const SizedBox(width: 8),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
