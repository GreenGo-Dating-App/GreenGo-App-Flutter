import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/services/translation_service.dart';
import '../../domain/entities/community_message.dart';

/// A community tip in the viewer's language.
@immutable
class TipTranslation {
  const TipTranslation({required this.text, required this.sameLanguage});

  /// The translated text (the original when [sameLanguage]).
  final String text;

  /// The tip already is in the viewer's language: show it as is, no toggle.
  final bool sameLanguage;
}

/// Device cache of tip translations. Keys are hashes, values small JSON.
abstract class TipTranslationStore {
  Future<String?> get(String key);
  Future<void> put(String key, String value);
}

/// In-memory store (tests, or when Hive is unavailable).
class MemoryTipTranslationStore implements TipTranslationStore {
  final Map<String, String> data = {};
  @override
  Future<String?> get(String key) async => data[key];
  @override
  Future<void> put(String key, String value) async => data[key] = value;
}

/// Persistent store: Hive box `community_tip_translations_v1`, bounded.
class HiveTipTranslationStore implements TipTranslationStore {
  static const String boxName = 'community_tip_translations_v1';
  static const int maxEntries = 20000;
  Box<String>? _box;
  bool _failed = false;

  Future<Box<String>?> _open() async {
    if (_failed) return null;
    if (_box != null) return _box;
    try {
      _box = Hive.isBoxOpen(boxName)
          ? Hive.box<String>(boxName)
          : await Hive.openBox<String>(boxName);
      return _box;
    } catch (_) {
      _failed = true; // Hive not initialised (tests) or storage blocked.
      return null;
    }
  }

  @override
  Future<String?> get(String key) async {
    try {
      return (await _open())?.get(key);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> put(String key, String value) async {
    final box = await _open();
    if (box == null) return;
    try {
      if (box.length >= maxEntries) {
        await box.deleteAll(box.keys.take(maxEntries ~/ 5).toList());
      }
      await box.put(key, value);
    } catch (_) {/* best effort */}
  }
}

/// Reads one shared translation `translations/{id}` (null = not stored).
typedef SharedTranslationReader = Future<String?> Function(String id);

/// Calls `translateCommunityTips`; returns the raw `translations` list.
typedef TipTranslateCall = Future<List<dynamic>> Function(
    String communityId, List<String> messageIds, String target);

/// Shows community Tips in the viewer's language (owner request 2026-10-21):
/// every tip is translated ONCE for everyone (server, shared store
/// `translations/{sha256(target \0 text)}`) and then cached on the device, so
/// a device never asks twice for the same tip.
///
/// Layers, cheapest first:
///  1. memory, then the device cache (Hive), keyed on
///     messageId + sha256(content) + target — an edited tip has a new hash;
///  2. the shared store, read directly by id (no function call on a hit);
///  3. `translateCommunityTips` for the misses only: the server reads the tip
///     text itself (the client sends ids, never texts or translations),
///     translates, stores it for everyone and returns it.
///
/// Requests made in the same frame (one visible page of tips) are batched,
/// at most [maxPerCall] ids per callable, and identical in-flight requests
/// are deduplicated.
class CommunityTipTranslator {
  CommunityTipTranslator({
    TipTranslationStore? store,
    SharedTranslationReader? readShared,
    TipTranslateCall? callServer,
  })  : _store = store ?? HiveTipTranslationStore(),
        _readShared = readShared ?? _defaultReadShared,
        _callServer = callServer ?? _defaultCallServer;

  /// The app-wide instance.
  static final CommunityTipTranslator instance = CommunityTipTranslator();

  static const int maxPerCall = 30;

  /// The server truncates tip text to this before hashing (MAX_CHARS).
  static const int maxChars = 5000;

  /// Do not retry a failed tip for this long (server rate-limited / quota).
  static const Duration failureBackoff = Duration(minutes: 5);

  final TipTranslationStore _store;
  final SharedTranslationReader _readShared;
  final TipTranslateCall _callServer;

  final Map<String, TipTranslation> _memory = {};
  final Map<String, Future<TipTranslation?>> _inFlight = {};
  final Map<String, DateTime> _failedAt = {};
  final Map<String, List<_Pending>> _queue = {}; // "communityId|target"
  bool _flushScheduled = false;

  static Future<String?> _defaultReadShared(String id) async {
    final doc =
        await FirebaseFirestore.instance.collection('translations').doc(id).get();
    final v = doc.data()?['translated'];
    return v is String && v.isNotEmpty ? v : null;
  }

  static Future<List<dynamic>> _defaultCallServer(
      String communityId, List<String> messageIds, String target) async {
    final res = await FirebaseFunctions.instance
        .httpsCallable('translateCommunityTips',
            options: HttpsCallableOptions(timeout: const Duration(seconds: 30)))
        .call<Map<String, dynamic>>({
      'communityId': communityId,
      'messageIds': messageIds,
      'target': target,
    });
    return (res.data['translations'] as List?) ?? const [];
  }

  static String _text(String content) =>
      content.length > maxChars ? content.substring(0, maxChars) : content;

  /// sha256 of the tip text, as the server computes it.
  static String contentHash(String content) =>
      sha256.convert(utf8.encode(_text(content))).toString();

  /// Device cache key: messageId + content hash + target (hashed).
  static String cacheKey(String messageId, String hash, String target) =>
      sha256.convert(utf8.encode('$messageId|$hash|$target')).toString();

  /// The translation already in memory (synchronous, for the first build).
  TipTranslation? peek(CommunityMessage tip, String targetLanguage) {
    final target = TranslationService.normalizeLanguage(targetLanguage);
    return _memory[cacheKey(tip.id, contentHash(tip.content), target)];
  }

  /// [tip] in [targetLanguage], or null when it cannot be translated now.
  /// Never throws.
  Future<TipTranslation?> translate(
      CommunityMessage tip, String targetLanguage) {
    if (!tip.isTip || tip.content.trim().isEmpty) return Future.value(null);
    final target = TranslationService.normalizeLanguage(targetLanguage);
    final hash = contentHash(tip.content);
    final key = cacheKey(tip.id, hash, target);
    final hit = _memory[key];
    if (hit != null) return Future.value(hit);
    final failed = _failedAt[key];
    if (failed != null && DateTime.now().difference(failed) < failureBackoff) {
      return Future.value(null);
    }
    return _inFlight[key] ??= _resolve(tip, target, hash, key)
        .whenComplete(() {
      _inFlight.remove(key);
    });
  }

  Future<TipTranslation?> _resolve(
      CommunityMessage tip, String target, String hash, String key) async {
    final cached = await _store.get(key);
    if (cached != null) {
      try {
        final m = jsonDecode(cached) as Map<String, dynamic>;
        final r = TipTranslation(
            text: m['t'] as String, sameLanguage: m['s'] == true);
        _memory[key] = r;
        return r;
      } catch (_) {/* corrupt entry: fetch again */}
    }
    final pending = _Pending(tip, hash, key);
    _queue.putIfAbsent('${tip.communityId}|$target', () => []).add(pending);
    if (!_flushScheduled) {
      _flushScheduled = true;
      // Microtask, not a Timer: every bubble of the visible page asks in the
      // same frame, so they land in one batch.
      scheduleMicrotask(_flush);
    }
    return pending.completer.future;
  }

  Future<void> _flush() async {
    _flushScheduled = false;
    final batches = Map.of(_queue);
    _queue.clear();
    await Future.wait(batches.entries.map((e) {
      final sep = e.key.lastIndexOf('|');
      return _flushOne(e.key.substring(0, sep), e.key.substring(sep + 1), e.value);
    }));
  }

  Future<void> _flushOne(
      String communityId, String target, List<_Pending> items) async {
    // 2) Shared store by id (one small doc each, in parallel).
    final misses = <_Pending>[];
    await Future.wait(items.map((p) async {
      try {
        final text = _text(p.tip.content);
        final v =
            await _readShared(TranslationService.sharedTranslationId(target, text));
        if (v != null) {
          await _done(p, TipTranslation(text: v, sameLanguage: v == text));
          return;
        }
      } catch (_) {/* not readable / offline: ask the server */}
      misses.add(p);
    }));

    // 3) The server, for the misses only, by id, <= maxPerCall per call.
    for (var c = 0; c < misses.length; c += maxPerCall) {
      final chunk = misses.sublist(
          c, c + maxPerCall > misses.length ? misses.length : c + maxPerCall);
      final ids = <String>[];
      for (final p in chunk) {
        if (!ids.contains(p.tip.id)) ids.add(p.tip.id);
      }
      List<dynamic> out = const [];
      try {
        out = await _callServer(communityId, ids, target);
      } catch (e) {
        debugPrint('translateCommunityTips failed: $e');
      }
      final byId = <String, Map>{};
      for (final r in out) {
        if (r is Map && r['messageId'] is String && r['text'] is String) {
          byId[r['messageId'] as String] = r;
        }
      }
      for (final p in chunk) {
        final r = byId[p.tip.id];
        if (r == null) {
          _failedAt[p.key] = DateTime.now();
          p.completer.complete(null);
          continue;
        }
        final t = TipTranslation(
            text: r['text'] as String, sameLanguage: r['sameLanguage'] == true);
        // Cached under the hash of the text the SERVER translated, so an
        // edit made meanwhile is fetched again.
        final serverHash = r['hash'] is String ? r['hash'] as String : p.hash;
        if (serverHash != p.hash) {
          final k = cacheKey(p.tip.id, serverHash, target);
          _memory[k] = t;
          unawaited(_store.put(k, _encode(t)));
        }
        await _done(p, t);
      }
    }
  }

  static String _encode(TipTranslation t) =>
      jsonEncode({'t': t.text, 's': t.sameLanguage});

  Future<void> _done(_Pending p, TipTranslation t) async {
    _memory[p.key] = t;
    p.completer.complete(t);
    await _store.put(p.key, _encode(t));
  }

  @visibleForTesting
  void clearMemory() {
    _memory.clear();
    _failedAt.clear();
  }
}

class _Pending {
  _Pending(this.tip, this.hash, this.key);
  final CommunityMessage tip;
  final String hash;
  final String key;
  final Completer<TipTranslation?> completer = Completer<TipTranslation?>();
}
