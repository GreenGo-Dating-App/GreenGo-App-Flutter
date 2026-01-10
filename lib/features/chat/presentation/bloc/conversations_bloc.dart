import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_conversations.dart';
import 'conversations_event.dart';
import 'conversations_state.dart';

/// Conversations BLoC
///
/// Manages list of user's conversations
class ConversationsBloc extends Bloc<ConversationsEvent, ConversationsState> {
  final GetConversations getConversations;

  String? _userId;

  ConversationsBloc({
    required this.getConversations,
  }) : super(const ConversationsInitial()) {
    on<ConversationsLoadRequested>(_onLoadRequested);
    on<ConversationsRefreshRequested>(_onRefreshRequested);
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

  @override
  Future<void> close() {
    return super.close();
  }
}
