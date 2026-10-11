import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:greengo_chat/features/referral/data/services/referral_service.dart';
import 'package:greengo_chat/features/referral/presentation/screens/referral_screen.dart';
import 'package:greengo_chat/features/referral/presentation/widgets/referral_progress_card.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  Widget host(Widget child) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      );

  Future<void> pumpCard(WidgetTester tester, ReferralProgress p) async {
    await tester.pumpWidget(host(ReferralProgressCard(progress: p)));
    await tester.pump();
  }

  group('ReferralProgressCard', () {
    testWidgets('7 friends: Silver unlocked, 3 more to Gold', (tester) async {
      await pumpCard(
        tester,
        const ReferralProgress(
            invitedCount: 7, coinsEarned: 350, milestonesGranted: {5}),
      );
      expect(find.text(l10n.referralFriendsJoined(7)), findsOneWidget);
      expect(find.text('7 friends joined'), findsOneWidget);
      expect(find.text(l10n.referralMoreToTier(3, l10n.membershipGold)),
          findsOneWidget);
      expect(find.text('3 more to Gold'), findsOneWidget);
      expect(
          find.byKey(const Key('referralMilestoneUnlocked_5')), findsOneWidget);
      expect(
          find.byKey(const Key('referralMilestoneLocked_10')), findsOneWidget);
      expect(
          find.byKey(const Key('referralMilestoneLocked_20')), findsOneWidget);
      // The ladder names every reward.
      expect(find.text(l10n.referralMilestoneReward(l10n.membershipSilver)),
          findsOneWidget);
      expect(find.text(l10n.referralMilestoneReward(l10n.membershipGold)),
          findsOneWidget);
      expect(find.text(l10n.referralMilestoneReward(l10n.membershipPlatinum)),
          findsOneWidget);
    });

    testWidgets('no friends yet: 5 more to Silver, nothing unlocked',
        (tester) async {
      await pumpCard(tester, ReferralProgress.empty);
      expect(find.text(l10n.referralFriendsJoined(0)), findsOneWidget);
      expect(find.text(l10n.referralMoreToTier(5, l10n.membershipSilver)),
          findsOneWidget);
      for (final c in [5, 10, 20]) {
        expect(find.byKey(Key('referralMilestoneLocked_$c')), findsOneWidget);
      }
    });

    testWidgets('19 friends: 1 more to Platinum (singular)', (tester) async {
      await pumpCard(
        tester,
        const ReferralProgress(
            invitedCount: 19, coinsEarned: 950, milestonesGranted: {5, 10}),
      );
      expect(find.text('1 more to Platinum'), findsOneWidget);
    });

    testWidgets('20+ friends: all unlocked', (tester) async {
      await pumpCard(
        tester,
        const ReferralProgress(
            invitedCount: 23,
            coinsEarned: 1000,
            milestonesGranted: {5, 10, 20}),
      );
      expect(find.text(l10n.referralAllMilestonesUnlocked), findsOneWidget);
      for (final c in [5, 10, 20]) {
        expect(find.byKey(Key('referralMilestoneUnlocked_$c')), findsOneWidget);
      }
    });

    testWidgets('renders in every supported locale without overflow',
        (tester) async {
      for (final locale in AppLocalizations.supportedLocales) {
        await tester.pumpWidget(MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: SizedBox(
              width: 320,
              child: SingleChildScrollView(
                child: ReferralProgressCard(
                  progress: ReferralProgress(
                      invitedCount: 7,
                      coinsEarned: 350,
                      milestonesGranted: {5}),
                ),
              ),
            ),
          ),
        ));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: '$locale');
      }
    });
  });

  group('ReferralScreen', () {
    late FakeFirebaseFirestore firestore;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      GetIt.instance.registerSingleton<ReferralService>(
          ReferralService(firestore: firestore));
    });
    tearDown(() => GetIt.instance.reset());

    testWidgets(
        'reads the server-authoritative referral_stats doc and states the rules',
        (tester) async {
      await firestore.doc('referral_codes/ABC234').set({'ownerId': 'me'});
      await firestore.doc('referrals/me').set({
        'code': 'ABC234',
        // Display mirror (client-writable): must NOT drive the progress.
        'invitedCount': 99,
        'coinsEarned': 0,
      });
      await firestore.doc('referral_stats/me').set({
        'invitedCount': 12,
        'coinsEarned': 600,
        'milestonesGranted': [5, 10],
      });

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ReferralScreen(userId: 'me'),
      ));
      await tester.pumpAndSettle();

      expect(
          find.text('https://greengo-chat.web.app/r/ABC234'), findsOneWidget);
      expect(find.text(l10n.referralLinkHowItWorks), findsOneWidget);
      expect(find.byType(TextField), findsNothing); // no code entry
      expect(find.text('12 friends joined'), findsOneWidget);
      expect(find.text('8 more to Platinum'), findsOneWidget);
      expect(find.text('600'), findsOneWidget);
      expect(find.text('99'), findsNothing);
      expect(
          find.byKey(const Key('referralMilestoneUnlocked_5')), findsOneWidget);
      expect(find.byKey(const Key('referralMilestoneUnlocked_10')),
          findsOneWidget);
      expect(
          find.byKey(const Key('referralMilestoneLocked_20')), findsOneWidget);

      await tester.scrollUntilVisible(
          find.text(l10n.referralRuleAlwaysCounts), 200,
          scrollable: find.byType(Scrollable).first);
      expect(find.text('Your friend gets 1 week of Base membership'),
          findsOneWidget);
      expect(
          find.text(
              'You get 50 coins per friend who joins (up to 1,000 coins a month)'),
          findsOneWidget);
      expect(find.textContaining('Platinum.'), findsNothing);
    });

    testWidgets('a user without a code gets one from the server (invite link)',
        (tester) async {
      await GetIt.instance.reset();
      GetIt.instance.registerSingleton<ReferralService>(ReferralService(
          firestore: firestore, serverCode: () async => 'SRV234'));
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ReferralScreen(userId: 'newbie'),
      ));
      await tester.pumpAndSettle();
      expect(
          find.text('https://greengo-chat.web.app/r/SRV234'), findsOneWidget);
    });
  });
}
