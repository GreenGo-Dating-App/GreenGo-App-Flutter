import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/error/exceptions.dart';
import 'package:greengo_chat/features/authentication/data/datasources/auth_remote_data_source.dart';

/// Master Test Plan — A. Authentication & Session (session reads + provider
/// gating). Exercises the safe, Firebase-Auth-only paths of the remote data
/// source with firebase_auth_mocks (no Firestore/Functions touched here).
void main() {
  group('session reads via MockFirebaseAuth', () {
    test('getCurrentUser returns null when signed out', () async {
      final ds = AuthRemoteDataSourceImpl(firebaseAuth: MockFirebaseAuth());
      expect(await ds.getCurrentUser(), isNull);
    });

    test('getCurrentUser maps the Firebase user to a UserModel', () async {
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(
          uid: 'uid_42',
          email: 'clara@greengo.app',
          displayName: 'Clara Nunes',
          isEmailVerified: true,
        ),
      );
      final ds = AuthRemoteDataSourceImpl(firebaseAuth: auth);

      final user = await ds.getCurrentUser();
      expect(user, isNotNull);
      expect(user!.id, 'uid_42');
      expect(user.email, 'clara@greengo.app');
      expect(user.emailVerified, isTrue);
    });

    test('isSignedIn reflects the auth state', () async {
      final signedOut =
          AuthRemoteDataSourceImpl(firebaseAuth: MockFirebaseAuth());
      final signedIn = AuthRemoteDataSourceImpl(
        firebaseAuth: MockFirebaseAuth(
          signedIn: true,
          mockUser: MockUser(uid: 'u1'),
        ),
      );

      expect(await signedOut.isSignedIn(), isFalse);
      expect(await signedIn.isSignedIn(), isTrue);
    });

    test('signOut clears the current session', () async {
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'u1', email: 'a@b.com'),
      );
      final ds = AuthRemoteDataSourceImpl(firebaseAuth: auth);

      expect(await ds.isSignedIn(), isTrue);
      await ds.signOut();
      expect(await ds.getCurrentUser(), isNull);
    });
  });

  group('disabled social providers throw AuthenticationException', () {
    test('signInWithGoogle throws when not enabled/configured', () async {
      final ds = AuthRemoteDataSourceImpl(firebaseAuth: MockFirebaseAuth());
      expect(
        () => ds.signInWithGoogle(),
        throwsA(isA<AuthenticationException>()),
      );
    });

    test('signInWithFacebook throws when not enabled/configured', () async {
      final ds = AuthRemoteDataSourceImpl(firebaseAuth: MockFirebaseAuth());
      expect(
        () => ds.signInWithFacebook(),
        throwsA(isA<AuthenticationException>()),
      );
    });
  });
}
