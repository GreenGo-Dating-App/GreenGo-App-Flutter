import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../services/push_notification_service.dart';
import '../../generated/app_localizations.dart';

/// Last-resort screen shown when a widget build throws.
///
/// Flutter's default [ErrorWidget] paints a flat grey rectangle in release
/// builds, which on web is indistinguishable from a blank page — a crash in
/// any post-login screen looked to users like "the app shows a white page"
/// with nothing to report. This replaces that with something a user can act
/// on and a developer can read.
///
/// It deliberately depends on nothing: no GetIt lookup, no Bloc, no inherited
/// widget. The failing build may well be the thing that would have provided
/// them, and a crash screen that itself crashes leaves the blank page behind.
class AppErrorScreen extends StatelessWidget {
  const AppErrorScreen({
    required this.details,
    this.onReload,
    super.key,
  });

  final FlutterErrorDetails details;
  final VoidCallback? onReload;

  /// Localized text where a live context can supply it, English otherwise.
  /// Localization itself can be part of what failed, so every lookup falls
  /// back to a literal rather than propagating a null.
  static AppLocalizations? get _l10n {
    try {
      final ctx = PushNotificationService.navigatorKey.currentContext;
      return ctx == null ? null : AppLocalizations.of(ctx);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: AppColors.deepBlack,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.richGold, size: 56),
                  const SizedBox(height: 20),
                  Text(
                    l10n?.errorScreenTitle ?? 'Something went wrong',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.richGold,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n?.errorScreenBody ??
                        'This screen could not be opened. Reload the app to '
                            'try again — your account is not affected.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 15),
                  ),
                  const SizedBox(height: 24),
                  // The exception text is what makes a crash reportable at all.
                  // Shown in debug and profile builds; release users get the
                  // message above, and Crashlytics gets the full details.
                  if (!kReleaseMode) ...[
                    Container(
                      constraints: const BoxConstraints(maxWidth: 560),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.charcoal,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: SelectableText(
                        details.exceptionAsString(),
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (onReload != null)
                    SizedBox(
                      width: 240,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.richGold,
                          foregroundColor: AppColors.deepBlack,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: onReload,
                        child: Text(
                          l10n?.errorScreenReload ?? 'Reload',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
