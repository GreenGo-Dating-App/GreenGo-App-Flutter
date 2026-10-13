import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/chat_datasets/chat_datasets.dart';
import '../../../../generated/app_localizations.dart';

/// First use of the app: downloads every chat dataset (ice-breakers,
/// sentences, cultural tips, keywords, word lists, quotes) into the device
/// cache, showing a small non-blocking card with progress above the bottom of
/// the screen. Later starts read everything from the cache, with no card.
/// A failed download is retried quietly at the next start.
class ChatDatasetsFirstRun {
  ChatDatasetsFirstRun._();

  static const String doneKey = 'chat_datasets_first_download_done';
  static bool _running = false;

  /// Shows the card and downloads, once per install. Safe to call every start.
  static Future<void> maybeStart(BuildContext context, {ChatDatasets? datasets}) async {
    if (_running) return;
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(doneKey) == true) {
        // Already downloaded once: warm up from the cache, no card.
        (datasets ?? ChatDatasets.instance).preloadAll();
        return;
      }
    } catch (_) {/* no prefs: still download, just without remembering it */}
    if (!context.mounted) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    _running = true;
    final progress = ValueNotifier<(int, int, bool?)>((0, ChatDatasets.all.length, null));
    final entry = OverlayEntry(builder: (_) => ChatDatasetsDownloadCard(progress: progress));
    overlay.insert(entry);
    try {
      final ok = await (datasets ?? ChatDatasets.instance).preloadAll(
        onProgress: (done, total) => progress.value = (done, total, null),
      );
      progress.value = (progress.value.$1, progress.value.$2, ok);
      if (ok) await prefs?.setBool(doneKey, true);
      await Future<void>.delayed(const Duration(seconds: 2));
    } finally {
      entry.remove();
      progress.dispose();
      _running = false;
    }
  }
}

/// The progress card: "Downloading chat content for offline use… 3/6".
/// `progress` = (done, total, result): result null while downloading, then
/// true (ready) or false (some files failed, retried at the next start).
class ChatDatasetsDownloadCard extends StatelessWidget {
  const ChatDatasetsDownloadCard({super.key, required this.progress});

  final ValueListenable<(int, int, bool?)> progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();
    return Positioned(
      left: 16,
      right: 16,
      bottom: MediaQuery.of(context).padding.bottom + 88,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Material(
            key: const ValueKey('chat-datasets-download-card'),
            color: AppColors.charcoal,
            elevation: 6,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: ValueListenableBuilder<(int, int, bool?)>(
                valueListenable: progress,
                builder: (context, p, _) {
                  final (done, total, result) = p;
                  final text = switch (result) {
                    true => l10n.chatDatasetsReady,
                    false => l10n.chatDatasetsRetryLater,
                    null => l10n.chatDatasetsDownloading(done, total),
                  };
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [
                        Icon(result == true ? Icons.check_circle : Icons.cloud_download_outlined,
                            color: AppColors.richGold, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(text,
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5)),
                        ),
                      ]),
                      if (result == null) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: total == 0 ? null : done / total,
                            minHeight: 5,
                            color: AppColors.richGold,
                            backgroundColor: AppColors.backgroundDark,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
