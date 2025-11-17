# Notifications Feature

## Overview

The Notifications feature provides real-time in-app and push notifications for user engagement. It implements a comprehensive notification system with granular user preferences, quiet hours, and Firebase Cloud Messaging (FCM) integration.

## Architecture

This feature follows Clean Architecture with three main layers:

### Domain Layer
- **Entities**: NotificationEntity, NotificationPreferences
- **Repository Interface**: NotificationRepository
- **Use Cases**:
  - GetNotifications
  - MarkNotificationRead
  - MarkAllNotificationsRead
  - GetNotificationPreferences
  - UpdateNotificationPreferences

### Data Layer
- **Models**: NotificationModel, NotificationPreferencesModel
- **Repository Implementation**: NotificationRepositoryImpl
- **Data Sources**: NotificationRemoteDataSource (Firestore + FCM)

### Presentation Layer
- **BLoCs**: NotificationsBloc, NotificationPreferencesBloc
- **Screens**: NotificationsScreen, NotificationPreferencesScreen
- **Widgets**: NotificationCard

## Notification Types

The system supports 8 notification types:

1. **newMatch** - When users get a new match
2. **newMessage** - When someone sends a message
3. **newLike** - When someone likes the user
4. **profileView** - When someone views the user's profile
5. **superLike** - When someone super likes the user
6. **matchExpiring** - When a match is about to expire
7. **promotional** - Tips, offers, and promotions
8. **system** - System announcements

Each type has a unique icon and color for visual distinction.

## Features

### Real-time Notifications
- Firestore real-time listeners for instant notification updates
- Unread count badge displayed on navigation bar
- Auto-refresh when notifications are marked as read

### Push Notifications
- Firebase Cloud Messaging (FCM) integration
- Device token management
- Background and foreground notification handling
- Deep linking support via actionUrl

### Notification Preferences
Users can customize:
- **Master Controls**: Enable/disable push and email notifications
- **Per-Type Settings**: Granular control for each notification type
- **Sound & Vibration**: Toggle notification sounds and vibration
- **Quiet Hours**: Set time range to mute notifications (e.g., 22:00 to 08:00)

### UI Features
- Swipe-to-dismiss notifications
- Visual distinction for unread notifications
- "Mark all as read" action
- Pull-to-refresh
- Empty state messaging
- Error handling with retry

## Data Models

### NotificationEntity
```dart
class NotificationEntity {
  final String notificationId;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final bool isRead;
  final String? actionUrl;
  final String? imageUrl;
}
```

### NotificationPreferences
```dart
class NotificationPreferences {
  final String userId;
  final bool pushNotificationsEnabled;
  final bool emailNotificationsEnabled;
  final bool newMatchNotifications;
  final bool newMessageNotifications;
  final bool newLikeNotifications;
  final bool profileViewNotifications;
  final bool superLikeNotifications;
  final bool matchExpiringNotifications;
  final bool promotionalNotifications;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final String quietHoursStart;
  final String quietHoursEnd;
  final bool quietHoursEnabled;
}
```

## Firestore Structure

### notifications Collection
```
notifications/
  {notificationId}/
    - userId: string
    - type: string
    - title: string
    - message: string
    - data: map (optional)
    - createdAt: timestamp
    - isRead: boolean
    - actionUrl: string (optional)
    - imageUrl: string (optional)
```

### notification_preferences Collection
```
notification_preferences/
  {userId}/
    - pushNotificationsEnabled: boolean
    - emailNotificationsEnabled: boolean
    - newMatchNotifications: boolean
    - newMessageNotifications: boolean
    - newLikeNotifications: boolean
    - profileViewNotifications: boolean
    - superLikeNotifications: boolean
    - matchExpiringNotifications: boolean
    - promotionalNotifications: boolean
    - soundEnabled: boolean
    - vibrationEnabled: boolean
    - quietHoursStart: string (HH:mm format)
    - quietHoursEnd: string (HH:mm format)
    - quietHoursEnabled: boolean
```

## Firestore Indexes

Three composite indexes are required:

1. **Query unread notifications by user**:
   - userId (ASC) + isRead (ASC) + createdAt (DESC)

2. **Query notifications by type**:
   - userId (ASC) + type (ASC) + createdAt (DESC)

3. **Query all user notifications**:
   - userId (ASC) + createdAt (DESC)

## Usage

### Display Notifications Screen
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => NotificationsScreen(userId: userId),
  ),
);
```

### Display Preferences Screen
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => NotificationPreferencesScreen(userId: userId),
  ),
);
```

### Create a Notification (Backend/Cloud Function)
```dart
await notificationRepository.createNotification(
  userId: 'user123',
  type: NotificationType.newMatch,
  title: 'New Match!',
  message: 'You matched with Sarah',
  data: {'matchId': 'match456'},
  actionUrl: '/matches/match456',
  imageUrl: 'https://...',
);
```

### Mark Notification as Read
```dart
context.read<NotificationsBloc>().add(
  NotificationMarkedAsRead(notificationId: 'notif123'),
);
```

### Update Preferences
```dart
context.read<NotificationPreferencesBloc>().add(
  NotificationPreferencesUpdated(
    preferences: updatedPreferences,
  ),
);
```

## State Management

### NotificationsBloc States
- `NotificationsInitial` - Initial state
- `NotificationsLoading` - Loading notifications
- `NotificationsLoaded` - Notifications loaded with unread count
- `NotificationsEmpty` - No notifications
- `NotificationsError` - Error loading notifications

### NotificationsBloc Events
- `NotificationsLoadRequested` - Load user notifications
- `NotificationMarkedAsRead` - Mark single notification as read
- `NotificationsMarkedAllAsRead` - Mark all notifications as read
- `NotificationDeleted` - Delete notification
- `NotificationTapped` - Handle notification tap

### NotificationPreferencesBloc States
- `NotificationPreferencesInitial` - Initial state
- `NotificationPreferencesLoading` - Loading preferences
- `NotificationPreferencesLoaded` - Preferences loaded
- `NotificationPreferencesError` - Error loading preferences

### NotificationPreferencesBloc Events
- `NotificationPreferencesLoadRequested` - Load user preferences
- `NotificationPreferencesUpdated` - Update preferences

## Integration with Navigation

The main navigation screen displays an unread notification badge:
- Notification bell icon in AppBar
- Real-time unread count badge (e.g., "5" or "99+")
- Red badge color for visibility
- Tapping navigates to NotificationsScreen

## FCM Setup (Required)

### Android (android/app/google-services.json)
Download from Firebase Console and place in android/app/

### iOS (ios/Runner/GoogleService-Info.plist)
Download from Firebase Console and place in ios/Runner/

### Request Permission
```dart
final granted = await notificationRepository.requestPermission();
if (granted) {
  final token = await notificationRepository.getFCMToken();
  await notificationRepository.saveFCMToken(userId, token!);
}
```

## Navigation Actions

When a notification is tapped, the system can navigate to:
- Chat screen (for newMessage)
- Matches screen (for newMatch)
- Profile view (for newLike, profileView)
- Any custom route via actionUrl

Example actionUrl: `/chat/{conversationId}` or `/matches/{matchId}`

## Best Practices

### Performance
- Use Firestore real-time listeners for instant updates
- Limit query results (e.g., last 100 notifications)
- Clean up StreamSubscriptions in bloc close()

### User Experience
- Show notification count badges
- Provide granular control over notification types
- Respect quiet hours
- Allow swipe-to-dismiss
- Show loading states

### Security
- Validate notification ownership (userId check)
- Sanitize notification data
- Use Firestore security rules to prevent unauthorized access

### Testing
- Test FCM integration on physical devices
- Test quiet hours boundary conditions
- Test notification tapping and navigation
- Test mark all as read with large notification counts

## Future Enhancements

Potential improvements:
1. Group notifications by type
2. Notification history archive
3. Rich media notifications (images, videos)
4. Action buttons in notifications
5. Scheduled notifications
6. Email digest of notifications
7. Notification analytics
8. Custom notification sounds per type
9. Notification priority levels
10. Multi-language support

## Dependencies

```yaml
dependencies:
  firebase_messaging: ^latest
  cloud_firestore: ^latest
  flutter_bloc: ^latest
  equatable: ^latest
  dartz: ^latest
  get_it: ^latest
```

## File Structure

```
lib/features/notifications/
├── data/
│   ├── datasources/
│   │   └── notification_remote_datasource.dart
│   ├── models/
│   │   ├── notification_model.dart
│   │   └── notification_preferences_model.dart
│   └── repositories/
│       └── notification_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── notification.dart
│   │   └── notification_preferences.dart
│   ├── repositories/
│   │   └── notification_repository.dart
│   └── usecases/
│       ├── get_notifications.dart
│       ├── mark_notification_read.dart
│       ├── mark_all_notifications_read.dart
│       ├── get_notification_preferences.dart
│       └── update_notification_preferences.dart
├── presentation/
│   ├── bloc/
│   │   ├── notifications_bloc.dart
│   │   ├── notifications_event.dart
│   │   ├── notifications_state.dart
│   │   ├── notification_preferences_bloc.dart
│   │   ├── notification_preferences_event.dart
│   │   └── notification_preferences_state.dart
│   ├── screens/
│   │   ├── notifications_screen.dart
│   │   └── notification_preferences_screen.dart
│   └── widgets/
│       └── notification_card.dart
└── README.md
```

## Support

For issues or questions about the notifications feature:
1. Check Firestore indexes are deployed
2. Verify FCM setup is correct
3. Check notification permissions
4. Review BLoC state changes in DevTools
5. Check Firestore security rules

## Version History

- **v1.0.0** - Initial implementation with FCM, real-time updates, and preferences
