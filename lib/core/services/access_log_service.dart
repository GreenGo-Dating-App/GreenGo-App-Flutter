import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Records an application access (Marco Civil da Internet art. 15, legal
/// audit BR-09) through the `logAccess` callable: the SERVER takes the IP
/// address and time from the request and keeps them for 6 months in the
/// server-only `access_logs` collection. Nothing is stored on the device.
///
/// Called once per signed-in app start (`app_session`) and after an actual
/// sign-in (`sign_in`). Fire-and-forget: it never throws and never delays the
/// UI; a failure only loses one log line.
class AccessLogService {
  AccessLogService._();

  /// The callable (overridable in tests).
  @visibleForTesting
  static Future<void> Function(Map<String, dynamic> payload) call =
      _callServer;

  static Future<void> _callServer(Map<String, dynamic> payload) async {
    await FirebaseFunctions.instance
        .httpsCallable('logAccess',
            options: HttpsCallableOptions(timeout: const Duration(seconds: 15)))
        .call<Map<String, dynamic>>(payload);
  }

  static String get _platform =>
      kIsWeb ? 'web' : defaultTargetPlatform.name;

  /// Logs one access. [signIn]: true right after credentials / social login.
  static void log({required bool signIn}) {
    unawaited(_send(signIn: signIn));
  }

  @visibleForTesting
  static Future<void> send({required bool signIn}) => _send(signIn: signIn);

  static Future<void> _send({required bool signIn}) async {
    try {
      await call({
        'event': signIn ? 'sign_in' : 'app_session',
        'platform': _platform,
      });
    } catch (e) {
      debugPrint('AccessLogService: logAccess failed: $e');
    }
  }
}
