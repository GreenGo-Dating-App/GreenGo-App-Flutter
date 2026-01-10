import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_helpers.dart';
import 'test_app.dart';

/// New Features User Tests (20 tests)
/// Tests cover: Consent Checkboxes, Chat Translation, Message Actions
void main() {
  TestHelpers.initializeTests();

  group('Consent Checkboxes Tests', () {
    // Test 101: User sees consent checkboxes on registration
    testWidgets('Test 101: User sees consent checkboxes on registration', (tester) async {
      await pumpTestApp(tester, child: const TestRegisterWithConsentScreen());

      // Verify consent checkboxes are displayed
      expect(find.byKey(const Key('privacy_policy_checkbox')), findsOneWidget);
      expect(find.byKey(const Key('terms_checkbox')), findsOneWidget);
      expect(find.byKey(const Key('profiling_checkbox')), findsOneWidget);
      expect(find.byKey(const Key('third_party_checkbox')), findsOneWidget);
    });

    // Test 102: User must accept required consents to register
    testWidgets('Test 102: User must accept required consents to register', (tester) async {
      await pumpTestApp(tester, child: const TestRegisterWithConsentScreen());

      // Verify register button is disabled initially
      final registerButton = tester.widget<ElevatedButton>(find.byKey(const Key('register_button')));
      expect(registerButton.onPressed, isNull);

      // Verify warning message is shown
      expect(find.text('Please accept Privacy Policy and Terms to continue'), findsOneWidget);
    });

    // Test 103: User can accept privacy policy checkbox
    testWidgets('Test 103: User can accept privacy policy checkbox', (tester) async {
      await pumpTestApp(tester, child: const TestRegisterWithConsentScreen());

      // Tap privacy policy checkbox
      await tester.tap(find.byKey(const Key('privacy_policy_checkbox')));
      await tester.pumpAndSettle();

      // Verify checkbox is checked
      final checkbox = tester.widget<CheckboxListTile>(find.byKey(const Key('privacy_policy_checkbox')));
      expect(checkbox.value, isTrue);
    });

    // Test 104: User can accept terms checkbox
    testWidgets('Test 104: User can accept terms checkbox', (tester) async {
      await pumpTestApp(tester, child: const TestRegisterWithConsentScreen());

      // Tap terms checkbox
      await tester.tap(find.byKey(const Key('terms_checkbox')));
      await tester.pumpAndSettle();

      // Verify checkbox is checked
      final checkbox = tester.widget<CheckboxListTile>(find.byKey(const Key('terms_checkbox')));
      expect(checkbox.value, isTrue);
    });

    // Test 105: Register button enables when required consents are accepted
    testWidgets('Test 105: Register button enables when required consents are accepted', (tester) async {
      await pumpTestApp(tester, child: const TestRegisterWithConsentScreen());

      // Accept both required checkboxes
      await tester.tap(find.byKey(const Key('privacy_policy_checkbox')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('terms_checkbox')));
      await tester.pumpAndSettle();

      // Verify register button is now enabled
      final registerButton = tester.widget<ElevatedButton>(find.byKey(const Key('register_button')));
      expect(registerButton.onPressed, isNotNull);

      // Verify warning message is gone
      expect(find.text('Please accept Privacy Policy and Terms to continue'), findsNothing);
    });

    // Test 106: User can accept optional profiling checkbox
    testWidgets('Test 106: User can accept optional profiling checkbox', (tester) async {
      await pumpTestApp(tester, child: const TestRegisterWithConsentScreen());

      // Tap profiling checkbox
      await tester.tap(find.byKey(const Key('profiling_checkbox')));
      await tester.pumpAndSettle();

      // Verify checkbox is checked
      final checkbox = tester.widget<CheckboxListTile>(find.byKey(const Key('profiling_checkbox')));
      expect(checkbox.value, isTrue);
    });

    // Test 107: User can accept optional third-party data checkbox
    testWidgets('Test 107: User can accept optional third-party data checkbox', (tester) async {
      await pumpTestApp(tester, child: const TestRegisterWithConsentScreen());

      // Scroll to make checkbox visible
      await tester.ensureVisible(find.byKey(const Key('third_party_checkbox')));
      await tester.pumpAndSettle();

      // Tap third-party checkbox
      await tester.tap(find.byKey(const Key('third_party_checkbox')));
      await tester.pumpAndSettle();

      // Verify checkbox is checked
      final checkbox = tester.widget<CheckboxListTile>(find.byKey(const Key('third_party_checkbox')));
      expect(checkbox.value, isTrue);
    });

    // Test 108: User can tap privacy policy link
    testWidgets('Test 108: User can tap privacy policy link', (tester) async {
      await pumpTestApp(tester, child: const TestRegisterWithConsentScreen());

      // Scroll to make link visible if needed
      await tester.ensureVisible(find.byKey(const Key('privacy_policy_link')));

      // Tap privacy policy link
      await tester.tap(find.byKey(const Key('privacy_policy_link')));
      await tester.pumpAndSettle();

      // Verify action (snackbar shown)
      expect(find.text('Opening Privacy Policy'), findsOneWidget);
    });

    // Test 109: User can tap terms link
    testWidgets('Test 109: User can tap terms link', (tester) async {
      await pumpTestApp(tester, child: const TestRegisterWithConsentScreen());

      // Scroll to make link visible if needed
      await tester.ensureVisible(find.byKey(const Key('terms_link')));

      // Tap terms link
      await tester.tap(find.byKey(const Key('terms_link')));
      await tester.pumpAndSettle();

      // Verify action (snackbar shown)
      expect(find.text('Opening Terms and Conditions'), findsOneWidget);
    });

    // Test 110: User can register with all consents accepted
    testWidgets('Test 110: User can register with all consents accepted', (tester) async {
      await pumpTestApp(tester, child: const TestRegisterWithConsentScreen());

      // Fill in registration form
      await tester.enterText(find.byKey(const Key('register_email_field')), 'test@example.com');
      await tester.enterText(find.byKey(const Key('register_password_field')), 'Password123!');
      await tester.enterText(find.byKey(const Key('confirm_password_field')), 'Password123!');

      // Accept required consents
      await tester.tap(find.byKey(const Key('privacy_policy_checkbox')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('terms_checkbox')));
      await tester.pumpAndSettle();

      // Scroll to register button
      await tester.ensureVisible(find.byKey(const Key('register_button')));
      await tester.pumpAndSettle();

      // Tap register
      await tester.tap(find.byKey(const Key('register_button')));
      await tester.pumpAndSettle();

      // Verify success
      expect(find.text('Registration Successful'), findsOneWidget);
    });
  });

  group('Chat Translation Tests', () {
    // Test 111: User can view chat screen with messages
    testWidgets('Test 111: User can view chat screen with messages', (tester) async {
      await pumpTestApp(tester, child: const TestChatScreenWithTranslation());

      // Verify chat screen elements
      expect(find.byKey(const Key('message_list')), findsOneWidget);
      expect(find.byKey(const Key('message_input')), findsOneWidget);
      expect(find.byKey(const Key('send_button')), findsOneWidget);
      expect(find.text('Marco'), findsOneWidget);
    });

    // Test 112: User can see existing messages
    testWidgets('Test 112: User can see existing messages', (tester) async {
      await pumpTestApp(tester, child: const TestChatScreenWithTranslation());

      // Verify messages are displayed
      expect(find.text('Ciao! Come stai?'), findsOneWidget);
      expect(find.text('Hello! I am fine, thanks!'), findsOneWidget);
      expect(find.text('Che bel tempo oggi!'), findsOneWidget);
    });

    // Test 113: User can send a new message
    testWidgets('Test 113: User can send a new message', (tester) async {
      await pumpTestApp(tester, child: const TestChatScreenWithTranslation());

      // Enter message
      await tester.enterText(find.byKey(const Key('message_input')), 'Test message');
      await tester.pumpAndSettle();

      // Send message
      await tester.tap(find.byKey(const Key('send_button')));
      await tester.pumpAndSettle();

      // Verify message appears
      expect(find.text('Test message'), findsOneWidget);
    });

    // Test 114: User can open message context menu
    testWidgets('Test 114: User can open message context menu', (tester) async {
      await pumpTestApp(tester, child: const TestChatScreenWithTranslation());

      // Find the message content text and long press on it
      await tester.longPress(find.text('Ciao! Come stai?'));
      await tester.pumpAndSettle();

      // Verify context menu options
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Translate'), findsOneWidget);
      expect(find.text('Forward'), findsOneWidget);
    });

    // Test 115: User can translate a message
    testWidgets('Test 115: User can translate a message', (tester) async {
      await pumpTestApp(tester, child: const TestChatScreenWithTranslation());

      // Long press on first message (Italian)
      await tester.longPress(find.text('Ciao! Come stai?'));
      await tester.pumpAndSettle();

      // Tap translate
      await tester.tap(find.text('Translate'));
      await tester.pumpAndSettle();

      // Verify translation appears
      expect(find.text('Translated'), findsOneWidget);
      expect(find.text('Hello! How are you?'), findsOneWidget);
    });

    // Test 116: User can see translated content in message bubble
    testWidgets('Test 116: User can see translated content in message bubble', (tester) async {
      await pumpTestApp(tester, child: const TestChatScreenWithTranslation());

      // Translate first message
      await tester.longPress(find.text('Ciao! Come stai?'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Translate'));
      await tester.pumpAndSettle();

      // Verify translated indicator and content
      expect(find.byIcon(Icons.translate), findsAtLeast(1));
      expect(find.text('Hello! How are you?'), findsOneWidget);
    });

    // Test 117: User can open translation settings
    testWidgets('Test 117: User can open translation settings', (tester) async {
      await pumpTestApp(tester, child: const TestChatScreenWithTranslation());

      // Tap translation settings button
      await tester.tap(find.byKey(const Key('translation_settings_button')));
      await tester.pumpAndSettle();

      // Verify settings dialog
      expect(find.text('Translation Settings'), findsOneWidget);
      expect(find.text('Auto-translate messages'), findsOneWidget);
    });

    // Test 118: User can download language pack
    testWidgets('Test 118: User can download language pack', (tester) async {
      await pumpTestApp(tester, child: const TestChatScreenWithTranslation());

      // Open translation settings
      await tester.tap(find.byKey(const Key('translation_settings_button')));
      await tester.pumpAndSettle();

      // Tap download language
      await tester.tap(find.byKey(const Key('download_language_button')));
      await tester.pumpAndSettle();

      // Verify download started
      expect(find.text('Downloading Italian language pack...'), findsOneWidget);
    });

    // Test 119: User can copy a message
    testWidgets('Test 119: User can copy a message', (tester) async {
      await pumpTestApp(tester, child: const TestChatScreenWithTranslation());

      // Long press on a message
      await tester.longPress(find.text('Hello! I am fine, thanks!'));
      await tester.pumpAndSettle();

      // Tap copy
      await tester.tap(find.text('Copy'));
      await tester.pumpAndSettle();

      // Verify copy action
      expect(find.text('Message copied'), findsOneWidget);
    });

    // Test 120: Translate option hidden for already translated messages
    testWidgets('Test 120: Translate option hidden for already translated messages', (tester) async {
      await pumpTestApp(tester, child: const TestChatScreenWithTranslation());

      // First translate the message
      await tester.longPress(find.text('Ciao! Come stai?'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Translate'));
      await tester.pumpAndSettle();

      // Open context menu again - long press on the original message text
      await tester.longPress(find.text('Ciao! Come stai?'));
      await tester.pumpAndSettle();

      // Verify translate option is not shown (only Copy and Forward should appear)
      expect(find.text('Translate'), findsNothing);
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Forward'), findsOneWidget);
    });
  });
}
