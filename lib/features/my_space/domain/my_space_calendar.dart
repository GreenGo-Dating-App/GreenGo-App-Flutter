import 'package:equatable/equatable.dart';

import '../../events/domain/entities/event.dart';
import '../../experience_bookings/domain/entities/booking.dart';
import 'my_space_models.dart';

/// The filter chips of the My Space calendars.
enum MsCalendarFilter { all, hosting, going }

/// The user's part in a calendar entry.
enum MsCalendarRole { hosting, going }

extension MsCalendarFilterX on MsCalendarFilter {
  bool accepts(MsCalendarRole r) => switch (this) {
        MsCalendarFilter.all => true,
        MsCalendarFilter.hosting => r == MsCalendarRole.hosting,
        MsCalendarFilter.going => r == MsCalendarRole.going,
      };
}

/// One event on the events calendar.
class MsEventEntry extends Equatable {
  const MsEventEntry(this.event, this.role);
  final Event event;
  final MsCalendarRole role;

  String get id => 'ev_${event.id}';
  String? get imageUrl => MySpaceCalendar.eventImage(event);

  @override
  List<Object?> get props => [event, role];
}

/// One entry on the experiences calendar.
///
/// Hosting: a SESSION — every live booking of one experience at one start
/// time (requests included). Going: one of the user's own bookings.
class MsExperienceEntry extends Equatable {
  const MsExperienceEntry({
    required this.role,
    required this.experienceId,
    required this.title,
    required this.start,
    required this.end,
    required this.bookings,
  });

  final MsCalendarRole role;
  final String experienceId;
  final String title;
  final DateTime start;
  final DateTime end;

  /// Never empty.
  final List<Booking> bookings;

  String get id => role == MsCalendarRole.hosting
      ? 'xh_${experienceId}_${start.millisecondsSinceEpoch}'
      : 'xg_${bookings.first.id}';

  /// People expected (party sizes summed).
  int get guests => bookings.fold<int>(0, (n, b) => n + b.guests);

  /// Only requests (nothing accepted yet): drawn outlined.
  bool get onlyRequested =>
      bookings.every((b) => b.status == BookingStatus.requested);

  /// The check-in session of the accepted bookings (host), if any.
  CheckInSession? get checkInSession {
    if (role != MsCalendarRole.hosting) return null;
    final s = CheckInSession.group(bookings);
    return s.isEmpty ? null : s.first;
  }

  @override
  List<Object?> get props => [role, experienceId, title, start, end, bookings];
}

/// Pure rules behind the My Space calendars (no Flutter, unit-tested).
class MySpaceCalendar {
  const MySpaceCalendar._();

  /// Hosting = creator / co-owner; going = a GOING attendee (not owner).
  static MsCalendarRole? eventRole(Event e, String uid) {
    if (e.isOwner(uid)) return MsCalendarRole.hosting;
    final going = e.attendees
        .any((a) => a.userId == uid && a.status == RSVPStatus.going);
    return going ? MsCalendarRole.going : null;
  }

  /// The cover image, else the first gallery photo.
  static String? eventImage(Event e) {
    final cover = e.imageUrl?.trim();
    if (cover != null && cover.isNotEmpty) return cover;
    for (final p in e.photoUrls) {
      if (p.trim().isNotEmpty) return p.trim();
    }
    return null;
  }

  /// Every event of the user (past ones included) matching [filter].
  static List<MsEventEntry> events(
      Iterable<Event> events, String uid, MsCalendarFilter filter) {
    final out = <MsEventEntry>[];
    final seen = <String>{};
    for (final e in events) {
      if (!seen.add(e.id)) continue;
      final r = eventRole(e, uid);
      if (r != null && filter.accepts(r)) out.add(MsEventEntry(e, r));
    }
    out.sort((a, b) => a.event.startDate.compareTo(b.event.startDate));
    return out;
  }

  /// Bookings a host sees on the calendar (no cancelled / declined /
  /// expired).
  static bool hostStatus(BookingStatus s) =>
      s == BookingStatus.requested ||
      s == BookingStatus.confirmed ||
      s == BookingStatus.completed ||
      s == BookingStatus.noShow;

  /// Bookings a guest sees on the calendar.
  static bool guestStatus(BookingStatus s) =>
      s == BookingStatus.requested ||
      s == BookingStatus.confirmed ||
      s == BookingStatus.completed;

  /// Hosted sessions + own bookings matching [filter], soonest first.
  static List<MsExperienceEntry> experiences(
      Iterable<Booking> bookings, String uid, MsCalendarFilter filter) {
    final sessions = <String, List<Booking>>{};
    final out = <MsExperienceEntry>[];
    final seen = <String>{};
    for (final b in bookings) {
      if (!seen.add(b.id)) continue;
      if (b.hostId == uid) {
        if (!filter.accepts(MsCalendarRole.hosting) || !hostStatus(b.status)) {
          continue;
        }
        sessions
            .putIfAbsent(
                '${b.experienceId}_${b.slotStart.millisecondsSinceEpoch}',
                () => <Booking>[])
            .add(b);
      } else if (b.guestId == uid) {
        if (!filter.accepts(MsCalendarRole.going) || !guestStatus(b.status)) {
          continue;
        }
        out.add(MsExperienceEntry(
          role: MsCalendarRole.going,
          experienceId: b.experienceId,
          title: b.experienceTitle ?? '',
          start: b.slotStart,
          end: b.slotEnd,
          bookings: [b],
        ));
      }
    }
    for (final list in sessions.values) {
      out.add(MsExperienceEntry(
        role: MsCalendarRole.hosting,
        experienceId: list.first.experienceId,
        title: list.first.experienceTitle ?? '',
        start: list.first.slotStart,
        end: list.map((b) => b.slotEnd).reduce((a, b) => a.isAfter(b) ? a : b),
        bookings: List.unmodifiable(list),
      ));
    }
    out.sort((a, b) => a.start.compareTo(b.start));
    return out;
  }
}
