import 'package:flutter/material.dart';

import '../../generated/app_localizations.dart';
import '../constants/app_colors.dart';
import '../web/ios_install_detector.dart';
import 'ios_install_hint.dart';

/// Which instructions the web "notifications are off" popup shows.
enum WebNotificationHelp {
  /// Any desktop / Android browser: site permission next to the address bar.
  browser,

  /// iPhone / iPad home-screen web app: the iOS Settings app.
  iosInstalled,

  /// iPhone / iPad browser tab: web push needs the home-screen web app first.
  iosNotInstalled,
}

/// Overridable in tests.
WebNotificationHelp Function() webNotificationHelpKind = () {
  if (isIosBrowserNotInstalled()) return WebNotificationHelp.iosNotInstalled;
  if (isIosWebDevice()) return WebNotificationHelp.iosInstalled;
  return WebNotificationHelp.browser;
};

/// Web only. A web page cannot open the browser's or the phone's settings,
/// and once notifications are blocked the browser never asks again, so
/// instead of an "Open Settings" button this popup explains where to switch
/// notifications back on.
Future<void> showWebNotificationHelpDialog(BuildContext context) {
  final kind = webNotificationHelpKind();
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      final l10n = AppLocalizations.of(ctx)!;
      final body = switch (kind) {
        WebNotificationHelp.iosNotInstalled => l10n.notificationWebIosInstallBody,
        WebNotificationHelp.iosInstalled =>
          '${l10n.notificationWebBlockedBody}\n\n${l10n.notificationWebStepsIos}',
        WebNotificationHelp.browser =>
          '${l10n.notificationWebBlockedBody}\n\n${l10n.notificationWebStepsBrowser}',
      };
      return AlertDialog(
        key: const ValueKey('web-notification-help'),
        backgroundColor: AppColors.charcoal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.richGold, width: 1.5),
        ),
        title: Text(
          l10n.notificationDialogTitle,
          style: const TextStyle(color: AppColors.richGold, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Text(body, style: const TextStyle(color: AppColors.textSecondary, height: 1.4)),
        ),
        actions: [
          if (kind == WebNotificationHelp.iosNotInstalled) ...[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.notificationDialogNotNow,
                  style: const TextStyle(color: AppColors.textTertiary)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                openIosInstallGuide(context);
              },
              child: Text(l10n.notificationWebHowToInstall,
                  style: const TextStyle(color: AppColors.richGold, fontWeight: FontWeight.bold)),
            ),
          ] else
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.ok,
                  style: const TextStyle(color: AppColors.richGold, fontWeight: FontWeight.bold)),
            ),
        ],
      );
    },
  );
}
