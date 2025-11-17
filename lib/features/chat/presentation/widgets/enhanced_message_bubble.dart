import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/message.dart';

/// Enhanced Message Bubble Widget
///
/// Displays a chat message with reactions, status indicators, and context menu
class EnhancedMessageBubble extends StatelessWidget {
  final Message message;
  final bool isCurrentUser;
  final String currentUserId;
  final VoidCallback? onReact;
  final VoidCallback? onCopy;
  final VoidCallback? onDelete;
  final VoidCallback? onForward;
  final VoidCallback? onTranslate;

  const EnhancedMessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    required this.currentUserId,
    this.onReact,
    this.onCopy,
    this.onDelete,
    this.onForward,
    this.onTranslate,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showContextMenu(context),
      child: Align(
        alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Message bubble
            Container(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Column(
                crossAxisAlignment: isCurrentUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  // Main message container
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isCurrentUser
                          ? AppColors.richGold
                          : AppColors.backgroundCard,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(AppDimensions.radiusM),
                        topRight: const Radius.circular(AppDimensions.radiusM),
                        bottomLeft: Radius.circular(isCurrentUser
                            ? AppDimensions.radiusM
                            : AppDimensions.radiusS),
                        bottomRight: Radius.circular(isCurrentUser
                            ? AppDimensions.radiusS
                            : AppDimensions.radiusM),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Message content
                        _buildMessageContent(context),

                        // Translation if available
                        if (message.isTranslated) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (isCurrentUser
                                      ? AppColors.deepBlack
                                      : AppColors.backgroundDark)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusS),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.translate,
                                      size: 12,
                                      color: isCurrentUser
                                          ? AppColors.deepBlack
                                              .withOpacity(0.6)
                                          : AppColors.textTertiary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Translated',
                                      style: TextStyle(
                                        color: isCurrentUser
                                            ? AppColors.deepBlack
                                                .withOpacity(0.6)
                                            : AppColors.textTertiary,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  message.translatedContent!,
                                  style: TextStyle(
                                    color: isCurrentUser
                                        ? AppColors.deepBlack.withOpacity(0.8)
                                        : AppColors.textSecondary,
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 4),

                        // Time and status indicators
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
                              _buildStatusIndicator(),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Reactions
                  if (message.hasReactions) ...[
                    const SizedBox(height: 4),
                    _buildReactions(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
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

      case MessageType.video:
        return Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.backgroundDark,
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Video thumbnail
              if (message.metadata?['thumbnailUrl'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  child: Image.network(
                    message.metadata!['thumbnailUrl'] as String,
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              // Play button
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.deepBlack.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
        );

      case MessageType.voiceNote:
        return Container(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.mic,
                color: isCurrentUser
                    ? AppColors.deepBlack
                    : AppColors.richGold,
                size: 20,
              ),
              const SizedBox(width: 8),
              // Waveform visualization placeholder
              Container(
                width: 120,
                height: 30,
                decoration: BoxDecoration(
                  color: (isCurrentUser
                          ? AppColors.deepBlack
                          : AppColors.richGold)
                      .withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    message.metadata?['duration'] ?? '0:00',
                    style: TextStyle(
                      color: isCurrentUser
                          ? AppColors.deepBlack
                          : AppColors.textPrimary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.play_arrow,
                color: isCurrentUser
                    ? AppColors.deepBlack
                    : AppColors.richGold,
                size: 20,
              ),
            ],
          ),
        );

      case MessageType.gif:
      case MessageType.sticker:
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          child: Image.network(
            message.content,
            width: 150,
            height: 150,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 150,
              height: 150,
              color: AppColors.backgroundDark,
              child: const Icon(
                Icons.broken_image,
                color: AppColors.textTertiary,
              ),
            ),
          ),
        );

      case MessageType.system:
        return Text(
          message.content,
          style: const TextStyle(
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

  Widget _buildStatusIndicator() {
    IconData icon;
    Color color;

    switch (message.status) {
      case MessageStatus.sending:
        icon = Icons.access_time;
        color = AppColors.deepBlack.withOpacity(0.4);
        break;
      case MessageStatus.sent:
        icon = Icons.done;
        color = AppColors.deepBlack.withOpacity(0.6);
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        color = AppColors.deepBlack.withOpacity(0.6);
        break;
      case MessageStatus.read:
        icon = Icons.done_all;
        color = AppColors.successGreen;
        break;
      case MessageStatus.failed:
        icon = Icons.error_outline;
        color = AppColors.errorRed;
        break;
    }

    return Icon(
      icon,
      size: 14,
      color: color,
    );
  }

  Widget _buildReactions() {
    final reactionsList = message.reactions!.entries.toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.divider,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < reactionsList.length && i < 3; i++) ...[
            Text(
              reactionsList[i].value,
              style: const TextStyle(fontSize: 14),
            ),
            if (i < reactionsList.length - 1 && i < 2)
              const SizedBox(width: 4),
          ],
          if (reactionsList.length > 3) ...[
            const SizedBox(width: 4),
            Text(
              '+${reactionsList.length - 3}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusL),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Quick reactions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildQuickReaction(context, '❤️'),
                  _buildQuickReaction(context, '😂'),
                  _buildQuickReaction(context, '😮'),
                  _buildQuickReaction(context, '😢'),
                  _buildQuickReaction(context, '😡'),
                  _buildQuickReaction(context, '👍'),
                ],
              ),
            ),

            const Divider(height: 1),

            // Menu options
            if (message.type == MessageType.text)
              _buildMenuItem(
                context,
                icon: Icons.copy,
                title: 'Copy',
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: message.content));
                  if (onCopy != null) onCopy!();
                },
              ),

            if (!message.isTranslated && message.type == MessageType.text)
              _buildMenuItem(
                context,
                icon: Icons.translate,
                title: 'Translate',
                onTap: () {
                  Navigator.pop(context);
                  if (onTranslate != null) onTranslate!();
                },
              ),

            _buildMenuItem(
              context,
              icon: Icons.forward,
              title: 'Forward',
              onTap: () {
                Navigator.pop(context);
                if (onForward != null) onForward!();
              },
            ),

            if (isCurrentUser)
              _buildMenuItem(
                context,
                icon: Icons.delete,
                title: 'Delete',
                color: AppColors.errorRed,
                onTap: () {
                  Navigator.pop(context);
                  if (onDelete != null) onDelete!();
                },
              ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickReaction(BuildContext context, String emoji) {
    final bool isReacted = message.getReaction(currentUserId) == emoji;

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        if (onReact != null) onReact!();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isReacted
              ? AppColors.richGold.withOpacity(0.2)
              : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: isReacted ? AppColors.richGold : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: color ?? AppColors.textPrimary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? AppColors.textPrimary,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
    );
  }
}
