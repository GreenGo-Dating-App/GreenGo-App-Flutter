import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

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
  final String code; // experience_limit | prohibited_text | invalid_experience
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
            tokens.skip(1).every(e.searchKeywords.contains) &&
            (category == null || e.category == category),
      );
    }
    if (category != null) {
      return _QueryPager(
        published
            .where('category', isEqualTo: category.name)
            .orderBy('createdAt', descending: true),
        pageSize,
      );
    }
    final newest = _QueryPager(
        published.orderBy('createdAt', descending: true), pageSize);
    if (lat == null || lng == null) return newest;
    return _NearbyThenNewestPager(
      scanner: GeoRingScanner<UserExperience>(
        base: published,
        lat: lat,
        lng: lng,
        startRadiusM: 50000,
        perQueryLimit: pageSize,
        maxRoundsPerCall: 4,
        parse: UserExperienceModel.fromDoc,
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

  Future<String> create(UserExperience draft) async {
    try {
      final res = await _functions
          .httpsCallable('createUserExperience')
          .call<Object?>(UserExperienceModel.createPayload(draft));
      final data = res.data;
      final id = data is Map ? data['id'] as String? : null;
      if (id == null || id.isEmpty) {
        throw const ExperienceCreateException('invalid_response');
      }
      return id;
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
      if (code == 'prohibited_text') {
        throw const ExperienceCreateException('prohibited_text');
      }
      if (code == 'invalid_experience') {
        throw ExperienceCreateException(
          'invalid_experience',
          fields: details is Map && details['fields'] is List
              ? (details['fields'] as List).whereType<String>().toList()
              : const [],
        );
      }
      rethrow;
    }
  }

  Future<void> update(UserExperience e) {
    return _col.doc(e.id).update({
      ...UserExperienceModel.editablePayload(e),
      'hostName': e.hostName,
      'hostPhotoUrl': e.hostPhotoUrl,
      // The host can't move a moderation-hidden listing (rules enforce it).
      if (!e.isHidden) 'status': e.status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setStatus(String id, ExperienceStatus status) =>
      _col.doc(id).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

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

/// Cursor pager over an ordered query; [keep] filters a page client-side
/// (the cursor still advances past dropped docs).
class _QueryPager implements ExperienceFeedPager {
  _QueryPager(this._query, this._pageSize, {this.keep, this.skipIds});

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
    if (!_hasMore) return const [];
    var q = _query.limit(_pageSize);
    if (_last != null) q = q.startAfterDocument(_last!);
    final snap = await q.get();
    if (snap.docs.isNotEmpty) _last = snap.docs.last;
    _hasMore = snap.docs.length >= _pageSize;
    return [
      for (final d in snap.docs)
        if (!(skipIds?.contains(d.id) ?? false))
          UserExperienceModel.fromDoc(d),
    ].where((e) => keep?.call(e) ?? true).toList();
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
  }) : _fallbackQuery = fallback._query;

  final GeoRingScanner<UserExperience> scanner;
  final Query<Map<String, dynamic>> _fallbackQuery;
  final int pageSize;
  final Set<String> _seen = {};
  _QueryPager? _fallback;

  @override
  bool get hasMore => scanner.hasMore || (_fallback?.hasMore ?? true);

  @override
  Future<List<UserExperience>> next() async {
    final out = <UserExperience>[];
    // A ring can come back empty (sparse area) — keep scanning, bounded.
    var guard = 0;
    while (out.length < pageSize && scanner.hasMore && guard++ < 4) {
      for (final e in await scanner.next()) {
        if (_seen.add(e.id)) out.add(e);
      }
    }
    if (out.isNotEmpty) return out;
    if (scanner.hasMore) return out; // budget spent; next scroll continues
    _fallback ??= _QueryPager(_fallbackQuery, pageSize, skipIds: _seen);
    // Pages can be fully deduplicated away; read a few until something new.
    var g2 = 0;
    while (out.isEmpty && _fallback!.hasMore && g2++ < 3) {
      out.addAll(await _fallback!.next());
    }
    return out;
  }
}

/// Distance helper re-exported for cards ("2.3 km").
double experienceDistanceKm(UserExperience e, double lat, double lng) =>
    GeoQuery.distanceMeters(lat, lng, e.lat!, e.lng!) / 1000;
