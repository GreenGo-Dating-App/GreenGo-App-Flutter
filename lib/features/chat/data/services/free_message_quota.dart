import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/tier_entitlements.dart';

/// Thrown when an account without Base has used today's free messages.
class FreeMessageLimitException implements Exception {
  const FreeMessageLimitException();

  @override
  String toString() => 'FreeMessageLimitException';
}

/// Daily message allowance of accounts without Base (owner rule 2026-10-25):
/// [TierEntitlements.freeDailyMessages] messages per UTC day across all free
/// chats. Enforced by the Firestore rules (`freeMessageCounted`): a free
/// message is written in ONE batch with `free_message_usage/{uid}` =
/// `{at: serverTime, count}`, which may only move up by one (or restart at 1
/// on a new UTC day). The last known count is kept in memory, so a send costs
/// no extra read after the first one.
class FreeMessageQuota {
  FreeMessageQuota({FirebaseFirestore? firestore}) : _fs = firestore;

  static FreeMessageQuota instance = FreeMessageQuota();

  final FirebaseFirestore? _fs;
  FirebaseFirestore get _db => _fs ?? FirebaseFirestore.instance;

  int get limit => TierEntitlements.freeDailyMessages;

  String? _uid;
  int _dayStartMs = -1;
  int _count = 0;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection('free_message_usage').doc(uid);

  static int utcDayStartMs(DateTime now) {
    final ms = now.toUtc().millisecondsSinceEpoch;
    return ms - ms % Duration.millisecondsPerDay;
  }

  Future<void> _load(String uid, DateTime now) async {
    if (_uid == uid && _dayStartMs == utcDayStartMs(now)) return;
    final snap = await _doc(uid).get();
    final d = snap.data();
    final at = d?['at'];
    final atMs = at is Timestamp ? at.millisecondsSinceEpoch : -1;
    _uid = uid;
    _dayStartMs = utcDayStartMs(now);
    _count = atMs >= _dayStartMs ? ((d?['count'] as num?)?.toInt() ?? 0) : 0;
  }

  /// Messages already sent today (UTC).
  Future<int> used(String uid, {DateTime? now}) async {
    await _load(uid, now ?? DateTime.now());
    return _count;
  }

  /// Messages left today.
  Future<int> remaining(String uid, {DateTime? now}) async =>
      (limit - await used(uid, now: now)).clamp(0, limit);

  /// Commits [write] together with the counter bump, or throws
  /// [FreeMessageLimitException] when nothing is left. Around midnight the
  /// device clock and the server may disagree about the day: a refused write
  /// is retried once with the other day assumption.
  Future<void> commitWith(String uid, void Function(WriteBatch batch) write,
      {DateTime? now}) async {
    final t = now ?? DateTime.now();
    await _load(uid, t);
    if (_count >= limit) throw const FreeMessageLimitException();
    Future<void> attempt(int next) async {
      final batch = _db.batch();
      write(batch);
      batch.set(_doc(uid), {'at': FieldValue.serverTimestamp(), 'count': next});
      await batch.commit();
      _count = next;
    }

    try {
      await attempt(_count + 1);
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
      // Re-read the server's view of today, then try once more.
      _dayStartMs = -1;
      await _load(uid, t);
      if (_count >= limit) throw const FreeMessageLimitException();
      await attempt(_count + 1);
    }
  }

  /// Test / sign-out hook.
  void reset() {
    _uid = null;
    _dayStartMs = -1;
    _count = 0;
  }
}
