import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'capture_protection_state.dart';
import 'web_screen_guard.dart';

/// Something the user did that the app noticed but could not (fully) stop.
enum ScreenCaptureEvent {
  /// A screenshot was taken (iOS `userDidTakeScreenshotNotification`, Android
  /// 14+ `ScreenCaptureCallback` while FLAG_SECURE is off). With protection
  /// on, the picture itself is black/blank; chats still post a
  /// "X took a screenshot" notice.
  screenshot,

  /// Web: PrintScreen / print / save-page shortcut intercepted.
  blockedShortcut,
}

/// Screenshot / screen-recording protection, one entry point for all
/// platforms.
///
/// | platform | blocked                              | detected                 | deterred (best effort)       |
/// |----------|--------------------------------------|--------------------------|------------------------------|
/// | Android  | FLAG_SECURE: screenshots, recordings, recents thumbnail (black) | 14+: screenshots when FLAG_SECURE is off; 15+: recording state | - |
/// | iOS      | secure-layer: app renders blank in screenshots/recordings | screenshots, recording/mirroring (`isCaptured`) | full-screen cover while captured |
/// | web      | nothing can truly be blocked         | PrintScreen, print, save, focus loss | blur on focus loss, cleared clipboard, no print, watermarks, app-only content |
///
/// Native side: `MainActivity.kt` and `AppDelegate.swift`, channel
/// [channelName]. Dart -> native: `enable`, `disable`, `isCaptured`.
/// Native -> Dart: `onScreenshot`, `onCaptureChanged(bool)`.
class ScreenSecurityService {
  ScreenSecurityService._();

  static final ScreenSecurityService instance = ScreenSecurityService._();

  static const String channelName = 'greengo/screen_security';
  static const MethodChannel _channel = MethodChannel(channelName);

  final ValueNotifier<CaptureProtectionState> state =
      ValueNotifier<CaptureProtectionState>(const CaptureProtectionState());

  final StreamController<ScreenCaptureEvent> _events =
      StreamController<ScreenCaptureEvent>.broadcast();

  /// Screenshots and blocked shortcuts, for chat notices and the toast.
  Stream<ScreenCaptureEvent> get events => _events.stream;

  /// Only screenshots (what chat screens listen to).
  Stream<void> get screenshots =>
      events.where((e) => e == ScreenCaptureEvent.screenshot);

  bool _initialized = false;
  bool _secure = true;

  /// Whether FLAG_SECURE / the iOS secure layer is requested on.
  bool get secure => _secure;

  /// Wires the native channel (mobile) or the web shim. Idempotent; never
  /// throws (protection failing must not stop the app from starting).
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    if (kIsWeb) {
      attachWebScreenGuard(handleWebEvent);
      return;
    }
    if (!_isMobile) return;
    _channel.setMethodCallHandler(handleNativeCall);
    // Native code turned protection on before the first frame; repeating it
    // here lets iOS retry the secure-layer install once the window is on
    // screen.
    await setSecure(_secure);
    try {
      final captured = await _channel.invokeMethod<bool>('isCaptured');
      if (captured == true) _signal(CaptureSignal.captureStarted);
    } catch (e) {
      debugPrint('[ScreenSecurity] isCaptured unavailable: $e');
    }
  }

  static bool get _isMobile =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  /// Remote kill-switch (feature flag `screenProtection`). Off = no
  /// FLAG_SECURE / secure layer, no overlay, no web blur. Screenshot notices
  /// in chats keep working (they only report, never block).
  Future<void> setProtectionEnabled(bool enabled) async {
    _signal(enabled
        ? CaptureSignal.protectionEnabled
        : CaptureSignal.protectionDisabled);
    if (kIsWeb) {
      setWebScreenGuardEnabled(enabled);
      return;
    }
    // persist: iOS remembers a remote "off" so the next launch does not
    // even install the secure layer (see AppDelegate.swift).
    await setSecure(enabled, persist: true);
  }

  /// FLAG_SECURE (Android) / secure layer (iOS) on or off. App-wide default
  /// is ON (set natively before the first frame); a screen that must allow
  /// screenshots (none today) can call `setSecure(false)` and restore it in
  /// `dispose`.
  Future<void> setSecure(bool secure, {bool persist = false}) async {
    _secure = secure;
    if (kIsWeb || !_isMobile) return;
    try {
      await _channel.invokeMethod<void>(
          secure ? 'enable' : 'disable', <String, Object>{'persist': persist});
    } catch (e) {
      debugPrint('[ScreenSecurity] ${secure ? 'enable' : 'disable'} failed: $e');
    }
  }

  @visibleForTesting
  Future<Object?> handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'onScreenshot':
        _events.add(ScreenCaptureEvent.screenshot);
        return null;
      case 'onCaptureChanged':
        _signal(call.arguments == true
            ? CaptureSignal.captureStarted
            : CaptureSignal.captureStopped);
        return null;
    }
    throw MissingPluginException('Unknown method ${call.method}');
  }

  @visibleForTesting
  void handleWebEvent(String event) {
    final signal = captureSignalForWebEvent(event);
    if (signal != null) {
      _signal(signal);
      return;
    }
    if (kBlockedCaptureWebEvents.contains(event) && state.value.enabled) {
      _events.add(ScreenCaptureEvent.blockedShortcut);
    }
  }

  void _signal(CaptureSignal signal) {
    state.value = state.value.apply(signal);
  }

  @visibleForTesting
  void resetForTest() {
    state.value = const CaptureProtectionState();
    _secure = true;
    _initialized = false;
  }
}
