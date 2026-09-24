import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// "Show what you saw last time, then refresh" for Firestore-backed screens.
///
/// WHY NOT a plain `Source.cache` query: the Firestore disk cache holds
/// whatever documents any earlier query happened to fetch, so running a
/// query against it returns a partial, arbitrary mix. That's why the old
/// cache-first pass (`SessionCacheGate`, now disabled) painted wrong or
/// partial lists.
///
/// Instead, after every successful SERVER load a screen records the ordered
/// document ids it rendered ([saveIds]). On the next open it paints exactly
/// those documents, read by id from the local Firestore cache ([loadDocs]),
/// which takes milliseconds and needs no network. Then it runs its normal
/// server query and replaces the list.
///
/// Rules for callers:
///  * Only ever paint a NON-EMPTY cached result. An empty cache never shows
///    an empty state; keep the skeleton instead.
///  * Always follow a cached paint with the server load, and let that replace
///    the list (it may add, remove or reorder items).
///  * Keys are per signed-in user automatically, so accounts never see each
///    other's data.
///  * Entries older than [maxAge] are ignored.
///
/// For non-document data (e.g. a small JSON summary) use [saveJson] and
/// [loadJson].
class LastResultCache {
  LastResultCache._();

  static const String _boxName = 'last_results_v1';
  static const Duration defaultMaxAge = Duration(days: 7);

  /// Hard cap on ids stored per key, so no screen can bloat the box.
  static const int maxIds = 200;

  static Box<String>? _box;
  static Future<Box<String>?>? _opening;

  static Future<Box<String>?> _open() {
    if (_box != null) return Future.value(_box);
    return _opening ??= () async {
      try {
        // Hive.initFlutter() already ran in CacheService.initialize().
        _box = Hive.isBoxOpen(_boxName)
            ? Hive.box<String>(_boxName)
            : await Hive.openBox<String>(_boxName);
      } catch (e) {
        debugPrint('LastResultCache: box unavailable ($e)');
        _box = null;
      }
      _opening = null;
      return _box;
    }();
  }

  static String _scoped(String key) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anon';
    return '$uid::$key';
  }

  /// Remember the ordered ids a screen just rendered from the SERVER.
  static Future<void> saveIds(String key, Iterable<String> ids) async {
    final list = ids.where((id) => id.isNotEmpty).take(maxIds).toList();
    await _write(key, {'ids': list});
  }

  /// Remember a small JSON-encodable value (counts, summaries).
  static Future<void> saveJson(String key, Object? value) =>
      _write(key, {'v': value});

  static Future<void> _write(String key, Map<String, Object?> body) async {
    final box = await _open();
    if (box == null) return;
    try {
      await box.put(
        _scoped(key),
        jsonEncode({...body, 't': DateTime.now().millisecondsSinceEpoch}),
      );
    } catch (e) {
      debugPrint('LastResultCache: write failed for $key ($e)');
    }
  }

  static Future<Map<String, dynamic>?> _read(
      String key, Duration maxAge) async {
    final box = await _open();
    final raw = box?.get(_scoped(key));
    if (raw == null) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final t = (m['t'] as num?)?.toInt() ?? 0;
      if (DateTime.now().millisecondsSinceEpoch - t > maxAge.inMilliseconds) {
        return null;
      }
      return m;
    } catch (_) {
      return null;
    }
  }

  /// The ids saved for [key], or empty.
  static Future<List<String>> loadIds(String key,
      {Duration maxAge = defaultMaxAge}) async {
    final m = await _read(key, maxAge);
    return (m?['ids'] as List?)?.whereType<String>().toList() ?? const [];
  }

  static Future<Object?> loadJson(String key,
      {Duration maxAge = defaultMaxAge}) async {
    final m = await _read(key, maxAge);
    return m?['v'];
  }

  /// The documents last rendered under [key], read by id from the LOCAL cache
  /// only (no network), in the saved order. Documents that are no longer in
  /// the cache are skipped. Returns empty if nothing usable is cached.
  static Future<List<DocumentSnapshot<Map<String, dynamic>>>> loadDocs(
    String key,
    CollectionReference<Map<String, dynamic>> collection, {
    Duration maxAge = defaultMaxAge,
  }) async {
    final ids = await loadIds(key, maxAge: maxAge);
    if (ids.isEmpty) return const [];
    final snaps = await Future.wait(ids.map((id) async {
      try {
        final s = await collection
            .doc(id)
            .get(const GetOptions(source: Source.cache));
        return s.exists ? s : null;
      } catch (_) {
        return null; // not in the local cache
      }
    }));
    return snaps.whereType<DocumentSnapshot<Map<String, dynamic>>>().toList();
  }

  /// Forget everything (sign-out).
  static Future<void> clear() async {
    final box = await _open();
    try {
      await box?.clear();
    } catch (_) {}
  }
}
