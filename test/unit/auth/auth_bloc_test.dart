import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/error/failures.dart';
import 'package:greengo_chat/features/authentication/domain/entities/user.dart';
import 'package:greengo_chat/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:greengo_chat/features/authentication/presentation/bloc/auth_event.dart';
import 'package:greengo_chat/features/authentication/presentation/bloc/auth_state.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/auth_fixtures.dart';

/// Master Test Plan — A. Authentication & Session (login / register / logout
/// state transitions). Drives [AuthBloc] with a mocked [AuthRepository] and a
/// mocked AccessControlService (no bloc_test — uses expectLater + emitsInOrder).
void main() {
  late MockAuthRepository repository;
  late MockAccessControlService accessControl;
  late User user;

  setUp(() {
    repository = MockAuthRepository();
    accessControl = MockAccessControlService();
    user = buildTestUser();

    // The bloc subscribes to this in its constructor — keep it inert.
    when(() => repository.authStateChanges)
        .thenAnswer((_) => const Stream<User?>.empty());

    // Side-effects invoked on the success paths — stub so they don't throw.
    when(() => accessControl.refreshUserAccessDate(any(), any()))
        .thenAnswer((_) async {});
    when(() => accessControl.initializeUserAccess(
          userId: any(named: 'userId'),
          email: any(named: 'email'),
        )).thenAnswer((_) async {});
  });

  AuthBloc buildBloc() =>
      AuthBloc(repository: repository, accessControlService: accessControl);

  group('sign in with email', () {
    test('emits [Loading, Authenticated] on success', () async {
      when(() => repository.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => Right(user));

      final bloc = buildBloc();
      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<AuthAuthenticated>()
              .having((s) => s.user.id, 'user.id', user.id),
        ]),
      );

      bloc.add(const AuthSignInWithEmailRequested(
          email: 'ava@greengo.app', password: 'Str0ng!Pass'));
      await expectation;
      await bloc.close();
    });

    test('emits [Loading, Error] on failure', () async {
      when(() => repository.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer(
          (_) async => const Left(InvalidCredentialsFailure()));

      final bloc = buildBloc();
      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<AuthError>().having(
              (s) => s.message, 'message', 'Invalid email or password'),
        ]),
      );

      bloc.add(const AuthSignInWithEmailRequested(
          email: 'ava@greengo.app', password: 'wrong'));
      await expectation;
      await bloc.close();
    });
  });

  group('register with email', () {
    test('emits [Loading, Authenticated] on success', () async {
      when(() => repository.registerWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => Right(user));

      final bloc = buildBloc();
      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthLoading>(), isA<AuthAuthenticated>()]),
      );

      bloc.add(const AuthRegisterWithEmailRequested(
          email: 'new@greengo.app', password: 'Str0ng!Pass'));
      await expectation;
      await bloc.close();
    });

    test('initializes access control on successful registration', () async {
      when(() => repository.registerWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => Right(user));

      final bloc = buildBloc();
      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthLoading>(), isA<AuthAuthenticated>()]),
      );

      bloc.add(const AuthRegisterWithEmailRequested(
          email: 'new@greengo.app', password: 'Str0ng!Pass'));
      await expectation;
      // initializeUserAccess is awaited before AuthAuthenticated is emitted.
      verify(() => accessControl.initializeUserAccess(
            userId: user.uid,
            email: 'new@greengo.app',
          )).called(1);
      await bloc.close();
    });

    test('emits [Loading, Error] when the email is already in use', () async {
      when(() => repository.registerWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer(
          (_) async => const Left(EmailAlreadyInUseFailure()));

      final bloc = buildBloc();
      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<AuthError>()
              .having((s) => s.message, 'message', 'Email already in use'),
        ]),
      );

      bloc.add(const AuthRegisterWithEmailRequested(
          email: 'taken@greengo.app', password: 'Str0ng!Pass'));
      await expectation;
      await bloc.close();
    });
  });

  group('password reset', () {
    test('emits [Loading, PasswordResetSent] on success', () async {
      when(() => repository.sendPasswordResetEmail(any()))
          .thenAnswer((_) async => const Right(null));

      final bloc = buildBloc();
      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthLoading>(), isA<AuthPasswordResetSent>()]),
      );

      bloc.add(const AuthPasswordResetRequested('reset@greengo.app'));
      await expectation;
      await bloc.close();
    });

    test('emits [Loading, Error] on failure', () async {
      when(() => repository.sendPasswordResetEmail(any()))
          .thenAnswer((_) async => const Left(ServerFailure('nope')));

      final bloc = buildBloc();
      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<AuthError>().having((s) => s.message, 'message', 'nope'),
        ]),
      );

      bloc.add(const AuthPasswordResetRequested('reset@greengo.app'));
      await expectation;
      await bloc.close();
    });
  });

  group('logout', () {
    test('emits Unauthenticated after signOut', () async {
      when(() => repository.signOut())
          .thenAnswer((_) async => const Right(null));

      final bloc = buildBloc();
      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthUnauthenticated>()]),
      );

      bloc.add(const AuthSignOutRequested());
      await expectation;
      verify(() => repository.signOut()).called(1);
      await bloc.close();
    });
  });

  group('auth check', () {
    test('emits Authenticated when a current user exists', () async {
      when(() => repository.getCurrentUser())
          .thenAnswer((_) async => Right(user));

      final bloc = buildBloc();
      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthAuthenticated>()]),
      );

      bloc.add(const AuthCheckRequested());
      await expectation;
      await bloc.close();
    });

    test('emits Unauthenticated when no current user', () async {
      when(() => repository.getCurrentUser())
          .thenAnswer((_) async => const Right(null));

      final bloc = buildBloc();
      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthUnauthenticated>()]),
      );

      bloc.add(const AuthCheckRequested());
      await expectation;
      await bloc.close();
    });

    test('emits Unauthenticated when getCurrentUser fails', () async {
      when(() => repository.getCurrentUser())
          .thenAnswer((_) async => const Left(AuthenticationFailure()));

      final bloc = buildBloc();
      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthUnauthenticated>()]),
      );

      bloc.add(const AuthCheckRequested());
      await expectation;
      await bloc.close();
    });
  });

  group('disabled social providers (AppConfig flags off)', () {
    test('Google sign-in emits an Error explaining it is disabled', () async {
      final bloc = buildBloc();
      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthError>()]),
      );

      bloc.add(const AuthSignInWithGoogleRequested());
      await expectation;
      verifyNever(() => repository.signInWithGoogle());
      await bloc.close();
    });

    test('phone sign-in emits [Loading, Error] (not yet available)', () async {
      final bloc = buildBloc();
      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthLoading>(), isA<AuthError>()]),
      );

      bloc.add(const AuthSignInWithPhoneRequested('+15551234567'));
      await expectation;
      await bloc.close();
    });
  });
}
