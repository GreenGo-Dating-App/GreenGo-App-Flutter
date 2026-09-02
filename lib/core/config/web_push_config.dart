import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Web Push (FCM on web) configuration.
///
/// The VAPID public key authorizes the browser to receive FCM web push. It is a
/// **public** value (safe to ship in the client) — generate it once in the
/// Firebase Console:
///   Project settings → Cloud Messaging → Web configuration →
///   "Web Push certificates" → Generate key pair → copy the public key.
///
/// Two sources, in order:
///  1. `--dart-define=WEB_PUSH_VAPID_KEY=…` at build time.
///  2. Firestore `app_config/web_push.vapidPublicKey`.
///
/// The Firestore fallback exists so the key can be added (or rotated) without
/// rebuilding and redeploying the web app — paste it into the doc and the next
/// page load picks it up. Same pattern as the Cloud TTS key in
/// `app_config/api_keys`.
///
/// Until one of the two is set, web push token retrieval is skipped gracefully
/// (see [NotificationRemoteDataSource.getFCMToken]) so the web build still
/// runs; only web push delivery stays inactive.
class WebPushConfig {
  const WebPushConfig._();

  /// Public VAPID key baked in at build time. Empty when not passed.
  static const String _buildTimeKey = String.fromEnvironment(
    'WEB_PUSH_VAPID_KEY',
    defaultValue: '',
  );

  static String? _resolved;

  /// Resolve the VAPID key, preferring the build-time define.
  ///
  /// Cached after the first successful lookup — this runs on every token
  /// fetch and must not hit Firestore each time.
  static Future<String?> resolveVapidKey() async {
    if (_buildTimeKey.isNotEmpty) return _buildTimeKey;
    if (_resolved != null) return _resolved!.isEmpty ? null : _resolved;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('web_push')
          .get();
      final key = doc.data()?['vapidPublicKey'] as String?;
      _resolved = key ?? '';
    } catch (e) {
      debugPrint('[FCM] Failed to read VAPID key from app_config/web_push: $e');
      // Leave unresolved so a transient failure retries on the next call.
      return null;
    }

    return _resolved!.isEmpty ? null : _resolved;
  }

  /// Whether a key was baked in at build time. Callers that need the real
  /// answer (including the Firestore fallback) should await [resolveVapidKey].
  static bool get isConfigured => _buildTimeKey.isNotEmpty;
}
