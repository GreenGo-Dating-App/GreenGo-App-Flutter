import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test helper utilities for user tests
class TestHelpers {
  /// Initialize test binding
  static void initializeTests() {
    TestWidgetsFlutterBinding.ensureInitialized();
  }

  /// Wait for animations to complete
  static Future<void> waitForAnimations(WidgetTester tester) async {
    await tester.pumpAndSettle();
  }

  /// Tap a widget by key
  static Future<void> tapByKey(WidgetTester tester, String key) async {
    final finder = find.byKey(Key(key));
    expect(finder, findsOneWidget);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Tap a widget by text
  static Future<void> tapByText(WidgetTester tester, String text) async {
    final finder = find.text(text);
    expect(finder, findsOneWidget);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Enter text into a field by key
  static Future<void> enterTextByKey(
    WidgetTester tester,
    String key,
    String text,
  ) async {
    final finder = find.byKey(Key(key));
    expect(finder, findsOneWidget);
    await tester.enterText(finder, text);
    await tester.pumpAndSettle();
  }

  /// Enter text into a TextField by hint text
  static Future<void> enterTextByHint(
    WidgetTester tester,
    String hint,
    String text,
  ) async {
    final finder = find.widgetWithText(TextField, hint);
    if (finder.evaluate().isEmpty) {
      final decoratedFinder = find.byWidgetPredicate((widget) {
        if (widget is TextField) {
          return widget.decoration?.hintText == hint;
        }
        return false;
      });
      expect(decoratedFinder, findsOneWidget);
      await tester.enterText(decoratedFinder, text);
    } else {
      await tester.enterText(finder, text);
    }
    await tester.pumpAndSettle();
  }

  /// Scroll until widget is visible
  static Future<void> scrollUntilVisible(
    WidgetTester tester,
    Finder finder, {
    double delta = -100,
    int maxScrolls = 50,
  }) async {
    int scrolls = 0;
    while (finder.evaluate().isEmpty && scrolls < maxScrolls) {
      await tester.drag(find.byType(Scrollable).first, Offset(0, delta));
      await tester.pumpAndSettle();
      scrolls++;
    }
    expect(finder, findsOneWidget);
  }

  /// Swipe a card right (Like)
  static Future<void> swipeRight(WidgetTester tester, Finder card) async {
    await tester.drag(card, const Offset(300, 0));
    await tester.pumpAndSettle();
  }

  /// Swipe a card left (Pass)
  static Future<void> swipeLeft(WidgetTester tester, Finder card) async {
    await tester.drag(card, const Offset(-300, 0));
    await tester.pumpAndSettle();
  }

  /// Swipe a card up (Super Like)
  static Future<void> swipeUp(WidgetTester tester, Finder card) async {
    await tester.drag(card, const Offset(0, -300));
    await tester.pumpAndSettle();
  }

  /// Verify widget exists
  static void expectWidgetExists(Finder finder) {
    expect(finder, findsOneWidget);
  }

  /// Verify widget does not exist
  static void expectWidgetNotExists(Finder finder) {
    expect(finder, findsNothing);
  }

  /// Verify text is displayed
  static void expectTextDisplayed(String text) {
    expect(find.text(text), findsOneWidget);
  }

  /// Navigate to bottom navigation tab
  static Future<void> navigateToTab(WidgetTester tester, int index) async {
    final bottomNav = find.byType(BottomNavigationBar);
    expect(bottomNav, findsOneWidget);
    final icons = find.descendant(
      of: bottomNav,
      matching: find.byType(Icon),
    );
    await tester.tap(icons.at(index));
    await tester.pumpAndSettle();
  }

  /// Long press a widget
  static Future<void> longPress(WidgetTester tester, Finder finder) async {
    await tester.longPress(finder);
    await tester.pumpAndSettle();
  }

  /// Pull to refresh
  static Future<void> pullToRefresh(WidgetTester tester) async {
    await tester.drag(find.byType(RefreshIndicator), const Offset(0, 300));
    await tester.pumpAndSettle();
  }

  /// Wait for a specific duration
  static Future<void> wait(WidgetTester tester, Duration duration) async {
    await tester.pump(duration);
  }

  /// Check if a widget is enabled
  static bool isEnabled(WidgetTester tester, Finder finder) {
    final widget = tester.widget(finder);
    if (widget is ElevatedButton) {
      return widget.onPressed != null;
    }
    if (widget is TextButton) {
      return widget.onPressed != null;
    }
    if (widget is IconButton) {
      return widget.onPressed != null;
    }
    return true;
  }
}

/// Test user data for simulating user actions
class TestUserData {
  static const String validEmail = 'testuser@example.com';
  static const String validPassword = 'TestPass123!';
  static const String invalidEmail = 'invalid-email';
  static const String weakPassword = '123';
  static const String userName = 'Test User';
  static const int userAge = 25;
  static const String userBio = 'This is a test bio for the user profile.';
  static const List<String> userInterests = ['Music', 'Travel', 'Sports'];
}
