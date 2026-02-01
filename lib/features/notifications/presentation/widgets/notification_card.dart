import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/notification.dart';

/// Notification Card Widget
///
/// Displays a single notification
class NotificationCard extends StatelessWidget {
  final NotificationEntity notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.notificationId),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.errorRed,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isRead
                ? Colors.transparent
                : AppColors.richGold.withOpacity(0.05),
            border: Border(
              bottom: BorderSide(
                color: AppColors.divider.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getIconBackgroundColor(),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIcon(),
                  color: _getIconColor(),
                  size: 24,
                ),
              ),

              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      notification.title,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: notification.isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Message
                    Text(
                      notification.message,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Time
                    Text(
                      notification.timeSinceText,
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Unread indicator
              if (!notification.isRead)
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.richGold,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (notification.type) {
      case NotificationType.newMatch:
        return Icons.favorite;
      case NotificationType.newMessage:
        return Icons.chat_bubble;
      case NotificationType.newLike:
        return Icons.thumb_up;
      case NotificationType.profileView:
        return Icons.visibility;
      case NotificationType.superLike:
        return Icons.star;
      case NotificationType.matchExpiring:
        return Icons.schedule;
      case NotificationType.promotional:
        return Icons.local_offer;
      case NotificationType.system:
        return Icons.info;
      case NotificationType.newChat:
        return Icons.forum;
      case NotificationType.coinsPurchased:
        return Icons.monetization_on;
      case NotificationType.progressAchieved:
        return Icons.emoji_events;
    }
  }

  Color _getIconColor() {
    switch (notification.type) {
      case NotificationType.newMatch:
      case NotificationType.superLike:
        return AppColors.richGold;
      case NotificationType.newMessage:
        return AppColors.successGreen;
      case NotificationType.newLike:
        return AppColors.richGold;
      case NotificationType.profileView:
        return AppColors.textSecondary;
      case NotificationType.matchExpiring:
        return AppColors.errorRed;
      case NotificationType.promotional:
        return AppColors.richGold;
      case NotificationType.system:
        return AppColors.textSecondary;
      case NotificationType.newChat:
        return AppColors.successGreen;
      case NotificationType.coinsPurchased:
        return AppColors.richGold;
      case NotificationType.progressAchieved:
        return AppColors.richGold;
    }
  }

  Color _getIconBackgroundColor() {
    return _getIconColor().withOpacity(0.1);
  }
}
