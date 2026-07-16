import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/widgets/country_flag_badge.dart';
import 'package:greengo_chat/core/widgets/verified_badge.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

import '../support/profile_fixtures.dart';

/// These test the SMALL leaf widgets composed by the profile detail header
/// (name + age + flags + verified/business badges). Testing the full
/// ProfileDetailScreen is avoided because it touches FirebaseFirestore in
/// initState; the header's meaning lives in these composable pieces.
Future<void> pumpBadge(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  group('VerifiedBadge', () {
    testWidgets('renders a check icon', (tester) async {
      await pumpBadge(tester, const VerifiedBadge());
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('lays out at the requested size', (tester) async {
      await pumpBadge(tester, const VerifiedBadge(size: 40, isPremium: true));
      final size = tester.getSize(find.byType(VerifiedBadge));
      expect(size.width, 40);
      expect(size.height, 40);
    });
  });

  group('BusinessBadge', () {
    testWidgets('renders the localized label and a storefront icon',
        (tester) async {
      await pumpBadge(tester, const BusinessBadge(label: 'Business'));
      expect(find.text('Business'), findsOneWidget);
      expect(find.byIcon(Icons.storefront), findsOneWidget);
    });
  });

  group('LanguageFlagBadge', () {
    testWidgets('renders flag emoji for known languages', (tester) async {
      await pumpBadge(
        tester,
        const LanguageFlagBadge(languages: ['English', 'Italian']),
      );
      final text = tester.widget<Text>(find.byType(Text));
      expect(text.data, isNotEmpty);
    });

    testWidgets('renders nothing for an empty language list', (tester) async {
      await pumpBadge(tester, const LanguageFlagBadge(languages: []));
      expect(find.byType(Text), findsNothing);
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('caps the number of flags at maxFlags', (tester) async {
      await pumpBadge(
        tester,
        const LanguageFlagBadge(
          languages: ['English', 'Italian', 'French', 'German'],
          maxFlags: 2,
        ),
      );
      // Each flag emoji is 2 regional-indicator runes, so 2 flags = 4 runes.
      final text = tester.widget<Text>(find.byType(Text));
      expect(text.data!.runes.length, 4);
    });
  });

  group('Header composition (age + flags under the name)', () {
    testWidgets(
        'age text and language flags render together beneath the name',
        (tester) async {
      // Rebuild the essential header column the detail screen composes so we
      // can assert the age sits directly with the language flags.
      final profile = buildProfile(
        displayName: 'Ava Reyes',
        dateOfBirth: DateTime(DateTime.now().year - 28, 1, 1),
        languages: const ['English', 'Portuguese'],
      );

      await pumpBadge(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(profile.displayName),
            Wrap(
              children: [
                Text('${profile.age}'),
                LanguageFlagBadge(languages: profile.languages),
              ],
            ),
          ],
        ),
      );

      expect(find.text('Ava Reyes'), findsOneWidget);
      expect(find.text('28'), findsOneWidget);
      expect(find.byType(LanguageFlagBadge), findsOneWidget);
    });
  });
}
