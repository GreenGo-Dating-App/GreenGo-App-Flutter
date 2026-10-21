import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/media_library_item.dart';

/// Why a review request failed (server `details.code`, imageReview.ts).
enum ReviewRequestError { rateLimited, alreadyRequested, notReviewable, failed }

class ReviewRequestException implements Exception {
  const ReviewRequestException(this.error);
  final ReviewRequestError error;

  @override
  String toString() => 'ReviewRequestException($error)';
}

/// "My pictures" data access. Reads are owner-scoped and paged, newest first.
abstract class MediaLibraryRepository {
  /// [approvedOnly]: the pickers (ordered by approvedAt - only approved items
  /// carry it, so no composite index). Otherwise every item, by createdAt.
  Future<MediaLibraryPage> fetchPage({
    required bool approvedOnly,
    Object? cursor,
    int limit = 30,
  });

  /// Removes the entry (the storage object and its uses stay).
  Future<void> remove(String itemId);

  /// Asks a person to review a held picture. Throws [ReviewRequestException].
  Future<void> requestReview(String itemId, {String? note});
}

class FirestoreMediaLibraryRepository implements MediaLibraryRepository {
  FirestoreMediaLibraryRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    String? uid,
  })  : _firestore = firestore,
        _functions = functions,
        _uid = uid;

  final FirebaseFirestore? _firestore;
  final FirebaseFunctions? _functions;
  final String? _uid;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;
  String get _owner => _uid ?? FirebaseAuth.instance.currentUser?.uid ?? '';

  CollectionReference<Map<String, dynamic>> get _items =>
      _db.collection('media_library').doc(_owner).collection('items');

  @override
  Future<MediaLibraryPage> fetchPage({
    required bool approvedOnly,
    Object? cursor,
    int limit = 30,
  }) async {
    if (_owner.isEmpty) return const MediaLibraryPage([], null, hasMore: false);
    Query<Map<String, dynamic>> q = _items
        .orderBy(approvedOnly ? 'approvedAt' : 'createdAt', descending: true)
        .limit(limit);
    if (cursor is DocumentSnapshot) q = q.startAfterDocument(cursor);
    final snap = await q.get();
    final items = snap.docs
        .map((d) => MediaLibraryItem.fromMap(d.id, d.data()))
        .where((i) => !approvedOnly || i.isApproved)
        .toList();
    return MediaLibraryPage(
      items,
      snap.docs.isEmpty ? null : snap.docs.last,
      hasMore: snap.docs.length == limit,
    );
  }

  @override
  Future<void> remove(String itemId) => _items.doc(itemId).delete();

  @override
  Future<void> requestReview(String itemId, {String? note}) async {
    try {
      await (_functions ?? FirebaseFunctions.instance)
          .httpsCallable('requestImageReview')
          .call<dynamic>({
        'itemId': itemId,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      });
    } on FirebaseFunctionsException catch (e) {
      final details = e.details;
      final code = details is Map ? details['code']?.toString() : e.message;
      switch (code) {
        case 'rate_limited':
          throw const ReviewRequestException(ReviewRequestError.rateLimited);
        case 'already_requested':
          throw const ReviewRequestException(
              ReviewRequestError.alreadyRequested);
        case 'not_reviewable':
          throw const ReviewRequestException(ReviewRequestError.notReviewable);
        default:
          throw const ReviewRequestException(ReviewRequestError.failed);
      }
    }
  }
}
