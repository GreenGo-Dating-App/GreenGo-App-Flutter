import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../../generated/app_localizations.dart';
import 'capture_protection_state.dart';
import 'screen_security_service.dart';

/// App-wide cover shown while the screen is captured (recording / mirroring)
/// or, on web, while the page is not in focus; plus the
/// "Screenshots are not allowed" toast.
///
/// Mounted once, in `MaterialApp.builder`, so it sits above every route and
/// dialog. [state] / [events] default to [ScreenSecurityService.instance];
/// tests pass their own.
class ScreenProtectionOverlay extends StatefulWidget {
  const ScreenProtectionOverlay({
    required this.child,
    super.key,
    this.state,
    this.events,
    this.toastDuration = const Duration(milliseconds: 2500),
  });

  final Widget child;
  final ValueListenable<CaptureProtectionState>? state;
  final Stream<ScreenCaptureEvent>? events;
  final Duration toastDuration;

  @override
  State<ScreenProtectionOverlay> createState() =>
      _ScreenProtectionOverlayState();
}

class _ScreenProtectionOverlayState extends State<ScreenProtectionOverlay> {
  StreamSubscription<ScreenCaptureEvent>? _sub;
  Timer? _toastTimer;
  bool _toastVisible = false;

  ValueListenable<CaptureProtectionState> get _state =>
      widget.state ?? ScreenSecurityService.instance.state;

  @override
  void initState() {
    super.initState();
    _sub = (widget.events ?? ScreenSecurityService.instance.events)
        .listen((_) => _showToast());
  }

  void _showToast() {
    if (!mounted) return;
    setState(() => _toastVisible = true);
    _toastTimer?.cancel();
    _toastTimer = Timer(widget.toastDuration, () {
      if (mounted) setState(() => _toastVisible = false);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _toastTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        ValueListenableBuilder<CaptureProtectionState>(
          valueListenable: _state,
          builder: (context, state, _) {
            final cover = state.cover;
            if (cover == CaptureCover.none || l10n == null) {
              return const SizedBox.shrink();
            }
            return _CaptureCover(
              key: const ValueKey('captureCover'),
              title: cover == CaptureCover.recording
                  ? l10n.screenProtectionRecordingTitle
                  : l10n.screenProtectionHiddenTitle,
              body: cover == CaptureCover.recording
                  ? l10n.screenProtectionRecordingBody
                  : l10n.screenProtectionHiddenBody,
              icon: cover == CaptureCover.recording
                  ? Icons.videocam_off_rounded
                  : Icons.visibility_off_rounded,
            );
          },
        ),
        if (_toastVisible && l10n != null)
          Positioned(
            left: 24,
            right: 24,
            bottom: 48,
            child: IgnorePointer(
              child: Center(
                child: Material(
                  key: const ValueKey('captureToast'),
                  color: Colors.black.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.no_photography_rounded,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            l10n.screenProtectionScreenshotsNotAllowed,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CaptureCover extends StatelessWidget {
  const _CaptureCover({
    required this.title,
    required this.body,
    required this.icon,
    super.key,
  });

  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    // Blur AND an almost opaque scrim: the blur alone can be undone by a
    // determined person with an image editor, the scrim cannot.
    return Positioned.fill(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Material(
            color: Colors.black.withValues(alpha: 0.92),
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: Colors.white70, size: 56),
                      const SizedBox(height: 16),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        body,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
