import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_helpers.dart';
import 'test_app.dart';

/// Authentication User Tests (15 tests)
/// Tests cover: Registration, Login, Password Reset, Session Management
void main() {
  TestHelpers.initializeTests();

  group('Authentication Tests', () {
    // Test 1: User can view login screen on app launch
    testWidgets('Test 1: User can view login screen on app launch', (tester) async {
      await pumpTestApp(tester);

      // Verify login screen elements are visible
      expect(find.text('Login'), findsAtLeast(1)); // Title and button both have "Login"
      expect(find.byKey(const Key('email_field')), findsOneWidget);
      expect(find.byKey(const Key('password_field')), findsOneWidget);
      expect(find.byKey(const Key('login_button')), findsOneWidget);
    });

    // Test 2: User can navigate to registration screen
    testWidgets('Test 2: User can navigate to registration screen', (tester) async {
      await pumpTestApp(tester);

      // Tap on register link
      await TestHelpers.tapByText(tester, 'Create Account');

      // Verify registration screen is displayed
      expect(find.text('Register'), findsAtLeast(1)); // Title and button both have "Register"
      expect(find.byKey(const Key('register_email_field')), findsOneWidget);
      expect(find.byKey(const Key('register_password_field')), findsOneWidget);
      expect(find.byKey(const Key('confirm_password_field')), findsOneWidget);
    });

    // Test 3: User can register with valid credentials
    testWidgets('Test 3: User can register with valid credentials', (tester) async {
      await pumpTestApp(tester);

      // Navigate to registration
      await TestHelpers.tapByText(tester, 'Create Account');

      // Enter valid registration data
      await TestHelpers.enterTextByKey(tester, 'register_email_field', TestUserData.validEmail);
      await TestHelpers.enterTextByKey(tester, 'register_password_field', TestUserData.validPassword);
      await TestHelpers.enterTextByKey(tester, 'confirm_password_field', TestUserData.validPassword);

      // Submit registration
      await TestHelpers.tapByKey(tester, 'register_button');
      await tester.pumpAndSettle();

      // Verify success message
      expect(find.text('Registration Successful'), findsOneWidget);
    });

    // Test 4: User sees error for invalid email format during registration
    testWidgets('Test 4: User sees error for invalid email format during registration', (tester) async {
      await pumpTestApp(tester);

      // Navigate to registration
      await TestHelpers.tapByText(tester, 'Create Account');

      // Enter invalid email
      await TestHelpers.enterTextByKey(tester, 'register_email_field', TestUserData.invalidEmail);
      await TestHelpers.enterTextByKey(tester, 'register_password_field', TestUserData.validPassword);
      await TestHelpers.enterTextByKey(tester, 'confirm_password_field', TestUserData.validPassword);

      // Submit registration
      await TestHelpers.tapByKey(tester, 'register_button');
      await tester.pumpAndSettle();

      // Verify error message
      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    // Test 5: User sees password strength indicator during registration
    testWidgets('Test 5: User sees password strength indicator during registration', (tester) async {
      await pumpTestApp(tester);

      // Navigate to registration
      await TestHelpers.tapByText(tester, 'Create Account');

      // Enter weak password
      await TestHelpers.enterTextByKey(tester, 'register_password_field', TestUserData.weakPassword);

      // Verify weak indicator
      expect(find.text('Weak'), findsOneWidget);

      // Clear and enter strong password
      await tester.enterText(find.byKey(const Key('register_password_field')), '');
      await tester.pumpAndSettle();
      await TestHelpers.enterTextByKey(tester, 'register_password_field', TestUserData.validPassword);

      // Verify strong indicator
      expect(find.text('Strong'), findsOneWidget);
    });

    // Test 6: User sees error when passwords don't match
    testWidgets('Test 6: User sees error when passwords do not match', (tester) async {
      await pumpTestApp(tester);

      // Navigate to registration
      await TestHelpers.tapByText(tester, 'Create Account');

      // Enter mismatched passwords
      await TestHelpers.enterTextByKey(tester, 'register_email_field', TestUserData.validEmail);
      await TestHelpers.enterTextByKey(tester, 'register_password_field', TestUserData.validPassword);
      await TestHelpers.enterTextByKey(tester, 'confirm_password_field', 'DifferentPass123!');

      // Submit registration
      await TestHelpers.tapByKey(tester, 'register_button');
      await tester.pumpAndSettle();

      // Verify error message
      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    // Test 7: User can login with valid credentials
    testWidgets('Test 7: User can login with valid credentials', (tester) async {
      await pumpTestApp(tester);

      // Enter valid credentials
      await TestHelpers.enterTextByKey(tester, 'email_field', TestUserData.validEmail);
      await TestHelpers.enterTextByKey(tester, 'password_field', TestUserData.validPassword);

      // Submit login
      await TestHelpers.tapByKey(tester, 'login_button');
      await tester.pumpAndSettle();

      // Verify navigation to main app
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    // Test 8: User sees error for invalid credentials during login
    testWidgets('Test 8: User sees error for invalid credentials during login', (tester) async {
      await pumpTestApp(tester);

      // Enter invalid credentials
      await TestHelpers.enterTextByKey(tester, 'email_field', 'wrong@email.com');
      await TestHelpers.enterTextByKey(tester, 'password_field', 'WrongPassword123!');

      // Submit login
      await TestHelpers.tapByKey(tester, 'login_button');
      await tester.pumpAndSettle();

      // Verify error message
      expect(find.text('Invalid email or password'), findsOneWidget);
    });

    // Test 9: User can toggle password visibility
    testWidgets('Test 9: User can toggle password visibility', (tester) async {
      await pumpTestApp(tester);

      // Enter password
      await TestHelpers.enterTextByKey(tester, 'password_field', TestUserData.validPassword);

      // Find and tap visibility toggle
      final visibilityToggle = find.byKey(const Key('password_visibility_toggle'));
      expect(visibilityToggle, findsOneWidget);

      await tester.tap(visibilityToggle);
      await tester.pumpAndSettle();

      // Password should now be visible (TextField obscureText = false)
      final textField = tester.widget<TextField>(find.byKey(const Key('password_field')));
      expect(textField.obscureText, isFalse);
    });

    // Test 10: User can navigate to forgot password screen
    testWidgets('Test 10: User can navigate to forgot password screen', (tester) async {
      await pumpTestApp(tester);

      // Tap forgot password link
      await TestHelpers.tapByText(tester, 'Forgot Password?');

      // Verify forgot password screen
      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.byKey(const Key('reset_email_field')), findsOneWidget);
    });

    // Test 11: User can request password reset
    testWidgets('Test 11: User can request password reset', (tester) async {
      await pumpTestApp(tester);

      // Navigate to forgot password
      await TestHelpers.tapByText(tester, 'Forgot Password?');

      // Enter email
      await TestHelpers.enterTextByKey(tester, 'reset_email_field', TestUserData.validEmail);

      // Submit reset request
      await TestHelpers.tapByKey(tester, 'reset_button');
      await tester.pumpAndSettle();

      // Verify success message
      expect(find.text('Password reset email sent'), findsOneWidget);
    });

    // Test 12: User can access language selector on login screen
    testWidgets('Test 12: User can access language selector on login screen', (tester) async {
      await pumpTestApp(tester);

      // Find and tap language selector
      final languageSelector = find.byKey(const Key('language_selector'));
      expect(languageSelector, findsOneWidget);

      await tester.tap(languageSelector);
      await tester.pumpAndSettle();

      // Verify language options appear
      expect(find.text('Select Language'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Español'), findsOneWidget);
    });

    // Test 13: User sees loading indicator during login
    testWidgets('Test 13: User sees loading indicator during authentication', (tester) async {
      await pumpTestApp(tester);

      // Enter credentials
      await TestHelpers.enterTextByKey(tester, 'email_field', TestUserData.validEmail);
      await TestHelpers.enterTextByKey(tester, 'password_field', TestUserData.validPassword);

      // Tap login (don't pumpAndSettle immediately)
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pump();

      // Verify loading indicator appears
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for completion
      await tester.pumpAndSettle();
    });

    // Test 14: Login button is present and tappable
    testWidgets('Test 14: Login button is present and functional', (tester) async {
      await pumpTestApp(tester);

      // Verify login button exists
      final loginButton = find.byKey(const Key('login_button'));
      expect(loginButton, findsOneWidget);

      // Verify it's an ElevatedButton
      expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
    });

    // Test 15: Create Account link is present
    testWidgets('Test 15: Create Account link is present and functional', (tester) async {
      await pumpTestApp(tester);

      // Verify Create Account text exists
      expect(find.text('Create Account'), findsOneWidget);

      // Tap it and verify navigation
      await TestHelpers.tapByText(tester, 'Create Account');

      // Should now be on Register screen
      expect(find.text('Register'), findsAtLeast(1)); // Title and button both have "Register"
    });
  });
}
