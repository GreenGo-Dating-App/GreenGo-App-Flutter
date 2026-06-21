import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/external_event.dart';

/// Reads cached third-party experiences from `external_events` (populated by the
/// scheduled `ingestExternalEvents` Cloud Function). Cache-first via Firestore
/// persistence, so it's instant on repeat opens and scales to millions of users
/// (no per-user API calls). Falls back to a small built-in preview while the
/// collection is empty (before live keys/ingestion).
class ExternalEventsDataSource {
  ExternalEventsDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<ExternalEvent>> getExperiences({
    String? country,
    int limit = 60,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('external_events')
          .orderBy('rating', descending: true)
          .limit(limit);
      final snap = await query.get();
      final list = snap.docs.map(ExternalEvent.fromFirestore).toList();
      if (list.isEmpty) return ExternalEvent.samples;
      // Light client-side preference: surface the user's country first.
      if (country != null && country.isNotEmpty) {
        list.sort((a, b) {
          final ac = a.country == country ? 0 : 1;
          final bc = b.country == country ? 0 : 1;
          return ac.compareTo(bc);
        });
      }
      return list;
    } catch (_) {
      return ExternalEvent.samples;
    }
  }
}
