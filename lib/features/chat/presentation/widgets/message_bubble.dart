import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/message.dart';

/// Message Bubble Widget
///
/// Displays a single chat message with translation support
/// Double-tap to toggle between translated and original text
/// Long-press for message options (reply, forward, star, report)
class MessageBubble extends StatefulWidget {
  final Message message;
  final bool isCurrentUser;
  final String? currentUserId;
  final Function(Message)? onReport;
  final Function(Message, bool)? onStar;
  final Function(Message)? onReply;
  final Function(Message)? onForward;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.currentUserId,
    this.onReport,
    this.onStar,
    this.onReply,
    this.onForward,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _showOriginal = false;
  bool _isStarred = false;

  @override
  void initState() {
    super.initState();
    // Check if message is starred from metadata
    _isStarred = widget.message.metadata?['isStarred'] == true;
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final isCurrentUser = widget.isCurrentUser;
    final hasTranslation = message.translatedContent != null && message.translatedContent!.isNotEmpty;

    return GestureDetector(
      onDoubleTap: hasTranslation ? () {
        setState(() {
          _showOriginal = !_showOriginal;
        });
      } : null,
      onLongPress: () => _showMessageOptions(context),
      child: Align(
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
              // Reply indicator if this is a reply
              if (message.metadata?['replyToMessageId'] != null)
                _buildReplyIndicator(),

              // Message content
              _buildMessageContent(),

              const SizedBox(height: 4),

              // Translation indicator, star, and time
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Star indicator
                  if (_isStarred) ...[
                    Icon(
                      Icons.star,
                      size: 12,
                      color: isCurrentUser
                          ? AppColors.deepBlack.withOpacity(0.6)
                          : AppColors.richGold,
                    ),
                    const SizedBox(width: 4),
                  ],
                  // Show translation indicator if message is translated
                  if (hasTranslation) ...[
                    Icon(
                      Icons.translate,
                      size: 12,
                      color: isCurrentUser
                          ? AppColors.deepBlack.withOpacity(0.6)
                          : AppColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _showOriginal ? 'Original' : 'Translated',
                      style: TextStyle(
                        color: isCurrentUser
                            ? AppColors.deepBlack.withOpacity(0.6)
                            : AppColors.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
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
                      message.status == MessageStatus.sending
                          ? Icons.access_time
                          : message.isRead
                              ? Icons.done_all
                              : Icons.done,
                      size: 14,
                      color: message.status == MessageStatus.sending
                          ? AppColors.deepBlack.withOpacity(0.4)
                          : message.isRead
                              ? AppColors.successGreen
                              : AppColors.deepBlack.withOpacity(0.6),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReplyIndicator() {
    final isCurrentUser = widget.isCurrentUser;
    final replyContent = widget.message.metadata?['replyContent'] as String? ?? 'Message';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppColors.deepBlack.withOpacity(0.1)
            : AppColors.backgroundDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border(
          left: BorderSide(
            color: isCurrentUser ? AppColors.deepBlack.withOpacity(0.3) : AppColors.richGold,
            width: 3,
          ),
        ),
      ),
      child: Text(
        replyContent.length > 50 ? '${replyContent.substring(0, 50)}...' : replyContent,
        style: TextStyle(
          color: isCurrentUser
              ? AppColors.deepBlack.withOpacity(0.7)
              : AppColors.textSecondary,
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  void _toggleStar() {
    setState(() {
      _isStarred = !_isStarred;
    });
    widget.onStar?.call(widget.message, _isStarred);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isStarred ? 'Message starred' : 'Message unstarred'),
        duration: const Duration(seconds: 1),
        backgroundColor: AppColors.backgroundCard,
      ),
    );
  }

  Widget _buildMessageContent() {
    final message = widget.message;
    final isCurrentUser = widget.isCurrentUser;
    final hasTranslation = message.translatedContent != null && message.translatedContent!.isNotEmpty;

    // Determine which content to display
    // If translated and not showing original, show translated content
    // Otherwise show original content
    final displayContent = hasTranslation && !_showOriginal
        ? message.translatedContent!
        : message.content;

    switch (message.type) {
      case MessageType.text:
        return Text(
          displayContent,
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

  void _showMessageOptions(BuildContext context) {
    final message = widget.message;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Message Options',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.reply, color: Colors.blue),
              title: const Text(
                'Reply',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              subtitle: const Text(
                'Reply to this message',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                widget.onReply?.call(message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.forward, color: Colors.purple),
              title: const Text(
                'Forward',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              subtitle: const Text(
                'Forward to another chat',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                widget.onForward?.call(message);
              },
            ),
            ListTile(
              leading: Icon(
                _isStarred ? Icons.star : Icons.star_border,
                color: AppColors.richGold,
              ),
              title: Text(
                _isStarred ? 'Unstar Message' : 'Star Message',
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              subtitle: Text(
                _isStarred ? 'Remove from starred messages' : 'Add to starred messages',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _toggleStar();
              },
            ),
            if (!widget.isCurrentUser) ...[
              const Divider(color: AppColors.divider, height: 1),
              ListTile(
                leading: const Icon(Icons.flag, color: AppColors.errorRed),
                title: const Text(
                  'Report Message',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                subtitle: const Text(
                  'Report inappropriate content',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _showReportDialog(context);
                },
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    final reasons = [
      'Harassment or bullying',
      'Spam or scam',
      'Inappropriate content',
      'Sharing personal information',
      'Threatening behavior',
      'Other',
    ];

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text(
          'Report Message',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Why are you reporting this message?',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ...reasons.map((reason) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                reason,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              ),
              onTap: () {
                Navigator.pop(dialogContext);
                _submitReport(context, reason);
              },
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReport(BuildContext context, String reason) async {
    // Call the onReport callback if provided
    if (widget.onReport != null) {
      widget.onReport!(widget.message);
    }

    // Show a confirmation
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message reported. We will review it shortly.'),
          backgroundColor: AppColors.richGold,
        ),
      );
    }
  }
}
