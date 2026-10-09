import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/security/app_only_content.dart';
import 'package:greengo_chat/core/security/capture_protection_state.dart';
import 'package:greengo_chat/core/security/screen_protection_overlay.dart';
import 'package:greengo_chat/core/security/screen_security_service.dart';
import 'package:greengo_chat/core/security/viewer_watermark.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

Widget _app(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  group('ScreenProtectionOverlay', () {
    late ValueNotifier<CaptureProtectionState> state;
    late StreamController<ScreenCaptureEvent> events;

    setUp(() {
      state = ValueNotifier(const CaptureProtectionState());
      events = StreamController<ScreenCaptureEvent>.broadcast();
    });
    tearDown(() => events.close());

    Widget overlay() => _app(ScreenProtectionOverlay(
          state: state,
          events: events.stream,
          toastDuration: const Duration(milliseconds: 300),
          child: const Text('secret content'),
        ));

    testWidgets('no cover by default', (tester) async {
      await tester.pumpWidget(overlay());
      expect(find.byKey(const ValueKey('captureCover')), findsNothing);
      expect(find.text('secret content'), findsOneWidget);
    });

    testWidgets('recording shows the "not allowed" cover until it stops',
        (tester) async {
      await tester.pumpWidget(overlay());
      state.value = state.value.apply(CaptureSignal.captureStarted);
      await tester.pump();
      expect(find.byKey(const ValueKey('captureCover')), findsOneWidget);
      expect(find.text('Screen recording is not allowed'), findsOneWidget);

      state.value = state.value.apply(CaptureSignal.captureStopped);
      await tester.pump();
      expect(find.byKey(const ValueKey('captureCover')), findsNothing);
    });

    testWidgets('web focus loss shows the hidden-content cover',
        (tester) async {
      await tester.pumpWidget(overlay());
      state.value = state.value.apply(CaptureSignal.windowBlurred);
      await tester.pump();
      expect(find.text('Content hidden'), findsOneWidget);
      state.value = state.value.apply(CaptureSignal.windowFocused);
      await tester.pump();
      expect(find.text('Content hidden'), findsNothing);
    });

    testWidgets('cover is localized', (tester) async {
      await tester.pumpWidget(_app(
        ScreenProtectionOverlay(
          state: ValueNotifier(const CaptureProtectionState(captured: true)),
          events: const Stream.empty(),
          child: const SizedBox(),
        ),
        locale: const Locale('it'),
      ));
      expect(find.text('La registrazione dello schermo non è consentita'),
          findsOneWidget);
    });

    testWidgets('screenshot / shortcut shows a toast that goes away',
        (tester) async {
      await tester.pumpWidget(overlay());
      events.add(ScreenCaptureEvent.blockedShortcut);
      await tester.pump();
      expect(find.text('Screenshots are not allowed'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Screenshots are not allowed'), findsNothing);
    });
  });

  group('ViewerWatermark', () {
    test('policy: private media everywhere, all photos on web', () {
      expect(shouldWatermarkMedia(isPrivate: true, isWeb: false), isTrue);
      expect(shouldWatermarkMedia(isPrivate: true, isWeb: true), isTrue);
      expect(shouldWatermarkMedia(isPrivate: false, isWeb: true), isTrue);
      expect(shouldWatermarkMedia(isPrivate: false, isWeb: false), isFalse);
    });

    test('label names the viewer', () {
      expect(viewerWatermarkLabel(uid: 'abcdefghijklmnop', nickname: 'mia'),
          '@mia · abcdefghij');
      expect(viewerWatermarkLabel(uid: 'u1'), 'u1');
      expect(viewerWatermarkLabel(nickname: 'mia'), '@mia');
      expect(viewerWatermarkLabel(), '');
    });

    testWidgets('paints over the child and never takes input', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_app(SizedBox(
        width: 300,
        height: 300,
        child: ViewerWatermark(
          label: '@viewer · uid123',
          child: GestureDetector(
            onTap: () => taps++,
            child: Container(color: Colors.blue),
          ),
        ),
      )));
      final finder = find.byKey(const ValueKey('viewerWatermark'));
      expect(finder, findsOneWidget);
      final paint = tester.widget<CustomPaint>(finder);
      expect((paint.painter! as WatermarkPainter).text, '@viewer · uid123');
      await tester.tap(find.byType(GestureDetector));
      expect(taps, 1);
    });

    testWidgets('disabled or no viewer -> child only', (tester) async {
      await tester.pumpWidget(_app(const ViewerWatermark(
        label: 'x',
        enabled: false,
        child: SizedBox(width: 10, height: 10),
      )));
      expect(find.byKey(const ValueKey('viewerWatermark')), findsNothing);
      await tester.pumpWidget(_app(const ViewerWatermark(
        label: '',
        child: SizedBox(width: 10, height: 10),
      )));
      expect(find.byKey(const ValueKey('viewerWatermark')), findsNothing);
    });
  });

  group('app-only content (web gating)', () {
    test('blocked on web only', () {
      expect(isAppOnlyContentBlocked(isWeb: true), isTrue);
      expect(isAppOnlyContentBlocked(isWeb: false), isFalse);
      // Tests run on the VM: the real default is "not web".
      expect(isAppOnlyContentBlocked(), kIsWeb);
    });

    testWidgets('notice says to open the app', (tester) async {
      await tester.pumpWidget(_app(const AppOnlyContentNotice()));
      expect(find.text('Open in the GreenGo app to view'), findsOneWidget);
      expect(find.text('Open the app'), findsOneWidget);
    });

    testWidgets('screen variant is a full page', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AppOnlyContentScreen(),
      ));
      expect(find.byKey(const ValueKey('appOnlyTitle')), findsOneWidget);
    });
  });
}
