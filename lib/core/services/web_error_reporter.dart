import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Web has no Crashlytics: a page that fails to build just turns grey and the
/// error is lost. This writes uncaught errors (truncated message + stack, app
/// version, uid) to the write-only `client_errors` collection so they can be
/// diagnosed. At most [_maxPerSession] reports per page load, duplicates
/// skipped. No-op on mobile (Crashlytics covers it) and when signed out.
class WebErrorReporter {
  WebErrorReporter._();

  static const int _maxPerSession = 8;
  static int _sent = 0;
  static final Set<String> _seen = {};
  static String? _version;

  static Future<void> report(Object error, StackTrace? stack) async {
    if (!kIsWeb || _sent >= _maxPerSession) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final msg = error.toString();
    final key = msg.length > 120 ? msg.substring(0, 120) : msg;
    if (!_seen.add(key)) return;
    _sent++;
    try {
      _version ??= await PackageInfo.fromPlatform()
          .then((p) => '${p.version}+${p.buildNumber}')
          .catchError((Object _) => '?');
      final st = (stack ?? StackTrace.current).toString();
      await FirebaseFirestore.instance.collection('client_errors').add({
        'v': _version,
        'at': FieldValue.serverTimestamp(),
        'uid': uid,
        'platform': 'web',
        'msg': msg.length > 900 ? msg.substring(0, 900) : msg,
        'stack': st.length > 3800 ? st.substring(0, 3800) : st,
        'url': Uri.base.path,
      });
    } catch (_) {/* never let reporting fail the app */}
  }
}
