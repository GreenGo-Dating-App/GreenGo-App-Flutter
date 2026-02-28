import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../profile/domain/entities/profile.dart';
import '../../../chat/presentation/screens/support_chat_screen.dart';
import '../bloc/notifications_bloc.dart';
import '../bloc/notifications_event.dart';
import '../bloc/notifications_state.dart';
import '../widgets/notification_card.dart';

/// Notifications Screen
///
/// Displays all user notifications with real-time updates
class NotificationsScreen extends StatelessWidget {
  final String userId;

  const NotificationsScreen({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<NotificationsBloc>()
        ..add(NotificationsLoadRequested(userId: userId)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          actions: [
            BlocBuilder<NotificationsBloc, NotificationsState>(
              builder: (context, state) {
                if (state is NotificationsLoaded && state.unreadCount > 0) {
                  return TextButton(
                    onPressed: () {
                      context.read<NotificationsBloc>().add(
                            NotificationsMarkedAllAsRead(userId),
                          );
                    },
                    child: const Text(
                      'Mark all read',
                      style: TextStyle(color: AppColors.richGold),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: BlocBuilder<NotificationsBloc, NotificationsState>(
          builder: (context, state) {
            if (state is NotificationsLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.richGold,
                ),
              );
            }

            if (state is NotificationsError) {
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
                      state.message,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        context.read<NotificationsBloc>().add(
                              NotificationsLoadRequested(userId: userId),
                            );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.richGold,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state is NotificationsEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 80,
                      color: AppColors.textSecondary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No notifications yet',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'When you get notifications, they\'ll show up here',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            if (state is NotificationsLoaded) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<NotificationsBloc>().add(
                        NotificationsLoadRequested(userId: userId),
                      );
                },
                color: AppColors.richGold,
                child: ListView.builder(
                  itemCount: state.notifications.length,
                  itemBuilder: (context, index) {
                    final notification = state.notifications[index];

                    return NotificationCard(
                      notification: notification,
                      onTap: () {
                        // Mark as read
                        context.read<NotificationsBloc>().add(
                              NotificationTapped(
                                notificationId: notification.notificationId,
                              ),
                            );

                        // Navigate based on notification type and actionUrl
                        _handleNotificationTap(context, notification);
                      },
                      onDismiss: () {
                        context.read<NotificationsBloc>().add(
                              NotificationDeleted(notification.notificationId),
                            );
                      },
                    );
                  },
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  void _handleNotificationTap(BuildContext context, notification) {
    final data = notification.data as Map<String, dynamic>?;
    final action = data?['action'] as String?;

    // Handle support message notifications — navigate to the support chat
    if (action == 'support_message') {
      final conversationId = data?['conversationId'] as String?;
      if (conversationId != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SupportChatScreen(
              conversationId: conversationId,
              currentUserId: userId,
            ),
          ),
        );
      }
    }
  }
}
