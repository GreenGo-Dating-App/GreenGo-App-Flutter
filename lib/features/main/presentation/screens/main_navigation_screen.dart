import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/feature_flags_service.dart';
import '../../../../core/services/access_control_service.dart';
import '../../../../core/widgets/countdown_blur_overlay.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../discovery/presentation/screens/discovery_screen.dart';
import '../../../discovery/presentation/screens/matches_screen.dart';
import '../../../chat/presentation/screens/conversations_screen.dart';
import '../../../coins/presentation/screens/shop_screen.dart';
import '../../../profile/presentation/screens/edit_profile_screen.dart';
import '../../../profile/presentation/screens/onboarding_screen.dart' as profile;
import '../../../profile/presentation/widgets/verification_status_widget.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../../notifications/presentation/bloc/notifications_bloc.dart';
import '../../../notifications/presentation/bloc/notifications_event.dart';
import '../../../notifications/presentation/bloc/notifications_state.dart';
import '../../../notifications/domain/entities/notification.dart' as notif;
// Language Learning imports - only used when feature is enabled
import '../../../language_learning/presentation/screens/language_learning_home_screen.dart';
import '../../../language_learning/presentation/bloc/language_learning_bloc.dart';

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
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
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

  late final List<Widget> _screens;
  late final NotificationsBloc _notificationsBloc;

  @override
  void initState() {
    super.initState();

    // Initialize access control service
    _accessControlService = AccessControlService();

    // Build screens list based on enabled features from Firestore
    // MVP: Discover, Matches, Messages, Shop, Profile (5 tabs)
    // With Learning: Discover, Matches, Messages, Shop, Learn, Profile (6 tabs)
    _screens = [
      DiscoveryScreen(userId: widget.userId),
      MatchesScreen(userId: widget.userId),
      ConversationsScreen(userId: widget.userId),
      ShopScreen(userId: widget.userId),
      if (featureFlags.languageLearningEnabled)
        BlocProvider(
          create: (context) => di.sl<LanguageLearningBloc>(),
          child: const LanguageLearningHomeScreen(),
        ),
      EditProfileScreen(userId: widget.userId),
    ];

    // Initialize notifications bloc for badge count
    _notificationsBloc = di.sl<NotificationsBloc>()
      ..add(NotificationsLoadRequested(
        userId: widget.userId,
        unreadOnly: true,
      ));

    // Check if user has a profile, redirect to onboarding if not
    _checkUserProfile();

    // Load access control data
    _loadAccessData();
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
    final profileIndex = featureFlags.languageLearningEnabled ? 5 : 4;
    setState(() {
      _currentIndex = profileIndex;
    });
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

        setState(() {
          _verificationStatus = status;
          _verificationRejectionReason = data['verificationRejectionReason'] as String?;
          _isAdmin = data['isAdmin'] as bool? ?? false;
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
    _notificationsBloc.close();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
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
    final isPreLaunchBlocked = _accessData != null &&
        _accessData!.approvalStatus == ApprovalStatus.approved &&
        !_accessData!.canAccessApp;

    final profileIndex = featureFlags.languageLearningEnabled ? 5 : 4;

    final scaffold = Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens.asMap().entries.map((entry) {
          final index = entry.key;
          final screen = entry.value;

          // Profile is always the last tab
          // Shop is index 3
          // Learn is index 4 (only if enabled)
          // Profile is index 4 (MVP) or 5 (with Learning)
          final learnIndex = featureFlags.languageLearningEnabled ? 4 : -1;

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

          // Shop and Learn (if enabled) don't need verification overlay
          if (index == 3 || index == learnIndex) {
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
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          backgroundColor: AppColors.backgroundCard,
          selectedItemColor: AppColors.richGold,
          unselectedItemColor: AppColors.textTertiary,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Discover',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline),
              activeIcon: Icon(Icons.favorite),
              label: 'Matches',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Messages',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.store_outlined),
              activeIcon: Icon(Icons.store),
              label: 'Shop',
            ),
            // Only show Learn tab if language learning is enabled
            if (featureFlags.languageLearningEnabled)
              const BottomNavigationBarItem(
                icon: Icon(Icons.school_outlined),
                activeIcon: Icon(Icons.school),
                label: 'Learn',
              ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );

    // Wrap with red border if admin is logged in
    return BlocProvider.value(
      value: _notificationsBloc,
      child: _isAdmin
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
    );
  }

  PreferredSizeWidget? _buildAppBar() {
    // Only show app bar on certain tabs
    // Tab indexes: 0=Discover, 1=Matches, 2=Messages, 3=Shop, 4=Profile (MVP)
    // With Learning: 0=Discover, 1=Matches, 2=Messages, 3=Shop, 4=Learn, 5=Profile
    if (_currentIndex == 0) {
      // Discovery screen - show logo and notifications
      return AppBar(
        title: const Text(
          'GreenGo',
          style: TextStyle(
            color: AppColors.richGold,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        actions: [
          _buildNotificationButton(),
          const SizedBox(width: 8),
        ],
      );
    } else if (_currentIndex == 1 || _currentIndex == 2) {
      // Matches and Messages - show title and notifications
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
          _buildNotificationButton(),
          const SizedBox(width: 8),
        ],
      );
    }
    // Shop, Learn (if enabled), and Profile - no app bar (have their own)
    return null;
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
}
