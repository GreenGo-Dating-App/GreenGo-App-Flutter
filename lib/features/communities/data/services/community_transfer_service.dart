import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// A pending community ownership offer (`community_transfers/{communityId}`,
/// written only by the server; readable by its owner and its target).
@immutable
class CommunityTransferOffer {
  const CommunityTransferOffer({
    required this.communityId,
    required this.communityName,
    required this.fromUserId,
    required this.fromName,
    required this.toUserId,
    required this.toName,
    required this.expiresAt,
    this.sponsorshipWillEnd = false,
  });

  factory CommunityTransferOffer.fromMap(Map<String, dynamic> d) {
    DateTime? at(Object? v) => v is Timestamp
        ? v.toDate()
        : (v is DateTime ? v : (v is int ? DateTime.fromMillisecondsSinceEpoch(v) : null));
    return CommunityTransferOffer(
      communityId: '${d['communityId'] ?? ''}',
      communityName: '${d['communityName'] ?? ''}',
      fromUserId: '${d['fromUserId'] ?? ''}',
      fromName: '${d['fromName'] ?? ''}',
      toUserId: '${d['toUserId'] ?? ''}',
      toName: '${d['toName'] ?? ''}',
      expiresAt: at(d['expiresAt']),
      sponsorshipWillEnd: d['sponsorshipWillEnd'] == true,
    );
  }

  final String communityId;
  final String communityName;
  final String fromUserId;
  final String fromName;
  final String toUserId;
  final String toName;
  final DateTime? expiresAt;
  final bool sponsorshipWillEnd;

  bool isExpired([DateTime? now]) =>
      expiresAt != null && !expiresAt!.isAfter(now ?? DateTime.now());
}

/// Why a transfer call was refused (server `details.code`).
enum CommunityTransferFailure {
  requiresRecentLogin,
  notMember,
  unavailable,
  pending,
  limit,
  gone,
  failed,
}

/// Thrown by [CommunityTransferService] calls.
class CommunityTransferException implements Exception {
  const CommunityTransferException(this.failure);
  final CommunityTransferFailure failure;
  @override
  String toString() => 'CommunityTransferException($failure)';
}

/// Community ownership transfer: the three callables
/// (`requestCommunityTransfer` / `respondCommunityTransfer` /
/// `cancelCommunityTransfer`, functions/src/communities/transfer.ts) and the
/// live pending offer of a community.
///
/// Every Firebase handle is resolved lazily, so a screen that merely shows
/// the banner works in widget tests without Firebase (no offer is shown).
class CommunityTransferService {
  CommunityTransferService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore,
        _functions = functions;

  static CommunityTransferService instance = CommunityTransferService();

  final FirebaseFirestore? _firestore;
  final FirebaseFunctions? _functions;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;
  FirebaseFunctions get _fn => _functions ?? FirebaseFunctions.instance;

  static const String collection = 'community_transfers';

  /// The pending offer of [communityId] that [userId] may see: as its owner
  /// (sender) or as its target. Emits null when there is none. Rules allow
  /// these two shapes only (owner reads the doc by id, a target queries by
  /// toUserId), so nobody else ever triggers a permission error.
  Stream<CommunityTransferOffer?> watchOffer({
    required String communityId,
    required String userId,
    required bool asOwner,
  }) {
    try {
      final Stream<Map<String, dynamic>?> raw = asOwner
          ? _db
              .collection(collection)
              .doc(communityId)
              .snapshots()
              .map((s) => s.data())
          : _db
              .collection(collection)
              .where('toUserId', isEqualTo: userId)
              .where('communityId', isEqualTo: communityId)
              .limit(1)
              .snapshots()
              .map((q) => q.docs.isEmpty ? null : q.docs.first.data());
      return raw
          .map((d) {
            if (d == null) return null;
            final o = CommunityTransferOffer.fromMap(d);
            final mine = asOwner ? o.fromUserId == userId : o.toUserId == userId;
            return mine && !o.isExpired() ? o : null;
          })
          .handleError((Object e) =>
              debugPrint('[CommunityTransfer] watch failed: $e'));
    } catch (e) {
      debugPrint('[CommunityTransfer] watch unavailable: $e');
      return Stream<CommunityTransferOffer?>.value(null);
    }
  }

  /// Offers the community to [toUserId]. Needs a sign-in from the last
  /// 5 minutes (call after re-authentication).
  Future<void> request({
    required String communityId,
    required String toUserId,
  }) =>
      _call('requestCommunityTransfer',
          {'communityId': communityId, 'toUserId': toUserId});

  /// The target accepts ([accept] = true) or declines the offer.
  Future<void> respond({required String communityId, required bool accept}) =>
      _call('respondCommunityTransfer',
          {'communityId': communityId, 'accept': accept});

  /// The owner withdraws the pending offer.
  Future<void> cancel({required String communityId}) =>
      _call('cancelCommunityTransfer', {'communityId': communityId});

  Future<void> _call(String name, Map<String, dynamic> data) async {
    try {
      await _fn.httpsCallable(name).call<dynamic>(data);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[CommunityTransfer] $name failed: ${e.code} ${e.details}');
      throw CommunityTransferException(failureFor(e.code, e.details));
    } catch (e) {
      debugPrint('[CommunityTransfer] $name failed: $e');
      throw const CommunityTransferException(CommunityTransferFailure.failed);
    }
  }

  /// Maps a callable error (code + `details.code`) to a failure.
  @visibleForTesting
  static CommunityTransferFailure failureFor(String code, Object? details) {
    final detail = details is Map ? '${details['code'] ?? ''}' : '';
    switch (detail) {
      case 'requires_recent_login':
        return CommunityTransferFailure.requiresRecentLogin;
      case 'target_not_member':
        return CommunityTransferFailure.notMember;
      case 'target_unavailable':
      case 'self_transfer':
        return CommunityTransferFailure.unavailable;
      case 'transfer_pending':
        return CommunityTransferFailure.pending;
      case 'owner_limit_reached':
        return CommunityTransferFailure.limit;
      case 'no_pending_transfer':
      case 'transfer_expired':
      case 'community_not_found':
      case 'not_creator':
        return CommunityTransferFailure.gone;
    }
    return CommunityTransferFailure.failed;
  }
}
