import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Regional strong age assurance (P3-1, audit H-21).
///
/// When `app_config/feature_flags.ageAssuranceEnforced` is on, users in the
/// configured regions (BR, GB, US-TX by default; decided SERVER-side by
/// `getAgeAssuranceStatus`) need an approved ID verification, an accepted
/// store age signal or an admin override before they can use people discovery
/// and start private 1:1 conversations. Everything else keeps working.
///
/// This class is the app-side half (UX only): the server refuses the
/// coin-priced discovery / direct-message features and scheduled first
/// messages, and the Firestore rules of the later lockdown wave enforce the
/// rest (docs/security/age-assurance-rules.md). Every method here fails OPEN:
/// a network blip must never lock someone out of the app.
enum AgeAssuranceMethod { idVerification, storeSignal, adminOverride }

AgeAssuranceMethod? _parseMethod(Object? v) {
  switch (v) {
    case 'id_verification':
      return AgeAssuranceMethod.idVerification;
    case 'store_signal':
      return AgeAssuranceMethod.storeSignal;
    case 'admin_override':
      return AgeAssuranceMethod.adminOverride;
  }
  return null;
}

/// Which client platform is asking (drives the options the gate shows).
enum AgeAssurancePlatform { android, ios, web, other }

@immutable
class AgeAssuranceStatus {
  const AgeAssuranceStatus({
    required this.enforced,
    required this.required,
    required this.satisfied,
    this.satisfiedBy = const [],
    this.methods = const [
      AgeAssuranceMethod.idVerification,
      AgeAssuranceMethod.storeSignal,
    ],
  });

  /// Flag off, or nothing known: nobody is gated.
  const AgeAssuranceStatus.notRequired()
      : enforced = false,
        required = false,
        satisfied = false,
        satisfiedBy = const [],
        methods = const [];

  factory AgeAssuranceStatus.fromMap(Map<String, dynamic> m) {
    List<AgeAssuranceMethod> list(Object? v) => v is List
        ? v.map(_parseMethod).whereType<AgeAssuranceMethod>().toList()
        : const [];
    return AgeAssuranceStatus(
      enforced: m['enforced'] == true,
      required: m['required'] == true,
      satisfied: m['satisfied'] == true,
      satisfiedBy: list(m['satisfiedBy']),
      methods: list(m['methods']),
    );
  }

  final bool enforced;
  final bool required;
  final bool satisfied;
  final List<AgeAssuranceMethod> satisfiedBy;
  final List<AgeAssuranceMethod> methods;

  /// Discovery and NEW private messages are closed for this user.
  bool get blocked => required && !satisfied;

  /// The options the gate screen offers on [platform]: the store signal only
  /// where a store exists (no store on the web), ID verification everywhere.
  List<AgeAssuranceMethod> optionsFor(AgeAssurancePlatform platform) {
    final offered = methods.isEmpty
        ? const [AgeAssuranceMethod.idVerification, AgeAssuranceMethod.storeSignal]
        : methods;
    final hasStore = platform == AgeAssurancePlatform.android ||
        platform == AgeAssurancePlatform.ios;
    return [
      if (hasStore && offered.contains(AgeAssuranceMethod.storeSignal))
        AgeAssuranceMethod.storeSignal,
      if (offered.contains(AgeAssuranceMethod.idVerification))
        AgeAssuranceMethod.idVerification,
    ];
  }
}

/// Outcome of a store age-signal check.
enum StoreSignalOutcome { accepted, notAccepted, unavailable, underage }

AgeAssurancePlatform currentAgeAssurancePlatform() {
  if (kIsWeb) return AgeAssurancePlatform.web;
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return AgeAssurancePlatform.android;
    case TargetPlatform.iOS:
      return AgeAssurancePlatform.ios;
    default:
      return AgeAssurancePlatform.other;
  }
}

/// Signature of the flag read, injectable for tests.
typedef AgeAssuranceFlagReader = Future<bool> Function();

/// Signature of the status callable, injectable for tests.
typedef AgeAssuranceStatusFetcher = Future<Map<String, dynamic>> Function(
    Map<String, dynamic> hints);

class AgeAssuranceService {
  AgeAssuranceService({
    AgeAssuranceFlagReader? readFlag,
    AgeAssuranceStatusFetcher? fetchStatus,
    Duration ttl = const Duration(minutes: 10),
  })  : _readFlag = readFlag ?? _defaultReadFlag,
        _fetchStatus = fetchStatus ?? _defaultFetchStatus,
        _ttl = ttl;

  /// Shared instance used by screens and data sources.
  static AgeAssuranceService instance = AgeAssuranceService();

  static const MethodChannel channel =
      MethodChannel('com.greengochat.greengochatapp/age_signals');

  final AgeAssuranceFlagReader _readFlag;
  final AgeAssuranceStatusFetcher _fetchStatus;
  final Duration _ttl;

  AgeAssuranceStatus? _cached;
  DateTime? _cachedAt;
  String? _cachedUid;
  Future<AgeAssuranceStatus>? _inFlight;

  static Future<bool> _defaultReadFlag() async {
    final snap =
        await FirebaseFirestore.instance.doc('app_config/feature_flags').get();
    final d = snap.data() ?? const <String, dynamic>{};
    final flags = d['flags'];
    return d['ageAssuranceEnforced'] == true ||
        (flags is Map && flags['ageAssuranceEnforced'] == true);
  }

  static Future<Map<String, dynamic>> _defaultFetchStatus(
      Map<String, dynamic> hints) async {
    final r = await FirebaseFunctions.instance
        .httpsCallable('getAgeAssuranceStatus')
        .call<dynamic>(hints);
    return Map<String, dynamic>.from(r.data as Map);
  }

  /// Device hints the server may use when the profile has no country.
  static Map<String, dynamic> deviceHints() {
    final cc = PlatformDispatcher.instance.locale.countryCode;
    return {if (cc != null && cc.isNotEmpty) 'localeCountry': cc};
  }

  /// Forget the cached status (after a verification, sign-out, ...).
  void invalidate() {
    _cached = null;
    _cachedAt = null;
    _inFlight = null;
  }

  /// Current status, cached for [_ttl] per signed-in user. Never throws.
  Future<AgeAssuranceStatus> status({bool refresh = false}) {
    final uid = _uid();
    if (!refresh &&
        _cached != null &&
        _cachedUid == uid &&
        _cachedAt != null &&
        DateTime.now().difference(_cachedAt!) < _ttl) {
      return Future.value(_cached);
    }
    if (!refresh && _inFlight != null) return _inFlight!;
    final f = _load(uid);
    _inFlight = f;
    return f;
  }

  String? _uid() {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null; // tests / no Firebase app
    }
  }

  Future<AgeAssuranceStatus> _load(String? uid) async {
    var result = const AgeAssuranceStatus.notRequired();
    var cache = true;
    try {
      // Cheap first: one document read. Flag off -> nobody is gated and the
      // callable is never invoked.
      if (await _readFlag()) {
        result = AgeAssuranceStatus.fromMap(await _fetchStatus(deviceHints()));
      }
    } catch (e) {
      debugPrint('[AgeAssurance] status failed (fail open): $e');
      cache = false;
    }
    if (cache) {
      _cached = result;
      _cachedAt = DateTime.now();
      _cachedUid = uid;
    }
    _inFlight = null;
    return result;
  }

  /// True when discovery / new private messages are closed right now.
  Future<bool> isBlocked() async => (await status()).blocked;

  /// Whether [uid] has already written in [conversationId] (such
  /// conversations stay usable). Fails open.
  Future<bool> hasWrittenIn(String conversationId, String uid) async {
    try {
      final q = await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .where('senderId', isEqualTo: uid)
          .limit(1)
          .get();
      return q.docs.isNotEmpty;
    } catch (e) {
      debugPrint('[AgeAssurance] hasWrittenIn failed (fail open): $e');
      return true;
    }
  }

  /// Reads the store age signal on the device (Play Age Signals / Apple
  /// Declared Age Range) and records it server-side. The server decides
  /// whether it is strong enough.
  Future<StoreSignalOutcome> checkStoreSignal() async {
    final platform = currentAgeAssurancePlatform();
    if (platform != AgeAssurancePlatform.android &&
        platform != AgeAssurancePlatform.ios) {
      return StoreSignalOutcome.unavailable;
    }
    Map<String, dynamic> signal;
    try {
      final raw = await channel.invokeMethod<dynamic>('checkAgeSignals');
      signal = raw is Map ? Map<String, dynamic>.from(raw) : const {};
    } catch (e) {
      debugPrint('[AgeAssurance] store signal unavailable: $e');
      return StoreSignalOutcome.unavailable;
    }
    if (signal['available'] != true) return StoreSignalOutcome.unavailable;
    try {
      final r = await FirebaseFunctions.instance
          .httpsCallable('recordStoreAgeSignal')
          .call<dynamic>({
        'platform': platform == AgeAssurancePlatform.android ? 'android' : 'ios',
        'shared': signal['shared'] != false,
        'ageLower': signal['ageLower'],
        'ageUpper': signal['ageUpper'],
        'ageRangeSource': signal['ageRangeSource'],
        'declaration': signal['declaration'],
        'installId': signal['installId'],
      });
      final data = Map<String, dynamic>.from(r.data as Map);
      invalidate();
      if (data['reason'] == 'UNDER_18') return StoreSignalOutcome.underage;
      return data['accepted'] == true
          ? StoreSignalOutcome.accepted
          : StoreSignalOutcome.notAccepted;
    } catch (e) {
      debugPrint('[AgeAssurance] recordStoreAgeSignal failed: $e');
      return StoreSignalOutcome.unavailable;
    }
  }
}

/// Thrown by the chat data source when a new conversation / first message is
/// attempted while age assurance is required and missing.
class AgeAssuranceRequiredException implements Exception {
  const AgeAssuranceRequiredException();
  @override
  String toString() => 'AgeAssuranceRequiredException: age-assurance-required';
}
