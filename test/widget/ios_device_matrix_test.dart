import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/error/failures.dart';
import 'package:greengo_chat/core/providers/language_provider.dart';
import 'package:greengo_chat/features/authentication/domain/entities/user.dart'
    as domain;
import 'package:greengo_chat/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:greengo_chat/features/authentication/presentation/screens/forgot_password_screen.dart';
import 'package:greengo_chat/features/authentication/presentation/screens/login_screen.dart';
import 'package:greengo_chat/features/authentication/presentation/screens/register_screen.dart';
import 'package:greengo_chat/features/authentication/presentation/widgets/auth_button.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../support/auth_fixtures.dart';
import '../support/ios_viewports.dart';

/// Layout contract for the screens an App Store reviewer walks through,
/// checked against every iOS form factor the app ships to.
///
/// The 2.1 rejection ("no further action occurred after tapping on the Login
/// button") was a layout failure that only appeared at one viewport. These
/// tests assert the invariant that was violated: on every supported device,
/// with and without the keyboard, the primary button must be present, free of
/// overflow, hit-testable, and above the keyboard.

MockAuthRepository buildRepo() {
  final repo = MockAuthRepository();
  when(() => repo.authStateChanges)
      .thenAnswer((_) => const Stream<domain.User?>.empty());
  when(() => repo.signInWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenAnswer(
    (_) async => const Left<Failure, domain.User>(AuthenticationFailure()),
  );
  return repo;
}

Widget wrap(Widget home, MockAuthRepository repo) {
  return MultiProvider(
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
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );
}

/// [shortForm] screens fit on screen at rest, so the user has no cue that
/// anything lies below: their action must stay visible when the keyboard
/// appears. A long form is scrolled by the user anyway, so it only has to be
/// reachable.
typedef ScreenCase = ({
  String name,
  Widget Function() build,
  Finder action,
  bool shortForm,
});

void main() {
  final screens = <ScreenCase>[
    (
      name: 'LoginScreen',
      build: () => const LoginScreen(),
      action: find.byType(AuthButton),
      shortForm: true,
    ),
    (
      name: 'RegisterScreen',
      build: () => const RegisterScreen(),
      action: find.byType(AuthButton),
      // A dozen fields — it never fits, and the user scrolls to submit.
      shortForm: false,
    ),
    (
      name: 'ForgotPasswordScreen',
      build: () => const ForgotPasswordScreen(),
      action: find.byType(AuthButton),
      shortForm: true,
    ),
  ];

  for (final screen in screens) {
    group(screen.name, () {
      for (final viewport in kAllIosViewports) {
        testWidgets('${screen.name} — $viewport', (tester) async {
          final repo = buildRepo();

          // Phase 1 — keyboard down. This is the state the user judges the
          // page by: whether it looks like there is anything to scroll to.
          await pumpAtViewport(tester, wrap(screen.build(), repo), viewport);
          expectNoLayoutOverflow(tester, viewport, context: '(keyboard down)');

          final scrollableAtRest = maxScrollExtentOf(tester) > 0;
          await expectPrimaryActionReachable(tester, screen.action, viewport,
              context: '(keyboard down)');

          // Phase 2 — keyboard up on the same screen.
          final withKeyboard = viewport.keyboardUp;
          await raiseKeyboard(tester, viewport);
          expectNoLayoutOverflow(tester, withKeyboard,
              context: '(keyboard up)');

          if (scrollableAtRest || !screen.shortForm) {
            // The page already scrolled before the keyboard appeared, so the
            // user knows to scroll for the button.
            await expectPrimaryActionReachable(
                tester, screen.action, withKeyboard,
                context: '(keyboard up, page scrolls at rest)');
          } else {
            // Nothing on screen suggested more content, so the button must
            // stay put. This is exactly the iPad case Apple rejected.
            expectPrimaryActionUsable(tester, screen.action, withKeyboard,
                context: '(keyboard up, page did NOT scroll at rest)');
          }
        });
      }
    });
  }
}
