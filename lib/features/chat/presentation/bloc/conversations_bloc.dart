import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_conversations.dart';
import 'conversations_event.dart';
import 'conversations_state.dart';

/// Conversations BLoC
///
/// Manages list of user's conversations
class ConversationsBloc extends Bloc<ConversationsEvent, ConversationsState> {
  final GetConversations getConversations;

  StreamSubscription? _conversationsSubscription;
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

    // Cancel existing subscription
    await _conversationsSubscription?.cancel();

    // Start listening to conversations
    _conversationsSubscription = getConversations(event.userId).listen(
      (conversationsResult) {
        conversationsResult.fold(
          (failure) {
            emit(ConversationsError(
                'Failed to load conversations: ${failure.toString()}'));
          },
          (conversations) {
            if (conversations.isEmpty) {
              emit(const ConversationsEmpty());
            } else {
              emit(ConversationsLoaded(conversations: conversations));
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
    _conversationsSubscription?.cancel();
    return super.close();
  }
}
