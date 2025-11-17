import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../profile/domain/entities/profile.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../widgets/message_bubble.dart';

/// Chat Screen
///
/// Individual chat conversation with a match
class ChatScreen extends StatefulWidget {
  final String matchId;
  final String currentUserId;
  final String otherUserId;
  final Profile otherUserProfile;

  const ChatScreen({
    super.key,
    required this.matchId,
    required this.currentUserId,
    required this.otherUserId,
    required this.otherUserProfile,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(BuildContext context) {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    context.read<ChatBloc>().add(ChatMessageSent(content: content));
    _messageController.clear();

    // Scroll to bottom after sending
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<ChatBloc>()
        ..add(ChatConversationLoaded(
          matchId: widget.matchId,
          currentUserId: widget.currentUserId,
          otherUserId: widget.otherUserId,
        )),
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            // Messages list
            Expanded(
              child: BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  if (state is ChatLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.richGold,
                      ),
                    );
                  }

                  if (state is ChatError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: AppColors.errorRed,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            state.message,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is ChatLoaded || state is ChatSending) {
                    final messages = state is ChatLoaded
                        ? state.messages
                        : (state as ChatSending).messages;

                    final isOtherUserTyping = state is ChatLoaded
                        ? state.isOtherUserTyping
                        : false;

                    if (messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: AppColors.backgroundCard,
                              backgroundImage: widget
                                      .otherUserProfile.photoUrls.isNotEmpty
                                  ? NetworkImage(
                                      widget.otherUserProfile.photoUrls.first)
                                  : null,
                              child: widget
                                      .otherUserProfile.photoUrls.isEmpty
                                  ? const Icon(
                                      Icons.person,
                                      size: 50,
                                      color: AppColors.textTertiary,
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Say hi to ${widget.otherUserProfile.displayName}!',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                'Send a message to start the conversation',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: messages.length + (isOtherUserTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        // Typing indicator
                        if (index == 0 && isOtherUserTyping) {
                          return _buildTypingIndicator();
                        }

                        final messageIndex =
                            isOtherUserTyping ? index - 1 : index;
                        final message = messages[messageIndex];

                        return MessageBubble(
                          message: message,
                          isCurrentUser:
                              message.senderId == widget.currentUserId,
                        );
                      },
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),

            // Input field
            _buildInputField(context),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.backgroundCard,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.backgroundDark,
            backgroundImage:
                widget.otherUserProfile.photoUrls.isNotEmpty
                    ? NetworkImage(widget.otherUserProfile.photoUrls.first)
                    : null,
            child: widget.otherUserProfile.photoUrls.isEmpty
                ? const Icon(
                    Icons.person,
                    size: 20,
                    color: AppColors.textTertiary,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.otherUserProfile.displayName,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  if (state is ChatLoaded && state.isOtherUserTyping) {
                    return const Text(
                      'typing...',
                      style: TextStyle(
                        color: AppColors.richGold,
                        fontSize: 12,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
          onPressed: () {
            // TODO: Show options menu
          },
        ),
      ],
    );
  }

  Widget _buildInputField(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.backgroundCard,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Attach button (optional)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              color: AppColors.textSecondary,
              onPressed: () {
                // TODO: Show attach options (photo, gif, etc.)
              },
            ),

            // Text input
            Expanded(
              child: TextField(
                controller: _messageController,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: const TextStyle(
                    color: AppColors.textTertiary,
                  ),
                  filled: true,
                  fillColor: AppColors.backgroundDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),

            const SizedBox(width: 8),

            // Send button
            BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                final isSending = state is ChatSending;

                return CircleAvatar(
                  backgroundColor: AppColors.richGold,
                  radius: 24,
                  child: isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.deepBlack,
                            strokeWidth: 2,
                          ),
                        )
                      : IconButton(
                          icon: const Icon(
                            Icons.send,
                            color: AppColors.deepBlack,
                            size: 20,
                          ),
                          onPressed: () => _sendMessage(context),
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTypingDot(0),
          const SizedBox(width: 4),
          _buildTypingDot(1),
          const SizedBox(width: 4),
          _buildTypingDot(2),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 100)),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: (value * 2) % 1.0,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.textTertiary,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
      onEnd: () {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }
}
