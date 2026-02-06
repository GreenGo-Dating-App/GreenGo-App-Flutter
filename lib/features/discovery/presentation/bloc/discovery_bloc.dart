import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/discovery_card.dart';
import '../../domain/entities/swipe_action.dart';
import '../../domain/usecases/get_discovery_stack.dart';
import '../../domain/usecases/record_swipe.dart';
import '../../../../core/services/usage_limit_service.dart';
import 'discovery_event.dart';
import 'discovery_state.dart';

/// Discovery BLoC
///
/// Manages the discovery stack and swipe actions
class DiscoveryBloc extends Bloc<DiscoveryEvent, DiscoveryState> {
  final GetDiscoveryStack getDiscoveryStack;
  final RecordSwipe recordSwipe;
  final UsageLimitService _usageLimitService;

  DiscoveryBloc({
    required this.getDiscoveryStack,
    required this.recordSwipe,
    UsageLimitService? usageLimitService,
  })  : _usageLimitService = usageLimitService ?? UsageLimitService(),
        super(const DiscoveryInitial()) {
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
      (failure) => emit(DiscoveryError(failure.message)),
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

    // Only check limits if membership rules are provided
    if (event.membershipRules != null && event.membershipTier != null) {
      // Check if it's a super like - check super like limit first
      if (event.actionType == SwipeActionType.superLike) {
        final superLikeLimit = await _usageLimitService.checkLimit(
          userId: event.userId,
          limitType: UsageLimitType.superLikes,
          rules: event.membershipRules!,
          currentTier: event.membershipTier!,
        );

        if (!superLikeLimit.isAllowed) {
          emit(DiscoverySuperLikeLimitReached(
            cards: currentState.cards,
            currentIndex: currentState.currentIndex,
            limitResult: superLikeLimit,
          ));
          return;
        }
      }

      // Check swipe limit for all swipe types (like, pass, superLike all count as swipes)
      final swipeLimit = await _usageLimitService.checkLimit(
        userId: event.userId,
        limitType: UsageLimitType.swipes,
        rules: event.membershipRules!,
        currentTier: event.membershipTier!,
      );

      if (!swipeLimit.isAllowed) {
        emit(DiscoverySwipeLimitReached(
          cards: currentState.cards,
          currentIndex: currentState.currentIndex,
          limitResult: swipeLimit,
        ));
        return;
      }
    }

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

    // Handle result - use isLeft/isRight pattern instead of fold for async handling
    if (result.isLeft()) {
      // Revert to previous state on error
      emit(currentState);
      return;
    }

    // Success case - get the swipe action
    final swipeAction = result.getOrElse(() => throw Exception('Unreachable'));

    // Record usage after successful swipe
    await _usageLimitService.recordUsage(
      userId: event.userId,
      limitType: UsageLimitType.swipes,
    );

    // Also record super like usage if applicable
    if (event.actionType == SwipeActionType.superLike) {
      await _usageLimitService.recordUsage(
        userId: event.userId,
        limitType: UsageLimitType.superLikes,
      );
    }

    // Move to next card
    final nextIndex = currentState.currentIndex + 1;

    if (swipeAction.createdMatch) {
      // Match created! Emit match state
      emit(DiscoverySwipeCompleted(
        cards: currentState.cards,
        currentIndex: nextIndex,
        createdMatch: true,
      ));

      // Wait briefly then transition to loaded state
      await Future.delayed(const Duration(milliseconds: 300));

      if (nextIndex >= currentState.cards.length) {
        emit(const DiscoveryStackEmpty());
      } else {
        emit(DiscoveryLoaded(
          cards: currentState.cards,
          currentIndex: nextIndex,
        ));
      }
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
