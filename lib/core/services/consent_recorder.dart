import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Consent types the server's `recordConsent` callable accepts
/// (functions/src/ai/aiGateway.ts). Kept as constants so a typo cannot
/// silently create an unknown type the server rejects.
class ConsentTypes {
  const ConsentTypes._();
  static const String idVerification = 'id_verification';
  static const String analytics = 'analytics';
  static const String marketingEmail = 'marketing_email';
  static const String marketingPush = 'marketing_push';
  static const String terms = 'terms';
  static const String privacy = 'privacy';
  static const String profiling = 'profiling';
  static const String thirdPartyData = 'third_party_data';
}

/// Sends one consent decision to the server. Throws on failure.
typedef ConsentCallable = Future<void> Function(Map<String, dynamic> payload);

Future<void> _callRecordConsent(Map<String, dynamic> payload) async {
  await FirebaseFunctions.instance
      .httpsCallable('recordConsent',
          options: HttpsCallableOptions(timeout: const Duration(seconds: 20)))
      .call<dynamic>(payload);
}

/// Records consent decisions server-side (`consents/{uid}` + `events`
/// history) through the `recordConsent` callable, and mirrors the latest
/// decision locally (per user) so settings screens can show it: the server
/// record is not readable by the client.
class ConsentRecorder {
  ConsentRecorder({ConsentCallable? callable, String? Function()? currentUid})
      : _callable = callable ?? _callRecordConsent,
        _currentUid =
            currentUid ?? (() => FirebaseAuth.instance.currentUser?.uid);

  static ConsentRecorder instance = ConsentRecorder();

  final ConsentCallable _callable;
  final String? Function() _currentUid;

  static String localKey(String uid, String type) => 'consent_${type}_$uid';

  /// Builds the wire payload (exposed for tests).
  static Map<String, dynamic> payload({
    required String type,
    required bool accepted,
    int version = 1,
    String? docVersion,
    String? region,
  }) {
    return {
      'type': type,
      'version': version,
      'accepted': accepted,
      'locale': PlatformDispatcher.instance.locale.toLanguageTag(),
      'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
      if (docVersion != null) 'docVersion': docVersion,
      if (region != null) 'region': region,
    };
  }

  /// Records [type]. Returns true when the server stored it. Never throws.
  /// [retries] extra attempts are made on failure (short back-off).
  Future<bool> record({
    required String type,
    required bool accepted,
    int version = 1,
    String? docVersion,
    String? region,
    int retries = 0,
  }) async {
    final uid = _currentUid();
    if (uid == null) return false;
    final data = payload(
      type: type,
      accepted: accepted,
      version: version,
      docVersion: docVersion,
      region: region,
    );
    for (var attempt = 0; attempt <= retries; attempt++) {
      try {
        await _callable(data);
        // Mirror only what the server actually stored.
        await _writeLocal(uid, type, accepted);
        return true;
      } catch (e) {
        debugPrint('ConsentRecorder: $type attempt ${attempt + 1} failed: $e');
        if (attempt < retries) {
          await Future<void>.delayed(Duration(seconds: 2 * (attempt + 1)));
        }
      }
    }
    return false;
  }

  /// The last decision recorded from this device for the signed-in user, or
  /// null when none.
  Future<bool?> localDecision(String type) async {
    final uid = _currentUid();
    if (uid == null) return null;
    try {
      return (await SharedPreferences.getInstance()).getBool(localKey(uid, type));
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeLocal(String uid, String type, bool accepted) async {
    try {
      await (await SharedPreferences.getInstance())
          .setBool(localKey(uid, type), accepted);
    } catch (e) {
      debugPrint('ConsentRecorder: local write failed: $e');
    }
  }

  /// Signup records (P2-5(d)): terms + privacy acceptance and the optional
  /// choices actually made on the form. Fire-and-forget from the caller's
  /// point of view: never throws and never blocks signup.
  Future<void> recordSignupConsents({
    required bool profiling,
    required bool thirdPartyData,
    required bool marketingEmail,
    String docVersion = '1.0',
  }) async {
    await Future.wait([
      record(type: ConsentTypes.terms, accepted: true, docVersion: docVersion, retries: 1),
      record(type: ConsentTypes.privacy, accepted: true, docVersion: docVersion, retries: 1),
      record(type: ConsentTypes.profiling, accepted: profiling, retries: 1),
      record(type: ConsentTypes.thirdPartyData, accepted: thirdPartyData, retries: 1),
      record(type: ConsentTypes.marketingEmail, accepted: marketingEmail, retries: 1),
    ]);
  }
}
