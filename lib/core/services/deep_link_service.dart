import '../../features/ticket_payments/presentation/screens/get_paid_screen.dart';
import '../../features/ticket_payments/presentation/screens/ticket_order_screen.dart';
import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../../features/communities/domain/repositories/communities_repository.dart';
import '../../features/communities/presentation/bloc/communities_bloc.dart';
import '../../features/communities/presentation/screens/community_detail_screen.dart';
import '../../features/discovery/presentation/open_user_profile.dart';
import '../../features/events/presentation/screens/event_detail_loader_screen.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/profile/presentation/bloc/profile_event.dart';
import '../../generated/app_localizations.dart';
import '../di/injection_container.dart' as di;
import 'push_notification_service.dart';

/// Handles inbound deep links / universal links for shareable PROFILE, EVENT
/// and COMMUNITY links, and builds/shares those same links from inside the app.
///
/// Supported link shapes (kept in sync with `web/.well-known/*`,
/// `AndroidManifest.xml` intent-filters and the iOS entitlements / Info.plist):
///   * Profile: `https://greengo-chat.web.app/u/{userId}`  or `greengo://u/{userId}`
///   * Event:   `https://greengo-chat.web.app/e/{eventId}` or `greengo://e/{eventId}`
///   * Community: `https://greengo-chat.web.app/c/{communityId}` or `greengo://c/{communityId}`
///
/// Tapping a link opens the app and:
///   * profile -> opens that user's profile ("profile first", via
///     [openUserProfile], which loads the target `Profile` and skips blocked
///     users); the chat is one tap away in the profile's app bar;
///   * event   -> opens [EventDetailLoaderScreen] for that event;
///   * community -> opens [CommunityDetailScreen] for that community.
///
/// Profile, event and community links are all rendered by the `sharePreview`
/// Cloud Function (Hosting rewrites) so WhatsApp / Telegram / Instagram show a
/// preview card with the real name/title, description and photo (a profile's
/// MAIN photo). When the app is NOT installed that page bounces to the store;
/// desktop browsers are sent to the web app as `/?link=/u/{id}`, which
/// [captureWebLaunchLink] picks up.
///
/// Links that arrive before the user is signed in / before the home shell
/// (MainNavigationScreen) is up are kept PENDING and opened by [attachHome] -
/// otherwise the post-login `pushAndRemoveUntil(home)` would wipe the pushed
/// screen (cold start) or the link would be dropped (web, signed out).
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

  /// A link that could not be opened yet (signed out / home not mounted).
  DeepLinkTarget? _pending;

  /// The signed-in home shells currently mounted (see [attachHome]). A set,
  /// not a flag: on restart the new shell attaches before the old disposes.
  final Set<Object> _homeShells = <Object>{};
  bool get _homeAttached => _homeShells.isNotEmpty;
  bool _webLaunchCaptured = false;

  /// Canonical shareable HTTPS link for a user profile.
  static String buildProfileLink(String userId) =>
      'https://$linkHost/u/${Uri.encodeComponent(userId.trim())}';

  /// Canonical shareable HTTPS link for an event.
  static String buildEventLink(String eventId) =>
      'https://$linkHost/e/${Uri.encodeComponent(eventId.trim())}';

  /// Canonical shareable HTTPS link for a community.
  static String buildCommunityLink(String communityId) =>
      'https://$linkHost/c/${Uri.encodeComponent(communityId.trim())}';

  /// The web app reads `?link=/u/{id}` (set by the share page for desktop
  /// browsers) or a direct `/u/{id}` path from the page URL. Captured once per
  /// page load; opened after sign-in by [attachHome].
  void captureWebLaunchLink([Uri? launchUri]) {
    if (_webLaunchCaptured) return;
    _webLaunchCaptured = true;
    final target = parse(launchUri ?? Uri.base);
    if (target != null) _pending = target;
  }

  /// Called by the signed-in home shell ([owner] = its State) once it has
  /// painted. Opens any pending link on top of it.
  void attachHome(Object owner) {
    _homeShells.add(owner);
    if (kIsWeb) captureWebLaunchLink();
    final target = _pending;
    if (target == null) return;
    _pending = null;
    _openWhenReady(target);
  }

  /// Called when the home shell is disposed (sign-out, restart).
  void detachHome(Object owner) {
    _homeShells.remove(owner);
  }

  /// The link waiting for the home shell, if any.
  @visibleForTesting
  DeepLinkTarget? get pendingTarget => _pending;

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
    final target = parse(uri);
    if (target == null) {
      debugPrint('DeepLinkService: ignoring unrecognized link "$uri"');
      return;
    }
    if (!_homeAttached) {
      // Cold start / signed out: open once the home shell is up.
      _pending = target;
      return;
    }
    _openWhenReady(target);
  }

  static final RegExp _idPattern = RegExp(r'^[A-Za-z0-9_-]{1,128}$');

  /// Extract a target from an https universal link, the `greengo://` custom
  /// scheme, or the web app's `?link=/u/{id}` hand-off. Returns null for
  /// anything that isn't `/u/{id}`, `/e/{id}` or `/c/{id}` with a well-formed
  /// id.
  static DeepLinkTarget? parse(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    final isHttp = scheme == 'http' || scheme == 'https';

    // Only accept OUR host for http(s) (plus localhost for web dev); accept
    // any host for the custom scheme.
    final host = uri.host.toLowerCase();
    if (isHttp && host != linkHost && host != 'localhost') return null;
    if (!isHttp && scheme != _customScheme) return null;

    // Web hand-off: https://greengo-chat.web.app/?link=%2Fu%2F{id}
    if (isHttp) {
      final handOff = uri.queryParameters['link'];
      if (handOff != null && handOff.startsWith('/')) {
        final inner = Uri.tryParse(handOff);
        if (inner != null) {
          final t = _fromSegments(inner.pathSegments);
          if (t != null) return t;
        }
      }
    }

    final segments = <String>[];
    // For `greengo://u/{id}` the "u"/"e" lands in uri.host, not the path.
    if (!isHttp && uri.host.isNotEmpty) segments.add(uri.host);
    segments.addAll(uri.pathSegments);
    return _fromSegments(segments);
  }

  static DeepLinkTarget? _fromSegments(List<String> raw) {
    final segments = raw.where((s) => s.isNotEmpty).toList();
    for (var i = 0; i < segments.length - 1; i++) {
      final kind = segments[i].toLowerCase();
      final id = segments[i + 1].trim();
      if (!_idPattern.hasMatch(id)) continue;
      if (kind == 'u') return DeepLinkTarget(DeepLinkKind.profile, id);
      if (kind == 'e') return DeepLinkTarget(DeepLinkKind.event, id);
      if (kind == 'c') return DeepLinkTarget(DeepLinkKind.community, id);
      // Ticket order (checkout return page) and "Get paid" (onboarding return).
      if (kind == 't') return DeepLinkTarget(DeepLinkKind.ticketOrder, id);
      if (kind == 'pay') return DeepLinkTarget(DeepLinkKind.getPaid, id);
    }
    return null;
  }

  /// The navigator may not be mounted yet on a cold start — retry briefly until
  /// it is (capped so a malformed launch never loops forever).
  void _openWhenReady(DeepLinkTarget target, {int attempt = 0}) {
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

  void _open(BuildContext context, DeepLinkTarget target) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    // Not signed in yet — keep it until the home shell attaches after login.
    if (currentUserId == null || currentUserId.isEmpty) {
      _pending = target;
      return;
    }

    if (target.kind == DeepLinkKind.profile) {
      if (target.id == currentUserId) return; // own link: nothing to open
      // "Profile first": open the person's profile; the chat is started from
      // its app bar (with the normal connect gates).
      openUserProfile(
        context,
        currentUserId: currentUserId,
        userId: target.id,
      );
    } else if (target.kind == DeepLinkKind.community) {
      _openCommunity(context, target.id, currentUserId);
    } else if (target.kind == DeepLinkKind.ticketOrder) {
      Navigator.of(context).push(TicketOrderScreen.route(target.id));
    } else if (target.kind == DeepLinkKind.getPaid) {
      Navigator.of(context).push(GetPaidScreen.route(currentUserId));
    } else {
      Navigator.of(context).push(
        EventDetailLoaderScreen.route(
          eventId: target.id,
          currentUserId: currentUserId,
        ),
      );
    }
  }

  /// Load the community, then open its detail screen with the blocs it needs.
  /// A missing/deleted community is ignored.
  Future<void> _openCommunity(
      BuildContext context, String communityId, String currentUserId) async {
    final navigator = Navigator.of(context);
    try {
      final result =
          await di.sl<CommunitiesRepository>().getCommunityById(communityId);
      final community = result.fold((_) => null, (c) => c);
      if (community == null) return;
      await navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider<CommunitiesBloc>(
                create: (_) => di.sl<CommunitiesBloc>(),
              ),
              BlocProvider<ProfileBloc>(
                create: (_) => di.sl<ProfileBloc>()
                  ..add(ProfileLoadRequested(userId: currentUserId)),
              ),
            ],
            child: CommunityDetailScreen(community: community),
          ),
        ),
      );
    } catch (e) {
      debugPrint('DeepLinkService: could not open community $communityId: $e');
    }
  }
}

enum DeepLinkKind { profile, event, community, ticketOrder, getPaid }

@immutable
class DeepLinkTarget {
  const DeepLinkTarget(this.kind, this.id);
  final DeepLinkKind kind;
  final String id;

  @override
  bool operator ==(Object other) =>
      other is DeepLinkTarget && other.kind == kind && other.id == id;

  @override
  int get hashCode => Object.hash(kind, id);

  @override
  String toString() => 'DeepLinkTarget(${kind.name}, $id)';
}

/// Share-sheet anchor for iPad (UIActivityViewController is a popover there
/// and share_plus REJECTS the call without a non-empty origin inside the
/// view). Pass the tapped button's context.
Rect? _shareOrigin(BuildContext context) {
  if (!context.mounted) return null;
  try {
    final box = context.findRenderObject();
    if (box is RenderBox && box.hasSize && box.attached) {
      final origin = box.localToGlobal(Offset.zero) & box.size;
      if (!origin.isEmpty) return origin;
    }
    final size = MediaQuery.maybeSizeOf(context);
    if (size == null || size.isEmpty) return null;
    return Rect.fromLTWH(size.width / 2, size.height / 2, 1, 1);
  } catch (_) {
    return null; // e.g. a sheet's context that is already being torn down
  }
}

/// Desktop browsers mostly lack the Web Share API (share_plus then throws or
/// opens a mailto: draft), so on web only phones/tablets use the native sheet.
bool get _webCanUseNativeShare =>
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;

/// Open the OS share sheet with [text]; when that is not possible (desktop
/// web, no share target, platform error) copy [link] to the clipboard and say
/// so. Never throws.
Future<void> shareLinkText(
  BuildContext context, {
  required String text,
  required String link,
  String? subject,
}) async {
  final messenger = context.mounted ? ScaffoldMessenger.maybeOf(context) : null;
  final copiedLabel = (context.mounted
          ? AppLocalizations.of(context)?.shareLinkCopied
          : null) ??
      'Link copied';
  final origin = _shareOrigin(context);

  if (!kIsWeb || _webCanUseNativeShare) {
    try {
      await Share.share(text, subject: subject, sharePositionOrigin: origin);
      return;
    } catch (e) {
      debugPrint('shareLinkText: native share failed, copying instead: $e');
    }
  }
  try {
    await Clipboard.setData(ClipboardData(text: link));
    messenger?.showSnackBar(SnackBar(content: Text(copiedLabel)));
  } catch (e) {
    debugPrint('shareLinkText: clipboard failed: $e');
  }
}

/// The text that accompanies a shared profile link. Your own profile reads
/// "Chat with me..."; someone else's names them.
String profileShareText({
  required String link,
  required bool isSelf,
  String? displayName,
  AppLocalizations? l10n,
}) {
  final name = displayName?.trim() ?? '';
  if (isSelf || name.isEmpty) {
    return l10n?.shareProfileMessage(link) ?? 'Chat with me on GreenGo: $link';
  }
  return l10n?.shareOtherProfileMessage(name, link) ??
      'Meet $name on GreenGo: $link';
}

/// Share a user's profile deep link via the OS share sheet (clipboard on
/// desktop web). The link unfurls into a card with the profile's main photo,
/// name and a short bio (rendered by the `sharePreview` function).
///
/// Reusable entry point — the profile detail Share button and the storefront
/// share action call this. Pass the BUTTON's context (iPad popover anchor).
Future<void> shareProfileLink(
  BuildContext context,
  String userId, {
  String? displayName,
}) async {
  if (userId.trim().isEmpty) return;
  final link = DeepLinkService.buildProfileLink(userId);
  final isSelf = FirebaseAuth.instance.currentUser?.uid == userId;
  final text = profileShareText(
    link: link,
    isSelf: isSelf,
    displayName: displayName,
    l10n: AppLocalizations.of(context),
  );
  final name = displayName?.trim() ?? '';
  await shareLinkText(
    context,
    text: text,
    link: link,
    subject: name.isNotEmpty ? name : null,
  );
}

/// Share an event deep link via the OS share sheet. The message leads with the
/// event's title; the link itself unfurls into a preview card (title,
/// description, photo) in WhatsApp / Telegram / Instagram.
Future<void> shareEventLink(BuildContext context, String eventId,
    {String? title}) async {
  final link = DeepLinkService.buildEventLink(eventId);
  final l10n = AppLocalizations.of(context);
  final t = title?.trim() ?? '';
  final text = t.isNotEmpty
      ? (l10n?.shareEventMessageTitled(t, link) ??
          '$t\nCheck out this event on GreenGo: $link')
      : (l10n?.shareEventMessage(link) ??
          'Check out this event on GreenGo: $link');
  await shareLinkText(context,
      text: text, link: link, subject: t.isNotEmpty ? t : null);
}

/// Share a community deep link via the OS share sheet (same preview card as
/// events).
Future<void> shareCommunityLink(BuildContext context, String communityId,
    {required String name}) async {
  final link = DeepLinkService.buildCommunityLink(communityId);
  final l10n = AppLocalizations.of(context);
  final n = name.trim();
  final text = l10n?.shareCommunityMessage(n, link) ??
      '$n\nJoin this community on GreenGo: $link';
  await shareLinkText(context,
      text: text, link: link, subject: n.isNotEmpty ? n : null);
}
