# GreenGo Chat - User Tests

This folder contains 100 comprehensive user tests covering all features of the GreenGo Chat application from an end-user perspective.

## Test Structure

| Category | Tests | Test Numbers |
|----------|-------|--------------|
| Authentication | 15 | 1-15 |
| Onboarding | 12 | 16-27 |
| Profile Editing | 10 | 28-37 |
| Discovery & Swiping | 12 | 38-49 |
| Matching | 8 | 50-57 |
| Chat & Messaging | 12 | 58-69 |
| Notifications | 8 | 70-77 |
| Gamification | 10 | 78-87 |
| Coins & Shop | 6 | 88-93 |
| Subscription | 4 | 94-97 |
| Settings | 3 | 98-100 |
| **Total** | **100** | |

## Files Overview

- `test_helpers.dart` - Utility functions for tests
- `authentication_tests.dart` - Login, registration, password reset
- `onboarding_tests.dart` - 8-step profile creation flow
- `profile_editing_tests.dart` - Edit profile sections
- `discovery_tests.dart` - Swiping and matching discovery
- `matching_tests.dart` - Match management
- `chat_tests.dart` - Messaging functionality
- `notifications_tests.dart` - Notification management
- `gamification_tests.dart` - Achievements, challenges, leaderboard
- `coins_tests.dart` - Virtual currency and shop
- `subscription_tests.dart` - Premium plans
- `settings_tests.dart` - App settings
- `all_user_tests.dart` - Main entry point to run all tests
- `test_report_generator.dart` - Generate HTML test reports
- `run_tests_with_report.dart` - Run tests and generate report

## How to Run Tests

### Run All Tests
```bash
flutter test tests/userTests/
```

### Run Individual Test File
```bash
flutter test tests/userTests/authentication_tests.dart
```

### Run Tests with Report Generation
```bash
dart run tests/userTests/run_tests_with_report.dart
```

### Generate Report from Existing Output
```bash
# First, run tests with machine output
flutter test --machine tests/userTests/ > test_output.json

# Then generate report
dart run tests/userTests/test_report_generator.dart
```

## Test Report

After running tests with the report generator, you will get:

- `test_report.html` - Detailed HTML report with:
  - Overall pass/fail statistics
  - Pass rate percentage
  - Test duration
  - Results by category
  - Individual test results
  - Error messages for failed tests

Open `test_report.html` in any browser to view the report.

## Test Coverage

These tests cover the following user journeys:

### Authentication Flow
- Registration with email/password
- Login with valid/invalid credentials
- Password reset
- Session persistence
- Logout

### Profile Creation
- Complete 8-step onboarding
- Photo upload
- Bio writing
- Interest selection
- Location settings
- Voice recording
- Personality quiz

### Discovery & Matching
- Swipe right/left/up
- View full profiles
- Match notifications
- Discovery preferences
- Filter by age/distance/gender

### Messaging
- View conversations
- Send/receive messages
- Typing indicators
- Online status
- Delete conversations

### Gamification
- View achievements
- Complete daily challenges
- Participate in seasonal events
- Leaderboard rankings

### Premium Features
- View subscription plans
- Purchase coins
- Use premium features
- Transaction history

## Customization

To add new tests:

1. Create a new test file or add to existing ones
2. Follow the naming convention: `Test X: Description`
3. Import in `all_user_tests.dart`
4. Use helpers from `test_helpers.dart`

## Prerequisites

Make sure you have these dependencies in your `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  mockito: ^5.4.4
  bloc_test: ^9.1.5
```

## Notes

- Tests are designed as integration tests using Flutter's integration_test package
- Each test simulates real user behavior
- Tests use widget keys for reliable element finding
- Mock data is provided in `test_helpers.dart`
- Tests should be adapted to match actual widget keys in your app
