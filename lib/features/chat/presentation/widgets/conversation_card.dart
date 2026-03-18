import 'package:flutter/material.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../domain/entities/conversation.dart';

/// Conversation Card Widget
///
/// Displays a conversation in the list
class ConversationCard extends StatefulWidget {
  final Conversation conversation;
  final Profile? otherUserProfile;
  final String currentUserId;
  final String? chatLanguage;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onAcceptSuperLike;
  final VoidCallback? onRejectSuperLike;

  const ConversationCard({
    super.key,
    required this.conversation,
    required this.otherUserProfile,
    required this.currentUserId,
    this.chatLanguage,
    this.onTap,
    this.onLongPress,
    this.onToggleFavorite,
    this.onAcceptSuperLike,
    this.onRejectSuperLike,
  });

  static String _flagForLanguage(String? langCode) {
    if (langCode == null || langCode.isEmpty) return '';
    final code = langCode.toLowerCase().replaceAll('-', '_');
    const flags = {
      'en': '\u{1F1EC}\u{1F1E7}',
      'de': '\u{1F1E9}\u{1F1EA}',
      'es': '\u{1F1EA}\u{1F1F8}',
      'fr': '\u{1F1EB}\u{1F1F7}',
      'it': '\u{1F1EE}\u{1F1F9}',
      'pt': '\u{1F1F5}\u{1F1F9}',
      'pt_br': '\u{1F1E7}\u{1F1F7}',
      'ja': '\u{1F1EF}\u{1F1F5}',
      'ko': '\u{1F1F0}\u{1F1F7}',
      'zh': '\u{1F1E8}\u{1F1F3}',
      'ar': '\u{1F1F8}\u{1F1E6}',
      'hi': '\u{1F1EE}\u{1F1F3}',
      'tr': '\u{1F1F9}\u{1F1F7}',
      'ru': '\u{1F1F7}\u{1F1FA}',
    };
    return flags[code] ?? '';
  }

  @override
  State<ConversationCard> createState() => _ConversationCardState();
}

class _ConversationCardState extends State<ConversationCard>
    with SingleTickerProviderStateMixin {
  AnimationController? _shimmerController;

  bool get _isUnreadForCurrentUser =>
      widget.conversation.hasUnreadMessages &&
      widget.conversation.lastMessage != null &&
      !widget.conversation.lastMessage!.isSentBy(widget.currentUserId);

  @override
  void initState() {
    super.initState();
    if (_isUnreadForCurrentUser) {
      // Small delay so the list is fully visible before the shimmer plays
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _initShimmer();
      });
    }
  }

  @override
  void didUpdateWidget(covariant ConversationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger shimmer when conversation becomes unread or gets a new message
    if (_isUnreadForCurrentUser &&
        (!oldWidget.conversation.hasUnreadMessages ||
         widget.conversation.unreadCount > oldWidget.conversation.unreadCount)) {
      if (mounted) _initShimmer();
    }
  }

  void _initShimmer() {
    _shimmerController?.dispose();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    setState(() {});
    _shimmerController!.forward();
  }

  @override
  void dispose() {
    _shimmerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasUnread = _isUnreadForCurrentUser;
    final isTyping = widget.conversation.isOtherUserTyping(widget.currentUserId);
    final userLanguageFlags = _buildUserLanguageFlags();

    final content = Container(
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
          _buildAvatar(hasUnread),
          const SizedBox(width: 12),
          _buildInfo(l10n, hasUnread, isTyping, userLanguageFlags),
          _buildTrailing(l10n, hasUnread),
        ],
      ),
    );

    return InkWell(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: hasUnread && _shimmerController != null
          ? Stack(
              children: [
                content,
                // Gold shimmer sweep overlay
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _shimmerController!,
                      builder: (context, _) {
                        final pos = Tween<double>(begin: -0.3, end: 1.3)
                            .chain(CurveTween(curve: Curves.easeInOut))
                            .evaluate(_shimmerController!);
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: const [
                                Colors.transparent,
                                Color(0x30D4AF37),
                                Color(0x55FFD700),
                                Color(0x30D4AF37),
                                Colors.transparent,
                              ],
                              stops: [
                                (pos - 0.2).clamp(0.0, 1.0),
                                (pos - 0.1).clamp(0.0, 1.0),
                                pos.clamp(0.0, 1.0),
                                (pos + 0.1).clamp(0.0, 1.0),
                                (pos + 0.2).clamp(0.0, 1.0),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            )
          : content,
    );
  }

  Widget _buildAvatar(bool hasUnread) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: AppColors.backgroundCard,
          backgroundImage: widget.otherUserProfile?.photoUrls.isNotEmpty ?? false
              ? NetworkImage(widget.otherUserProfile!.photoUrls.first)
              : null,
          child: widget.otherUserProfile?.photoUrls.isEmpty ?? true
              ? const Icon(Icons.person, size: 30, color: AppColors.textTertiary)
              : null,
        ),
        if (widget.otherUserProfile?.isOnline ?? false)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.successGreen,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.backgroundDark, width: 2),
              ),
            ),
          ),
        if (widget.conversation.isSearchConversation)
          Positioned(
            left: -2,
            bottom: -2,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.backgroundDark,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.richGold.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: const Icon(Icons.search, size: 10, color: AppColors.richGold),
            ),
          ),
        if (hasUnread && widget.conversation.unreadCount > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              decoration: BoxDecoration(
                color: AppColors.richGold,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.backgroundDark, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.richGold.withOpacity(0.3),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.conversation.unreadCount > 99
                      ? '99+'
                      : '${widget.conversation.unreadCount}',
                  style: const TextStyle(
                    color: AppColors.deepBlack,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfo(AppLocalizations l10n, bool hasUnread, bool isTyping, String flags) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  widget.otherUserProfile?.displayName ?? l10n.chatUnknown,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: hasUnread ? FontWeight.bold : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (flags.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(flags, style: const TextStyle(fontSize: 12)),
              ],
            ],
          ),
          const SizedBox(height: 4),
          if (isTyping)
            Row(
              children: [
                Text(
                  l10n.chatTyping,
                  style: const TextStyle(
                    color: AppColors.richGold,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 4),
                const SizedBox(
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
              widget.conversation.lastMessagePreview,
              style: TextStyle(
                color: hasUnread ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: 14,
                fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Widget _buildTrailing(AppLocalizations l10n, bool hasUnread) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.chatLanguage != null && widget.chatLanguage!.isNotEmpty) ...[
          Text(
            ConversationCard._flagForLanguage(widget.chatLanguage),
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 2),
        ],
        Text(
          widget.conversation.timeSinceLastMessage,
          style: TextStyle(
            color: hasUnread ? AppColors.richGold : AppColors.textTertiary,
            fontSize: 12,
            fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 4),
        if (widget.onToggleFavorite != null)
          GestureDetector(
            onTap: widget.onToggleFavorite,
            child: Icon(
              widget.conversation.isFavoritedBy(widget.currentUserId)
                  ? Icons.star
                  : Icons.star_border,
              color: widget.conversation.isFavoritedBy(widget.currentUserId)
                  ? AppColors.richGold
                  : AppColors.textTertiary,
              size: 22,
            ),
          ),
        if (widget.conversation.isPendingSuperLikeFor(widget.currentUserId)) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.onAcceptSuperLike != null)
                GestureDetector(
                  onTap: widget.onAcceptSuperLike,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.successGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      l10n.priorityConnectAccept,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              if (widget.onRejectSuperLike != null)
                GestureDetector(
                  onTap: widget.onRejectSuperLike,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.errorRed,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      l10n.priorityConnectReject,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  String _buildUserLanguageFlags() {
    final profile = widget.otherUserProfile;
    if (profile == null) return '';

    final flags = <String>[];
    if (profile.nativeLanguage != null && profile.nativeLanguage!.isNotEmpty) {
      final f = ConversationCard._flagForLanguage(profile.nativeLanguage);
      if (f.isNotEmpty) flags.add(f);
    }
    for (final lang in profile.languages) {
      final f = ConversationCard._flagForLanguage(lang);
      if (f.isNotEmpty && !flags.contains(f)) {
        flags.add(f);
      }
    }
    return flags.join('');
  }
}
