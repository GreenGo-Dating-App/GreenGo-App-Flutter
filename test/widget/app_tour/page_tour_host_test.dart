import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/app_tour/presentation/tour_controller.dart';
import 'package:greengo_chat/features/app_tour/presentation/tour_environment.dart';
import 'package:greengo_chat/features/app_tour/presentation/tour_keys.dart';
import 'package:greengo_chat/features/app_tour/presentation/widgets/page_tour_host.dart';
import 'package:greengo_chat/features/app_tour/presentation/widgets/tour_showcase.dart';
import 'package:greengo_chat/features/business/data/business_center_repository.dart';
import 'package:greengo_chat/features/business/presentation/screens/business_center_screen.dart';
import 'package:greengo_chat/features/finance_documents/data/billing_profile_repository.dart';
import 'package:greengo_chat/features/finance_documents/domain/billing_profile.dart';
import 'package:greengo_chat/features/membership/domain/entities/membership.dart';
import 'package:greengo_chat/features/profile/domain/entities/profile.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/profile_fixtures.dart';

class _Repo implements BusinessCenterRepository {
  @override
  Future<BusinessMonthStats> monthStats(String uid, DateTime now) async =>
      const BusinessMonthStats(
          ticketsSold: 1, orders: 1, currency: 'brl', sales: 100, fees: 10,
          net: 90, followers: 1, newLeads: 0, ratingAvg: 0, ratingCount: 0);

  @override
  Future<BusinessTodo> todo(String uid) async => const BusinessTodo();
}

class _Billing implements BillingProfileRepository {
  @override
  Future<BillingStatus> get() async => const BillingStatus(complete: true);
  @override
  Future<BillingStatus> save(BillingDraft draft) async =>
      const BillingStatus(complete: true);
}

Widget _app(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

/// Lets the host's post-frame + start delay elapse without pumpAndSettle
/// (the tooltip glyphs animate forever).
Future<void> _elapse(WidgetTester t, [int ms = 2500]) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

const _tour = 'test_page';
final _a = GlobalKey(debugLabel: 'a');
final _b = GlobalKey(debugLabel: 'b');
final _never = GlobalKey(debugLabel: 'never-mounted');

Widget _page({bool enabled = true}) => _app(Scaffold(
      body: PageTourHost(
        tourId: _tour,
        userId: 'u1',
        enabled: enabled,
        keys: () => [_a, _never, _b],
        child: Column(children: [
          TourAnchor(
              tourId: _tour,
              showcaseKey: _a,
              title: 'A-title',
              description: 'A-desc',
              child: const Text('A')),
          TourAnchor(
              tourId: _tour,
              showcaseKey: _b,
              title: 'B-title',
              description: 'B-desc',
              child: const Text('B')),
        ]),
      ),
    ));

void main() {
  setUp(() {
    TourEnvironment.debugOverride = true;
    TourController.debugResetPrefsCache();
  });
  tearDown(() => TourEnvironment.debugOverride = null);

  testWidgets('starts once per user, skipping unmounted steps', (t) async {
    SharedPreferences.setMockInitialValues({});
    await t.pumpWidget(_page());
    await _elapse(t);
    expect(find.byType(TourShowcase), findsNWidgets(2));
    expect(find.text('A-title'), findsOneWidget);
    // Step numbering only counts the mounted steps (1/2).
    expect(TourController.instance.stepNumberFor(_a), (1, 2));
    expect(TourController.instance.stepNumberFor(_b), (2, 2));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(TourController.prefKeyFor(_tour, 'u1')), isTrue);

    // Next visit: not armed, no showcase targets in the tree at all.
    await t.pumpWidget(const SizedBox());
    await t.pumpWidget(_page());
    await _elapse(t);
    expect(find.byType(TourShowcase), findsNothing);
    expect(find.text('A-title'), findsNothing);
    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('disabled host never arms', (t) async {
    SharedPreferences.setMockInitialValues({});
    await t.pumpWidget(_page(enabled: false));
    await _elapse(t);
    expect(find.byType(TourShowcase), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(TourController.prefKeyFor(_tour, 'u1')), isNull);
  });

  testWidgets('App Guide reset re-arms a mounted page', (t) async {
    SharedPreferences.setMockInitialValues(
        {TourController.prefKeyFor(_tour, 'u1'): true});
    await t.pumpWidget(_page());
    await _elapse(t);
    expect(find.byType(TourShowcase), findsNothing);
    await TourController.instance.resetTour(_tour, 'u1');
    await _elapse(t);
    expect(find.text('A-title'), findsOneWidget);
  });

  testWidgets('Business Center tour starts once on the tab bar', (t) async {
    t.view.physicalSize = const Size(1200, 2400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final Profile p = buildBusinessProfile().copyWith(
      membershipTier: MembershipTier.gold,
      membershipEndDate: DateTime.now().add(const Duration(days: 30)),
    );
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    Widget screen() => _app(BusinessCenterScreen(
        profile: p, repository: _Repo(), billingRepository: _Billing()));

    await t.pumpWidget(screen());
    await _elapse(t);
    expect(find.text(l.tourBcOverviewDesc), findsOneWidget);
    expect(TourController.instance.stepNumberFor(TourKeys.bcOverview), (1, 6));
    final prefs = await SharedPreferences.getInstance();
    expect(
        prefs.getBool(TourController.prefKeyFor(
            TourController.businessCenterTourId, p.userId)),
        isTrue);

    await t.pumpWidget(const SizedBox());
    await t.pumpWidget(screen());
    await _elapse(t);
    expect(find.text(l.tourBcOverviewDesc), findsNothing);
    expect(find.byType(TourShowcase), findsNothing);
  });
}
