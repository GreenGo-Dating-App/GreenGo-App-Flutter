import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../discovery/presentation/screens/discovery_screen.dart';
import '../../../discovery/presentation/screens/matches_screen.dart';
import '../../../chat/presentation/screens/conversations_screen.dart';
import '../../../profile/presentation/screens/edit_profile_screen.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../../notifications/presentation/bloc/notifications_bloc.dart';
import '../../../notifications/presentation/bloc/notifications_event.dart';
import '../../../notifications/presentation/bloc/notifications_state.dart';

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

  late final List<Widget> _screens;
  late final NotificationsBloc _notificationsBloc;

  @override
  void initState() {
    super.initState();
    _screens = [
      DiscoveryScreen(userId: widget.userId),
      MatchesScreen(userId: widget.userId),
      ConversationsScreen(userId: widget.userId),
      EditProfileScreen(userId: widget.userId),
    ];

    // Initialize notifications bloc for badge count
    _notificationsBloc = di.sl<NotificationsBloc>()
      ..add(NotificationsLoadRequested(
        userId: widget.userId,
        unreadOnly: true,
      ));
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
    return BlocProvider.value(
      value: _notificationsBloc,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: _buildAppBar(),
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
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
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.explore_outlined),
                activeIcon: Icon(Icons.explore),
                label: 'Discover',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite_outline),
                activeIcon: Icon(Icons.favorite),
                label: 'Matches',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline),
                activeIcon: Icon(Icons.chat_bubble),
                label: 'Messages',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget? _buildAppBar() {
    // Only show app bar on certain tabs
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
    // Profile screen - no app bar (has its own)
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
