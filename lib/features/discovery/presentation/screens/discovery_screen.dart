import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../domain/entities/discovery_card.dart';
import '../../domain/entities/match_preferences.dart';
import '../../../matching/domain/repositories/matching_repository.dart';
import '../../domain/entities/swipe_action.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../../notifications/domain/entities/notification.dart';
import '../../../notifications/domain/repositories/notification_repository.dart';
import '../../../membership/domain/entities/membership.dart';
import '../../../coins/domain/repositories/coin_repository.dart';
import '../bloc/discovery_bloc.dart';
import '../bloc/discovery_event.dart';
import '../bloc/discovery_state.dart';
import '../widgets/swipe_card.dart';
import '../widgets/swipe_buttons.dart';
import '../widgets/match_notification.dart';
import 'discovery_preferences_screen.dart';
import 'profile_detail_screen.dart';
import '../widgets/nickname_search_dialog.dart';
import '../../../coins/presentation/bloc/coin_bloc.dart';
import '../../../coins/presentation/bloc/coin_event.dart';
import '../../../coins/presentation/screens/coin_shop_screen.dart';
import '../../../chat/presentation/screens/chat_screen.dart';
import '../../domain/entities/match.dart';
import 'match_detail_screen.dart';
import '../../../../core/utils/base_membership_gate.dart';
import '../../../../generated/app_localizations.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_state.dart';

/// Discovery Screen
///
/// Main screen for browsing and swiping through potential matches
class DiscoveryScreen extends StatefulWidget {
  final String userId;
  final VoidCallback? onGridModeChanged;

  const DiscoveryScreen({
    super.key,
    required this.userId,
    this.onGridModeChanged,
  });

  @override
  DiscoveryScreenState createState() => DiscoveryScreenState();
}

class DiscoveryScreenState extends State<DiscoveryScreen> {
  final GlobalKey<_DiscoveryScreenContentState> _contentKey =
      GlobalKey<_DiscoveryScreenContentState>();

  /// Toggle grid/swipe mode - callable from parent widgets
  void toggleGridMode() {
    _contentKey.currentState?.toggleGridMode();
  }

  /// Whether grid mode is active - queryable from parent widgets
  bool get isGridMode => _contentKey.currentState?.isGridMode ?? false;

  /// Current saved preferences - queryable from parent widgets
  MatchPreferences? get savedPreferences =>
      _contentKey.currentState?.savedPreferences;

  /// Refresh the discovery stack
  void refresh() {
    _contentKey.currentState?.refresh();
  }

  /// Refresh with new preferences (resets grid state too)
  void refreshWithPreferences(MatchPreferences preferences) {
    _contentKey.currentState?.refreshWithPreferences(preferences);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<DiscoveryBloc>(),
      child: _DiscoveryScreenContent(
        key: _contentKey,
        userId: widget.userId,
        onGridModeChanged: widget.onGridModeChanged,
      ),
    );
  }
}

class _DiscoveryScreenContent extends StatefulWidget {
  final String userId;
  final VoidCallback? onGridModeChanged;

  const _DiscoveryScreenContent({
    super.key,
    required this.userId,
    this.onGridModeChanged,
  });

  @override
  State<_DiscoveryScreenContent> createState() => _DiscoveryScreenContentState();
}

class _DiscoveryScreenContentState extends State<_DiscoveryScreenContent> {
  final ValueNotifier<double> _dragProgress = ValueNotifier(0.0);
  Profile? _currentUserProfile;
  final Set<String> _precachedImageUrls = {};
  MatchPreferences? _savedPreferences;

  // Traveler tracking — detect when traveler mode activates to refresh discovery
  bool _wasTravelerActive = false;
  String _prevTravelerCity = '';

  // Grid mode state
  bool _isGridMode = true;
  int _gridColumns = 3; // 2, 3, or 4 columns
  int _gridExtraPurchased = 0; // Number of extra batches purchased
  int _gridStartIndex = 0; // Snapshot of currentIndex when grid mode was entered
  final Set<String> _gridSkippedIds = {}; // Skipped users (disappear from grid)
  final Map<String, String> _gridActionOverlays = {}; // userId -> 'liked'|'superLiked'|'matched'
  String? _lastAttemptedGridCardId; // Track last grid action for limit-hit overlay revert

  // Online status refresh
  Timer? _onlineStatusTimer;
  final Map<String, bool> _onlineStatusOverrides = {}; // userId -> isOnline

  String get userId => widget.userId;

  /// Get current preferences (saved from Firestore, or default)
  MatchPreferences get _currentPreferences =>
      _savedPreferences ?? MatchPreferences.defaultFor(userId);

  /// Get grid profile limit based on membership tier
  int get _gridProfileLimit {
    final tier = _currentUserProfile?.membershipTier ?? MembershipTier.free;
    int baseRows;
    switch (tier) {
      case MembershipTier.free:
        baseRows = 3;
        break;
      case MembershipTier.silver:
        baseRows = 30;
        break;
      case MembershipTier.gold:
        baseRows = 60;
        break;
      case MembershipTier.platinum:
      case MembershipTier.test:
        baseRows = 100;
        break;
    }
    return (baseRows * _gridColumns) + (_gridExtraPurchased * _gridColumns * 3);
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentUserProfile();
    _loadSavedPreferencesAndStart();
    _loadSwipeHistoryOverlays();
    _onlineStatusTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _refreshOnlineStatuses(),
    );
  }

  /// Load saved match preferences from Firestore, then start the discovery stack
  Future<void> _loadSavedPreferencesAndStart() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists && doc.data()?['matchPreferences'] != null) {
        final prefsMap = doc.data()!['matchPreferences'] as Map<String, dynamic>;
        _savedPreferences = MatchPreferences.fromMap(prefsMap);
        debugPrint('Loaded saved preferences: maxDistance=${_savedPreferences!.maxDistanceKm}km');
      }
    } catch (e) {
      debugPrint('Could not load saved preferences: $e');
    }

    if (mounted) {
      context.read<DiscoveryBloc>().add(DiscoveryStackLoadRequested(
        userId: userId,
        preferences: _currentPreferences,
      ));
    }
  }

  Future<void> _loadCurrentUserProfile() async {
    final profileRepo = di.sl<ProfileRepository>();
    final result = await profileRepo.getProfile(userId);
    result.fold(
      (failure) => debugPrint('Could not load current user profile: ${failure.message}'),
      (profile) {
        if (mounted) {
          setState(() {
            _currentUserProfile = profile;
            _wasTravelerActive = profile.isTravelerActive;
            _prevTravelerCity = profile.travelerLocation?.city ?? '';
          });
        }
      },
    );
  }

  /// Load swipe history from Firestore to pre-populate grid action overlays.
  /// This makes gradients persistent across sessions.
  Future<void> _loadSwipeHistoryOverlays() async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Load swipe history
      final swipesSnapshot = await firestore
          .collection('swipes')
          .where('userId', isEqualTo: userId)
          .get();

      // Load active matches to mark matched users
      final matchesSnapshot = await firestore
          .collection('matches')
          .where('isActive', isEqualTo: true)
          .get();

      final matchedUserIds = <String>{};
      for (final doc in matchesSnapshot.docs) {
        final data = doc.data();
        final u1 = data['userId1'] as String?;
        final u2 = data['userId2'] as String?;
        if (u1 == userId && u2 != null) matchedUserIds.add(u2);
        if (u2 == userId && u1 != null) matchedUserIds.add(u1);
      }

      if (!mounted) return;

      setState(() {
        for (final doc in swipesSnapshot.docs) {
          final data = doc.data();
          final targetUserId = data['targetUserId'] as String?;
          final actionType = data['actionType'] as String?;
          if (targetUserId == null || actionType == null) continue;

          // If this user is matched, mark as matched (overrides like/superLike)
          if (matchedUserIds.contains(targetUserId)) {
            _gridActionOverlays[targetUserId] = 'matched';
          } else {
            // Map Firestore actionType to overlay key
            switch (actionType) {
              case 'like':
                _gridActionOverlays[targetUserId] = 'liked';
                break;
              case 'superLike':
                _gridActionOverlays[targetUserId] = 'superLiked';
                break;
              case 'pass':
                _gridActionOverlays[targetUserId] = 'passed';
                _gridSkippedIds.add(targetUserId);
                break;
              case 'skip':
                _gridActionOverlays[targetUserId] = 'skipped';
                _gridSkippedIds.add(targetUserId);
                break;
            }
          }
        }
      });
      debugPrint('[Discovery] Loaded ${_gridActionOverlays.length} swipe overlays from history');
    } catch (e) {
      debugPrint('[Discovery] Error loading swipe history overlays: $e');
    }
  }

  /// Periodically refresh online statuses for profiles visible in the grid.
  Future<void> _refreshOnlineStatuses() async {
    if (!mounted || !_isGridMode) return;

    final state = context.read<DiscoveryBloc>().state;
    final List<DiscoveryCard> cards;
    if (state is DiscoveryLoaded) {
      cards = state.cards;
    } else if (state is DiscoverySwiping) {
      cards = state.cards;
    } else if (state is DiscoverySwipeCompleted) {
      cards = state.cards;
    } else if (state is DiscoverySwipeLimitReached) {
      cards = state.cards;
    } else if (state is DiscoverySuperLikeLimitReached) {
      cards = state.cards;
    } else if (state is DiscoveryInsufficientCoins) {
      cards = state.cards;
    } else if (state is DiscoveryRewindUnavailable) {
      cards = state.cards;
    } else {
      return;
    }

    final startIdx = _gridStartIndex.clamp(0, cards.length);
    final visibleCards = cards.sublist(startIdx);
    if (visibleCards.isEmpty) return;

    final userIds = visibleCards.map((c) => c.userId).toSet().toList();

    try {
      final firestore = FirebaseFirestore.instance;
      final newStatuses = <String, bool>{};

      // Batch query in groups of 10 (Firestore whereIn limit)
      for (var i = 0; i < userIds.length; i += 10) {
        final batch = userIds.sublist(i, (i + 10).clamp(0, userIds.length));
        final snapshot = await firestore
            .collection('profiles')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        for (final doc in snapshot.docs) {
          final data = doc.data();
          newStatuses[doc.id] = data['isOnline'] == true;
        }
      }

      if (!mounted) return;

      // Check if any status actually changed
      bool changed = false;
      for (final entry in newStatuses.entries) {
        final current = _onlineStatusOverrides[entry.key];
        if (current != entry.value) {
          changed = true;
          break;
        }
      }

      if (changed) {
        setState(() {
          _onlineStatusOverrides.addAll(newStatuses);
        });
      }
    } catch (e) {
      debugPrint('[Discovery] Error refreshing online statuses: $e');
    }
  }

  @override
  void dispose() {
    _onlineStatusTimer?.cancel();
    _dragProgress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      listenWhen: (_, curr) => curr is ProfileLoaded || curr is ProfileUpdated,
      listener: (context, state) {
        Profile? profile;
        if (state is ProfileLoaded) profile = state.profile;
        if (state is ProfileUpdated) profile = state.profile;
        if (profile == null) return;

        final isNowActive = profile.isTravelerActive;
        final nowCity = profile.travelerLocation?.city ?? '';

        // Always keep local profile reference up to date (membership, etc.)
        _currentUserProfile = profile;

        final travelerJustActivated = isNowActive && !_wasTravelerActive;
        final travelerCityChanged = isNowActive && _wasTravelerActive && nowCity != _prevTravelerCity;

        if (travelerJustActivated || travelerCityChanged) {
          debugPrint('[Discovery] Traveler activated/changed → refreshing stack');
          refreshWithPreferences(_currentPreferences);
        }

        _wasTravelerActive = isNowActive;
        _prevTravelerCity = nowCity;
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: SafeArea(
          child: BlocConsumer<DiscoveryBloc, DiscoveryState>(
          listener: (context, state) {
            if (state is DiscoverySwipeCompleted) {
              // Swipe accepted — clear the pending grid card tracker
              _lastAttemptedGridCardId = null;
              // Refresh coin balance after any swipe (super likes cost coins)
              context.read<CoinBloc>().add(LoadCoinBalance(userId));
              // Update grid overlay for match result
              if (state.createdMatch && state.matchedUserId != null) {
                setState(() {
                  _gridActionOverlays[state.matchedUserId!] = 'matched';
                });
                _showMatchDialog(context, state);
              }
            }
            if (state is DiscoveryRewindUnavailable) {
              _handleRewindUnavailable(context, state.reason);
            }
            if (state is DiscoverySwipeLimitReached || state is DiscoverySuperLikeLimitReached) {
              // Revert grid overlay if a grid action was blocked by the limit
              if (_lastAttemptedGridCardId != null) {
                setState(() {
                  _gridActionOverlays.remove(_lastAttemptedGridCardId);
                });
                _lastAttemptedGridCardId = null;
              }
              final message = state is DiscoverySwipeLimitReached
                  ? (state as DiscoverySwipeLimitReached).limitResult.message
                  : (state as DiscoverySuperLikeLimitReached).limitResult.message;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  duration: const Duration(seconds: 4),
                  backgroundColor: Colors.red.shade700,
                ),
              );
            }
            if (state is DiscoveryInsufficientCoins) {
              _showInsufficientCoinsDialog(context, state);
            }
          },
          builder: (context, state) {
            if (state is DiscoveryLoading) {
              return _buildLoading();
            }

            if (state is DiscoveryError) {
              return _buildError(context, state.message);
            }

            if (state is DiscoveryStackEmpty) {
              return _buildEmptyState(context);
            }

            // Handle all states that carry cards
            if (state is DiscoveryLoaded ||
                state is DiscoverySwiping ||
                state is DiscoveryRewindUnavailable ||
                state is DiscoverySwipeCompleted ||
                state is DiscoverySwipeLimitReached ||
                state is DiscoverySuperLikeLimitReached ||
                state is DiscoveryInsufficientCoins) {
              late final List<DiscoveryCard> cards;
              late final int currentIndex;

              if (state is DiscoveryLoaded) {
                cards = state.cards;
                currentIndex = state.currentIndex;
              } else if (state is DiscoverySwiping) {
                cards = state.cards;
                currentIndex = state.currentIndex;
              } else if (state is DiscoveryRewindUnavailable) {
                cards = state.cards;
                currentIndex = state.currentIndex;
              } else if (state is DiscoverySwipeCompleted) {
                cards = state.cards;
                currentIndex = state.currentIndex;
              } else if (state is DiscoverySwipeLimitReached) {
                cards = state.cards;
                currentIndex = state.currentIndex;
              } else if (state is DiscoverySuperLikeLimitReached) {
                cards = state.cards;
                currentIndex = state.currentIndex;
              } else {
                final s = state as DiscoveryInsufficientCoins;
                cards = s.cards;
                currentIndex = s.currentIndex;
              }

              // In grid mode, the grid uses _gridStartIndex (frozen snapshot),
              // not the bloc's currentIndex. The bloc advances currentIndex
              // with each grid action, but the grid pool is independent.
              // Only show empty state in swipe mode when index is exhausted.
              if (_isGridMode) {
                // Pre-cache images for grid cards
                _precacheUpcomingImages(cards, _gridStartIndex.clamp(0, cards.length));
                return _buildGridMode(context, cards, currentIndex);
              }

              // In swipe mode, skip cards that were already acted on from grid
              var effectiveIndex = currentIndex;
              while (effectiveIndex < cards.length &&
                  _gridActionOverlays.containsKey(cards[effectiveIndex].userId)) {
                effectiveIndex++;
              }

              if (effectiveIndex >= cards.length) {
                return _buildEmptyState(context);
              }

              // Pre-cache images for upcoming cards
              _precacheUpcomingImages(cards, effectiveIndex);

              final enabled = state is DiscoveryLoaded ||
                  state is DiscoveryRewindUnavailable ||
                  state is DiscoverySwipeLimitReached ||
                  state is DiscoverySuperLikeLimitReached ||
                  state is DiscoveryInsufficientCoins;

              return Column(
                children: [
                  // Header
                  _buildHeader(context),

                  // Card stack
                  Expanded(
                    child: _buildCardStack(
                      context,
                      cards,
                      effectiveIndex,
                      enabled,
                    ),
                  ),

                  // Action buttons
                  _buildActionButtons(
                    context,
                    cards[effectiveIndex],
                    enabled,
                  ),

                  const SizedBox(height: 24),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    ),
    );
  }

  /// Pre-cache images for upcoming cards so they load instantly
  void _precacheUpcomingImages(List<DiscoveryCard> cards, int currentIndex) {
    // Precache the next 15 cards ahead
    final end = (currentIndex + 15).clamp(0, cards.length);
    for (int i = currentIndex; i < end; i++) {
      final photoUrls = cards[i].candidate.profile.photoUrls;
      for (final url in photoUrls) {
        if (url.isNotEmpty && !_precachedImageUrls.contains(url)) {
          _precachedImageUrls.add(url);
          precacheImage(
            CachedNetworkImageProvider(url),
            context,
          ).catchError((_) {
            // Ignore precache errors silently
          });
        }
      }
    }
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.richGold,
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.errorRed,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.read<DiscoveryBloc>().add(
                    DiscoveryStackRefreshRequested(
                      userId: userId,
                      preferences: _currentPreferences,
                    ),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.richGold,
              foregroundColor: AppColors.deepBlack,
            ),
            child: Text(AppLocalizations.of(context)!.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.people_outline,
            size: 80,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)!.noOthersToSee,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              AppLocalizations.of(context)!.checkBackLater,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => DiscoveryPreferencesScreen(
                    userId: userId,
                    currentPreferences: _savedPreferences,
                    onSave: (preferences) {
                      refreshWithPreferences(preferences);
                    },
                  ),
                ),
              );
            },
            icon: const Icon(Icons.tune),
            label: Text(AppLocalizations.of(context)!.adjustPreferences),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.richGold,
              foregroundColor: AppColors.deepBlack,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    // Header is now handled by MainNavigationScreen's AppBar
    return const SizedBox.shrink();
  }

  Widget _buildCardStack(
    BuildContext context,
    List cards,
    int currentIndex,
    bool enabled,
  ) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: SwipeCard(
        key: ValueKey(cards[currentIndex].userId),
        card: cards[currentIndex],
        isFront: true,
        onSwipe: enabled
            ? (direction) => _handleSwipe(context, cards[currentIndex], direction)
            : null,
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, card, bool enabled) {
    return SwipeButtons(
      enabled: enabled,
      onRewind: () => _handleRewind(context),
      onPass: () => _handleSwipe(context, card, SwipeDirection.left),
      onSkip: () => _handleSwipe(context, card, SwipeDirection.down),
      onSuperLike: () => _handleSwipe(context, card, SwipeDirection.up),
      onLike: () => _handleSwipe(context, card, SwipeDirection.right),
    );
  }

  // ───────────────────── Grid Mode ─────────────────────

    Widget _buildGridMode(BuildContext context, List<DiscoveryCard> cards, int currentIndex) {
        // Use the snapshot index from when grid mode was entered, so bloc's
    // currentIndex advancing on each action doesn't shrink the pool.
    final startIdx = _gridStartIndex.clamp(0, cards.length);
    // If no cards at all, show empty state
    if (cards.isEmpty) {
      return _buildEmptyState(context);
    }
    // Show ALL users (including skipped ones) but with their action overlays
    // Grid mode always sorts by distance (closest first)
    final allCards = cards
        .sublist(startIdx)
        .toList()
      ..sort((a, b) => a.candidate.distance.compareTo(b.candidate.distance));
    
    // Separate admin/support profiles — they always go first
    final adminCards = allCards.where((card) =>
        card.candidate.profile.isAdmin || card.candidate.profile.isSupport).toList();
    final regularCards = allCards.where((card) =>
        !card.candidate.profile.isAdmin && !card.candidate.profile.isSupport).toList();

    // Apply action filters to regular cards only
    List<DiscoveryCard> filteredRegular;
    if (_activeFilters.isEmpty) {
      filteredRegular = regularCards;
    } else {
      filteredRegular = regularCards.where((card) {
        final overlay = _gridActionOverlays[card.userId];
        // If no overlay and user wants to see 'all' or specific actions
        if (overlay == null) {
          return _activeFilters.contains('all');
        }
        // Check if this card's action matches any active filter
        return _activeFilters.contains(overlay);
      }).toList();
    }

    // Admin/support always first, then regular profiles
    final List<DiscoveryCard> filteredCards = [
      ...adminCards,
      ...filteredRegular,
    ];
    
    final limit = _gridProfileLimit;
    final visibleCount = filteredCards.length.clamp(0, limit);
    final visibleCards = filteredCards.take(visibleCount).toList();
    final hasMore = visibleCount >= limit;
    final tier = _currentUserProfile?.membershipTier ?? MembershipTier.free;

        return Column(
      children: [
        // Grid header with column selector and profile count
        _buildGridHeader(visibleCount, filteredCards.length, tier),

        // Grid content
        Expanded(
          child: RefreshIndicator(
            color: AppColors.richGold,
            backgroundColor: AppColors.backgroundCard,
            onRefresh: () {
              final completer = Completer<void>();
              refreshWithPreferences(_currentPreferences);
              // Keep spinner visible until bloc emits a non-loading state
              StreamSubscription? sub;
              sub = context.read<DiscoveryBloc>().stream.listen((state) {
                if (state is! DiscoveryLoading) {
                  completer.complete();
                  sub?.cancel();
                }
              });
              // Safety timeout so spinner never hangs
              return completer.future.timeout(
                const Duration(seconds: 15),
                onTimeout: () {},
              );
            },
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _gridColumns,
                crossAxisSpacing: 3,
                mainAxisSpacing: 3,
                childAspectRatio: _gridColumns == 4 ? 0.8 : 0.7,
              ),
              itemCount: visibleCount + (hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= visibleCount) {
                  return _buildLoadMoreCard();
                }
                return _buildGridProfileCard(context, visibleCards[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

      Widget _buildGridHeader(int showing, int total, MembershipTier tier) {
    final l10n = AppLocalizations.of(context)!;
    final tierName = tier == MembershipTier.free
        ? l10n.tierFree
        : tier == MembershipTier.silver
            ? l10n.silver
            : tier == MembershipTier.gold
                ? l10n.gold
                : l10n.platinum;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.showingProfiles(showing),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  if (_activeFilters.isNotEmpty)
                    Text(
                      'Filtered from $total',
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.richGold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  tierName,
                  style: const TextStyle(
                    color: AppColors.richGold,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              // Column selector
              _buildColumnSelector(),
            ],
          ),
          const SizedBox(height: 8),
          // Filter buttons
          _buildGridFilters(),
        ],
      ),
    );
  }

    Widget _buildColumnSelector() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [2, 3, 4].map((cols) {
          final isSelected = _gridColumns == cols;
          return GestureDetector(
            onTap: () {
              if (_gridColumns != cols) {
                HapticFeedback.lightImpact();
                setState(() {
                  _gridColumns = cols;
                  _gridExtraPurchased = 0;
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.richGold : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$cols',
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textTertiary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Filter state
  final Set<String> _activeFilters = {};

  Widget _buildGridFilters() {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        _buildFilterChip(l10n.discoveryFilterAll, 'all', Icons.grid_view),
        _buildFilterChip(l10n.discoveryFilterLiked, 'liked', Icons.favorite),
        _buildFilterChip(l10n.discoveryFilterSuperLiked, 'superLiked', Icons.star),
        _buildFilterChip(l10n.discoveryFilterPassed, 'passed', Icons.close),
        _buildFilterChip(l10n.discoveryFilterSkipped, 'skipped', Icons.arrow_downward),
        _buildFilterChip(l10n.discoveryFilterMatches, 'matched', Icons.favorite_border),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isActive = _activeFilters.contains(value) || (value == 'all' && _activeFilters.isEmpty);
    return FilterChip(
      label: Text(label),
      avatar: Icon(icon, size: 16),
      selected: isActive,
      onSelected: (selected) {
        setState(() {
          if (value == 'all') {
            _activeFilters.clear();
          } else {
            if (selected) {
              _activeFilters.add(value);
            } else {
              _activeFilters.remove(value);
            }
            // If all filters are removed, show all
            if (_activeFilters.isEmpty) {
              // Show all - no filtering
            }
          }
        });
      },
      selectedColor: AppColors.richGold.withOpacity(0.2),
      checkmarkColor: AppColors.richGold,
      backgroundColor: AppColors.backgroundCard,
      labelStyle: TextStyle(
        color: isActive ? AppColors.richGold : AppColors.textSecondary,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isActive ? AppColors.richGold : AppColors.divider,
          width: 1,
        ),
      ),
    );
  }

  Widget _buildGridProfileCard(BuildContext context, DiscoveryCard card) {
    return _GridProfileCard(
      key: ValueKey(card.userId),
      card: card,
      gridColumns: _gridColumns,
      actionOverlay: _gridActionOverlays[card.userId],
      isOnlineOverride: _onlineStatusOverrides[card.userId],
      onAction: _gridAction,
    );
  }

  Future<void> _gridAction(DiscoveryCard card, SwipeActionType actionType) async {
    // Base membership gate
    final wasMember = _currentUserProfile?.isBaseMembershipActive ?? false;
    final allowed = await BaseMembershipGate.checkAndGate(
      context: context,
      profile: _currentUserProfile,
      userId: userId,
    );
    if (!allowed) return;
    if (!wasMember) await _loadCurrentUserProfile();

    // Dispatch the swipe action to the bloc with membership data for limit checks
    final tier = _currentUserProfile?.membershipTier ?? MembershipTier.free;
    final rules = MembershipRules.getDefaultsForTier(tier);
    // Track the card being actioned so we can revert its overlay if the limit is hit
    _lastAttemptedGridCardId = card.userId;
    context.read<DiscoveryBloc>().add(
      DiscoverySwipeRecorded(
        userId: userId,
        targetUserId: card.userId,
        actionType: actionType,
        membershipRules: rules,
        membershipTier: tier,
      ),
    );

    setState(() {
      switch (actionType) {
                case SwipeActionType.skip:
          // Skip: mark as skipped and show skipped overlay
          _gridSkippedIds.add(card.userId);
          _gridActionOverlays[card.userId] = 'skipped';
          break;
        case SwipeActionType.pass:
          // Nope: mark as passed and show passed overlay
          _gridSkippedIds.add(card.userId);
          _gridActionOverlays[card.userId] = 'passed';
          break;
        case SwipeActionType.like:
          _gridActionOverlays[card.userId] = 'liked';
          break;
        case SwipeActionType.superLike:
          _gridActionOverlays[card.userId] = 'superLiked';
          _sendSuperLikeNotification(card.userId, card.displayName);
          break;
      }
    });

    // Match detection is handled by the BlocConsumer listener above
  }

  Widget _buildLoadMoreCard() {
    final l10n = AppLocalizations.of(context)!;
    final batchSize = _gridColumns * 3; // 3 rows worth of profiles
    return GestureDetector(
      onTap: _purchaseMoreGridProfiles,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.richGold.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              color: AppColors.richGold.withOpacity(0.7),
              size: 36,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.seeMoreProfiles(batchSize),
              style: const TextStyle(
                color: AppColors.richGold,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.monetization_on, color: AppColors.richGold.withOpacity(0.7), size: 14),
                const SizedBox(width: 2),
                Text(
                  l10n.coinsCost(10),
                  style: TextStyle(
                    color: AppColors.richGold.withOpacity(0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _purchaseMoreGridProfiles() async {
    final l10n = AppLocalizations.of(context)!;
    final batchSize = _gridColumns * 3;
    try {
      final coinRepo = di.sl<CoinRepository>();
      final balanceResult = await coinRepo.getBalance(userId);

      if (!mounted) return;

      final hasEnough = balanceResult.fold(
        (failure) => false,
        (balance) => balance.availableCoins >= 10,
      );

      if (!hasEnough) {
        _showGridPurchaseInsufficientCoins();
        return;
      }

      // Confirm purchase
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.backgroundCard,
          title: Row(
            children: [
              const Icon(Icons.grid_view, color: AppColors.richGold),
              const SizedBox(width: 8),
              Text(l10n.seeMoreProfilesTitle, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18)),
            ],
          ),
          content: Text(
            l10n.unlockMoreProfiles(batchSize, 10),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.cancel, style: const TextStyle(color: AppColors.textTertiary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.richGold),
              child: Text(l10n.unlock, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) return;

      await coinRepo.purchaseFeature(
        userId: userId,
        featureName: 'grid_view_more',
        cost: 10,
      );

      if (mounted) {
        setState(() {
          _gridExtraPurchased++;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.discoveryError(e.toString())), backgroundColor: AppColors.errorRed),
        );
      }
    }
  }

  void _showGridPurchaseInsufficientCoins() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(l10n.insufficientCoins, style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(
          l10n.needCoinsForProfiles(10),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel, style: const TextStyle(color: AppColors.textTertiary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => CoinShopScreen(userId: userId)),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.richGold),
            child: Text(l10n.buyCoins, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Toggle to grid mode - called from MainNavigationScreen app bar
  void toggleGridMode() {
    setState(() {
      _isGridMode = !_isGridMode;
      _gridExtraPurchased = 0;
      // Don't clear overlays — they persist from swipe history
      // Snapshot the current index when entering grid mode so actions
      // dispatched to the bloc don't shrink the grid pool.
      if (_isGridMode) {
        final state = context.read<DiscoveryBloc>().state;
        if (state is DiscoveryLoaded) {
          _gridStartIndex = state.currentIndex;
        } else if (state is DiscoverySwiping) {
          _gridStartIndex = state.currentIndex;
        } else if (state is DiscoverySwipeCompleted) {
          _gridStartIndex = state.currentIndex;
        }
      }
    });
    widget.onGridModeChanged?.call();
  }

  /// Whether grid mode is active - used by MainNavigationScreen
  bool get isGridMode => _isGridMode;

  /// Current saved preferences - used by MainNavigationScreen
  MatchPreferences? get savedPreferences => _savedPreferences;

  /// Refresh the discovery stack
  void refresh() {
    _loadSavedPreferencesAndStart();
  }

  /// Refresh with new preferences — resets grid state and reloads stack
  void refreshWithPreferences(MatchPreferences preferences) {
    setState(() {
      _savedPreferences = preferences;
      // Reset grid position but keep action overlays (persistent)
      _gridStartIndex = 0;
      _gridExtraPurchased = 0;
      _onlineStatusOverrides.clear();
    });
    context.read<DiscoveryBloc>().add(
          DiscoveryStackRefreshRequested(
            userId: userId,
            preferences: preferences,
          ),
        );
  }

  // ───────────────────── Swipe Handlers ─────────────────────

  Future<void> _handleSwipe(BuildContext context, card, SwipeDirection direction) async {
    // Base membership gate
    final wasMember = _currentUserProfile?.isBaseMembershipActive ?? false;
    final allowed = await BaseMembershipGate.checkAndGate(
      context: context,
      profile: _currentUserProfile,
      userId: userId,
    );
    if (!allowed) return;
    if (!wasMember) await _loadCurrentUserProfile();

    debugPrint('_handleSwipe: direction=$direction, card.userId=${card.userId}');

    // Admin/support profiles cannot be noped/passed/skipped
    final isPrivileged = card.candidate.profile.isAdmin || card.candidate.profile.isSupport;
    if (isPrivileged && (direction == SwipeDirection.left || direction == SwipeDirection.down)) {
      return; // Silently ignore nope/skip on admin
    }

    SwipeActionType actionType;
    switch (direction) {
      case SwipeDirection.left:
        actionType = SwipeActionType.pass;
        break;
      case SwipeDirection.right:
        actionType = SwipeActionType.like;
        break;
      case SwipeDirection.up:
        actionType = SwipeActionType.superLike;
        break;
      case SwipeDirection.down:
        actionType = SwipeActionType.skip;
        break;
    }

    final tier = _currentUserProfile?.membershipTier ?? MembershipTier.free;
    final rules = MembershipRules.getDefaultsForTier(tier);
    debugPrint('Dispatching DiscoverySwipeRecorded: userId=$userId, target=${card.userId}, action=$actionType');
    context.read<DiscoveryBloc>().add(
          DiscoverySwipeRecorded(
            userId: userId,
            targetUserId: card.userId,
            actionType: actionType,
            membershipRules: rules,
            membershipTier: tier,
          ),
        );

    // Send notification to target user when super liked
    if (actionType == SwipeActionType.superLike) {
      _sendSuperLikeNotification(card.userId, card.displayName);
    }
  }

  void _handleRewind(BuildContext context) {
    context.read<DiscoveryBloc>().add(
          DiscoveryRewindRequested(userId: userId),
        );
  }

  void _handleRewindUnavailable(BuildContext context, String reason) {
    final l10n = AppLocalizations.of(context)!;
    switch (reason) {
      case 'no_previous':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.noPreviousProfile),
            duration: const Duration(seconds: 2),
          ),
        );
        break;
      case 'match_created':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.cantUndoMatched),
            duration: const Duration(seconds: 2),
          ),
        );
        break;
    }
  }

  void _handleSwipeFromProfile(BuildContext context, card, SwipeActionType actionType) {
    final tier = _currentUserProfile?.membershipTier ?? MembershipTier.free;
    final rules = MembershipRules.getDefaultsForTier(tier);
    context.read<DiscoveryBloc>().add(
          DiscoverySwipeRecorded(
            userId: userId,
            targetUserId: card.userId,
            actionType: actionType,
            membershipRules: rules,
            membershipTier: tier,
          ),
        );
  }

  void _showMatchDialog(BuildContext context, DiscoverySwipeCompleted state) async {
    // Find the matched user's profile from the cards list
    Profile? matchedProfile;
    if (state.matchedUserId != null) {
      try {
        final matchedCard = state.cards.firstWhere(
          (card) => card.userId == state.matchedUserId,
        );
        matchedProfile = matchedCard.candidate.profile;
      } catch (_) {
        // Card not found in list, try fetching from repository
        final profileRepo = di.sl<ProfileRepository>();
        final result = await profileRepo.getProfile(state.matchedUserId!);
        result.fold(
          (failure) => debugPrint('Could not fetch matched profile: ${failure.message}'),
          (profile) => matchedProfile = profile,
        );
      }
    }

    // Ensure current user profile is loaded
    if (_currentUserProfile == null) {
      await _loadCurrentUserProfile();
    }

    if (!mounted) return;

    if (_currentUserProfile != null && matchedProfile != null) {
      showMatchNotification(
        context,
        currentUserProfile: _currentUserProfile!,
        matchedProfile: matchedProfile!,
        onKeepSwiping: () {},
        onSendMessage: () {
          if (state.matchId != null) {
            final match = Match(
              matchId: state.matchId!,
              userId1: userId,
              userId2: state.matchedUserId!,
              matchedAt: DateTime.now(),
            );
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MatchDetailScreen(
                  match: match,
                  profile: matchedProfile,
                  currentUserId: userId,
                ),
              ),
            );
          }
        },
        onViewProfile: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProfileDetailScreen(
                profile: matchedProfile!,
                currentUserId: userId,
              ),
            ),
          );
        },
      );
    }
  }

  void _showInsufficientCoinsDialog(BuildContext context, DiscoveryInsufficientCoins state) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Row(
          children: [
            const Icon(Icons.monetization_on, color: AppColors.richGold),
            const SizedBox(width: 8),
            Text(
              l10n.insufficientCoins,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          '${state.featureName}: ${l10n.coinsRequired(state.required)}\n${l10n.coinsCost(state.available)}',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel, style: const TextStyle(color: AppColors.textTertiary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => CoinShopScreen(userId: userId)),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.richGold),
            child: Text(l10n.buyCoins, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _sendSuperLikeNotification(String targetUserId, String targetDisplayName) async {
    try {
      final notificationRepo = di.sl<NotificationRepository>();
      final senderName = _currentUserProfile?.displayName ?? 'Someone';
      final senderPhoto = _currentUserProfile?.photoUrls.isNotEmpty == true
          ? _currentUserProfile!.photoUrls.first
          : null;

      final l10n = AppLocalizations.of(context)!;
      await notificationRepo.createNotification(
        userId: targetUserId,
        type: NotificationType.superLike,
        title: l10n.youGotSuperLike,
        message: l10n.superLikedYou(senderName),
        data: {
          'senderUserId': userId,
          'senderDisplayName': senderName,
        },
        imageUrl: senderPhoto,
      );
    } catch (e) {
      debugPrint('Failed to send super like notification: $e');
    }
  }
}

// ───────────────────── Grid Profile Card Widget ─────────────────────

class _GridProfileCard extends StatefulWidget {
  final DiscoveryCard card;
  final int gridColumns;
  final String? actionOverlay; // 'liked', 'superLiked', 'matched'
  final bool? isOnlineOverride; // Refreshed online status (overrides profile.isOnline)
  final Function(DiscoveryCard, SwipeActionType) onAction;

  const _GridProfileCard({
    super.key,
    required this.card,
    required this.gridColumns,
    required this.onAction,
    this.actionOverlay,
    this.isOnlineOverride,
  });

  @override
  State<_GridProfileCard> createState() => _GridProfileCardState();
}

class _GridProfileCardState extends State<_GridProfileCard> {
  bool _showMenu = false;
  bool _showPreview = false;

  @override
  Widget build(BuildContext context) {
    final profile = widget.card.candidate.profile;
    final photoUrl = profile.photoUrls.isNotEmpty ? profile.photoUrls.first : null;
    final showText = widget.gridColumns <= 3;
    final location = profile.effectiveLocation;
    final distanceText = widget.card.candidate.distanceText;
    final cityText = location.city.isNotEmpty ? location.city : '';

    return GestureDetector(
      onTap: () {
        if (_showMenu || _showPreview) {
          setState(() { _showMenu = false; _showPreview = false; });
          return;
        }
        if (widget.actionOverlay != null) return;
        HapticFeedback.lightImpact();
        setState(() => _showMenu = true);
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        setState(() { _showMenu = false; _showPreview = true; });
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Profile image
            if (photoUrl != null && photoUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: photoUrl,
                fit: BoxFit.cover,
                memCacheWidth: 600,
                maxWidthDiskCache: 600,
                fadeInDuration: const Duration(milliseconds: 200),
                placeholder: (context, url) => Container(
                  color: AppColors.backgroundCard,
                  child: Center(
                    child: Icon(
                      Icons.person,
                      color: AppColors.textTertiary.withOpacity(0.5),
                      size: widget.gridColumns == 4 ? 32 : 48,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.backgroundCard,
                  child: Icon(
                    Icons.person,
                    color: AppColors.textTertiary.withOpacity(0.5),
                    size: widget.gridColumns == 4 ? 32 : 48,
                  ),
                ),
              )
            else
              Container(
                color: AppColors.backgroundCard,
                child: const Icon(Icons.person, color: AppColors.textTertiary, size: 40),
              ),

            // Online indicator (use refreshed status if available)
            if (widget.isOnlineOverride ?? profile.isOnline)
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.successGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),

                        // Action overlay (after action confirmed)
            if (widget.actionOverlay == 'liked')
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        AppColors.successGreen.withOpacity(0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              )
            else if (widget.actionOverlay == 'superLiked')
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        AppColors.richGold.withOpacity(0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              )
            else if (widget.actionOverlay == 'skipped')
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        AppColors.infoBlue.withOpacity(0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              )
            else if (widget.actionOverlay == 'passed')
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        AppColors.errorRed.withOpacity(0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              )
            else if (showText && !_showMenu && !_showPreview)
              // Default gradient for text readability
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.center,
                      colors: [
                        Colors.black.withOpacity(0.85),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

            // Match heart icon (top right)
            if (widget.actionOverlay == 'matched')
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.errorRed.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.errorRed.withOpacity(0.5),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.favorite, color: Colors.white, size: 14),
                ),
              ),

            // Distance badge (top left)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on, color: Colors.white70, size: 10),
                    const SizedBox(width: 2),
                    Text(
                      distanceText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Name, age, compatibility, and city (2-3 column mode)
            if (showText)
              Positioned(
                left: 6,
                right: 6,
                bottom: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.card.displayName}, ${widget.card.age}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.favorite, color: AppColors.richGold.withOpacity(0.8), size: 10),
                        const SizedBox(width: 3),
                        Text(
                          widget.card.matchPercentage,
                          style: TextStyle(
                            color: AppColors.richGold.withOpacity(0.9),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (cityText.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              cityText,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

            // Tier badge (top right) — all tiers except test
            if (profile.membershipTier != MembershipTier.test &&
                widget.actionOverlay != 'matched')
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: switch (profile.membershipTier) {
                        MembershipTier.silver => [const Color(0xFFC0C0C0), const Color(0xFF8E8E8E)],
                        MembershipTier.gold => [const Color(0xFFFFD700), const Color(0xFFDAA520)],
                        MembershipTier.platinum => [AppColors.platinumBlue, AppColors.platinumBlueDark],
                        MembershipTier.free => [AppColors.basePurple, AppColors.basePurpleDark],
                        _ => [Colors.grey, Colors.grey],
                      },
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    switch (profile.membershipTier) {
                      MembershipTier.free => 'B',
                      MembershipTier.silver => 'S',
                      MembershipTier.gold => 'G',
                      MembershipTier.platinum => 'P',
                      _ => '',
                    },
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: profile.membershipTier == MembershipTier.gold
                          ? const Color(0xFF5D4200)
                          : Colors.white,
                    ),
                  ),
                ),
              ),

            // Traveler badge (top right, below tier badge if present)
            if (profile.isTravelerActive && widget.actionOverlay != 'matched')
              Positioned(
                top: profile.membershipTier != MembershipTier.free &&
                     profile.membershipTier != MembershipTier.test ? 24 : 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flight, size: 10, color: Colors.white),
                      SizedBox(width: 2),
                      Text(
                        'Travel',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Tap action menu overlay - just 4 action buttons
            if (_showMenu)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => _showMenu = false),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.black.withOpacity(0.6),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildInCardAction(Icons.close, AppColors.errorRed, () {
                              setState(() => _showMenu = false);
                              widget.onAction(widget.card, SwipeActionType.pass);
                            }),
                            _buildInCardAction(Icons.arrow_downward, AppColors.infoBlue, () {
                              setState(() => _showMenu = false);
                              widget.onAction(widget.card, SwipeActionType.skip);
                            }),
                            _buildInCardAction(Icons.star, AppColors.richGold, () {
                              setState(() => _showMenu = false);
                              widget.onAction(widget.card, SwipeActionType.superLike);
                            }),
                            _buildInCardAction(Icons.favorite, AppColors.successGreen, () {
                              setState(() => _showMenu = false);
                              widget.onAction(widget.card, SwipeActionType.like);
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Long-press preview overlay - full info like swipe card + actions
            if (_showPreview)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => _showPreview = false),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        stops: const [0.0, 0.7, 1.0],
                        colors: [
                          Colors.black.withOpacity(0.95),
                          Colors.black.withOpacity(0.7),
                          Colors.black.withOpacity(0.4),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(widget.gridColumns == 4 ? 6 : 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Spacer(),
                          // Name and age
                          Text(
                            '${widget.card.displayName}, ${widget.card.age}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: widget.gridColumns == 4 ? 12 : 15,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: widget.gridColumns == 4 ? 3 : 5),
                          // Distance & city
                          Row(
                            children: [
                              Icon(
                                profile.isTravelerActive ? Icons.flight : Icons.location_on,
                                color: Colors.white70,
                                size: widget.gridColumns == 4 ? 10 : 12,
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  cityText.isNotEmpty ? '$distanceText · $cityText' : distanceText,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: widget.gridColumns == 4 ? 9 : 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: widget.gridColumns == 4 ? 2 : 4),
                          // Match %
                          Row(
                            children: [
                              Icon(Icons.favorite, color: AppColors.richGold, size: widget.gridColumns == 4 ? 10 : 12),
                              const SizedBox(width: 3),
                              Text(
                                '${widget.card.matchPercentage} match',
                                style: TextStyle(
                                  color: AppColors.richGold,
                                  fontSize: widget.gridColumns == 4 ? 9 : 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          // Languages (only on 2-3 cols)
                          if (widget.gridColumns <= 3 && profile.languages.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.translate, color: Colors.white70, size: 12),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    profile.languages.take(3).join(', '),
                                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          // Interests (only on 2-3 cols)
                          if (widget.gridColumns <= 3 && profile.interests.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 4,
                              runSpacing: 3,
                              children: profile.interests.take(3).map((i) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(i, style: const TextStyle(color: Colors.white, fontSize: 9)),
                                );
                              }).toList(),
                            ),
                          ],
                          // Bio snippet (only on 2 cols)
                          if (widget.gridColumns == 2 && widget.card.bioPreview.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.card.bioPreview,
                              style: const TextStyle(color: Colors.white54, fontSize: 10, height: 1.2),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          SizedBox(height: widget.gridColumns == 4 ? 6 : 10),
                          // Action buttons row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildInCardAction(Icons.close, AppColors.errorRed, () {
                                setState(() => _showPreview = false);
                                widget.onAction(widget.card, SwipeActionType.pass);
                              }),
                              _buildInCardAction(Icons.arrow_downward, AppColors.infoBlue, () {
                                setState(() => _showPreview = false);
                                widget.onAction(widget.card, SwipeActionType.skip);
                              }),
                              _buildInCardAction(Icons.star, AppColors.richGold, () {
                                setState(() => _showPreview = false);
                                widget.onAction(widget.card, SwipeActionType.superLike);
                              }),
                              _buildInCardAction(Icons.favorite, AppColors.successGreen, () {
                                setState(() => _showPreview = false);
                                widget.onAction(widget.card, SwipeActionType.like);
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInCardAction(IconData icon, Color color, VoidCallback onTap) {
    final btnSize = widget.gridColumns == 4 ? 26.0 : 34.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: btnSize,
        height: btnSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
        child: Icon(icon, color: color, size: btnSize * 0.5),
      ),
    );
  }
}
