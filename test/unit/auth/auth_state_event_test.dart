import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/authentication/presentation/bloc/auth_event.dart';
import 'package:greengo_chat/features/authentication/presentation/bloc/auth_state.dart';

import '../../support/auth_fixtures.dart';

/// Master Test Plan — A. Authentication & Session (state machine contracts).
/// Equatable props tests for auth events/states so BLoC transition assertions
/// elsewhere are meaningful (distinct payloads => distinct instances).
void main() {
  group('AuthEvent equality', () {
    test('sign-in events with same credentials are equal', () {
      expect(
        const AuthSignInWithEmailRequested(
            email: 'a@b.com', password: 'pw'),
        const AuthSignInWithEmailRequested(
            email: 'a@b.com', password: 'pw'),
      );
    });

    test('sign-in events differ when password differs', () {
      expect(
        const AuthSignInWithEmailRequested(email: 'a@b.com', password: 'pw'),
        isNot(const AuthSignInWithEmailRequested(
            email: 'a@b.com', password: 'other')),
      );
    });

    test('register events carry email + password in props', () {
      const e = AuthRegisterWithEmailRequested(
          email: 'x@y.com', password: 'Secret1!');
      expect(e.props, ['x@y.com', 'Secret1!']);
    });

    test('password-reset event exposes the email in props', () {
      const e = AuthPasswordResetRequested('reset@me.com');
      expect(e.props, ['reset@me.com']);
    });
  });

  group('AuthState equality', () {
    test('AuthAuthenticated is equal for the same user', () {
      final user = buildTestUser();
      expect(AuthAuthenticated(user), AuthAuthenticated(user));
    });

    test('AuthAuthenticated differs for different users', () {
      expect(
        AuthAuthenticated(buildTestUser(id: 'a')),
        isNot(AuthAuthenticated(buildTestUser(id: 'b'))),
      );
    });

    test('AuthError with the same message are equal (message-only equality)', () {
      // Actual behaviour: AuthError equality is driven by its message only.
      final a = AuthError('boom');
      final b = AuthError('boom');
      expect(a.message, b.message);
      expect(a == b, isTrue);
      expect(a, isNot(AuthError('different')));
    });

    test('const singleton states are equal', () {
      expect(const AuthUnauthenticated(), const AuthUnauthenticated());
      expect(const AuthLoading(), const AuthLoading());
      expect(const AuthPasswordResetSent(), const AuthPasswordResetSent());
    });

    test('AuthWaitingForAccess carries approval + tier metadata', () {
      final state = AuthWaitingForAccess(
        user: buildTestUser(),
        approvalStatus: 'pending',
        accessDate: kFixedNow,
        membershipTier: 'gold',
        canAccessApp: false,
      );
      expect(state.approvalStatus, 'pending');
      expect(state.membershipTier, 'gold');
      expect(state.canAccessApp, isFalse);
    });
  });
}
