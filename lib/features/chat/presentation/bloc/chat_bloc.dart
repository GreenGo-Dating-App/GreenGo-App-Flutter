import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_conversation.dart';
import '../../domain/usecases/get_messages.dart';
import '../../domain/usecases/mark_as_read.dart';
import '../../domain/usecases/send_message.dart';
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

  StreamSubscription? _messagesSubscription;
  String? _conversationId;
  String? _matchId;
  String? _currentUserId;
  String? _otherUserId;

  ChatBloc({
    required this.getConversation,
    required this.getMessages,
    required this.sendMessage,
    required this.markAsRead,
  }) : super(const ChatInitial()) {
    on<ChatConversationLoaded>(_onConversationLoaded);
    on<ChatMessageSent>(_onMessageSent);
    on<ChatMessagesMarkedAsRead>(_onMessagesMarkedAsRead);
    on<ChatTypingIndicatorChanged>(_onTypingIndicatorChanged);
    on<ChatMessageDeleted>(_onMessageDeleted);
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

    await conversationResult.fold(
      (failure) async {
        emit(ChatError('Failed to load conversation: ${failure.toString()}'));
      },
      (conversation) async {
        _conversationId = conversation.conversationId;

        // Start listening to messages
        await _messagesSubscription?.cancel();

        _messagesSubscription = getMessages(
          GetMessagesParams(conversationId: conversation.conversationId),
        ).listen((messagesResult) {
          messagesResult.fold(
            (failure) {
              emit(ChatError('Failed to load messages: ${failure.toString()}'));
            },
            (messages) {
              final currentState = state;

              if (currentState is ChatLoaded) {
                emit(currentState.copyWith(
                  messages: messages,
                  isOtherUserTyping: conversation.isOtherUserTyping(event.currentUserId),
                ));
              } else {
                emit(ChatLoaded(
                  conversation: conversation,
                  messages: messages,
                  currentUserId: event.currentUserId,
                  otherUserId: event.otherUserId,
                  isOtherUserTyping: conversation.isOtherUserTyping(event.currentUserId),
                ));
              }

              // Auto-mark as read when messages are loaded
              if (messages.isNotEmpty) {
                add(const ChatMessagesMarkedAsRead());
              }
            },
          );
        });
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
      (_) {
        // Message will be added via stream listener
        // Revert to loaded state
        emit(ChatLoaded(
          conversation: currentState.conversation,
          messages: currentState.messages,
          currentUserId: currentState.currentUserId,
          otherUserId: currentState.otherUserId,
        ));
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
    // TODO: Implement typing indicator via repository
    // For now, this is a placeholder
  }

  Future<void> _onMessageDeleted(
    ChatMessageDeleted event,
    Emitter<ChatState> emit,
  ) async {
    // TODO: Implement message deletion via repository
    // For now, this is a placeholder
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    return super.close();
  }
}
