import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/cache/last_result_cache.dart';
import '../data/models/booking_model.dart';
import '../domain/entities/booking.dart';

/// "Paint what was shown last time, then refresh" for the bookings lists, on
/// top of [LastResultCache] (ids saved after a server load; documents read
/// back by id from the LOCAL Firestore cache only). Never throws.
class BookingsFirstPageCache {
  const BookingsFirstPageCache();

  /// Per role + time bucket (+ experience for a host's per-listing list).
  static String keyFor(BookingsQuery q) =>
      'bookings_${q.role.name}_${q.upcoming ? 'up' : 'past'}'
      '_${q.experienceId ?? ''}';

  Future<List<Booking>> load(BookingsQuery q) async {
    try {
      final key = keyFor(q);
      final ids = await LastResultCache.loadIds(key);
      if (ids.isEmpty) return const [];
      final docs = await LastResultCache.loadDocs(
          key, FirebaseFirestore.instance.collection('bookings'));
      return docs.map(BookingModel.fromDoc).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> save(BookingsQuery q, List<Booking> page) async {
    try {
      await LastResultCache.saveIds(keyFor(q), page.map((b) => b.id));
    } catch (_) {/* best-effort */}
  }
}
