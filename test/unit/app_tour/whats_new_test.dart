import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/app_tour/presentation/tour_environment.dart';
import 'package:greengo_chat/features/app_tour/presentation/whats_new.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const editions = ['5.0.43', '5.1.0'];

  test('compareVersions is numeric and ignores the build number', () {
    expect(WhatsNew.compareVersions('5.0.43', '5.0.42+276'), 1);
    expect(WhatsNew.compareVersions('5.0.9', '5.0.10'), -1);
    expect(WhatsNew.compareVersions('5.0.43+1', '5.0.43+9'), 0);
    expect(WhatsNew.compareVersions('5.1', '5.1.0'), 0);
  });

  test('fresh install: nothing, whatever the version', () {
    expect(
        WhatsNew.editionToShow(
            currentVersion: '5.0.43',
            lastSeen: null,
            isExistingUser: false,
            editions: editions),
        isNull);
  });

  test('existing user updating to an edition version sees it once', () {
    expect(
        WhatsNew.editionToShow(
            currentVersion: '5.0.43',
            lastSeen: null,
            isExistingUser: true,
            editions: editions),
        '5.0.43');
    expect(
        WhatsNew.editionToShow(
            currentVersion: '5.0.43',
            lastSeen: '5.0.42',
            isExistingUser: true,
            editions: editions),
        '5.0.43');
    // Already seen on this version.
    expect(
        WhatsNew.editionToShow(
            currentVersion: '5.0.43',
            lastSeen: '5.0.43',
            isExistingUser: true,
            editions: editions),
        isNull);
  });

  test('no edition newer than the running version; newest due one wins', () {
    expect(
        WhatsNew.editionToShow(
            currentVersion: '5.0.42',
            lastSeen: '5.0.41',
            isExistingUser: true,
            editions: editions),
        isNull);
    expect(
        WhatsNew.editionToShow(
            currentVersion: '5.2.0',
            lastSeen: '5.0.40',
            isExistingUser: true,
            editions: editions),
        '5.1.0');
    expect(
        WhatsNew.editionToShow(
            currentVersion: '5.0.50',
            lastSeen: '5.0.43',
            isExistingUser: true,
            editions: editions),
        isNull);
  });

  test('the 5.0.43 edition has 2-3 bullets', () {
    expect(whatsNewEditions['5.0.43']!.length, inInclusiveRange(2, 3));
  });

  group('maybeShow', () {
    setUp(() => TourEnvironment.debugOverride = true);
    tearDown(() => TourEnvironment.debugOverride = null);

    Future<BuildContext> pumpHost(WidgetTester t) async {
      late BuildContext ctx;
      await t.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (c) {
          ctx = c;
          return const Scaffold();
        }),
      ));
      return ctx;
    }

    testWidgets('shows the card once per version and records it', (t) async {
      SharedPreferences.setMockInitialValues({WhatsNew.prefKey: '5.0.42'});
      final ctx = await pumpHost(t);
      final shown = WhatsNew.maybeShow(ctx,
          isExistingUser: true, currentVersion: '5.0.43+277');
      await t.pumpAndSettle();
      expect(find.byType(WhatsNewSheet), findsOneWidget);
      final l = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l.whatsNewTitle), findsOneWidget);
      expect(find.text(l.whatsNew5043WorldMap), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('whats-new-got-it')));
      await t.pumpAndSettle();
      expect(await shown, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(WhatsNew.prefKey), '5.0.43');

      final again = WhatsNew.maybeShow(ctx,
          isExistingUser: true, currentVersion: '5.0.43+277');
      await t.pumpAndSettle();
      expect(await again, isFalse);
      expect(find.byType(WhatsNewSheet), findsNothing);
    });

    testWidgets('fresh install only records the version', (t) async {
      SharedPreferences.setMockInitialValues({});
      final ctx = await pumpHost(t);
      final shown = WhatsNew.maybeShow(ctx,
          isExistingUser: false, currentVersion: '5.0.43');
      await t.pumpAndSettle();
      expect(await shown, isFalse);
      expect(find.byType(WhatsNewSheet), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(WhatsNew.prefKey), '5.0.43');
    });
  });
}
