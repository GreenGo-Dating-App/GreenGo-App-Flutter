import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/app_guide/presentation/faq_entries.dart';
import 'package:greengo_chat/features/app_guide/presentation/screens/app_guide_screen.dart';
import 'package:greengo_chat/features/ticket_payments/data/ticket_payments_service.dart';
import 'package:greengo_chat/features/ticket_payments/domain/ticket_payments.dart';
import 'package:greengo_chat/features/ticket_payments/presentation/screens/my_ticket_orders_screen.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'package:greengo_chat/generated/app_localizations_de.dart';
import 'package:greengo_chat/generated/app_localizations_en.dart';

class _NoOrdersService extends TicketPaymentsService {
  @override
  Future<List<TicketOrder>> myOrders(String buyerId, {int limit = 50}) async =>
      const <TicketOrder>[];
}

void main() {
  final l = AppLocalizationsEn();

  Widget app(Widget home, {Locale locale = const Locale('en')}) => MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      );

  group('FAQ data', () {
    test('about 20 questions, all with text, in every language', () {
      for (final loc in [l, AppLocalizationsDe()]) {
        final faq = buildFaqEntries(loc);
        expect(faq.length, 20);
        expect(faq.map((e) => e.id).toSet().length, faq.length);
        for (final e in faq) {
          expect(e.question.trim(), isNotEmpty);
          expect(e.answer.trim(), isNotEmpty);
        }
      }
    });

    test('filterFaq matches every word, case-insensitive, in Q or A', () {
      final faq = buildFaqEntries(l);
      expect(filterFaq(faq, ''), faq);
      expect(filterFaq(faq, 'REFUND').map((e) => e.id), contains('tickets'));
      expect(filterFaq(faq, 'cancel subscription').map((e) => e.id),
          contains('cancel_subscription'));
      expect(filterFaq(faq, 'zzqqxx'), isEmpty);
    });

    test('facts that must match the app: fees caps, 4 tickets, launch offer',
        () {
      final faq = {for (final e in buildFaqEntries(l)) e.id: e.answer};
      expect(faq['seller_fees'],
          allOf(contains('US\$30'), contains('US\$28'), contains('US\$25')));
      expect(faq['price_phases'], contains('4 tickets'));
      expect(
          faq['launch_offer'],
          allOf(contains('50%'), contains('31 March 2027'),
              contains('no free trial')));
      expect(faq['translation'], contains('Google'));
      expect(faq['location'], contains('100 m'));
    });
  });

  group('App Guide FAQ search', () {
    testWidgets('typing filters the questions; nonsense shows "no results"',
        (t) async {
      await t.pumpWidget(app(const AppGuideScreen()));
      await t.pumpAndSettle();
      expect(find.text(l.xplFaqTitle), findsOneWidget);
      expect(find.byKey(const Key('faq_tickets')), findsOneWidget);

      await t.enterText(find.byKey(const Key('faq_search')), 'refund');
      await t.pumpAndSettle();
      expect(find.byKey(const Key('faq_tickets')), findsOneWidget);
      expect(find.byKey(const Key('faq_coins')), findsNothing);
      // The guide sections step aside while searching.
      expect(find.text(l.xplGuideFeaturesTitle), findsNothing);

      await t.enterText(find.byKey(const Key('faq_search')), 'zzqqxx');
      await t.pumpAndSettle();
      expect(find.byKey(const Key('faq_no_results')), findsOneWidget);
    });
  });

  group('Helpful empty states', () {
    testWidgets('My tickets: explains and offers Browse events', (t) async {
      await t.pumpWidget(
          app(MyTicketOrdersScreen(uid: 'u1', service: _NoOrdersService())));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('tickets_helpful_empty')), findsOneWidget);
      expect(find.text(l.xplEmptyTickets), findsOneWidget);
      expect(find.text(l.xplBrowseEvents), findsOneWidget);
    });

    testWidgets('My tickets empty state is translated (de)', (t) async {
      await t.pumpWidget(app(
        MyTicketOrdersScreen(uid: 'u1', service: _NoOrdersService()),
        locale: const Locale('de'),
      ));
      await t.pumpAndSettle();
      expect(find.text(AppLocalizationsDe().xplEmptyTickets), findsOneWidget);
    });
  });
}
