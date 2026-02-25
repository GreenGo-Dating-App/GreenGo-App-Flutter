import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Enhancement #3: Last Seen Text
/// Shows when a user was last active
class LastSeenText extends StatelessWidget {
  final DateTime? lastSeen;
  final bool isOnline;
  final double fontSize;

  const LastSeenText({
    super.key,
    this.lastSeen,
    this.isOnline = false,
    this.fontSize = 12,
  });

  String _formatLastSeen() {
    if (isOnline) return 'Online now';
    if (lastSeen == null) return 'Offline';

    final now = DateTime.now();
    final difference = now.difference(lastSeen!);

    if (difference.inMinutes < 1) {
      return 'Online just now';
    } else if (difference.inMinutes < 60) {
      return 'Online ${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return 'Online ${difference.inHours}h ago';
    } else if (difference.inDays < 5) {
      return 'Online ${difference.inDays}d ago';
    } else {
      return 'Offline';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatLastSeen(),
      style: TextStyle(
        color: isOnline ? AppColors.successGreen : AppColors.textTertiary,
        fontSize: fontSize,
        fontWeight: isOnline ? FontWeight.w500 : FontWeight.normal,
      ),
    );
  }
}
