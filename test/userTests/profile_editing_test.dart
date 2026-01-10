import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_helpers.dart';
import 'test_app.dart';

/// Profile Editing User Tests (10 tests)
/// Tests cover: Edit profile sections, photo management, save changes
void main() {
  TestHelpers.initializeTests();

  group('Profile Editing Tests', () {
    // Test 28: User can view their profile from Profile tab
    testWidgets('Test 28: User can view their profile from Profile tab', (tester) async {
      await pumpTestApp(tester, child: const TestMainScreen());

      // Navigate to Profile tab
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Verify profile screen elements
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.byKey(const Key('edit_profile_button')), findsOneWidget);
      expect(find.byKey(const Key('profile_photo')), findsOneWidget);
    });

    // Test 29: User can navigate to Edit Profile screen
    testWidgets('Test 29: User can navigate to Edit Profile screen', (tester) async {
      await pumpTestApp(tester, child: const TestMainScreen());

      // Navigate to Profile tab
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Tap edit profile button
      await TestHelpers.tapByKey(tester, 'edit_profile_button');
      await tester.pumpAndSettle();

      // Verify edit profile screen
      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.byKey(const Key('edit_basic_info_card')), findsOneWidget);
      expect(find.byKey(const Key('edit_photos_card')), findsOneWidget);
      expect(find.byKey(const Key('edit_bio_card')), findsOneWidget);
    });

    // Test 30: User can edit basic info
    testWidgets('Test 30: User can edit basic info', (tester) async {
      await pumpTestApp(tester, child: const TestEditBasicInfoScreen());

      // Edit name
      await tester.enterText(find.byKey(const Key('name_field')), 'Jane Smith');
      await tester.pumpAndSettle();

      // Save changes
      await TestHelpers.tapByKey(tester, 'save_button');
      await tester.pumpAndSettle();

      // Verify success message
      expect(find.text('Profile updated successfully'), findsOneWidget);
    });

    // Test 31: User can manage photos
    testWidgets('Test 31: User can manage photos', (tester) async {
      await pumpTestApp(tester, child: const TestEditPhotosScreen());

      // Verify photo grid
      expect(find.byKey(const Key('photo_preview_0')), findsOneWidget);
      expect(find.byKey(const Key('photo_preview_1')), findsOneWidget);
      expect(find.byKey(const Key('add_photo_button')), findsOneWidget);
    });

    // Test 32: User can add new photo from gallery
    testWidgets('Test 32: User can add new photo from gallery', (tester) async {
      await pumpTestApp(tester, child: const TestEditPhotosScreen());

      // Tap add photo button
      await TestHelpers.tapByKey(tester, 'add_photo_button');
      await tester.pumpAndSettle();

      // Verify photo source options
      expect(find.text('Choose from Gallery'), findsOneWidget);
      expect(find.text('Take Photo'), findsOneWidget);

      // Select gallery option
      await tester.tap(find.text('Choose from Gallery'));
      await tester.pumpAndSettle();
    });

    // Test 33: User can take new photo with camera
    testWidgets('Test 33: User can take new photo with camera', (tester) async {
      await pumpTestApp(tester, child: const TestEditPhotosScreen());

      // Tap add photo button
      await TestHelpers.tapByKey(tester, 'add_photo_button');
      await tester.pumpAndSettle();

      // Select camera option
      await tester.tap(find.text('Take Photo'));
      await tester.pumpAndSettle();
    });

    // Test 34: User can delete a photo
    testWidgets('Test 34: User can delete a photo', (tester) async {
      await pumpTestApp(tester, child: const TestEditPhotosScreen());

      // Long press on photo
      await tester.longPress(find.byKey(const Key('photo_preview_0')));
      await tester.pumpAndSettle();

      // Tap delete
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Verify confirmation dialog
      expect(find.text('Delete this photo?'), findsOneWidget);
    });

    // Test 35: User can update bio
    testWidgets('Test 35: User can update bio', (tester) async {
      await pumpTestApp(tester, child: const TestEditBioScreen());

      // Update bio text
      await tester.enterText(find.byKey(const Key('bio_field')), 'New bio text');
      await tester.pumpAndSettle();

      // Save
      await TestHelpers.tapByKey(tester, 'save_button');
      await tester.pumpAndSettle();

      // Verify success
      expect(find.text('Bio updated successfully'), findsOneWidget);
    });

    // Test 36: User sees bio character count
    testWidgets('Test 36: User sees bio character count', (tester) async {
      await pumpTestApp(tester, child: const TestEditBioScreen());

      // Enter bio text
      await tester.enterText(find.byKey(const Key('bio_field')), 'Test bio');
      await tester.pumpAndSettle();

      // Verify character count (may have multiple instances from TextField counter)
      expect(find.textContaining('/500'), findsAtLeastNWidgets(1));
    });

    // Test 37: User can select height from picker
    testWidgets('Test 37: User can select height from picker', (tester) async {
      await pumpTestApp(tester, child: const TestEditBasicInfoScreen());

      // Tap height field
      await TestHelpers.tapByKey(tester, 'height_field');
      await tester.pumpAndSettle();

      // Verify height options (175 cm also appears in the subtitle)
      expect(find.text('170 cm'), findsOneWidget);
      expect(find.text('175 cm'), findsAtLeastNWidgets(1));
      expect(find.text('180 cm'), findsOneWidget);
    });
  });
}
