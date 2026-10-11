import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/legal_versions.dart';

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

  /// Local mirror of the legal-document version the server stored for
  /// [type] (terms / privacy). Lets the legal-update gate skip its server
  /// read once the current version is known to be accepted.
  static String localDocKey(String uid, String type) =>
      'consent_doc_${type}_$uid';

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
        await _writeLocal(uid, type, accepted, accepted ? docVersion : null);
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

  /// The legal-document version last accepted from this device for [type]
  /// by the signed-in user (see [localDocKey]), or null.
  Future<String?> localDocVersion(String type) async {
    final uid = _currentUid();
    if (uid == null) return null;
    try {
      return (await SharedPreferences.getInstance())
          .getString(localDocKey(uid, type));
    } catch (_) {
      return null;
    }
  }

  /// Mirrors a server-confirmed accepted [docVersion] locally (used by the
  /// legal-update gate after it read the server record).
  Future<void> rememberDocVersion(String type, String docVersion) async {
    final uid = _currentUid();
    if (uid == null) return;
    try {
      await (await SharedPreferences.getInstance())
          .setString(localDocKey(uid, type), docVersion);
    } catch (_) {}
  }

  Future<void> _writeLocal(
      String uid, String type, bool accepted, String? docVersion) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(localKey(uid, type), accepted);
      if (docVersion != null) {
        await prefs.setString(localDocKey(uid, type), docVersion);
      }
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
    String termsDocVersion = kTermsVersion,
    String privacyDocVersion = kPrivacyPolicyVersion,
  }) async {
    await Future.wait([
      record(type: ConsentTypes.terms, accepted: true, docVersion: termsDocVersion, retries: 1),
      record(type: ConsentTypes.privacy, accepted: true, docVersion: privacyDocVersion, retries: 1),
      record(type: ConsentTypes.profiling, accepted: profiling, retries: 1),
      record(type: ConsentTypes.thirdPartyData, accepted: thirdPartyData, retries: 1),
      record(type: ConsentTypes.marketingEmail, accepted: marketingEmail, retries: 1),
    ]);
  }

  /// Acceptance of updated Terms / Privacy Policy (the legal-update sheet).
  /// The server stamps the time (`recordConsent` writes a server timestamp);
  /// the client only sends the document versions. True when BOTH records
  /// were stored. Never throws.
  Future<bool> recordLegalUpdateAcceptance({
    String termsDocVersion = kTermsVersion,
    String privacyDocVersion = kPrivacyPolicyVersion,
  }) async {
    final results = await Future.wait([
      record(type: ConsentTypes.terms, accepted: true, docVersion: termsDocVersion, retries: 1),
      record(type: ConsentTypes.privacy, accepted: true, docVersion: privacyDocVersion, retries: 1),
    ]);
    return results.every((ok) => ok);
  }
}
