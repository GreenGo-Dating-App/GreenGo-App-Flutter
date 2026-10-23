import 'package:uuid/uuid.dart';

import '../../domain/buddy_exception.dart';
import '../../domain/entities/buddy.dart';
import '../../domain/entities/buddy_message.dart';
import '../../domain/entities/buddy_status.dart';
import '../../domain/repositories/buddies_repository.dart';
import '../datasources/buddies_remote_datasource.dart';

class BuddiesRepositoryImpl implements BuddiesRepository {
  BuddiesRepositoryImpl({required this.remote, Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final BuddiesRemoteDataSource remote;
  final Uuid _uuid;

  /// Runs a callable and turns any failure into a [BuddyException].
  Future<Map<String, dynamic>> _call(String name, Map<String, Object?> data,
      {Duration timeout = const Duration(seconds: 30)}) async {
    try {
      return await remote.call(name, data, timeout: timeout);
    } catch (e) {
      throw BuddyException.from(e);
    }
  }

  @override
  Stream<List<Buddy>> watchBuddies(String uid) => remote.watchBuddies(uid);

  @override
  Stream<Buddy?> watchBuddy(String uid, String buddyId) => remote.watchBuddy(uid, buddyId);

  @override
  Future<BuddyStatus> getStatus() async =>
      BuddyStatus.fromMap(await _call('getBuddyStatus', const {}));

  @override
  Future<String> createBuddy(BuddySettings settings) async {
    final res = await _call('createBuddy', {'settings': settings.toMap()});
    final id = res['buddyId'];
    if (id is! String || id.isEmpty) {
      throw const BuddyException(BuddyErrorKind.other);
    }
    return id;
  }

  @override
  Future<void> updateBuddy(String buddyId, Map<String, Object?> patch) async {
    if (patch.isEmpty) return;
    await _call('updateBuddy', {'buddyId': buddyId, 'settings': patch});
  }

  @override
  Future<void> deleteBuddy(String buddyId) async {
    await _call('deleteBuddy', {'buddyId': buddyId}, timeout: const Duration(seconds: 60));
  }

  @override
  Future<void> clearChat(String buddyId, {bool forgetMemory = false}) async {
    await _call('clearBuddyChat', {'buddyId': buddyId, 'forgetMemory': forgetMemory},
        timeout: const Duration(seconds: 60));
  }

  @override
  Future<void> forgetMemory(String buddyId, {String? factId}) async {
    await _call('forgetBuddyMemory', {
      'buddyId': buddyId,
      if (factId != null) 'factId': factId,
    });
  }

  @override
  Future<BuddySendResult> sendMessage({
    required String buddyId,
    required String text,
    required String requestId,
  }) async {
    final res = await _call(
      'sendBuddyMessage',
      {'buddyId': buddyId, 'text': text, 'requestId': requestId},
      timeout: const Duration(seconds: 60),
    );
    return BuddySendResult.fromMap(res);
  }

  @override
  Future<BuddyMessagePage> latestMessages(String uid, String buddyId, {int limit = 30}) =>
      remote.latestMessages(uid, buddyId, limit);

  @override
  Future<BuddyMessagePage> olderMessages(String uid, String buddyId,
          {required DateTime before, int limit = 30}) =>
      remote.olderMessages(uid, buddyId, before, limit);

  @override
  Stream<List<BuddyMessage>> watchNewMessages(String uid, String buddyId, {DateTime? after}) =>
      remote.watchNewMessages(uid, buddyId, after);

  /// uuid v4: 36 chars of [0-9a-f-], valid for the server's
  /// `validRequestId` (/^[A-Za-z0-9_-]{8,80}$/).
  @override
  String newRequestId() => _uuid.v4();
}
