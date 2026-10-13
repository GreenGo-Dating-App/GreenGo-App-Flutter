import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/chat_datasets/chat_datasets.dart';
import '../../../../generated/app_localizations.dart';

/// First use of the app, ONCE: downloads every chat dataset (ice-breakers,
/// sentences, cultural tips, keywords, word lists, quotes) into the device
/// cache, in a centred window with the percentage. The user can wait, or
/// minimise it to a small percentage pill at the bottom and keep using the
/// app. When the download completes the window / pill disappears by itself.
/// Later starts read everything from the cache (nothing shown). If something
/// fails, the window says so (OK closes it; the pill just goes away) and the
/// download runs again at the next start.
class ChatDatasetsFirstRun {
  ChatDatasetsFirstRun._();

  // v2: 4.9.7+218 shows the centred window (with %) once to everyone.
  static const String doneKey = 'chat_datasets_first_download_done_v2';
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
    final navigator = Navigator.of(context, rootNavigator: true);
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    var dialogOpen = true;
    OverlayEntry? pill;

    void minimise() {
      if (!dialogOpen) return;
      dialogOpen = false;
      navigator.pop();
      if (overlay != null) {
        pill = OverlayEntry(builder: (_) => ChatDatasetsDownloadPill(progress: progress));
        overlay.insert(pill!);
      }
    }

    final dialog = showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => PopScope(
        canPop: false,
        child: ChatDatasetsDownloadDialog(progress: progress, onMinimise: minimise),
      ),
    ).whenComplete(() => dialogOpen = false);
    try {
      final ok = await ds.preloadAll(onProgress: (f) => progress.value = (f, null));
      if (ok) await prefs?.setBool(doneKey, true);
      progress.value = (ok ? 1.0 : progress.value.$1, ok);
      if (ok) {
        // Done: show "ready" a moment, then the window / pill goes away.
        await Future<void>.delayed(const Duration(milliseconds: 900));
        if (dialogOpen) navigator.pop();
      } else if (!dialogOpen) {
        // Minimised and failed: just go away; it retries next start.
      }
      pill?.remove();
      pill = null;
      if (!ok && dialogOpen) await dialog; // the user reads the message, OK
    } finally {
      pill?.remove();
      progress.dispose();
      _running = false;
    }
  }
}

/// Minimised: a small pill at the bottom with the percentage; the app runs
/// normally meanwhile.
class ChatDatasetsDownloadPill extends StatefulWidget {
  const ChatDatasetsDownloadPill({super.key, required this.progress});

  final ValueListenable<(double, bool?)> progress;

  @override
  State<ChatDatasetsDownloadPill> createState() => _ChatDatasetsDownloadPillState();
}

/// The pill can be dragged anywhere on screen (it starts at the bottom).
class _ChatDatasetsDownloadPillState extends State<ChatDatasetsDownloadPill> {
  Offset _delta = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();
    final mq = MediaQuery.of(context);
    final bottom = mq.padding.bottom + 84;
    return Positioned(
      left: 0,
      right: 0,
      bottom: bottom,
      child: Transform.translate(
        offset: _delta,
        child: Center(
          child: GestureDetector(
            key: const ValueKey('chat-datasets-download-pill-drag'),
            onPanUpdate: (d) => setState(() {
              final next = _delta + d.delta;
              // Keep it on screen.
              final maxX = mq.size.width / 2 - 40;
              _delta = Offset(
                next.dx.clamp(-maxX, maxX),
                next.dy.clamp(-(mq.size.height - bottom - mq.padding.top - 40), bottom - 8),
              );
            }),
            child: Material(
              key: const ValueKey('chat-datasets-download-pill'),
              color: AppColors.charcoal,
              elevation: 6,
              shape: const StadiumBorder(side: BorderSide(color: AppColors.richGold)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: ValueListenableBuilder<(double, bool?)>(
                  valueListenable: widget.progress,
                  builder: (context, p, _) {
                    final (target, result) = p;
                    return SmoothProgress(
                      target: result == true ? 1 : target,
                      builder: (fraction) => Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.drag_indicator, size: 16, color: AppColors.textTertiary),
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: result == true
                              ? const Icon(Icons.check_circle, size: 16, color: AppColors.richGold)
                              : CircularProgressIndicator(
                                  value: fraction, strokeWidth: 2.5, color: AppColors.richGold),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          result == true
                              ? l10n.chatDatasetsReady
                              : l10n.chatDatasetsDownloadingPercent((fraction * 100).floor().clamp(0, 100)),
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        ),
                      ]),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Moves the shown value toward [target] at a steady pace, so the
/// percentage climbs linearly instead of jumping file by file.
class SmoothProgress extends StatelessWidget {
  const SmoothProgress({super.key, required this.target, required this.builder});

  final double target;
  final Widget Function(double fraction) builder;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween<double>(end: target.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 700),
        curve: Curves.linear,
        builder: (context, v, _) => builder(v),
      );
}

/// The centred window: title, "only once" note, big percentage, bar.
/// `progress` = (fraction, result): result null while downloading, true when
/// ready, false when some files failed (then an OK button closes it).
class ChatDatasetsDownloadDialog extends StatelessWidget {
  const ChatDatasetsDownloadDialog({super.key, required this.progress, this.onMinimise});

  final ValueListenable<(double, bool?)> progress;

  /// Shrinks the window to the bottom percentage pill (while downloading).
  final VoidCallback? onMinimise;

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
          final (target, result) = p;
          return SmoothProgress(
            target: result == true ? 1 : target,
            builder: (fraction) => _body(l10n, fraction, result),
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
              : p.$2 == null && onMinimise != null
                  ? TextButton(
                      key: const ValueKey('chat-datasets-minimise'),
                      onPressed: onMinimise,
                      child: Text(l10n.chatDatasetsMinimise),
                    )
                  : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _body(AppLocalizations l10n, double fraction, bool? result) {
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
  }
}
