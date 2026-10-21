import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// One listing that blocks account deletion (server: getDeletionBlockers,
/// functions/src/auth/deletionBlockers.ts): an upcoming / ongoing event or
/// experience the user SELLS with paid orders that are not refunded, or a
/// refund of theirs that is not settled.
class DeletionBlocker {
  const DeletionBlocker({
    required this.kind,
    required this.listingId,
    required this.title,
    this.startsAt,
    this.paidOrders = 0,
    this.refundsInProgress = 0,
    this.failedRefunds = 0,
    this.pendingReview = 0,
    this.bookingIds = const [],
    this.failedOrderIds = const [],
  });

  factory DeletionBlocker.fromMap(Map<String, dynamic> m) {
    int n(Object? v) => v is num ? v.toInt() : 0;
    List<String> ids(Object? v) =>
        v is List ? v.whereType<String>().toList() : const <String>[];
    final action = m['actionOrders'] is List ? m['actionOrders'] as List : const [];
    return DeletionBlocker(
      kind: m['kind'] == 'experience' ? 'experience' : 'event',
      listingId: (m['listingId'] as String?) ?? '',
      title: (m['title'] as String?) ?? '',
      startsAt: m['startsAt'] is String ? DateTime.tryParse(m['startsAt'] as String) : null,
      paidOrders: n(m['paidOrders']),
      refundsInProgress: n(m['refundsInProgress']),
      failedRefunds: n(m['failedRefunds']),
      pendingReview: n(m['pendingReview']),
      bookingIds: ids(m['bookingIds']),
      failedOrderIds: [
        for (final a in action)
          if (a is Map && a['status'] == 'refund_failed' && a['orderId'] is String)
            a['orderId'] as String,
      ],
    );
  }

  /// 'event' | 'experience'.
  final String kind;
  final String listingId;
  final String title;
  final DateTime? startsAt;
  final int paidOrders;
  final int refundsInProgress;
  final int failedRefunds;
  final int pendingReview;

  /// Experience bookings the host can still cancel (full refund).
  final List<String> bookingIds;

  /// Orders whose automatic refund failed: the seller refunds by hand and
  /// uploads the proof.
  final List<String> failedOrderIds;

  bool get isEvent => kind == 'event';

  /// "Cancel & refund" makes sense while something can still be cancelled.
  bool get canCancel =>
      isEvent ? paidOrders > refundsInProgress + failedRefunds + pendingReview : bookingIds.isNotEmpty;
}

/// Parses the getDeletionBlockers result / the `deletion_blocked_paid_orders`
/// error details (both carry `blockers`).
List<DeletionBlocker> parseDeletionBlockers(Object? data) {
  final raw = data is Map ? data['blockers'] : null;
  if (raw is! List) return const [];
  return [
    for (final b in raw)
      if (b is Map) DeletionBlocker.fromMap(Map<String, dynamic>.from(b)),
  ];
}

/// The server's refusal code when deletion is blocked.
const String kDeletionBlockedCode = 'deletion_blocked_paid_orders';

/// Max size of a manual-refund proof (storage.rules refund_proofs: 10 MB).
const int kRefundProofMaxBytes = 10 * 1024 * 1024;

/// Content type of a proof file, or null when it is not accepted
/// (storage.rules: images or PDF).
String? refundProofContentType(String fileName) {
  final ext = fileName.split('.').last.toLowerCase();
  return switch (ext) {
    'pdf' => 'application/pdf',
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'webp' => 'image/webp',
    'heic' => 'image/heic',
    _ => null,
  };
}

/// Calls behind the Delete account blockers sheet.
class DeletionBlockersService {
  DeletionBlockersService({
    FirebaseFunctions? functions,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _functions = functions,
        _firestore = firestore,
        _storage = storage;

  final FirebaseFunctions? _functions;
  final FirebaseFirestore? _firestore;
  final FirebaseStorage? _storage;

  FirebaseFunctions get _fn => _functions ?? FirebaseFunctions.instance;

  Future<List<DeletionBlocker>> fetch() async {
    final res = await _fn.httpsCallable('getDeletionBlockers').call<Map<String, dynamic>>(<String, dynamic>{});
    return parseDeletionBlockers(res.data);
  }

  /// Cancels the event: the server refunds every buyer in full
  /// (refundTicketsOnEventCancelled). Never deletes it.
  Future<void> cancelEvent(String eventId) async {
    await (_firestore ?? FirebaseFirestore.instance).collection('events').doc(eventId).update({
      'status': 'cancelled',
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Host cancels each paid booking: full refund (Terms 12.2 / 12.5 c).
  Future<void> cancelBookings(List<String> bookingIds) async {
    final call = _fn.httpsCallable('cancelBooking');
    for (final id in bookingIds) {
      await call.call<Map<String, dynamic>>(<String, dynamic>{'bookingId': id});
    }
  }

  /// Uploads the proof of a manual refund and asks for an admin review.
  Future<void> submitRefundProof({
    required String orderId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final type = refundProofContentType(fileName);
    if (type == null || bytes.length > kRefundProofMaxBytes) {
      throw ArgumentError('refund_proof_invalid');
    }
    final ext = fileName.split('.').last.toLowerCase();
    final path = 'refund_proofs/$orderId/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await (_storage ?? FirebaseStorage.instance).ref(path).putData(bytes, SettableMetadata(contentType: type));
    await _fn.httpsCallable('submitManualRefundProof').call<Map<String, dynamic>>(<String, dynamic>{
      'orderId': orderId,
      'proofPath': path,
    });
  }
}
