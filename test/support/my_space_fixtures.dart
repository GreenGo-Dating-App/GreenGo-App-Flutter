import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/error/failures.dart';
import 'package:greengo_chat/core/services/qr_checkin_service.dart';
import 'package:greengo_chat/features/events/domain/entities/event.dart';
import 'package:greengo_chat/features/experience_bookings/domain/entities/booking.dart';
import 'package:greengo_chat/features/my_space/data/my_space_repository.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

/// In-memory [MySpaceRepository] for My Space widget / cubit tests.
class FakeMySpaceRepository implements MySpaceRepository {
  FakeMySpaceRepository({
    this.requests = 0,
    this.payments = 0,
    this.guestUpcoming = 0,
    this.hostUpcoming = 0,
    List<Event>? events,
    List<Booking>? hostBookings,
    Map<String, List<EventAttendee>>? attendees,
    this.failEvents = false,
  })  : events = events ?? <Event>[],
        hostBookings = hostBookings ?? <Booking>[],
        attendees = attendees ?? <String, List<EventAttendee>>{};

  int requests;
  int payments;
  int guestUpcoming;
  int hostUpcoming;
  List<Event> events;
  List<Booking> hostBookings;
  Map<String, List<EventAttendee>> attendees;
  bool failEvents;

  /// Refusal returned by [setEventCheckIn] (null = accepted).
  String? refuseCheckIn;
  final List<(String, String, bool)> checkInCalls = [];
  final List<String> manualBookingCalls = [];

  @override
  Future<int> bookingRequestsToConfirm(String uid) async => requests;

  @override
  Future<int> paymentsToConfirm(String uid) async => payments;

  @override
  Future<int> upcomingBookings(String uid, BookingRole role) async =>
      role == BookingRole.guest ? guestUpcoming : hostUpcoming;

  @override
  Future<List<Event>> myEvents(String uid) async {
    if (failEvents) throw Exception('offline');
    return events;
  }

  @override
  Future<EventCheckInStats> eventCheckInStats(String eventId) async {
    final going = (attendees[eventId] ?? const <EventAttendee>[])
        .where((a) => a.status == RSVPStatus.going)
        .toList();
    return EventCheckInStats(
        going: going.length, checkedIn: going.where((a) => a.checkedIn).length);
  }

  @override
  Future<AttendeesPage> goingAttendees(String eventId,
      {String? startAfterId, int limit = 50}) async {
    final all = (attendees[eventId] ?? const <EventAttendee>[])
        .where((a) => a.status == RSVPStatus.going)
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final from = startAfterId == null
        ? 0
        : all.indexWhere((a) => a.id == startAfterId) + 1;
    final page = all.skip(from).take(limit).toList();
    return AttendeesPage(items: page, hasMore: from + limit < all.length);
  }

  @override
  Future<CheckInOutcome> setEventCheckIn(
      String eventId, String userId, bool checkedIn) async {
    checkInCalls.add((eventId, userId, checkedIn));
    if (refuseCheckIn != null) {
      return CheckInOutcome(approved: false, reason: refuseCheckIn);
    }
    final list = attendees[eventId]!;
    final i = list.indexWhere((a) => a.userId == userId);
    list[i] = list[i].copyWith(checkedIn: checkedIn);
    return const CheckInOutcome(approved: true);
  }

  @override
  Future<List<Booking>> hostUpcomingConfirmed(String uid,
          {int limit = 50}) async =>
      hostBookings;

  @override
  Future<List<Booking>> sessionBookings(
          {required String hostId,
          required String experienceId,
          required DateTime slotStart}) async =>
      hostBookings
          .where(
              (b) => b.experienceId == experienceId && b.slotStart == slotStart)
          .toList();

  @override
  Future<Either<Failure, Booking>> manualCheckInBooking(Booking b) async {
    manualBookingCalls.add(b.id);
    final updated = b.copyWith(checkedInAt: DateTime(2030, 1, 1, 18, 5));
    hostBookings = [for (final x in hostBookings) x.id == b.id ? updated : x];
    return Right(updated);
  }
}

Booking testBooking({
  String id = 'b1',
  String experienceId = 'x1',
  String hostId = 'me',
  String guestId = 'g1',
  int guests = 1,
  BookingStatus status = BookingStatus.confirmed,
  DateTime? start,
  String title = 'Cooking class',
  DateTime? checkedInAt,
}) {
  final s = start ?? DateTime(2030, 1, 1, 18);
  return Booking(
    id: id,
    experienceId: experienceId,
    slotId: 's1',
    hostId: hostId,
    guestId: guestId,
    guests: guests,
    status: status,
    slotStart: s,
    slotEnd: s.add(const Duration(hours: 2)),
    experienceTitle: title,
    checkedInAt: checkedInAt,
  );
}

EventAttendee testAttendee(String eventId, String uid,
        {bool checkedIn = false,
        RSVPStatus status = RSVPStatus.going,
        String? name,
        int guests = 0}) =>
    EventAttendee(
      id: uid,
      eventId: eventId,
      userId: uid,
      userName: name ?? uid,
      status: status,
      rsvpDate: DateTime(2029, 12, 1),
      checkedIn: checkedIn,
      guestCount: guests,
    );

/// A localized app around [child] at a given logical width.
Future<void> pumpLocalized(WidgetTester tester, Widget child,
    {double width = 400, double height = 900}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  ));
}
