import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../domain/entities/match_preferences.dart';
import '../../../matching/domain/repositories/matching_repository.dart';
import '../../domain/entities/swipe_action.dart';
import '../bloc/discovery_bloc.dart';
import '../bloc/discovery_event.dart';
import '../bloc/discovery_state.dart';
import '../widgets/swipe_card.dart';
import '../widgets/swipe_buttons.dart';
import '../widgets/match_notification.dart';
import 'discovery_preferences_screen.dart';
import 'profile_detail_screen.dart';
import '../widgets/nickname_search_dialog.dart';

/// Discovery Screen
///
/// Main screen for browsing and swiping through potential matches
class DiscoveryScreen extends StatelessWidget {
  final String userId;

  const DiscoveryScreen({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<DiscoveryBloc>()
        ..add(DiscoveryStackLoadRequested(
          userId: userId,
          preferences: MatchPreferences.defaultFor(userId),
        )),
      child: _DiscoveryScreenContent(userId: userId),
    );
  }
}

class _DiscoveryScreenContent extends StatelessWidget {
  final String userId;

  const _DiscoveryScreenContent({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: BlocConsumer<DiscoveryBloc, DiscoveryState>(
          listener: (context, state) {
            if (state is DiscoverySwipeCompleted && state.createdMatch) {
              // Show match notification
              // Note: In production, fetch the matched profile
              _showMatchDialog(context);
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

            if (state is DiscoveryLoaded || state is DiscoverySwiping) {
              final loadedState = state is DiscoveryLoaded
                  ? state
                  : (state as DiscoverySwiping);

              final cards = state is DiscoveryLoaded
                  ? state.cards
                  : (state as DiscoverySwiping).cards;

              final currentIndex = state is DiscoveryLoaded
                  ? state.currentIndex
                  : (state as DiscoverySwiping).currentIndex;

              if (currentIndex >= cards.length) {
                return _buildEmptyState(context);
              }

              return Column(
                children: [
                  // Header
                  _buildHeader(context),

                  // Card stack
                  Expanded(
                    child: _buildCardStack(
                      context,
                      cards,
                      currentIndex,
                      state is! DiscoverySwiping,
                    ),
                  ),

                  // Action buttons
                  _buildActionButtons(
                    context,
                    cards[currentIndex],
                    state is! DiscoverySwiping,
                  ),

                  const SizedBox(height: 24),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
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
                      preferences: MatchPreferences.defaultFor(userId),
                    ),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.richGold,
              foregroundColor: AppColors.deepBlack,
            ),
            child: const Text('Retry'),
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
          const Text(
            "There's no others to see",
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Check back later for new people, or adjust your preferences',
              style: TextStyle(
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
                    onSave: (preferences) {
                      context.read<DiscoveryBloc>().add(
                            DiscoveryStackRefreshRequested(
                              userId: userId,
                              preferences: preferences,
                            ),
                          );
                    },
                  ),
                ),
              );
            },
            icon: const Icon(Icons.tune),
            label: const Text('Adjust Preferences'),
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
    return Stack(
      alignment: Alignment.center,
      children: [
        // Next card (behind)
        if (currentIndex + 1 < cards.length)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: SwipeCard(
              card: cards[currentIndex + 1],
              isFront: false,
            ),
          ),

        // Current card (front)
        SwipeCard(
          card: cards[currentIndex],
          isFront: true,
          onSwipe: enabled
              ? (direction) => _handleSwipe(context, cards[currentIndex], direction)
              : null,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ProfileDetailScreen(
                  profile: cards[currentIndex].candidate.profile,
                  currentUserId: userId,
                  onSwipe: (actionType) {
                    _handleSwipeFromProfile(context, cards[currentIndex], actionType);
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, card, bool enabled) {
    return SwipeButtons(
      enabled: enabled,
      onPass: () => _handleSwipe(context, card, SwipeDirection.left),
      onSuperLike: () => _handleSwipe(context, card, SwipeDirection.up),
      onLike: () => _handleSwipe(context, card, SwipeDirection.right),
    );
  }

  void _handleSwipe(BuildContext context, card, SwipeDirection direction) {
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
    }

    context.read<DiscoveryBloc>().add(
          DiscoverySwipeRecorded(
            userId: userId,
            targetUserId: card.userId,
            actionType: actionType,
          ),
        );
  }

  void _handleSwipeFromProfile(BuildContext context, card, SwipeActionType actionType) {
    context.read<DiscoveryBloc>().add(
          DiscoverySwipeRecorded(
            userId: userId,
            targetUserId: card.userId,
            actionType: actionType,
          ),
        );
  }

  void _showMatchDialog(BuildContext context) {
    // TODO: Fetch actual matched profile
    // For now, showing placeholder
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text(
          "It's a Match!",
          style: TextStyle(color: AppColors.richGold),
        ),
        content: const Text(
          'You have a new match!',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Keep Swiping',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Navigate to chat
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.richGold,
              foregroundColor: AppColors.deepBlack,
            ),
            child: const Text('Send Message'),
          ),
        ],
      ),
    );
  }
}
