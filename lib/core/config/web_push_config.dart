/// Web Push (FCM on web) configuration.
///
/// The VAPID public key authorizes the browser to receive FCM web push. It is a
/// **public** value (safe to ship in the client) — generate it once in the
/// Firebase Console:
///   Project settings → Cloud Messaging → Web configuration →
///   "Web Push certificates" → Generate key pair → copy the public key here.
///
/// Until it is filled in, web push token retrieval is skipped gracefully (see
/// [NotificationRemoteDataSource.getFCMToken]) so the web build still runs;
/// only web push delivery stays inactive.
class WebPushConfig {
  const WebPushConfig._();

  /// Public VAPID key. Empty = web push disabled (paste the key to enable).
  static const String vapidPublicKey = String.fromEnvironment(
    'WEB_PUSH_VAPID_KEY',
    defaultValue: '',
  );

  /// Whether a VAPID key has been configured.
  static bool get isConfigured => vapidPublicKey.isNotEmpty;
}
