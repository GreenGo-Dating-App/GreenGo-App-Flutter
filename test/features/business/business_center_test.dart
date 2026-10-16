import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/business/data/business_center_repository.dart';
import 'package:greengo_chat/features/business/presentation/screens/business_center_screen.dart';
import 'package:greengo_chat/features/finance_documents/data/billing_profile_repository.dart';
import 'package:greengo_chat/features/finance_documents/domain/billing_profile.dart';
import 'package:greengo_chat/features/membership/domain/entities/membership.dart';
import 'package:greengo_chat/features/profile/domain/entities/profile.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

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
}

class _Billing implements BillingProfileRepository {
  _Billing(this.complete);
  final bool complete;
  @override
  Future<BillingStatus> get() async => BillingStatus(complete: complete);
  @override
  Future<BillingStatus> save(BillingDraft draft) async => BillingStatus(complete: complete);
}

Profile _business({MembershipTier tier = MembershipTier.gold}) => buildBusinessProfile().copyWith(
      membershipTier: tier,
      membershipEndDate: DateTime.now().add(const Duration(days: 30)),
    );

Widget _app(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

String _text(WidgetTester t, String key) => (t.widget(find.byKey(ValueKey(key))) as Text).data!;

void main() {
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
    expect(find.byKey(const ValueKey('bc-todo-none')), findsOneWidget);
  });

  testWidgets('every former Business tool is in a tab; experiences point to My Space', (t) async {
    await t.pumpWidget(_app(BusinessCenterScreen(
        profile: _business(), repository: _Repo(), billingRepository: _Billing(true))));
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
    await tab('Listings');
    expect(find.byKey(const ValueKey('bc-events')), findsOneWidget);
    expect(find.byKey(const ValueKey('bc-experiences')), findsOneWidget);
    expect(find.byKey(const ValueKey('bc-scanner')), findsOneWidget);
    await tab('Marketing');
    expect(find.byKey(const ValueKey('bc-promote')), findsOneWidget);
    expect(find.byKey(const ValueKey('bc-analytics')), findsOneWidget);
    await tab('Storefront');
    expect(find.byKey(const ValueKey('bc-edit-storefront')), findsOneWidget);
    expect(find.byKey(const ValueKey('bc-account')), findsOneWidget);
    expect(find.byKey(const ValueKey('bc-verification')), findsOneWidget);
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
}
