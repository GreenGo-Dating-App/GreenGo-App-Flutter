import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../domain/entities/conversation.dart';

/// Conversation Card Widget
///
/// Displays a conversation in the list
class ConversationCard extends StatelessWidget {
  final Conversation conversation;
  final Profile? otherUserProfile;
  final String currentUserId;
  final VoidCallback? onTap;

  const ConversationCard({
    super.key,
    required this.conversation,
    required this.otherUserProfile,
    required this.currentUserId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnread = conversation.hasUnreadMessages;
    final isTyping = conversation.isOtherUserTyping(currentUserId);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.divider.withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Profile photo
            Stack(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.backgroundCard,
                  backgroundImage: otherUserProfile?.photoUrls.isNotEmpty ??
                          false
                      ? NetworkImage(otherUserProfile!.photoUrls.first)
                      : null,
                  child: otherUserProfile?.photoUrls.isEmpty ?? true
                      ? const Icon(
                          Icons.person,
                          size: 30,
                          color: AppColors.textTertiary,
                        )
                      : null,
                ),

                // Unread badge
                if (hasUnread)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.richGold,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        conversation.unreadCount > 9
                            ? '9+'
                            : '${conversation.unreadCount}',
                        style: const TextStyle(
                          color: AppColors.deepBlack,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 12),

            // Conversation info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    otherUserProfile?.displayName ?? 'Unknown',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight:
                          hasUnread ? FontWeight.bold : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Last message or typing indicator
                  if (isTyping)
                    const Row(
                      children: [
                        Text(
                          'typing',
                          style: TextStyle(
                            color: AppColors.richGold,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        SizedBox(width: 4),
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            color: AppColors.richGold,
                            strokeWidth: 2,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      conversation.lastMessagePreview,
                      style: TextStyle(
                        color: hasUnread
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight:
                            hasUnread ? FontWeight.w500 : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // Time
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  conversation.timeSinceLastMessage,
                  style: TextStyle(
                    color: hasUnread
                        ? AppColors.richGold
                        : AppColors.textTertiary,
                    fontSize: 12,
                    fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
