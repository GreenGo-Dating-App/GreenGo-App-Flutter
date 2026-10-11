import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/security/capture_protection_state.dart';
import 'package:greengo_chat/core/security/media_url.dart';
import 'package:greengo_chat/core/security/screen_security_service.dart';

/// Screenshot / recording protection: the pure state machine behind the
/// capture cover, the service's native + web event handling, and the cache
/// key that keeps short-lived signed URLs cacheable.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final nativeCalls = <MethodCall>[];
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel(ScreenSecurityService.channelName),
    (call) async {
      nativeCalls.add(call);
      return true;
    },
  );

  group('CaptureProtectionState', () {
    const s0 = CaptureProtectionState();

    test('starts uncovered', () {
      expect(s0.cover, CaptureCover.none);
      expect(s0.obscured, isFalse);
    });

    test('recording covers until it stops', () {
      final rec = s0.apply(CaptureSignal.captureStarted);
      expect(rec.cover, CaptureCover.recording);
      expect(rec.apply(CaptureSignal.captureStopped).cover, CaptureCover.none);
    });

    test('web: blur / hidden cover as "away", focus / visible uncover', () {
      final blurred = s0.apply(CaptureSignal.windowBlurred);
      expect(blurred.cover, CaptureCover.away);
      expect(blurred.apply(CaptureSignal.windowFocused).cover, CaptureCover.none);

      final hidden = s0.apply(CaptureSignal.pageHidden);
      expect(hidden.cover, CaptureCover.away);
      // Coming back to the tab clears both flags at once.
      final back = hidden
          .apply(CaptureSignal.windowBlurred)
          .apply(CaptureSignal.pageVisible);
      expect(back.cover, CaptureCover.none);
    });

    test('hidden page stays covered when only focus returns', () {
      final s = s0
          .apply(CaptureSignal.pageHidden)
          .apply(CaptureSignal.windowFocused);
      expect(s.cover, CaptureCover.away);
    });

    test('recording wins over away', () {
      final s = s0
          .apply(CaptureSignal.windowBlurred)
          .apply(CaptureSignal.captureStarted);
      expect(s.cover, CaptureCover.recording);
    });

    test('kill-switch off never covers, and restores on re-enable', () {
      final s = s0
          .apply(CaptureSignal.captureStarted)
          .apply(CaptureSignal.protectionDisabled);
      expect(s.cover, CaptureCover.none);
      expect(s.apply(CaptureSignal.protectionEnabled).cover,
          CaptureCover.recording);
    });

    test('value equality', () {
      expect(s0.apply(CaptureSignal.windowBlurred),
          const CaptureProtectionState(windowBlurred: true));
    });

    test('web shim event names', () {
      expect(captureSignalForWebEvent('blur'), CaptureSignal.windowBlurred);
      expect(captureSignalForWebEvent('focus'), CaptureSignal.windowFocused);
      expect(captureSignalForWebEvent('hidden'), CaptureSignal.pageHidden);
      expect(captureSignalForWebEvent('visible'), CaptureSignal.pageVisible);
      expect(captureSignalForWebEvent('printscreen'), isNull);
      expect(kBlockedCaptureWebEvents,
          containsAll(<String>['printscreen', 'print', 'save']));
    });
  });

  group('ScreenSecurityService event handling', () {
    final service = ScreenSecurityService.instance;
    setUp(service.resetForTest);

    test('native onScreenshot -> screenshot event', () async {
      final got =
          expectLater(service.events, emits(ScreenCaptureEvent.screenshot));
      await service.handleNativeCall(const MethodCall('onScreenshot'));
      await got;
    });

    test('native onCaptureChanged drives the cover', () async {
      await service.handleNativeCall(const MethodCall('onCaptureChanged', true));
      expect(service.state.value.cover, CaptureCover.recording);
      await service
          .handleNativeCall(const MethodCall('onCaptureChanged', false));
      expect(service.state.value.cover, CaptureCover.none);
    });

    test('unknown native method is rejected', () {
      expect(() => service.handleNativeCall(const MethodCall('nope')),
          throwsA(isA<MissingPluginException>()));
    });

    test('web focus loss covers; shortcuts produce a blocked event', () async {
      service.handleWebEvent('blur');
      expect(service.state.value.cover, CaptureCover.away);
      service.handleWebEvent('focus');
      expect(service.state.value.cover, CaptureCover.none);

      final got = expectLater(
          service.events, emits(ScreenCaptureEvent.blockedShortcut));
      service.handleWebEvent('printscreen');
      await got;
    });

    test('no toast event while the kill-switch is off', () async {
      final seen = <ScreenCaptureEvent>[];
      final sub = service.events.listen(seen.add);
      await service.setProtectionEnabled(false);
      service.handleWebEvent('print');
      await Future<void>.delayed(Duration.zero);
      expect(seen, isEmpty);
      expect(service.state.value.enabled, isFalse);
      expect(service.secure, isFalse);
      // Remote kill-switch is persisted natively (iOS skips the secure layer
      // on the next launch).
      expect(nativeCalls.last.method, 'disable');
      expect(nativeCalls.last.arguments, {'persist': true});
      await sub.cancel();
    });
  });

  group('stableMediaCacheKey', () {
    const b = 'greengo-chat.appspot.com';
    test('download URL and signed URLs of one object share a key', () {
      const dl = 'https://firebasestorage.googleapis.com/v0/b/$b/o/'
          'profiles%2Fu1%2Fphotos%2F1.jpg?alt=media&token=abc';
      const signed1 = 'https://storage.googleapis.com/$b/profiles/u1/photos/'
          '1.jpg?X-Goog-Algorithm=GOOG4-RSA-SHA256&X-Goog-Signature=aaa';
      const signed2 = 'https://storage.googleapis.com/$b/profiles/u1/photos/'
          '1.jpg?X-Goog-Algorithm=GOOG4-RSA-SHA256&X-Goog-Signature=bbb';
      const key = 'gs://$b/profiles/u1/photos/1.jpg';
      expect(stableMediaCacheKey(dl), key);
      expect(stableMediaCacheKey(signed1), key);
      expect(stableMediaCacheKey(signed2), key);
      expect(
          stableMediaCacheKey(
              'https://$b.storage.googleapis.com/profiles/u1/photos/1.jpg?x=1'),
          key);
    });

    test('anything else is its own key', () {
      expect(stableMediaCacheKey('https://cdn.example.com/a.jpg?v=1'),
          'https://cdn.example.com/a.jpg?v=1');
      expect(stableMediaCacheKey('not a url'), 'not a url');
    });
  });
}
