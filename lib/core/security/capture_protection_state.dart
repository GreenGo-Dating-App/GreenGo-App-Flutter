import 'package:flutter/foundation.dart';

/// Why the app is currently covered by the capture-protection overlay.
enum CaptureCover {
  /// Nothing to hide: the app renders normally.
  none,

  /// The screen is being recorded, mirrored or AirPlayed (iOS
  /// `UIScreen.isCaptured`, Android 15+ screen-recording callback).
  recording,

  /// Web only: the page lost focus or was hidden (tab switch, snipping tool,
  /// another window in front). A best-effort deterrent, not a real block.
  away,
}

/// Signals fed into [CaptureProtectionState.apply], from the native channel
/// (`greengo/screen_security`) or the web shim in `web/index.html`.
enum CaptureSignal {
  captureStarted,
  captureStopped,
  pageHidden,
  pageVisible,
  windowBlurred,
  windowFocused,
  protectionEnabled,
  protectionDisabled,
}

/// Pure state machine behind the capture-protection overlay.
///
/// Kept free of Flutter/platform code so every transition is unit-testable.
/// [cover] is the only thing the UI reads: recording wins over "away", and a
/// disabled protection (remote kill-switch `screenProtection`) never covers.
@immutable
class CaptureProtectionState {
  const CaptureProtectionState({
    this.enabled = true,
    this.captured = false,
    this.pageHidden = false,
    this.windowBlurred = false,
  });

  /// Remote kill-switch (feature flag `screenProtection`, default on).
  final bool enabled;

  /// The screen is being recorded / mirrored right now.
  final bool captured;

  /// Web: `document.visibilityState == 'hidden'`.
  final bool pageHidden;

  /// Web: the browser window lost focus (`window.blur`).
  final bool windowBlurred;

  CaptureCover get cover {
    if (!enabled) return CaptureCover.none;
    if (captured) return CaptureCover.recording;
    if (pageHidden || windowBlurred) return CaptureCover.away;
    return CaptureCover.none;
  }

  bool get obscured => cover != CaptureCover.none;

  CaptureProtectionState apply(CaptureSignal signal) {
    switch (signal) {
      case CaptureSignal.captureStarted:
        return _copy(captured: true);
      case CaptureSignal.captureStopped:
        return _copy(captured: false);
      case CaptureSignal.pageHidden:
        return _copy(pageHidden: true);
      case CaptureSignal.pageVisible:
        // Coming back to the tab: the window is focused again too (the
        // browser fires `focus` as well, but not reliably before the frame).
        return _copy(pageHidden: false, windowBlurred: false);
      case CaptureSignal.windowBlurred:
        return _copy(windowBlurred: true);
      case CaptureSignal.windowFocused:
        return _copy(windowBlurred: false);
      case CaptureSignal.protectionEnabled:
        return _copy(enabled: true);
      case CaptureSignal.protectionDisabled:
        return _copy(enabled: false);
    }
  }

  CaptureProtectionState _copy({
    bool? enabled,
    bool? captured,
    bool? pageHidden,
    bool? windowBlurred,
  }) =>
      CaptureProtectionState(
        enabled: enabled ?? this.enabled,
        captured: captured ?? this.captured,
        pageHidden: pageHidden ?? this.pageHidden,
        windowBlurred: windowBlurred ?? this.windowBlurred,
      );

  @override
  bool operator ==(Object other) =>
      other is CaptureProtectionState &&
      other.enabled == enabled &&
      other.captured == captured &&
      other.pageHidden == pageHidden &&
      other.windowBlurred == windowBlurred;

  @override
  int get hashCode => Object.hash(enabled, captured, pageHidden, windowBlurred);

  @override
  String toString() => 'CaptureProtectionState(enabled: $enabled, '
      'captured: $captured, pageHidden: $pageHidden, '
      'windowBlurred: $windowBlurred)';
}

/// Maps an event name sent by the web shim (`window.__ggScreenGuard`) to a
/// state signal; null for events that are not state changes (shortcuts).
CaptureSignal? captureSignalForWebEvent(String event) {
  switch (event) {
    case 'blur':
      return CaptureSignal.windowBlurred;
    case 'focus':
      return CaptureSignal.windowFocused;
    case 'hidden':
      return CaptureSignal.pageHidden;
    case 'visible':
      return CaptureSignal.pageVisible;
  }
  return null;
}

/// Web shim events that mean "the user tried to capture/print/save" and get
/// the "Screenshots are not allowed" toast.
const Set<String> kBlockedCaptureWebEvents = {'printscreen', 'print', 'save'};
