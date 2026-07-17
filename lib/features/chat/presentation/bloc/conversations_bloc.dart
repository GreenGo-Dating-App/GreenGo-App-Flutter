import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/chat_repository.dart';
import '../../domain/usecases/delete_conversation.dart';
import '../../domain/usecases/get_conversations.dart';
import 'conversations_event.dart';
import 'conversations_state.dart';

/// Conversations BLoC
///
/// Manages list of user's conversations
class ConversationsBloc extends Bloc<ConversationsEvent, ConversationsState> {

  ConversationsBloc({
    required this.getConversations,
    required this.deleteConversationForMe,
    required this.deleteConversationForBoth,
    required this.chatRepository,
  }) : super(const ConversationsInitial()) {
    on<ConversationsLoadRequested>(_onLoadRequested);
    on<ConversationsRefreshRequested>(_onRefreshRequested);
    on<ConversationDeleteForMeRequested>(_onDeleteForMe);
    on<ConversationDeleteForBothRequested>(_onDeleteForBoth);
    on<ConversationToggleFavoriteRequested>(_onToggleFavorite);
    on<ConversationAcceptSuperLikeRequested>(_onAcceptSuperLike);
    on<ConversationRejectSuperLikeRequested>(_onRejectSuperLike);
  }
  final GetConversations getConversations;
  final DeleteConversationForMe deleteConversationForMe;
  final DeleteConversationForBoth deleteConversationForBoth;
  final ChatRepository chatRepository;

  String? _userId;

  Future<void> _onLoadRequested(
    ConversationsLoadRequested event,
    Emitter<ConversationsState> emit,
  ) async {
    emit(const ConversationsLoading());

    _userId = event.userId;

    // Use emit.forEach to properly handle stream emissions within bloc
    await emit.forEach(
      getConversations(event.userId),
      onData: (conversationsResult) {
        return conversationsResult.fold(
          (failure) => ConversationsError(
              'Failed to load conversations: ${failure.toString()}'),
          (conversations) {
            if (conversations.isEmpty) {
              return const ConversationsEmpty();
            } else {
              return ConversationsLoaded(conversations: conversations);
            }
          },
        );
      },
    );
  }

  Future<void> _onRefreshRequested(
    ConversationsRefreshRequested event,
    Emitter<ConversationsState> emit,
  ) async {
    if (_userId != null) {
      add(ConversationsLoadRequested(_userId!));
    }
  }

  /// Optimistically drop [conversationId] from the currently-shown list so the
  /// row disappears IMMEDIATELY (no waiting on the round-trip, no full-screen
  /// error/loading swap). The active conversations stream reconciles afterwards.
  void _removeConversationOptimistically(
    String conversationId,
    Emitter<ConversationsState> emit,
  ) {
    final cur = state;
    if (cur is! ConversationsLoaded) return;
    final remaining = cur.conversations
        .where((c) => c.conversationId != conversationId)
        .toList();
    emit(remaining.isEmpty
        ? const ConversationsEmpty()
        : ConversationsLoaded(conversations: remaining));
  }

  Future<void> _onDeleteForMe(
    ConversationDeleteForMeRequested event,
    Emitter<ConversationsState> emit,
  ) async {
    _removeConversationOptimistically(event.conversationId, emit);
    final result = await deleteConversationForMe(
      DeleteConversationForMeParams(
        conversationId: event.conversationId,
        userId: event.userId,
      ),
    );
    // On failure, reload to restore the row; on success the stream reconciles —
    // no reload (which would blank the list with a Loading state).
    result.fold(
      (_) {
        if (_userId != null) add(ConversationsLoadRequested(_userId!));
      },
      (_) {},
    );
  }

  Future<void> _onDeleteForBoth(
    ConversationDeleteForBothRequested event,
    Emitter<ConversationsState> emit,
  ) async {
    _removeConversationOptimistically(event.conversationId, emit);
    final result = await deleteConversationForBoth(
      DeleteConversationForBothParams(
        conversationId: event.conversationId,
        userId: event.userId,
      ),
    );
    result.fold(
      (_) {
        if (_userId != null) add(ConversationsLoadRequested(_userId!));
      },
      (_) {},
    );
  }

  Future<void> _onToggleFavorite(
    ConversationToggleFavoriteRequested event,
    Emitter<ConversationsState> emit,
  ) async {
    await chatRepository.toggleFavorite(
      conversationId: event.conversationId,
      userId: event.userId,
      isFavorite: event.isFavorite,
    );
  }

  Future<void> _onAcceptSuperLike(
    ConversationAcceptSuperLikeRequested event,
    Emitter<ConversationsState> emit,
  ) async {
    await chatRepository.acceptSuperLike(
      conversationId: event.conversationId,
    );
  }

  Future<void> _onRejectSuperLike(
    ConversationRejectSuperLikeRequested event,
    Emitter<ConversationsState> emit,
  ) async {
    await chatRepository.rejectSuperLike(
      conversationId: event.conversationId,
      userId: event.userId,
    );
    if (_userId != null) {
      add(ConversationsLoadRequested(_userId!));
    }
  }

}
