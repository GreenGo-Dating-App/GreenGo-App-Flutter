import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_conversations.dart';
import '../../domain/usecases/delete_conversation.dart';
import 'conversations_event.dart';
import 'conversations_state.dart';

/// Conversations BLoC
///
/// Manages list of user's conversations
class ConversationsBloc extends Bloc<ConversationsEvent, ConversationsState> {
  final GetConversations getConversations;
  final DeleteConversationForMe deleteConversationForMe;
  final DeleteConversationForBoth deleteConversationForBoth;

  String? _userId;

  ConversationsBloc({
    required this.getConversations,
    required this.deleteConversationForMe,
    required this.deleteConversationForBoth,
  }) : super(const ConversationsInitial()) {
    on<ConversationsLoadRequested>(_onLoadRequested);
    on<ConversationsRefreshRequested>(_onRefreshRequested);
    on<ConversationDeleteForMeRequested>(_onDeleteForMe);
    on<ConversationDeleteForBothRequested>(_onDeleteForBoth);
  }

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

  Future<void> _onDeleteForMe(
    ConversationDeleteForMeRequested event,
    Emitter<ConversationsState> emit,
  ) async {
    final result = await deleteConversationForMe(
      DeleteConversationForMeParams(
        conversationId: event.conversationId,
        userId: event.userId,
      ),
    );
    result.fold(
      (failure) => emit(ConversationsError('Failed to delete: ${failure.toString()}')),
      (_) {
        // Refresh conversations after deletion
        if (_userId != null) {
          add(ConversationsLoadRequested(_userId!));
        }
      },
    );
  }

  Future<void> _onDeleteForBoth(
    ConversationDeleteForBothRequested event,
    Emitter<ConversationsState> emit,
  ) async {
    final result = await deleteConversationForBoth(
      DeleteConversationForBothParams(
        conversationId: event.conversationId,
        userId: event.userId,
      ),
    );
    result.fold(
      (failure) => emit(ConversationsError('Failed to delete: ${failure.toString()}')),
      (_) {
        // Refresh conversations after deletion
        if (_userId != null) {
          add(ConversationsLoadRequested(_userId!));
        }
      },
    );
  }

  @override
  Future<void> close() {
    return super.close();
  }
}
