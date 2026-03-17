import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/feature_flags_service.dart';
import '../../../../core/services/access_control_service.dart';
import '../../../../core/services/activity_tracking_service.dart';
import '../../../../core/services/presence_service.dart';
import '../../../../core/services/subscription_expiry_service.dart';
import '../../../app_guide/presentation/screens/app_guide_screen.dart';
import '../../../../core/widgets/countdown_blur_overlay.dart';
import '../../../../core/widgets/loading_indicator.dart';
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
import '../../../../core/services/usage_limit_service.dart';
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
import '../../../../core/services/push_notification_service.dart';
import '../../../subscription/domain/entities/subscription.dart';
import '../../../subscription/presentation/screens/subscription_selection_screen.dart';
import '../../../subscription/presentation/bloc/subscription_bloc.dart';
import '../../../gamification/presentation/bloc/gamification_bloc.dart';
import '../../../gamification/presentation/bloc/gamification_event.dart';
import '../../../gamification/presentation/bloc/gamification_state.dart';
import '../../../gamification/presentation/widgets/level_up_celebration_dialog.dart';
import '../../../gamification/presentation/widgets/achievement_unlock_dialog.dart';
import '../../../gamification/domain/entities/achievement.dart';
import '../../../gamification/domain/entities/user_level.dart';
import '../../../gamification/presentation/screens/leaderboard_screen.dart';
import '../../../coins/data/datasources/coin_remote_datasource.dart';
import '../../../coins/domain/entities/coin_transaction.dart';
// App Tour imports
import '../../../app_tour/presentation/widgets/tour_overlay.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../core/widgets/base_membership_dialog.dart';

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
  bool _showCachedCountdown = false; // True while Firestore hasn't loaded yet but cached countdown exists
  int? _cachedCountdownEndMs; // Cached end timestamp in milliseconds
  static const String _countdownEndKeyPrefix = 'countdown_end_';

  // Activity tracking for re-engagement notifications
  late final ActivityTrackingService _activityTrackingService;

  // Online presence service
  late final PresenceService _presenceService;

  late List<Widget> _screens;
  late final NotificationsBloc _notificationsBloc;

  // Coin balance bloc for app bar
  late final CoinBloc _coinBloc;

  // Profile bloc for shared profile state across screens
  late final ProfileBloc _profileBloc;

  // Discovery screen key for grid mode toggle
  final GlobalKey<DiscoveryScreenState> _discoveryKey = GlobalKey<DiscoveryScreenState>();

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

  // Hourly usage counters for discovery
  int _likeUsage = 0;
  int _nopeUsage = 0;
  int _superLikeUsage = 0;
  final UsageLimitService _usageLimitService = UsageLimitService();

  // Badge counts for bottom nav
  int _newMatchCount = 0;
  int _unreadMessageCount = 0;
  StreamSubscription? _matchCountSub;
  StreamSubscription? _messageCountSub;

  // Real-time level-up & achievement listeners
  StreamSubscription? _levelUpSub;
  StreamSubscription? _achievementSub;
  int? _lastKnownLevel; // track to detect level changes
  Set<String> _knownUnlockedAchievements = {}; // track already-unlocked achievements

  @override
  void initState() {
    super.initState();

    // Set current user ID for push notification navigation
    PushNotificationService.currentUserId = widget.userId;

    // Initialize access control service and load countdown dates from Firestore
    _accessControlService = AccessControlService();
    AccessControlService.loadCountdownDatesFromFirestore();

    // Initialize activity tracking for re-engagement notifications
    _activityTrackingService = ActivityTrackingService();
    _activityTrackingService.startTracking();

    // Initialize presence service and mark user as online
    _presenceService = PresenceService(userId: widget.userId);
    _presenceService.onAppResumed();
    WidgetsBinding.instance.addObserver(this);

    // Initialize gamification bloc (only when enabled)
    if (AppConfig.enableGamification) {
      _gamificationBloc = di.sl<GamificationBloc>()
        ..add(LoadUserLevel(widget.userId));
      // Start real-time listeners for level-up and achievement unlock celebrations
      _startLevelUpListener();
      _startAchievementListener();
    }

    // Initialize notifications bloc for badge count
    _notificationsBloc = di.sl<NotificationsBloc>()
      ..add(NotificationsLoadRequested(
        userId: widget.userId,
        unreadOnly: true,
      ));

    // Initialize coin bloc for balance display — load immediately then subscribe to stream
    _coinBloc = di.sl<CoinBloc>()
      ..add(LoadCoinBalance(widget.userId))
      ..add(SubscribeToCoinBalance(widget.userId));

    // Grant daily 100 free coins
    _grantDailyFreeCoins();

    // Initialize profile bloc for shared profile state (MUST be before _screens)
    _profileBloc = di.sl<ProfileBloc>()
      ..add(ProfileLoadRequested(userId: widget.userId));

    // Build screens list:
    // Network(0), Exchanges(1), Leaderboard(2), Shop(3), Profile(4)
    _screens = [
      DiscoveryScreen(
        key: _discoveryKey,
        userId: widget.userId,
        onGridModeChanged: () {
          if (mounted) setState(() {});
        },
      ),
      ConversationsScreen(userId: widget.userId),
      BlocProvider(
        create: (context) => di.sl<GamificationBloc>()
          ..add(LoadLeaderboard(userId: widget.userId)),
        child: LeaderboardScreen(userId: widget.userId),
      ),
      CoinShopScreen(userId: widget.userId),
      BlocProvider.value(
        value: _profileBloc,
        child: EditProfileScreen(userId: widget.userId),
      ),
    ];

    // Check profile, load countdown cache, and access data together
    // _isCheckingProfile stays true until ALL of these complete
    _initializeAppState();

    // Load hourly usage counters for discovery
    _loadUsageCounters();

    // Check subscription expiry and downgrade to free if expired
    _checkSubscriptionExpiry();

    // Check base membership expiry
    _checkBaseMembershipExpiry();

    // Direct Firestore check for trial welcome popup (fallback if BlocListener doesn't fire)
    _checkBaseMembershipDirect();

    // Check if app tour should be shown
    _checkAppTour();

    // Listen for new match count and unread message count
    _startBadgeCountListeners();
  }

  Future<void> _checkAppTour() async {
    // App tour disabled
    return;
  }

  Future<void> _completeTour() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tourPrefKey, true);
    if (mounted) {
      setState(() {
        _showTour = false;
        _currentIndex = 0; // Redirect to Exchange tab after tour
      });
    }
  }

  void _skipTour() {
    _completeTour();
  }

  /// Initialize app state: profile check + countdown + access data in parallel
  /// _isCheckingProfile stays true until all complete
  Future<void> _initializeAppState() async {
    // Run all three in parallel
    await Future.wait([
      _loadCachedCountdown(),
      _loadAccessData(),
      _checkUserProfile(),
    ]);
    // Only now show the main content (profile check may have already redirected)
    if (mounted && _isCheckingProfile) {
      setState(() {
        _isCheckingProfile = false;
      });
    }
  }

  bool _membershipCheckDone = false;

  /// Check base membership on app start — show trial welcome or purchase dialog
  void _checkBaseMembership(Profile profile) {
    if (_membershipCheckDone) return;
    _membershipCheckDone = true;

    // If user has an active trial membership, show one-time welcome popup
    if (profile.isBaseMembershipActive && profile.baseMembershipEndDate != null) {
      // Delay to ensure the widget tree is fully built before showing dialog
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) _showTrialWelcomeDialog(profile.baseMembershipEndDate!);
      });
      return;
    }

    // No active membership — show purchase dialog
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        BaseMembershipDialog.show(context: context, userId: widget.userId);
      }
    });
  }

  /// Directly fetch profile from Firestore and trigger membership check
  /// This is a fallback in case the BlocListener doesn't fire
  Future<void> _checkBaseMembershipDirect() async {
    // Wait for widget tree to be fully built
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted || _membershipCheckDone) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(widget.userId)
          .get();
      if (!doc.exists || !mounted || _membershipCheckDone) return;

      final data = doc.data()!;
      final hasBase = data['hasBaseMembership'] as bool? ?? false;
      final endTs = data['baseMembershipEndDate'] as Timestamp?;
      final endDate = endTs?.toDate();
      final isActive = hasBase && endDate != null && endDate.isAfter(DateTime.now());

      _membershipCheckDone = true;

      if (isActive && endDate != null) {
        if (mounted) _showTrialWelcomeDialog(endDate);
      } else {
        if (mounted) {
          BaseMembershipDialog.show(context: context, userId: widget.userId);
        }
      }
    } catch (e) {
      debugPrint('Direct membership check error: $e');
    }
  }

  /// Open membership dialog to extend (called from profile/shop)
  void showExtendMembershipDialog() {
    BaseMembershipDialog.show(
      context: context,
      userId: widget.userId,
      isExtending: true,
    );
  }

  /// Show a one-time trial welcome popup after first login
  /// Uses Firestore `users/{userId}.trialWelcomeShown` to persist across devices/reinstalls
  Future<void> _showTrialWelcomeDialog(DateTime expirationDate) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      if (doc.data()?['trialWelcomeShown'] == true) return;

      // Mark as shown immediately in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'trialWelcomeShown': true});
    } catch (e) {
      // If Firestore fails, skip the popup rather than crash
      debugPrint('Trial welcome check error: $e');
      return;
    }

    if (!mounted) return;

    final l10n = AppLocalizations.of(context);
    final formattedDate = '${expirationDate.day.toString().padLeft(2, '0')}/'
        '${expirationDate.month.toString().padLeft(2, '0')}/'
        '${expirationDate.year}';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.charcoal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.richGold, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.card_giftcard,
                  color: AppColors.richGold, size: 48),
              const SizedBox(height: 16),
              Text(
                l10n?.trialWelcomeTitle ?? 'Welcome to GreenGo!',
                style: const TextStyle(
                  color: AppColors.richGold,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n?.trialWelcomeMessage(formattedDate) ??
                    'You are currently using the trial version. Your free base membership is active until $formattedDate. Enjoy exploring GreenGo!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.richGold,
                    foregroundColor: AppColors.deepBlack,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    l10n?.trialWelcomeButton ?? 'Get Started',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Grant 20 free coins daily (once per calendar day)
  Future<void> _grantDailyFreeCoins() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final todayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final lastGranted = prefs.getString('daily_coins_last_granted_${widget.userId}');

      if (lastGranted == todayKey) return; // Already granted today

      final coinDs = di.sl<CoinRemoteDataSource>();
      await coinDs.updateBalance(
        userId: widget.userId,
        amount: 20,
        type: CoinTransactionType.credit,
        reason: CoinTransactionReason.dailyLoginStreakReward,
        metadata: {'type': 'daily_free_coins', 'date': todayKey},
      );

      await prefs.setString('daily_coins_last_granted_${widget.userId}', todayKey);

      // Refresh coin balance
      if (mounted) {
        _coinBloc.add(LoadCoinBalance(widget.userId));
      }

      debugPrint('Daily free coins: Granted 20 coins for $todayKey');
    } catch (e) {
      debugPrint('Daily free coins: Error: $e');
    }
  }

  /// Reload hourly usage counters (likes, nopes, super likes)
  Future<void> _loadUsageCounters() async {
    try {
      final results = await Future.wait([
        _usageLimitService.getCurrentUsage(widget.userId, UsageLimitType.likes),
        _usageLimitService.getCurrentUsage(widget.userId, UsageLimitType.nopes),
        _usageLimitService.getCurrentUsage(widget.userId, UsageLimitType.superLikes),
      ]);
      if (mounted) {
        setState(() {
          _likeUsage = results[0];
          _nopeUsage = results[1];
          _superLikeUsage = results[2];
        });
      }
    } catch (_) {}
  }

  int? _getCachedCountdownEnd() => _cachedCountdownEndMs;

  Future<void> _loadCachedCountdown() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedEndMs = prefs.getInt('$_countdownEndKeyPrefix${widget.userId}');
    if (cachedEndMs != null && mounted) {
      final endTime = DateTime.fromMillisecondsSinceEpoch(cachedEndMs);
      if (DateTime.now().isBefore(endTime)) {
        setState(() {
          _cachedCountdownEndMs = cachedEndMs;
          _showCachedCountdown = true;
        });
      } else {
        // Expired — clear the key
        prefs.remove('$_countdownEndKeyPrefix${widget.userId}');
      }
    }
  }

  Future<void> _loadAccessData() async {
    // 1. Fetch latest countdown dates from Firestore (set by admin panel)
    await AccessControlService.loadCountdownDatesFromFirestore();

    // 2. Recalculate this user's accessDate based on their tier + fresh dates
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await _accessControlService.refreshUserAccessDate(
        currentUser.uid,
        currentUser.email,
      ).catchError((_) => null);
    }

    // 3. Now read the updated access data (force server to get the write we just did)
    final accessData = await _accessControlService.getCurrentUserAccess(forceServer: true);
    if (mounted && accessData != null) {
      final isAdminOrTest = accessData.isAdmin || accessData.isTestUser;
      setState(() {
        _accessData = accessData;
        _showCachedCountdown = false; // Firestore data is now authoritative
        // Admin and test users always bypass verification overlay
        if (isAdminOrTest) {
          _verificationStatus = VerificationStatus.approved;
          _isAdmin = _isAdmin || accessData.isAdmin;
        }
      });

      // Persist or clear countdown end time
      final prefs = await SharedPreferences.getInstance();
      if (!isAdminOrTest && accessData.isCountdownActive) {
        // Countdown is active — cache the end timestamp
        prefs.setInt(
          '$_countdownEndKeyPrefix${widget.userId}',
          accessData.accessDate.millisecondsSinceEpoch,
        );
      } else {
        // No countdown — clear any cached value
        prefs.remove('$_countdownEndKeyPrefix${widget.userId}');
      }

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

  /// Check if base membership has expired and update Firestore
  Future<void> _checkBaseMembershipExpiry() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(widget.userId)
          .get();
      if (!doc.exists || !mounted) return;

      final data = doc.data()!;
      final hasBase = data['hasBaseMembership'] as bool? ?? false;
      final endTs = data['baseMembershipEndDate'];

      if (hasBase && endTs != null) {
        final endDate = (endTs as Timestamp).toDate();
        if (endDate.isBefore(DateTime.now())) {
          // Expired — clear the flag
          await FirebaseFirestore.instance
              .collection('profiles')
              .doc(widget.userId)
              .update({'hasBaseMembership': false});

          // Refresh profile bloc
          if (mounted) {
            _profileBloc.add(ProfileLoadRequested(userId: widget.userId));
          }
        }
      }
    } catch (e) {
      debugPrint('[MainNav] Failed to check base membership expiry: $e');
    }
  }

  void _showDowngradeDialog(String previousTierName) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(
          AppLocalizations.of(ctx)!.subscriptionExpired,
          style: const TextStyle(color: AppColors.richGold),
        ),
        content: Text(
          AppLocalizations.of(ctx)!.subscriptionExpiredBody(previousTierName),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx)!.ok),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Navigate to subscription screen
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => BlocProvider(
                    create: (context) => di.sl<SubscriptionBloc>(),
                    child: const MembershipSelectionScreen(),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.richGold,
              foregroundColor: AppColors.deepBlack,
            ),
            child: Text(AppLocalizations.of(ctx)!.upgrade),
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
        'title': AppLocalizations.of(context)!.accountApproved,
        'body': AppLocalizations.of(context)!.accountApprovedBody,
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
        'title': AppLocalizations.of(context)!.accessGranted,
        'body': AppLocalizations.of(context)!.accessGrantedBody(tierName),
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
    // Tabs: Exchange(0), Messages(1), Learn(2), Play(3), Profile(4)
    setState(() {
      _currentIndex = 4;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        _activityTrackingService.startTracking();
        _presenceService.onAppResumed();
        // Re-check access control on every app resume to enforce countdown
        _loadCachedCountdown();
        _loadAccessData();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _activityTrackingService.stopTracking();
        _presenceService.onAppPaused();
        break;
    }
  }

  Future<void> _checkUserProfile() async {
    try {
      final profileDoc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(widget.userId)
          .get(const GetOptions(source: Source.server));

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
          case 'verified':
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

        final isAdmin = data['isAdmin'] as bool? ?? false;
        // Check if test user (tier == 'test' in profiles or users collection)
        final isTestTier = membershipTierString?.toLowerCase() == 'test';

        // Admin and test users ALWAYS bypass verification — force approved
        if (isAdmin || isTestTier) {
          status = VerificationStatus.approved;
        }

        setState(() {
          _verificationStatus = status;
          _verificationRejectionReason = data['verificationRejectionReason'] as String?;
          _isAdmin = isAdmin;
          _membershipTier = membershipTier;
          // _isCheckingProfile set to false by _initializeAppState after all futures complete
        });
      }
    } catch (e) {
      // On error, assume profile exists — _isCheckingProfile handled by _initializeAppState
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

  // XP level thresholds (must match backend LEVEL_XP_REQUIREMENTS)
  static const _levelXpRequirements = [
    0, 100, 250, 500, 1000, 2000, 3500, 5500, 8000, 11000, 15000, 20000,
    26000, 33000, 41000, 50000,
  ];

  static int _calculateLevel(int totalXp) {
    int level = 1;
    while (level < _levelXpRequirements.length &&
        totalXp >= _levelXpRequirements[level]) {
      level++;
    }
    return level;
  }

  /// Listen to user_levels/{userId} for real-time level changes
  void _startLevelUpListener() {
    final fs = FirebaseFirestore.instance;
    _levelUpSub = fs
        .collection('user_levels')
        .doc(widget.userId)
        .snapshots()
        .listen((snapshot) {
      if (!mounted || !snapshot.exists) return;
      final data = snapshot.data()!;
      final totalXp = (data['totalXP'] as num?)?.toInt() ?? 0;
      final newLevel = _calculateLevel(totalXp);

      if (_lastKnownLevel == null) {
        // First snapshot — just record the current level
        _lastKnownLevel = newLevel;
        return;
      }

      if (newLevel > _lastKnownLevel!) {
        final previousLevel = _lastKnownLevel!;
        _lastKnownLevel = newLevel;

        // Show level-up celebration
        if (mounted) {
          final rewards = StandardLevelRewards.getRewardsForLevel(newLevel);
          LevelUpCelebrationDialog.show(
            context,
            newLevel: newLevel,
            previousLevel: previousLevel,
            rewards: rewards,
            isVIP: newLevel >= 50,
          );
        }
      } else {
        _lastKnownLevel = newLevel;
      }
    });
  }

  /// Listen to user_achievements for newly unlocked achievements
  void _startAchievementListener() {
    final fs = FirebaseFirestore.instance;
    _achievementSub = fs
        .collection('user_achievements')
        .where('userId', isEqualTo: widget.userId)
        .where('isUnlocked', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;

      final currentIds = snapshot.docs.map((d) => d.data()['achievementId'] as String? ?? d.id).toSet();

      if (_knownUnlockedAchievements.isEmpty) {
        // First snapshot — record all currently unlocked achievements
        _knownUnlockedAchievements = currentIds;
        return;
      }

      // Find newly unlocked achievements
      final newlyUnlocked = currentIds.difference(_knownUnlockedAchievements);
      _knownUnlockedAchievements = currentIds;

      for (final achievementId in newlyUnlocked) {
        final achievement = Achievements.getById(achievementId);
        if (achievement != null && mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            barrierColor: Colors.black87,
            builder: (ctx) => AchievementUnlockDialog(achievement: achievement),
          );
        }
      }
    });
  }

  void _startBadgeCountListeners() {
    final fs = FirebaseFirestore.instance;
    final uid = widget.userId;

    // New matches: count where user hasn't seen the match
    // Listen to matches where user is userId1 or userId2
    _matchCountSub = fs
        .collection('matches')
        .where(Filter.or(
          Filter('userId1', isEqualTo: uid),
          Filter('userId2', isEqualTo: uid),
        ))
        .where('isActive', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      int count = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final uid1 = data['userId1'] as String?;
        final uid2 = data['userId2'] as String?;
        if (uid1 != uid && uid2 != uid) continue;
        final seen = uid == uid1
            ? (data['user1Seen'] as bool? ?? false)
            : (data['user2Seen'] as bool? ?? false);
        if (!seen) count++;
      }
      if (mounted && count != _newMatchCount) {
        setState(() => _newMatchCount = count);
      }
    });

    // Unread chats: count conversations where someone sent me a message I haven't seen
    _messageCountSub = fs
        .collection('conversations')
        .where(Filter.or(
          Filter('userId1', isEqualTo: uid),
          Filter('userId2', isEqualTo: uid),
        ))
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      int count = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final uid1 = data['userId1'] as String?;
        final uid2 = data['userId2'] as String?;
        if (uid1 != uid && uid2 != uid) continue;

        // Skip deleted conversations
        if (data['isDeleted'] == true) continue;
        final deletedFor = data['deletedFor'] as Map<String, dynamic>?;
        if (deletedFor != null && deletedFor.containsKey(uid)) continue;

        // Skip conversations hidden via visibleTo (super like not yet accepted)
        final visibleTo = data['visibleTo'] as List<dynamic>?;
        if (visibleTo != null && visibleTo.isNotEmpty && !visibleTo.contains(uid)) continue;

        // Skip super like conversations
        final conversationType = data['conversationType'] as String?;
        if (conversationType == 'superLike') continue;

        final unread = (data['unreadCount'] as int?) ?? 0;
        if (unread <= 0) continue;

        // Only count if last message was sent by the other person
        final lastMsg = data['lastMessage'] as Map<String, dynamic>?;
        final lastSenderId = lastMsg?['senderId'] as String?;
        if (lastSenderId != null && lastSenderId != uid) {
          count += unread;
        }
      }
      if (mounted && count != _unreadMessageCount) {
        setState(() => _unreadMessageCount = count);
      }
    });
  }

  @override
  void dispose() {
    _matchCountSub?.cancel();
    _messageCountSub?.cancel();
    _levelUpSub?.cancel();
    _achievementSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _presenceService.dispose();
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
    _presenceService.recordActivity();
    setState(() {
      _currentIndex = index;
    });
  }

  /// Refresh the discovery tab by rebuilding the DiscoveryScreen with a new key
  void refreshDiscoveryTab() {
    setState(() {
      _currentIndex = 0;
    });
    _discoveryKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while checking profile
    if (_isCheckingProfile) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: const Center(
          child: LoadingIndicator(
            color: AppColors.richGold,
          ),
        ),
      );
    }

    // Check if countdown is active (access date in the future)
    // Admin and test users bypass ALL restrictions (countdown, approval, verification)
    final isAdminOrTestUser = _isAdmin ||
        (_accessData?.isAdmin ?? false) ||
        (_accessData?.isTestUser ?? false);

    // Countdown blocks ALL non-admin/non-tester users until their access date expires
    final isPreLaunchBlocked = !isAdminOrTestUser &&
        ((_accessData != null && _accessData!.isCountdownActive) ||
         (_accessData == null && _showCachedCountdown));

    // Tabs: Exchange(0), Messages(1), Shop(2), Profile(3)
    const profileIndex = 3;

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

          // Verification is gated at login level — no in-app overlay needed
          return screen;
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
          selectedFontSize: 13,
          unselectedFontSize: 13,
          iconSize: 28,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.people_outline),
              activeIcon: const Icon(Icons.people),
              label: AppLocalizations.of(context)!.discover,
            ),
            BottomNavigationBarItem(
              icon: _buildBadgeIcon(Icons.forum_outlined, _unreadMessageCount),
              activeIcon: _buildBadgeIcon(Icons.forum, _unreadMessageCount),
              label: AppLocalizations.of(context)!.messages,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.leaderboard_outlined),
              activeIcon: const Icon(Icons.leaderboard),
              label: AppLocalizations.of(context)!.leaderboardTitle,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.store_outlined),
              activeIcon: const Icon(Icons.store),
              label: AppLocalizations.of(context)!.shop,
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
              // Check base membership on first profile load
              _checkBaseMembership(state.profile);
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
                  child: _buildMainContent(scaffold, isPreLaunchBlocked),
                )
              : _buildMainContent(scaffold, isPreLaunchBlocked),
        ),
      ),
    );
  }

  Widget _buildMainContent(Widget scaffold, bool isPreLaunchBlocked) {
    // When countdown is active, overlay the ENTIRE scaffold (covers AppBar + BottomNav)
    if (isPreLaunchBlocked) {
      final overlayAccessData = _accessData ?? UserAccessData(
        userId: widget.userId,
        approvalStatus: ApprovalStatus.approved,
        accessDate: DateTime.fromMillisecondsSinceEpoch(
          _getCachedCountdownEnd() ?? DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch,
        ),
        membershipTier: SubscriptionTier.basic,
      );
      return CountdownBlurOverlay(
        accessData: overlayAccessData,
        onLogout: () async {
          await FirebaseAuth.instance.signOut();
          if (context.mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
          }
        },
        child: scaffold,
      );
    }

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
    final l10n = AppLocalizations.of(context)!;
    // Tab indexes: 0=Network, 1=Exchanges, 2=Leaderboard, 3=Shop, 4=Profile
    if (_currentIndex == 0) {
      // Discovery screen - coins on left, actions on right
      return AppBar(
        titleSpacing: 0,
        leadingWidth: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const SizedBox(width: 12),
            _buildAppBarCoinBalance(),
          ],
        ),
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        actions: [
          // RIGHT side: help, search, filter, grid toggle
          IconButton(
            icon: const Icon(Icons.help_outline, color: AppColors.textSecondary, size: 22),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AppGuideScreen()),
              );
            },
            tooltip: AppLocalizations.of(context)!.guideTitle,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textSecondary, size: 22),
            onPressed: _showNicknameSearch,
            tooltip: AppLocalizations.of(context)!.searchByNicknameTooltip,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
          IconButton(
            icon: const Icon(Icons.tune, color: AppColors.textSecondary, size: 22),
            onPressed: _openDiscoveryPreferences,
            tooltip: AppLocalizations.of(context)!.discoveryPreferencesTooltip,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
          IconButton(
            icon: Icon(
              (_discoveryKey.currentState?.isGridMode ?? true)
                  ? Icons.swipe
                  : Icons.grid_view,
              color: AppColors.textSecondary,
              size: 22,
            ),
            onPressed: () {
              _discoveryKey.currentState?.toggleGridMode();
            },
            tooltip: (_discoveryKey.currentState?.isGridMode ?? true)
                ? AppLocalizations.of(context)!.discoverySwitchToSwipe
                : AppLocalizations.of(context)!.discoverySwitchToGrid,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(width: 4),
        ],
      );
    } else if (_currentIndex == 1) {
      // Messages - show title and membership badge
      return AppBar(
        title: Text(
          l10n.messages,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        actions: [
          _buildMembershipBadgeWidget(),
          const SizedBox(width: 8),
        ],
      );
    } else if (_currentIndex == 2) {
      // Leaderboard - no app bar (has its own)
      return null;
    }
    // Shop and Profile - no app bar (have their own)
    return null;
  }

  void _openDiscoveryPreferences() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DiscoveryPreferencesScreen(
          userId: widget.userId,
          currentPreferences:
              _discoveryKey.currentState?.savedPreferences,
          onSave: (preferences) {
            // Refresh discovery stack with new filters (resets grid state too)
            _discoveryKey.currentState?.refreshWithPreferences(preferences);
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
                    unreadCount > 999 ? '999+' : unreadCount.toString(),
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
            // Navigate to Coin Shop screen (no longer a tab)
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => CoinShopScreen(userId: widget.userId),
              ),
            );
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
    );
  }

  Widget _buildBadgeIcon(IconData icon, int count) {
    if (count <= 0) return Icon(icon);
    final label = count > 999 ? '999+' : '$count';
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        Positioned(
          right: -8,
          top: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.errorRed,
              borderRadius: BorderRadius.circular(10),
            ),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  /// Compact usage chip: icon + "used/limit"
  Widget _buildUsageChip(String assetPath, IconData fallbackIcon, int used, int limit, Color color) {
    final limitText = limit == -1 ? '\u221E' : '$limit';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(fallbackIcon, size: 14, color: color),
          const SizedBox(width: 3),
          Text(
            '$used/$limitText',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  /// Refresh usage counters (call after each swipe)
  void refreshUsageCounters() {
    _loadUsageCounters();
  }

  int _lastKnownCoins = 0;

  Widget _buildAppBarCoinBalance() {
    return BlocBuilder<CoinBloc, CoinState>(
      bloc: _coinBloc,
      builder: (context, state) {
        if (state is CoinBalanceLoaded) {
          _lastKnownCoins = state.balance.availableCoins;
        } else if (state is CoinBalanceUpdated) {
          _lastKnownCoins = state.balance.availableCoins;
        }
        final coins = _lastKnownCoins;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.monetization_on, color: AppColors.richGold, size: 18),
              const SizedBox(width: 3),
              Text(
                '$coins',
                style: const TextStyle(
                  color: AppColors.richGold,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
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
                    child: Text(
                      AppLocalizations.of(context)!.gamificationMyProgress,
                      style: const TextStyle(
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
                      _buildLevelCard(context),
                      const SizedBox(height: 20),

                      // Stats Row
                      _buildStatsRow(context),
                      const SizedBox(height: 20),

                      // Achievements Section
                      _buildSectionHeader(context, AppLocalizations.of(context)!.gamificationAchievements, Icons.emoji_events_rounded),
                      const SizedBox(height: 12),
                      _buildAchievementsGrid(),
                      const SizedBox(height: 24),

                      // Daily Challenges Section
                      _buildSectionHeader(context, AppLocalizations.of(context)!.gamificationDailyChallenges, Icons.bolt_rounded),
                      const SizedBox(height: 12),
                      _buildChallengesList(),
                      const SizedBox(height: 24),

                      // Leaderboard Preview
                      _buildSectionHeader(context, AppLocalizations.of(context)!.gamificationLeaderboard, Icons.leaderboard_rounded),
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

  Widget _buildLevelCard(BuildContext context) {
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
                        Text(
                          AppLocalizations.of(context)!.gamificationExperiencePoints,
                          style: const TextStyle(
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

  Widget _buildStatsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildStatCard('🔥', '15', AppLocalizations.of(context)!.gamificationDayStreak)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('⭐', '23', AppLocalizations.of(context)!.gamificationAchievements)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('🏆', '#42', AppLocalizations.of(context)!.gamificationRank)),
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

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
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
            AppLocalizations.of(context)!.seeAll,
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
