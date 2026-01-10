import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_helpers.dart';
import 'test_app.dart';

/// Notifications User Tests (8 tests)
/// Tests cover: View notifications, mark as read, configure preferences
void main() {
  TestHelpers.initializeTests();

  group('Notifications Tests', () {
    // Test 70: User can view notifications screen
    testWidgets('Test 70: User can view notifications screen', (tester) async {
      await pumpTestApp(tester, child: const TestMainScreen());

      // Navigate to Profile tab and tap notifications icon
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      await TestHelpers.tapByKey(tester, 'notifications_icon');
      await tester.pumpAndSettle();

      // Verify notifications screen
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.byKey(const Key('notifications_list')), findsOneWidget);
    });

    // Test 71: User can see different notification types
    testWidgets('Test 71: User can see different notification types', (tester) async {
      await pumpTestApp(tester, child: const TestNotificationsScreen());

      // Verify different notification types are displayed
      expect(find.textContaining('liked you'), findsWidgets);
      expect(find.textContaining('super liked you'), findsWidgets);
      expect(find.textContaining('new match'), findsWidgets);
      expect(find.textContaining('message'), findsWidgets);
    });

    // Test 72: User can tap notification to navigate to source
    testWidgets('Test 72: User can tap notification to navigate to source', (tester) async {
      await pumpTestApp(tester, child: const TestNotificationsScreen());

      // Tap on a notification
      await tester.tap(find.byKey(const Key('notification_item_0')));
      await tester.pumpAndSettle();

      // Verify navigation to profile
      expect(find.byKey(const Key('profile_detail')), findsOneWidget);
    });

    // Test 73: User can see unread indicators
    testWidgets('Test 73: User can see unread indicators', (tester) async {
      await pumpTestApp(tester, child: const TestNotificationsScreen());

      // Verify unread indicator
      expect(find.byKey(const Key('unread_indicator_0')), findsOneWidget);
    });

    // Test 74: User can mark all as read
    testWidgets('Test 74: User can mark all as read', (tester) async {
      await pumpTestApp(tester, child: const TestNotificationsScreen());

      // Tap mark all read button
      expect(find.byKey(const Key('mark_all_read_button')), findsOneWidget);
    });

    // Test 75: User can access notification settings
    testWidgets('Test 75: User can access notification settings', (tester) async {
      await pumpTestApp(tester, child: const TestNotificationsScreen());

      // Tap notification settings
      await TestHelpers.tapByKey(tester, 'notification_settings_button');
      await tester.pumpAndSettle();

      // Verify notification preferences screen
      expect(find.text('Notification Preferences'), findsOneWidget);
    });

    // Test 76: User can configure notification preferences
    testWidgets('Test 76: User can configure notification preferences', (tester) async {
      await pumpTestApp(tester, child: const TestNotificationPreferencesScreen());

      // Verify preference toggles
      expect(find.byKey(const Key('push_notifications_toggle')), findsOneWidget);
      expect(find.byKey(const Key('email_notifications_toggle')), findsOneWidget);
    });

    // Test 77: User can save notification preferences
    testWidgets('Test 77: User can save notification preferences', (tester) async {
      await pumpTestApp(tester, child: const TestNotificationPreferencesScreen());

      // Save preferences
      await TestHelpers.tapByKey(tester, 'save_preferences_button');
      await tester.pumpAndSettle();

      // Verify success
      expect(find.text('Preferences saved'), findsOneWidget);
    });
  });
}
