import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/entitlement_usage.dart';
import 'package:greengo_chat/core/services/tier_entitlements.dart';
import 'package:greengo_chat/core/services/tier_gate.dart';
import 'package:greengo_chat/core/services/tier_limits_service.dart';
import 'package:greengo_chat/core/widgets/tier_comparison_table.dart';
import 'package:greengo_chat/features/coins/domain/entities/coin_transaction.dart';
import 'package:greengo_chat/features/membership/domain/entities/membership.dart';
import 'package:greengo_chat/features/subscription/domain/entities/subscription.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

/// Membership benefits audit (2026-10-11): what the app promises is exactly
/// what TierEntitlements holds (and the server enforces), and the gates read
/// the SERVER-owned counters (entitlement_usage/{uid}).
void main() {
  final now = DateTime.now();
  final future = Timestamp.fromDate(now.add(const Duration(days: 30)));
  final past = Timestamp.fromDate(now.subtract(const Duration(days: 1)));

  group('SubscriptionTier.features = TierEntitlements (honest promises)', () {
    const pairs = {
      SubscriptionTier.basic: MembershipTier.free,
      SubscriptionTier.silver: MembershipTier.silver,
      SubscriptionTier.gold: MembershipTier.gold,
      SubscriptionTier.platinum: MembershipTier.platinum,
    };

    test('no "ad-free" and no "see who connected" (H1 / H3)', () {
      for (final t in SubscriptionTier.values) {
        expect(t.features.containsKey('noAds'), isFalse);
        expect(t.features.containsKey('seeWhoConnected'), isFalse);
      }
    });

    test('every value comes from TierEntitlements', () {
      pairs.forEach((sub, m) {
        final f = sub.features;
        expect(f['eventsCreate'], TierEntitlements.maxEvents(m) ?? -1);
        expect(f['groupsCreate'], TierEntitlements.maxGroups(m) ?? -1);
        expect(f['dailyConnects'], TierEntitlements.maxDailyConnects(m) ?? -1);
        expect(f['boostsPerMonth'], TierEntitlements.boostsPerMonth(m));
        expect(f['monthlyCoins'], TierEntitlements.monthlyCoins(m));
        expect(f['travelMode'], TierEntitlements.travelModeEnabled(m));
        expect(f['travelModeFree'], TierEntitlements.travelModeFree(m));
        expect(f['prioritySupport'], TierEntitlements.prioritySupport(m));
        expect(f['businessAccount'], TierEntitlements.canBecomeBusiness(m));
      });
    });

    test('priority support: Gold and Platinum only (not Silver)', () {
      expect(SubscriptionTier.silver.features['prioritySupport'], isFalse);
      expect(SubscriptionTier.gold.features['prioritySupport'], isTrue);
      expect(SubscriptionTier.platinum.features['prioritySupport'], isTrue);
    });
  });

  group('comparison table (M7)', () {
    late AppLocalizations l10n;
    setUpAll(() async {
      l10n = await AppLocalizations.delegate.load(const Locale('en'));
    });

    test('rows carry a value per tier incl. Platinum, from TierEntitlements', () {
      final rows = TierEntitlements.comparisonRows(l10n,
          travelCoinsPerDay: CoinFeaturePrices.traveler);
      for (final r in rows) {
        expect(r.values, hasLength(4), reason: r.label);
      }
      String row(String label, int i) =>
          rows.firstWhere((r) => r.label == label).values[i];
      expect([for (var i = 0; i < 4; i++) row(l10n.shopEventsCreate, i)],
          ['1', '5', '10', l10n.shopUnlimited]);
      expect([for (var i = 0; i < 4; i++) row(l10n.shopExperiencesCreate, i)],
          ['1', '5', '10', l10n.shopUnlimited]);
      // Business accounts (paid tickets / bookings): Silver and up.
      expect([for (var i = 0; i < 4; i++) row(l10n.shopBusinessAccount, i)],
          ['✗', '✓', '✓', '✓']);
      expect([for (var i = 0; i < 4; i++) row(l10n.shopDailyConnects, i)],
          ['10', '50', '200', l10n.shopUnlimited]);
      expect([for (var i = 0; i < 4; i++) row(l10n.shopMonthlyBoosts, i)],
          ['0', '1', '4', '30']);
      expect([for (var i = 0; i < 4; i++) row(l10n.shopMonthlyCoins, i)],
          ['20', '300', '400', '500']);
      // Travel: Platinum free, Silver/Gold pay per day (H5 / M4).
      expect([for (var i = 0; i < 4; i++) row(l10n.tierTravelModeCostRow, i)],
          ['✗', '${CoinFeaturePrices.traveler}', '${CoinFeaturePrices.traveler}', l10n.tierFree]);
      expect([for (var i = 0; i < 4; i++) row(l10n.membershipPrioritySupport, i)],
          ['✗', '✗', '✓', '✓']);
    });

    testWidgets('renders the four tier columns and no removed promise', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: SingleChildScrollView(child: TierComparisonTable())),
      ));
      await tester.pumpAndSettle();
      expect(find.text(l10n.membershipPlatinum), findsOneWidget);
      expect(find.text(l10n.membershipBase), findsOneWidget);
      expect(find.text(l10n.membershipPrioritySupport), findsOneWidget);
      expect(find.textContaining('Ad-free'), findsNothing);
      expect(find.textContaining('See who'), findsNothing);
    });
  });

  group('entitlement_usage readers (UTC windows)', () {
    test('connects today / free boosts this month / ongoing events / groups', () {
      final usage = <String, dynamic>{
        'connectDayStartMs': utcDayStartMs(now),
        'connectCount': 7,
        'boostMonth': utcMonthKey(now),
        'boostsUsed': 2,
        'eventActiveEnds': [
          now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
          now.add(const Duration(days: 1)).millisecondsSinceEpoch,
        ],
        'eventExtraCredits': 2,
        'eventExtraUsed': 1,
        'groupsCreated': 1,
      };
      expect(connectsTodayFrom(usage, now), 7);
      expect(connectsTodayFrom(usage, now.add(const Duration(days: 1))), 0);
      expect(freeBoostsUsedFrom(usage, now), 2);
      expect(freeBoostsUsedFrom({...usage, 'boostMonth': '2000-01'}, now), 0);
      expect(ongoingEventSlotsFrom(usage, now), 1);
      expect(groupsCreatedFrom(usage), 1);
      expect(connectsTodayFrom(null, now), 0);
      expect(ongoingEventSlotsFrom(null, now), 0);
    });
  });

  group('TierGate / TierLimitsService read the server counters', () {
    late FakeFirebaseFirestore fs;
    late TierGate gate;
    late TierLimitsService limits;

    setUp(() async {
      fs = FakeFirebaseFirestore();
      gate = TierGate(firestore: fs);
      limits = TierLimitsService(firestore: fs);
      await fs.doc('profiles/free').set({'membershipTier': 'FREE'});
      await fs.doc('profiles/silver').set({'membershipTier': 'SILVER', 'membershipEndDate': future});
      await fs.doc('profiles/gold').set({'membershipTier': 'GOLD', 'membershipEndDate': future});
      await fs.doc('profiles/plat').set({'membershipTier': 'PLATINUM', 'membershipEndDate': future});
      await fs.doc('profiles/lapsed').set({'membershipTier': 'GOLD', 'membershipEndDate': past});
    });

    test('daily connects: today (UTC) against the effective tier cap', () async {
      await fs.doc('entitlement_usage/free').set({
        'connectDayStartMs': utcDayStartMs(now), 'connectCount': 10,
      });
      var r = await gate.canConnectToday('free');
      expect(r.allowed, isFalse);
      expect(r.current, 10);
      expect(r.limit, 10);
      await fs.doc('entitlement_usage/free').set({
        'connectDayStartMs': utcDayStartMs(now) - 86400000, 'connectCount': 10,
      });
      r = await gate.canConnectToday('free');
      expect(r.allowed, isTrue);
      expect(r.current, 0);
      await fs.doc('entitlement_usage/lapsed').set({
        'connectDayStartMs': utcDayStartMs(now), 'connectCount': 10,
      });
      expect((await gate.canConnectToday('lapsed')).allowed, isFalse);
      expect((await gate.canConnectToday('plat')).isUnlimited, isTrue);
    });

    test('free boosts: Silver 1 / Gold 4 / Platinum 30, none on the free plan', () async {
      await fs.doc('entitlement_usage/gold').set({'boostMonth': utcMonthKey(now), 'boostsUsed': 3});
      final g = await gate.boostAllowance('gold');
      expect(g.allowance, 4);
      expect(g.left, 1);
      final s = await gate.boostAllowance('silver');
      expect(s.allowance, 1);
      expect(s.left, 1);
      expect((await gate.boostAllowance('plat')).left, 30);
      final f = await gate.boostAllowance('free');
      expect(f.available, isFalse);
      expect((await gate.canBoost('free')).allowed, isFalse);
      // A paid plan may always boost: extra boosts cost coins.
      await fs.doc('entitlement_usage/silver').set({'boostMonth': utcMonthKey(now), 'boostsUsed': 1});
      expect((await gate.canBoost('silver')).allowed, isTrue);
      expect((await gate.boostAllowance('silver')).left, 0);
    });

    test('events: ACTIVE slots at a time (Base 1 / Silver 5 / Gold 10); no paid extras', () async {
      final ended = now.subtract(const Duration(days: 1)).millisecondsSinceEpoch;
      final running = now.add(const Duration(days: 1)).millisecondsSinceEpoch;
      await fs.doc('entitlement_usage/free').set({'eventActiveEnds': [ended, ended, ended]});
      var r = await limits.canCreateEvent('free');
      expect(r.allowed, isTrue, reason: 'ended events do not count');
      expect(r.current, 0);
      await fs.doc('entitlement_usage/free').set({'eventActiveEnds': [running]});
      r = await limits.canCreateEvent('free');
      expect(r.allowed, isFalse);
      expect(r.current, 1);
      expect(r.remaining, 0);
      // The retired coin credit no longer lets one more through.
      await fs.doc('entitlement_usage/free').set(
          {'eventExtraCredits': 1, 'eventExtraUsed': 0}, SetOptions(merge: true));
      expect((await limits.canCreateEvent('free')).allowed, isFalse);
      await fs.doc('entitlement_usage/silver')
          .set({'eventActiveEnds': List.filled(4, running)});
      r = await limits.canCreateEvent('silver');
      expect(r.allowed, isTrue);
      expect(r.max, 5);
      expect(r.remaining, 1);
      await fs.doc('entitlement_usage/gold')
          .set({'eventActiveEnds': List.filled(10, running)});
      r = await limits.canCreateEvent('gold');
      expect(r.allowed, isFalse);
      expect(r.max, 10);
      expect((await limits.canCreateEvent('plat')).max, isNull);
      expect((await limits.canCreateEvent('plat')).remaining, isNull);
    });

    test('groups: the server count, not a denied count() query', () async {
      expect((await limits.canCreateGroup('free')).allowed, isTrue);
      await fs.doc('entitlement_usage/free').set({'groupsCreated': 1});
      final r = await limits.canCreateGroup('free');
      expect(r.allowed, isFalse);
      expect(r.current, 1);
      expect((await limits.canCreateGroup('silver')).allowed, isTrue);
    });
  });
}
