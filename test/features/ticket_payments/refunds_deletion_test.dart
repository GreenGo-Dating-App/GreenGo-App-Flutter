// Seller-cancelled refunds + account-deletion blockers (2026-10-21), app side:
// an event with paid, unrefunded tickets is cancelled (not deleted) by the
// Delete action, `paidOrderCount` is read but never written back, the
// blockers payload parses, and the deletion refusal maps to the sheet.
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/session_cache_gate.dart';
import 'package:greengo_chat/features/events/data/models/event_model.dart';
import 'package:greengo_chat/features/events/domain/entities/event.dart';
import 'package:greengo_chat/features/events/domain/repositories/events_repository.dart';
import 'package:greengo_chat/features/events/presentation/bloc/events_bloc.dart';
import 'package:greengo_chat/features/events/presentation/bloc/events_event.dart';
import 'package:greengo_chat/features/events/presentation/bloc/events_state.dart';
import 'package:greengo_chat/features/profile/data/deletion_blockers_service.dart';
import 'package:greengo_chat/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:greengo_chat/features/profile/presentation/bloc/profile_state.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/events_fixtures.dart';

class _MockEventsRepository extends Mock implements EventsRepository {}

void main() {
  group('Event.paidOrderCount', () {
    test('parsed from the server doc, default 0, never written back', () {
      final m = EventModel.fromJson(const {'id': 'e', 'price': 20, 'paidOrderCount': 3});
      expect(m.paidOrderCount, 3);
      expect(m.hasPaidSales, isTrue);
      expect(EventModel.fromJson(const {'id': 'e2', 'price': 20}).paidOrderCount, 0);
      // The rules refuse any client change of the server counter.
      expect(EventModel.fromEntity(m).toJson().containsKey('paidOrderCount'), isFalse);
      expect(m.copyWith(title: 'x').paidOrderCount, 3);
    });
  });

  group('Delete of a sold event = cancel (buyers refunded by the server)', () {
    late _MockEventsRepository repo;
    late EventsBloc bloc;
    final sold = EventFixtures.build(id: 'sold', startDate: DateTime(2030, 1, 1)).copyWith(paidOrderCount: 2);
    final unsold = EventFixtures.build(id: 'free', startDate: DateTime(2030, 2, 1));

    setUp(() async {
      SessionCacheGate.reset();
      repo = _MockEventsRepository();
      bloc = EventsBloc(repository: repo);
      when(() => repo.getEvents(
            category: any(named: 'category'),
            city: any(named: 'city'),
            upcoming: any(named: 'upcoming'),
            preferCache: any(named: 'preferCache'),
          )).thenAnswer((_) async => Right([sold, unsold]));
      when(() => repo.deleteEvent(any())).thenAnswer((_) async => const Right(null));
      bloc.add(const LoadEvents());
      await bloc.stream.firstWhere((s) => s is EventsLoaded);
    });
    tearDown(() => bloc.close());

    test('sold: stays listed as cancelled, cancel signal, data source called', () async {
      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<EventCancelledWithRefunds>().having((s) => s.eventId, 'id', 'sold'),
          isA<EventsLoaded>().having(
              (s) => s.events.firstWhere((e) => e.id == 'sold').status, 'status', EventStatus.cancelled),
        ]),
      );
      bloc.add(const DeleteEvent(eventId: 'sold'));
      await expectation;
      verify(() => repo.deleteEvent('sold')).called(1);
    });

    test('unsold: removed as before', () async {
      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<EventDeleted>(),
          isA<EventsLoaded>().having((s) => s.events.map((e) => e.id), 'ids', ['sold']),
        ]),
      );
      bloc.add(const DeleteEvent(eventId: 'free'));
      await expectation;
    });
  });

  group('deletion blockers', () {
    final payload = {
      'blocked': true,
      'blockers': [
        {
          'kind': 'event', 'listingId': 'e1', 'title': 'Rooftop Samba', 'startsAt': '2030-01-01T20:00:00.000Z',
          'paidOrders': 3, 'refundsInProgress': 1, 'failedRefunds': 1, 'pendingReview': 0,
          'bookingIds': <String>[],
          'actionOrders': [
            {'orderId': 'o1', 'status': 'refund_failed'},
            {'orderId': 'o2', 'status': 'manual_refund_pending_review'},
          ],
        },
        {'kind': 'experience', 'listingId': 'x1', 'title': 'Walk', 'paidOrders': 1, 'bookingIds': ['b1']},
        'junk',
      ],
    };

    test('parse', () {
      final b = parseDeletionBlockers(payload);
      expect(b, hasLength(2));
      expect(b[0].isEvent, isTrue);
      expect(b[0].failedOrderIds, ['o1']);
      expect(b[0].canCancel, isTrue); // 3 paid, 2 already being handled
      expect(b[0].startsAt, DateTime.utc(2030, 1, 1, 20));
      expect(b[1].isEvent, isFalse);
      expect(b[1].bookingIds, ['b1']);
      expect(b[1].canCancel, isTrue);
      expect(parseDeletionBlockers(null), isEmpty);
      expect(parseDeletionBlockers(const {'blocked': false, 'blockers': []}), isEmpty);
    });

    test('a cancelled event whose refunds all run cannot be cancelled again', () {
      final b = DeletionBlocker.fromMap(const {'kind': 'event', 'listingId': 'e', 'paidOrders': 2, 'refundsInProgress': 2});
      expect(b.canCancel, isFalse);
    });

    test('proof files: images or PDF only', () {
      expect(refundProofContentType('pix.PDF'), 'application/pdf');
      expect(refundProofContentType('a.jpeg'), 'image/jpeg');
      expect(refundProofContentType('a.png'), 'image/png');
      expect(refundProofContentType('a.txt'), isNull);
      expect(refundProofContentType('noext'), isNull);
      expect(kRefundProofMaxBytes, 10 * 1024 * 1024); // storage.rules refund_proofs
    });

    test('the server refusal maps to the blockers sheet', () {
      expect(
        ProfileBloc.deleteFailureFor('failed-precondition', {'code': kDeletionBlockedCode, 'blockers': []}),
        ProfileDeleteFailure.blockedPaidOrders,
      );
    });
  });
}
