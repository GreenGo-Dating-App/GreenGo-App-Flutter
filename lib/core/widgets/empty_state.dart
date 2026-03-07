import 'package:flutter/material.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIllustration(),
            const SizedBox(height: 24),
            Text(
              title ?? _getDefaultTitle(l10n),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message ?? _getDefaultMessage(l10n),
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

  String _getDefaultTitle(AppLocalizations l10n) {
    switch (type) {
      case EmptyStateType.noMatches:
        return l10n.emptyStateNoMatchesTitle;
      case EmptyStateType.noMessages:
        return l10n.emptyStateNoMessagesTitle;
      case EmptyStateType.noNotifications:
        return l10n.emptyStateNoNotificationsTitle;
      case EmptyStateType.noLikes:
        return l10n.emptyStateNoLikesTitle;
      case EmptyStateType.noResults:
        return l10n.emptyStateNoResultsTitle;
      case EmptyStateType.noInternet:
        return l10n.emptyStateNoInternetTitle;
      case EmptyStateType.error:
        return l10n.emptyStateErrorTitle;
    }
  }

  String _getDefaultMessage(AppLocalizations l10n) {
    switch (type) {
      case EmptyStateType.noMatches:
        return l10n.emptyStateNoMatchesMessage;
      case EmptyStateType.noMessages:
        return l10n.emptyStateNoMessagesMessage;
      case EmptyStateType.noNotifications:
        return l10n.emptyStateNoNotificationsMessage;
      case EmptyStateType.noLikes:
        return l10n.emptyStateNoLikesMessage;
      case EmptyStateType.noResults:
        return l10n.emptyStateNoResultsMessage;
      case EmptyStateType.noInternet:
        return l10n.emptyStateNoInternetMessage;
      case EmptyStateType.error:
        return l10n.emptyStateErrorMessage;
    }
  }
}
