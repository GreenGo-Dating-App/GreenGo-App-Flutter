// AuthCheckAccessStatusRequested must never sign the user out of the UI over
// a failed read. It used to emit AuthUnauthenticated when getCurrentUser
// failed or the pre-launch access read came back empty, which made AuthWrapper
// drop the session and swap the running app for the login screen while the
// user was still signed in — reported as "the app restarts by itself".
import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/error/failures.dart';
import 'package:greengo_chat/core/services/access_control_service.dart';
import 'package:greengo_chat/features/authentication/domain/entities/user.dart';
import 'package:greengo_chat/features/authentication/domain/repositories/auth_repository.dart';
import 'package:greengo_chat/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:greengo_chat/features/authentication/presentation/bloc/auth_event.dart';
import 'package:greengo_chat/features/authentication/presentation/bloc/auth_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements AuthRepository {}

class _MockAccess extends Mock implements AccessControlService {}

void main() {
  late _MockRepo repo;
  late _MockAccess access;
  final user = User(
    id: 'u1',
    email: 'u1@example.com',
    emailVerified: true,
    createdAt: DateTime(2026),
  );

  setUp(() {
    repo = _MockRepo();
    access = _MockAccess();
    when(() => repo.authStateChanges)
        .thenAnswer((_) => const Stream<User?>.empty());
  });

  Future<List<AuthState>> run() async {
    final bloc = AuthBloc(repository: repo, accessControlService: access);
    final seen = <AuthState>[];
    final sub = bloc.stream.listen(seen.add);
    bloc.add(const AuthCheckAccessStatusRequested());
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await sub.cancel();
    await bloc.close();
    return seen;
  }

  test('getCurrentUser failure keeps the current state', () async {
    when(() => access.isPreLaunchMode).thenReturn(false);
    when(() => repo.getCurrentUser())
        .thenAnswer((_) async => const Left(NetworkFailure('offline')));
    expect(await run(), isEmpty);
  });

  test('pre-launch access read failure keeps the current state', () async {
    when(() => access.isPreLaunchMode).thenReturn(true);
    when(() => repo.getCurrentUser()).thenAnswer((_) async => Right(user));
    when(() => access.getCurrentUserAccess()).thenAnswer((_) async => null);
    expect(await run(), isEmpty);
  });

  test('pre-launch access read that throws keeps the current state', () async {
    when(() => access.isPreLaunchMode).thenReturn(true);
    when(() => repo.getCurrentUser()).thenAnswer((_) async => Right(user));
    when(() => access.getCurrentUserAccess()).thenThrow(StateError('boom'));
    expect(await run(), isEmpty);
  });

  test('signed-in user after launch stays authenticated', () async {
    when(() => access.isPreLaunchMode).thenReturn(false);
    when(() => repo.getCurrentUser()).thenAnswer((_) async => Right(user));
    expect(await run(), [AuthAuthenticated(user)]);
  });

  test('genuinely signed out still reports unauthenticated', () async {
    when(() => access.isPreLaunchMode).thenReturn(false);
    when(() => repo.getCurrentUser()).thenAnswer((_) async => const Right(null));
    expect(await run(), [const AuthUnauthenticated()]);
  });
}
