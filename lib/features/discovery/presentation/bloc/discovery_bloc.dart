import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/discovery_card.dart';
import '../../domain/usecases/get_discovery_stack.dart';
import '../../domain/usecases/record_swipe.dart';
import 'discovery_event.dart';
import 'discovery_state.dart';

/// Discovery BLoC
///
/// Manages the discovery stack and swipe actions
class DiscoveryBloc extends Bloc<DiscoveryEvent, DiscoveryState> {
  final GetDiscoveryStack getDiscoveryStack;
  final RecordSwipe recordSwipe;

  DiscoveryBloc({
    required this.getDiscoveryStack,
    required this.recordSwipe,
  }) : super(const DiscoveryInitial()) {
    on<DiscoveryStackLoadRequested>(_onLoadStack);
    on<DiscoverySwipeRecorded>(_onSwipeRecorded);
    on<DiscoveryStackRefreshRequested>(_onRefreshStack);
    on<DiscoveryMoreCandidatesRequested>(_onLoadMore);
  }

  Future<void> _onLoadStack(
    DiscoveryStackLoadRequested event,
    Emitter<DiscoveryState> emit,
  ) async {
    emit(const DiscoveryLoading());

    final result = await getDiscoveryStack(
      GetDiscoveryStackParams(
        userId: event.userId,
        preferences: event.preferences,
        limit: event.limit,
      ),
    );

    result.fold(
      (failure) => emit(const DiscoveryError('Failed to load discovery stack')),
      (candidates) {
        if (candidates.isEmpty) {
          emit(const DiscoveryStackEmpty());
        } else {
          final cards = candidates
              .asMap()
              .entries
              .map((entry) => DiscoveryCard(
                    candidate: entry.value,
                    position: entry.key,
                    isFocused: entry.key == 0,
                  ))
              .toList();

          emit(DiscoveryLoaded(cards: cards, currentIndex: 0));
        }
      },
    );
  }

  Future<void> _onSwipeRecorded(
    DiscoverySwipeRecorded event,
    Emitter<DiscoveryState> emit,
  ) async {
    if (state is! DiscoveryLoaded) return;

    final currentState = state as DiscoveryLoaded;

    // Emit swiping state
    emit(DiscoverySwiping(
      cards: currentState.cards,
      currentIndex: currentState.currentIndex,
    ));

    // Record swipe
    final result = await recordSwipe(
      RecordSwipeParams(
        userId: event.userId,
        targetUserId: event.targetUserId,
        actionType: event.actionType,
      ),
    );

    result.fold(
      (failure) {
        // Revert to previous state on error
        emit(currentState);
      },
      (swipeAction) {
        // Move to next card
        final nextIndex = currentState.currentIndex + 1;

        if (swipeAction.createdMatch) {
          // Match created! Emit match state
          // Note: In a real implementation, we'd fetch the match details here
          emit(DiscoverySwipeCompleted(
            cards: currentState.cards,
            currentIndex: nextIndex,
            createdMatch: true,
          ));

          // Then transition to loaded state after showing match notification
          Future.delayed(const Duration(milliseconds: 500), () {
            if (nextIndex >= currentState.cards.length) {
              emit(const DiscoveryStackEmpty());
            } else {
              emit(DiscoveryLoaded(
                cards: currentState.cards,
                currentIndex: nextIndex,
              ));
            }
          });
        } else {
          // No match, just move to next card
          if (nextIndex >= currentState.cards.length) {
            emit(const DiscoveryStackEmpty());
          } else {
            emit(DiscoveryLoaded(
              cards: currentState.cards,
              currentIndex: nextIndex,
            ));
          }
        }
      },
    );
  }

  Future<void> _onRefreshStack(
    DiscoveryStackRefreshRequested event,
    Emitter<DiscoveryState> emit,
  ) async {
    // Reload the stack
    add(DiscoveryStackLoadRequested(
      userId: event.userId,
      preferences: event.preferences,
    ));
  }

  Future<void> _onLoadMore(
    DiscoveryMoreCandidatesRequested event,
    Emitter<DiscoveryState> emit,
  ) async {
    if (state is! DiscoveryLoaded) return;

    final currentState = state as DiscoveryLoaded;

    // Get more candidates
    final result = await getDiscoveryStack(
      GetDiscoveryStackParams(
        userId: event.userId,
        preferences: event.preferences,
        limit: 10,
      ),
    );

    result.fold(
      (failure) {
        // Keep current state on error
      },
      (candidates) {
        if (candidates.isNotEmpty) {
          final newCards = candidates
              .asMap()
              .entries
              .map((entry) => DiscoveryCard(
                    candidate: entry.value,
                    position: currentState.cards.length + entry.key,
                  ))
              .toList();

          emit(DiscoveryLoaded(
            cards: [...currentState.cards, ...newCards],
            currentIndex: currentState.currentIndex,
          ));
        }
      },
    );
  }
}
