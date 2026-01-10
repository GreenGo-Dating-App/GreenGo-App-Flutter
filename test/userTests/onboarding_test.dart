import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_helpers.dart';
import 'test_app.dart';

/// Onboarding User Tests (12 tests)
/// Tests cover: Welcome screen, profile setup, photo upload
void main() {
  TestHelpers.initializeTests();

  group('Onboarding Tests', () {
    // Test 16: New user sees main screen after login
    testWidgets('Test 16: New user sees main screen after login', (tester) async {
      await pumpTestApp(tester);

      // Login with valid credentials
      await TestHelpers.enterTextByKey(tester, 'email_field', TestUserData.validEmail);
      await TestHelpers.enterTextByKey(tester, 'password_field', TestUserData.validPassword);
      await TestHelpers.tapByKey(tester, 'login_button');
      await tester.pumpAndSettle();

      // Verify main screen with bottom navigation
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('Discover'), findsAtLeast(1));
    });

    // Test 17: User can access edit profile from profile tab
    testWidgets('Test 17: User can access edit profile from profile tab', (tester) async {
      await pumpTestApp(tester, child: const TestMainScreen());

      // Navigate to Profile tab
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Tap edit profile
      await TestHelpers.tapByKey(tester, 'edit_profile_button');
      await tester.pumpAndSettle();

      // Verify edit profile screen
      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Basic Info'), findsOneWidget);
    });

    // Test 18: User can edit basic info
    testWidgets('Test 18: User can edit basic info', (tester) async {
      await pumpTestApp(tester, child: const TestEditBasicInfoScreen());

      // Verify basic info fields
      expect(find.byKey(const Key('name_field')), findsOneWidget);
      expect(find.byKey(const Key('height_field')), findsOneWidget);

      // Edit name
      await tester.enterText(find.byKey(const Key('name_field')), 'New Name');
      await tester.pumpAndSettle();

      // Save changes
      await TestHelpers.tapByKey(tester, 'save_button');
      await tester.pump();

      // Verify success message
      expect(find.text('Profile updated successfully'), findsOneWidget);
    });

    // Test 19: User can access photos section
    testWidgets('Test 19: User can access photos section', (tester) async {
      await pumpTestApp(tester, child: const TestEditPhotosScreen());

      // Verify photos screen
      expect(find.text('Photos'), findsOneWidget);
      expect(find.byKey(const Key('add_photo_button')), findsOneWidget);

      // Verify existing photo previews
      expect(find.byKey(const Key('photo_preview_0')), findsOneWidget);
    });

    // Test 20: User can add a new photo
    testWidgets('Test 20: User can add a new photo', (tester) async {
      await pumpTestApp(tester, child: const TestEditPhotosScreen());

      // Tap add photo button
      await TestHelpers.tapByKey(tester, 'add_photo_button');
      await tester.pumpAndSettle();

      // Verify photo options appear
      expect(find.text('Choose from Gallery'), findsOneWidget);
      expect(find.text('Take Photo'), findsOneWidget);
    });

    // Test 21: User can edit bio
    testWidgets('Test 21: User can edit bio', (tester) async {
      await pumpTestApp(tester, child: const TestEditBioScreen());

      // Verify bio screen (may have multiple "Bio" texts - AppBar and labels)
      expect(find.text('Bio'), findsAtLeastNWidgets(1));
      expect(find.byKey(const Key('bio_field')), findsOneWidget);

      // Edit bio
      await tester.enterText(find.byKey(const Key('bio_field')), 'New bio text for testing');
      await tester.pumpAndSettle();

      // Verify character count (may have multiple instances from TextField counter)
      expect(find.textContaining('/500'), findsAtLeastNWidgets(1));
    });

    // Test 22: User can save bio changes
    testWidgets('Test 22: User can save bio changes', (tester) async {
      await pumpTestApp(tester, child: const TestEditBioScreen());

      // Edit bio
      await tester.enterText(find.byKey(const Key('bio_field')), 'Updated bio');
      await tester.pumpAndSettle();

      // Save
      await TestHelpers.tapByKey(tester, 'save_button');
      await tester.pumpAndSettle();

      // Verify success
      expect(find.text('Bio updated successfully'), findsOneWidget);
    });

    // Test 23: User sees discard dialog when leaving with unsaved changes
    testWidgets('Test 23: User sees discard dialog when leaving with unsaved changes', (tester) async {
      await pumpTestApp(tester, child: const TestEditBioScreen());

      // Make changes
      await tester.enterText(find.byKey(const Key('bio_field')), 'Changed bio');
      await tester.pumpAndSettle();

      // Try to go back
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Verify discard dialog
      expect(find.text('Discard changes?'), findsOneWidget);
    });

    // Test 24: User can view profile sections
    testWidgets('Test 24: User can view profile sections', (tester) async {
      await pumpTestApp(tester, child: const TestEditProfileScreen());

      // Verify all profile sections
      expect(find.text('Basic Info'), findsOneWidget);
      expect(find.text('Photos'), findsOneWidget);
      expect(find.text('Bio'), findsOneWidget);
      expect(find.text('Interests'), findsOneWidget);
      expect(find.text('Location'), findsOneWidget);
    });

    // Test 25: User can select height from picker
    testWidgets('Test 25: User can select height from picker', (tester) async {
      await pumpTestApp(tester, child: const TestEditBasicInfoScreen());

      // Tap height field
      await TestHelpers.tapByKey(tester, 'height_field');
      await tester.pumpAndSettle();

      // Verify height options (175 cm also appears in the subtitle)
      expect(find.text('170 cm'), findsOneWidget);
      expect(find.text('175 cm'), findsAtLeastNWidgets(1));
      expect(find.text('180 cm'), findsOneWidget);
    });

    // Test 26: User sees validation for empty name
    testWidgets('Test 26: User sees validation for empty name', (tester) async {
      await pumpTestApp(tester, child: const TestEditBasicInfoScreen());

      // Clear name field
      await tester.enterText(find.byKey(const Key('name_field')), '');
      await tester.pumpAndSettle();

      // Try to save
      await TestHelpers.tapByKey(tester, 'save_button');
      await tester.pumpAndSettle();

      // Verify error
      expect(find.text('Name cannot be empty'), findsOneWidget);
    });

    // Test 27: User can delete a photo
    testWidgets('Test 27: User can delete a photo', (tester) async {
      await pumpTestApp(tester, child: const TestEditPhotosScreen());

      // Long press on photo to show options
      await tester.longPress(find.byKey(const Key('photo_preview_0')));
      await tester.pumpAndSettle();

      // Tap delete
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Verify confirmation dialog
      expect(find.text('Delete this photo?'), findsOneWidget);
    });
  });
}
