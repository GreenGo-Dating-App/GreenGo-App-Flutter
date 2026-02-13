import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/message.dart';
import '../../domain/usecases/get_conversation.dart';
import '../../domain/usecases/get_messages.dart';
import '../../domain/usecases/mark_as_read.dart';
import '../../domain/usecases/send_message.dart';
import '../../domain/usecases/set_typing_indicator.dart';
import '../../domain/usecases/delete_message.dart';
import '../../domain/usecases/block_user.dart';
import '../../domain/usecases/report_user.dart';
import '../../domain/usecases/star_message.dart';
import '../../domain/usecases/forward_message.dart';
import '../../domain/usecases/delete_conversation.dart';
import '../../../../core/services/usage_limit_service.dart';
import '../../../membership/domain/entities/membership.dart';
import 'chat_event.dart';
import 'chat_state.dart';

/// Chat BLoC
///
/// Manages chat conversation state and real-time messaging
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GetConversation getConversation;
  final GetMessages getMessages;
  final SendMessage sendMessage;
  final MarkAsRead markAsRead;
  final SetTypingIndicator setTypingIndicator;
  final DeleteMessage deleteMessage;
  final DeleteMessageForMe deleteMessageForMe;
  final DeleteMessageForBoth deleteMessageForBoth;
  final BlockUser blockUser;
  final UnblockUser unblockUser;
  final ReportUser reportUser;
  final StarMessage starMessage;
  final ForwardMessage forwardMessage;
  final DeleteConversationForMe deleteConversationForMe;
  final DeleteConversationForBoth deleteConversationForBoth;
  final UsageLimitService _usageLimitService;

  String? _conversationId;
  String? _matchId;
  String? _currentUserId;
  String? _otherUserId;

  ChatBloc({
    required this.getConversation,
    required this.getMessages,
    required this.sendMessage,
    required this.markAsRead,
    required this.setTypingIndicator,
    required this.deleteMessage,
    required this.deleteMessageForMe,
    required this.deleteMessageForBoth,
    required this.blockUser,
    required this.unblockUser,
    required this.reportUser,
    required this.starMessage,
    required this.forwardMessage,
    required this.deleteConversationForMe,
    required this.deleteConversationForBoth,
    UsageLimitService? usageLimitService,
  })  : _usageLimitService = usageLimitService ?? UsageLimitService(),
        super(const ChatInitial()) {
    on<ChatConversationLoaded>(_onConversationLoaded);
    on<ChatMessageSent>(_onMessageSent);
    on<ChatMessagesMarkedAsRead>(_onMessagesMarkedAsRead);
    on<ChatTypingIndicatorChanged>(_onTypingIndicatorChanged);
    on<ChatMessageDeleted>(_onMessageDeleted);
    on<ChatImageSent>(_onImageSent);
    on<ChatVideoSent>(_onVideoSent);
    on<ChatDeletedForMe>(_onDeletedForMe);
    on<ChatDeletedForBoth>(_onDeletedForBoth);
    on<ChatUserBlocked>(_onUserBlocked);
    on<ChatUserReported>(_onUserReported);
    on<ChatMessageStarred>(_onMessageStarred);
    on<ChatMessageReplied>(_onMessageReplied);
    on<ChatMessageForwarded>(_onMessageForwarded);
    on<ChatMessageDeletedForMe>(_onMessageDeletedForMe);
    on<ChatMessageDeletedForBoth>(_onMessageDeletedForBoth);
  }

  Future<void> _onConversationLoaded(
    ChatConversationLoaded event,
    Emitter<ChatState> emit,
  ) async {
    emit(const ChatLoading());

    _matchId = event.matchId;
    _currentUserId = event.currentUserId;
    _otherUserId = event.otherUserId;

    // Get or create conversation
    final conversationResult = await getConversation(event.matchId);

    final conversation = conversationResult.fold(
      (failure) {
        emit(ChatError('Failed to load conversation: ${failure.toString()}'));
        return null;
      },
      (conversation) => conversation,
    );

    if (conversation == null) return;

    _conversationId = conversation.conversationId;

    // Use emit.forEach to properly handle stream emissions
    await emit.forEach(
      getMessages(
        GetMessagesParams(
          conversationId: conversation.conversationId,
          userId: event.currentUserId,
        ),
      ),
      onData: (messagesResult) {
        return messagesResult.fold(
          (failure) => ChatError('Failed to load messages: ${failure.toString()}'),
          (messages) {
            // Auto-mark as read when messages are loaded
            if (messages.isNotEmpty) {
              add(const ChatMessagesMarkedAsRead());
            }

            return ChatLoaded(
              conversation: conversation,
              messages: messages,
              currentUserId: event.currentUserId,
              otherUserId: event.otherUserId,
              isOtherUserTyping: conversation.isOtherUserTyping(event.currentUserId),
            );
          },
        );
      },
    );
  }

  Future<void> _onMessageSent(
    ChatMessageSent event,
    Emitter<ChatState> emit,
  ) async {
    if (state is! ChatLoaded) return;

    final currentState = state as ChatLoaded;

    if (_matchId == null || _currentUserId == null || _otherUserId == null) {
      emit(const ChatError('Missing conversation details'));
      return;
    }

    // Check message limit if membership rules are provided
    if (event.membershipRules != null && event.membershipTier != null) {
      final messageLimit = await _usageLimitService.checkLimit(
        userId: _currentUserId!,
        limitType: UsageLimitType.messages,
        rules: event.membershipRules!,
        currentTier: event.membershipTier!,
      );

      if (!messageLimit.isAllowed) {
        emit(ChatMessageLimitReached(
          conversation: currentState.conversation,
          messages: currentState.messages,
          currentUserId: currentState.currentUserId,
          otherUserId: currentState.otherUserId,
          limitResult: messageLimit,
        ));
        return;
      }
    }

    // Emit sending state
    emit(ChatSending(
      conversation: currentState.conversation,
      messages: currentState.messages,
      currentUserId: currentState.currentUserId,
      otherUserId: currentState.otherUserId,
    ));

    final result = await sendMessage(
      SendMessageParams(
        matchId: _matchId!,
        senderId: _currentUserId!,
        receiverId: _otherUserId!,
        content: event.content,
        type: event.type,
      ),
    );

    result.fold(
      (failure) {
        emit(ChatLoaded(
          conversation: currentState.conversation,
          messages: currentState.messages,
          currentUserId: currentState.currentUserId,
          otherUserId: currentState.otherUserId,
        ));
        emit(ChatError('Failed to send message: ${failure.toString()}'));
      },
      (_) async {
        // Record message usage
        if (event.membershipRules != null && _currentUserId != null) {
          await _usageLimitService.recordUsage(
            userId: _currentUserId!,
            limitType: UsageLimitType.messages,
          );
        }

        // Optimistic update: add message locally so it shows immediately
        final optimisticMessage = Message(
          messageId: 'optimistic_${DateTime.now().millisecondsSinceEpoch}',
          matchId: _matchId!,
          conversationId: _conversationId ?? '',
          senderId: _currentUserId!,
          receiverId: _otherUserId!,
          content: event.content,
          type: event.type,
          sentAt: DateTime.now(),
          status: MessageStatus.sending,
        );

        final updatedMessages = [optimisticMessage, ...currentState.messages];

        emit(ChatLoaded(
          conversation: currentState.conversation,
          messages: updatedMessages,
          currentUserId: currentState.currentUserId,
          otherUserId: currentState.otherUserId,
        ));
        // Firestore stream will replace optimistic message with the real one
      },
    );
  }

  Future<void> _onMessagesMarkedAsRead(
    ChatMessagesMarkedAsRead event,
    Emitter<ChatState> emit,
  ) async {
    if (_conversationId == null || _currentUserId == null) return;

    await markAsRead(
      MarkAsReadParams(
        conversationId: _conversationId!,
        userId: _currentUserId!,
      ),
    );
  }

  Future<void> _onTypingIndicatorChanged(
    ChatTypingIndicatorChanged event,
    Emitter<ChatState> emit,
  ) async {
    if (_conversationId == null || _currentUserId == null) return;

    final result = await setTypingIndicator(
      SetTypingIndicatorParams(
        conversationId: _conversationId!,
        userId: _currentUserId!,
        isTyping: event.isTyping,
      ),
    );

    result.fold(
      (failure) {
        // Silently fail - typing indicator is not critical
      },
      (_) {
        // Success - typing indicator updated
      },
    );
  }

  Future<void> _onMessageDeleted(
    ChatMessageDeleted event,
    Emitter<ChatState> emit,
  ) async {
    if (_conversationId == null) return;

    final result = await deleteMessage(
      DeleteMessageParams(
        messageId: event.messageId,
        conversationId: _conversationId!,
      ),
    );

    result.fold(
      (failure) {
        emit(ChatError('Failed to delete message: ${failure.message}'));
      },
      (_) {
        // Message will be removed via stream listener
        emit(const ChatMessageActionSuccess('Message deleted'));
      },
    );
  }

  Future<void> _onMessageDeletedForMe(
    ChatMessageDeletedForMe event,
    Emitter<ChatState> emit,
  ) async {
    if (_conversationId == null || _currentUserId == null) return;

    final result = await deleteMessageForMe(
      DeleteMessageForMeParams(
        messageId: event.messageId,
        conversationId: _conversationId!,
        userId: _currentUserId!,
      ),
    );

    result.fold(
      (failure) {
        emit(ChatError('Failed to delete message: ${failure.message}'));
      },
      (_) {
        emit(const ChatMessageActionSuccess('Message deleted for you'));
      },
    );
  }

  Future<void> _onMessageDeletedForBoth(
    ChatMessageDeletedForBoth event,
    Emitter<ChatState> emit,
  ) async {
    if (_conversationId == null || _currentUserId == null) return;

    final result = await deleteMessageForBoth(
      DeleteMessageForBothParams(
        messageId: event.messageId,
        conversationId: _conversationId!,
        userId: _currentUserId!,
      ),
    );

    result.fold(
      (failure) {
        emit(ChatError('Failed to delete message: ${failure.message}'));
      },
      (_) {
        emit(const ChatMessageActionSuccess('Message deleted for everyone'));
      },
    );
  }

  Future<void> _onImageSent(
    ChatImageSent event,
    Emitter<ChatState> emit,
  ) async {
    if (state is! ChatLoaded) return;

    final currentState = state as ChatLoaded;

    // Image is sent as a regular message with image type
    // The upload happens in the UI layer, here we just send the URL
    if (_matchId == null || _currentUserId == null || _otherUserId == null) return;

    // Check if media sending is allowed for this tier
    if (event.membershipRules != null && event.membershipTier != null) {
      if (!event.membershipRules!.canSendMedia) {
        // Find the minimum tier that allows media sending
        MembershipTier requiredTier = MembershipTier.gold; // Default to gold
        for (final tier in MembershipTier.values) {
          final rules = MembershipRules.getDefaultsForTier(tier);
          if (rules.canSendMedia) {
            requiredTier = tier;
            break;
          }
        }

        emit(ChatMediaNotAllowed(
          conversation: currentState.conversation,
          messages: currentState.messages,
          currentUserId: currentState.currentUserId,
          otherUserId: currentState.otherUserId,
          currentTier: event.membershipTier!,
          requiredTier: requiredTier,
        ));
        return;
      }
    }

    await sendMessage(
      SendMessageParams(
        matchId: _matchId!,
        senderId: _currentUserId!,
        receiverId: _otherUserId!,
        content: event.imagePath,
        type: MessageType.image,
      ),
    );
  }

  Future<void> _onVideoSent(
    ChatVideoSent event,
    Emitter<ChatState> emit,
  ) async {
    if (state is! ChatLoaded) return;

    final currentState = state as ChatLoaded;

    // Video is sent as a regular message with video type
    if (_matchId == null || _currentUserId == null || _otherUserId == null) return;

    // Check if media sending is allowed for this tier
    if (event.membershipRules != null && event.membershipTier != null) {
      if (!event.membershipRules!.canSendMedia) {
        // Find the minimum tier that allows media sending
        MembershipTier requiredTier = MembershipTier.gold; // Default to gold
        for (final tier in MembershipTier.values) {
          final rules = MembershipRules.getDefaultsForTier(tier);
          if (rules.canSendMedia) {
            requiredTier = tier;
            break;
          }
        }

        emit(ChatMediaNotAllowed(
          conversation: currentState.conversation,
          messages: currentState.messages,
          currentUserId: currentState.currentUserId,
          otherUserId: currentState.otherUserId,
          currentTier: event.membershipTier!,
          requiredTier: requiredTier,
        ));
        return;
      }
    }

    await sendMessage(
      SendMessageParams(
        matchId: _matchId!,
        senderId: _currentUserId!,
        receiverId: _otherUserId!,
        content: event.videoPath,
        type: MessageType.video,
      ),
    );
  }

  Future<void> _onDeletedForMe(
    ChatDeletedForMe event,
    Emitter<ChatState> emit,
  ) async {
    if (_conversationId == null || _currentUserId == null) return;

    final result = await deleteConversationForMe(
      DeleteConversationForMeParams(
        conversationId: _conversationId!,
        userId: _currentUserId!,
      ),
    );

    result.fold(
      (failure) {
        emit(ChatError('Failed to delete conversation: ${failure.message}'));
      },
      (_) {
        emit(const ChatConversationDeleted());
      },
    );
  }

  Future<void> _onDeletedForBoth(
    ChatDeletedForBoth event,
    Emitter<ChatState> emit,
  ) async {
    if (_conversationId == null || _currentUserId == null) return;

    final result = await deleteConversationForBoth(
      DeleteConversationForBothParams(
        conversationId: _conversationId!,
        userId: _currentUserId!,
      ),
    );

    result.fold(
      (failure) {
        emit(ChatError('Failed to delete conversation: ${failure.message}'));
      },
      (_) {
        emit(const ChatConversationDeleted());
      },
    );
  }

  Future<void> _onUserBlocked(
    ChatUserBlocked event,
    Emitter<ChatState> emit,
  ) async {
    if (_currentUserId == null) return;

    final result = await blockUser(
      BlockUserParams(
        blockerId: _currentUserId!,
        blockedUserId: event.userId,
        reason: event.reason ?? 'Blocked from chat',
      ),
    );

    result.fold(
      (failure) {
        emit(ChatError('Failed to block user: ${failure.message}'));
      },
      (_) {
        emit(ChatUserBlockedSuccess(event.userId));
      },
    );
  }

  Future<void> _onUserReported(
    ChatUserReported event,
    Emitter<ChatState> emit,
  ) async {
    if (_currentUserId == null) return;

    final result = await reportUser(
      ReportUserParams(
        reporterId: _currentUserId!,
        reportedUserId: event.userId,
        reason: event.reason,
        conversationId: _conversationId,
        messageId: event.messageId,
        additionalDetails: event.additionalDetails,
      ),
    );

    result.fold(
      (failure) {
        emit(ChatError('Failed to report user: ${failure.message}'));
      },
      (_) {
        emit(const ChatUserReportedSuccess());
      },
    );
  }

  Future<void> _onMessageStarred(
    ChatMessageStarred event,
    Emitter<ChatState> emit,
  ) async {
    if (_conversationId == null || _currentUserId == null) return;

    final result = await starMessage(
      StarMessageParams(
        messageId: event.messageId,
        conversationId: _conversationId!,
        userId: _currentUserId!,
        isStarred: event.isStarred,
      ),
    );

    result.fold(
      (failure) {
        emit(ChatError('Failed to ${event.isStarred ? 'star' : 'unstar'} message: ${failure.message}'));
      },
      (_) {
        emit(ChatMessageActionSuccess(
          event.isStarred ? 'Message starred' : 'Message unstarred',
        ));
      },
    );
  }

  Future<void> _onMessageReplied(
    ChatMessageReplied event,
    Emitter<ChatState> emit,
  ) async {
    if (state is! ChatLoaded) return;

    final currentState = state as ChatLoaded;

    if (_matchId == null || _currentUserId == null || _otherUserId == null) {
      emit(const ChatError('Missing conversation details'));
      return;
    }

    // Emit sending state
    emit(ChatSending(
      conversation: currentState.conversation,
      messages: currentState.messages,
      currentUserId: currentState.currentUserId,
      otherUserId: currentState.otherUserId,
    ));

    // Find the original message to get its content for the reply preview
    final originalMessage = currentState.messages.firstWhere(
      (m) => m.messageId == event.replyToMessageId,
      orElse: () => currentState.messages.first,
    );

    final result = await sendMessage(
      SendMessageParams(
        matchId: _matchId!,
        senderId: _currentUserId!,
        receiverId: _otherUserId!,
        content: event.content,
        type: event.type,
        metadata: {
          'replyToMessageId': event.replyToMessageId,
          'replyContent': originalMessage.content,
        },
      ),
    );

    result.fold(
      (failure) {
        emit(ChatLoaded(
          conversation: currentState.conversation,
          messages: currentState.messages,
          currentUserId: currentState.currentUserId,
          otherUserId: currentState.otherUserId,
        ));
        emit(ChatError('Failed to send reply: ${failure.toString()}'));
      },
      (_) {
        emit(ChatLoaded(
          conversation: currentState.conversation,
          messages: currentState.messages,
          currentUserId: currentState.currentUserId,
          otherUserId: currentState.otherUserId,
        ));
      },
    );
  }

  Future<void> _onMessageForwarded(
    ChatMessageForwarded event,
    Emitter<ChatState> emit,
  ) async {
    if (_conversationId == null || _currentUserId == null) return;

    final result = await forwardMessage(
      ForwardMessageParams(
        messageId: event.messageId,
        fromConversationId: _conversationId!,
        senderId: _currentUserId!,
        toMatchIds: event.toMatchIds,
      ),
    );

    result.fold(
      (failure) {
        emit(ChatError('Failed to forward message: ${failure.message}'));
      },
      (_) {
        emit(ChatMessageActionSuccess(
          'Message forwarded to ${event.toMatchIds.length} conversation${event.toMatchIds.length > 1 ? 's' : ''}',
        ));
      },
    );
  }

  @override
  Future<void> close() {
    return super.close();
  }
}
