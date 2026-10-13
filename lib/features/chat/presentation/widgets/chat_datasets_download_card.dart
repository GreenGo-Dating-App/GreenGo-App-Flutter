import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/chat_datasets/chat_datasets.dart';
import '../../../../generated/app_localizations.dart';

/// First use of the app, ONCE: downloads every chat dataset (ice-breakers,
/// sentences, cultural tips, keywords, word lists, quotes) into the device
/// cache behind a centred, blocking window with the percentage. The user
/// waits until it completes. Later starts read everything from the cache
/// (no window). If something fails the window says so, the user continues,
/// and the download runs again at the next start.
class ChatDatasetsFirstRun {
  ChatDatasetsFirstRun._();

  static const String doneKey = 'chat_datasets_first_download_done';
  static bool _running = false;

  static Future<void> maybeStart(BuildContext context, {ChatDatasets? datasets}) async {
    if (_running) return;
    final ds = datasets ?? ChatDatasets.instance;
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(doneKey) == true) {
        ds.preloadAll(); // already downloaded once: warm up from the cache
        return;
      }
    } catch (_) {/* no prefs: still download, just without remembering it */}
    if (!context.mounted) return;
    _running = true;
    final progress = ValueNotifier<(double, bool?)>((0, null));
    final dialog = showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => PopScope(
        canPop: false,
        child: ChatDatasetsDownloadDialog(progress: progress),
      ),
    );
    try {
      final ok = await ds.preloadAll(onProgress: (f) => progress.value = (f, null));
      if (ok) {
        await prefs?.setBool(doneKey, true);
        progress.value = (1, true);
        await Future<void>.delayed(const Duration(milliseconds: 900));
        if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      } else {
        progress.value = (progress.value.$1, false); // the user closes it
      }
      await dialog;
    } finally {
      progress.dispose();
      _running = false;
    }
  }
}

/// The centred window: title, "only once" note, big percentage, bar.
/// `progress` = (fraction, result): result null while downloading, true when
/// ready, false when some files failed (then an OK button closes it).
class ChatDatasetsDownloadDialog extends StatelessWidget {
  const ChatDatasetsDownloadDialog({super.key, required this.progress});

  final ValueListenable<(double, bool?)> progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      key: const ValueKey('chat-datasets-download-dialog'),
      backgroundColor: AppColors.charcoal,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.richGold, width: 1.2),
      ),
      content: ValueListenableBuilder<(double, bool?)>(
        valueListenable: progress,
        builder: (context, p, _) {
          final (fraction, result) = p;
          final percent = (fraction * 100).floor().clamp(0, 100);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                result == true
                    ? Icons.check_circle
                    : result == false
                        ? Icons.cloud_off_outlined
                        : Icons.cloud_download_outlined,
                color: AppColors.richGold,
                size: 44,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.chatDatasetsDownloadTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                result == false ? l10n.chatDatasetsRetryLater : l10n.chatDatasetsDownloadOnce,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5, height: 1.35),
              ),
              if (result != false) ...[
                const SizedBox(height: 18),
                Text(
                  result == true ? l10n.chatDatasetsReady : l10n.chatDatasetsDownloadingPercent(percent),
                  key: const ValueKey('chat-datasets-download-percent'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.richGold, fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: result == true ? 1 : fraction,
                    minHeight: 8,
                    color: AppColors.richGold,
                    backgroundColor: AppColors.backgroundDark,
                  ),
                ),
              ],
            ],
          );
        },
      ),
      actions: [
        ValueListenableBuilder<(double, bool?)>(
          valueListenable: progress,
          builder: (context, p, _) => p.$2 == false
              ? TextButton(
                  onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                  child: Text(l10n.ok),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
