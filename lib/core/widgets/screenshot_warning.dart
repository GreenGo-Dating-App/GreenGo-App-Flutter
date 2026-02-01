import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Enhancement #19: Screenshot Warning Dialog
/// Warns user that screenshot was detected
class ScreenshotWarningDialog extends StatelessWidget {
  final VoidCallback? onDismiss;
  final String? otherUserName;

  const ScreenshotWarningDialog({
    super.key,
    this.onDismiss,
    this.otherUserName,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.backgroundCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.warningAmber, width: 2),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.warningAmber.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.camera_alt,
              color: AppColors.warningAmber,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Screenshot Detected',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            otherUserName != null
                ? '$otherUserName will be notified that you took a screenshot of this conversation.'
                : 'The other user will be notified that you took a screenshot.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Please respect others\' privacy.',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onDismiss?.call();
          },
          child: const Text(
            'I Understand',
            style: TextStyle(
              color: AppColors.richGold,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

/// Screenshot notification banner
class ScreenshotNotificationBanner extends StatelessWidget {
  final String userName;
  final VoidCallback? onDismiss;

  const ScreenshotNotificationBanner({
    super.key,
    required this.userName,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.warningAmber.withOpacity(0.2),
      child: Row(
        children: [
          const Icon(
            Icons.camera_alt,
            color: AppColors.warningAmber,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$userName took a screenshot',
              style: const TextStyle(
                color: AppColors.warningAmber,
                fontSize: 13,
              ),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(
                Icons.close,
                color: AppColors.warningAmber,
                size: 18,
              ),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}

/// Show screenshot warning
void showScreenshotWarning(BuildContext context, {String? otherUserName}) {
  showDialog(
    context: context,
    builder: (context) => ScreenshotWarningDialog(
      otherUserName: otherUserName,
    ),
  );
}
