import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/error/failures.dart';
import 'package:greengo_chat/features/experience_bookings/domain/entities/booking.dart';
import 'package:greengo_chat/features/experience_bookings/domain/repositories/bookings_repository.dart';
import 'package:greengo_chat/features/experience_bookings/presentation/bookings_first_page_cache.dart';
import 'package:greengo_chat/features/experience_bookings/presentation/screens/bookings_list_screen.dart';
import 'package:greengo_chat/features/user_experiences/domain/repositories/user_experiences_repository.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/my_space_fixtures.dart';

/// No local first-page cache in widget tests (it is Hive file IO).
class _NoCache extends BookingsFirstPageCache {
  const _NoCache();
  @override
  Future<List<Booking>> load(BookingsQuery q) async => const [];
  @override
  Future<void> save(BookingsQuery q, List<Booking> page) async {}
}

class _Repo extends Fake implements BookingsRepository {
  _Repo(this.all);
  final List<Booking> all;
  final List<BookingsQuery> queries = [];
  final List<(String, bool)> responses = [];

  @override
  Future<Either<Failure, ExperiencePage<Booking>>> bookings(
    BookingsQuery query, {
    Object? cursor,
    int limit = 20,
  }) async {
    queries.add(query);
    final items = all
        .where((b) => query.status == null || b.status == query.status)
        .toList();
    return Right(ExperiencePage(items: items, hasMore: false));
  }

  @override
  Future<Either<Failure, Booking>> respond(Booking b,
      {required bool accept}) async {
    responses.add((b.id, accept));
    return Right(b.copyWith(
        status: accept ? BookingStatus.confirmed : BookingStatus.declined));
  }
}

void main() {
  // The first-page cache and the user directory persist through Hive.
  setUpAll(() => Hive.init(
      Directory.systemTemp.createTempSync('bookings_to_confirm_test').path));
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final requested =
      testBooking(id: 'r1', status: BookingStatus.requested, title: 'Pottery');
  final confirmed = testBooking(id: 'c1', title: 'Surf lesson');

  Future<_Repo> pump(WidgetTester tester, {bool openToConfirm = true}) async {
    final repo = _Repo([requested, confirmed]);
    await pumpLocalized(
      tester,
      BookingsListScreen(
        role: BookingRole.host,
        currentUserId: 'me',
        openToConfirm: openToConfirm,
        repository: repo,
        firstPageCache: const _NoCache(),
      ),
    );
    await tester.pumpAndSettle();
    return repo;
  }

  testWidgets('host list: To confirm / Upcoming / Past, opens on To confirm',
      (tester) async {
    final repo = await pump(tester);
    expect(find.text('To confirm'), findsOneWidget);
    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('Past'), findsOneWidget);
    expect(find.text('Pottery'), findsOneWidget);
    expect(find.text('Surf lesson'), findsNothing);
    expect(
        repo.queries.any((q) =>
            q.status == BookingStatus.requested && q.upcoming && q.uid == 'me'),
        isTrue);
  });

  testWidgets('quick Accept answers through respond and leaves the list',
      (tester) async {
    final repo = await pump(tester);
    await tester.tap(find.byKey(const ValueKey('accept-r1')));
    await tester.pumpAndSettle();
    expect(repo.responses, [('r1', true)]);
    expect(find.text('Pottery'), findsNothing);
    expect(find.text('No booking requests waiting for you.'), findsOneWidget);
  });

  testWidgets('quick Decline asks first', (tester) async {
    final repo = await pump(tester);
    await tester.tap(find.byKey(const ValueKey('decline-r1')));
    await tester.pumpAndSettle();
    expect(repo.responses, isEmpty);
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.descendant(
        of: find.byType(AlertDialog), matching: find.text('Decline')));
    await tester.pumpAndSettle();
    expect(repo.responses, [('r1', false)]);
  });

  testWidgets('without a pending badge it opens on Upcoming', (tester) async {
    await pump(tester, openToConfirm: false);
    expect(find.text('Surf lesson'), findsOneWidget);
  });

  test('the status filter is part of the query and its cache key', () {
    const a = BookingsQuery(role: BookingRole.host, uid: 'u', upcoming: true);
    const b = BookingsQuery(
        role: BookingRole.host,
        uid: 'u',
        upcoming: true,
        status: BookingStatus.requested);
    expect(a == b, isFalse);
    expect(BookingsFirstPageCache.keyFor(a),
        isNot(BookingsFirstPageCache.keyFor(b)));
    expect(BookingsFirstPageCache.keyFor(a), 'bookings_host_up_');
  });
}
