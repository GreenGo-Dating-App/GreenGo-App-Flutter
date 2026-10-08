import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// URL of [uid]'s ID-verification selfie for an admin reviewer.
///
/// Security audit C-10 / P1-4: the selfie is no longer referenced by a
/// tokenised download URL on the public profile. New submissions store only
/// its Storage PATH in the owner-only `profiles_private/{uid}`; the
/// `getVerificationPhotoUrl` callable (admin_users moderators) turns it into
/// a short-lived signed URL. [legacyUrl] (older submissions, or a reviewer the
/// callable refuses) is the fallback. Null when there is no photo.
Future<String?> resolveVerificationPhotoUrl(String uid,
    {String? legacyUrl, FirebaseFunctions? functions}) {
  // Memoised for a few minutes (the signed URL lives 10): review cards
  // rebuild often and must not call the function on every frame.
  final hit = _memo[uid];
  if (hit != null && DateTime.now().difference(hit.$1) < _memoTtl) {
    return hit.$2;
  }
  final f = _resolve(uid, legacyUrl: legacyUrl, functions: functions);
  _memo[uid] = (DateTime.now(), f);
  return f;
}

const Duration _memoTtl = Duration(minutes: 5);
final Map<String, (DateTime, Future<String?>)> _memo = {};

Future<String?> _resolve(String uid,
    {String? legacyUrl, FirebaseFunctions? functions}) async {
  try {
    final res = await (functions ?? FirebaseFunctions.instance)
        .httpsCallable('getVerificationPhotoUrl')
        .call<Object?>({'uid': uid}).timeout(const Duration(seconds: 15));
    final data = res.data;
    final url = data is Map ? data['url'] : null;
    if (url is String && url.isNotEmpty) return url;
  } catch (e) {
    debugPrint('[VerificationPhoto] callable unavailable for $uid: $e');
  }
  return (legacyUrl != null && legacyUrl.isNotEmpty) ? legacyUrl : null;
}
