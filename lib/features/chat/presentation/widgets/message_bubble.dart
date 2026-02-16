import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
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
                      _showOriginal ? AppLocalizations.of(context)!.chatMessageOriginal : AppLocalizations.of(context)!.chatMessageTranslated,
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
    final isMediaUrl = replyContent.contains('firebasestorage.googleapis.com') ||
        replyContent.startsWith('https://') && (replyContent.contains('/chat_images/') || replyContent.contains('/chat_videos/'));

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
      child: isMediaUrl
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Image.network(
                        replyContent,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.image, color: Colors.white54, size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  replyContent.contains('/chat_videos/') ? Icons.videocam : Icons.photo,
                  color: isCurrentUser
                      ? AppColors.deepBlack.withOpacity(0.5)
                      : AppColors.textSecondary,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  replyContent.contains('/chat_videos/') ? 'Video' : 'Photo',
                  style: TextStyle(
                    color: isCurrentUser
                        ? AppColors.deepBlack.withOpacity(0.7)
                        : AppColors.textSecondary,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            )
          : Text(
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
        content: Text(_isStarred ? AppLocalizations.of(context)!.chatMessageStarred : AppLocalizations.of(context)!.chatMessageUnstarred),
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
            GestureDetector(
              onTap: () => _openFullScreenImage(context, message.content),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Blurred thumbnail
                      ImageFiltered(
                        imageFilter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Image.network(
                          message.content,
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                          cacheWidth: 200,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: AppColors.backgroundDark,
                            child: const Icon(
                              Icons.broken_image,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                      ),
                      // Semi-transparent overlay + tap icon
                      Container(
                        color: Colors.black.withOpacity(0.2),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.visibility, color: Colors.white70, size: 32),
                            SizedBox(height: 6),
                            Text(
                              'Tap to view',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
        return Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              child: GestureDetector(
                onTap: () => _openVideoPlayer(context, message.content),
                child: Container(
                  width: 200,
                  height: 200,
                  color: AppColors.backgroundDark,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.videocam,
                        color: AppColors.textTertiary,
                        size: 48,
                      ),
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ],
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

  void _openVideoPlayer(BuildContext context, String videoUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullScreenVideoPlayer(videoUrl: videoUrl),
      ),
    );
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
            Text(
              AppLocalizations.of(context)!.chatMessageOptions,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.reply, color: Colors.blue),
              title: Text(
                AppLocalizations.of(context)!.chatReply,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              subtitle: Text(
                AppLocalizations.of(context)!.chatReplyToMessage,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                widget.onReply?.call(message);
              },
            ),
            // Hide forward for private album images (non-chat uploaded images)
            if (!(message.type == MessageType.image &&
                !message.content.contains('/chat_images/')))
              ListTile(
                leading: const Icon(Icons.forward, color: Colors.purple),
                title: Text(
                  AppLocalizations.of(context)!.chatForward,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                subtitle: Text(
                  AppLocalizations.of(context)!.chatForwardToChat,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
                _isStarred ? AppLocalizations.of(context)!.chatUnstarMessage : AppLocalizations.of(context)!.chatStarMessage,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              subtitle: Text(
                _isStarred ? AppLocalizations.of(context)!.chatRemoveFromStarred : AppLocalizations.of(context)!.chatAddToStarred,
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
                title: Text(
                  AppLocalizations.of(context)!.chatReportMessage,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                subtitle: Text(
                  AppLocalizations.of(context)!.chatReportInappropriate,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
    final l10n = AppLocalizations.of(context)!;
    final reasons = [
      l10n.chatReportReasonHarassment,
      l10n.chatReportReasonSpam,
      l10n.chatReportReasonInappropriate,
      l10n.chatReportReasonPersonalInfo,
      l10n.chatReportReasonThreatening,
      l10n.chatReportReasonOther,
    ];

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(
          l10n.chatReportMessage,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.chatWhyReportMessage,
              style: const TextStyle(color: AppColors.textSecondary),
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
            child: Text(l10n.cancel),
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
        SnackBar(
          content: Text(AppLocalizations.of(context)!.chatMessageReported),
          backgroundColor: AppColors.richGold,
        ),
      );
    }
  }

  void _openFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.richGold),
                  );
                },
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(Icons.broken_image, color: Colors.white54, size: 64),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-screen video player widget
class _FullScreenVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const _FullScreenVideoPlayer({required this.videoUrl});

  @override
  State<_FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<_FullScreenVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _isInitialized = true);
          _controller.play();
        }
      }).catchError((e) {
        if (mounted) setState(() => _hasError = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: _hasError
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: Colors.white54, size: 48),
                  SizedBox(height: 12),
                  Text('Failed to load video',
                      style: TextStyle(color: Colors.white70)),
                ],
              )
            : !_isInitialized
                ? const CircularProgressIndicator(color: AppColors.richGold)
                : GestureDetector(
                    onTap: () {
                      setState(() {
                        _controller.value.isPlaying
                            ? _controller.pause()
                            : _controller.play();
                      });
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        ),
                        if (!_controller.value.isPlaying)
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.play_arrow,
                                color: Colors.white, size: 40),
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
