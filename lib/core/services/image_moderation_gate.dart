import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Thrown when an uploaded image fails server-side moderation.
class ImageRejectedException implements Exception {
  ImageRejectedException(this.reasons);

  /// e.g. ['adult'], ['racy'], ['no_face'], ['verification_failed'].
  final List<String> reasons;

  bool get isExplicit =>
      reasons.contains('adult') ||
      reasons.contains('racy') ||
      reasons.contains('violence');
  bool get isMissingFace => reasons.contains('no_face');
  bool get checkFailed => reasons.contains('verification_failed');

  @override
  String toString() => 'ImageRejectedException(${reasons.join(',')})';
}

/// Blocks until the server has verified an uploaded image.
///
/// The `moderateUploadedImage` Storage trigger writes its verdict to
/// `image_moderation/{objectPath with '/' replaced by '~'}`. The id is derived
/// from the path so the uploader can listen for its own result without being
/// told where to look.
///
/// The upload path awaits this BEFORE the download URL is used anywhere, so an
/// image is never shown or attached to a profile before it has passed. That is
/// the whole point: returning the URL first and moderating afterwards would
/// leave explicit content visible for as long as the check takes.
///
/// On timeout this THROWS rather than allowing the image through. An unchecked
/// image reaching a profile is the failure this exists to prevent, so the safe
/// direction is to refuse. The trigger itself also writes `error` rather than
/// `approved` when Vision is unreachable, for the same reason.
class ImageModerationGate {
  ImageModerationGate({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static String docIdFor(String objectPath) => objectPath.replaceAll('/', '~');

  /// Waits for the verdict on [objectPath]. Returns normally when approved;
  /// throws [ImageRejectedException] when rejected, when the check errored, or
  /// when no verdict arrives within [timeout].
  Future<void> awaitVerdict(
    String objectPath, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final doc = _firestore.collection('image_moderation').doc(docIdFor(objectPath));

    // The verdict often lands before we start listening (a small image is
    // checked in well under a second), so read once before subscribing.
    final existing = await doc.get();
    final settled = _verdictOf(existing.data());
    if (settled != null) return _resolve(settled);

    try {
      final snap = await doc
          .snapshots()
          .firstWhere((s) => _verdictOf(s.data()) != null)
          .timeout(timeout);
      return _resolve(_verdictOf(snap.data())!);
    } on TimeoutException {
      throw ImageRejectedException(['verification_failed']);
    }
  }

  ({String status, List<String> reasons})? _verdictOf(
      Map<String, dynamic>? data) {
    if (data == null) return null;
    final status = (data['status'] as String?) ?? '';
    if (status != 'approved' && status != 'rejected' && status != 'error') {
      return null;
    }
    final reasons = (data['reasons'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toList();
    return (status: status, reasons: reasons);
  }

  void _resolve(({String status, List<String> reasons}) v) {
    if (v.status == 'approved') return;
    throw ImageRejectedException(
      v.reasons.isEmpty ? ['verification_failed'] : v.reasons,
    );
  }
}
