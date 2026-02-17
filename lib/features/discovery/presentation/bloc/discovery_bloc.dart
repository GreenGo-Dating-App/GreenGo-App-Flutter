import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/discovery_card.dart';
import '../../domain/entities/match_preferences.dart';
import '../../domain/entities/swipe_action.dart';
import '../../domain/usecases/get_discovery_stack.dart';
import '../../domain/usecases/record_swipe.dart';
import '../../domain/usecases/undo_swipe.dart';
import '../../../../core/services/usage_limit_service.dart';
import '../../../membership/domain/entities/membership.dart';
import '../../../coins/domain/entities/coin_transaction.dart';
import '../../../coins/domain/repositories/coin_repository.dart';
import '../../data/datasources/discovery_remote_datasource.dart';
import 'discovery_event.dart';
import 'discovery_state.dart';

/// Discovery BLoC
///
/// Manages the discovery stack and swipe actions with a 20-profile queue
/// and automatic pre-fetching when the queue runs low
class DiscoveryBloc extends Bloc<DiscoveryEvent, DiscoveryState> {
  final GetDiscoveryStack getDiscoveryStack;
  final RecordSwipe recordSwipe;
  final UndoSwipe undoSwipe;
  final UsageLimitService _usageLimitService;
  final CoinRepository? coinRepository;
  final DiscoveryRemoteDataSource? discoveryDataSource;

  // Queue management
  static const int queueSize = 20;
  static const int prefetchThreshold = 10;
  bool _isPrefetching = false;
  String? _currentUserId;
  MatchPreferences? _currentPreferences;

  // Rewind tracking (single-level undo)
  DiscoveryCard? _lastSwipedCard;
  SwipeActionType? _lastSwipeType;
  bool _lastSwipeCreatedMatch = false;

  DiscoveryBloc({
    required this.getDiscoveryStack,
    required this.recordSwipe,
    required this.undoSwipe,
    UsageLimitService? usageLimitService,
    this.coinRepository,
    this.discoveryDataSource,
  })  : _usageLimitService = usageLimitService ?? UsageLimitService(),
        super(const DiscoveryInitial()) {
    on<DiscoveryStackLoadRequested>(_onLoadStack);
    on<DiscoverySwipeRecorded>(_onSwipeRecorded);
    on<DiscoveryRewindRequested>(_onRewind);
    on<DiscoveryStackRefreshRequested>(_onRefreshStack);
    on<DiscoveryMoreCandidatesRequested>(_onLoadMore);
    on<DiscoveryPrefetchRequested>(_onPrefetch);
    on<DiscoveryActivateBoost>(_onActivateBoost);
  }

  Future<void> _onLoadStack(
    DiscoveryStackLoadRequested event,
    Emitter<DiscoveryState> emit,
  ) async {
    emit(const DiscoveryLoading());

    // Store current context for prefetching
    _currentUserId = event.userId;
    _currentPreferences = event.preferences;

    // Always load the full queue size (20 profiles)
    final result = await getDiscoveryStack(
      GetDiscoveryStackParams(
        userId: event.userId,
        preferences: event.preferences,
        limit: queueSize,
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

          debugPrint('📱 Discovery queue loaded: ${cards.length} profiles ready');
          emit(DiscoveryLoaded(cards: cards, currentIndex: 0));
        }
      },
    );
  }

  /// Extract cards and currentIndex from any card-bearing state
  ({List<DiscoveryCard> cards, int currentIndex})? _extractCards() {
    final s = state;
    if (s is DiscoveryLoaded) return (cards: s.cards, currentIndex: s.currentIndex);
    if (s is DiscoveryRewindUnavailable) return (cards: s.cards, currentIndex: s.currentIndex);
    if (s is DiscoverySwipeLimitReached) return (cards: s.cards, currentIndex: s.currentIndex);
    if (s is DiscoverySuperLikeLimitReached) return (cards: s.cards, currentIndex: s.currentIndex);
    if (s is DiscoverySwipeCompleted) return (cards: s.cards, currentIndex: s.currentIndex);
    if (s is DiscoveryInsufficientCoins) return (cards: s.cards, currentIndex: s.currentIndex);
    if (s is DiscoveryBoostActivated) return (cards: s.cards, currentIndex: s.currentIndex);
    return null;
  }

  Future<void> _onSwipeRecorded(
    DiscoverySwipeRecorded event,
    Emitter<DiscoveryState> emit,
  ) async {
    final data = _extractCards();
    if (data == null) {
      return;
    }

    final currentState = DiscoveryLoaded(cards: data.cards, currentIndex: data.currentIndex);

    // Get membership info (use defaults if not provided)
    final rules = event.membershipRules ?? MembershipRules.freeDefaults;
    final tier = event.membershipTier ?? MembershipTier.free;

    // ── Super Like: check hourly limit first, then coins ──
    if (event.actionType == SwipeActionType.superLike) {
      bool usedFreeAllowance = false;

      // Step 1: Check hourly super like limit
      final superLikeLimit = await _usageLimitService.checkLimit(
        userId: event.userId,
        limitType: UsageLimitType.superLikes,
        rules: rules,
        currentTier: tier,
      );

      if (superLikeLimit.isAllowed) {
        // Free super like available from tier allowance — no coins needed
        usedFreeAllowance = true;
      }

      // Step 2: If no free allowance, charge coins
      if (!usedFreeAllowance && coinRepository != null) {
        final balanceResult = await coinRepository!.getBalance(event.userId);
        final insufficient = balanceResult.fold(
          (failure) => true,
          (balance) => balance.availableCoins < CoinFeaturePrices.superLike,
        );

        if (insufficient) {
          final available = balanceResult.fold(
            (failure) => 0,
            (balance) => balance.availableCoins,
          );
          emit(DiscoveryInsufficientCoins(
            cards: currentState.cards,
            currentIndex: currentState.currentIndex,
            required: CoinFeaturePrices.superLike,
            available: available,
            featureName: 'Super Like',
          ));
          emit(DiscoveryLoaded(cards: currentState.cards, currentIndex: currentState.currentIndex));
          return;
        }

        // Deduct coins
        await coinRepository!.purchaseFeature(
          userId: event.userId,
          featureName: 'superlike',
          cost: CoinFeaturePrices.superLike,
        );
      } else if (!usedFreeAllowance && coinRepository == null) {
        // No free allowance and no coin repository — block action
        emit(DiscoveryInsufficientCoins(
          cards: currentState.cards,
          currentIndex: currentState.currentIndex,
          required: CoinFeaturePrices.superLike,
          available: 0,
          featureName: 'Super Like',
        ));
        emit(DiscoveryLoaded(cards: currentState.cards, currentIndex: currentState.currentIndex));
        return;
      }
    }

    // ── Hourly limit check per action type ──
    // Map swipe action to the correct hourly limit type
    final UsageLimitType? hourlyType;
    switch (event.actionType) {
      case SwipeActionType.like:
        hourlyType = UsageLimitType.likes;
        break;
      case SwipeActionType.pass:
        hourlyType = UsageLimitType.nopes;
        break;
      case SwipeActionType.superLike:
        // Already checked above via super like flow
        hourlyType = null;
        break;
      case SwipeActionType.skip:
        // Skips are free — no hourly limit
        hourlyType = null;
        break;
    }

    if (hourlyType != null) {
      final hourlyLimit = await _usageLimitService.checkLimit(
        userId: event.userId,
        limitType: hourlyType,
        rules: rules,
        currentTier: tier,
      );

      if (!hourlyLimit.isAllowed) {
        emit(DiscoverySwipeLimitReached(
          cards: currentState.cards,
          currentIndex: currentState.currentIndex,
          limitResult: hourlyLimit,
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
      debugPrint('❌ RecordSwipe FAILED: ${result.fold((l) => l.toString(), (r) => '')}');
      // Revert to previous state on error
      emit(currentState);
      return;
    }
    debugPrint('✅ RecordSwipe succeeded');

    // Success case - get the swipe action
    final swipeAction = result.getOrElse(() => throw Exception('Unreachable'));

    // Record hourly usage after successful swipe (non-critical — don't block on failure)
    try {
      switch (event.actionType) {
        case SwipeActionType.like:
          await _usageLimitService.recordUsage(
            userId: event.userId,
            limitType: UsageLimitType.likes,
          );
          break;
        case SwipeActionType.pass:
          await _usageLimitService.recordUsage(
            userId: event.userId,
            limitType: UsageLimitType.nopes,
          );
          break;
        case SwipeActionType.superLike:
          await _usageLimitService.recordUsage(
            userId: event.userId,
            limitType: UsageLimitType.superLikes,
          );
          break;
        case SwipeActionType.skip:
          // Skips are not tracked against any limit
          break;
      }
    } catch (e) {
      debugPrint('⚠️ Usage recording failed (non-critical): $e');
    }

    // Track last swiped card for rewind
    _lastSwipedCard = currentState.cards[currentState.currentIndex];
    _lastSwipeType = event.actionType;
    _lastSwipeCreatedMatch = swipeAction.createdMatch;

    // Move to next card
    final nextIndex = currentState.currentIndex + 1;
    final remainingCards = currentState.cards.length - nextIndex;

    // Check if we need to prefetch more profiles
    if (remainingCards <= prefetchThreshold && !_isPrefetching) {
      debugPrint('⏳ Queue low ($remainingCards profiles left), prefetching more...');
      _triggerPrefetch(event.userId);
    }

    if (swipeAction.createdMatch) {
      // Match created! Emit match state with matched user info
      emit(DiscoverySwipeCompleted(
        cards: currentState.cards,
        currentIndex: nextIndex,
        createdMatch: true,
        matchedUserId: event.targetUserId,
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
      // No match — still emit SwipeCompleted so listeners can refresh coins etc.
      emit(DiscoverySwipeCompleted(
        cards: currentState.cards,
        currentIndex: nextIndex,
        createdMatch: false,
      ));

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

  Future<void> _onRewind(
    DiscoveryRewindRequested event,
    Emitter<DiscoveryState> emit,
  ) async {
    // Get current cards and index from any card-bearing state
    final data = _extractCards();
    if (data == null) return;
    final cards = data.cards;
    final currentIndex = data.currentIndex;

    // Check coins for undo (3 coins)
    if (coinRepository != null) {
      final balanceResult = await coinRepository!.getBalance(event.userId);
      final insufficient = balanceResult.fold(
        (failure) => true,
        (balance) => balance.availableCoins < CoinFeaturePrices.undo,
      );

      if (insufficient) {
        final available = balanceResult.fold(
          (failure) => 0,
          (balance) => balance.availableCoins,
        );
        emit(DiscoveryInsufficientCoins(
          cards: cards,
          currentIndex: currentIndex,
          required: CoinFeaturePrices.undo,
          available: available,
          featureName: 'Undo Swipe',
        ));
        emit(DiscoveryLoaded(cards: cards, currentIndex: currentIndex));
        return;
      }
    }

    // Check if there's a previous swipe to undo
    if (_lastSwipedCard == null) {
      emit(DiscoveryRewindUnavailable(
        reason: 'no_previous',
        cards: cards,
        currentIndex: currentIndex,
      ));
      // Transition back to DiscoveryLoaded so swipes still work
      emit(DiscoveryLoaded(cards: cards, currentIndex: currentIndex));
      return;
    }

    // Can't undo if last swipe created a match
    if (_lastSwipeCreatedMatch) {
      emit(DiscoveryRewindUnavailable(
        reason: 'match_created',
        cards: cards,
        currentIndex: currentIndex,
      ));
      emit(DiscoveryLoaded(cards: cards, currentIndex: currentIndex));
      return;
    }

    // Delete the swipe record from Firestore
    final result = await undoSwipe(UndoSwipeParams(
      userId: event.userId,
      targetUserId: _lastSwipedCard!.userId,
    ));

    if (result.isLeft()) {
      // Failed to undo — stay on current state
      return;
    }

    // Deduct coins for successful undo
    if (coinRepository != null) {
      await coinRepository!.purchaseFeature(
        userId: event.userId,
        featureName: 'undo',
        cost: CoinFeaturePrices.undo,
      );
    }

    // Decrement index to go back to the previous card
    final rewindedIndex = currentIndex - 1;

    // Clear rewind tracking (prevent double-rewind)
    _lastSwipedCard = null;
    _lastSwipeType = null;
    _lastSwipeCreatedMatch = false;

    emit(DiscoveryLoaded(
      cards: cards,
      currentIndex: rewindedIndex < 0 ? 0 : rewindedIndex,
    ));
  }

  /// Trigger prefetch for more profiles
  void _triggerPrefetch(String userId) {
    if (_currentPreferences != null && !_isPrefetching) {
      add(DiscoveryPrefetchRequested(
        userId: userId,
        preferences: _currentPreferences!,
      ));
    }
  }

  /// Handle prefetch request - loads more profiles in the background
  Future<void> _onPrefetch(
    DiscoveryPrefetchRequested event,
    Emitter<DiscoveryState> emit,
  ) async {
    if (_isPrefetching) return;
    if (state is! DiscoveryLoaded) return;

    _isPrefetching = true;
    final currentState = state as DiscoveryLoaded;

    try {
      final result = await getDiscoveryStack(
        GetDiscoveryStackParams(
          userId: event.userId,
          preferences: event.preferences,
          limit: queueSize,
        ),
      );

      result.fold(
        (failure) {
          debugPrint('⚠️ Prefetch failed: ${failure.message}');
        },
        (candidates) {
          if (candidates.isNotEmpty && state is DiscoveryLoaded) {
            // Filter out profiles already in the queue
            final existingIds = currentState.cards
                .map((c) => c.candidate.profile.userId)
                .toSet();

            final newCandidates = candidates
                .where((c) => !existingIds.contains(c.profile.userId))
                .toList();

            if (newCandidates.isNotEmpty) {
              final newCards = newCandidates
                  .asMap()
                  .entries
                  .map((entry) => DiscoveryCard(
                        candidate: entry.value,
                        position: currentState.cards.length + entry.key,
                      ))
                  .toList();

              debugPrint('✅ Prefetched ${newCards.length} new profiles');

              emit(DiscoveryLoaded(
                cards: [...currentState.cards, ...newCards],
                currentIndex: currentState.currentIndex,
              ));
            }
          }
        },
      );
    } catch (e) {
      debugPrint('⚠️ Prefetch error: $e');
    } finally {
      _isPrefetching = false;
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

  /// Handle boost activation
  Future<void> _onActivateBoost(
    DiscoveryActivateBoost event,
    Emitter<DiscoveryState> emit,
  ) async {
    final data = _extractCards();
    if (data == null) return;

    if (discoveryDataSource == null) return;

    bool usedFreeBoost = false;

    // Step 1: Check tier's free monthly boost allowance
    if (event.membershipRules != null && event.membershipTier != null) {
      final boostLimit = await _usageLimitService.checkLimit(
        userId: event.userId,
        limitType: UsageLimitType.boosts,
        rules: event.membershipRules!,
        currentTier: event.membershipTier!,
      );

      if (boostLimit.isAllowed) {
        // Free boost available from tier — no coins needed
        usedFreeBoost = true;
      }
    }

    // Step 2: If no free boost, charge coins
    if (!usedFreeBoost) {
      if (coinRepository == null) {
        emit(DiscoveryInsufficientCoins(
          cards: data.cards,
          currentIndex: data.currentIndex,
          required: CoinFeaturePrices.boost,
          available: 0,
          featureName: 'Boost',
        ));
        emit(DiscoveryLoaded(cards: data.cards, currentIndex: data.currentIndex));
        return;
      }

      final balanceResult = await coinRepository!.getBalance(event.userId);
      final insufficient = balanceResult.fold(
        (failure) => true,
        (balance) => balance.availableCoins < CoinFeaturePrices.boost,
      );

      if (insufficient) {
        final available = balanceResult.fold(
          (failure) => 0,
          (balance) => balance.availableCoins,
        );
        emit(DiscoveryInsufficientCoins(
          cards: data.cards,
          currentIndex: data.currentIndex,
          required: CoinFeaturePrices.boost,
          available: available,
          featureName: 'Boost',
        ));
        emit(DiscoveryLoaded(cards: data.cards, currentIndex: data.currentIndex));
        return;
      }

      // Deduct coins
      await coinRepository!.purchaseFeature(
        userId: event.userId,
        featureName: 'boost',
        cost: CoinFeaturePrices.boost,
      );
    }

    // Record boost usage
    try {
      await _usageLimitService.recordUsage(
        userId: event.userId,
        limitType: UsageLimitType.boosts,
      );
    } catch (e) {
      debugPrint('⚠️ Boost usage recording failed (non-critical): $e');
    }

    // Activate boost
    final expiry = await discoveryDataSource!.activateBoost(event.userId);

    emit(DiscoveryBoostActivated(
      cards: data.cards,
      currentIndex: data.currentIndex,
      expiry: expiry,
    ));

    // Transition back to loaded
    emit(DiscoveryLoaded(cards: data.cards, currentIndex: data.currentIndex));
  }
}
