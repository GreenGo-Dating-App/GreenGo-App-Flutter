import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/repositories/language_games_repository.dart';
import '../bloc/language_games_bloc.dart';
import '../bloc/language_games_event.dart';
import '../bloc/language_games_state.dart';

/// In-game chat overlay that can be toggled on/off with a floating button.
///
/// When hidden: shows a small chat FAB with unread count badge.
/// When shown: slides in from the bottom-right as a compact chat panel.
///
/// Players can chat while playing — the chat doesn't block the game UI.
class GameChatOverlay extends StatefulWidget {
  final String roomId;
  final String currentUserId;
  final String currentDisplayName;

  const GameChatOverlay({
    super.key,
    required this.roomId,
    required this.currentUserId,
    required this.currentDisplayName,
  });

  @override
  State<GameChatOverlay> createState() => _GameChatOverlayState();
}

class _GameChatOverlayState extends State<GameChatOverlay>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  int _lastSeenCount = 0;
  int _unreadCount = 0;

  late AnimationController _animController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _toggleChat() {
    HapticFeedback.lightImpact();
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _animController.forward();
        _unreadCount = 0;
        _scrollToBottom();
      } else {
        _animController.reverse();
        _focusNode.unfocus();
      }
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();
    context.read<LanguageGamesBloc>().add(
          SendChatMessage(
            roomId: widget.roomId,
            userId: widget.currentUserId,
            text: text,
          ),
        );
    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageGamesBloc, LanguageGamesState>(
      builder: (context, state) {
        final messages = state is LanguageGamesInRoom
            ? (state.chatMessages ?? <GameChatMessage>[])
            : <GameChatMessage>[];

        // Track unread messages
        if (!_isOpen && messages.length > _lastSeenCount) {
          _unreadCount += messages.length - _lastSeenCount;
        }
        _lastSeenCount = messages.length;
        if (_isOpen) _unreadCount = 0;

        return Stack(
          children: [
            // Chat panel (animated)
            if (_isOpen || _animController.isAnimating)
              Positioned(
                bottom: 70,
                right: 12,
                child: AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, _slideAnimation.value * 200),
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: child,
                    ),
                  ),
                  child: _buildChatPanel(messages),
                ),
              ),

            // Toggle button
            Positioned(
              bottom: 12,
              right: 12,
              child: GestureDetector(
                onTap: _toggleChat,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _isOpen
                        ? AppColors.richGold
                        : AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _isOpen
                          ? AppColors.richGold
                          : AppColors.divider,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          _isOpen
                              ? Icons.close_rounded
                              : Icons.chat_bubble_outline_rounded,
                          color: _isOpen
                              ? AppColors.deepBlack
                              : AppColors.textSecondary,
                          size: 22,
                        ),
                      ),
                      // Unread badge
                      if (!_isOpen && _unreadCount > 0)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.errorRed,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              _unreadCount > 9 ? '9+' : '$_unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChatPanel(List<GameChatMessage> messages) {
    return Container(
      width: 280,
      height: 320,
      decoration: BoxDecoration(
        color: AppColors.backgroundCard.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.richGold.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.chat_rounded,
                  color: AppColors.richGold,
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Game Chat',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${messages.length} msgs',
                  style: TextStyle(
                    color: AppColors.textTertiary.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Messages list
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Text(
                      'No messages yet.\nSay hi! 👋',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textTertiary.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg.userId == widget.currentUserId;
                      final isSystem = msg.isSystemMessage;

                      if (isSystem) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Center(
                            child: Text(
                              msg.text,
                              style: TextStyle(
                                color: AppColors.richGold.withValues(alpha: 0.7),
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            if (!isMe)
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 4,
                                  bottom: 2,
                                ),
                                child: Text(
                                  msg.displayName,
                                  style: TextStyle(
                                    color: AppColors.richGold.withValues(alpha: 0.8),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? AppColors.richGold.withValues(alpha: 0.2)
                                    : AppColors.backgroundInput,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                msg.text,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Input
          Container(
            padding: const EdgeInsets.fromLTRB(10, 6, 6, 10),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundInput,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(
                          color: AppColors.textTertiary.withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        isDense: true,
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.richGold,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: AppColors.deepBlack,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
