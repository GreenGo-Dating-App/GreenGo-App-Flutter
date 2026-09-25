import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../features/profile/data/models/profile_model.dart';
import '../../features/profile/domain/entities/profile.dart';

/// Lightweight public profile summary used to render names/avatars for user ids
/// (group members, message senders) without storing duplicated name data.
class UserBrief {
  const UserBrief({
    required this.name,
    this.photoUrl,
    this.language,
    this.isActive = true,
  });

  /// Builds a brief from a full profile. This is the ONE place the display
  /// name precedence lives: displayName, else `@nickname`, else '' (never the
  /// uid). Business/storefront names are NOT used here — surfaces that show a
  /// storefront identity read it from the full [Profile].
  factory UserBrief.fromProfile(Profile p) {
    final name = p.displayName.trim().isNotEmpty
        ? p.displayName.trim()
        : (p.nickname != null && p.nickname!.isNotEmpty
            ? '@${p.nickname}'
            : '');
    return UserBrief(
      name: name,
      photoUrl: p.photoUrls.isNotEmpty ? p.photoUrls.first : null,
      language: p.languages.isNotEmpty ? p.languages.first : null,
      isActive: p.accountStatus == 'active' && !p.isBanned,
    );
  }

  /// Placeholder for a user whose profile doc does not exist (deleted).
  static const UserBrief missing = UserBrief(name: '', isActive: false);

  final String name;
  final String? photoUrl;

  /// Primary language (a code like `en`/`pt_BR` or a display name) — used to
  /// show the member's origin flag in group chats. Null when unknown.
  final String? language;

  /// False when the user no longer exists (profile doc deleted) or their
  /// account is not active (deleted/suspended/banned). Callers should HIDE
  /// such users from pickers (e.g. the event-share list).
  final bool isActive;

  Map<String, Object?> _toJson(int fetchedAtMs) => {
        'n': name,
        if (photoUrl != null) 'p': photoUrl,
        if (language != null) 'l': language,
        'a': isActive,
        't': fetchedAtMs,
      };

  static UserBrief _fromJson(Map<String, dynamic> j) => UserBrief(
        name: j['n'] as String? ?? '',
        photoUrl: j['p'] as String?,
        language: j['l'] as String?,
        isActive: j['a'] as bool? ?? true,
      );
}

class _Entry {
  _Entry(this.brief, this.fetchedAtMs, {this.missing = false});
  final UserBrief brief;

  /// Server confirmed the profile doc does not exist.
  final bool missing;

  /// When the SERVER last confirmed this entry. 0 = only seen in the local
  /// Firestore cache (may be stale) → refreshed from the server in background.
  final int fetchedAtMs;
}

/// Resolves user ids → display name + avatar.
///
/// Guarantees:
///  * NEVER returns a uid as a name. Unknown → '' ; callers show nothing (or a
///    skeleton) until [isResolved] is true.
///  * Cache-first: memory → persisted Hive box (survives restarts, bounded
///    LRU) → Firestore LOCAL cache → server. Server reads are batched with
///    `whereIn` on the document id (30 per query, in parallel) and coalesced
///    across callers that ask within the same frame.
///  * At most one server read per unknown uid per [_refreshAfter]: stale
///    entries are still served instantly, then refreshed in the background.
///  * It is a [ChangeNotifier]: widgets can listen and rebuild when late
///    briefs arrive.
class UserDirectoryService extends ChangeNotifier {
  UserDirectoryService._();
  static final UserDirectoryService instance = UserDirectoryService._();

  static const String _boxName = 'user_briefs_v1';
  static const int _maxPersisted = 2000;
  static const int _maxProfiles = 500;
  static const int _chunk = 30; // Firestore `whereIn` limit.
  static const Duration _refreshAfter = Duration(days: 1);

  /// Full profiles are volatile (online dot, lastSeen) — re-check them in the
  /// background when older than this (still served instantly meanwhile).
  static const Duration _profileRefreshAfter = Duration(minutes: 5);

  // LinkedHashMap = insertion order; re-inserting on access gives LRU order.
  final LinkedHashMap<String, _Entry> _cache = LinkedHashMap();
  final LinkedHashMap<String, _ProfileEntry> _profiles = LinkedHashMap();

  /// uids whose profile doc is CONFIRMED missing on the server (deleted).
  /// (Also represented in [_cache] as an inactive brief.)
  final Set<String> _confirmedMissing = {};

  final Map<String, Future<void>> _inflight = {};
  final Set<String> _pendingServer = {};
  Completer<void>? _pendingServerDone;
  Timer? _flushTimer;
  final Set<String> _refreshing = {};

  Box<String>? _box;
  Future<void>? _loading;
  bool _loaded = false;
  bool _notifyScheduled = false;

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  int get _now => DateTime.now().millisecondsSinceEpoch;

  // ---------------------------------------------------------------- sync API

  /// Synchronously returns a cached brief, or null if not yet loaded.
  UserBrief? cached(String uid) {
    _ensureLoadStarted();
    return _cache[uid]?.brief;
  }

  /// True once [uid] has a known brief (found, or confirmed deleted).
  bool isResolved(String uid) {
    _ensureLoadStarted();
    return _cache.containsKey(uid);
  }

  /// True when every uid in [uids] is resolved.
  bool allResolved(Iterable<String> uids) =>
      uids.every((u) => u.isEmpty || isResolved(u));

  /// Display name for [uid]; '' when unknown or nameless. NEVER the uid.
  String nameFor(String uid) => cached(uid)?.name ?? '';

  /// The full profile for [uid] when loaded through [resolveProfiles].
  Profile? cachedProfile(String uid) => _profiles[uid]?.profile;

  /// True when [resolveProfiles] has an answer for [uid]: a profile, or a
  /// server-confirmed "does not exist".
  bool isProfileResolved(String uid) =>
      _profiles.containsKey(uid) || _confirmedMissing.contains(uid);

  /// True when the server confirmed [uid] has no profile document.
  bool isConfirmedMissing(String uid) => _confirmedMissing.contains(uid);

  // --------------------------------------------------------------- async API

  /// Resolves [uid] and returns its display name ('' when unknown).
  Future<String> displayName(String uid) async {
    if (uid.isEmpty) return '';
    final r = await resolve([uid]);
    return r[uid]?.name ?? '';
  }

  /// Returns a brief for every uid in [uids]. Known uids come straight from
  /// memory / the persisted box; unknown ones are read from the Firestore
  /// local cache, then the server (batched). Users that could not be loaded
  /// (deleted, or a network failure) get an inactive, nameless brief — never
  /// their uid.
  Future<Map<String, UserBrief>> resolve(Iterable<String> uids) async {
    final unique = uids.where((u) => u.isNotEmpty).toSet();
    await _ensureLoaded();
    final missing = unique.where((u) => !_cache.containsKey(u)).toList();
    if (missing.isNotEmpty) await _fetch(missing);
    _scheduleStaleRefresh(unique);
    return {
      for (final u in unique) u: _cache[u]?.brief ?? UserBrief.missing,
    };
  }

  /// Full profiles for [uids] (for surfaces that need more than a brief, e.g.
  /// the conversation list's online dot / storefront identity / opening the
  /// chat). Same cache-first + batched path as [resolve]; the result map holds
  /// null for users confirmed deleted and OMITS users that failed to load.
  Future<Map<String, Profile?>> resolveProfiles(Iterable<String> uids) async {
    final unique = uids.where((u) => u.isNotEmpty).toSet();
    await _ensureLoaded();
    final missing = unique.where((u) => !isProfileResolved(u)).toList();
    if (missing.isNotEmpty) await _fetch(missing, wantProfiles: true);
    // Volatile fields: refresh old profiles in the background.
    final now = _now;
    final stale = unique
        .where((u) =>
            _profiles[u] != null &&
            now - _profiles[u]!.fetchedAtMs >
                _profileRefreshAfter.inMilliseconds)
        .toList();
    if (stale.isNotEmpty) _backgroundServer(stale);
    return {
      for (final u in unique)
        if (_profiles.containsKey(u))
          u: _profiles[u]!.profile
        else if (_confirmedMissing.contains(u))
          u: null,
    };
  }

  // ---------------------------------------------------------------- fetching

  /// Loads [uids]: Firestore local cache first, then the server for the rest.
  /// Concurrent requests for the same uid share one fetch.
  Future<void> _fetch(List<String> uids, {bool wantProfiles = false}) async {
    final waits = <Future<void>>[];
    final todo = <String>[];
    for (final u in uids) {
      final f = _inflight[u];
      if (f != null) {
        waits.add(f);
      } else {
        todo.add(u);
      }
    }
    if (todo.isNotEmpty) {
      final f = _load(todo);
      for (final u in todo) {
        _inflight[u] = f;
      }
      waits.add(f.whenComplete(() {
        for (final u in todo) {
          if (identical(_inflight[u], f)) _inflight.remove(u);
        }
      }));
    }
    await Future.wait(waits);
    // A brief can exist (persisted) without a full profile — fetch those too.
    if (wantProfiles) {
      final need = uids.where((u) => !isProfileResolved(u)).toList();
      if (need.isNotEmpty) await _load(need);
    }
  }

  Future<void> _load(List<String> uids, {bool skipLocal = false}) async {
    var remaining = uids;
    if (!skipLocal) {
      // 1) Firestore LOCAL cache — no network, milliseconds.
      final local = await Future.wait(remaining.map((u) async {
        try {
          final snap = await _db
              .collection('profiles')
              .doc(u)
              .get(const GetOptions(source: Source.cache));
          if (snap.exists && snap.data() != null) {
            _store(u, snap.data()!, fromServer: false);
            return null;
          }
        } catch (_) {
          // Not in the local cache.
        }
        return u;
      }));
      final hitLocal = remaining.length - local.whereType<String>().length;
      remaining = local.whereType<String>().toList();
      if (hitLocal > 0) {
        // Local copies may be stale: confirm them with the server, batched.
        _backgroundServer(
            uids.where((u) => !remaining.contains(u)).toList());
      }
    }
    // 2) Server, batched + coalesced.
    if (remaining.isNotEmpty) await _enqueueServer(remaining);
    _notify();
  }

  /// Queues [uids] for the next batched server read (coalesces callers that
  /// ask within ~one frame into shared `whereIn` queries).
  Future<void> _enqueueServer(Iterable<String> uids) {
    _pendingServer.addAll(uids);
    final done = _pendingServerDone ??= Completer<void>();
    _flushTimer ??= Timer(const Duration(milliseconds: 16), _flushServer);
    return done.future;
  }

  Future<void> _flushServer() async {
    _flushTimer = null;
    final ids = _pendingServer.toList();
    _pendingServer.clear();
    final done = _pendingServerDone;
    _pendingServerDone = null;
    try {
      await _serverBatch(ids);
    } finally {
      done?.complete();
    }
  }

  Future<void> _serverBatch(List<String> ids) async {
    if (ids.isEmpty) return;
    final chunks = <List<String>>[
      for (var i = 0; i < ids.length; i += _chunk)
        ids.sublist(i, i + _chunk > ids.length ? ids.length : i + _chunk),
    ];
    await Future.wait(chunks.map((chunk) async {
      try {
        final qs = await _db
            .collection('profiles')
            .where(FieldPath.documentId, whereIn: chunk)
            .get(const GetOptions(source: Source.server));
        final found = <String>{};
        for (final d in qs.docs) {
          found.add(d.id);
          _store(d.id, d.data(), fromServer: true);
        }
        // Absent from a successful server answer = the profile doc does not
        // exist (user deleted). Mark inactive; never expose the uid.
        for (final u in chunk) {
          if (!found.contains(u)) _storeMissing(u);
        }
      } catch (e) {
        // Network/permission failure: leave these unresolved so the next
        // request retries. Callers get a nameless placeholder meanwhile.
        debugPrint('UserDirectoryService: server batch failed ($e)');
      }
    }));
  }

  /// Background server refresh (no await), at most once in flight per uid.
  void _backgroundServer(List<String> uids) {
    final todo = uids.where(_refreshing.add).toList();
    if (todo.isEmpty) return;
    _enqueueServer(todo).whenComplete(() {
      _refreshing.removeAll(todo);
      _notify();
    });
  }

  void _scheduleStaleRefresh(Iterable<String> uids) {
    final cutoff = _now - _refreshAfter.inMilliseconds;
    final stale = uids
        .where((u) => (_cache[u]?.fetchedAtMs ?? cutoff + 1) < cutoff)
        .toList();
    if (stale.isNotEmpty) _backgroundServer(stale);
  }

  void _store(String uid, Map<String, dynamic> data,
      {required bool fromServer}) {
    final UserBrief brief;
    final Profile profile;
    try {
      // Same parsing as ProfileRemoteDataSource.getProfile, so the name
      // precedence and status semantics are identical to before.
      profile = ProfileModel.fromJson({...data, 'userId': uid});
      brief = UserBrief.fromProfile(profile);
    } catch (e) {
      // Malformed doc: previously getProfile threw and the user was treated
      // as missing. Keep that behaviour.
      _storeMissing(uid);
      return;
    }
    final t = fromServer ? _now : 0;
    // Don't let a stale local-cache copy overwrite a fresher server entry.
    final existing = _cache[uid];
    final keepBrief = !fromServer && existing != null && existing.fetchedAtMs > 0;
    if (!keepBrief) {
      _confirmedMissing.remove(uid);
      _put(uid, _Entry(brief, t));
    }
    if (fromServer || !_profiles.containsKey(uid)) {
      _profiles.remove(uid);
      _profiles[uid] = _ProfileEntry(profile, fromServer ? _now : 0);
      while (_profiles.length > _maxProfiles) {
        _profiles.remove(_profiles.keys.first);
      }
    }
  }

  void _storeMissing(String uid) {
    _confirmedMissing.add(uid);
    _profiles.remove(uid);
    _put(uid, _Entry(UserBrief.missing, _now, missing: true));
  }

  void _put(String uid, _Entry e) {
    _cache.remove(uid);
    _cache[uid] = e;
    while (_cache.length > _maxPersisted) {
      _cache.remove(_cache.keys.first);
    }
    _persist(uid, e);
    _notify();
  }

  /// Coalesce listener notifications to one per microtask.
  void _notify() {
    if (_notifyScheduled) return;
    _notifyScheduled = true;
    scheduleMicrotask(() {
      _notifyScheduled = false;
      notifyListeners();
    });
  }

  // ------------------------------------------------------------- persistence

  void _ensureLoadStarted() {
    if (!_loaded) _ensureLoaded();
  }

  Future<void> _ensureLoaded() {
    if (_loaded) return Future.value();
    return _loading ??= () async {
      try {
        // Hive.initFlutter() already ran in CacheService.initialize(). On web
        // the box is IndexedDB; if it is unavailable we run memory-only.
        _box = Hive.isBoxOpen(_boxName)
            ? Hive.box<String>(_boxName)
            : await Hive.openBox<String>(_boxName);
        final rows = <MapEntry<String, _Entry>>[];
        for (final key in _box!.keys) {
          try {
            final raw = _box!.get(key);
            if (raw == null) continue;
            final j = jsonDecode(raw) as Map<String, dynamic>;
            rows.add(MapEntry(key as String,
                _Entry(UserBrief._fromJson(j), (j['t'] as num?)?.toInt() ?? 0,
                    missing: j['m'] == true)));
          } catch (_) {}
        }
        rows.sort((a, b) => a.value.fetchedAtMs.compareTo(b.value.fetchedAtMs));
        for (final r in rows) {
          // Never overwrite something fetched during the load.
          if (!_cache.containsKey(r.key)) {
            _cache[r.key] = r.value;
            if (r.value.missing) _confirmedMissing.add(r.key);
          }
        }
        _trimBox();
      } catch (e) {
        debugPrint('UserDirectoryService: brief box unavailable ($e)');
        _box = null;
      }
      _loaded = true;
      _loading = null;
      _notify();
    }();
  }

  void _persist(String uid, _Entry e) {
    final box = _box;
    // Only server-confirmed entries are persisted: a local-cache read may be
    // stale and is re-confirmed right away anyway.
    if (box == null || e.fetchedAtMs == 0) return;
    try {
      box.put(uid,
          jsonEncode({...e.brief._toJson(e.fetchedAtMs), if (e.missing) 'm': true}));
      if (box.length > _maxPersisted + 200) _trimBox();
    } catch (_) {}
  }

  /// Keeps the persisted box at [_maxPersisted] entries, dropping the ones
  /// least recently confirmed.
  void _trimBox() {
    final box = _box;
    if (box == null || box.length <= _maxPersisted) return;
    try {
      final rows = <MapEntry<dynamic, int>>[];
      for (final key in box.keys) {
        var t = 0;
        try {
          t = ((jsonDecode(box.get(key) ?? '{}') as Map)['t'] as num?)
                  ?.toInt() ??
              0;
        } catch (_) {}
        rows.add(MapEntry(key, t));
      }
      rows.sort((a, b) => a.value.compareTo(b.value));
      final drop = rows.length - _maxPersisted;
      box.deleteAll(rows.take(drop).map((r) => r.key));
    } catch (_) {}
  }
}

class _ProfileEntry {
  _ProfileEntry(this.profile, this.fetchedAtMs);
  final Profile profile;
  final int fetchedAtMs;
}
