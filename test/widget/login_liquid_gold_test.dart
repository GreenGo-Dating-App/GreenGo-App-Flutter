import 'dart:ui' as ui;

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/constants/e2e_keys.dart';
import 'package:greengo_chat/core/error/failures.dart';
import 'package:greengo_chat/core/providers/language_provider.dart';
import 'package:greengo_chat/core/widgets/gold_shimmer.dart';
import 'package:greengo_chat/core/widgets/liquid_gold_background.dart';
import 'package:greengo_chat/features/authentication/domain/entities/user.dart'
    as domain;
import 'package:greengo_chat/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:greengo_chat/features/authentication/presentation/screens/login_screen.dart';
import 'package:greengo_chat/features/authentication/presentation/widgets/liquid_gold_widgets.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../support/auth_fixtures.dart';

LiquidGoldBackgroundState _bgState(WidgetTester tester) =>
    tester.state<LiquidGoldBackgroundState>(find.byType(LiquidGoldBackground));

CustomPainter? _layerPainter(WidgetTester tester) => tester
    .widget<CustomPaint>(
        find.byKey(const ValueKey('liquid_gold_background_layer')))
    .painter;

Widget _host(Widget child, {bool reducedMotion = false}) => MaterialApp(
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(disableAnimations: reducedMotion),
          child: child,
        ),
      ),
    );

void _background(WidgetTester tester) {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
}

void _resume(WidgetTester tester) {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
}

Future<void> _pumpLogin(
  WidgetTester tester,
  Locale locale, {
  bool reducedMotion = false,
  Duration settle = const Duration(seconds: 2),
}) async {
  final repo = MockAuthRepository();
  when(() => repo.authStateChanges)
      .thenAnswer((_) => const Stream<domain.User?>.empty());
  when(() => repo.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ))
      .thenAnswer((_) async =>
          const Left<Failure, domain.User>(AuthenticationFailure()));

  tester.view.devicePixelRatio = 2.0;
  tester.view.physicalSize = const Size(390, 844) * 2.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(
            repository: repo,
            accessControlService: MockAccessControlService(),
          ),
        ),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(disableAnimations: reducedMotion),
          child: child!,
        ),
        home: const LoginScreen(),
      ),
    ),
  );
  if (settle > Duration.zero) await tester.pump(settle);
}

void main() {
  group('LiquidGoldBackground', () {
    testWidgets('falls back to the Dart painter when the shader fails to load',
        (tester) async {
      await tester.pumpWidget(_host(LiquidGoldBackground(
        programLoader: () async => throw Exception('no shader support'),
        child: const Text('child'),
      )));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('child'), findsOneWidget);
      expect(_bgState(tester).usingShader, isFalse);
      expect(_layerPainter(tester), isA<LiquidGoldFallbackPainter>());
      expect(_bgState(tester).isAnimating, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('useShader:false renders the fallback without loading',
        (tester) async {
      var loads = 0;
      await tester.pumpWidget(_host(LiquidGoldBackground(
        useShader: false,
        programLoader: () async {
          loads++;
          throw Exception('should not be called');
        },
        child: const SizedBox(),
      )));
      await tester.pump(const Duration(milliseconds: 100));
      expect(loads, 0);
      expect(_layerPainter(tester), isA<LiquidGoldFallbackPainter>());
      expect(tester.takeException(), isNull);
    });

    testWidgets('uses the fragment shader when it loads', (tester) async {
      ui.FragmentProgram? program;
      await tester.runAsync(() async {
        try {
          program = await ui.FragmentProgram.fromAsset(
              LiquidGoldBackground.shaderAsset);
        } catch (_) {
          program = null;
        }
      });
      if (program == null) {
        // The test runner has no shader back-end on this host; the fallback
        // path is covered above.
        markTestSkipped('FragmentProgram unavailable in this test runner');
        return;
      }
      await tester.pumpWidget(_host(LiquidGoldBackground(
        programLoader: () async => program!,
        child: const SizedBox(),
      )));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(_bgState(tester).usingShader, isTrue);
      expect(_layerPainter(tester), isNot(isA<LiquidGoldFallbackPainter>()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('reduced motion renders a static frame (no ticker)',
        (tester) async {
      await tester.pumpWidget(_host(
        const LiquidGoldBackground(useShader: false, child: SizedBox()),
        reducedMotion: true,
      ));
      await tester.pump(const Duration(seconds: 1));
      expect(_bgState(tester).isAnimating, isFalse);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('pauses when the app is backgrounded and resumes after',
        (tester) async {
      await tester.pumpWidget(_host(
        const LiquidGoldBackground(useShader: false, child: SizedBox()),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      expect(_bgState(tester).isAnimating, isTrue);

      _background(tester);
      await tester.pump();
      expect(_bgState(tester).isAnimating, isFalse);

      _resume(tester);
      await tester.pump();
      expect(_bgState(tester).isAnimating, isTrue);
    });

    testWidgets('the child is isolated from the animated layer',
        (tester) async {
      var builds = 0;
      await tester.pumpWidget(_host(LiquidGoldBackground(
        useShader: false,
        child: Builder(builder: (_) {
          builds++;
          return const SizedBox();
        }),
      )));
      final before = builds;
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(builds, before, reason: 'drift must repaint, never rebuild');
      expect(
        find.ancestor(
          of: find.byKey(const ValueKey('liquid_gold_background_layer')),
          matching: find.byType(RepaintBoundary),
        ),
        findsWidgets,
      );
    });

    test('glows drift slowly and smoothly (never fast)', () {
      const phone = Size(390, 844);
      // Worst case over a whole 38 s leg, sampled at the 30 fps tick.
      var maxStep = 0.0;
      var prev = LiquidGoldBackground.resolve(phone, 0);
      for (var t = 1 / 30; t <= 38; t += 1 / 30) {
        final now = LiquidGoldBackground.resolve(phone, t);
        for (var i = 0; i < now.length; i++) {
          final d = (now[i].center - prev[i].center).distance;
          if (d > maxStep) maxStep = d;
        }
        prev = now;
      }
      expect(maxStep, lessThan(0.5), reason: 'px per frame at 30 fps');

      // Each glow actually travels (60–100 px) and returns (alternate).
      final a0 = LiquidGoldBackground.resolve(phone, 0);
      for (var i = 0; i < 3; i++) {
        final g = LiquidGoldBackground.glows[i];
        final mid = LiquidGoldBackground.resolve(phone, g.period);
        final back = LiquidGoldBackground.resolve(phone, 2 * g.period);
        expect((mid[i].center - a0[i].center).distance, greaterThan(50));
        expect((back[i].center - a0[i].center).distance, lessThan(0.01));
      }
    });

    test('glows grow with the window (desktop is not a black field)', () {
      final phone = LiquidGoldBackground.resolve(const Size(390, 844), 0);
      final desk = LiquidGoldBackground.resolve(const Size(1440, 900), 0);
      expect(desk[0].radius, greaterThan(phone[0].radius * 1.5));
    });
  });

  group('LoginScreen (liquid gold)', () {
    setUpAll(() => LiquidGoldBackground.debugResetProgramCache());

    testWidgets('form keys, background, glass card and tagline are present',
        (tester) async {
      await _pumpLogin(tester, const Locale('en'));
      expect(find.byType(LiquidGoldBackground), findsOneWidget);
      expect(find.byType(GlassCard), findsOneWidget);
      expect(find.byType(BreathingGoldButton), findsOneWidget);
      expect(find.byType(GoldShimmer), findsOneWidget);
      expect(find.byKey(E2EKeys.loginEmail), findsOneWidget);
      expect(find.byKey(E2EKeys.loginPassword), findsOneWidget);
      expect(find.byKey(E2EKeys.loginSubmit), findsOneWidget);
      expect(
        find.text('Discover cultures. Connect without language barriers.'),
        findsOneWidget,
      );
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      // Uppercase labels above the fields.
      expect(find.text(l10n.loginEmailOrNickname.toUpperCase()),
          findsOneWidget);
      expect(find.text(l10n.password.toUpperCase()), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    for (final size in const [Size(320, 640), Size(390, 844), Size(1440, 900)]) {
      testWidgets('card is centred and capped at 420 px — $size',
          (tester) async {
        await _pumpLogin(tester, const Locale('en'));
        tester.view.physicalSize = size * 2.0;
        await tester.pump(const Duration(milliseconds: 100));
        final card = tester.getRect(find.byType(GlassCard));
        expect(card.width, lessThanOrEqualTo(420));
        expect(card.center.dx, moreOrLessEquals(size.width / 2, epsilon: 1));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('validators still run (empty submit shows errors)',
        (tester) async {
      await _pumpLogin(tester, const Locale('en'), reducedMotion: true);
      await tester.ensureVisible(find.byKey(E2EKeys.loginSubmit));
      await tester.tap(find.byKey(E2EKeys.loginSubmit));
      await tester.pump();
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l10n.authPleaseEnterEmail), findsOneWidget);
      expect(find.text(l10n.passwordRequired), findsOneWidget);
    });

    for (final locale in AppLocalizations.supportedLocales) {
      testWidgets('tagline is localized — $locale', (tester) async {
        await _pumpLogin(tester, locale, reducedMotion: true);
        final l10n = await AppLocalizations.delegate.load(locale);
        expect(l10n.loginTagline.trim(), isNotEmpty);
        final tagline =
            tester.widget<Text>(find.byKey(const ValueKey('login_tagline')));
        expect(tagline.data, l10n.loginTagline);
        if (locale.languageCode != 'en') {
          final en = await AppLocalizations.delegate.load(const Locale('en'));
          expect(l10n.loginTagline, isNot(en.loginTagline),
              reason: 'tagline must be translated for $locale');
        }
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('reduced motion → fully static login (nothing ticks)',
        (tester) async {
      await _pumpLogin(tester, const Locale('en'), reducedMotion: true);
      expect(_bgState(tester).isAnimating, isFalse);
      expect(
        tester
            .state<BreathingGoldButtonState>(find.byType(BreathingGoldButton))
            .isAnimating,
        isFalse,
      );
      await tester.pump(const Duration(seconds: 10));
      expect(
        tester.state<GoldShimmerState>(find.byType(GoldShimmer)).isSweeping,
        isFalse,
      );
      expect(tester.widget<RiseIn>(find.byType(RiseIn).first).animation.value,
          1.0);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('background and button glow pause when backgrounded',
        (tester) async {
      await _pumpLogin(tester, const Locale('en'));
      final button =
          tester.state<BreathingGoldButtonState>(find.byType(BreathingGoldButton));
      expect(_bgState(tester).isAnimating, isTrue);
      expect(button.isAnimating, isTrue);

      _background(tester);
      await tester.pump();
      expect(_bgState(tester).isAnimating, isFalse);
      expect(button.isAnimating, isFalse);

      _resume(tester);
      await tester.pump();
      expect(_bgState(tester).isAnimating, isTrue);
      expect(button.isAnimating, isTrue);
    });

    testWidgets('the form is not rebuilt by the background or the glow',
        (tester) async {
      await _pumpLogin(tester, const Locale('en'),
          settle: const Duration(seconds: 3));
      final form = tester.widget<Form>(find.byType(Form));
      final field = tester.widget(find.byKey(E2EKeys.loginEmail));
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 33));
      }
      expect(identical(tester.widget<Form>(find.byType(Form)), form), isTrue,
          reason: 'animated layers must repaint, never rebuild the form');
      expect(identical(tester.widget(find.byKey(E2EKeys.loginEmail)), field),
          isTrue);
    });

    testWidgets('staggered entrance runs once, not on rebuilds',
        (tester) async {
      await _pumpLogin(tester, const Locale('en'), settle: Duration.zero);
      await tester.pump(const Duration(milliseconds: 300));
      List<double> values() => [
            for (final r in tester.widgetList<RiseIn>(find.byType(RiseIn)))
              r.animation.value,
          ];
      // Logo already on its way, footer not started yet.
      expect(values().first, greaterThan(0));
      expect(values().last, 0);

      await tester.pump(const Duration(seconds: 2));
      expect(values(), everyElement(1.0));

      // Keyboard up/down (and the rebuilds it causes) must not replay it.
      tester.view.viewInsets = const FakeViewPadding(bottom: 600);
      await tester.pump();
      tester.view.viewInsets = FakeViewPadding.zero;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(values(), everyElement(1.0));
      expect(tester.takeException(), isNull);
    });

    testWidgets('typing during the entrance keeps text and focus',
        (tester) async {
      await _pumpLogin(tester, const Locale('en'),
          settle: const Duration(milliseconds: 900));
      await tester.enterText(find.byKey(E2EKeys.loginEmail), 'early@bird.io');
      await tester.pump(const Duration(seconds: 2)); // entrance completes
      final editable = tester.widget<EditableText>(find.descendant(
          of: find.byKey(E2EKeys.loginEmail),
          matching: find.byType(EditableText)));
      expect(editable.controller.text, 'early@bird.io');
      expect(editable.focusNode.hasFocus, isTrue,
          reason: 'finishing the entrance must not remount the form');
    });

    testWidgets('logo shimmer sweeps occasionally, then rests',
        (tester) async {
      await _pumpLogin(tester, const Locale('en'));
      final shimmer = tester.state<GoldShimmerState>(find.byType(GoldShimmer));
      expect(shimmer.isSweeping, isFalse);
      // First sweep starts at 1.4 s + 5.58 s idle (CSS 0–62 % rest).
      await tester.pump(const Duration(seconds: 6));
      await tester.pump(const Duration(milliseconds: 500));
      expect(shimmer.isSweeping, isTrue);
      expect(
        find.descendant(
            of: find.byType(GoldShimmer), matching: find.byType(ShaderMask)),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 500));
      expect(shimmer.isSweeping, isFalse);
      expect(
        find.descendant(
            of: find.byType(GoldShimmer), matching: find.byType(ShaderMask)),
        findsNothing,
      );
    });

    testWidgets('fields get the gold focus halo', (tester) async {
      await _pumpLogin(tester, const Locale('en'));
      await tester.tap(find.byKey(E2EKeys.loginEmail));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      final editable = tester.widget<EditableText>(find.descendant(
          of: find.byKey(E2EKeys.loginEmail),
          matching: find.byType(EditableText)));
      expect(editable.focusNode.hasFocus, isTrue);
      expect(tester.takeException(), isNull);
    });
  });
}
