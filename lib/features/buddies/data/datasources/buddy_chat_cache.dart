import '../../../../core/cache/last_result_cache.dart';
import '../../domain/entities/buddy_message.dart';

/// Local copy of the latest messages of each Buddy chat, INCLUDING their
/// stored translations: painted at once when a chat opens (before Firestore
/// answers), then replaced by the server page. Owner 2026-10-24.
///
/// Bounded: the newest [maxMessages] messages per Buddy, for the
/// [maxBuddies] most recently used Buddies (the oldest chat is dropped).
/// Cleared per Buddy on clear chat / delete Buddy, and entirely on sign-out
/// (the default store is [LastResultCache], which sign-out clears and which
/// is scoped to the signed-in user).
abstract class BuddyChatCache {
  Future<List<BuddyMessage>> load(String buddyId);
  Future<void> save(String buddyId, List<BuddyMessage> messages);
  Future<void> clear(String buddyId);
}

/// Where [JsonBuddyChatCache] keeps its JSON values.
abstract class BuddyChatCacheStore {
  Future<Object?> read(String key);
  Future<void> write(String key, Object? value);
}

/// The app store: the per-user Hive box of [LastResultCache].
class LastResultBuddyChatCacheStore implements BuddyChatCacheStore {
  const LastResultBuddyChatCacheStore();

  /// A chat not opened for this long is not painted from the cache.
  static const Duration maxAge = Duration(days: 30);

  @override
  Future<Object?> read(String key) => LastResultCache.loadJson(key, maxAge: maxAge);

  @override
  Future<void> write(String key, Object? value) => LastResultCache.saveJson(key, value);
}

/// An in-memory store (tests; never persisted).
class MemoryBuddyChatCacheStore implements BuddyChatCacheStore {
  final Map<String, Object?> values = {};

  @override
  Future<Object?> read(String key) async => values[key];

  @override
  Future<void> write(String key, Object? value) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }
}

/// [BuddyChatCache] as JSON in a [BuddyChatCacheStore]: one value per Buddy
/// plus an index of the cached Buddies (most recent first).
class JsonBuddyChatCache implements BuddyChatCache {
  JsonBuddyChatCache({BuddyChatCacheStore? store})
      : _store = store ?? const LastResultBuddyChatCacheStore();

  final BuddyChatCacheStore _store;

  static const int maxMessages = 50;
  static const int maxBuddies = 10;
  static const String indexKey = 'buddy_chat_cache_index';
  static String keyOf(String buddyId) => 'buddy_chat_cache_$buddyId';

  @override
  Future<List<BuddyMessage>> load(String buddyId) async {
    try {
      final raw = await _store.read(keyOf(buddyId));
      if (raw is! List) return const [];
      return [
        for (final m in raw)
          if (messageFromJson(m) case final msg?) msg,
      ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> save(String buddyId, List<BuddyMessage> messages) async {
    try {
      final stored = [for (final m in messages) if (!m.isLocal) m]
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final newest = stored.length > maxMessages
          ? stored.sublist(stored.length - maxMessages)
          : stored;
      if (newest.isEmpty) return;
      await _store.write(keyOf(buddyId), [for (final m in newest) messageToJson(m)]);
      // Most recently used first; the Buddies past the cap are dropped.
      final index = await _index();
      final next = [buddyId, for (final id in index) if (id != buddyId) id];
      for (final dropped in next.skip(maxBuddies)) {
        await _store.write(keyOf(dropped), null);
      }
      await _store.write(indexKey, next.take(maxBuddies).toList());
    } catch (_) {
      // A cache: never fails the chat.
    }
  }

  @override
  Future<void> clear(String buddyId) async {
    try {
      await _store.write(keyOf(buddyId), null);
      final index = await _index();
      if (index.contains(buddyId)) {
        await _store.write(indexKey, [for (final id in index) if (id != buddyId) id]);
      }
    } catch (_) {}
  }

  Future<List<String>> _index() async {
    final raw = await _store.read(indexKey);
    return raw is List ? raw.whereType<String>().toList() : <String>[];
  }

  static Map<String, Object?> messageToJson(BuddyMessage m) => {
        'id': m.id,
        'role': m.isBuddy ? 'buddy' : 'user',
        'text': m.text,
        'kind': m.kind.name,
        'charged': m.charged,
        'at': m.createdAt.millisecondsSinceEpoch,
        if (m.keywords.isNotEmpty)
          'keywords': [for (final k in m.keywords) {'type': k.type, 'name': k.name}],
        if (m.translation != null)
          'translation': {
            'text': m.translation!.text,
            if (m.translation!.lang != null) 'lang': m.translation!.lang,
          },
      };

  static BuddyMessage? messageFromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'], text = raw['text'], at = raw['at'];
    if (id is! String || id.isEmpty || text is! String || at is! num) return null;
    return BuddyMessage(
      id: id,
      role: BuddyMessage.roleFrom(raw['role']),
      text: text,
      kind: BuddyMessage.kindFrom(raw['kind']),
      charged: raw['charged'] is String ? raw['charged'] as String : 'none',
      createdAt: DateTime.fromMillisecondsSinceEpoch(at.toInt()),
      keywords: BuddyKeyword.listFrom(raw['keywords']),
      translation: BuddyTranslation.fromMap(raw['translation']),
    );
  }
}
