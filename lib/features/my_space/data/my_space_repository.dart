import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../core/di/injection_container.dart' as di;
import '../../../core/error/failures.dart';
import '../../../core/services/qr_checkin_service.dart';
import '../../events/data/datasources/events_remote_datasource.dart';
import '../../events/data/models/event_attendee_model.dart';
import '../../events/domain/entities/event.dart';
import '../../experience_bookings/data/models/booking_model.dart';
import '../../experience_bookings/domain/booking_rules.dart';
import '../../experience_bookings/domain/entities/booking.dart';
import '../../experience_bookings/domain/repositories/bookings_repository.dart';
import '../domain/my_space_models.dart';

/// Data behind "My Space" (Explore → My Space) and the booking dashboard
/// cards. Everything here is a per-user indexed query or a server
/// `count()` aggregate — never a full-collection read — so the hub costs a
/// handful of index lookups for any user, at any scale:
///
///   bookings      (hostId|guestId, status, slotStart)  count / page
///   ticket_orders (organizerId, status)                count
///   events/{id}/attendees (status[, checkedIn])        count / page
///
/// It AGGREGATES the existing sources ([EventsRemoteDataSource],
/// [BookingsRepository], [QrCheckinService]); the business rules stay in
/// those and on the server.
abstract class MySpaceRepository {
  /// Host: booking requests waiting for an answer.
  Future<int> bookingRequestsToConfirm(String uid);

  /// Organizer: manual ticket payments the buyer marked as sent.
  Future<int> paymentsToConfirm(String uid);

  /// Upcoming active bookings: as a guest (requested + confirmed) or as the
  /// host (confirmed).
  Future<int> upcomingBookings(String uid, BookingRole role);

  /// Events the user organizes, co-owns or is going to (bounded, memoised).
  Future<List<Event>> myEvents(String uid);

  /// Going attendees and how many of them are checked in (2 count()s).
  Future<EventCheckInStats> eventCheckInStats(String eventId);

  /// One page of an event's GOING attendees, by attendee id.
  Future<AttendeesPage> goingAttendees(String eventId,
      {String? startAfterId, int limit = 50});

  /// Organizer ticks [userId] in / out (server callable, audited).
  Future<CheckInOutcome> setEventCheckIn(
      String eventId, String userId, bool checkedIn);

  /// Host: the next confirmed bookings (soonest first) — grouped into
  /// sessions by [CheckInSession.group].
  Future<List<Booking>> hostUpcomingConfirmed(String uid, {int limit = 50});

  /// Host: every booking of one session (experience + start time).
  Future<List<Booking>> sessionBookings(
      {required String hostId,
      required String experienceId,
      required DateTime slotStart});

  /// Host ticks a guest in without the code (server callable, audited).
  Future<Either<Failure, Booking>> manualCheckInBooking(Booking b);
}

class FirestoreMySpaceRepository implements MySpaceRepository {
  FirestoreMySpaceRepository({
    FirebaseFirestore? firestore,
    EventsRemoteDataSource? events,
    BookingsRepository? bookings,
    QrCheckinService? checkin,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _eventsOverride = events,
        _bookingsOverride = bookings,
        _checkin = checkin ?? QrCheckinService();

  final FirebaseFirestore _db;
  final EventsRemoteDataSource? _eventsOverride;
  final BookingsRepository? _bookingsOverride;
  final QrCheckinService _checkin;

  EventsRemoteDataSource get _events =>
      _eventsOverride ?? di.sl<EventsRemoteDataSource>();
  BookingsRepository get _bookingsRepo =>
      _bookingsOverride ?? di.sl<BookingsRepository>();

  CollectionReference<Map<String, dynamic>> get _bookings =>
      _db.collection('bookings');

  static Future<int> _count(Query<Map<String, dynamic>> q) async {
    final snap = await q.count().get();
    return snap.count ?? 0;
  }

  @override
  Future<int> bookingRequestsToConfirm(String uid) => _count(_bookings
      .where('hostId', isEqualTo: uid)
      .where('status', isEqualTo: BookingStatus.requested.wire));

  @override
  Future<int> paymentsToConfirm(String uid) => _count(_db
      .collection('ticket_orders')
      .where('organizerId', isEqualTo: uid)
      .where('status', isEqualTo: 'awaiting_confirmation'));

  @override
  Future<int> upcomingBookings(String uid, BookingRole role) {
    final cutoff =
        Timestamp.fromDate(BookingRules.upcomingCutoff(DateTime.now()));
    final statuses = role == BookingRole.guest
        ? [BookingStatus.requested.wire, BookingStatus.confirmed.wire]
        : [BookingStatus.confirmed.wire];
    return _count(_bookings
        .where(role == BookingRole.guest ? 'guestId' : 'hostId', isEqualTo: uid)
        .where('status', whereIn: statuses)
        .where('slotStart', isGreaterThanOrEqualTo: cutoff));
  }

  @override
  Future<List<Event>> myEvents(String uid) => _events.getUserEvents(uid);

  CollectionReference<Map<String, dynamic>> _attendees(String eventId) =>
      _db.collection('events').doc(eventId).collection('attendees');

  @override
  Future<EventCheckInStats> eventCheckInStats(String eventId) async {
    final going =
        _attendees(eventId).where('status', isEqualTo: RSVPStatus.going.name);
    final r = await Future.wait(
        [_count(going), _count(going.where('checkedIn', isEqualTo: true))]);
    return EventCheckInStats(going: r[0], checkedIn: r[1]);
  }

  @override
  Future<AttendeesPage> goingAttendees(String eventId,
      {String? startAfterId, int limit = 50}) async {
    Query<Map<String, dynamic>> q = _attendees(eventId)
        .where('status', isEqualTo: RSVPStatus.going.name)
        .orderBy(FieldPath.documentId)
        .limit(limit);
    if (startAfterId != null) q = q.startAfter([startAfterId]);
    final snap = await q.get();
    return AttendeesPage(
      items: [for (final d in snap.docs) EventAttendeeModel.fromFirestore(d)],
      hasMore: snap.docs.length >= limit,
    );
  }

  @override
  Future<CheckInOutcome> setEventCheckIn(
          String eventId, String userId, bool checkedIn) =>
      _checkin.setEventCheckIn(eventId, userId, checkedIn);

  @override
  Future<List<Booking>> hostUpcomingConfirmed(String uid,
      {int limit = 50}) async {
    final cutoff =
        Timestamp.fromDate(BookingRules.upcomingCutoff(DateTime.now()));
    final snap = await _bookings
        .where('hostId', isEqualTo: uid)
        .where('status', isEqualTo: BookingStatus.confirmed.wire)
        .where('slotStart', isGreaterThanOrEqualTo: cutoff)
        .orderBy('slotStart')
        .limit(limit)
        .get();
    return [for (final d in snap.docs) BookingModel.fromDoc(d)];
  }

  @override
  Future<List<Booking>> sessionBookings(
      {required String hostId,
      required String experienceId,
      required DateTime slotStart}) async {
    // (hostId, experienceId, slotStart) composite index; equality only.
    final snap = await _bookings
        .where('hostId', isEqualTo: hostId)
        .where('experienceId', isEqualTo: experienceId)
        .where('slotStart', isEqualTo: Timestamp.fromDate(slotStart))
        .limit(200)
        .get();
    return [
      for (final d in snap.docs) BookingModel.fromDoc(d),
    ].where((b) => CheckInSession.isCheckInStatus(b.status)).toList();
  }

  @override
  Future<Either<Failure, Booking>> manualCheckInBooking(Booking b) =>
      _bookingsRepo.manualCheckIn(b);
}

class EventCheckInStats extends Equatable {
  const EventCheckInStats({required this.going, required this.checkedIn});
  final int going;
  final int checkedIn;

  double get progress =>
      going <= 0 ? 0 : (checkedIn / going).clamp(0.0, 1.0).toDouble();

  @override
  List<Object?> get props => [going, checkedIn];
}

class AttendeesPage {
  const AttendeesPage({required this.items, required this.hasMore});
  final List<EventAttendee> items;
  final bool hasMore;
}
