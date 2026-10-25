import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/cache/last_result_cache.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

/// What [ChatMessageCache] painted for a chat: its latest messages (newest
/// first) and, for a 1:1 chat, the conversation they belong to.
class CachedChat {
  const CachedChat({required this.messages, this.conversation});
  final List<Message> messages;
  final Conversation? conversation;
}

/// Local copy of the latest messages of each chat (1:1 and group), INCLUDING
/// their stored translations (`tr` / `lang`): painted at once when a chat
/// opens, before Firestore answers, then replaced by the live window.
/// Owner 2026-10-24 ("we read what is cached first inside the app").
///
/// Bounded: the newest [JsonChatMessageCache.maxMessages] messages per chat,
/// for the [JsonChatMessageCache.maxChats] most recently opened chats (the
/// oldest chat is dropped). The default store is [LastResultCache]: scoped to
/// the signed-in user and cleared on sign-out.
abstract class ChatMessageCache {
  Future<CachedChat?> load(String key);
  Future<void> save(
    String key,
    List<Message> messages, {
    Conversation? conversation,
  });
  Future<void> clear(String key);

  /// Key of a 1:1 chat (the match id is known before the conversation).
  static String direct(String matchId) => 'c_$matchId';

  /// Key of a group chat.
  static String group(String groupId) => 'g_$groupId';
}

/// Where [JsonChatMessageCache] keeps its JSON values.
abstract class ChatMessageCacheStore {
  Future<Object?> read(String key);
  Future<void> write(String key, Object? value);
}

/// The app store: the per-user Hive box of [LastResultCache].
class LastResultChatMessageCacheStore implements ChatMessageCacheStore {
  const LastResultChatMessageCacheStore();

  /// A chat not opened for this long is not painted from the cache.
  static const Duration maxAge = Duration(days: 30);

  @override
  Future<Object?> read(String key) =>
      LastResultCache.loadJson(key, maxAge: maxAge);

  @override
  Future<void> write(String key, Object? value) =>
      LastResultCache.saveJson(key, value);
}

/// An in-memory store (tests; never persisted).
class MemoryChatMessageCacheStore implements ChatMessageCacheStore {
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

/// [ChatMessageCache] as JSON in a [ChatMessageCacheStore]: one value per
/// chat plus an index of the cached chats (most recent first).
class JsonChatMessageCache implements ChatMessageCache {
  JsonChatMessageCache({ChatMessageCacheStore? store})
    : _store = store ?? const LastResultChatMessageCacheStore();

  /// The app-wide instance (Hive-backed).
  static final JsonChatMessageCache instance = JsonChatMessageCache();

  final ChatMessageCacheStore _store;

  static const int maxMessages = 50;
  static const int maxChats = 30;
  static const String indexKey = 'chat_msg_cache_index';
  static String keyOf(String key) => 'chat_msg_cache_$key';

  @override
  Future<CachedChat?> load(String key) async {
    try {
      final raw = await _store.read(keyOf(key));
      if (raw is! Map) return null;
      final list = raw['m'];
      if (list is! List) return null;
      final messages = <Message>[
        for (final m in list)
          if (_messageFromJson(m) case final msg?) msg,
      ]..sort((a, b) => b.sentAt.compareTo(a.sentAt));
      if (messages.isEmpty) return null;
      return CachedChat(
        messages: messages,
        conversation: _conversationFromJson(raw['c']),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(
    String key,
    List<Message> messages, {
    Conversation? conversation,
  }) async {
    try {
      final sorted = [...messages]
        ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
      final newest = sorted.take(maxMessages).toList();
      if (newest.isEmpty) return;
      await _store.write(keyOf(key), {
        'm': [for (final m in newest) _messageToJson(m)],
        if (conversation != null) 'c': _conversationToJson(conversation),
      });
      // Most recently used first; the chats past the cap are dropped.
      final index = await _index();
      final next = [
        key,
        for (final k in index)
          if (k != key) k,
      ];
      for (final dropped in next.skip(maxChats)) {
        await _store.write(keyOf(dropped), null);
      }
      await _store.write(indexKey, next.take(maxChats).toList());
    } catch (_) {
      // A cache: never fails the chat.
    }
  }

  @override
  Future<void> clear(String key) async {
    try {
      await _store.write(keyOf(key), null);
      final index = await _index();
      if (index.contains(key)) {
        await _store.write(indexKey, [
          for (final k in index)
            if (k != key) k,
        ]);
      }
    } catch (_) {}
  }

  Future<List<String>> _index() async {
    final raw = await _store.read(indexKey);
    return raw is List ? raw.whereType<String>().toList() : <String>[];
  }

  static Map<String, dynamic> _messageToJson(Message m) {
    final json = MessageModel.fromEntity(m).toJson();
    if (json['metadata'] != null) json['metadata'] = jsonSafe(json['metadata']);
    return json;
  }

  static Message? _messageFromJson(Object? raw) {
    if (raw is! Map) return null;
    final json = Map<String, dynamic>.from(raw);
    if (json['metadata'] is Map) {
      json['metadata'] = Map<String, dynamic>.from(
        fromJsonSafe(json['metadata']) as Map,
      );
    }
    return MessageModel.fromJson(json);
  }

  static Map<String, dynamic> _conversationToJson(Conversation c) =>
      ConversationModel(
        conversationId: c.conversationId,
        matchId: c.matchId,
        userId1: c.userId1,
        userId2: c.userId2,
        lastMessageAt: c.lastMessageAt,
        unreadCount: c.unreadCount,
        createdAt: c.createdAt,
      ).toJson();

  static Conversation? _conversationFromJson(Object? raw) {
    if (raw is! Map) return null;
    try {
      final c = ConversationModel.fromJson(Map<String, dynamic>.from(raw));
      return c.conversationId.isEmpty ? null : c;
    } catch (_) {
      return null;
    }
  }

  /// Message metadata as JSON: Firestore values that JSON cannot hold
  /// (Timestamp, GeoPoint) are tagged so [fromJsonSafe] restores them; any
  /// other non-JSON value is dropped.
  static Object? jsonSafe(Object? v) {
    if (v == null || v is String || v is num || v is bool) return v;
    if (v is Timestamp) return {r'$ts': v.microsecondsSinceEpoch};
    if (v is DateTime) return {r'$ts': v.microsecondsSinceEpoch};
    if (v is GeoPoint) {
      return {
        r'$geo': [v.latitude, v.longitude],
      };
    }
    if (v is Map) {
      final out = <String, Object?>{};
      v.forEach((k, val) {
        final safe = jsonSafe(val);
        if (safe != null || val == null) out['$k'] = safe;
      });
      return out;
    }
    if (v is Iterable) {
      return [
        for (final e in v)
          if (jsonSafe(e) case final s?) s,
      ];
    }
    return null;
  }

  static Object? fromJsonSafe(Object? v) {
    if (v is Map) {
      if (v.length == 1 && v[r'$ts'] is num) {
        return Timestamp.fromMicrosecondsSinceEpoch((v[r'$ts'] as num).toInt());
      }
      if (v.length == 1 && v[r'$geo'] is List) {
        final g = v[r'$geo'] as List;
        return GeoPoint((g[0] as num).toDouble(), (g[1] as num).toDouble());
      }
      return <String, dynamic>{
        for (final e in v.entries) '${e.key}': fromJsonSafe(e.value),
      };
    }
    if (v is List) return [for (final e in v) fromJsonSafe(e)];
    return v;
  }
}
