@Tags(['compliance'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/effective_tier.dart';
import 'package:greengo_chat/core/utils/eula_link.dart';
import 'package:greengo_chat/core/widgets/subscription_legal_footer.dart';
import 'package:greengo_chat/features/membership/domain/entities/membership.dart';
import 'package:greengo_chat/features/safety/data/services/age_assurance_service.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

/// App Review fixes of 17 Oct 2026 (owner-approved plan): one introductory
/// offer (no free trials anywhere), Apple-only wording on iOS, EULA links,
/// Base never sold on top of a paid tier, no Declared Age Range option yet.
void main() {
  late List<File> dartFiles;

  setUpAll(() {
    dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !f.path.contains('generated'))
        .toList();
    expect(dartFiles, isNotEmpty, reason: 'run this from the package root');
  });

  group('no free trial on any platform (3.1.2(c), owner 2026-10-17)', () {
    test('no UI uses the 7-day trial copy or the old trial notice switch', () {
      final offenders = <String>[];
      for (final f in dartFiles) {
        final src = f.readAsStringSync();
        for (final needle in [
          '.subscriptionFreeTrialInfo',
          'showFreeTrialNotice',
          'hasSevenDayFreeTrial',
          '.guideMembershipItem2',
          '.membershipTrialTitle',
          '.membershipTrialSubtitle',
          '.membershipTrialCta',
          '.membershipTrialFooter',
          '.membershipTrialBadge',
        ]) {
          if (src.contains(needle)) offenders.add('${f.path}: $needle');
        }
      }
      expect(offenders, isEmpty);
    });

    testWidgets('purchase footer: no trial text, Terms + Privacy + EULA',
        (t) async {
      await t.pumpWidget(_host(const SubscriptionLegalFooter()));
      expect(find.textContaining('7 days'), findsNothing);
      expect(find.textContaining('free'), findsNothing);
      expect(find.text('Terms and Conditions'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.byKey(const ValueKey('subscription-footer-eula')),
          findsOneWidget);
    });
  });

  group('EULA link (3.1.2)', () {
    test('website /eula in the app language (site ?lang= parameter)', () {
      expect(eulaUri(const Locale('en')).toString(),
          'https://greengochat.com/eula?lang=en');
      expect(eulaUri(const Locale('pt', 'BR')).toString(),
          'https://greengochat.com/eula?lang=pt');
      expect(eulaUri(const Locale('de')).toString(),
          'https://greengochat.com/eula?lang=de');
      expect(eulaUri(const Locale('ja')).toString(),
          'https://greengochat.com/eula?lang=en');
    });

    testWidgets('tapping EULA in the footer opens it', (t) async {
      final opened = <Uri>[];
      eulaLauncher = (u) async {
        opened.add(u);
        return true;
      };
      await t.pumpWidget(_host(const SubscriptionLegalFooter()));
      await t.tap(find.byKey(const ValueKey('subscription-footer-eula')));
      await t.pump();
      expect(opened.single.toString(), 'https://greengochat.com/eula?lang=en');
    });

    test('Help & Support lists Terms, Privacy and the EULA', () {
      final src = File(
              'lib/features/profile/presentation/screens/edit_profile_screen.dart')
          .readAsStringSync();
      expect(src, contains("ValueKey('help-terms')"));
      expect(src, contains("ValueKey('help-privacy')"));
      expect(src, contains("ValueKey('help-eula')"));
      expect(src, contains('openEula(context)'));
    });
  });

  group('Base on top of a paid tier (3.1.2(b))', () {
    test('included in Silver / Gold / Platinum only', () {
      expect(baseIncludedInPaidTier(MembershipTier.silver), isTrue);
      expect(baseIncludedInPaidTier(MembershipTier.gold), isTrue);
      expect(baseIncludedInPaidTier(MembershipTier.platinum), isTrue);
      expect(baseIncludedInPaidTier(MembershipTier.free), isFalse);
      expect(baseIncludedInPaidTier(MembershipTier.test), isFalse);
    });

    test('an expired paid tier no longer includes Base', () {
      final now = DateTime.utc(2026, 10, 17);
      expect(
          baseIncludedInPaidTier(effectiveTier(
              rawTier: 'GOLD',
              endDate: now.add(const Duration(days: 1)),
              now: now)),
          isTrue);
      expect(
          baseIncludedInPaidTier(effectiveTier(
              rawTier: 'GOLD',
              endDate: now.subtract(const Duration(days: 1)),
              now: now)),
          isFalse);
    });

    test('every screen that sells Base checks it', () {
      for (final path in [
        'lib/features/coins/presentation/screens/coin_shop_screen.dart',
        'lib/features/subscription/presentation/screens/membership_screen.dart',
        'lib/features/subscription/presentation/screens/subscription_selection_screen.dart',
      ]) {
        final src = File(path).readAsStringSync();
        expect(src, contains('baseIncludedInPaidTier('), reason: path);
        expect(src, contains('baseIncludedInPlan'), reason: path);
      }
    });
  });

  group('iOS age check', () {
    test('no "Confirm with the App Store" option until the entitlement ships',
        () {
      expect(kAppleDeclaredAgeRangeEnabled, isFalse);
      const s =
          AgeAssuranceStatus(enforced: true, required: true, satisfied: false);
      expect(s.optionsFor(AgeAssurancePlatform.ios),
          [AgeAssuranceMethod.idVerification]);
      // Android keeps the Play age signal.
      expect(s.optionsFor(AgeAssurancePlatform.android),
          contains(AgeAssuranceMethod.storeSignal));
    });
  });

  group('iOS copy names only Apple (2.3.10), in every language', () {
    for (final locale in AppLocalizations.supportedLocales) {
      test('$locale', () {
        final l = lookupAppLocalizations(locale);
        for (final text in [
          l.purchasesWithdrawalStoreHelpIos,
          l.manageSubscriptionStoreHelpIos,
          l.deleteAccountConfirmationIos,
          l.profileDeleteAccountWarningIos,
          l.promoRenewsAppStore,
          l.promoStoreFirstYear('50', 'a', 'b'),
          l.promoStoreFirst3Months('50', 'a', 'b'),
        ]) {
          expect(text, isNot(contains('Google')), reason: text);
          expect(text, isNot(contains('Android')), reason: text);
        }
        expect(l.deleteAccountConfirmationIos, contains('App Store'));
        expect(l.profileDeleteAccountWarningIos, contains('App Store'));
        expect(l.aiConsentTranslateReceived, contains('Google'));
        expect(l.eulaShort, 'EULA');
      });
    }
  });
}

Widget _host(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
