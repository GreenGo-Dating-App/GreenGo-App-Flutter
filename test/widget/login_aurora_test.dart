import 'dart:ui' as ui;

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/constants/e2e_keys.dart';
import 'package:greengo_chat/core/error/failures.dart';
import 'package:greengo_chat/core/providers/language_provider.dart';
import 'package:greengo_chat/core/widgets/aurora_background.dart';
import 'package:greengo_chat/features/authentication/domain/entities/user.dart'
    as domain;
import 'package:greengo_chat/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:greengo_chat/features/authentication/presentation/screens/login_screen.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../support/auth_fixtures.dart';

AuroraBackgroundState _auroraState(WidgetTester tester) =>
    tester.state<AuroraBackgroundState>(find.byType(AuroraBackground));

CustomPainter? _layerPainter(WidgetTester tester) => tester
    .widget<CustomPaint>(find.byKey(const ValueKey('aurora_background_layer')))
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

Future<void> _pumpLogin(WidgetTester tester, Locale locale,
    {bool reducedMotion = false}) async {
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
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  group('AuroraBackground', () {
    testWidgets('falls back to the Dart painter when the shader fails to load',
        (tester) async {
      await tester.pumpWidget(_host(AuroraBackground(
        programLoader: () async => throw Exception('no shader support'),
        child: const Text('child'),
      )));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('child'), findsOneWidget);
      expect(_auroraState(tester).usingShader, isFalse);
      expect(_layerPainter(tester), isA<AuroraFallbackPainter>());
      expect(_auroraState(tester).isAnimating, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('useShader:false renders the fallback without loading',
        (tester) async {
      var loads = 0;
      await tester.pumpWidget(_host(AuroraBackground(
        useShader: false,
        programLoader: () async {
          loads++;
          throw Exception('should not be called');
        },
        child: const SizedBox(),
      )));
      await tester.pump();
      expect(loads, 0);
      expect(_layerPainter(tester), isA<AuroraFallbackPainter>());
    });

    testWidgets('uses the fragment shader when it loads', (tester) async {
      ui.FragmentProgram? program;
      await tester.runAsync(() async {
        try {
          program =
              await ui.FragmentProgram.fromAsset(AuroraBackground.shaderAsset);
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
      await tester.pumpWidget(_host(AuroraBackground(
        programLoader: () async => program!,
        child: const SizedBox(),
      )));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(_auroraState(tester).usingShader, isTrue);
      expect(_layerPainter(tester), isNot(isA<AuroraFallbackPainter>()));
    });

    testWidgets('reduced motion renders a static frame (no ticker)',
        (tester) async {
      await tester.pumpWidget(_host(
        const AuroraBackground(useShader: false, child: SizedBox()),
        reducedMotion: true,
      ));
      await tester.pump(const Duration(seconds: 1));
      expect(_auroraState(tester).isAnimating, isFalse);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('pauses when the app is backgrounded and resumes after',
        (tester) async {
      await tester.pumpWidget(_host(
        const AuroraBackground(useShader: false, child: SizedBox()),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      expect(_auroraState(tester).isAnimating, isTrue);

      tester.binding
          .handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(_auroraState(tester).isAnimating, isFalse);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding
          .handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(_auroraState(tester).isAnimating, isTrue);
    });

    testWidgets('the child is isolated from the animated layer',
        (tester) async {
      var builds = 0;
      await tester.pumpWidget(_host(AuroraBackground(
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
          of: find.byKey(const ValueKey('aurora_background_layer')),
          matching: find.byType(RepaintBoundary),
        ),
        findsWidgets,
      );
    });
  });

  group('LoginScreen (calm aurora)', () {
    setUpAll(() => AuroraBackground.debugResetProgramCache());

    testWidgets('form keys, aurora and tagline are present', (tester) async {
      await _pumpLogin(tester, const Locale('en'));
      expect(find.byType(AuroraBackground), findsOneWidget);
      expect(find.byKey(E2EKeys.loginEmail), findsOneWidget);
      expect(find.byKey(E2EKeys.loginPassword), findsOneWidget);
      expect(find.byKey(E2EKeys.loginSubmit), findsOneWidget);
      expect(
        find.text('Discover cultures. Connect without language barriers.'),
        findsOneWidget,
      );
    });

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
      });
    }

    testWidgets('reduced motion → static background on the login screen',
        (tester) async {
      await _pumpLogin(tester, const Locale('en'), reducedMotion: true);
      expect(_auroraState(tester).isAnimating, isFalse);
    });
  });
}
