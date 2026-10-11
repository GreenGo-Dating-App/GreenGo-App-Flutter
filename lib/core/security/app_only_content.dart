import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../generated/app_localizations.dart';

/// Content that is NOT viewable in the web build at all: other people's
/// private photos, ID / age verification. A browser cannot block screenshots
/// (see `ScreenSecurityService`), the mobile apps can, so these stay
/// app-only and the web shows "Open in the GreenGo app to view" instead.
///
/// [isWeb] is only overridden by tests.
bool isAppOnlyContentBlocked({bool? isWeb}) => isWeb ?? kIsWeb;

/// Device router on the marketing site: sends phones to their store / the
/// installed app, desktops to the download page.
final Uri kOpenInAppUri = Uri.parse('https://greengochat.com/app');

/// Full-screen replacement for an app-only screen on web.
class AppOnlyContentScreen extends StatelessWidget {
  const AppOnlyContentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const AppOnlyContentNotice(),
    );
  }
}

/// "Open in the GreenGo app to view" + a button to the app.
class AppOnlyContentNotice extends StatelessWidget {
  const AppOnlyContentNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.phone_iphone_rounded, size: 56),
            const SizedBox(height: 16),
            Text(
              l10n.screenProtectionAppOnlyTitle,
              key: const ValueKey('appOnlyTitle'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.screenProtectionAppOnlyBody,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => launchUrl(
                kOpenInAppUri,
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.open_in_new_rounded),
              label: Text(l10n.screenProtectionOpenApp),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows the app-only notice as a bottom sheet (for actions that open a
/// sheet/viewer instead of a route, e.g. "view shared private album").
Future<void> showAppOnlyContentSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (_) => const SafeArea(child: AppOnlyContentNotice()),
  );
}
