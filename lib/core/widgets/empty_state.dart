import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Enhancement #22: Empty State Illustrations
/// Beautiful empty states for different scenarios
enum EmptyStateType {
  noMatches,
  noMessages,
  noNotifications,
  noLikes,
  noResults,
  noInternet,
  error,
}

class EmptyState extends StatelessWidget {
  final EmptyStateType type;
  final String? title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.type,
    this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIllustration(),
            const SizedBox(height: 24),
            Text(
              title ?? _getDefaultTitle(),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message ?? _getDefaultMessage(),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.richGold,
                  foregroundColor: AppColors.deepBlack,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(
                  actionLabel!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration() {
    IconData icon;
    Color color;
    String emoji;

    switch (type) {
      case EmptyStateType.noMatches:
        icon = Icons.favorite_border;
        color = AppColors.errorRed;
        emoji = '💔';
        break;
      case EmptyStateType.noMessages:
        icon = Icons.chat_bubble_outline;
        color = AppColors.infoBlue;
        emoji = '💬';
        break;
      case EmptyStateType.noNotifications:
        icon = Icons.notifications_none;
        color = AppColors.warningAmber;
        emoji = '🔔';
        break;
      case EmptyStateType.noLikes:
        icon = Icons.thumb_up_outlined;
        color = AppColors.richGold;
        emoji = '👍';
        break;
      case EmptyStateType.noResults:
        icon = Icons.search_off;
        color = AppColors.textTertiary;
        emoji = '🔍';
        break;
      case EmptyStateType.noInternet:
        icon = Icons.wifi_off;
        color = AppColors.warningAmber;
        emoji = '📡';
        break;
      case EmptyStateType.error:
        icon = Icons.error_outline;
        color = AppColors.errorRed;
        emoji = '❌';
        break;
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // Background circle
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
        ),
        // Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 36),
            ),
          ),
        ),
      ],
    );
  }

  String _getDefaultTitle() {
    switch (type) {
      case EmptyStateType.noMatches:
        return 'No matches yet';
      case EmptyStateType.noMessages:
        return 'No messages';
      case EmptyStateType.noNotifications:
        return 'All caught up!';
      case EmptyStateType.noLikes:
        return 'No likes yet';
      case EmptyStateType.noResults:
        return 'No results found';
      case EmptyStateType.noInternet:
        return 'No connection';
      case EmptyStateType.error:
        return 'Something went wrong';
    }
  }

  String _getDefaultMessage() {
    switch (type) {
      case EmptyStateType.noMatches:
        return 'Start swiping to find your perfect match!';
      case EmptyStateType.noMessages:
        return 'When you match with someone, you can start chatting here.';
      case EmptyStateType.noNotifications:
        return 'You don\'t have any new notifications.';
      case EmptyStateType.noLikes:
        return 'Complete your profile to get more likes!';
      case EmptyStateType.noResults:
        return 'Try adjusting your search or filters.';
      case EmptyStateType.noInternet:
        return 'Please check your internet connection and try again.';
      case EmptyStateType.error:
        return 'We couldn\'t load this content. Please try again.';
    }
  }
}
