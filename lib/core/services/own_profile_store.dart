import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../features/profile/data/models/profile_model.dart';
import '../../features/profile/domain/entities/profile.dart';

/// The signed-in user's own `profiles/{uid}` document, shared app-wide.
///
/// WHY: the own profile used to be read from the server ~10 times per session
/// (auth check, shell, coin shop, membership, leaderboard, ...), each one a
/// network round trip, while the shell already keeps a live listener on the
/// very same document. That listener now [publish]es every snapshot here, so
/// any screen can get the current profile in microseconds.
///
/// How to use it (other screens):
///  * Need it right now, synchronously (build, a tap handler):
///    `OwnProfileStore.instance.peek(uid)` - null until the first snapshot.
///  * Need it, and may wait a moment the first time:
///    `await OwnProfileStore.instance.current(uid)` - returns the cached value
///    immediately when there is one, otherwise does ONE shared read (Firestore
///    default source: server, falling back to the local cache offline).
///  * Must be fresh from the server (right after a purchase / entitlement
///    grant): `await OwnProfileStore.instance.current(uid, forceServer: true)`.
///  * Rebuild on change: listen to [profile] (a ValueNotifier) - e.g.
///    `ValueListenableBuilder<Profile?>(valueListenable: OwnProfileStore.instance.profile, ...)`.
///  * Raw fields not on [Profile] (e.g. `signupGrantsApplied` maps): [raw].
///
/// Values are per user: [peek]/[current] never return another account's
/// profile, and [reset] runs on sign-out.
class OwnProfileStore {
  OwnProfileStore._();

  static final OwnProfileStore instance = OwnProfileStore._();

  /// The current own profile (null before the first snapshot / after sign-out).
  final ValueNotifier<Profile?> profile = ValueNotifier<Profile?>(null);

  String? _uid;
  Map<String, dynamic>? _raw;
  bool _live = false;
  bool _fromServer = false;
  Future<Profile?>? _inflight;

  /// The user the stored value belongs to.
  String? get uid => _uid;

  /// The raw document data last seen for [uid] (read-only view).
  Map<String, dynamic>? get raw =>
      _raw == null ? null : Map<String, dynamic>.unmodifiable(_raw!);

  /// True while a live listener (the main shell) is feeding this store and the
  /// last snapshot came from the server: the value is as fresh as a server
  /// read would be.
  bool get isLive => _live && _fromServer;

  /// The stored profile for [userId], or null. Never blocks.
  Profile? peek(String userId) =>
      (userId.isNotEmpty && userId == _uid) ? profile.value : null;

  /// The stored profile for [userId] only when it is live-fresh (see
  /// [isLive]); otherwise null. Used where a server read used to be forced.
  Profile? peekLive(String userId) => isLive ? peek(userId) : null;

  /// Feed a snapshot from the live listener on `profiles/{userId}`.
  void publish(String userId, Map<String, dynamic> data,
      {bool fromServer = true}) {
    _store(userId, data, fromServer: fromServer);
    if (userId == _uid) _live = true;
  }

  /// Feed a one-shot read (not a listener), e.g. AuthWrapper's server check.
  /// Does not mark the store live.
  void seed(String userId, Map<String, dynamic> data,
      {bool fromServer = true}) {
    // A live listener is authoritative; a one-shot read that lands after it
    // may be older, so it must not overwrite the listener's value.
    if (_live && userId == _uid) return;
    _store(userId, data, fromServer: fromServer);
  }

  void _store(String userId, Map<String, dynamic> data,
      {required bool fromServer}) {
    if (userId.isEmpty) return;
    final parsed = _parse(userId, data);
    if (parsed == null) return;
    if (_uid != userId) _live = false;
    _uid = userId;
    _raw = Map<String, dynamic>.from(data);
    _fromServer = fromServer;
    profile.value = parsed;
  }

  /// The live listener for [userId] stopped (shell disposed). The value is
  /// kept as "last known" but is no longer treated as live-fresh.
  void detach(String userId) {
    if (userId == _uid) _live = false;
  }

  /// Forget everything (sign-out).
  void reset() {
    _uid = null;
    _raw = null;
    _live = false;
    _fromServer = false;
    _inflight = null;
    profile.value = null;
  }

  /// The own profile: the stored value immediately when there is one,
  /// otherwise a single shared read. With [forceServer] it always reads the
  /// server (falls back to the stored value if the server can't be reached).
  /// Returns null when the profile doesn't exist or can't be read.
  Future<Profile?> current(String userId, {bool forceServer = false}) {
    if (userId.isEmpty) return Future.value();
    if (!forceServer) {
      final hit = peek(userId);
      if (hit != null) return Future.value(hit);
    }
    final running = _inflight;
    if (running != null && !forceServer) return running;
    final read = _read(userId, forceServer: forceServer);
    if (!forceServer) {
      _inflight = read;
      read.whenComplete(() {
        if (identical(_inflight, read)) _inflight = null;
      });
    }
    return read;
  }

  Future<Profile?> _read(String userId, {required bool forceServer}) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(userId)
          .get(forceServer ? const GetOptions(source: Source.server) : null);
      final data = doc.data();
      if (data == null) return null;
      seed(userId, data, fromServer: !doc.metadata.isFromCache);
      return _parse(userId, data);
    } catch (e) {
      debugPrint('[OwnProfileStore] read failed for $userId: $e');
      return peek(userId);
    }
  }

  static Profile? _parse(String userId, Map<String, dynamic> data) {
    try {
      return ProfileModel.fromJson({...data, 'userId': userId});
    } catch (e) {
      debugPrint('[OwnProfileStore] could not parse profile $userId: $e');
      return null;
    }
  }
}
