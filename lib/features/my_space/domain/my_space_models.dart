import 'package:equatable/equatable.dart';

import '../../events/domain/entities/event.dart';
import '../../experience_bookings/domain/entities/booking.dart';

/// The badges of My Space's "To do" card. Each is a server `count()`.
class MySpaceCounts extends Equatable {
  const MySpaceCounts({
    this.bookingRequestsToConfirm = 0,
    this.paymentsToConfirm = 0,
    this.guestUpcomingBookings = 0,
    this.hostUpcomingBookings = 0,
  });

  static const MySpaceCounts zero = MySpaceCounts();

  /// Host: requests waiting for accept / decline.
  final int bookingRequestsToConfirm;

  /// Organizer: manual ticket payments to confirm.
  final int paymentsToConfirm;

  /// Guest: upcoming requested + confirmed bookings.
  final int guestUpcomingBookings;

  /// Host: upcoming confirmed bookings.
  final int hostUpcomingBookings;

  @override
  List<Object?> get props => [
        bookingRequestsToConfirm,
        paymentsToConfirm,
        guestUpcomingBookings,
        hostUpcomingBookings,
      ];
}

/// One experience SESSION: the bookings of one experience at one start time
/// (private time slots: usually one booking; a group slot can hold several).
class CheckInSession extends Equatable {
  const CheckInSession({
    required this.experienceId,
    required this.title,
    required this.start,
    required this.end,
    required this.bookings,
  });

  final String experienceId;
  final String title;
  final DateTime start;
  final DateTime end;
  final List<Booking> bookings;

  String get id => '${experienceId}_${start.millisecondsSinceEpoch}';

  /// People expected (party sizes summed).
  int get guests => bookings.fold<int>(0, (n, b) => n + b.guests);

  /// Bookings checked in.
  int get checkedIn => bookings.where((b) => b.isCheckedIn).length;

  double get progress => bookings.isEmpty
      ? 0
      : (checkedIn / bookings.length).clamp(0.0, 1.0).toDouble();

  /// Statuses a session checklist lists (no requests / cancellations).
  static bool isCheckInStatus(BookingStatus s) =>
      s == BookingStatus.confirmed ||
      s == BookingStatus.completed ||
      s == BookingStatus.noShow;

  /// Groups [bookings] (any order) into sessions, soonest first.
  static List<CheckInSession> group(Iterable<Booking> bookings) {
    final by = <String, List<Booking>>{};
    for (final b in bookings) {
      if (!isCheckInStatus(b.status)) continue;
      by
          .putIfAbsent(
              '${b.experienceId}_${b.slotStart.millisecondsSinceEpoch}',
              () => <Booking>[])
          .add(b);
    }
    final out = [
      for (final list in by.values)
        CheckInSession(
          experienceId: list.first.experienceId,
          title: list.first.experienceTitle ?? '',
          start: list.first.slotStart,
          end:
              list.map((b) => b.slotEnd).reduce((a, b) => a.isAfter(b) ? a : b),
          bookings: List.unmodifiable(list),
        ),
    ]..sort((a, b) => a.start.compareTo(b.start));
    return out;
  }

  @override
  List<Object?> get props => [experienceId, title, start, end, bookings];
}

/// "Today" rules of the hub — which events / sessions need the door now.
class MySpaceRules {
  const MySpaceRules._();

  /// The server's event door window (functions/src/checkin/eventCheckin.ts).
  static const Duration eventEarly = Duration(hours: 3);
  static const Duration eventLate = Duration(hours: 12);

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Starts today, or its check-in window is open now.
  static bool isCheckInDay(DateTime start, DateTime end, DateTime now) {
    final local = now.toLocal();
    if (_sameDay(start.toLocal(), local)) return true;
    final last = end.isBefore(start) ? start : end;
    return !now.isBefore(start.subtract(eventEarly)) &&
        !now.isAfter(last.add(eventLate));
  }

  /// Hosted (creator or co-owner) and not over yet (door still open),
  /// soonest first.
  static List<Event> hosting(List<Event> events, String uid, DateTime now) =>
      events
          .where(
              (e) => e.isOwner(uid) && !now.isAfter(e.endDate.add(eventLate)))
          .toList()
        ..sort((a, b) => a.startDate.compareTo(b.startDate));

  /// Going to (not hosting) and not ended, soonest first.
  static List<Event> attending(List<Event> events, String uid, DateTime now) =>
      events
          .where((e) =>
              !e.isOwner(uid) &&
              !now.isAfter(e.endDate) &&
              e.attendees
                  .any((a) => a.userId == uid && a.status == RSVPStatus.going))
          .toList()
        ..sort((a, b) => a.startDate.compareTo(b.startDate));
}
