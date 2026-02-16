import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/feature_flags_service.dart';
import '../../../../core/services/access_control_service.dart';
import '../../../../core/services/activity_tracking_service.dart';
import '../../../../core/services/subscription_expiry_service.dart';
import '../../../../core/widgets/countdown_blur_overlay.dart';
import '../../../../core/widgets/membership_badge.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../discovery/presentation/screens/discovery_screen.dart';
import '../../../discovery/presentation/screens/matches_screen.dart';
import '../../../discovery/presentation/screens/discovery_preferences_screen.dart';
import '../../../discovery/presentation/widgets/nickname_search_dialog.dart';
import '../../../chat/presentation/screens/conversations_screen.dart';
import '../../../coins/presentation/screens/coin_shop_screen.dart';
import '../../../coins/presentation/bloc/coin_bloc.dart';
import '../../../coins/presentation/bloc/coin_event.dart';
import '../../../coins/presentation/bloc/coin_state.dart';
import '../../../coins/domain/entities/coin_balance.dart';
import '../../../membership/domain/entities/membership.dart';
import '../../../profile/presentation/screens/edit_profile_screen.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_event.dart';
import '../../../profile/presentation/bloc/profile_state.dart';
import '../../../profile/presentation/screens/onboarding_screen.dart' as profile;
import '../../../profile/presentation/widgets/verification_status_widget.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../../notifications/presentation/bloc/notifications_bloc.dart';
import '../../../notifications/presentation/bloc/notifications_event.dart';
import '../../../notifications/presentation/bloc/notifications_state.dart';
import '../../../notifications/domain/entities/notification.dart' as notif;
import '../../../subscription/presentation/screens/subscription_selection_screen.dart';
import '../../../subscription/presentation/bloc/subscription_bloc.dart';
// Language Learning imports - only used when feature is enabled
import '../../../language_learning/presentation/screens/language_learning_home_screen.dart';
import '../../../language_learning/presentation/bloc/language_learning_bloc.dart';
// Gamification/Progress imports
import '../../../gamification/presentation/screens/progress_screen.dart';
import '../../../gamification/presentation/bloc/gamification_bloc.dart';
import '../../../gamification/presentation/bloc/gamification_event.dart';
import '../../../gamification/presentation/bloc/gamification_state.dart';
import '../../../gamification/presentation/widgets/level_up_celebration_dialog.dart';
// App Tour imports
import '../../../app_tour/presentation/widgets/tour_overlay.dart';
import '../../../../generated/app_localizations.dart';

/// Main Navigation Screen
///
/// Bottom navigation with Discovery, Matches, Messages, and Profile tabs
class MainNavigationScreen extends StatefulWidget {
  final String userId;

  const MainNavigationScreen({
    super.key,
    required this.userId,
  });

  @override
  MainNavigationScreenState createState() => MainNavigationScreenState();
}

class MainNavigationScreenState extends State<MainNavigationScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _isCheckingProfile = true;
  VerificationStatus _verificationStatus = VerificationStatus.notSubmitted;
  String? _verificationRejectionReason;
  bool _isAdmin = false;

  // Access control state
  UserAccessData? _accessData;
  late final AccessControlService _accessControlService;
  bool _hasShownApprovalNotification = false;
  bool _hasShownAccessGrantedNotification = false;

  // Activity tracking for re-engagement notifications
  late final ActivityTrackingService _activityTrackingService;

  late List<Widget> _screens;
  late final NotificationsBloc _notificationsBloc;

  // Coin balance bloc for app bar
  late final CoinBloc _coinBloc;

  // Profile bloc for shared profile state across screens
  late final ProfileBloc _profileBloc;

  // User's membership tier
  MembershipTier _membershipTier = MembershipTier.free;

  // State de-duplication to prevent cascading rebuilds (black screen fix)
  MembershipTier? _lastProcessedTier;
  bool _isProcessingState = false;

  // Global gamification bloc for level-up celebrations (only when enabled)
  GamificationBloc? _gamificationBloc;

  // App tour state
  bool _showTour = false;
  static const String _tourPrefKey = 'has_completed_app_tour';

  @override
  void initState() {
    super.initState();

    // Initialize access control service
    _accessControlService = AccessControlService();

    // Initialize activity tracking for re-engagement notifications
    _activityTrackingService = ActivityTrackingService();
    _activityTrackingService.startTracking();
    WidgetsBinding.instance.addObserver(this);

    // Initialize gamification bloc (only when enabled)
    if (AppConfig.enableGamification) {
      _gamificationBloc = di.sl<GamificationBloc>()
        ..add(LoadUserLevel(widget.userId));
    }

    // Initialize notifications bloc for badge count
    _notificationsBloc = di.sl<NotificationsBloc>()
      ..add(NotificationsLoadRequested(
        userId: widget.userId,
        unreadOnly: true,
      ));

    // Initialize coin bloc for balance display in app bar
    _coinBloc = di.sl<CoinBloc>()
      ..add(SubscribeToCoinBalance(widget.userId));

    // Initialize profile bloc for shared profile state (MUST be before _screens)
    _profileBloc = di.sl<ProfileBloc>()
      ..add(ProfileLoadRequested(userId: widget.userId));

    // Build screens list based on enabled features from Firestore
    // MVP: Discover, Matches, Messages, Shop, Progress, Profile (6 tabs)
    // With Learning: Discover, Matches, Messages, Shop, Progress, Learn, Profile (7 tabs)
    // Note: Progress placeholder is built via getter to ensure proper context
    _screens = [
      DiscoveryScreen(userId: widget.userId),
      MatchesScreen(userId: widget.userId),
      ConversationsScreen(userId: widget.userId),
      CoinShopScreen(userId: widget.userId),
      if (_gamificationBloc != null)
        BlocProvider.value(
          value: _gamificationBloc!,
          child: ProgressScreen(userId: widget.userId),
        )
      else
        const _GamificationPlaceholderScreen(),
      if (featureFlags.languageLearningEnabled)
        BlocProvider(
          create: (context) => di.sl<LanguageLearningBloc>(),
          child: const LanguageLearningHomeScreen(),
        ),
      BlocProvider.value(
        value: _profileBloc,
        child: EditProfileScreen(userId: widget.userId),
      ),
    ];

    // Check if user has a profile, redirect to onboarding if not
    _checkUserProfile();

    // Load access control data
    _loadAccessData();

    // Check subscription expiry and downgrade to free if expired
    _checkSubscriptionExpiry();

    // Check if app tour should be shown
    _checkAppTour();
  }

  Future<void> _checkAppTour() async {
    final prefs = await SharedPreferences.getInstance();
    final hasCompletedTour = prefs.getBool(_tourPrefKey) ?? false;
    if (!hasCompletedTour && mounted) {
      // Delay tour to let the app load first
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _showTour = true;
          });
        }
      });
    }
  }

  Future<void> _completeTour() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tourPrefKey, true);
    if (mounted) {
      setState(() {
        _showTour = false;
      });
    }
  }

  void _skipTour() {
    _completeTour();
  }

  Future<void> _loadAccessData() async {
    final accessData = await _accessControlService.getCurrentUserAccess();
    if (mounted && accessData != null) {
      setState(() {
        _accessData = accessData;
      });

      // Check and show notifications based on access state
      _checkAndShowAccessNotifications(accessData);
    }
  }

  Future<void> _checkSubscriptionExpiry() async {
    final expiryService = SubscriptionExpiryService();

    // Check and handle expired subscriptions (rollback to free)
    final previousTier = await expiryService.checkAndHandleExpiry(widget.userId);

    if (previousTier != null && mounted) {
      // Subscription was expired - show downgrade dialog
      _showDowngradeDialog(previousTier);

      // Refresh profile to reflect free tier
      _profileBloc.add(ProfileLoadRequested(userId: widget.userId));

      // Update local membership tier
      setState(() {
        _membershipTier = MembershipTier.free;
      });
    }

    // Grant 1 bonus month on release (only once per user, only after release date)
    final releaseDate = AccessControlService.generalAccessDate;
    if (DateTime.now().isAfter(releaseDate)) {
      await expiryService.grantReleaseBonusMonth(widget.userId);
    }
  }

  void _showDowngradeDialog(String previousTierName) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text(
          'Subscription Expired',
          style: TextStyle(color: AppColors.richGold),
        ),
        content: Text(
          'Your $previousTierName subscription has expired. '
          'You have been moved to the Free tier.\n\n'
          'Upgrade anytime to restore your premium features!',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Navigate to subscription screen
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => BlocProvider(
                    create: (context) => di.sl<SubscriptionBloc>(),
                    child: const SubscriptionSelectionScreen(),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.richGold,
              foregroundColor: AppColors.deepBlack,
            ),
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkAndShowAccessNotifications(UserAccessData accessData) async {
    // Show approval notification if user was just approved
    if (accessData.approvalStatus == ApprovalStatus.approved &&
        !_hasShownApprovalNotification) {
      _hasShownApprovalNotification = true;
      await _createApprovalNotification();
    }

    // Show access granted notification if access date has arrived
    if (accessData.approvalStatus == ApprovalStatus.approved &&
        accessData.canAccessApp &&
        !_hasShownAccessGrantedNotification) {
      _hasShownAccessGrantedNotification = true;
      await _createAccessGrantedNotification();
    }
  }

  Future<void> _createApprovalNotification() async {
    try {
      final notificationData = {
        'userId': widget.userId,
        'type': 'system',
        'title': 'Account Approved!',
        'body': 'Your GreenGo account has been approved. Welcome to the community!',
        'data': {'action': 'approval'},
        'createdAt': Timestamp.now(),
        'isRead': false,
      };

      await FirebaseFirestore.instance
          .collection('notifications')
          .add(notificationData);
    } catch (e) {
      // Silently handle notification creation errors
    }
  }

  Future<void> _createAccessGrantedNotification() async {
    try {
      final tierName = _accessData?.membershipTier.name ?? 'member';
      final notificationData = {
        'userId': widget.userId,
        'type': 'system',
        'title': 'Access Granted!',
        'body': 'GreenGo is now live! As a $tierName, you now have full access to all features.',
        'data': {'action': 'access_granted'},
        'createdAt': Timestamp.now(),
        'isRead': false,
      };

      await FirebaseFirestore.instance
          .collection('notifications')
          .add(notificationData);
    } catch (e) {
      // Silently handle notification creation errors
    }
  }

  void _navigateToSettings() {
    // Navigate to Profile/Settings tab
    // Tabs: Discover(0), Matches(1), Messages(2), Shop(3), Progress(4), [Learn(5)], Profile(5 or 6)
    final profileIndex = featureFlags.languageLearningEnabled ? 6 : 5;
    setState(() {
      _currentIndex = profileIndex;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        _activityTrackingService.startTracking();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _activityTrackingService.stopTracking();
        break;
    }
  }

  Future<void> _checkUserProfile() async {
    try {
      final profileDoc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(widget.userId)
          .get();

      if (!mounted) return;

      if (!profileDoc.exists) {
        // User doesn't have a profile, redirect to onboarding
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => profile.OnboardingScreen(userId: widget.userId),
          ),
        );
      } else {
        // Check verification status
        final data = profileDoc.data()!;
        final statusString = data['verificationStatus'] as String?;
        VerificationStatus status = VerificationStatus.notSubmitted;

        switch (statusString) {
          case 'pending':
            status = VerificationStatus.pending;
            break;
          case 'approved':
            status = VerificationStatus.approved;
            break;
          case 'rejected':
            status = VerificationStatus.rejected;
            break;
          case 'needsResubmission':
            status = VerificationStatus.needsResubmission;
            break;
          default:
            status = VerificationStatus.notSubmitted;
        }

        // Get membership tier
        final membershipTierString = data['membershipTier'] as String?;
        MembershipTier membershipTier = MembershipTier.free;
        if (membershipTierString != null) {
          membershipTier = MembershipTier.fromString(membershipTierString);
        }

        setState(() {
          _verificationStatus = status;
          _verificationRejectionReason = data['verificationRejectionReason'] as String?;
          _isAdmin = data['isAdmin'] as bool? ?? false;
          _membershipTier = membershipTier;
          _isCheckingProfile = false;
        });
      }
    } catch (e) {
      // On error, assume profile exists and show main screen
      if (mounted) {
        setState(() {
          _isCheckingProfile = false;
        });
      }
    }
  }

  void _navigateToVerification() {
    // Navigate to onboarding verification step
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => profile.OnboardingScreen(userId: widget.userId),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _activityTrackingService.dispose();
    _notificationsBloc.close();
    _coinBloc.close();
    _profileBloc.close();
    _gamificationBloc?.close();
    super.dispose();
  }

  void _onTabTapped(int index) {
    // Ensure index is within valid bounds
    if (index < 0 || index >= _screens.length) {
      return;
    }
    setState(() {
      _currentIndex = index;
    });
  }

  /// Refresh the discovery tab by rebuilding the DiscoveryScreen with a new key
  void refreshDiscoveryTab() {
    setState(() {
      _currentIndex = 0;
      _screens = List.from(_screens);
      _screens[0] = DiscoveryScreen(key: UniqueKey(), userId: widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while checking profile
    if (_isCheckingProfile) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: const Center(
          child: CircularProgressIndicator(
            color: AppColors.richGold,
          ),
        ),
      );
    }

    // Check if user is approved but before access date (pre-launch mode)
    // Admin and test users bypass ALL restrictions (countdown, approval, verification)
    final isAdminOrTestUser = _isAdmin ||
        (_accessData?.isAdmin ?? false) ||
        (_accessData?.isTestUser ?? false);

    final isPreLaunchBlocked = !isAdminOrTestUser &&
        _accessData != null &&
        _accessData!.approvalStatus == ApprovalStatus.approved &&
        !_accessData!.canAccessApp;

    // Tabs: Discover(0), Matches(1), Messages(2), Shop(3), Progress(4), [Learn(5)], Profile(5 or 6)
    final profileIndex = featureFlags.languageLearningEnabled ? 6 : 5;
    final progressIndex = 4;
    final learnIndex = featureFlags.languageLearningEnabled ? 5 : -1;

    // Ensure current index is valid
    final safeIndex = _currentIndex.clamp(0, _screens.length - 1);

    final scaffold = Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: safeIndex,
        children: _screens.asMap().entries.map((entry) {
          final index = entry.key;
          final screen = entry.value;

          // Profile is always the last tab
          // Shop is index 3, Progress is index 4
          // Learn is index 5 (only if enabled)
          // Profile is index 5 (MVP) or 6 (with Learning)

          // Profile/Settings is always accessible (no overlays)
          if (index == profileIndex) {
            return screen;
          }

          // For pre-launch blocked users: show countdown overlay on ALL other screens
          if (isPreLaunchBlocked) {
            return CountdownBlurOverlay(
              accessData: _accessData!,
              onSettingsTapped: _navigateToSettings,
              child: screen,
            );
          }

          // Shop, Progress, and Learn (if enabled) don't need verification overlay
          if (index == 3 || index == progressIndex || index == learnIndex) {
            return screen;
          }

          // Admin and test users bypass verification overlay
          if (isAdminOrTestUser) {
            return screen;
          }

          // Wrap other screens with verification overlay
          return VerificationBlockedOverlay(
            status: _verificationStatus,
            rejectionReason: _verificationRejectionReason,
            onVerifyNow: _navigateToVerification,
            child: screen,
          );
        }).toList(),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppColors.divider,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: safeIndex,
          onTap: _onTabTapped,
          backgroundColor: AppColors.backgroundCard,
          selectedItemColor: AppColors.richGold,
          unselectedItemColor: AppColors.textTertiary,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.explore_outlined),
              activeIcon: const Icon(Icons.explore),
              label: AppLocalizations.of(context)!.discover,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.favorite_outline),
              activeIcon: const Icon(Icons.favorite),
              label: AppLocalizations.of(context)!.matches,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.chat_bubble_outline),
              activeIcon: const Icon(Icons.chat_bubble),
              label: AppLocalizations.of(context)!.messages,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.store_outlined),
              activeIcon: const Icon(Icons.store),
              label: AppLocalizations.of(context)!.shop,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.emoji_events_outlined),
              activeIcon: const Icon(Icons.emoji_events),
              label: AppLocalizations.of(context)!.progress,
            ),
            // Only show Learn tab if language learning is enabled
            if (featureFlags.languageLearningEnabled)
              BottomNavigationBarItem(
                icon: const Icon(Icons.school_outlined),
                activeIcon: const Icon(Icons.school),
                label: AppLocalizations.of(context)!.learn,
              ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: AppLocalizations.of(context)!.profile,
            ),
          ],
        ),
      ),
    );

    // Wrap with red border if admin is logged in
    // Also wrap with PopScope to handle back button
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // If not on the first tab, go back to first tab
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
          return;
        }

        // On first tab, show exit confirmation
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.backgroundCard,
            title: Text(
              AppLocalizations.of(context)!.exitApp,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            content: Text(
              AppLocalizations.of(context)!.exitAppConfirmation,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  AppLocalizations.of(context)!.cancel,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  AppLocalizations.of(context)!.exit,
                  style: const TextStyle(color: AppColors.richGold),
                ),
              ),
            ],
          ),
        );

        if (shouldExit == true) {
          // Use SystemNavigator.pop() to properly exit the app
          // Navigator.pop() doesn't work here because MainNavigationScreen
          // is the root screen (not pushed onto the stack)
          SystemNavigator.pop();
        }
      },
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _notificationsBloc),
          BlocProvider.value(value: _coinBloc),
          BlocProvider.value(value: _profileBloc),
          if (_gamificationBloc != null)
            BlocProvider.value(value: _gamificationBloc!),
        ],
        child: BlocListener<ProfileBloc, ProfileState>(
          listenWhen: (previous, current) {
            // Only listen when tier actually changes (prevents cascading rebuilds)
            if (current is ProfileLoaded) {
              return _lastProcessedTier != current.profile.membershipTier;
            }
            if (current is ProfileUpdated) {
              return _lastProcessedTier != current.profile.membershipTier;
            }
            return false;
          },
          listener: (context, state) {
            // Guard against concurrent processing and unmounted widget
            if (_isProcessingState || !mounted) return;
            _isProcessingState = true;

            // Update membership tier when profile is loaded or updated
            if (state is ProfileLoaded) {
              _lastProcessedTier = state.profile.membershipTier;
              setState(() {
                _membershipTier = state.profile.membershipTier;
              });
            } else if (state is ProfileUpdated) {
              _lastProcessedTier = state.profile.membershipTier;
              setState(() {
                _membershipTier = state.profile.membershipTier;
              });
            }

            _isProcessingState = false;
          },
          child: _gamificationBloc != null
              ? BlocListener<GamificationBloc, GamificationState>(
                  listener: (context, state) {
                    // Show level-up celebration dialog when user levels up
                    if (state.leveledUp && state.userLevel != null) {
                      LevelUpCelebrationDialog.show(
                        context,
                        newLevel: state.userLevel!.level,
                        previousLevel: state.previousLevel ?? (state.userLevel!.level - 1),
                        rewards: state.pendingRewards,
                        isVIP: state.userLevel!.isVIP,
                        onDismiss: () {
                          // Clear the level-up flag after showing dialog
                          _gamificationBloc!.add(const ClearLevelUpFlag());
                        },
                      );
                    }
                  },
                  child: _buildMainContent(scaffold),
                )
              : _buildMainContent(scaffold),
        ),
      ),
    );
  }

  Widget _buildMainContent(Widget scaffold) {
    return Stack(
      children: [
        _isAdmin
            ? Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.errorRed,
                    width: 4,
                  ),
                ),
                child: scaffold,
              )
            : scaffold,

        // App Tour Overlay
        if (_showTour)
          TourOverlay(
            onComplete: _completeTour,
            onSkip: _skipTour,
            onTabChange: (tabIndex) {
              setState(() {
                _currentIndex = tabIndex;
              });
            },
          ),
      ],
    );
  }

  PreferredSizeWidget? _buildAppBar() {
    // Only show app bar on certain tabs
    // Tab indexes: 0=Discover, 1=Matches, 2=Messages, 3=Shop, 4=Progress, 5=Profile (MVP)
    // With Learning: 0=Discover, 1=Matches, 2=Messages, 3=Shop, 4=Progress, 5=Learn, 6=Profile
    if (_currentIndex == 0) {
      // Discovery screen - show logo with preferences, search, coins, notifications, and membership badge
      return AppBar(
        title: const Text(
          'GreenGo',
          style: TextStyle(
            color: AppColors.richGold,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.tune, color: AppColors.textSecondary),
          onPressed: _openDiscoveryPreferences,
          tooltip: 'Discovery Preferences',
        ),
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textSecondary),
            onPressed: _showNicknameSearch,
            tooltip: 'Search by nickname',
          ),
          _buildCoinBalanceWidget(),
          const SizedBox(width: 4),
          _buildMembershipBadgeWidget(),
          const SizedBox(width: 8),
        ],
      );
    } else if (_currentIndex == 1 || _currentIndex == 2) {
      // Matches and Messages - show title and coin balance + notifications + membership badge
      return AppBar(
        title: Text(
          _currentIndex == 1 ? 'Matches' : 'Messages',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        actions: [
          _buildCoinBalanceWidget(),
          const SizedBox(width: 4),
          _buildMembershipBadgeWidget(),
          const SizedBox(width: 8),
        ],
      );
    }
    // Shop, Progress, Learn (if enabled), and Profile - no app bar (have their own)
    return null;
  }

  void _openDiscoveryPreferences() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DiscoveryPreferencesScreen(
          userId: widget.userId,
          onSave: (preferences) {
            // Refresh the discovery stack when preferences change
          },
        ),
      ),
    );
  }

  void _showNicknameSearch() {
    NicknameSearchDialog.show(context, widget.userId);
  }

  Widget _buildNotificationButton() {
    return BlocBuilder<NotificationsBloc, NotificationsState>(
      builder: (context, state) {
        int unreadCount = 0;
        if (state is NotificationsLoaded) {
          unreadCount = state.unreadCount;
        }

        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        NotificationsScreen(userId: widget.userId),
                  ),
                );
              },
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.errorRed,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Coin balance widget for app bar
  Widget _buildCoinBalanceWidget() {
    return BlocBuilder<CoinBloc, CoinState>(
      builder: (context, state) {
        int coinBalance = 0;
        if (state is CoinBalanceLoaded) {
          coinBalance = state.balance.availableCoins;
        } else if (state is CoinBalanceUpdated) {
          coinBalance = state.balance.availableCoins;
        }

        return GestureDetector(
          onTap: () {
            // Navigate to Shop tab (index 3)
            setState(() {
              _currentIndex = 3;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.3),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.monetization_on,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatCoinBalance(coinBalance),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatCoinBalance(int balance) {
    if (balance >= 1000000) {
      return '${(balance / 1000000).toStringAsFixed(1)}M';
    } else if (balance >= 1000) {
      return '${(balance / 1000).toStringAsFixed(1)}K';
    }
    return balance.toString();
  }

  /// Membership badge widget for app bar
  Widget _buildMembershipBadgeWidget() {
    return MembershipIndicator(
      tier: _membershipTier,
      onTap: () {
        // Navigate to subscription screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlocProvider(
              create: (context) => di.sl<SubscriptionBloc>(),
              child: const SubscriptionSelectionScreen(),
            ),
          ),
        );
      },
    );
  }

}

/// Gamification Placeholder Screen - Beautiful UI when gamification is disabled
class _GamificationPlaceholderScreen extends StatelessWidget {
  const _GamificationPlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.black,
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  title: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFFFD700), AppColors.richGold, Color(0xFFE6C06E)],
                    ).createShader(bounds),
                    child: const Text(
                      'My Progress',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  centerTitle: true,
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.richGold.withOpacity(0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Level Card
                      _buildLevelCard(),
                      const SizedBox(height: 20),

                      // Stats Row
                      _buildStatsRow(),
                      const SizedBox(height: 20),

                      // Achievements Section
                      _buildSectionHeader('Achievements', Icons.emoji_events_rounded),
                      const SizedBox(height: 12),
                      _buildAchievementsGrid(),
                      const SizedBox(height: 24),

                      // Daily Challenges Section
                      _buildSectionHeader('Daily Challenges', Icons.bolt_rounded),
                      const SizedBox(height: 12),
                      _buildChallengesList(),
                      const SizedBox(height: 24),

                      // Leaderboard Preview
                      _buildSectionHeader('Leaderboard', Icons.leaderboard_rounded),
                      const SizedBox(height: 12),
                      _buildLeaderboardPreview(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.05),
              ],
            ),
            border: Border.all(
              color: AppColors.richGold.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.richGold.withOpacity(0.15),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Level Badge
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFFD700), AppColors.richGold, Color(0xFFB8860B)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.richGold.withOpacity(0.5),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '12',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'LEVEL',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // XP Progress
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Experience Points',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '2,450 / 3,000 XP',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Progress Bar
                        Container(
                          height: 10,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: Colors.white.withOpacity(0.1),
                          ),
                          child: Stack(
                            children: [
                              FractionallySizedBox(
                                widthFactor: 0.82,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFFD700), AppColors.richGold],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.richGold.withOpacity(0.5),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '550 XP to next level',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('🔥', '15', 'Day Streak')),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('⭐', '23', 'Achievements')),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('🏆', '#42', 'Rank')),
      ],
    );
  }

  Widget _buildStatCard(String emoji, String value, String label) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.richGold.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.richGold, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: () {},
          child: Text(
            'See All',
            style: TextStyle(
              color: AppColors.richGold.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementsGrid() {
    final achievements = [
      {'icon': '💬', 'name': 'Conversation Starter', 'progress': 0.8, 'unlocked': true},
      {'icon': '❤️', 'name': 'First Match', 'progress': 1.0, 'unlocked': true},
      {'icon': '📸', 'name': 'Photo Pro', 'progress': 0.6, 'unlocked': false},
      {'icon': '🌟', 'name': 'Profile Star', 'progress': 1.0, 'unlocked': true},
    ];

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: achievements.length,
        itemBuilder: (context, index) {
          final achievement = achievements[index];
          return _buildAchievementCard(
            achievement['icon'] as String,
            achievement['name'] as String,
            achievement['progress'] as double,
            achievement['unlocked'] as bool,
          );
        },
      ),
    );
  }

  Widget _buildAchievementCard(String icon, String name, double progress, bool unlocked) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: unlocked
                    ? [AppColors.richGold.withOpacity(0.2), AppColors.richGold.withOpacity(0.1)]
                    : [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
              ),
              border: Border.all(
                color: unlocked ? AppColors.richGold.withOpacity(0.4) : Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(icon, style: TextStyle(fontSize: 32, color: unlocked ? null : Colors.grey)),
                const SizedBox(height: 8),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: unlocked ? Colors.white : Colors.white54,
                  ),
                ),
                const SizedBox(height: 8),
                if (!unlocked || progress < 1.0)
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      unlocked ? AppColors.richGold : Colors.white38,
                    ),
                  )
                else
                  const Icon(Icons.check_circle, color: AppColors.richGold, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChallengesList() {
    final challenges = [
      {'icon': '💌', 'name': 'Send 5 Messages', 'reward': '+50 XP', 'progress': '3/5'},
      {'icon': '👋', 'name': 'Like 10 Profiles', 'reward': '+30 XP', 'progress': '7/10'},
      {'icon': '📝', 'name': 'Update Your Bio', 'reward': '+20 XP', 'progress': 'Done'},
    ];

    return Column(
      children: challenges.map((challenge) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(challenge['icon']!, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            challenge['name']!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            challenge['reward']!,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.richGold.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: challenge['progress'] == 'Done'
                            ? AppColors.richGold.withOpacity(0.2)
                            : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        challenge['progress']!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: challenge['progress'] == 'Done'
                              ? AppColors.richGold
                              : Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLeaderboardPreview() {
    final leaders = [
      {'rank': '1', 'name': 'Sarah M.', 'xp': '12,450', 'avatar': '👩'},
      {'rank': '2', 'name': 'John D.', 'xp': '11,200', 'avatar': '👨'},
      {'rank': '3', 'name': 'Emma K.', 'xp': '10,890', 'avatar': '👩‍🦰'},
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: leaders.asMap().entries.map((entry) {
              final index = entry.key;
              final leader = entry.value;
              final isFirst = index == 0;

              return Container(
                margin: EdgeInsets.only(bottom: index < leaders.length - 1 ? 12 : 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isFirst ? AppColors.richGold.withOpacity(0.15) : Colors.transparent,
                  border: isFirst ? Border.all(color: AppColors.richGold.withOpacity(0.3)) : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFirst
                            ? AppColors.richGold
                            : index == 1
                                ? Colors.grey.shade400
                                : Colors.brown.shade400,
                      ),
                      child: Center(
                        child: Text(
                          leader['rank']!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(leader['avatar']!, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        leader['name']!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Text(
                      '${leader['xp']!} XP',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isFirst ? AppColors.richGold : Colors.white70,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
