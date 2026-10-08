import '../../../../core/services/qr_checkin_service.dart';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../user_experiences/domain/entities/user_experience.dart';
import '../../../user_experiences/domain/repositories/user_experiences_repository.dart';
import '../../domain/booking_failure.dart';
import '../../domain/booking_rules.dart';
import '../../domain/entities/booking.dart';
import '../models/booking_model.dart';

/// Firestore + callables for experience bookings.
///
/// Every read is bounded: booking lists are pages of 20 on an indexed
/// (guestId | hostId [, experienceId], slotStart) query, slots at most 30 per
/// read, single documents by id.
class BookingsRemoteDataSource {
  BookingsRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _dbOverride = firestore,
        _functionsOverride = functions;

  final FirebaseFirestore? _dbOverride;
  final FirebaseFunctions? _functionsOverride;
  FirebaseFirestore get _db => _dbOverride ?? FirebaseFirestore.instance;
  FirebaseFunctions get _functions =>
      _functionsOverride ?? FirebaseFunctions.instance;

  CollectionReference<Map<String, dynamic>> get _bookings =>
      _db.collection('bookings');

  CollectionReference<Map<String, dynamic>> _slots(String experienceId) =>
      _db.collection('user_experiences').doc(experienceId).collection('slots');

  /// Maps a callable error to [BookingFailure] (see the class doc for
  /// [BookingFailure.definitive]).
  static BookingFailure failureFrom(Object e) {
    if (e is BookingFailure) return e;
    if (e is FirebaseFunctionsException) {
      final details = bookingMap(e.details);
      final reason = details?['code'] as String?;
      if (reason != null && reason != BookingFailure.internal) {
        // The server decided: nothing was written.
        return BookingFailure(
          reason,
          seatsLeft: (details?['seatsLeft'] as num?)?.toInt(),
          max: (details?['max'] as num?)?.toInt(),
          existingBookingId: details?['bookingId'] as String?,
        );
      }
      if (reason == BookingFailure.internal || e.code == 'internal') {
        return const BookingFailure(BookingFailure.internal, definitive: false);
      }
      const transport = {
        'unavailable',
        'deadline-exceeded',
        'unknown',
        'cancelled',
      };
      if (transport.contains(e.code)) {
        return const BookingFailure(BookingFailure.network, definitive: false);
      }
      // A refusal without our details (e.g. unauthenticated).
      return BookingFailure(e.code);
    }
    if (e is TimeoutException) {
      return const BookingFailure(BookingFailure.network, definitive: false);
    }
    if (e is FirebaseException) {
      return BookingFailure(e.code,
          definitive: e.code != 'unavailable' && e.code != 'deadline-exceeded');
    }
    return const BookingFailure(BookingFailure.network, definitive: false);
  }

  Future<Object?> _call(String name, Map<String, dynamic> payload) async {
    try {
      final res = await _functions
          .httpsCallable(name,
              options: HttpsCallableOptions(timeout: const Duration(seconds: 60)))
          .call<Object?>(payload);
      return res.data;
    } catch (e) {
      throw failureFrom(e);
    }
  }

  // ───────────────────────────────────────────────────────────── slots

  Future<List<ExperienceSlot>> slots(
    String experienceId, {
    DateTime? from,
    int limit = 30,
    bool includeCancelled = false,
  }) async {
    final snap = await _slots(experienceId)
        .where('start', isGreaterThanOrEqualTo: Timestamp.fromDate(from ?? DateTime.now()))
        .orderBy('start')
        .limit(limit)
        .get();
    return [
      for (final d in snap.docs)
        BookingModel.slotFromMap(experienceId, d.id, d.data()),
    ].where((s) => includeCancelled || s.isOpen).toList();
  }

  Future<ExperienceSlot> saveSlot(
    String experienceId,
    SlotDraft draft, {
    ExperienceSlot? existing,
  }) async {
    if (existing == null) {
      final ref = _slots(experienceId).doc();
      await ref.set(BookingModel.slotPayload(draft));
      return ExperienceSlot(
        id: ref.id,
        experienceId: experienceId,
        start: draft.start,
        end: draft.end,
        capacity: draft.capacity,
      );
    }
    final ref = _slots(experienceId).doc(existing.id);
    // Booked slots: times are frozen (rules) — only the capacity changes.
    await ref.update(existing.hasBookings
        ? {
            'capacity': draft.capacity,
            'updatedAt': FieldValue.serverTimestamp(),
          }
        : BookingModel.slotPayload(draft, existing: existing));
    final fresh = await ref.get();
    return BookingModel.slotFromMap(
        experienceId, ref.id, fresh.data() ?? const {});
  }

  /// "Repeat": creates many open slots. Starts already taken by an open slot
  /// in the same span are skipped (one bounded range read, so dates beyond
  /// the host's loaded list are also de-duplicated). Written in batches of
  /// [_slotBatch] — each create rule get()s the experience, and a batched
  /// write may make at most 20 document reads in rules.
  Future<List<ExperienceSlot>> createSlots(
    String experienceId,
    List<SlotDraft> drafts,
  ) async {
    if (drafts.isEmpty) return const [];
    final sorted = [...drafts]..sort((a, b) => a.start.compareTo(b.start));
    final existing = await _slots(experienceId)
        .where('start',
            isGreaterThanOrEqualTo: Timestamp.fromDate(sorted.first.start))
        .where('start',
            isLessThanOrEqualTo: Timestamp.fromDate(sorted.last.start))
        .orderBy('start')
        .limit(500)
        .get();
    final taken = {
      for (final d in existing.docs)
        if (d.data()['status'] != 'cancelled' && d.data()['start'] is Timestamp)
          (d.data()['start'] as Timestamp).millisecondsSinceEpoch,
    };
    final fresh = [
      for (final d in sorted)
        if (!taken.contains(d.start.millisecondsSinceEpoch)) d,
    ];

    final created = <ExperienceSlot>[];
    for (var i = 0; i < fresh.length; i += _slotBatch) {
      final chunk = fresh.skip(i).take(_slotBatch).toList();
      final batch = _db.batch();
      final refs = <DocumentReference<Map<String, dynamic>>>[];
      for (final d in chunk) {
        final ref = _slots(experienceId).doc();
        refs.add(ref);
        batch.set(ref, BookingModel.slotPayload(d));
      }
      await batch.commit();
      for (var j = 0; j < chunk.length; j++) {
        created.add(ExperienceSlot(
          id: refs[j].id,
          experienceId: experienceId,
          start: chunk[j].start,
          end: chunk[j].end,
          capacity: chunk[j].capacity,
        ));
      }
    }
    return created;
  }

  static const int _slotBatch = 10;

  Future<void> deleteSlot(String experienceId, String slotId) =>
      _slots(experienceId).doc(slotId).delete();

  Future<SlotCancelResult> cancelSlot(String experienceId, String slotId,
      {String? reason}) async {
    var total = 0;
    var more = true;
    // The callable cancels up to 400 bookings per call; re-call (bounded).
    for (var i = 0; i < 5 && more; i++) {
      final res = bookingMap(await _call('cancelExperienceSlot', {
        'experienceId': experienceId,
        'slotId': slotId,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      }));
      total += (res?['cancelledBookings'] as num?)?.toInt() ?? 0;
      more = res?['more'] == true;
    }
    return SlotCancelResult(cancelledBookings: total, more: more);
  }

  // ───────────────────────────────────────────────────────────── bookings

  /// The start times of a window, free / taken (server-computed: the host's
  /// bookings on ALL their experiences count; identities never returned).
  Future<SlotAvailability> slotAvailability(
      String experienceId, String slotId) async {
    final m = bookingMap(await _call('getSlotAvailability',
            {'experienceId': experienceId, 'slotId': slotId})) ??
        const {};
    final raw = m['starts'];
    final times = <SlotTime>[];
    if (raw is List) {
      for (final x in raw) {
        if (x is! Map) continue;
        final st = DateTime.tryParse('${x['start']}');
        final en = DateTime.tryParse('${x['end']}');
        if (st == null || en == null) continue;
        times.add(SlotTime(start: st, end: en, free: x['free'] == true));
      }
    }
    return SlotAvailability(
      slotId: slotId,
      lengthMinutes: (m['lengthMinutes'] as num?)?.toInt() ?? 0,
      times: times,
    );
  }

  Future<Booking> createBooking({
    required UserExperience experience,
    required String slotId,
    required int guests,
    required String requestId,
    PaymentMethod? method,
    required int consentVersion,
    DateTime? startAt,
  }) async {
    final data = await _call('createBooking', {
      'experienceId': experience.id,
      'slotId': slotId,
      if (startAt != null) 'startAt': startAt.toUtc().toIso8601String(),
      'guests': guests,
      'requestId': requestId,
      if (method != null) 'paymentMethod': method.name,
      'consentVersion': consentVersion,
    });
    final b = BookingModel.fromView(data, title: experience.title);
    return b.copyWith(createdAt: DateTime.now());
  }

  Query<Map<String, dynamic>> _query(BookingsQuery q) {
    Query<Map<String, dynamic>> query = _bookings.where(
        q.role == BookingRole.guest ? 'guestId' : 'hostId',
        isEqualTo: q.uid);
    if (q.role == BookingRole.host && q.experienceId != null) {
      query = query.where('experienceId', isEqualTo: q.experienceId);
    }
    final cutoff =
        Timestamp.fromDate(BookingRules.upcomingCutoff(DateTime.now()));
    return q.upcoming
        ? query
            .where('slotStart', isGreaterThanOrEqualTo: cutoff)
            .orderBy('slotStart')
        : query
            .where('slotStart', isLessThan: cutoff)
            .orderBy('slotStart', descending: true);
  }

  Future<ExperiencePage<Booking>> bookings(
    BookingsQuery q, {
    Object? cursor,
    int limit = 20,
  }) async {
    var query = _query(q).limit(limit);
    if (cursor is DocumentSnapshot) query = query.startAfterDocument(cursor);
    final snap = await query.get();
    return ExperiencePage(
      items: [for (final d in snap.docs) BookingModel.fromDoc(d)],
      hasMore: snap.docs.length >= limit,
      cursor: snap.docs.isEmpty ? cursor : snap.docs.last,
    );
  }

  Future<Booking?> getBooking(String id) async {
    try {
      final d = await _bookings.doc(id).get();
      if (!d.exists) return null;
      return BookingModel.fromDoc(d);
    } on FirebaseException catch (e) {
      // Not a party to it (or it does not exist: the rule reads resource).
      if (e.code == 'permission-denied') return null;
      rethrow;
    }
  }

  Future<Booking> _action(String name, Booking b,
          [Map<String, dynamic> extra = const {}]) async =>
      BookingModel.fromView(
        await _call(name, {'bookingId': b.id, ...extra}),
        previous: b,
      );

  Future<Booking> respond(Booking b, {required bool accept}) =>
      _action('respondToBookingRequest', b, {'accept': accept});

  Future<Booking> cancel(Booking b, {String? reason}) =>
      _action('cancelBooking', b, {
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      });

  /// The guest's check-in code. Cached on the device after the first fetch,
  /// so it still shows at a meeting point without signal.
  Future<BookingCheckInCode> checkInCode(String bookingId) async {
    final cache = QrCheckinService();
    try {
      final m = bookingMap(await _call(
              'getBookingCheckInCode', {'bookingId': bookingId})) ??
          const {};
      final code = BookingCheckInCode(
        bookingId: m['bookingId'] as String? ?? bookingId,
        code: m['code'] as String? ?? '',
        qrPayload: m['qrPayload'] as String? ?? '',
      );
      await cache.cacheBookingPayload(bookingId, code.qrPayload);
      return code;
    } on BookingFailure catch (f) {
      if (f.definitive) rethrow;
      final cached = ScannedCheckInCode.parse(
          await cache.cachedBookingPayload(bookingId));
      if (cached is BookingTicketCode && cached.bookingId == bookingId) {
        return BookingCheckInCode(
            bookingId: bookingId, code: cached.code, qrPayload: cached.raw);
      }
      rethrow;
    }
  }

  Future<Booking> checkIn(Booking b,
          {required String code, bool cashReceived = false}) =>
      _action('checkInBooking', b, {
        'code': code.trim().toUpperCase(),
        if (cashReceived) 'cashReceived': true,
      });

  Future<Booking> markNoShow(Booking b) => _action('markBookingNoShow', b);

  Future<Booking> markPaid(Booking b) => _action('markBookingPaid', b);

  Future<Booking> confirmCashReceived(Booking b) =>
      _action('confirmCashReceived', b);

  Future<Booking> openDispute(Booking b, {required String reason}) =>
      _action('openBookingDispute', b, {'reason': reason.trim()});

  // ───────────────────────────────────────────────────────────── guest reviews

  Future<GuestReview?> guestReviewFor(String bookingId) async {
    try {
      final d = await _db.collection('guest_reviews').doc(bookingId).get();
      if (!d.exists) return null;
      return BookingModel.guestReviewFromMap(d.id, d.data()!);
    } on FirebaseException catch (e) {
      // The read rule looks at the stored doc: a missing doc is a denial.
      if (e.code == 'permission-denied') return null;
      rethrow;
    }
  }

  Future<void> submitGuestReview(Booking b,
          {required int rating, required String comment}) =>
      _db.collection('guest_reviews').doc(b.id).set({
        'hostId': b.hostId,
        'guestId': b.guestId,
        'experienceId': b.experienceId,
        'rating': rating,
        'comment': comment.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
}
