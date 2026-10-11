import 'package:flutter/foundation.dart';

import '../../events/domain/entities/event.dart';
import '../../experience_bookings/domain/entities/booking.dart';
import '../domain/my_space_models.dart';
import 'my_space_repository.dart';

/// Number shown on the My Space entry icon (Explore header): the to-dos that
/// need the user's action — the same items as the hub's "To do" card:
/// booking requests to confirm + manual payments to confirm + today's hosted
/// events / experience sessions to check guests in.
///
/// Cheap by design: two `count()` aggregates plus the user's own events and up
/// to 50 upcoming confirmed bookings, cached for [_ttl] per user so moving
/// around the app doesn't re-query.
class MySpaceBadge {
  MySpaceBadge._();

  static final ValueNotifier<int> count = ValueNotifier<int>(0);

  static const Duration _ttl = Duration(minutes: 2);
  static String? _uid;
  static DateTime? _at;
  static Future<void>? _inFlight;

  /// Recomputes the count for [uid] unless a fresh value is cached
  /// ([force] skips the cache, e.g. after returning from My Space).
  static Future<void> refresh(
    String uid, {
    bool force = false,
    MySpaceRepository? repository,
    DateTime Function() now = DateTime.now,
  }) {
    if (uid != _uid) {
      // Another account: never show the previous user's number.
      _uid = uid;
      _at = null;
      count.value = 0;
    }
    final t = now();
    if (!force && _at != null && t.difference(_at!) < _ttl) {
      return Future<void>.value();
    }
    if (_inFlight != null && !force) return _inFlight!;
    final f = _compute(uid, repository ?? FirestoreMySpaceRepository(), t);
    _inFlight = f;
    return f.whenComplete(() {
      if (identical(_inFlight, f)) _inFlight = null;
    });
  }

  static Future<void> _compute(
      String uid, MySpaceRepository repo, DateTime t) async {
    try {
      final r = await Future.wait<Object>([
        repo.bookingRequestsToConfirm(uid),
        repo.paymentsToConfirm(uid),
        repo.myEvents(uid),
        repo.hostUpcomingConfirmed(uid),
      ]);
      if (uid != _uid) return; // signed out / switched account meanwhile
      final events = MySpaceRules.hosting(r[2] as List<Event>, uid, t);
      final todayEvents = events
          .where((e) => MySpaceRules.isCheckInDay(e.startDate, e.endDate, t))
          .length;
      final sessions = <String>{
        for (final b in (r[3] as List<Booking>))
          if (MySpaceRules.isCheckInDay(b.slotStart, b.slotEnd, t))
            '${b.experienceId}_${b.slotStart.millisecondsSinceEpoch}',
      };
      count.value =
          (r[0] as int) + (r[1] as int) + todayEvents + sessions.length;
      _at = t;
    } catch (e) {
      // Keep the last good number; the hub itself shows the details.
      debugPrint('[MySpaceBadge] refresh failed: $e');
    }
  }

  /// Clears the number (sign-out).
  static void reset() {
    _uid = null;
    _at = null;
    _inFlight = null;
    count.value = 0;
  }
}
