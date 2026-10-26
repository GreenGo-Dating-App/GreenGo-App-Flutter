import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/business/data/business_center_repository.dart';
import 'package:greengo_chat/features/business/presentation/company_checklist.dart';
import 'package:greengo_chat/features/business/presentation/screens/business_center_screen.dart';
import 'package:greengo_chat/features/finance_documents/data/billing_profile_repository.dart';
import 'package:greengo_chat/features/finance_documents/domain/billing_profile.dart';
import 'package:greengo_chat/features/membership/domain/entities/membership.dart';
import 'package:greengo_chat/features/profile/domain/entities/business_address.dart';
import 'package:greengo_chat/features/profile/domain/entities/profile.dart';
import 'package:greengo_chat/features/trader/data/trader_repository.dart';
import 'package:greengo_chat/features/trader/domain/trader_declaration.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

import '../../support/my_space_fixtures.dart';
import '../../support/profile_fixtures.dart';

class _Repo implements BusinessCenterRepository {
  _Repo({this.todoValue = const BusinessTodo()});
  final BusinessTodo todoValue;

  @override
  Future<BusinessMonthStats> monthStats(String uid, DateTime now) async => const BusinessMonthStats(
        ticketsSold: 12, orders: 9, currency: 'brl', sales: 50000, fees: 5000, net: 45000,
        followers: 34, newLeads: 5, ratingAvg: 4.5, ratingCount: 10);

  @override
  Future<BusinessTodo> todo(String uid) async => todoValue;

  final visibilityWrites = <StoreVisibility>[];
  @override
  Future<void> setStoreVisibility(String uid, StoreVisibility v) async => visibilityWrites.add(v);
}

class _Billing implements BillingProfileRepository {
  _Billing(this.complete);
  final bool complete;
  @override
  Future<BillingStatus> get() async => BillingStatus(complete: complete);
  @override
  Future<BillingStatus> save(BillingDraft draft) async => BillingStatus(complete: complete);
}

class _Trader extends TraderRepository {
  _Trader(this.declared);
  final bool declared;
  @override
  Future<TraderStatus> get() async =>
      TraderStatus(declaration: declared ? const TraderDeclaration(isTrader: false) : null);
}

Profile _business({MembershipTier tier = MembershipTier.gold, bool complete = true}) => buildBusinessProfile().copyWith(
      membershipTier: tier,
      membershipEndDate: DateTime.now().add(const Duration(days: 30)),
      businessCategory: complete ? 'cafe' : null,
      storefrontBio: complete ? 'Coffee and cake' : null,
      businessAddress: complete ? const BusinessAddress(address: 'Rua A 1', latitude: -23.5, longitude: -46.6) : null,
      // Gallery AND cover present either way: the required photo is the
      // BUSINESS PROFILE PICTURE (owner 2026-10-19).
      galleryImages: const ['https://example.com/g1.jpg'],
      coverImageUrl: 'https://example.com/cover.jpg',
      businessLogoUrl: complete ? 'https://example.com/logo.jpg' : '',
    );

Widget _app(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

String _text(WidgetTester t, String key) => (t.widget(find.byKey(ValueKey(key))) as Text).data!;

void main() {
  test('storefront photo checklist item = business profile picture, not cover/gallery', () {
    final p = _business();
    expect(companyChecklist(p)[CompanyItem.storefrontPhoto], isTrue);
    expect(companyChecklist(p.copyWith(businessLogoUrl: ''))[CompanyItem.storefrontPhoto], isFalse);
    // A cover and a gallery do not satisfy it.
    expect(
        companyChecklist(p.copyWith(
            businessLogoUrl: ' ',
            coverImageUrl: 'https://x/c.jpg',
            galleryImages: const ['https://x/1.jpg']))[CompanyItem.storefrontPhoto],
        isFalse);
    // The featured image alone is no longer required.
    expect(companyChecklist(p.copyWith(coverImageUrl: ''))[CompanyItem.storefrontPhoto], isTrue);
  });

  testWidgets('checklist item is labelled "Business profile picture"', (t) async {
    await t.pumpWidget(_app(const SizedBox()));
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    expect(l.bcCheckStorefrontPhoto, 'Business profile picture');
    final it = await AppLocalizations.delegate.load(const Locale('it'));
    expect(it.bcCheckStorefrontPhoto, "Foto profilo dell'attività");
  });

  testWidgets('overview: this month figures and what needs action', (t) async {
    t.view.physicalSize = const Size(1200, 2400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(_app(BusinessCenterScreen(
      profile: _business(),
      repository: _Repo(todoValue: const BusinessTodo(bookingRequests: 2, paymentsConnected: false)),
      billingRepository: _Billing(false),
    )));
    await t.pumpAndSettle();
    expect(find.text('Business Center'), findsOneWidget);
    expect(_text(t, 'bc-kpi-sales-value'), contains('500'));
    expect(_text(t, 'bc-kpi-payout-value'), contains('450'));
    expect(_text(t, 'bc-kpi-tickets-value'), '12');
    expect(_text(t, 'bc-kpi-followers-value'), '34');
    expect(_text(t, 'bc-kpi-leads-value'), '5');
    expect(_text(t, 'bc-kpi-rating-value'), contains('4.5'));
    expect(find.byKey(const ValueKey('bc-todo-connect')), findsOneWidget);
    expect(find.byKey(const ValueKey('bc-todo-bookings')), findsOneWidget);
    expect(find.byKey(const ValueKey('billing-required-banner')), findsOneWidget);
    expect(find.byKey(const ValueKey('bc-todo-none')), findsNothing);
  });

  testWidgets('nothing pending: all caught up', (t) async {
    await t.pumpWidget(_app(BusinessCenterScreen(
        profile: _business(), repository: _Repo(), billingRepository: _Billing(true))));
    await t.pumpAndSettle();
    // The "How it works" card sits above it: scroll it into view.
    await t.dragUntilVisible(find.byKey(const ValueKey('bc-todo-none')),
        find.byKey(const ValueKey('bc-overview')), const Offset(0, -200));
    expect(find.byKey(const ValueKey('bc-todo-none')), findsOneWidget);
  });

  testWidgets('every former Business tool is in a tab; events, experiences and scanner are the My Space tab', (t) async {
    await t.pumpWidget(_app(BusinessCenterScreen(
        profile: _business(), repository: _Repo(), billingRepository: _Billing(true), mySpaceRepository: FakeMySpaceRepository())));
    await t.pumpAndSettle();
    Future<void> tab(String label) async {
      await t.tap(find.text(label).last);
      await t.pumpAndSettle();
    }

    await tab('Customers');
    expect(find.byKey(const ValueKey('bc-leads')), findsOneWidget);
    expect(find.byKey(const ValueKey('bc-followers')), findsOneWidget);
    await tab('Sales');
    expect(find.byKey(const ValueKey('bc-get-paid')), findsOneWidget);
    expect(find.byKey(const ValueKey('bc-invoices')), findsOneWidget);
    await tab('My Space');
    expect(find.byKey(const ValueKey('bc-my-space')), findsOneWidget);
    await tab('Marketing');
    expect(find.byKey(const ValueKey('bc-promote')), findsOneWidget);
    expect(find.byKey(const ValueKey('bc-analytics')), findsOneWidget);
    // Followers lives only in Customers (owner, 2026-10-18).
    expect(find.byKey(const ValueKey('bc-followers-m')), findsNothing);
    await tab('Storefront');
    expect(find.byKey(const ValueKey('bc-edit-storefront')), findsOneWidget);
    expect(find.byKey(const ValueKey('bc-account')), findsOneWidget);
    expect(find.byKey(const ValueKey('bc-verification')), findsOneWidget);
  });

  testWidgets('storefront: Store visibility saves the owner choice at once', (t) async {
    t.view.physicalSize = const Size(1200, 2400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final repo = _Repo();
    await t.pumpWidget(_app(BusinessCenterScreen(
        profile: _business(), repository: repo, billingRepository: _Billing(true), mySpaceRepository: FakeMySpaceRepository())));
    await t.pumpAndSettle();
    await t.tap(find.text('Storefront').last);
    await t.pumpAndSettle();
    RadioListTile<StoreVisibility> tile(StoreVisibility v) =>
        t.widget(find.byKey(ValueKey('bc-store-visibility-${v.wire}')));
    expect(find.text('Store visibility'), findsOneWidget);
    expect(tile(StoreVisibility.visible).groupValue, StoreVisibility.visible);

    await t.tap(find.text('Fully hidden'));
    await t.pumpAndSettle();
    expect(repo.visibilityWrites, [StoreVisibility.fullyHidden]);
    expect(tile(StoreVisibility.fullyHidden).groupValue, StoreVisibility.fullyHidden);

    await t.tap(find.text('Hidden from Discover'));
    await t.pumpAndSettle();
    expect(repo.visibilityWrites, [StoreVisibility.fullyHidden, StoreVisibility.hiddenFromDiscovery]);
  });

  testWidgets('tabs are in the owner order: Overview, My Space, Sales, Marketing, Customers, Storefront, Settings', (t) async {
    await t.pumpWidget(_app(BusinessCenterScreen(
        profile: _business(), repository: _Repo(), billingRepository: _Billing(true), mySpaceRepository: FakeMySpaceRepository())));
    await t.pumpAndSettle();
    final labels = t.widgetList<Tab>(find.byType(Tab)).map((x) => x.text).toList();
    expect(labels, ['Overview', 'My Space', 'Sales', 'Marketing', 'Customers', 'Storefront', 'Settings']);
  });

  testWidgets('settings: company checklist, and missing details show in Action needed', (t) async {
    t.view.physicalSize = const Size(1200, 2400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(_app(BusinessCenterScreen(
        profile: _business(complete: false),
        repository: _Repo(),
        billingRepository: _Billing(true),
        traderRepository: _Trader(false))));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('bc-todo-company')), findsOneWidget);
    // The storefront photo has its own "Action needed" row.
    expect(find.byKey(const ValueKey('bc-todo-storefront-photo')), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('bc-todo-company')));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('bc-settings')), findsOneWidget);
    expect(_text(t, 'bc-company-progress'), '3 of 8 required items complete');
    // Terms 12.4 / DSA art. 30: the trader declaration is a required item.
    expect(_text(t, 'bc-check-traderStatus-state'), 'Missing: tap to add');
    expect(_text(t, 'bc-check-description-state'), 'Missing: tap to add');
    expect(_text(t, 'bc-check-storefrontPhoto-state'), 'Missing: tap to add');
    expect(_text(t, 'bc-check-name-state'), 'Done');
    expect(_text(t, 'bc-check-invoiceDetails-state'), 'Done');
  });

  testWidgets('a paused business (below Silver) gets the reactivate screen', (t) async {
    await t.pumpWidget(_app(BusinessCenterScreen(
        profile: _business(tier: MembershipTier.free), repository: _Repo(), billingRepository: _Billing(true))));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('bc-tabs')), findsNothing);
    final l = AppLocalizations.of(t.element(find.byType(Scaffold).first))!;
    expect(find.text(l.businessPausedTitle), findsOneWidget);
  });

  test('month summary: this month only, main currency, net falls back to total - fee', () {
    final since = DateTime(2026, 10);
    Map<String, dynamic> o(int day, String cur, int total, int fee, {int? net, int qty = 1}) => {
          'paidAt': Timestamp.fromDate(DateTime(2026, 10, day)),
          'currency': cur, 'totalAmount': total, 'feeTotal': fee, 'quantity': qty, if (net != null) 'hostNet': net,
        };
    final s = summarizeOrders([
      o(2, 'brl', 10000, 1000, net: 9000, qty: 2),
      o(5, 'brl', 5000, 500),
      o(6, 'usd', 3000, 300),
      {'paidAt': Timestamp.fromDate(DateTime(2026, 9, 30)), 'currency': 'brl', 'totalAmount': 99999, 'feeTotal': 0, 'quantity': 1},
    ], since);
    expect(s.currency, 'brl');
    expect(s.ticketsSold, 4);
    expect(s.sales, 15000);
    expect(s.fees, 1500);
    expect(s.net, 9000 + 4500);
  });

  testWidgets('settings: a saved trader declaration counts as done', (t) async {
    t.view.physicalSize = const Size(1200, 2400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(_app(BusinessCenterScreen(
        profile: _business(),
        repository: _Repo(),
        billingRepository: _Billing(true),
        traderRepository: _Trader(true))));
    await t.pumpAndSettle();
    await t.tap(find.text('Settings').last);
    await t.pumpAndSettle();
    expect(_text(t, 'bc-check-traderStatus-state'), 'Done');
  });
}
