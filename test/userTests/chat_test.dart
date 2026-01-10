import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_helpers.dart';
import 'test_app.dart';

/// Chat & Messaging User Tests (12 tests)
/// Tests cover: Chat list, sending messages, message status, chat interactions
void main() {
  TestHelpers.initializeTests();

  group('Chat & Messaging Tests', () {
    // Test 58: User can view conversations list
    testWidgets('Test 58: User can view conversations list', (tester) async {
      await pumpTestApp(tester, child: const TestMainScreen());

      // Navigate to Messages tab
      await tester.tap(find.text('Messages'));
      await tester.pumpAndSettle();

      // Verify conversations list
      expect(find.byKey(const Key('conversations_list')), findsOneWidget);
    });

    // Test 59: User can see unread message indicators
    testWidgets('Test 59: User can see unread message indicators', (tester) async {
      await pumpTestApp(tester, child: const TestMainScreen());

      // Navigate to Messages tab
      await tester.tap(find.text('Messages'));
      await tester.pumpAndSettle();

      // Verify unread badge
      expect(find.byKey(const Key('unread_badge_0')), findsOneWidget);
    });

    // Test 60: User can open a conversation
    testWidgets('Test 60: User can open a conversation', (tester) async {
      await pumpTestApp(tester, child: const TestMainScreen());

      // Navigate to Messages tab
      await tester.tap(find.text('Messages'));
      await tester.pumpAndSettle();

      // Tap on a conversation
      await tester.tap(find.byKey(const Key('conversation_item_0')));
      await tester.pumpAndSettle();

      // Verify chat screen opens
      expect(find.byKey(const Key('message_input')), findsOneWidget);
      expect(find.byKey(const Key('send_button')), findsOneWidget);
    });

    // Test 61: User can send a message
    testWidgets('Test 61: User can send a message', (tester) async {
      await pumpTestApp(tester, child: const TestChatScreen());

      // Enter message text
      await tester.enterText(find.byKey(const Key('message_input')), 'Hello there!');
      await tester.pumpAndSettle();

      // Tap send
      await TestHelpers.tapByKey(tester, 'send_button');
      await tester.pumpAndSettle();

      // Verify message appears
      expect(find.text('Hello there!'), findsOneWidget);
    });

    // Test 62: User can see message list
    testWidgets('Test 62: User can see message list', (tester) async {
      await pumpTestApp(tester, child: const TestChatScreen());

      // Verify message list
      expect(find.byKey(const Key('message_list')), findsOneWidget);
    });

    // Test 63: User can see sent messages
    testWidgets('Test 63: User can see sent messages', (tester) async {
      await pumpTestApp(tester, child: const TestChatScreen());

      // Verify sent message bubble
      expect(find.byKey(const Key('sent_message_bubble')), findsOneWidget);
    });

    // Test 64: User can see received messages
    testWidgets('Test 64: User can see received messages', (tester) async {
      await pumpTestApp(tester, child: const TestChatScreen());

      // Verify received message bubble
      expect(find.byKey(const Key('received_message_bubble')), findsOneWidget);
    });

    // Test 65: User can see chat partner's online status
    testWidgets('Test 65: User can see chat partner online status', (tester) async {
      await pumpTestApp(tester, child: const TestChatScreen());

      // Verify online status indicator
      expect(find.byKey(const Key('online_status')), findsOneWidget);
      expect(find.text('Online'), findsOneWidget);
    });

    // Test 66: User can tap on partner profile in chat
    testWidgets('Test 66: User can tap on partner profile in chat', (tester) async {
      await pumpTestApp(tester, child: const TestChatScreen());

      // Verify partner profile widget exists in app bar
      expect(find.byKey(const Key('chat_partner_profile')), findsOneWidget);
      expect(find.text('Anna'), findsOneWidget);
    });

    // Test 67: User can delete a conversation
    testWidgets('Test 67: User can delete a conversation', (tester) async {
      await pumpTestApp(tester, child: const TestMainScreen());

      // Navigate to Messages tab
      await tester.tap(find.text('Messages'));
      await tester.pumpAndSettle();

      // Long press to show delete option
      await tester.longPress(find.byKey(const Key('conversation_item_0')));
      await tester.pumpAndSettle();

      // Verify delete dialog
      expect(find.text('Delete this conversation?'), findsOneWidget);
    });

    // Test 68: User can confirm delete conversation
    testWidgets('Test 68: User can confirm delete conversation', (tester) async {
      await pumpTestApp(tester, child: const TestMainScreen());

      // Navigate to Messages tab
      await tester.tap(find.text('Messages'));
      await tester.pumpAndSettle();

      // Long press to show delete option
      await tester.longPress(find.byKey(const Key('conversation_item_0')));
      await tester.pumpAndSettle();

      // Confirm delete
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Verify success message
      expect(find.text('Conversation deleted'), findsOneWidget);
    });

    // Test 69: User can see message status
    testWidgets('Test 69: User can see message status', (tester) async {
      await pumpTestApp(tester, child: const TestChatScreen());

      // Verify message status indicator (delivered)
      expect(find.byKey(const Key('message_status_delivered')), findsWidgets);
    });
  });
}
