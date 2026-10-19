import 'package:cloud_firestore/cloud_firestore.dart';

/// Lightweight view model for an event shown on a business storefront (avoids
/// importing the events feature's model / entity into the business layer).
class StorefrontEvent {
  const StorefrontEvent({
    required this.id,
    required this.title,
    required this.status,
    this.imageUrl,
    this.startDate,
    this.endDate,
    this.hidden = false,
    this.isPrivate = false,
  });

  final String id;
  final String title;
  final String status;
  final String? imageUrl;
  final DateTime? startDate;
  final DateTime? endDate;

  /// Hidden by a plan downgrade (a draft to everyone but the organizer).
  final bool hidden;
  final bool isPrivate;

  factory StorefrontEvent.fromDoc(String id, Map<String, dynamic> d) {
    DateTime? ts(dynamic v) => v is Timestamp ? v.toDate() : null;
    final image = d['imageUrl'];
    return StorefrontEvent(
      id: id,
      title: (d['title'] as String?) ?? '',
      status: (d['status'] as String?) ?? 'draft',
      imageUrl: image is String && image.isNotEmpty ? image : null,
      startDate: ts(d['startDate']),
      endDate: ts(d['endDate']),
      hidden: d['hiddenByDowngrade'] == true,
      isPrivate: d['visibility'] == 'private',
    );
  }

  /// Shown publicly as "upcoming": published (not draft / cancelled /
  /// completed), not hidden by a downgrade, not private, and not over yet
  /// (future or ongoing).
  bool isUpcomingAt(DateTime now) =>
      status == 'published' &&
      !hidden &&
      !isPrivate &&
      (endDate ?? startDate)?.isAfter(now) != false;
}

/// Soonest first (by start date); undated events last.
int compareByStart(StorefrontEvent a, StorefrontEvent b) {
  final sa = a.startDate, sb = b.startDate;
  if (sa == null && sb == null) return 0;
  if (sa == null) return 1;
  if (sb == null) return -1;
  return sa.compareTo(sb);
}

/// One page of a business's upcoming events. [cursor] is the last RAW doc
/// read (client filtering may drop some), null when there is nothing more.
class UpcomingEventsPage {
  const UpcomingEventsPage(this.events, this.cursor);
  final List<StorefrontEvent> events;
  final DocumentSnapshot<Map<String, dynamic>>? cursor;
  bool get hasMore => cursor != null;
}

/// Reads a business's upcoming events, soonest first, in bounded pages.
///
/// Uses only EXISTING composite indexes (firestore.indexes.json):
///   * events(organizerId ASC, startDate ASC) — the paged list itself:
///     `organizerId == uid && startDate >= startOfToday orderBy startDate`.
///   * events(organizerId ASC, endDate ASC) — first page only: events that
///     started BEFORE today and are still running (multi-day). They all sort
///     before the paged ones (their start is earlier), so prepending them keeps
///     the global order exact. Bounded to [pageSize].
class BusinessUpcomingEventsRepository {
  BusinessUpcomingEventsRepository({FirebaseFirestore? firestore, this.clock})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Injectable "now" for tests.
  final DateTime Function()? clock;

  static const int pageSize = 20;

  DateTime _now() => (clock ?? DateTime.now)();

  Query<Map<String, dynamic>> _byOrganizer(String businessId) => _db
      .collection('events')
      .where('organizerId', isEqualTo: businessId);

  /// Page [cursor] (null = first page) of [businessId]'s upcoming events.
  Future<UpcomingEventsPage> page(
    String businessId, {
    DocumentSnapshot<Map<String, dynamic>>? cursor,
    int limit = pageSize,
  }) async {
    final now = _now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    var q = _byOrganizer(businessId)
        .where('startDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
        .orderBy('startDate');
    if (cursor != null) q = q.startAfterDocument(cursor);
    final snap = await q.limit(limit).get();

    final ongoing = <StorefrontEvent>[];
    if (cursor == null) {
      try {
        final o = await _byOrganizer(businessId)
            .where('endDate', isGreaterThan: Timestamp.fromDate(now))
            .orderBy('endDate')
            .limit(limit)
            .get();
        for (final d in o.docs) {
          final e = StorefrontEvent.fromDoc(d.id, d.data());
          if (e.startDate != null && e.startDate!.isBefore(startOfToday)) {
            ongoing.add(e);
          }
        }
      } catch (_) {
        // Best-effort: the future events still list.
      }
    }

    final events = [
      ...ongoing,
      ...snap.docs.map((d) => StorefrontEvent.fromDoc(d.id, d.data())),
    ].where((e) => e.isUpcomingAt(now)).toList()
      ..sort(compareByStart);
    final more = snap.docs.length >= limit ? snap.docs.last : null;
    return UpcomingEventsPage(events, more);
  }

  /// The storefront preview: the first [limit] upcoming events, soonest first.
  Future<List<StorefrontEvent>> preview(String businessId,
      {int limit = 5}) async {
    try {
      final p = await page(businessId, limit: 10);
      return p.events.take(limit).toList();
    } catch (_) {
      // Index not ready / transient: the bounded unordered read, filtered and
      // sorted client side.
      final now = _now();
      final snap = await _byOrganizer(businessId).limit(20).get();
      return (snap.docs
              .map((d) => StorefrontEvent.fromDoc(d.id, d.data()))
              .where((e) => e.isUpcomingAt(now))
              .toList()
            ..sort(compareByStart))
          .take(limit)
          .toList();
    }
  }
}
