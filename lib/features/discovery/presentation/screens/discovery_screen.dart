import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../domain/entities/match_preferences.dart';
import '../../../matching/domain/repositories/matching_repository.dart';
import '../../domain/entities/swipe_action.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../../notifications/domain/entities/notification.dart';
import '../../../notifications/domain/repositories/notification_repository.dart';
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

class _DiscoveryScreenContent extends StatefulWidget {
  final String userId;

  const _DiscoveryScreenContent({required this.userId});

  @override
  State<_DiscoveryScreenContent> createState() => _DiscoveryScreenContentState();
}

class _DiscoveryScreenContentState extends State<_DiscoveryScreenContent> {
  final ValueNotifier<double> _dragProgress = ValueNotifier(0.0);
  Profile? _currentUserProfile;

  String get userId => widget.userId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserProfile();
  }

  Future<void> _loadCurrentUserProfile() async {
    final profileRepo = di.sl<ProfileRepository>();
    final result = await profileRepo.getProfile(userId);
    result.fold(
      (failure) => debugPrint('Could not load current user profile: ${failure.message}'),
      (profile) {
        if (mounted) {
          setState(() => _currentUserProfile = profile);
        }
      },
    );
  }

  @override
  void dispose() {
    _dragProgress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: BlocConsumer<DiscoveryBloc, DiscoveryState>(
          listener: (context, state) {
            if (state is DiscoverySwipeCompleted && state.createdMatch) {
              _showMatchDialog(context, state);
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
        // Next card (behind) with parallax effect
        if (currentIndex + 1 < cards.length)
          ValueListenableBuilder<double>(
            valueListenable: _dragProgress,
            builder: (context, progress, child) {
              final scale = 0.92 + (0.08 * progress); // 0.92 → 1.0
              final offset = 30.0 * (1.0 - progress); // 30 → 0
              final opacity = 0.6 + (0.4 * progress); // 0.6 → 1.0
              return Transform.translate(
                offset: Offset(0, offset),
                child: Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: opacity,
                    child: child!,
                  ),
                ),
              );
            },
            child: SwipeCard(
              card: cards[currentIndex + 1],
              isFront: false,
            ),
          ),

        // Current card (front)
        SwipeCard(
          card: cards[currentIndex],
          isFront: true,
          onDragProgress: (progress) {
            _dragProgress.value = progress;
          },
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
      onSkip: () => _handleSwipe(context, card, SwipeDirection.down),
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
      case SwipeDirection.down:
        actionType = SwipeActionType.pass;
        break;
    }

    context.read<DiscoveryBloc>().add(
          DiscoverySwipeRecorded(
            userId: userId,
            targetUserId: card.userId,
            actionType: actionType,
          ),
        );

    // Send notification to target user when super liked
    if (actionType == SwipeActionType.superLike) {
      _sendSuperLikeNotification(card.userId, card.displayName);
    }
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
          // TODO: Navigate to chat with matched user
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

  Future<void> _sendSuperLikeNotification(String targetUserId, String targetDisplayName) async {
    try {
      final notificationRepo = di.sl<NotificationRepository>();
      final senderName = _currentUserProfile?.displayName ?? 'Someone';
      final senderPhoto = _currentUserProfile?.photoUrls.isNotEmpty == true
          ? _currentUserProfile!.photoUrls.first
          : null;

      await notificationRepo.createNotification(
        userId: targetUserId,
        type: NotificationType.superLike,
        title: 'You got a Super Like!',
        message: '$senderName super liked you!',
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
