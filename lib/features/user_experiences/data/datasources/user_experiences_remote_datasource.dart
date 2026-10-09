import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/utils/display_image.dart';
import '../../../../core/utils/geo_query.dart';
import '../../../events/data/datasources/geo_ring_scanner.dart';
import '../../domain/entities/experience_review.dart';
import '../../domain/entities/user_experience.dart';
import '../../domain/repositories/user_experiences_repository.dart';
import '../models/user_experience_model.dart';

/// Thrown by [UserExperiencesRemoteDataSource.create] for the server's
/// structured refusals (limit / prohibited text / invalid payload).
class ExperienceCreateException implements Exception {
  const ExperienceCreateException(this.code, {this.limit, this.count, this.fields = const []});

  /// experience_limit | prohibited_text | contact_info | invalid_experience |
  /// one of [safetyCodes].
  final String code;

  /// Phase 1 safety refusals (functions/src/user_experiences/safety.ts).
  static const Set<String> safetyCodes = {
    'id_document_required',
    'id_document_not_approved',
    'host_agreement_required',
    'new_host_paid_limit',
    'dates_required',
    'host_banned',
    'hidden',
    'agreement_outdated',
    // Paid listings need an active business account.
    'business_required',
  };
  final int? limit;
  final int? count;
  final List<String> fields;

  @override
  String toString() => 'ExperienceCreateException($code)';
}

/// Firestore + callable access for `user_experiences` and its subcollections.
///
/// Every read is bounded: pages of ≤ 20 experiences / ≤ 10 reviews or replies,
/// nearest-first scans through [GeoRingScanner] (limited per geohash range),
/// and the host's count is an aggregate count() (1 read per 1000 docs).
class UserExperiencesRemoteDataSource {
  UserExperiencesRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _functionsOverride = functions;

  final FirebaseFirestore _db;
  final FirebaseFunctions? _functionsOverride;
  FirebaseFunctions get _functions =>
      _functionsOverride ?? FirebaseFunctions.instance;

  static const String collection = 'user_experiences';

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(collection);

  CollectionReference<Map<String, dynamic>> _reviews(String experienceId) =>
      _col.doc(experienceId).collection('reviews');

  CollectionReference<Map<String, dynamic>> _replies(
          String experienceId, String reviewId) =>
      _reviews(experienceId).doc(reviewId).collection('replies');

  // ───────────────────────────────────────────────────────────── experiences

  ExperienceFeedPager communityFeed({
    double? lat,
    double? lng,
    ExperienceCategory? category,
    String query = '',
    int pageSize = 20,
  }) {
    final published = _col.where('status', isEqualTo: 'published');
    // Public feed: pictures only (the host's own list, [hostFeed], keeps all).
    UserExperience? parsePublic(QueryDocumentSnapshot<Map<String, dynamic>> d) {
      final e = UserExperienceModel.fromDoc(d);
      return experienceHasPicture(e) ? e : null;
    }

    final tokens = query
        .toLowerCase()
        .split(RegExp(r'[\s!-/:-@\[-`{-~]+'))
        .where((t) => t.length >= 2)
        .toList();

    if (tokens.isNotEmpty) {
      // Server matches the first token; the rest (and the category) narrow
      // the downloaded page client-side.
      return _QueryPager(
        published
            .where('searchKeywords', arrayContains: tokens.first)
            .orderBy('createdAt', descending: true),
        pageSize,
        keep: (e) =>
            experienceHasPicture(e) &&
            tokens.skip(1).every(e.searchKeywords.contains) &&
            (category == null || e.category == category),
      );
    }
    if (category != null) {
      final byCategory = published.where('category', isEqualTo: category.name);
      final newestInCategory = _QueryPager(
        byCategory.orderBy('createdAt', descending: true),
        pageSize,
        keep: experienceHasPicture,
      );
      if (lat == null || lng == null) return newestInCategory;
      // Nearest-first within the category too (index user_experiences(status,
      // category, geohash)); while that index is missing the scan fails over
      // to the newest-first category list, exactly as before.
      return _NearbyThenNewestPager(
        scanner: GeoRingScanner<UserExperience>(
          base: byCategory,
          lat: lat,
          lng: lng,
          startRadiusM: 50000,
          perQueryLimit: pageSize,
          maxRoundsPerCall: 4,
          parse: parsePublic,
          position: (e) =>
              e.hasCoordinates ? (lat: e.lat!, lng: e.lng!) : null,
        ),
        fallback: newestInCategory,
        pageSize: pageSize,
      );
    }
    final newest = _QueryPager(
        published.orderBy('createdAt', descending: true), pageSize,
        keep: experienceHasPicture);
    if (lat == null || lng == null) return newest;
    return _NearbyThenNewestPager(
      scanner: GeoRingScanner<UserExperience>(
        base: published,
        lat: lat,
        lng: lng,
        startRadiusM: 50000,
        perQueryLimit: pageSize,
        maxRoundsPerCall: 4,
        parse: parsePublic,
        position: (e) => e.hasCoordinates ? (lat: e.lat!, lng: e.lng!) : null,
      ),
      fallback: newest,
      pageSize: pageSize,
    );
  }

  ExperienceFeedPager hostFeed(String hostId, {int pageSize = 20}) =>
      _QueryPager(
        _col
            .where('hostId', isEqualTo: hostId)
            .orderBy('createdAt', descending: true),
        pageSize,
      );

  /// Published experiences posted in [communityId], newest first, pictures
  /// only, [pageSize] per page. Needs the composite index
  /// user_experiences(communityId ASC, status ASC, createdAt DESC); while it
  /// builds the query fails with failed-precondition and the pager returns
  /// an empty list (logged) instead of an error.
  ExperienceFeedPager communityExperiences(String communityId,
          {int pageSize = 20}) =>
      FailSafeExperiencePager(
        _QueryPager(
          _col
              .where('communityId', isEqualTo: communityId)
              .where('status', isEqualTo: 'published')
              .orderBy('createdAt', descending: true),
          pageSize,
          keep: experienceHasPicture,
        ),
        label: 'communityExperiences($communityId)',
      );

  /// The host's own NOT-published listings (drafts / hidden) in
  /// [communityId], newest first — visible only to the host (the rules let a
  /// host read their own docs). Two equality filters, no orderBy: served by
  /// the automatic single-field indexes (no composite needed); bounded by
  /// [limit] (a host has at most their tier's experience count anyway).
  Future<List<UserExperience>> hostCommunityDrafts(
    String communityId,
    String hostId, {
    int limit = 20,
  }) async {
    try {
      final snap = await _col
          .where('communityId', isEqualTo: communityId)
          .where('hostId', isEqualTo: hostId)
          .limit(limit)
          .get();
      final out = [
        for (final d in snap.docs) UserExperienceModel.fromDoc(d),
      ].where((e) => !e.isPublished).toList()
        ..sort((a, b) => (b.createdAt ?? DateTime(0))
            .compareTo(a.createdAt ?? DateTime(0)));
      return out;
    } on FirebaseException catch (e) {
      debugPrint('hostCommunityDrafts($communityId) failed: ${e.code}');
      return const [];
    }
  }

  /// null when the experience doesn't exist OR the viewer may not read it
  /// (someone else's draft / a moderation-hidden listing).
  Future<UserExperience?> get(String id) async {
    try {
      final doc = await _col.doc(id).get();
      if (!doc.exists) return null;
      return UserExperienceModel.fromDoc(doc);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') return null;
      rethrow;
    }
  }

  Future<int> countByHost(String hostId) async {
    final agg = await _col.where('hostId', isEqualTo: hostId).count().get();
    return agg.count ?? 0;
  }

  /// Calls [name]; maps the server's structured refusals to
  /// [ExperienceCreateException].
  Future<Object?> _call(String name, Map<String, dynamic> payload) async {
    try {
      final res = await _functions.httpsCallable(name).call<Object?>(payload);
      return res.data;
    } on FirebaseFunctionsException catch (e) {
      final details = e.details;
      final code = details is Map ? details['code'] as String? : null;
      if (e.code == 'resource-exhausted' || code == 'experience_limit') {
        throw ExperienceCreateException(
          'experience_limit',
          limit: details is Map ? (details['limit'] as num?)?.toInt() : null,
          count: details is Map ? (details['count'] as num?)?.toInt() : null,
        );
      }
      if (code == 'community_not_allowed' ||
          code == 'community_not_found' ||
          code == 'invalid_community') {
        throw ExperienceCreateException(code!);
      }
      if (code == 'prohibited_text' || code == 'contact_info') {
        throw ExperienceCreateException(code!);
      }
      if (code == 'invalid_experience') {
        throw ExperienceCreateException(
          'invalid_experience',
          fields: details is Map && details['fields'] is List
              ? (details['fields'] as List).whereType<String>().toList()
              : const [],
        );
      }
      if (code != null && ExperienceCreateException.safetyCodes.contains(code)) {
        throw ExperienceCreateException(code);
      }
      rethrow;
    }
  }

  Future<String> create(UserExperience draft) async {
    final data = await _call(
        'createUserExperience', UserExperienceModel.createPayload(draft));
    final id = data is Map ? data['id'] as String? : null;
    if (id == null || id.isEmpty) {
      throw const ExperienceCreateException('invalid_response');
    }
    return id;
  }

  /// Saves the host's edits. Every PUBLISH goes through [publish] (the rules
  /// only let a client write status 'published' on an already-published
  /// listing). Returns true when the caller must still call [publish]:
  ///  - [publish] false: saved with the status of [e] (draft = unpublish);
  ///  - [publish] true and [wasPublished]: saved in place when the rules
  ///    allow it (returns false); when they do not (e.g. a free listing made
  ///    paid), it is saved as a draft and must be re-published (true);
  ///  - [publish] true on a draft: saved as a draft (true).
  Future<bool> update(
    UserExperience e, {
    bool publish = false,
    bool wasPublished = false,
  }) async {
    final payload = <String, dynamic>{
      ...UserExperienceModel.editablePayload(e),
      'hostName': e.hostName,
      'hostPhotoUrl': e.hostPhotoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final ref = _col.doc(e.id);
    // A moderation-hidden listing keeps its status (rules enforce it).
    if (e.isHidden) {
      await ref.update(payload);
      return false;
    }
    if (!publish) {
      await ref.update({...payload, 'status': e.status.name});
      return false;
    }
    if (wasPublished) {
      try {
        await ref.update(payload);
        return false;
      } on FirebaseException catch (x) {
        if (x.code != 'permission-denied') rethrow;
      }
    }
    await ref.update({...payload, 'status': 'draft'});
    return true;
  }

  /// Publishes through the `publishUserExperience` callable (ID document,
  /// host agreement, approved document for paid, new-host paid limit).
  /// [asFree] first turns the listing into a free one.
  Future<void> publish(String id, {bool asFree = false}) =>
      _call('publishUserExperience', {'experienceId': id, 'asFree': asFree});

  Future<void> setStatus(String id, ExperienceStatus status) {
    if (status == ExperienceStatus.published) return publish(id);
    return _col.doc(id).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Records the host agreement (server-owned profile fields).
  Future<void> acceptHostAgreement(int version) =>
      _call('acceptHostAgreement', {'version': version});

  /// The guest consent before paying the host directly. Immutable: a second
  /// consent for the same experience keeps the first record.
  Future<void> recordBookingConsent({
    required String experienceId,
    required String uid,
    required CancellationPolicy policy,
    required int version,
    required PaymentMethod method,
  }) async {
    final ref =
        _col.doc(experienceId).collection('booking_consents').doc(uid);
    try {
      await ref.set({
        'acceptedAt': FieldValue.serverTimestamp(),
        'policy': policy.name,
        'version': version,
        'experienceId': experienceId,
        'method': method.name,
      });
    } on FirebaseException catch (x) {
      // Already recorded: the write is then a (forbidden) update. Fine.
      if (x.code != 'permission-denied') rethrow;
      final existing = await ref.get();
      if (!existing.exists) rethrow;
    }
  }

  Future<void> delete(String id) => _col.doc(id).delete();

  Future<void> report(Map<String, dynamic> data) =>
      _db.collection('reports').add({
        ...data,
        'reportedAt': Timestamp.fromDate(DateTime.now()),
        'status': 'pending',
      });

  // ───────────────────────────────────────────────────────────── reviews

  Future<ExperiencePage<ExperienceReview>> reviews(
    String experienceId, {
    Object? cursor,
    int limit = 10,
  }) async {
    Query<Map<String, dynamic>> q = _reviews(experienceId)
        .where('status', isEqualTo: 'visible')
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (cursor is DocumentSnapshot) q = q.startAfterDocument(cursor);
    final snap = await q.get();
    return ExperiencePage(
      items: [
        for (final d in snap.docs)
          ExperienceReviewModel.fromMap(experienceId, d.id, d.data()),
      ],
      hasMore: snap.docs.length >= limit,
      cursor: snap.docs.isEmpty ? cursor : snap.docs.last,
    );
  }

  Future<ExperienceReview?> myReview(String experienceId, String uid) async {
    final d = await _reviews(experienceId).doc(uid).get();
    if (!d.exists) return null;
    return ExperienceReviewModel.fromMap(experienceId, d.id, d.data()!);
  }

  Future<void> saveReview({
    required String experienceId,
    required String uid,
    required int rating,
    required String comment,
    required bool isNew,
  }) {
    final ref = _reviews(experienceId).doc(uid);
    if (isNew) {
      return ref.set({
        'authorId': uid,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    return ref.update({
      'rating': rating,
      'comment': comment,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteReview(String experienceId, String uid) =>
      _reviews(experienceId).doc(uid).delete();

  // ───────────────────────────────────────────── booking-gated reviews

  DocumentReference<Map<String, dynamic>> _pending(
          String experienceId, String uid) =>
      _col.doc(experienceId).collection('pending_reviews').doc(uid);

  Future<ReviewEligibility?> reviewEligibility(
      String experienceId, String uid) async {
    final d = await _col
        .doc(experienceId)
        .collection('review_eligibility')
        .doc(uid)
        .get();
    final m = d.data();
    if (!d.exists || m == null) return null;
    final bookingId = m['bookingId'] as String? ?? '';
    if (bookingId.isEmpty) return null;
    return ReviewEligibility(
      bookingId: bookingId,
      hostId: m['hostId'] as String?,
      reviewUntil: experienceDateFrom(m['reviewUntil']),
    );
  }

  Future<PendingReview?> pendingReview(String experienceId, String uid) async {
    final d = await _pending(experienceId, uid).get();
    final m = d.data();
    if (!d.exists || m == null) return null;
    return PendingReview(
      experienceId: experienceId,
      authorId: uid,
      bookingId: m['bookingId'] as String? ?? '',
      rating: ((m['rating'] as num?)?.toInt() ?? 1).clamp(1, 5),
      comment: m['comment'] as String? ?? '',
      createdAt: experienceDateFrom(m['createdAt']),
      revealAt: experienceDateFrom(m['revealAt']),
    );
  }

  /// The rules: create with exactly {authorId, bookingId, rating, comment,
  /// createdAt, updatedAt} (server timestamps) and a matching eligibility;
  /// edits touch only rating / comment / updatedAt.
  Future<void> savePendingReview({
    required String experienceId,
    required String uid,
    required String bookingId,
    required int rating,
    required String comment,
    required bool isNew,
  }) {
    final ref = _pending(experienceId, uid);
    if (isNew) {
      return ref.set({
        'authorId': uid,
        'bookingId': bookingId,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    return ref.update({
      'rating': rating,
      'comment': comment,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePendingReview(String experienceId, String uid) =>
      _pending(experienceId, uid).delete();

  // ───────────────────────────────────────────────────────────── replies

  Future<ExperiencePage<ExperienceReply>> replies(
    String experienceId,
    String reviewId, {
    Object? cursor,
    int limit = 10,
  }) async {
    Query<Map<String, dynamic>> q = _replies(experienceId, reviewId)
        .where('status', isEqualTo: 'visible')
        .orderBy('createdAt')
        .limit(limit);
    if (cursor is DocumentSnapshot) q = q.startAfterDocument(cursor);
    final snap = await q.get();
    return ExperiencePage(
      items: [
        for (final d in snap.docs)
          ExperienceReviewModel.replyFromMap(
              experienceId, reviewId, d.id, d.data()),
      ],
      hasMore: snap.docs.length >= limit,
      cursor: snap.docs.isEmpty ? cursor : snap.docs.last,
    );
  }

  Future<ExperienceReply> addReply({
    required String experienceId,
    required String reviewId,
    required String authorId,
    required String text,
    required List<String> mentions,
  }) async {
    final ref = await _replies(experienceId, reviewId).add({
      'authorId': authorId,
      'text': text,
      'mentions': mentions,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ExperienceReply(
      id: ref.id,
      experienceId: experienceId,
      reviewId: reviewId,
      authorId: authorId,
      text: text,
      mentions: mentions,
      createdAt: DateTime.now(),
    );
  }

  Future<void> deleteReply(
          String experienceId, String reviewId, String replyId) =>
      _replies(experienceId, reviewId).doc(replyId).delete();

  Stream<ReviewStatus> watchReplyStatus(
          String experienceId, String reviewId, String replyId) =>
      _replies(experienceId, reviewId)
          .doc(replyId)
          .snapshots()
          .map((s) => ReviewStatus.fromWire(s.data()?['status']));
}

/// Wraps [inner]: a query that needs a composite index still building
/// (`failed-precondition`) ends the feed with an empty page (logged) instead
/// of surfacing an error, so the screen shows its empty state.
class FailSafeExperiencePager implements ExperienceFeedPager {
  FailSafeExperiencePager(this._inner, {this.label = 'experiences'});

  final ExperienceFeedPager _inner;
  final String label;
  bool _failed = false;

  /// The last [next] hit a missing index.
  bool get indexMissing => _failed;

  @override
  bool get hasMore => !_failed && _inner.hasMore;

  @override
  Future<List<UserExperience>> next() async {
    if (_failed) return const [];
    try {
      return await _inner.next();
    } on FirebaseException catch (e) {
      if (e.code != 'failed-precondition') rethrow;
      _failed = true;
      debugPrint('$label: index not ready (${e.message}); showing empty');
      return const [];
    }
  }
}

/// Cursor pager over an ordered query; [keep] filters a page client-side
/// (the cursor still advances past dropped docs). A page thinned by [keep] /
/// [skipIds] is topped up from the following docs, at most [maxReadsPerPage]
/// reads per [next] (never an unbounded loop).
class _QueryPager implements ExperienceFeedPager {
  _QueryPager(this._query, this._pageSize, {this.keep, this.skipIds});

  static const int maxReadsPerPage = 3;

  final Query<Map<String, dynamic>> _query;
  final int _pageSize;
  final bool Function(UserExperience e)? keep;

  /// Ids already shown by a previous source (nearby → newest hand-off).
  final Set<String>? skipIds;

  DocumentSnapshot<Map<String, dynamic>>? _last;
  bool _hasMore = true;

  @override
  bool get hasMore => _hasMore;

  @override
  Future<List<UserExperience>> next() async {
    final out = <UserExperience>[];
    for (var reads = 0;
        _hasMore && out.length < _pageSize && reads < maxReadsPerPage;
        reads++) {
      var q = _query;
      if (_last != null) q = q.startAfterDocument(_last!);
      final snap = await q.limit(_pageSize).get();
      if (snap.docs.isNotEmpty) _last = snap.docs.last;
      _hasMore = snap.docs.length >= _pageSize;
      out.addAll([
        for (final d in snap.docs)
          if (!(skipIds?.contains(d.id) ?? false))
            UserExperienceModel.fromDoc(d),
      ].where((e) => keep?.call(e) ?? true));
    }
    return out;
  }
}

/// Nearest-first rings around the viewer; once the scan is exhausted the
/// rest of the catalogue (listings without coordinates) follows newest-first,
/// skipping what was already shown.
class _NearbyThenNewestPager implements ExperienceFeedPager {
  _NearbyThenNewestPager({
    required this.scanner,
    required _QueryPager fallback,
    required this.pageSize,
  })  : _fallbackQuery = fallback._query,
        _fallbackKeep = fallback.keep;

  final GeoRingScanner<UserExperience> scanner;
  final Query<Map<String, dynamic>> _fallbackQuery;

  /// The fallback's own filter (pictures only), kept across the hand-off.
  final bool Function(UserExperience e)? _fallbackKeep;
  final int pageSize;
  final Set<String> _seen = {};
  _QueryPager? _fallback;

  /// The scan's query failed (e.g. its geohash index is still building):
  /// serve the newest-first list instead.
  bool _scanFailed = false;

  /// The fallback's first page, read in parallel with the scan once the
  /// nearest ring came back empty, so a sparse area (scan exhausted quickly)
  /// doesn't wait for it afterwards.
  Future<List<UserExperience>>? _prefetch;
  bool _first = true;

  bool get _scanning => !_scanFailed && scanner.hasMore;

  @override
  bool get hasMore =>
      _scanning || _prefetch != null || (_fallback?.hasMore ?? true);

  Future<List<UserExperience>> _scan({int? maxRounds}) async {
    try {
      return await scanner.next(maxRounds: maxRounds);
    } on FirebaseException catch (e) {
      if (e.code != 'failed-precondition') rethrow;
      _scanFailed = true;
      return const [];
    }
  }

  @override
  Future<List<UserExperience>> next() async {
    final out = <UserExperience>[];
    if (_first) {
      _first = false;
      // Fast first paint: one read round; return as soon as the nearest ring
      // has anything instead of filling a whole page first.
      for (final e in await _scan(maxRounds: 1)) {
        if (_seen.add(e.id)) out.add(e);
      }
      if (out.isNotEmpty) return out;
      // Sparse area (nearest ring empty): read the fallback's first page in
      // parallel with the remaining rings. It used to start on EVERY open,
      // so a dense area paid for a newest-first page it never showed.
      if (_scanning) {
        _fallback = _QueryPager(_fallbackQuery, pageSize,
            keep: _fallbackKeep, skipIds: _seen);
        final prefetch = _fallback!.next();
        prefetch.then((_) {}, onError: (Object _) {});
        _prefetch = prefetch;
      }
    }
    // A ring can come back empty (sparse area) — keep scanning, bounded.
    var guard = 0;
    while (out.length < pageSize && _scanning && guard++ < 4) {
      for (final e in await _scan()) {
        if (_seen.add(e.id)) out.add(e);
      }
    }
    if (out.isNotEmpty) return out;
    if (_scanning) return out; // budget spent; next scroll continues
    _fallback ??= _QueryPager(_fallbackQuery, pageSize,
        keep: _fallbackKeep, skipIds: _seen);
    final prefetched = _prefetch;
    if (prefetched != null) {
      _prefetch = null;
      // Read before the scan finished: drop what the scan has shown since.
      out.addAll((await prefetched).where((e) => _seen.add(e.id)));
    }
    // Pages can be fully deduplicated away; read a few until something new.
    var g2 = 0;
    while (out.isEmpty && _fallback!.hasMore && g2++ < 3) {
      out.addAll((await _fallback!.next()).where((e) => _seen.add(e.id)));
    }
    return out;
  }
}

/// Distance helper re-exported for cards ("2.3 km").
double experienceDistanceKm(UserExperience e, double lat, double lng) =>
    GeoQuery.distanceMeters(lat, lng, e.lat!, e.lng!) / 1000;
