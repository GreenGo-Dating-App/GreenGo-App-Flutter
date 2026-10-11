import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/error/exceptions.dart';
import 'package:greengo_chat/core/utils/auth_error_localizer.dart';
import 'package:greengo_chat/features/authentication/data/datasources/auth_remote_data_source.dart';
import 'package:greengo_chat/features/authentication/data/datasources/nickname_sign_in.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

/// INC-2026-001: nickname sign-in goes through the `signInWithNickname`
/// callable (custom token); the client never reads an email from
/// nicknames/{nick}, and the mapping it keeps holds no email.
void main() {
  group('NicknameSignIn.nicknameFromIdentifier', () {
    test('emails are not nicknames', () {
      expect(NicknameSignIn.nicknameFromIdentifier('a@b.com'), isNull);
      expect(NicknameSignIn.nicknameFromIdentifier('  a@b.com '), isNull);
      expect(NicknameSignIn.nicknameFromIdentifier('@a@b.com'), isNull);
      expect(NicknameSignIn.nicknameFromIdentifier('   '), isNull);
      expect(NicknameSignIn.nicknameFromIdentifier('@'), isNull);
    });

    test('nickname is trimmed, @-stripped and lower-cased', () {
      expect(NicknameSignIn.nicknameFromIdentifier('Bobby'), 'bobby');
      expect(NicknameSignIn.nicknameFromIdentifier(' @Bob_Y '), 'bob_y');
    });
  });

  group('NicknameSignIn.mapError', () {
    String msg(String code, [Object? details]) =>
        NicknameSignIn.mapError(code, details).message;

    test('wrong password and unknown nickname look the same', () {
      expect(msg('unauthenticated', {'code': 'INVALID_CREDENTIALS'}),
          NicknameSignIn.invalidCredentials);
      expect(msg('invalid-argument'), NicknameSignIn.invalidCredentials);
    });

    test('rate limit, disabled, MFA, server failure, network', () {
      expect(msg('resource-exhausted'), NicknameSignIn.tooManyRequests);
      expect(msg('permission-denied', {'code': 'USER_DISABLED'}),
          NicknameSignIn.accountDisabled);
      expect(msg('failed-precondition', {'code': 'MFA_REQUIRED'}),
          NicknameSignIn.mfaRequired);
      expect(msg('unavailable', {'code': 'UNAVAILABLE'}),
          NicknameSignIn.signInFailed);
      expect(msg('unavailable'), startsWith('NETWORK_ERROR'));
      expect(msg('not-found'), NicknameSignIn.signInFailed);
      expect(msg('internal'), NicknameSignIn.signInFailed);
    });
  });

  group('AuthRemoteDataSourceImpl.signInWithEmail with a nickname', () {
    late FakeFirebaseFirestore db;
    late MockFirebaseAuth auth;

    setUp(() async {
      db = FakeFirebaseFirestore();
      auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'uid_bob', email: 'bob@example.com'),
      );
      await db.collection('profiles').doc('uid_bob').set({'nickname': 'bobby'});
    });

    test('calls the server with nickname + password and signs in with the custom token',
        () async {
      final calls = <List<String>>[];
      final ds = AuthRemoteDataSourceImpl(
        firebaseAuth: auth,
        firestore: db,
        nicknameTokenFetcher: (n, p) async {
          calls.add([n, p]);
          return 'custom-token';
        },
      );

      final user = await ds.signInWithEmail(email: '@Bobby', password: 'pw-123');

      expect(calls, [
        ['bobby', 'pw-123'],
      ]);
      expect(user.id, 'uid_bob');
      expect(auth.currentUser?.uid, 'uid_bob');
    });

    test('rewrites a legacy nickname doc WITHOUT the email', () async {
      await db.collection('nicknames').doc('bobby').set({
        'email': 'bob@example.com',
        'uid': 'uid_bob',
      });
      final ds = AuthRemoteDataSourceImpl(
        firebaseAuth: auth,
        firestore: db,
        nicknameTokenFetcher: (_, __) async => 'custom-token',
      );

      await ds.signInWithEmail(email: 'bobby', password: 'pw');

      final doc = (await db.collection('nicknames').doc('bobby').get()).data()!;
      expect(doc.containsKey('email'), isFalse);
      expect(doc['uid'], 'uid_bob');
      expect(doc['nickname'], 'bobby');
      expect(doc.keys.toSet(), {'uid', 'nickname', 'createdAt'});
      // The email still lands in the owner-only places.
      final priv = (await db.collection('profiles_private').doc('uid_bob').get()).data();
      expect(priv?['email'], 'bob@example.com');
    });

    test("never touches someone else's nickname mapping", () async {
      await db.collection('nicknames').doc('bobby').set({'uid': 'someone_else'});
      final ds = AuthRemoteDataSourceImpl(
        firebaseAuth: auth,
        firestore: db,
        nicknameTokenFetcher: (_, __) async => 'custom-token',
      );

      await ds.signInWithEmail(email: 'bobby', password: 'pw');

      final doc = (await db.collection('nicknames').doc('bobby').get()).data()!;
      expect(doc, {'uid': 'someone_else'});
    });

    test('server refusal surfaces the generic invalid-credentials error', () async {
      final ds = AuthRemoteDataSourceImpl(
        firebaseAuth: auth,
        firestore: db,
        nicknameTokenFetcher: (_, __) async => throw FirebaseFunctionsException(
          code: 'unauthenticated',
          message: 'Invalid credentials',
          details: {'code': 'INVALID_CREDENTIALS'},
        ),
      );

      await expectLater(
        ds.signInWithEmail(email: 'bobby', password: 'wrong'),
        throwsA(isA<AuthenticationException>()
            .having((e) => e.message, 'message', NicknameSignIn.invalidCredentials)),
      );
      expect(auth.currentUser, isNull);
    });

    test('MFA accounts are told to use their email', () async {
      final ds = AuthRemoteDataSourceImpl(
        firebaseAuth: auth,
        firestore: db,
        nicknameTokenFetcher: (_, __) async => throw FirebaseFunctionsException(
          code: 'failed-precondition',
          message: 'MFA_REQUIRED',
          details: {'code': 'MFA_REQUIRED'},
        ),
      );

      await expectLater(
        ds.signInWithEmail(email: 'bobby', password: 'pw'),
        throwsA(isA<AuthenticationException>()
            .having((e) => e.message, 'message', NicknameSignIn.mfaRequired)),
      );
    });

    test('an email identifier never calls the nickname callable', () async {
      var called = false;
      final ds = AuthRemoteDataSourceImpl(
        firebaseAuth: auth,
        firestore: db,
        nicknameTokenFetcher: (_, __) async {
          called = true;
          return 'x';
        },
      );

      final user = await ds.signInWithEmail(email: 'bob@example.com', password: 'pw');

      expect(called, isFalse);
      expect(user.id, 'uid_bob');
      final doc = (await db.collection('nicknames').doc('bobby').get()).data()!;
      expect(doc.containsKey('email'), isFalse);
    });
  });

  testWidgets('AuthErrorLocalizer maps the nickname codes', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      }),
    ));
    final l10n = AppLocalizations.of(ctx)!;
    expect(AuthErrorLocalizer.getLocalizedError(ctx, NicknameSignIn.mfaRequired),
        l10n.authErrorNicknameMfaRequired);
    expect(AuthErrorLocalizer.getLocalizedError(ctx, NicknameSignIn.signInFailed),
        l10n.authErrorNicknameSignInFailed);
    expect(AuthErrorLocalizer.getLocalizedError(ctx, NicknameSignIn.invalidCredentials),
        l10n.authErrorInvalidCredentials);
    expect(AuthErrorLocalizer.getLocalizedError(ctx, NicknameSignIn.tooManyRequests),
        l10n.authErrorTooManyRequests);
  });
}
