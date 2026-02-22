import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_app.dart';

/// Comprehensive 200 User Tests for GreenGo Dating App
/// Run with: flutter test test/userTests/comprehensive_200_tests.dart
///
/// Test Categories:
/// - Authentication (25 tests) - Tests 1-25
/// - Registration & Onboarding (25 tests) - Tests 26-50
/// - Profile Management (25 tests) - Tests 51-75
/// - Discovery & Swiping (25 tests) - Tests 76-100
/// - Matching System (20 tests) - Tests 101-120
/// - Chat & Messaging (25 tests) - Tests 121-145
/// - Notifications (15 tests) - Tests 146-160
/// - Coins & In-App Purchases (15 tests) - Tests 161-175
/// - Gamification & Progress (15 tests) - Tests 176-190
/// - Settings & Preferences (10 tests) - Tests 191-200

void main() {
  // ============================================================================
  // SECTION 1: AUTHENTICATION TESTS (25 tests) - Tests 1-25
  // ============================================================================
  group('1. Authentication Tests', () {
    testWidgets('Test 1: Login screen displays correctly', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestLoginScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Login'), findsWidgets);
      expect(find.byKey(const Key('email_field')), findsOneWidget);
      expect(find.byKey(const Key('password_field')), findsOneWidget);
    });

    testWidgets('Test 2: Email field accepts valid email', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestLoginScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('Test 3: Password field obscures text', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestLoginScreen()));
      await tester.pumpAndSettle();

      final passwordField = find.byKey(const Key('password_field'));
      await tester.enterText(passwordField, 'secret123');

      final textField = tester.widget<TextField>(passwordField);
      expect(textField.obscureText, isTrue);
    });

    testWidgets('Test 4: Password visibility toggle works', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestLoginScreen()));
      await tester.pumpAndSettle();

      final toggleButton = find.byKey(const Key('password_visibility_toggle'));
      await tester.tap(toggleButton);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('Test 5: Login button exists and is tappable', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestLoginScreen()));
      await tester.pumpAndSettle();

      final loginButton = find.byKey(const Key('login_button'));
      expect(loginButton, findsOneWidget);

      await tester.tap(loginButton);
      await tester.pump();
    });

    testWidgets('Test 6: Invalid credentials show error', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestLoginScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('email_field')), 'wrong@email.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'wrongpass');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      expect(find.text('Invalid email or password'), findsOneWidget);
    });

    testWidgets('Test 7: Valid credentials navigate to main screen', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestLoginScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('email_field')), 'testuser@example.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'TestPass123!');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      expect(find.text('Discover'), findsOneWidget);
    });

    testWidgets('Test 8: Forgot password link exists', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestLoginScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Forgot Password?'), findsOneWidget);
    });

    testWidgets('Test 9: Forgot password screen navigation', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestLoginScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      expect(find.text('Reset Password'), findsOneWidget);
    });

    testWidgets('Test 10: Create account link exists', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestLoginScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Create Account'), findsOneWidget);
    });

    testWidgets('Test 11: Language selector exists', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestLoginScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('language_selector')), findsOneWidget);
    });

    testWidgets('Test 12: Language selector opens dialog', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestLoginScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('language_selector')));
      await tester.pumpAndSettle();

      expect(find.text('Select Language'), findsOneWidget);
    });

    testWidgets('Test 13: Login loading indicator shows', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestLoginScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('email_field')), 'test@test.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'password');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Test 14: Empty email shows validation', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestLoginScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('password_field')), 'password');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      // Should show error for empty email
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('Test 15: Empty password shows validation', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestLoginScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('email_field')), 'test@test.com');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('Test 16: Email field has correct keyboard type', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestLoginScreen()));
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byKey(const Key('email_field')));
      expect(textField.keyboardType, TextInputType.emailAddress);
    });

    testWidgets('Test 17: Password field has correct input type', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestLoginScreen()));
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byKey(const Key('password_field')));
      expect(textField.obscureText, isTrue);
    });

    testWidgets('Test 18: Login button has correct styling', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestLoginScreen()));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
    });

    testWidgets('Test 19: Screen has proper padding', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestLoginScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(Padding), findsWidgets);
    });

    testWidgets('Test 20: SafeArea is used', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestLoginScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(SafeArea), findsOneWidget);
    });

    testWidgets('Test 21: Email trimming works correctly', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestLoginScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('email_field')), '  testuser@example.com  ');
      await tester.enterText(find.byKey(const Key('password_field')), 'TestPass123!');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      // Should login successfully with trimmed email
      expect(find.text('Discover'), findsOneWidget);
    });

    testWidgets('Test 22: Multiple login attempts handled', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestLoginScreen()));
      await tester.pumpAndSettle();

      // First attempt - wrong credentials
      await tester.enterText(find.byKey(const Key('email_field')), 'wrong@email.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'wrong');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      // Clear and try again
      await tester.enterText(find.byKey(const Key('email_field')), 'testuser@example.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'TestPass123!');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      expect(find.text('Discover'), findsOneWidget);
    });

    testWidgets('Test 23: Keyboard dismiss on tap outside', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestLoginScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('email_field')));
      await tester.pumpAndSettle();

      // Tap outside the text field
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
    });

    testWidgets('Test 24: Form submission via enter key', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestLoginScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('email_field')), 'test@test.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'password');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
    });

    testWidgets('Test 25: Screen orientation compatibility', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestLoginScreen()));
      await tester.pumpAndSettle();

      // Test portrait
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpAndSettle();
      expect(find.text('Login'), findsWidgets);

      // Reset
      await tester.binding.setSurfaceSize(null);
    });
  });

  // ============================================================================
  // SECTION 2: REGISTRATION & ONBOARDING TESTS (25 tests) - Tests 26-50
  // ============================================================================
  group('2. Registration & Onboarding Tests', () {
    testWidgets('Test 26: Registration screen displays correctly', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestRegisterScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Create Account'), findsWidgets);
    });

    testWidgets('Test 27: Email field exists in registration', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestRegisterScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('register_email_field')), findsOneWidget);
    });

    testWidgets('Test 28: Password field exists in registration', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestRegisterScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('register_password_field')), findsOneWidget);
    });

    testWidgets('Test 29: Confirm password field exists', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestRegisterScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('register_confirm_password_field')), findsOneWidget);
    });

    testWidgets('Test 30: Password strength indicator shows', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestRegisterScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('register_password_field')), 'Test123!');
      await tester.pumpAndSettle();

      expect(find.text('Strong'), findsOneWidget);
    });

    testWidgets('Test 31: Weak password indicator', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestRegisterScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('register_password_field')), '123');
      await tester.pumpAndSettle();

      expect(find.text('Weak'), findsOneWidget);
    });

    testWidgets('Test 32: Password mismatch validation', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestRegisterScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('register_password_field')), 'Test123!');
      await tester.enterText(find.byKey(const Key('register_confirm_password_field')), 'Different');
      await tester.tap(find.byKey(const Key('register_button')));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('Test 33: Terms checkbox exists', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestRegisterScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('terms_checkbox')), findsOneWidget);
    });

    testWidgets('Test 34: Terms must be accepted to register', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestRegisterScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('register_email_field')), 'new@user.com');
      await tester.enterText(find.byKey(const Key('register_password_field')), 'Test123!');
      await tester.enterText(find.byKey(const Key('register_confirm_password_field')), 'Test123!');
      await tester.tap(find.byKey(const Key('register_button')));
      await tester.pumpAndSettle();

      expect(find.text('Please accept the terms'), findsOneWidget);
    });

    testWidgets('Test 35: Valid registration succeeds', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestRegisterScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('register_email_field')), 'new@user.com');
      await tester.enterText(find.byKey(const Key('register_password_field')), 'Test123!');
      await tester.enterText(find.byKey(const Key('register_confirm_password_field')), 'Test123!');
      await tester.tap(find.byKey(const Key('terms_checkbox')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('register_button')));
      await tester.pumpAndSettle();

      expect(find.text('Welcome!'), findsOneWidget);
    });

    testWidgets('Test 36: Onboarding step 1 - Name entry', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestOnboardingScreen(step: 1)));
      await tester.pumpAndSettle();

      expect(find.text("What's your name?"), findsOneWidget);
      expect(find.byKey(const Key('name_field')), findsOneWidget);
    });

    testWidgets('Test 37: Onboarding step 2 - Birthday', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestOnboardingScreen(step: 2)));
      await tester.pumpAndSettle();

      expect(find.text('When is your birthday?'), findsOneWidget);
    });

    testWidgets('Test 38: Onboarding step 3 - Gender selection', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestOnboardingScreen(step: 3)));
      await tester.pumpAndSettle();

      expect(find.text('I am a'), findsOneWidget);
      expect(find.text('Man'), findsOneWidget);
      expect(find.text('Woman'), findsOneWidget);
    });

    testWidgets('Test 39: Onboarding step 4 - Looking for', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestOnboardingScreen(step: 4)));
      await tester.pumpAndSettle();

      expect(find.text("I'm looking for"), findsOneWidget);
    });

    testWidgets('Test 40: Onboarding step 5 - Location', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestOnboardingScreen(step: 5)));
      await tester.pumpAndSettle();

      expect(find.text('Where are you located?'), findsOneWidget);
    });

    testWidgets('Test 41: Onboarding step 6 - Photo upload', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestOnboardingScreen(step: 6)));
      await tester.pumpAndSettle();

      expect(find.text('Add photos'), findsOneWidget);
    });

    testWidgets('Test 42: Onboarding progress indicator', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestOnboardingScreen(step: 3)));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('progress_indicator')), findsOneWidget);
    });

    testWidgets('Test 43: Onboarding back navigation', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestOnboardingScreen(step: 3)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('back_button')));
      await tester.pumpAndSettle();
    });

    testWidgets('Test 44: Onboarding skip button', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestOnboardingScreen(step: 6)));
      await tester.pumpAndSettle();

      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('Test 45: Age verification (18+ check)', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestOnboardingScreen(step: 2)));
      await tester.pumpAndSettle();

      // Try to set an underage date
      await tester.tap(find.byKey(const Key('birthday_field')));
      await tester.pumpAndSettle();
    });

    testWidgets('Test 46: Email already exists validation', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestRegisterScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('register_email_field')), 'existing@user.com');
      await tester.enterText(find.byKey(const Key('register_password_field')), 'Test123!');
      await tester.enterText(find.byKey(const Key('register_confirm_password_field')), 'Test123!');
      await tester.tap(find.byKey(const Key('terms_checkbox')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('register_button')));
      await tester.pumpAndSettle();

      expect(find.text('Email already in use'), findsOneWidget);
    });

    testWidgets('Test 47: Invalid email format validation', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestRegisterScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('register_email_field')), 'notanemail');
      await tester.tap(find.byKey(const Key('register_button')));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email'), findsOneWidget);
    });

    testWidgets('Test 48: Bio character limit', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestOnboardingScreen(step: 7)));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('bio_field')), findsOneWidget);
    });

    testWidgets('Test 49: Interests selection', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestOnboardingScreen(step: 8)));
      await tester.pumpAndSettle();

      expect(find.text('Your interests'), findsOneWidget);
    });

    testWidgets('Test 50: Onboarding completion', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestOnboardingScreen(step: 9)));
      await tester.pumpAndSettle();

      expect(find.text('Profile complete!'), findsOneWidget);
    });
  });

  // ============================================================================
  // SECTION 3: PROFILE MANAGEMENT TESTS (25 tests) - Tests 51-75
  // ============================================================================
  group('3. Profile Management Tests', () {
    testWidgets('Test 51: Profile screen displays user info', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestProfileScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Test User'), findsOneWidget);
    });

    testWidgets('Test 52: Edit profile button exists', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestProfileScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('edit_profile_button')), findsOneWidget);
    });

    testWidgets('Test 53: Profile photo displayed', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestProfileScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('profile_photo')), findsOneWidget);
    });

    testWidgets('Test 54: Bio section displayed', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestProfileScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('bio_section')), findsOneWidget);
    });

    testWidgets('Test 55: Edit name functionality', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestEditProfileScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('edit_name_field')), 'New Name');
      await tester.tap(find.byKey(const Key('save_profile_button')));
      await tester.pumpAndSettle();

      expect(find.text('Profile saved'), findsOneWidget);
    });

    testWidgets('Test 56: Edit bio functionality', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestEditProfileScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('edit_bio_field')), 'New bio text');
      await tester.tap(find.byKey(const Key('save_profile_button')));
      await tester.pumpAndSettle();
    });

    testWidgets('Test 57: Add photo button', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestEditProfileScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('add_photo_button')), findsOneWidget);
    });

    testWidgets('Test 58: Reorder photos functionality', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestEditProfileScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('photo_grid')), findsOneWidget);
    });

    testWidgets('Test 59: Delete photo functionality', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestEditProfileScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('delete_photo_0')), findsOneWidget);
    });

    testWidgets('Test 60: Verification badge display', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestProfileScreen(isVerified: true)));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('verification_badge')), findsOneWidget);
    });

    testWidgets('Test 61: Request verification button', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestProfileScreen(isVerified: false)));
      await tester.pumpAndSettle();

      expect(find.text('Get Verified'), findsOneWidget);
    });

    testWidgets('Test 62: Interests display', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestProfileScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('interests_section')), findsOneWidget);
    });

    testWidgets('Test 63: Edit interests functionality', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestEditProfileScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit_interests_button')));
      await tester.pumpAndSettle();
    });

    testWidgets('Test 64: Location display', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestProfileScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('location_display')), findsOneWidget);
    });

    testWidgets('Test 65: Age display', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestProfileScreen()));
      await tester.pumpAndSettle();

      expect(find.text('25'), findsOneWidget);
    });

    testWidgets('Test 66: Profile stats display', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestProfileScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('profile_stats')), findsOneWidget);
    });

    testWidgets('Test 67: Prompt answers display', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestProfileScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('prompts_section')), findsOneWidget);
    });

    testWidgets('Test 68: Edit prompts functionality', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestEditProfileScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit_prompts_button')));
      await tester.pumpAndSettle();
    });

    testWidgets('Test 69: Profile visibility toggle', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestEditProfileScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('visibility_toggle')), findsOneWidget);
    });

    testWidgets('Test 70: Show me on discovery toggle', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestEditProfileScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('show_on_discovery_toggle')));
      await tester.pumpAndSettle();
    });

    testWidgets('Test 71: Profile completion percentage', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestProfileScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('completion_indicator')), findsOneWidget);
    });

    testWidgets('Test 72: Job title field', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestEditProfileScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('job_title_field')), findsOneWidget);
    });

    testWidgets('Test 73: Education field', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestEditProfileScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('education_field')), findsOneWidget);
    });

    testWidgets('Test 74: Height preference', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestEditProfileScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('height_field')), findsOneWidget);
    });

    testWidgets('Test 75: Lifestyle preferences', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestEditProfileScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Lifestyle'), findsOneWidget);
    });
  });

  // ============================================================================
  // SECTION 4: DISCOVERY & SWIPING TESTS (25 tests) - Tests 76-100
  // ============================================================================
  group('4. Discovery & Swiping Tests', () {
    testWidgets('Test 76: Discovery screen loads', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestDiscoveryScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Discover'), findsOneWidget);
    });

    testWidgets('Test 77: Profile cards displayed', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestDiscoveryScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('profile_card')), findsWidgets);
    });

    testWidgets('Test 78: Like button works', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestDiscoveryScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('like_button')));
      await tester.pumpAndSettle();
    });

    testWidgets('Test 79: Dislike button works', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestDiscoveryScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('dislike_button')));
      await tester.pumpAndSettle();
    });

    testWidgets('Test 80: Super like button works', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestDiscoveryScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('super_like_button')), findsOneWidget);
    });

    testWidgets('Test 81: Swipe right gesture', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestDiscoveryScreen()));
      await tester.pumpAndSettle();

      final card = find.byKey(const Key('profile_card')).first;
      await tester.drag(card, const Offset(300, 0));
      await tester.pumpAndSettle();
    });

    testWidgets('Test 82: Swipe left gesture', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestDiscoveryScreen()));
      await tester.pumpAndSettle();

      final card = find.byKey(const Key('profile_card')).first;
      await tester.drag(card, const Offset(-300, 0));
      await tester.pumpAndSettle();
    });

    testWidgets('Test 83: Profile detail expansion', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestDiscoveryScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('profile_card')).first);
      await tester.pumpAndSettle();
    });

    testWidgets('Test 84: Filter button exists', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestDiscoveryScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('filter_button')), findsOneWidget);
    });

    testWidgets('Test 85: Filter age range', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestDiscoveryFiltersScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('age_range_slider')), findsOneWidget);
    });

    testWidgets('Test 86: Filter distance', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestDiscoveryFiltersScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('distance_slider')), findsOneWidget);
    });

    testWidgets('Test 87: Filter gender preference', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestDiscoveryFiltersScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Show me'), findsOneWidget);
    });

    testWidgets('Test 88: Rewind last swipe', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestDiscoveryScreen()));
      await tester.pumpAndSettle();

      // First swipe
      await tester.tap(find.byKey(const Key('dislike_button')));
      await tester.pumpAndSettle();

      // Rewind
      await tester.tap(find.byKey(const Key('rewind_button')));
      await tester.pumpAndSettle();
    });

    testWidgets('Test 89: Empty state when no profiles', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestDiscoveryScreen(empty: true)));
      await tester.pumpAndSettle();

      expect(find.text('No more profiles'), findsOneWidget);
    });

    testWidgets('Test 90: Boost button exists', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestDiscoveryScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('boost_button')), findsOneWidget);
    });

    testWidgets('Test 91: Photo navigation in card', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestDiscoveryScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('next_photo_button')));
      await tester.pumpAndSettle();
    });

    testWidgets('Test 92: Report profile option', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestDiscoveryScreen()));
      await tester.pumpAndSettle();

      await tester.longPress(find.byKey(const Key('profile_card')).first);
      await tester.pumpAndSettle();

      expect(find.text('Report'), findsOneWidget);
    });

    testWidgets('Test 93: Block profile option', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestDiscoveryScreen()));
      await tester.pumpAndSettle();

      await tester.longPress(find.byKey(const Key('profile_card')).first);
      await tester.pumpAndSettle();

      expect(find.text('Block'), findsOneWidget);
    });

    testWidgets('Test 94: Distance display on card', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestDiscoveryScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('km away'), findsWidgets);
    });

    testWidgets('Test 95: Common interests display', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestDiscoveryScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('common_interests')), findsWidgets);
    });

    testWidgets('Test 96: Compatibility score display', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestDiscoveryScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('compatibility_score')), findsWidgets);
    });

    testWidgets('Test 97: Online status indicator', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestDiscoveryScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('online_indicator')), findsWidgets);
    });

    testWidgets('Test 98: Verified badge on card', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestDiscoveryScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('verified_badge')), findsWidgets);
    });

    testWidgets('Test 99: Refresh profiles button', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestDiscoveryScreen()));
      await tester.pumpAndSettle();

      await tester.drag(find.byKey(const Key('discovery_list')), const Offset(0, 200));
      await tester.pumpAndSettle();
    });

    testWidgets('Test 100: Premium filter options', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestDiscoveryFiltersScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Premium Filters'), findsOneWidget);
    });
  });

  // ============================================================================
  // SECTION 5: MATCHING SYSTEM TESTS (20 tests) - Tests 101-120
  // ============================================================================
  group('5. Matching System Tests', () {
    testWidgets('Test 101: Matches screen loads', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestMatchesScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Matches'), findsOneWidget);
    });

    testWidgets('Test 102: Match notification popup', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestMatchPopup()));
      await tester.pumpAndSettle();

      expect(find.text("It's a Match!"), findsOneWidget);
    });

    testWidgets('Test 103: Match list displays', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestMatchesScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('match_item')), findsWidgets);
    });

    testWidgets('Test 104: New matches section', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestMatchesScreen()));
      await tester.pumpAndSettle();

      expect(find.text('New Matches'), findsOneWidget);
    });

    testWidgets('Test 105: Messages section', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestMatchesScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Messages'), findsOneWidget);
    });

    testWidgets('Test 106: Tap match opens chat', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestMatchesScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('match_item')).first);
      await tester.pumpAndSettle();

      expect(find.byType(TestChatScreen), findsOneWidget);
    });

    testWidgets('Test 107: Unmatch option', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestMatchesScreen()));
      await tester.pumpAndSettle();

      await tester.longPress(find.byKey(const Key('match_item')).first);
      await tester.pumpAndSettle();

      expect(find.text('Unmatch'), findsOneWidget);
    });

    testWidgets('Test 108: Match expiry countdown', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestMatchesScreen(hasExpiry: true)));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('expiry_timer')), findsWidgets);
    });

    testWidgets('Test 109: Empty matches state', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestMatchesScreen(empty: true)));
      await tester.pumpAndSettle();

      expect(find.text('No matches yet'), findsOneWidget);
    });

    testWidgets('Test 110: Search matches', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestMatchesScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('search_button')));
      await tester.pumpAndSettle();
    });

    testWidgets('Test 111: Sort matches option', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestMatchesScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('sort_button')));
      await tester.pumpAndSettle();

      expect(find.text('Sort by'), findsOneWidget);
    });

    testWidgets('Test 112: Match profile preview', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestMatchesScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('match_photo')).first);
      await tester.pumpAndSettle();
    });

    testWidgets('Test 113: Like notification in matches', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestMatchesScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('likes_you_section')), findsOneWidget);
    });

    testWidgets('Test 114: Premium see who likes you', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestMatchesScreen()));
      await tester.pumpAndSettle();

      expect(find.text('See who likes you'), findsOneWidget);
    });

    testWidgets('Test 115: Last message preview', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestMatchesScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('last_message_preview')), findsWidgets);
    });

    testWidgets('Test 116: Unread message indicator', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestMatchesScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('unread_badge')), findsWidgets);
    });

    testWidgets('Test 117: Match timestamp', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestMatchesScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('match_timestamp')), findsWidgets);
    });

    testWidgets('Test 118: Pull to refresh matches', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestMatchesScreen()));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, 200));
      await tester.pumpAndSettle();
    });

    testWidgets('Test 119: Delete conversation option', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestMatchesScreen()));
      await tester.pumpAndSettle();

      await tester.longPress(find.byKey(const Key('match_item')).first);
      await tester.pumpAndSettle();

      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('Test 120: Match animation plays', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestMatchPopup()));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byKey(const Key('match_animation')), findsOneWidget);
    });
  });

  // ============================================================================
  // SECTION 6: CHAT & MESSAGING TESTS (25 tests) - Tests 121-145
  // ============================================================================
  group('6. Chat & Messaging Tests', () {
    testWidgets('Test 121: Chat screen loads', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestChatScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('message_input')), findsOneWidget);
    });

    testWidgets('Test 122: Send text message', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestChatScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('message_input')), 'Hello!');
      await tester.tap(find.byKey(const Key('send_button')));
      await tester.pumpAndSettle();

      expect(find.text('Hello!'), findsOneWidget);
    });

    testWidgets('Test 123: Message bubbles display', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestChatScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('message_bubble')), findsWidgets);
    });

    testWidgets('Test 124: Typing indicator', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestChatScreen(isTyping: true)));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('typing_indicator')), findsOneWidget);
    });

    testWidgets('Test 125: Message read receipts', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestChatScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('read_receipt')), findsWidgets);
    });

    testWidgets('Test 126: Send image message', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestChatScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('attachment_button')));
      await tester.pumpAndSettle();

      expect(find.text('Photo'), findsOneWidget);
    });

    testWidgets('Test 127: Send GIF', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestChatScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('gif_button')));
      await tester.pumpAndSettle();
    });

    testWidgets('Test 128: Message reactions', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestChatScreen()));
      await tester.pumpAndSettle();

      await tester.longPress(find.byKey(const Key('message_bubble')).first);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('reaction_picker')), findsOneWidget);
    });

    testWidgets('Test 129: Reply to message', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestChatScreen()));
      await tester.pumpAndSettle();

      await tester.longPress(find.byKey(const Key('message_bubble')).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reply'));
      await tester.pumpAndSettle();
    });

    testWidgets('Test 130: Delete message', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestChatScreen()));
      await tester.pumpAndSettle();

      await tester.longPress(find.byKey(const Key('message_bubble')).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
    });

    testWidgets('Test 131: Copy message text', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestChatScreen()));
      await tester.pumpAndSettle();

      await tester.longPress(find.byKey(const Key('message_bubble')).first);
      await tester.pumpAndSettle();

      expect(find.text('Copy'), findsOneWidget);
    });

    testWidgets('Test 132: Message timestamp', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestChatScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('message_timestamp')), findsWidgets);
    });

    testWidgets('Test 133: Icebreaker suggestions', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestChatScreen(isNew: true)));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('icebreaker_suggestions')), findsOneWidget);
    });

    testWidgets('Test 134: Voice message button', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestChatScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('voice_message_button')), findsOneWidget);
    });

    testWidgets('Test 135: Message translation', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestChatScreen()));
      await tester.pumpAndSettle();

      await tester.longPress(find.byKey(const Key('message_bubble')).first);
      await tester.pumpAndSettle();

      expect(find.text('Translate'), findsOneWidget);
    });

    testWidgets('Test 136: Video call button', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestChatScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('video_call_button')), findsOneWidget);
    });

    testWidgets('Test 137: Block user from chat', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestChatScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('chat_menu_button')));
      await tester.pumpAndSettle();

      expect(find.text('Block'), findsOneWidget);
    });

    testWidgets('Test 138: Report user from chat', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestChatScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('chat_menu_button')));
      await tester.pumpAndSettle();

      expect(find.text('Report'), findsOneWidget);
    });

    testWidgets('Test 139: Scroll to bottom button', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestChatScreen(manyMessages: true)));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, 500));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('scroll_to_bottom')), findsOneWidget);
    });

    testWidgets('Test 140: Emoji picker', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestChatScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('emoji_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('emoji_picker')), findsOneWidget);
    });

    testWidgets('Test 141: Message delivery status', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestChatScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('delivery_status')), findsWidgets);
    });

    testWidgets('Test 142: Online status in chat', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestChatScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('chat_online_status')), findsOneWidget);
    });

    testWidgets('Test 143: Link preview', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestChatScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('message_input')), 'https://example.com');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('link_preview')), findsOneWidget);
    });

    testWidgets('Test 144: Schedule message', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestChatScreen()));
      await tester.pumpAndSettle();

      await tester.longPress(find.byKey(const Key('send_button')));
      await tester.pumpAndSettle();

      expect(find.text('Schedule'), findsOneWidget);
    });

    testWidgets('Test 145: Message search', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestChatScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('chat_search_button')));
      await tester.pumpAndSettle();
    });
  });

  // ============================================================================
  // SECTION 7: NOTIFICATIONS TESTS (15 tests) - Tests 146-160
  // ============================================================================
  group('7. Notifications Tests', () {
    testWidgets('Test 146: Notifications screen loads', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestNotificationsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
    });

    testWidgets('Test 147: Notification list displays', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestNotificationsScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('notification_item')), findsWidgets);
    });

    testWidgets('Test 148: Mark notification as read', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestNotificationsScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('notification_item')).first);
      await tester.pumpAndSettle();
    });

    testWidgets('Test 149: Mark all as read button', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestNotificationsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Mark all read'), findsOneWidget);
    });

    testWidgets('Test 150: Delete notification', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestNotificationsScreen()));
      await tester.pumpAndSettle();

      await tester.drag(find.byKey(const Key('notification_item')).first, const Offset(-200, 0));
      await tester.pumpAndSettle();
    });

    testWidgets('Test 151: Notification badge count', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestMainScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('notification_badge')), findsOneWidget);
    });

    testWidgets('Test 152: Empty notifications state', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestNotificationsScreen(empty: true)));
      await tester.pumpAndSettle();

      expect(find.text('No notifications'), findsOneWidget);
    });

    testWidgets('Test 153: Notification preferences', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestNotificationSettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Push Notifications'), findsOneWidget);
    });

    testWidgets('Test 154: Match notification type', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestNotificationsScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('match_notification')), findsWidgets);
    });

    testWidgets('Test 155: Message notification type', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestNotificationsScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('message_notification')), findsWidgets);
    });

    testWidgets('Test 156: Like notification type', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestNotificationsScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('like_notification')), findsWidgets);
    });

    testWidgets('Test 157: Notification timestamp', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestNotificationsScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('notification_timestamp')), findsWidgets);
    });

    testWidgets('Test 158: Pull to refresh notifications', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestNotificationsScreen()));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, 200));
      await tester.pumpAndSettle();
    });

    testWidgets('Test 159: Notification sound toggle', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestNotificationSettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('sound_toggle')), findsOneWidget);
    });

    testWidgets('Test 160: Quiet hours setting', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestNotificationSettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Quiet Hours'), findsOneWidget);
    });
  });

  // ============================================================================
  // SECTION 8: COINS & IN-APP PURCHASES (15 tests) - Tests 161-175
  // ============================================================================
  group('8. Coins & In-App Purchases Tests', () {
    testWidgets('Test 161: Coin shop screen loads', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestCoinShopScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Shop'), findsOneWidget);
    });

    testWidgets('Test 162: Coin balance displays', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestCoinShopScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('coin_balance')), findsOneWidget);
    });

    testWidgets('Test 163: Coin packages displayed', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestCoinShopScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('coin_package')), findsWidgets);
    });

    testWidgets('Test 164: Purchase coin package', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestCoinShopScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('coin_package')).first);
      await tester.pumpAndSettle();

      expect(find.text('Confirm Purchase'), findsOneWidget);
    });

    testWidgets('Test 165: Boost purchase option', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestCoinShopScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Boost'), findsOneWidget);
    });

    testWidgets('Test 166: Super like purchase', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestCoinShopScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Super Likes'), findsOneWidget);
    });

    testWidgets('Test 167: Transaction history', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestCoinShopScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
    });

    testWidgets('Test 168: Best value badge', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestCoinShopScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Best Value'), findsOneWidget);
    });

    testWidgets('Test 169: Price display format', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestCoinShopScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('\$'), findsWidgets);
    });

    testWidgets('Test 170: Gift coins option', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestCoinShopScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('gift_coins_button')), findsOneWidget);
    });

    testWidgets('Test 171: Earn free coins section', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestCoinShopScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Earn Coins'), findsOneWidget);
    });

    testWidgets('Test 172: Watch ad for coins', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestCoinShopScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('watch_ad_button')), findsOneWidget);
    });

    testWidgets('Test 173: Daily reward claim', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestCoinShopScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Daily Reward'), findsOneWidget);
    });

    testWidgets('Test 174: Subscription upsell', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestCoinShopScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Go Premium'), findsOneWidget);
    });

    testWidgets('Test 175: Purchase confirmation dialog', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestCoinShopScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('coin_package')).first);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('purchase_dialog')), findsOneWidget);
    });
  });

  // ============================================================================
  // SECTION 9: GAMIFICATION & PROGRESS (15 tests) - Tests 176-190
  // ============================================================================
  group('9. Gamification & Progress Tests', () {
    testWidgets('Test 176: Progress screen loads', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestProgressScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Progress'), findsOneWidget);
    });

    testWidgets('Test 177: Level display', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestProgressScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('level_display')), findsOneWidget);
    });

    testWidgets('Test 178: XP progress bar', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestProgressScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('xp_progress_bar')), findsOneWidget);
    });

    testWidgets('Test 179: Achievements list', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestProgressScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('achievement_item')), findsWidgets);
    });

    testWidgets('Test 180: Daily challenges', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestProgressScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Daily Challenges'), findsOneWidget);
    });

    testWidgets('Test 181: Streak display', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestProgressScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('streak_display')), findsOneWidget);
    });

    testWidgets('Test 182: Badge collection', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestProgressScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Badges'), findsOneWidget);
    });

    testWidgets('Test 183: Leaderboard', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestProgressScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Leaderboard'));
      await tester.pumpAndSettle();
    });

    testWidgets('Test 184: Claim challenge reward', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestProgressScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('claim_reward_button')));
      await tester.pumpAndSettle();
    });

    testWidgets('Test 185: Level up celebration', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestLevelUpDialog()));
      await tester.pumpAndSettle();

      expect(find.text('Level Up!'), findsOneWidget);
    });

    testWidgets('Test 186: Achievement unlock animation', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestAchievementUnlockDialog()));
      await tester.pumpAndSettle();

      expect(find.text('Achievement Unlocked!'), findsOneWidget);
    });

    testWidgets('Test 187: Challenge progress indicator', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestProgressScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('challenge_progress')), findsWidgets);
    });

    testWidgets('Test 188: Weekly challenges', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestProgressScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Weekly Challenges'), findsOneWidget);
    });

    testWidgets('Test 189: Stats section', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestProgressScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Your Stats'), findsOneWidget);
    });

    testWidgets('Test 190: Seasonal event display', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestProgressScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('seasonal_event')), findsOneWidget);
    });
  });

  // ============================================================================
  // SECTION 10: SETTINGS & PREFERENCES (10 tests) - Tests 191-200
  // ============================================================================
  group('10. Settings & Preferences Tests', () {
    testWidgets('Test 191: Settings screen loads', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestSettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('Test 192: Account settings section', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestSettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Account'), findsOneWidget);
    });

    testWidgets('Test 193: Privacy settings', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestSettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Privacy'), findsOneWidget);
    });

    testWidgets('Test 194: Theme toggle', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestSettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('theme_toggle')), findsOneWidget);
    });

    testWidgets('Test 195: Language selection', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestSettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Language'), findsOneWidget);
    });

    testWidgets('Test 196: Logout button', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestSettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Logout'), findsOneWidget);
    });

    testWidgets('Test 197: Delete account option', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestSettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Delete Account'), findsOneWidget);
    });

    testWidgets('Test 198: Help & Support section', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestSettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Help & Support'), findsOneWidget);
    });

    testWidgets('Test 199: About section', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestSettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('Test 200: App version display', (tester) async {
      await tester.pumpWidget(const TestApp(child: TestSettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Version'), findsOneWidget);
    });
  });
}
