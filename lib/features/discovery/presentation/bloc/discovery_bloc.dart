import 'package:cloud_firestore/cloud_firestore.dart';
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
    on<DiscoveryGridSwipeRecorded>(_onGridSwipeRecorded);
    on<DiscoveryRewindRequested>(_onRewind);
    on<DiscoveryStackRefreshRequested>(_onRefreshStack);
    on<DiscoveryMoreCandidatesRequested>(_onLoadMore);
    on<DiscoveryPrefetchRequested>(_onPrefetch);
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
    if (s is DiscoveryBaseMembershipRequired) return (cards: s.cards, currentIndex: s.currentIndex);
    return null;
  }

  Future<void> _onSwipeRecorded(
    DiscoverySwipeRecorded event,
    Emitter<DiscoveryState> emit,
  ) async {
    await _processSwipeAction(
      userId: event.userId,
      targetUserId: event.targetUserId,
      actionType: event.actionType,
      membershipRules: event.membershipRules,
      membershipTier: event.membershipTier,
      emit: emit,
      advanceIndex: true,
    );
  }

  Future<void> _onGridSwipeRecorded(
    DiscoveryGridSwipeRecorded event,
    Emitter<DiscoveryState> emit,
  ) async {
    await _processSwipeAction(
      userId: event.userId,
      targetUserId: event.targetUserId,
      actionType: event.actionType,
      membershipRules: event.membershipRules,
      membershipTier: event.membershipTier,
      emit: emit,
      advanceIndex: false,
    );
  }

  /// Shared swipe processing logic for both swipe mode and grid mode.
  /// When [advanceIndex] is true (swipe mode), currentIndex advances to the next card.
  /// When false (grid mode), currentIndex stays unchanged.
  Future<void> _processSwipeAction({
    required String userId,
    required String targetUserId,
    required SwipeActionType actionType,
    MembershipRules? membershipRules,
    MembershipTier? membershipTier,
    required Emitter<DiscoveryState> emit,
    required bool advanceIndex,
  }) async {
    final data = _extractCards();
    if (data == null) {
      return;
    }

    final currentState = DiscoveryLoaded(cards: data.cards, currentIndex: data.currentIndex);

    // Get membership info (use defaults if not provided)
    final rules = membershipRules ?? MembershipRules.freeDefaults;
    final tier = membershipTier ?? MembershipTier.free;

    // ── Super Like: check base membership first, then limits, then coins ──
    if (actionType == SwipeActionType.superLike) {
      // Check if user has base membership before processing super like
      {
        try {
          final profileDoc = await FirebaseFirestore.instance
              .collection('profiles')
              .doc(userId)
              .get();
          final profileData = profileDoc.data();
          final hasBaseMembership = profileData?['hasBaseMembership'] as bool? ?? false;
          final endTs = profileData?['baseMembershipEndDate'] as Timestamp?;
          final isActive = hasBaseMembership &&
              endTs != null &&
              endTs.toDate().isAfter(DateTime.now());
          // Also allow test tier users through
          final memberTier = profileData?['membershipTier'] as String? ?? '';
          if (!isActive && memberTier != 'test') {
            emit(DiscoveryBaseMembershipRequired(
              cards: currentState.cards,
              currentIndex: currentState.currentIndex,
            ));
            // Transition back to loaded so UI can continue after dialog
            emit(DiscoveryLoaded(cards: currentState.cards, currentIndex: currentState.currentIndex));
            return;
          }
        } catch (e) {
          debugPrint('Error checking base membership: $e');
        }
      }
      bool usedFreeAllowance = false;

      // Step 1: Check daily super like limit
      final dailySuperLikeLimit = await _usageLimitService.checkLimit(
        userId: userId,
        limitType: UsageLimitType.dailySuperLikes,
        rules: rules,
        currentTier: tier,
      );

      if (dailySuperLikeLimit.isAllowed) {
        // Step 2: Check hourly super like limit
        final superLikeLimit = await _usageLimitService.checkLimit(
          userId: userId,
          limitType: UsageLimitType.superLikes,
          rules: rules,
          currentTier: tier,
        );

        if (superLikeLimit.isAllowed) {
          // Free super like available from tier allowance — no coins needed
          usedFreeAllowance = true;
        }
      }

      // Free users: strictly limited to daily allowance — no coin bypass
      if (!usedFreeAllowance && tier == MembershipTier.free) {
        emit(DiscoverySuperLikeLimitReached(
          cards: currentState.cards,
          currentIndex: currentState.currentIndex,
          limitResult: dailySuperLikeLimit,
        ));
        return;
      }

      // Step 3: If no free allowance (paid tiers only), charge coins
      if (!usedFreeAllowance && coinRepository != null) {
        final balanceResult = await coinRepository!.getBalance(userId);
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
          userId: userId,
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
    switch (actionType) {
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
        userId: userId,
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
        userId: userId,
        targetUserId: targetUserId,
        actionType: actionType,
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
      switch (actionType) {
        case SwipeActionType.like:
          await _usageLimitService.recordUsage(
            userId: userId,
            limitType: UsageLimitType.likes,
          );
          break;
        case SwipeActionType.pass:
          await _usageLimitService.recordUsage(
            userId: userId,
            limitType: UsageLimitType.nopes,
          );
          break;
        case SwipeActionType.superLike:
          await _usageLimitService.recordUsage(
            userId: userId,
            limitType: UsageLimitType.superLikes,
          );
          await _usageLimitService.recordUsage(
            userId: userId,
            limitType: UsageLimitType.dailySuperLikes,
          );
          break;
        case SwipeActionType.skip:
          // Skips are not tracked against any limit
          break;
      }
    } catch (e) {
      debugPrint('⚠️ Usage recording failed (non-critical): $e');
    }

    // Track last swiped card for rewind (swipe mode only)
    if (advanceIndex) {
      _lastSwipedCard = currentState.cards[currentState.currentIndex];
      _lastSwipeType = actionType;
      _lastSwipeCreatedMatch = swipeAction.createdMatch;
    }

    // Move to next card (swipe mode) or stay in place (grid mode)
    final nextIndex = advanceIndex
        ? currentState.currentIndex + 1
        : currentState.currentIndex;
    final remainingCards = currentState.cards.length - nextIndex;

    // Check if we need to prefetch more profiles (swipe mode only)
    if (advanceIndex && remainingCards <= prefetchThreshold && !_isPrefetching) {
      debugPrint('⏳ Queue low ($remainingCards profiles left), prefetching more...');
      _triggerPrefetch(userId);
    }

    if (swipeAction.createdMatch) {
      // Match created! Emit match state with matched user info
      emit(DiscoverySwipeCompleted(
        cards: currentState.cards,
        currentIndex: nextIndex,
        createdMatch: true,
        matchedUserId: targetUserId,
        matchId: swipeAction.matchId,
      ));

      // Wait briefly then transition to loaded state
      await Future.delayed(const Duration(milliseconds: 300));

      if (advanceIndex && nextIndex >= currentState.cards.length) {
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

      if (advanceIndex && nextIndex >= currentState.cards.length) {
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
    emit(const DiscoveryLoading());

    _currentUserId = event.userId;
    _currentPreferences = event.preferences;

    // forceRefresh=true bypasses the in-memory cache (new location, pull-to-refresh, etc.)
    final result = await getDiscoveryStack(
      GetDiscoveryStackParams(
        userId: event.userId,
        preferences: event.preferences,
        limit: queueSize,
        forceRefresh: true,
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
