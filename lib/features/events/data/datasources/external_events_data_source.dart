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

  /// One page of experiences for infinite scroll, ordered by rating.
  /// Returns the items plus the last document (cursor) for the next page.
  /// On the very first page, if the collection is empty, returns the built-in
  /// samples with a null cursor (so the tab is never blank before ingestion).
  Future<({List<ExternalEvent> items, DocumentSnapshot<Map<String, dynamic>>? cursor})>
      getExperiencesPage({
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 20,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('external_events')
          .orderBy('rating', descending: true)
          .limit(limit);
      if (startAfter != null) query = query.startAfterDocument(startAfter);
      final snap = await query.get();
      final items = snap.docs.map(ExternalEvent.fromFirestore).toList();
      if (items.isEmpty && startAfter == null) {
        return (items: ExternalEvent.samples, cursor: null);
      }
      return (
        items: items,
        cursor: snap.docs.isNotEmpty ? snap.docs.last : null,
      );
    } catch (_) {
      if (startAfter == null) return (items: ExternalEvent.samples, cursor: null);
      return (items: <ExternalEvent>[], cursor: null);
    }
  }

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
