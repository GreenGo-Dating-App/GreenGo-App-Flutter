import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/message.dart';

/// Message Bubble Widget
///
/// Displays a single chat message
class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isCurrentUser;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isCurrentUser
              ? AppColors.richGold
              : AppColors.backgroundCard,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppDimensions.radiusM),
            topRight: const Radius.circular(AppDimensions.radiusM),
            bottomLeft: Radius.circular(
                isCurrentUser ? AppDimensions.radiusM : AppDimensions.radiusS),
            bottomRight: Radius.circular(
                isCurrentUser ? AppDimensions.radiusS : AppDimensions.radiusM),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message content
            _buildMessageContent(),

            const SizedBox(height: 4),

            // Time and read status
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.timeText,
                  style: TextStyle(
                    color: isCurrentUser
                        ? AppColors.deepBlack.withOpacity(0.6)
                        : AppColors.textTertiary,
                    fontSize: 11,
                  ),
                ),
                if (isCurrentUser) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: message.isRead
                        ? AppColors.successGreen
                        : AppColors.deepBlack.withOpacity(0.6),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent() {
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.content,
          style: TextStyle(
            color: isCurrentUser ? AppColors.deepBlack : AppColors.textPrimary,
            fontSize: 15,
            height: 1.4,
          ),
        );

      case MessageType.image:
        return Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              child: Image.network(
                message.content,
                width: 200,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 200,
                  height: 200,
                  color: AppColors.backgroundDark,
                  child: const Icon(
                    Icons.broken_image,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ),
            if (message.metadata?['caption'] != null) ...[
              const SizedBox(height: 8),
              Text(
                message.metadata!['caption'] as String,
                style: TextStyle(
                  color: isCurrentUser
                      ? AppColors.deepBlack
                      : AppColors.textPrimary,
                  fontSize: 15,
                ),
              ),
            ],
          ],
        );

      case MessageType.system:
        return Text(
          message.content,
          style: TextStyle(
            color: AppColors.textTertiary,
            fontSize: 13,
            fontStyle: FontStyle.italic,
          ),
        );

      default:
        return Text(
          message.content,
          style: TextStyle(
            color: isCurrentUser ? AppColors.deepBlack : AppColors.textPrimary,
            fontSize: 15,
          ),
        );
    }
  }
}
