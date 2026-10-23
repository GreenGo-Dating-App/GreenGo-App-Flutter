import '../entities/buddy.dart';
import '../entities/buddy_message.dart';
import '../entities/buddy_status.dart';

/// GreenGo Buddies (AI chat friends). Reads are owner-only Firestore reads of
/// `ai_buddies/{uid}/...`; every write goes through a callable. Failed calls
/// throw a `BuddyException` (see buddy_exception.dart).
abstract class BuddiesRepository {
  /// The user's Buddies (a handful per user: at most the plan limit, 10).
  Stream<List<Buddy>> watchBuddies(String uid);

  /// One Buddy, live (null when deleted).
  Stream<Buddy?> watchBuddy(String uid, String buddyId);

  Future<BuddyStatus> getStatus();

  /// Returns the new Buddy id.
  Future<String> createBuddy(BuddySettings settings);

  /// [patch] holds only the changed settings keys.
  Future<void> updateBuddy(String buddyId, Map<String, Object?> patch);

  Future<void> deleteBuddy(String buddyId);

  Future<void> clearChat(String buddyId, {bool forgetMemory = false});

  /// Forgets one fact ([factId]) or everything (null).
  Future<void> forgetMemory(String buddyId, {String? factId});

  /// One reply. [requestId] is reused when retrying the same message.
  Future<BuddySendResult> sendMessage({
    required String buddyId,
    required String text,
    required String requestId,
  });

  /// The newest [limit] messages, oldest first.
  Future<BuddyMessagePage> latestMessages(String uid, String buddyId, {int limit = 30});

  /// [limit] messages older than [before], oldest first.
  Future<BuddyMessagePage> olderMessages(
    String uid,
    String buddyId, {
    required DateTime before,
    int limit = 30,
  });

  /// Messages created after [after] (all when null), oldest first, live.
  Stream<List<BuddyMessage>> watchNewMessages(String uid, String buddyId, {DateTime? after});

  /// A fresh idempotency id for `sendBuddyMessage`.
  String newRequestId();
}
