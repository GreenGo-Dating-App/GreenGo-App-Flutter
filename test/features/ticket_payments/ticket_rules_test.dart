import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/events/data/datasources/events_remote_datasource.dart';
import 'package:greengo_chat/features/events/data/models/event_model.dart';
import 'package:greengo_chat/features/events/domain/entities/event.dart';
import 'package:greengo_chat/features/ticket_payments/data/ticket_payments_service.dart';
import 'package:greengo_chat/features/ticket_payments/domain/ticket_payments.dart';
import 'package:greengo_chat/features/ticket_payments/domain/ticket_rules.dart';
import 'package:greengo_chat/features/ticket_payments/presentation/ticket_l10n.dart';
import 'package:greengo_chat/features/ticket_payments/presentation/widgets/buy_ticket_sheet.dart';
import 'package:greengo_chat/features/ticket_payments/presentation/widgets/ticket_rules_widgets.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'package:greengo_chat/generated/app_localizations_en.dart';

/// Event ticket / guest rules (owner request 2026-10-18), app side. The
/// server (functions/src/ticket_payments/ticketRules.ts + firestore.rules)
/// enforces every rule; these tests pin the app's matching limits and UI.
Widget _app(Widget child) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

Event _event(Map<String, dynamic> over) => EventModel.fromJson({
      'id': 'e1', 'organizerId': 'org', 'title': 'Samba', 'maxAttendees': 20, ...over,
    });

EventAttendee _going(String id, {int guests = 0, RSVPStatus status = RSVPStatus.going}) => EventAttendee(
      id: id, eventId: 'e1', userId: id, userName: id, status: status, rsvpDate: DateTime(2026), guestCount: guests,
    );

void main() {
  final l = AppLocalizationsEn();

  group('constants mirror functions/src/ticket_payments/config.ts', () {
    final ts = File('functions/src/ticket_payments/config.ts').readAsStringSync();
    int constant(String name) =>
        int.parse(RegExp('export const $name = (\\d+);').firstMatch(ts)!.group(1)!);
    test('MAX_TICKETS_PER_BUYER', () => expect(kMaxTicketsPerBuyer, constant('MAX_TICKETS_PER_BUYER')));
    test('ATTENDEE_NAME_MAX', () => expect(kAttendeeNameMaxLength, constant('ATTENDEE_NAME_MAX')));
    test('the owner value', () => expect(kMaxTicketsPerBuyer, 4));
  });

  group('rule 1: no plus-ones on paid events', () {
    test('paid events read the setting as 0', () {
      expect(_event({'guestsAllowedPerAttendee': 2}).plusOnesAllowed, 2);
      expect(_event({'guestsAllowedPerAttendee': 2}).guestsAllowed, isTrue);
      final paid = _event({'guestsAllowedPerAttendee': 2, 'price': 25, 'ticketProvider': 'stripe'});
      expect(paid.isPaidEvent, isTrue);
      expect(paid.plusOnesAllowed, 0);
      expect(paid.guestsAllowed, isFalse);
      expect(_event({'guestsAllowedPerAttendee': 2, 'ticketProvider': 'stripe'}).plusOnesAllowed, 0);
      expect(plusOnesAllowedFrom({'guestsAllowedPerAttendee': 2}), 2);
      expect(plusOnesAllowedFrom({'guestsAllowedPerAttendee': 2, 'price': 10}), 0);
      expect(plusOnesAllowedFrom({'guestsAllowedPerAttendee': 30}), 10);
    });

    testWidgets('editor: stepper on free events, a note instead on paid ones', (tester) async {
      var v = 0;
      await tester.pumpWidget(_app(StatefulBuilder(
        builder: (context, set) => PlusOnesField(isFree: true, value: v, onChanged: (n) => set(() => v = n)),
      )));
      expect(find.byKey(const ValueKey('event-guests-per-attendee')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('event-guests-plus')));
      await tester.pump();
      expect(v, 1);
      await tester.pumpWidget(_app(PlusOnesField(isFree: false, value: 2, onChanged: (_) {})));
      expect(find.byKey(const ValueKey('event-guests-per-attendee')), findsNothing);
      expect(find.byKey(const ValueKey('event-plus-ones-paid-note')), findsOneWidget);
      expect(find.text(l.eventPlusOnesPaidNote), findsOneWidget);
    });
  });

  group('rule 2: at most 4 tickets per buyer per event', () {
    test('the event limit is its own, never above 4', () {
      expect(eventTicketLimit(_event({})), 4);
      expect(eventTicketLimit(_event({'maxTicketsPerUser': null})), 4);
      expect(eventTicketLimit(_event({'maxTicketsPerUser': 2})), 2);
      expect(eventTicketLimit(_event({'maxTicketsPerUser': 50})), 4);
      expect(ticketsBuyerCanAdd(_event({'maxTicketsPerUser': null}), alreadyHeld: 3, remainingCapacity: null), 1);
      expect(ticketsBuyerCanAdd(_event({'maxTicketsPerUser': null}), alreadyHeld: 0, remainingCapacity: 2), 2);
      expect(ticketsBuyerCanAdd(_event({}), alreadyHeld: 6, remainingCapacity: null), 0);
    });

    test('editor value 1..4, empty = 4', () {
      expect(ticketsPerBuyerInvalid(''), isFalse);
      expect(ticketsPerBuyerInvalid('3'), isFalse);
      expect(ticketsPerBuyerInvalid('5'), isTrue);
      expect(ticketsPerBuyerInvalid('0'), isTrue);
      expect(ticketsPerBuyerInvalid('x'), isTrue);
      expect(ticketsPerBuyerValue(''), 4);
      expect(ticketsPerBuyerValue('2'), 2);
      expect(ticketsPerBuyerValue('9'), 4);
    });

    testWidgets('editor field shows the range and an error above 4', (tester) async {
      final c = TextEditingController(text: '7');
      InputDecoration deco() => tester.widget<TextField>(find.byType(TextField)).decoration!;
      await tester.pumpWidget(_app(TicketsPerBuyerField(controller: c, decoration: const InputDecoration())));
      expect(deco().errorText, l.tpMaxTicketsPerUserRange(4));
      c.text = '3';
      await tester.pumpWidget(_app(TicketsPerBuyerField(controller: c, decoration: const InputDecoration())));
      expect(deco().errorText, isNull);
      expect(deco().helperText, l.tpMaxTicketsPerUserRange(4));
    });

    testWidgets('buy sheet: the stepper stops at 4 minus what the buyer already has', (tester) async {
      final ev = _event({
        'price': 20, 'currency': 'R\$', 'currencyCode': 'brl', 'maxAttendees': 0, 'maxTicketsPerUser': null,
        'ticketProvider': 'stripe',
      });
      await tester.pumpWidget(_app(BuyTicketSheet(event: ev, uid: 'u1', types: const [], alreadyHeld: 1)));
      await tester.pump();
      expect(find.text(l.tpCanBuyMore(3)), findsOneWidget);
      for (var i = 0; i < 5; i++) {
        await tester.tap(find.byKey(const ValueKey('buy-qty-single-plus')));
        await tester.pump();
      }
      expect(tester.widget<Text>(find.byKey(const ValueKey('buy-qty-single-value'))).data, '3');
    });

    test('server refusal -> "You can buy up to 4 tickets for this event" + next step', () {
      expect(TicketL10n.error(l, const TicketPaymentException('ticket_limit_reached', null, {'limit': 4, 'kind': 'event'})),
          startsWith('You can buy up to 4 tickets for this event.'));
      expect(TicketL10n.error(l, const TicketPaymentException('ticket_limit_reached', null, {'limit': 2, 'kind': 'experience'})),
          l.tpErrLimit);
      expect(TicketL10n.error(l, const TicketPaymentException('attendee_names_required')), l.tpErrAttendeeNamesRequired);
    });
  });

  group('rule 3: attendee names', () {
    test('trimmed, non-empty, bounded, no control characters', () {
      expect(cleanAttendeeName('  Ana   Maria '), 'Ana Maria');
      expect(cleanAttendeeName(' '), isNull);
      expect(cleanAttendeeName(null), isNull);
      expect(cleanAttendeeName('x' * 50), 'x' * 50);
      expect(cleanAttendeeName('x' * 51), isNull);
      expect(cleanAttendeeName('Ana\u0007'), isNull);
      expect(cleanAttendeeName('<Ana>'), isNull);
      expect(validAttendeeNames([('Ana', 'Lima'), ('João', ' Silva ')]),
          const [AttendeeName('Ana', 'Lima'), AttendeeName('João', 'Silva')]);
      expect(validAttendeeNames([('Ana', 'Lima'), ('', 'Silva')]), isNull);
      expect(const AttendeeName('Ana', 'Lima').toMap(), {'firstName': 'Ana', 'lastName': 'Lima'});
    });

    test('only paid events ask', () {
      expect(_event({'requireAttendeeNames': true, 'price': 20, 'ticketProvider': 'stripe'}).asksAttendeeNames, isTrue);
      expect(_event({'requireAttendeeNames': true}).asksAttendeeNames, isFalse);
      expect(_event({'price': 20, 'ticketProvider': 'stripe'}).asksAttendeeNames, isFalse);
      expect(EventModel.fromEntity(_event({'requireAttendeeNames': true, 'price': 20})).toJson()['requireAttendeeNames'], isTrue);
    });

    test('a ticket shows its holder', () {
      final t = IssuedTicket.fromMap('o_1', const {'orderId': 'o', 'qrPayload': 'q', 'attendeeName': 'Ana Lima'});
      expect(t.attendeeName, 'Ana Lima');
      expect(IssuedTicket.fromMap('o_2', const {'orderId': 'o', 'qrPayload': 'q'}).attendeeName, isNull);
    });

    testWidgets('editor: the switch', (tester) async {
      var on = false;
      await tester.pumpWidget(_app(StatefulBuilder(
        builder: (context, set) => AttendeeNamesSwitch(value: on, onChanged: (v) => set(() => on = v)),
      )));
      expect(find.text(l.tpAttendeeNamesSwitch), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('event-require-names')));
      await tester.pump();
      expect(on, isTrue);
    });

    testWidgets('buy sheet: one name pair per ticket, required before paying', (tester) async {
      final ev = _event({
        'price': 20, 'currency': 'R\$', 'currencyCode': 'brl', 'maxAttendees': 0, 'maxTicketsPerUser': null,
        'ticketProvider': 'stripe', 'requireAttendeeNames': true,
      });
      await tester.pumpWidget(_app(BuyTicketSheet(event: ev, uid: 'u1', types: const [], alreadyHeld: 0)));
      await tester.pump();
      expect(find.byKey(const ValueKey('buy-attendee-names')), findsOneWidget);
      expect(find.byKey(const ValueKey('buy-attendee-first-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('buy-attendee-first-1')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('buy-qty-single-plus')));
      await tester.pump();
      expect(find.byKey(const ValueKey('buy-attendee-last-1')), findsOneWidget);
      // Missing names: the checkout does not open, the error is shown.
      await tester.enterText(find.byKey(const ValueKey('buy-attendee-first-0')), 'Ana');
      await tester.enterText(find.byKey(const ValueKey('buy-attendee-last-0')), 'Lima');
      await tester.ensureVisible(find.byKey(const ValueKey('buy-continue')));
      await tester.tap(find.byKey(const ValueKey('buy-continue')));
      await tester.pump();
      expect(find.byKey(const ValueKey('buy-attendee-names-error')), findsOneWidget);
      expect(find.byType(BuyTicketSheet), findsOneWidget);
    });

    testWidgets('no names form when the event does not ask', (tester) async {
      final ev = _event({
        'price': 20, 'currency': 'R\$', 'currencyCode': 'brl', 'maxAttendees': 0, 'ticketProvider': 'stripe',
      });
      await tester.pumpWidget(_app(BuyTicketSheet(event: ev, uid: 'u1', types: const [], alreadyHeld: 0)));
      await tester.pump();
      expect(find.byKey(const ValueKey('buy-attendee-names')), findsNothing);
    });
  });

  group('rule 4: capacity vs price phases', () {
    test('a capacity below the phases total is reported with that total', () {
      expect(capacityBelowPhases(capacity: 5, unlimited: false, phaseQuantities: [3, 4]), 7);
      expect(capacityBelowPhases(capacity: 7, unlimited: false, phaseQuantities: [3, 4]), isNull);
      expect(capacityBelowPhases(capacity: 9, unlimited: false, phaseQuantities: [3, 4]), isNull);
      expect(capacityBelowPhases(capacity: 5, unlimited: true, phaseQuantities: [3, 4]), isNull);
      expect(capacityBelowPhases(capacity: 5, unlimited: false, phaseQuantities: const []), isNull);
      expect(capacityBelowPhases(capacity: null, unlimited: false, phaseQuantities: [3]), isNull);
      expect(l.evCapacityBelowPhases(7), contains('7 tickets'));
    });
  });

  group('rule 5: free events count places = 1 + plus-ones', () {
    test('capacity 20 with one +1 RSVP leaves 18', () {
      final e = _event({'guestsAllowedPerAttendee': 1}).copyWith(attendees: [_going('a', guests: 1)]);
      expect(e.goingCount, 2);
      expect(e.spotsLeft, 18);
      expect(e.isFull, isFalse);
    });

    test('waitlist / interested take no place; the counter wins when larger', () {
      final e = _event({'attendeeCount': 5}).copyWith(attendees: [
        _going('a', guests: 2),
        _going('b', status: RSVPStatus.waitlist, guests: 1),
        _going('c', status: RSVPStatus.interested),
      ]);
      expect(e.goingCount, 5);
      expect(_event({'attendeeCount': 1}).copyWith(attendees: [_going('a', guests: 2)]).goingCount, 3);
      final full = _event({'maxAttendees': 2}).copyWith(attendees: [_going('a', guests: 1)]);
      expect(full.isFull, isTrue);
    });

    test('roster entry places', () {
      expect(attendeePlaces({'status': 'going', 'guestCount': 1}), 2);
      expect(attendeePlaces({'status': 'going'}), 1);
      expect(attendeePlaces({'status': 'waitlist', 'guestCount': 1}), 0);
      expect(attendeePlaces(null), 0);
    });
  });
}
