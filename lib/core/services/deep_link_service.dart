import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../features/chat/presentation/connect_and_chat.dart';
import '../../features/events/presentation/screens/event_detail_loader_screen.dart';
import '../../generated/app_localizations.dart';
import 'push_notification_service.dart';

/// Handles inbound deep links / universal links for shareable PROFILE and EVENT
/// links, and builds/shares those same links from inside the app.
///
/// Supported link shapes (kept in sync with `web/.well-known/*`,
/// `AndroidManifest.xml` intent-filters and the iOS entitlements / Info.plist):
///   * Profile: `https://greengo-chat.web.app/u/{userId}`  or `greengo://u/{userId}`
///   * Event:   `https://greengo-chat.web.app/e/{eventId}` or `greengo://e/{eventId}`
///
/// Tapping a link opens the app and:
///   * profile -> opens an instant, approval-free chat with that user
///     (via [openConnectChat], which loads the target `Profile` itself);
///   * event   -> opens [EventDetailLoaderScreen] for that event.
///
/// When the app is NOT installed the link is served by Firebase Hosting
/// (`web/u/index.html` / `web/e/index.html`) which bounces to the App Store /
/// Google Play.
///
/// NOTE: Firebase Dynamic Links is DEPRECATED and intentionally NOT used here.
// TODO(deferred-deeplink): There is no deferred deep-linking (opening the exact
// chat/event AFTER a fresh install). That required Firebase Dynamic Links, which
// is deprecated; a custom install-referrer / clipboard bridge would be needed.
class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();
  factory DeepLinkService() => instance;

  /// Public Firebase Hosting domain that serves the shareable links and the
  /// `assetlinks.json` / `apple-app-site-association` verification files.
  static const String linkHost = 'greengo-chat.web.app';
  static const String _customScheme = 'greengo';

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  GlobalKey<NavigatorState> _navigatorKey =
      PushNotificationService.navigatorKey;
  bool _initialized = false;

  /// Canonical shareable HTTPS link for a user profile.
  static String buildProfileLink(String userId) =>
      'https://$linkHost/u/$userId';

  /// Canonical shareable HTTPS link for an event.
  static String buildEventLink(String eventId) =>
      'https://$linkHost/e/$eventId';

  /// Wire up cold-start + warm deep-link handling. Call ONCE from the root app
  /// widget's initState (see main.dart / AuthWrapper). Safe to call repeatedly —
  /// only the first call takes effect.
  Future<void> init({GlobalKey<NavigatorState>? navigatorKey}) async {
    if (_initialized) return;
    _initialized = true;
    if (navigatorKey != null) _navigatorKey = navigatorKey;

    // Warm links (app already running / backgrounded).
    _sub = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (Object err) => debugPrint('DeepLinkService stream error: $err'),
    );

    // Cold start (app launched by tapping the link).
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _handleUri(initial);
    } catch (e) {
      debugPrint('DeepLinkService initial link error: $e');
    }
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    _initialized = false;
  }

  /// Parse a URI into a target, then route to it. Malformed links are ignored.
  void _handleUri(Uri uri) {
    final target = _parse(uri);
    if (target == null) {
      debugPrint('DeepLinkService: ignoring unrecognized link "$uri"');
      return;
    }
    _openWhenReady(target);
  }

  /// Extract a target from either an https universal link or the `greengo://`
  /// custom scheme. Returns null for anything that isn't `/u/{id}` or `/e/{id}`.
  _LinkTarget? _parse(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    final isHttp = scheme == 'http' || scheme == 'https';

    // Only accept OUR host for http(s); accept any host for the custom scheme.
    if (isHttp && uri.host.toLowerCase() != linkHost) return null;
    if (!isHttp && scheme != _customScheme) return null;

    final segments = <String>[];
    // For `greengo://u/{id}` the "u"/"e" lands in uri.host, not the path.
    if (!isHttp && uri.host.isNotEmpty) segments.add(uri.host);
    segments.addAll(uri.pathSegments.where((s) => s.isNotEmpty));

    for (var i = 0; i < segments.length - 1; i++) {
      final kind = segments[i].toLowerCase();
      final id = segments[i + 1].trim();
      if (id.isEmpty) continue;
      if (kind == 'u') return _LinkTarget(_LinkKind.profile, id);
      if (kind == 'e') return _LinkTarget(_LinkKind.event, id);
    }
    return null;
  }

  /// The navigator may not be mounted yet on a cold start — retry briefly until
  /// it is (capped so a malformed launch never loops forever).
  void _openWhenReady(_LinkTarget target, {int attempt = 0}) {
    final navigator = _navigatorKey.currentState;
    final context = _navigatorKey.currentContext;
    if (navigator == null || context == null) {
      if (attempt >= 40) {
        debugPrint('DeepLinkService: navigator never ready for $target');
        return;
      }
      Future<void>.delayed(
        const Duration(milliseconds: 250),
        () => _openWhenReady(target, attempt: attempt + 1),
      );
      return;
    }
    _open(context, target);
  }

  void _open(BuildContext context, _LinkTarget target) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    // Not signed in yet — we can't open a user-scoped chat/event. Ignore (the
    // not-installed / logged-out case is already handled by the web fallback).
    if (currentUserId == null || currentUserId.isEmpty) {
      debugPrint('DeepLinkService: no signed-in user; skipping ${target.id}');
      return;
    }

    if (target.kind == _LinkKind.profile) {
      if (target.id == currentUserId) return; // never open a chat with self
      // openConnectChat loads the target Profile via ProfileRepository and opens
      // an instant, approval-free chat.
      openConnectChat(
        context,
        currentUserId: currentUserId,
        otherUserId: target.id,
      );
    } else {
      Navigator.of(context).push(
        EventDetailLoaderScreen.route(
          eventId: target.id,
          currentUserId: currentUserId,
        ),
      );
    }
  }
}

enum _LinkKind { profile, event }

class _LinkTarget {
  const _LinkTarget(this.kind, this.id);
  final _LinkKind kind;
  final String id;

  @override
  String toString() => '_LinkTarget(${kind.name}, $id)';
}

/// Share a user's profile deep link via the OS share sheet.
///
/// Reusable entry point — the profile detail Share button, and later the
/// own-profile / storefront share actions, all call this.
Future<void> shareProfileLink(BuildContext context, String userId) async {
  final link = DeepLinkService.buildProfileLink(userId);
  final l10n = AppLocalizations.of(context);
  final text = l10n?.shareProfileMessage(link) ??
      'Chat with me on GreenGo: $link';
  await Share.share(text);
}

/// Share an event deep link via the OS share sheet.
Future<void> shareEventLink(BuildContext context, String eventId) async {
  final link = DeepLinkService.buildEventLink(eventId);
  final l10n = AppLocalizations.of(context);
  final text = l10n?.shareEventMessage(link) ??
      'Check out this event on GreenGo: $link';
  await Share.share(text);
}
