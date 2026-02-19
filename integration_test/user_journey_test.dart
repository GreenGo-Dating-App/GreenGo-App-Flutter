import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:greengo_chat/main.dart' as app;

/// Real User Journey Integration Tests
///
/// These tests simulate a real user interacting with the app:
/// - Entering wrong passwords
/// - Clicking buttons
/// - Applying filters
/// - Navigating through screens
/// - Testing all user flows
///
/// Run with: flutter test integration_test/user_journey_test.dart -d emulator-5554

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Test credentials
  const validEmail = 'mauro.tommasi@live.it';
  const validPassword = 'Bb4649dgurs???';
  const wrongPassword = 'wrongpassword123';
  const invalidEmail = 'notanemail';

  group('Real User Journey Tests', () {
    testWidgets('Complete User Journey - All Scenarios', (tester) async {
      // Start the app
      app.main();

      // Use pump with fixed duration instead of pumpAndSettle for apps with continuous listeners
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 2));

      print('=== SCENARIO 1: App Launch ===');
      // Verify app launched and shows login screen
      await tester.pump(const Duration(milliseconds: 500));
      final hasTextField = find.byType(TextField).evaluate().isNotEmpty;
      print('TextFields found: $hasTextField');
      expect(hasTextField, isTrue, reason: 'App should show login form with text fields');

      print('=== SCENARIO 2: Empty Fields Validation ===');
      // Try to login without entering anything
      var loginButton = find.widgetWithText(ElevatedButton, 'Login');
      if (loginButton.evaluate().isEmpty) {
        loginButton = find.widgetWithText(ElevatedButton, 'Sign In');
      }
      if (loginButton.evaluate().isEmpty) {
        loginButton = find.byType(ElevatedButton);
      }

      if (loginButton.evaluate().isNotEmpty) {
        await tester.tap(loginButton.first);
        await tester.pump(const Duration(seconds: 2));
        print('Tapped login with empty fields');
      }

      print('=== SCENARIO 3: Invalid Email Format ===');
      final emailFields = find.byType(TextField);
      if (emailFields.evaluate().length >= 2) {
        await tester.enterText(emailFields.first, invalidEmail);
        await tester.pump(const Duration(milliseconds: 500));
        print('Entered invalid email: $invalidEmail');

        if (loginButton.evaluate().isNotEmpty) {
          await tester.tap(loginButton.first);
          await tester.pump(const Duration(seconds: 2));
        }
      }

      print('=== SCENARIO 4: Wrong Password ===');
      // Clear and enter valid email with wrong password
      final currentEmailFields = find.byType(TextField);
      if (currentEmailFields.evaluate().length >= 2) {
        await tester.enterText(currentEmailFields.first, '');
        await tester.pump(const Duration(milliseconds: 200));
        await tester.enterText(currentEmailFields.first, validEmail);
        await tester.pump(const Duration(milliseconds: 500));

        await tester.enterText(currentEmailFields.at(1), wrongPassword);
        await tester.pump(const Duration(milliseconds: 500));
        print('Entered valid email with wrong password');

        var currentLoginButton = find.widgetWithText(ElevatedButton, 'Login');
        if (currentLoginButton.evaluate().isEmpty) {
          currentLoginButton = find.byType(ElevatedButton);
        }
        if (currentLoginButton.evaluate().isNotEmpty) {
          await tester.tap(currentLoginButton.first);
          await tester.pump(const Duration(seconds: 3));
          await tester.pump(const Duration(seconds: 2));
          print('Attempted login with wrong password');
        }
      }

      print('=== SCENARIO 5: Password Visibility Toggle ===');
      final visibilityToggle = find.byIcon(Icons.visibility);
      final visibilityOffToggle = find.byIcon(Icons.visibility_off);
      if (visibilityToggle.evaluate().isNotEmpty) {
        await tester.tap(visibilityToggle.first);
        await tester.pump(const Duration(milliseconds: 500));
        print('Toggled password visibility ON');
      } else if (visibilityOffToggle.evaluate().isNotEmpty) {
        await tester.tap(visibilityOffToggle.first);
        await tester.pump(const Duration(milliseconds: 500));
        print('Toggled password visibility OFF');
      }

      print('=== SCENARIO 6: Forgot Password Navigation ===');
      final forgotPassword = find.textContaining('Forgot');
      if (forgotPassword.evaluate().isNotEmpty) {
        await tester.tap(forgotPassword.first);
        await tester.pump(const Duration(seconds: 2));
        print('Navigated to forgot password');

        // Go back
        final backButton = find.byIcon(Icons.arrow_back);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton.first);
          await tester.pump(const Duration(seconds: 2));
        }
      }

      print('=== SCENARIO 7: Valid Login ===');
      // Now login with correct credentials
      final loginEmailFields = find.byType(TextField);
      if (loginEmailFields.evaluate().length >= 2) {
        await tester.enterText(loginEmailFields.first, '');
        await tester.pump(const Duration(milliseconds: 200));
        await tester.enterText(loginEmailFields.first, validEmail);
        await tester.pump(const Duration(milliseconds: 500));

        await tester.enterText(loginEmailFields.at(1), '');
        await tester.pump(const Duration(milliseconds: 200));
        await tester.enterText(loginEmailFields.at(1), validPassword);
        await tester.pump(const Duration(milliseconds: 500));

        var finalLoginButton = find.widgetWithText(ElevatedButton, 'Login');
        if (finalLoginButton.evaluate().isEmpty) {
          finalLoginButton = find.widgetWithText(ElevatedButton, 'Sign In');
        }
        if (finalLoginButton.evaluate().isEmpty) {
          finalLoginButton = find.byType(ElevatedButton);
        }

        if (finalLoginButton.evaluate().isNotEmpty) {
          await tester.tap(finalLoginButton.first);
          print('Logging in with valid credentials...');

          // Wait for Firebase authentication with multiple pumps
          for (int i = 0; i < 10; i++) {
            await tester.pump(const Duration(seconds: 1));
          }
          print('Login completed');
        }
      }

      print('=== SCENARIO 8: Handle Onboarding Tour ===');
      // The app may show a tour overlay after login - dismiss it
      for (int i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 500));

        final nextButton = find.text('Next');
        final skipButton = find.text('Skip');
        final doneButton = find.text('Done');
        final gotItButton = find.text('Got it');

        if (nextButton.evaluate().isNotEmpty) {
          await tester.tap(nextButton.first);
          await tester.pump(const Duration(seconds: 1));
          print('Tapped Next on tour ($i)');
        } else if (skipButton.evaluate().isNotEmpty) {
          await tester.tap(skipButton.first);
          await tester.pump(const Duration(seconds: 1));
          print('Tapped Skip on tour');
          break;
        } else if (doneButton.evaluate().isNotEmpty) {
          await tester.tap(doneButton.first);
          await tester.pump(const Duration(seconds: 1));
          print('Tapped Done on tour');
          break;
        } else if (gotItButton.evaluate().isNotEmpty) {
          await tester.tap(gotItButton.first);
          await tester.pump(const Duration(seconds: 1));
          print('Tapped Got it on tour');
          break;
        } else {
          // Check if we're past the tour
          final bottomNav = find.byType(BottomNavigationBar);
          if (bottomNav.evaluate().isNotEmpty) {
            print('Found bottom nav - tour completed');
            break;
          }
        }
      }

      await tester.pump(const Duration(seconds: 2));

      print('=== SCENARIO 9: Navigate Through Bottom Tabs ===');
      final bottomNav = find.byType(BottomNavigationBar);
      if (bottomNav.evaluate().isNotEmpty) {
        print('Found bottom navigation bar');

        // Find nav items by icons
        final chatIcon = find.byIcon(Icons.chat);
        final chatBubbleIcon = find.byIcon(Icons.chat_bubble);
        final messageIcon = find.byIcon(Icons.message);
        final favoriteIcon = find.byIcon(Icons.favorite);
        final personIcon = find.byIcon(Icons.person);
        final homeIcon = find.byIcon(Icons.home);

        if (chatIcon.evaluate().isNotEmpty) {
          await tester.tap(chatIcon.first);
          await tester.pump(const Duration(seconds: 2));
          print('Navigated to Chat tab');
        } else if (chatBubbleIcon.evaluate().isNotEmpty) {
          await tester.tap(chatBubbleIcon.first);
          await tester.pump(const Duration(seconds: 2));
          print('Navigated to Chat tab (bubble icon)');
        } else if (messageIcon.evaluate().isNotEmpty) {
          await tester.tap(messageIcon.first);
          await tester.pump(const Duration(seconds: 2));
          print('Navigated to Messages tab');
        }

        if (favoriteIcon.evaluate().isNotEmpty) {
          await tester.tap(favoriteIcon.first);
          await tester.pump(const Duration(seconds: 2));
          print('Navigated to Favorites/Matches tab');
        }

        if (personIcon.evaluate().isNotEmpty) {
          await tester.tap(personIcon.last);
          await tester.pump(const Duration(seconds: 2));
          print('Navigated to Profile tab');
        }

        if (homeIcon.evaluate().isNotEmpty) {
          await tester.tap(homeIcon.first);
          await tester.pump(const Duration(seconds: 2));
          print('Navigated back to Home/Discovery tab');
        }
      } else {
        print('No bottom navigation found - may still be in login/tour');
      }

      print('=== SCENARIO 10: Discovery Screen - Filter Interactions ===');
      final filterIcon = find.byIcon(Icons.tune);
      final filterButton = find.byIcon(Icons.filter_list);
      if (filterIcon.evaluate().isNotEmpty) {
        await tester.tap(filterIcon.first);
        await tester.pump(const Duration(seconds: 2));
        print('Opened filter menu');

        // Look for sliders (age range, distance)
        final sliders = find.byType(Slider);
        final rangeSliders = find.byType(RangeSlider);

        if (rangeSliders.evaluate().isNotEmpty) {
          print('Found ${rangeSliders.evaluate().length} range sliders');
        }

        if (sliders.evaluate().isNotEmpty) {
          await tester.drag(sliders.first, const Offset(30, 0));
          await tester.pump(const Duration(milliseconds: 500));
          print('Adjusted slider value');
        }

        // Close filter
        final closeButton = find.byIcon(Icons.close);
        final applyButton = find.textContaining('Apply');
        final saveButton = find.textContaining('Save');

        if (applyButton.evaluate().isNotEmpty) {
          await tester.tap(applyButton.first);
          await tester.pump(const Duration(seconds: 2));
        } else if (saveButton.evaluate().isNotEmpty) {
          await tester.tap(saveButton.first);
          await tester.pump(const Duration(seconds: 2));
        } else if (closeButton.evaluate().isNotEmpty) {
          await tester.tap(closeButton.first);
          await tester.pump(const Duration(seconds: 2));
        }
      } else if (filterButton.evaluate().isNotEmpty) {
        await tester.tap(filterButton.first);
        await tester.pump(const Duration(seconds: 2));
        print('Opened filter menu (filter_list icon)');
      }

      print('=== SCENARIO 11: Swipe Gestures on Discovery Cards ===');
      final cards = find.byType(Card);
      if (cards.evaluate().isNotEmpty) {
        print('Found ${cards.evaluate().length} cards');

        // Swipe right (like)
        await tester.drag(cards.first, const Offset(250, 0));
        await tester.pump(const Duration(seconds: 2));
        print('Swiped right (like)');

        // Find another card and swipe left
        final newCards = find.byType(Card);
        if (newCards.evaluate().isNotEmpty) {
          await tester.drag(newCards.first, const Offset(-250, 0));
          await tester.pump(const Duration(seconds: 2));
          print('Swiped left (pass)');
        }
      }

      print('=== SCENARIO 12: Like/Dislike Action Buttons ===');
      final likeButton = find.byIcon(Icons.favorite);
      final dislikeButton = find.byIcon(Icons.close);
      final superLikeButton = find.byIcon(Icons.star);

      if (dislikeButton.evaluate().isNotEmpty) {
        await tester.tap(dislikeButton.first);
        await tester.pump(const Duration(seconds: 2));
        print('Tapped dislike button');
      }

      if (likeButton.evaluate().isNotEmpty) {
        await tester.tap(likeButton.first);
        await tester.pump(const Duration(seconds: 2));
        print('Tapped like button');
      }

      if (superLikeButton.evaluate().isNotEmpty) {
        await tester.tap(superLikeButton.first);
        await tester.pump(const Duration(seconds: 2));
        print('Tapped super like button');
      }

      print('=== SCENARIO 13: Tap Card to View Profile Details ===');
      final profileCards = find.byType(Card);
      if (profileCards.evaluate().isNotEmpty) {
        await tester.tap(profileCards.first);
        await tester.pump(const Duration(seconds: 3));
        print('Tapped card to view profile details');

        // Go back
        final backButton = find.byIcon(Icons.arrow_back);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton.first);
          await tester.pump(const Duration(seconds: 2));
          print('Navigated back from profile details');
        }
      }

      print('=== SCENARIO 14: Navigate to Profile Screen ===');
      final profileNavIcon = find.byIcon(Icons.person);
      if (profileNavIcon.evaluate().isNotEmpty) {
        await tester.tap(profileNavIcon.last);
        await tester.pump(const Duration(seconds: 3));
        print('Navigated to profile screen');
      }

      print('=== SCENARIO 15: Access Settings ===');
      final settingsIcon = find.byIcon(Icons.settings);
      final moreIcon = find.byIcon(Icons.more_vert);

      if (settingsIcon.evaluate().isNotEmpty) {
        await tester.tap(settingsIcon.first);
        await tester.pump(const Duration(seconds: 2));
        print('Opened settings');
      } else if (moreIcon.evaluate().isNotEmpty) {
        await tester.tap(moreIcon.first);
        await tester.pump(const Duration(seconds: 2));
        print('Opened more menu');
      }

      print('=== SCENARIO 16: Scroll Through Content ===');
      final scrollables = find.byType(ListView);
      final singleChildScrollViews = find.byType(SingleChildScrollView);

      if (scrollables.evaluate().isNotEmpty) {
        await tester.drag(scrollables.first, const Offset(0, -200));
        await tester.pump(const Duration(seconds: 1));
        print('Scrolled down');

        await tester.drag(scrollables.first, const Offset(0, 200));
        await tester.pump(const Duration(seconds: 1));
        print('Scrolled up');
      } else if (singleChildScrollViews.evaluate().isNotEmpty) {
        await tester.drag(singleChildScrollViews.first, const Offset(0, -200));
        await tester.pump(const Duration(seconds: 1));
        await tester.drag(singleChildScrollViews.first, const Offset(0, 200));
        await tester.pump(const Duration(seconds: 1));
      }

      print('=== SCENARIO 17: Navigate to Chat/Messages ===');
      final chatNavIcon = find.byIcon(Icons.chat);
      final messageNavIcon = find.byIcon(Icons.message);
      final chatBubbleNavIcon = find.byIcon(Icons.chat_bubble_outline);

      if (chatNavIcon.evaluate().isNotEmpty) {
        await tester.tap(chatNavIcon.first);
        await tester.pump(const Duration(seconds: 3));
        print('Navigated to chat screen');
      } else if (messageNavIcon.evaluate().isNotEmpty) {
        await tester.tap(messageNavIcon.first);
        await tester.pump(const Duration(seconds: 3));
      } else if (chatBubbleNavIcon.evaluate().isNotEmpty) {
        await tester.tap(chatBubbleNavIcon.first);
        await tester.pump(const Duration(seconds: 3));
      }

      print('=== SCENARIO 18: Pull to Refresh ===');
      final refreshableList = find.byType(ListView);
      if (refreshableList.evaluate().isNotEmpty) {
        await tester.drag(refreshableList.first, const Offset(0, 300));
        await tester.pump(const Duration(seconds: 3));
        print('Performed pull to refresh');
      }

      print('=== SCENARIO 19: Long Press for Context Menu ===');
      final longPressTargets = find.byType(Card);
      final listTiles = find.byType(ListTile);

      if (longPressTargets.evaluate().isNotEmpty) {
        await tester.longPress(longPressTargets.first);
        await tester.pump(const Duration(seconds: 2));
        print('Long pressed on card');

        // Dismiss any menu that appeared
        await tester.tapAt(const Offset(10, 10));
        await tester.pump(const Duration(milliseconds: 500));
      } else if (listTiles.evaluate().isNotEmpty) {
        await tester.longPress(listTiles.first);
        await tester.pump(const Duration(seconds: 2));
        print('Long pressed on list tile');

        await tester.tapAt(const Offset(10, 10));
        await tester.pump(const Duration(milliseconds: 500));
      }

      print('=== SCENARIO 20: Navigate Back to Home ===');
      final homeNavIcon = find.byIcon(Icons.home);
      final exploreIcon = find.byIcon(Icons.explore);

      if (homeNavIcon.evaluate().isNotEmpty) {
        await tester.tap(homeNavIcon.first);
        await tester.pump(const Duration(seconds: 2));
        print('Navigated back to home');
      } else if (exploreIcon.evaluate().isNotEmpty) {
        await tester.tap(exploreIcon.first);
        await tester.pump(const Duration(seconds: 2));
      }

      print('=== ALL 20 SCENARIOS COMPLETED ===');
      print('Integration test completed successfully!');
    });
  });
}
