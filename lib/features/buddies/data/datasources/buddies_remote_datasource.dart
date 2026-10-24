import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../domain/entities/buddy.dart';
import '../../domain/entities/buddy_avatar_option.dart';
import '../../domain/entities/buddy_message.dart';

/// Firestore + callables of GreenGo Buddies (functions/src/buddies).
///
/// Reads are scoped to the signed-in user's own subtree and always bounded
/// (`limit`), so a user with a long history never loads it all.
class BuddiesRemoteDataSource {
  BuddiesRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore,
        _functions = functions;

  final FirebaseFirestore? _firestore;
  final FirebaseFunctions? _functions;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;
  FirebaseFunctions get _fn => _functions ?? FirebaseFunctions.instance;

  static const String collection = 'ai_buddies';

  /// Hard cap on the Buddies list (the top plan allows 10).
  static const int maxBuddies = 50;

  /// Pictures people pick a Buddy avatar from (read-only for clients).
  static const String avatarsCollection = 'buddy_avatars';

  /// The catalogue is small (about 50 pictures); one bounded read.
  static const int maxAvatars = 60;

  CollectionReference<Map<String, dynamic>> _buddies(String uid) =>
      _db.collection(collection).doc(uid).collection('buddies');

  CollectionReference<Map<String, dynamic>> _messages(String uid, String buddyId) =>
      _buddies(uid).doc(buddyId).collection('messages');

  Future<Map<String, dynamic>> call(String name, Map<String, Object?> data,
      {Duration timeout = const Duration(seconds: 30)}) async {
    final res = await _fn
        .httpsCallable(name, options: HttpsCallableOptions(timeout: timeout))
        .call<Object?>(data);
    final out = res.data;
    return out is Map ? Map<String, dynamic>.from(out) : <String, dynamic>{};
  }

  Stream<List<Buddy>> watchBuddies(String uid) => _buddies(uid)
      .orderBy('createdAt')
      .limit(maxBuddies)
      .snapshots()
      .map((s) => s.docs.map((d) => buddyFromMap(d.id, d.data())).toList());

  Stream<Buddy?> watchBuddy(String uid, String buddyId) => _buddies(uid)
      .doc(buddyId)
      .snapshots()
      .map((d) => d.exists ? buddyFromMap(d.id, d.data()!) : null);

  /// Active avatar pictures, ordered by `order` (then id).
  ///
  /// One equality filter only, sorted here: `active == true` + `orderBy`
  /// on another field would need a composite index, and the list is tiny.
  Future<List<BuddyAvatarOption>> fetchAvatarOptions() async {
    final snap = await _db
        .collection(avatarsCollection)
        .where('active', isEqualTo: true)
        .limit(maxAvatars)
        .get();
    final list = <BuddyAvatarOption>[
      for (final d in snap.docs)
        if (BuddyAvatarOption.fromMap(d.id, d.data()) case final o?) o,
    ];
    list.sort((a, b) => a.order != b.order ? a.order.compareTo(b.order) : a.id.compareTo(b.id));
    return list;
  }

  Future<BuddyMessagePage> latestMessages(String uid, String buddyId, int limit) async {
    final snap =
        await _messages(uid, buddyId).orderBy('createdAt', descending: true).limit(limit).get();
    return _page(snap, limit);
  }

  Future<BuddyMessagePage> olderMessages(
      String uid, String buddyId, DateTime before, int limit) async {
    final snap = await _messages(uid, buddyId)
        .where('createdAt', isLessThan: Timestamp.fromDate(before))
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return _page(snap, limit);
  }

  Stream<List<BuddyMessage>> watchNewMessages(String uid, String buddyId, DateTime? after) {
    Query<Map<String, dynamic>> q = _messages(uid, buddyId);
    if (after != null) {
      q = q.where('createdAt', isGreaterThan: Timestamp.fromDate(after));
    }
    // Only messages of this session arrive here (bounded anyway).
    return q
        .orderBy('createdAt')
        .limitToLast(200)
        .snapshots()
        .map((s) => s.docs.map((d) => messageFromMap(d.id, d.data())).toList());
  }

  BuddyMessagePage _page(QuerySnapshot<Map<String, dynamic>> snap, int limit) {
    final list = snap.docs.map((d) => messageFromMap(d.id, d.data())).toList().reversed.toList();
    return BuddyMessagePage(messages: list, hasMore: snap.docs.length >= limit);
  }

  static DateTime? _time(Object? v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
    return null;
  }

  static Buddy buddyFromMap(String id, Map<String, dynamic> d) {
    final memory = <BuddyMemoryFact>[];
    final raw = d['memory'];
    if (raw is List) {
      for (final f in raw) {
        if (f is Map && f['id'] is String && f['text'] is String) {
          memory.add(BuddyMemoryFact(
              id: f['id'] as String, text: f['text'] as String, at: _time(f['at'])));
        }
      }
    }
    return Buddy(
      id: id,
      settings: BuddySettings(
        name: (d['name'] as String?) ?? '',
        avatar: (d['avatar'] as String?) ?? 'buddy_01',
        topic: (d['topic'] as String?) ?? 'casual_chat',
        role: d['role'] as String?,
        tone: (d['tone'] as String?) ?? 'warm',
        language: (d['language'] as String?) ?? 'en',
        level: d['level'] as String?,
        cefr: d['cefr'] as String?,
        checkInsEnabled: d['checkInsEnabled'] != false,
      ),
      lastMessage: d['lastMessage'] as String?,
      lastMessageAt: _time(d['lastMessageAt']),
      createdAt: _time(d['createdAt']),
      messageCount: (d['messageCount'] as num?)?.toInt() ?? 0,
      unansweredCheckIns: (d['unansweredCheckIns'] as num?)?.toInt() ?? 0,
      memory: memory,
    );
  }

  static BuddyMessage messageFromMap(String id, Map<String, dynamic> d) => BuddyMessage(
        id: id,
        role: BuddyMessage.roleFrom(d['role']),
        text: (d['text'] as String?) ?? '',
        kind: BuddyMessage.kindFrom(d['kind']),
        charged: (d['charged'] as String?) ?? 'none',
        // A pending server timestamp reads as null: treat it as "now".
        createdAt: _time(d['createdAt']) ?? DateTime.now(),
      );
}
