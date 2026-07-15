import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/blocked_users_service.dart';

/// Thin service that performs the two user-safety write actions — reporting
/// and blocking — from surfaces that don't have the full chat stack wired up
/// (e.g. the profile detail screen).
///
/// It deliberately REUSES the exact same Firestore schema the chat feature
/// already writes:
///   * reports  -> `user_reports` collection (same shape chat's reportUser uses)
///   * blocks   -> `blockedUsers` collection + `users/{uid}.blockedUsers` array
/// and invalidates the shared [BlockedUsersService] cache so discovery/chat
/// filters pick the change up immediately. No new collections are introduced.
class SafetyActionsService {

  SafetyActionsService({
    required this.firestore,
    required this.blockedUsersService,
  });

  final FirebaseFirestore firestore;
  final BlockedUsersService blockedUsersService;

  /// File a user report. Mirrors the write performed by
  /// ChatRemoteDataSource.reportUser so both feed the same moderation pipeline.
  Future<void> reportUser({
    required String reporterId,
    required String reportedUserId,
    required String reason,
    String? additionalDetails,
  }) async {
    final reportRef = firestore.collection('user_reports').doc();

    final reportData = <String, dynamic>{
      'reportId': reportRef.id,
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'reason': reason,
      'reportedAt': Timestamp.fromDate(DateTime.now()),
      'createdAt': FieldValue.serverTimestamp(),
      'source': 'profile',
      'status': 'pending',
      'reviewedBy': null,
      'reviewedAt': null,
      'actionTaken': null,
    };
    if (additionalDetails != null && additionalDetails.isNotEmpty) {
      reportData['additionalDetails'] = additionalDetails;
    }

    await reportRef.set(reportData);

    // The moderation counter on the reported user's doc (`reportCount` /
    // `lastReportedAt`) is bumped server-side by the `onUserReportCreated`
    // Cloud Function (Admin SDK) — the client cannot write another user's doc,
    // so the previous best-effort client increment was always denied.
  }

  /// Whether [blockerId] has already blocked [blockedUserId].
  Future<bool> isBlocked({
    required String blockerId,
    required String blockedUserId,
  }) async {
    final ids = await blockedUsersService.getBlockedUserIds(blockerId);
    return ids.contains(blockedUserId);
  }

  /// Block a user. Same write shape as ChatRemoteDataSource.blockUser.
  Future<void> blockUser({
    required String blockerId,
    required String blockedUserId,
    String reason = 'Blocked from profile',
  }) async {
    final blockRef = firestore.collection('blockedUsers').doc();
    await blockRef.set({
      'blockId': blockRef.id,
      'blockerId': blockerId,
      'blockedUserId': blockedUserId,
      'reason': reason,
      'blockedAt': Timestamp.fromDate(DateTime.now()),
    });

    // Also mirror into the user's array for quick membership lookups.
    // Best-effort — the blockedUsers doc is the source of truth.
    try {
      await firestore.collection('users').doc(blockerId).update({
        'blockedUsers': FieldValue.arrayUnion([blockedUserId]),
      });
    } catch (_) {
      // Ignore.
    }

    // Invalidate the shared cache so discovery/chat filters see the block now.
    blockedUsersService.invalidate(blockerId);
  }
}
