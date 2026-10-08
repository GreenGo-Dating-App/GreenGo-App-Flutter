import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The user's decision about sending content to third-party AI services
/// (Google Gemini, Cloud Text-to-Speech, Cloud Translation): Apple 5.1.2(i),
/// EU AI Act art. 50, audit H-17.
enum AiConsentStatus { unknown, granted, declined }

/// Where the decision is kept on this device (per user).
abstract class AiConsentStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class SharedPrefsAiConsentStore implements AiConsentStore {
  @override
  Future<String?> read(String key) async =>
      (await SharedPreferences.getInstance()).getString(key);

  @override
  Future<void> write(String key, String value) async =>
      (await SharedPreferences.getInstance()).setString(key, value);
}

/// Sends the decision to the server (`recordConsent` callable). Throws on
/// failure; the service then retries on the next [AiConsentService.load].
typedef AiConsentRecorder = Future<void> Function(
    {required bool accepted, required int version});

Future<void> _recordOnServer({required bool accepted, required int version}) async {
  await FirebaseFunctions.instance
      .httpsCallable('recordConsent',
          options: HttpsCallableOptions(timeout: const Duration(seconds: 20)))
      .call<Map<String, dynamic>>({
    'type': 'ai_processing',
    'version': version,
    'accepted': accepted,
    'locale': PlatformDispatcher.instance.locale.toLanguageTag(),
    'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
  });
}

/// Reads the server record (`consents/{uid}.ai_processing`, readable only by
/// its owner): true = accepted, false = withdrawn ("AI services" OFF), null =
/// no usable record. Throws when the record cannot be read (offline, or the
/// rules that allow the owner to read it are not deployed yet).
typedef AiConsentServerReader = Future<bool?> Function(String uid);

Future<bool?> _readFromServer(String uid) async {
  final snap = await FirebaseFirestore.instance
      .collection('consents')
      .doc(uid)
      .get()
      .timeout(const Duration(seconds: 8));
  final c = snap.data()?['ai_processing'];
  if (c is! Map) return null;
  if (c['accepted'] == false) return false;
  final v = c['version'];
  if (c['accepted'] == true && v is num && v >= AiConsentService.currentVersion) {
    return true;
  }
  return null;
}

/// One-time AI-processing consent, kept locally (per signed-in user) and
/// recorded server-side in `consents/{uid}` (the AI callables refuse to run
/// without the server record). The user can turn AI services on or off at any
/// time in Profile > Account settings (`AiServicesSettingsCard`); every change
/// is a new `recordConsent` event (timestamped history on the server).
///
/// [status] is synchronous so hot paths (every chat bubble) can check it
/// without awaiting; call [load] once after sign-in (it is also called lazily
/// by [ensureLoaded]).
class AiConsentService {
  AiConsentService({
    AiConsentStore? store,
    AiConsentRecorder? recorder,
    String? Function()? currentUid,
    AiConsentServerReader? serverReader,
  })  : _store = store ?? SharedPrefsAiConsentStore(),
        _recorder = recorder ?? _recordOnServer,
        _serverReader = serverReader ?? _readFromServer,
        _currentUid = currentUid ?? (() => FirebaseAuth.instance.currentUser?.uid);

  static AiConsentService instance = AiConsentService();

  /// Bump when the consent text changes materially: everyone is asked again.
  static const int currentVersion = 1;

  final AiConsentStore _store;
  final AiConsentRecorder _recorder;
  final AiConsentServerReader _serverReader;
  final String? Function() _currentUid;

  /// Listen to react when the user decides (e.g. translate pending bubbles).
  final ValueNotifier<AiConsentStatus> statusListenable =
      ValueNotifier(AiConsentStatus.unknown);

  String? _loadedFor;
  bool _pendingSync = false;
  // Bumped by every local decision, so a slower server read started before
  // it cannot overwrite it.
  int _decisionGen = 0;
  Future<void>? _loading;

  /// Whether the consent sheet was already shown (and dismissed without a
  /// decision) in this app session, so screens don't nag on every open.
  bool promptedThisSession = false;

  AiConsentStatus get status {
    final uid = _currentUid();
    if (uid == null || uid != _loadedFor) return AiConsentStatus.unknown;
    return statusListenable.value;
  }

  bool get isGranted => status == AiConsentStatus.granted;

  static String _key(String uid) => 'ai_consent_$uid';

  /// Loads the decision of the signed-in user; re-sends it to the server if an
  /// earlier send failed.
  Future<void> load() async {
    final uid = _currentUid();
    if (uid == null) {
      _loadedFor = null;
      statusListenable.value = AiConsentStatus.unknown;
      return;
    }
    var next = AiConsentStatus.unknown;
    var pending = false;
    try {
      final raw = await _store.read(_key(uid));
      if (raw != null) {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        final v = (m['v'] as num?)?.toInt() ?? 0;
        if (v >= currentVersion) {
          next = m['a'] == true ? AiConsentStatus.granted : AiConsentStatus.declined;
          pending = m['s'] != true;
        }
      }
    } catch (e) {
      debugPrint('AiConsentService: load failed: $e');
    }
    if (uid != _loadedFor) promptedThisSession = false;
    _loadedFor = uid;
    _pendingSync = pending;
    statusListenable.value = next;
    if (_pendingSync && next != AiConsentStatus.unknown) {
      unawaited(_sync(uid, next == AiConsentStatus.granted));
    } else {
      // The choice may have changed on another device (the "AI services"
      // switch): the server record wins over this device's synced copy.
      unawaited(refreshFromServer());
    }
  }

  /// Aligns this device with the server record (the source of truth the AI
  /// callables check). A local decision that was not sent yet is newer and is
  /// kept. Returns the status after the refresh. Never throws.
  Future<AiConsentStatus> refreshFromServer() async {
    final uid = _currentUid();
    if (uid == null) return AiConsentStatus.unknown;
    if (_pendingSync && uid == _loadedFor) return status;
    final gen = _decisionGen;
    final bool? server;
    try {
      server = await _serverReader(uid);
    } catch (e) {
      debugPrint('AiConsentService: server read failed: $e');
      return status;
    }
    if (uid != _currentUid() || gen != _decisionGen || (_pendingSync && uid == _loadedFor)) {
      return status;
    }
    final next = server == null
        ? AiConsentStatus.unknown
        : (server ? AiConsentStatus.granted : AiConsentStatus.declined);
    _loadedFor = uid;
    if (statusListenable.value != next) {
      statusListenable.value = next;
      if (next == AiConsentStatus.unknown) {
        await _clearLocal(uid);
      } else {
        await _writeLocal(uid, next == AiConsentStatus.granted, synced: true);
      }
    }
    return next;
  }

  /// [load] once per signed-in user.
  Future<void> ensureLoaded() {
    final uid = _currentUid();
    if (uid != null && uid == _loadedFor) return Future.value();
    return _loading ??= load().whenComplete(() => _loading = null);
  }

  /// Records the user's decision locally (immediately) and on the server.
  /// Returns false when the server could not be reached (it is retried).
  Future<bool> setDecision({required bool accepted}) async {
    final uid = _currentUid();
    if (uid == null) return false;
    _decisionGen++;
    _loadedFor = uid;
    statusListenable.value =
        accepted ? AiConsentStatus.granted : AiConsentStatus.declined;
    await _writeLocal(uid, accepted, synced: false);
    return _sync(uid, accepted);
  }

  /// The server answered AI_CONSENT_REQUIRED although this device says
  /// "granted" (e.g. the first send failed): send it again. True when the
  /// caller may retry its AI request. If the server record says the user
  /// turned AI services OFF (e.g. on another device), that choice is adopted
  /// here and nothing is re-sent: a withdrawal is never overridden silently.
  Future<bool> resyncAfterServerRejection() async {
    final uid = _currentUid();
    if (uid == null || !isGranted) return false;
    if (!_pendingSync) {
      bool? server;
      try {
        server = await _serverReader(uid);
      } catch (_) {
        server = null; // unreadable: behave as before (re-send)
      }
      if (server == false) {
        statusListenable.value = AiConsentStatus.declined;
        await _writeLocal(uid, false, synced: true);
        return false;
      }
    }
    return _sync(uid, true);
  }

  Future<bool> _sync(String uid, bool accepted) async {
    try {
      await _recorder(accepted: accepted, version: currentVersion);
      _pendingSync = false;
      await _writeLocal(uid, accepted, synced: true);
      return true;
    } catch (e) {
      _pendingSync = true;
      debugPrint('AiConsentService: server record failed (will retry): $e');
      return false;
    }
  }

  Future<void> _writeLocal(String uid, bool accepted, {required bool synced}) async {
    try {
      await _store.write(
          _key(uid), jsonEncode({'v': currentVersion, 'a': accepted, 's': synced}));
    } catch (e) {
      debugPrint('AiConsentService: local write failed: $e');
    }
  }

  Future<void> _clearLocal(String uid) async {
    try {
      await _store.write(_key(uid), '{}');
    } catch (e) {
      debugPrint('AiConsentService: local clear failed: $e');
    }
  }

  /// True while the latest decision made on this device has not reached
  /// the server yet (it is retried on the next [load]).
  bool get hasUnsyncedDecision => _pendingSync;

  @visibleForTesting
  bool get pendingSync => _pendingSync;
}

/// True when a callable failed because the server has no accepted consent.
bool isAiConsentRequiredError(Object e) {
  if (e is FirebaseFunctionsException) {
    final d = e.details;
    if (d is Map && (d['code'] == 'AI_CONSENT_REQUIRED' || d['reason'] == 'AI_CONSENT_REQUIRED')) {
      return true;
    }
  }
  return false;
}
