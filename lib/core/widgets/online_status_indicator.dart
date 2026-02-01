import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Enhancement #1: Online Status Indicator
/// Shows a green dot when user is online, yellow when away, gray when offline
class OnlineStatusIndicator extends StatelessWidget {
  final bool isOnline;
  final bool isAway;
  final double size;
  final bool showBorder;

  const OnlineStatusIndicator({
    super.key,
    required this.isOnline,
    this.isAway = false,
    this.size = 12,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    if (isOnline) {
      statusColor = AppColors.online;
    } else if (isAway) {
      statusColor = AppColors.away;
    } else {
      statusColor = AppColors.offline;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: statusColor,
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
                color: AppColors.backgroundDark,
                width: 2,
              )
            : null,
        boxShadow: isOnline
            ? [
                BoxShadow(
                  color: statusColor.withOpacity(0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );
  }
}
