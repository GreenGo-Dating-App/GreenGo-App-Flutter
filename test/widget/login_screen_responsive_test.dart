import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/error/failures.dart';
import 'package:greengo_chat/core/providers/language_provider.dart';
import 'package:greengo_chat/features/authentication/domain/entities/user.dart'
    as domain;
import 'package:greengo_chat/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:greengo_chat/features/authentication/presentation/screens/login_screen.dart';
import 'package:greengo_chat/features/authentication/presentation/widgets/auth_button.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../support/auth_fixtures.dart';

/// Regression cover for the App Store 2.1 rejection on iPad Air 13" (M3):
/// "no further action occurred after tapping on the Login button".
///
/// Root cause: with the on-screen keyboard open in landscape the Scaffold
/// shrank the body to ~604pt while the fixed 320pt header pushed the Login
/// button to y=608..656 — behind the keyboard, so the tap never reached the
/// handler. Phones never hit it because the form is scrolled anyway there.
MockAuthRepository _pumpRepo() {
  final repo = MockAuthRepository();
  when(() => repo.authStateChanges)
      .thenAnswer((_) => const Stream<domain.User?>.empty());
  when(() => repo.signInWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenAnswer(
          (_) async => const Left<Failure, domain.User>(AuthenticationFailure()));
  return repo;
}

Future<void> pumpLogin(
  WidgetTester tester,
  MockAuthRepository repo,
  Size size, {
  double keyboard = 0,
}) async {
  tester.view.devicePixelRatio = 2.0;
  tester.view.physicalSize = size * 2.0;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard * 2.0);
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
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: LoginScreen(),
      ),
    ),
  );
  // Particles animate forever — pump past the entry animation, don't settle.
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  const viewports = <String, List<Object>>{
    'phone portrait': [Size(393, 852), 0.0],
    'phone portrait + keyboard': [Size(393, 852), 336.0],
    'tablet portrait': [Size(1024, 1366), 0.0],
    'tablet portrait + keyboard': [Size(1024, 1366), 400.0],
    'tablet landscape': [Size(1366, 1024), 0.0],
    'tablet landscape + keyboard': [Size(1366, 1024), 420.0],
    'split view, short window': [Size(507, 620), 0.0],
  };

  viewports.forEach((name, spec) {
    final size = spec[0] as Size;
    final keyboard = spec[1] as double;

    testWidgets('Login button stays above the keyboard — $name',
        (tester) async {
      final repo = _pumpRepo();
      await pumpLogin(tester, repo, size, keyboard: keyboard);

      final button = find.byType(AuthButton);
      expect(button, findsOneWidget);

      final rect = tester.getRect(button);
      expect(
        rect.bottom,
        lessThanOrEqualTo(size.height - keyboard),
        reason: 'Login button ($rect) must not sit under the keyboard '
            '(visible to ${size.height - keyboard}) on $name',
      );
      expect(find.byType(AuthButton).hitTestable(), findsOneWidget);
    });

    testWidgets('tapping Login reaches the auth repository — $name',
        (tester) async {
      final repo = _pumpRepo();
      await pumpLogin(tester, repo, size, keyboard: keyboard);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'reviewer@greengo.app');
      await tester.enterText(fields.at(1), 'Password123!');
      await tester.pump();

      await tester.tap(find.byType(AuthButton));
      await tester.pump();

      verify(() => repo.signInWithEmail(
            email: 'reviewer@greengo.app',
            password: 'Password123!',
          )).called(1);
    });
  });

  testWidgets('the keyboard Go key submits the form', (tester) async {
    final repo = _pumpRepo();
    await pumpLogin(tester, repo, const Size(1366, 1024), keyboard: 420);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'reviewer@greengo.app');
    await tester.enterText(fields.at(1), 'Password123!');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pump();

    verify(() => repo.signInWithEmail(
          email: 'reviewer@greengo.app',
          password: 'Password123!',
        )).called(1);
  });

  testWidgets('form is width-capped on a wide screen', (tester) async {
    final repo = _pumpRepo();
    await pumpLogin(tester, repo, const Size(1366, 1024));
    expect(tester.getSize(find.byType(AuthButton)).width,
        lessThanOrEqualTo(480.0));
  });
}
