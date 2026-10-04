import 'dart:async';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/error/failures.dart';
import 'package:greengo_chat/core/utils/user_error.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

FirebaseFunctionsException _fn(String code, [Object? details]) =>
    FirebaseFunctionsException(
        code: code, message: 'Internal dev text', details: details);

void main() {
  group('classifyUserError', () {
    test('Firestore / Functions codes', () {
      final cases = <String, UserErrorKind>{
        'permission-denied': UserErrorKind.permissionDenied,
        'unavailable': UserErrorKind.serverUnavailable,
        'deadline-exceeded': UserErrorKind.timeout,
        'not-found': UserErrorKind.notFound,
        'resource-exhausted': UserErrorKind.tooManyRequests,
        'unauthenticated': UserErrorKind.sessionExpired,
        'failed-precondition': UserErrorKind.notAllowed,
        'invalid-argument': UserErrorKind.invalidInput,
        'internal': UserErrorKind.generic,
      };
      cases.forEach((code, kind) {
        expect(
            classifyUserError(
                FirebaseException(plugin: 'cloud_firestore', code: code)),
            kind,
            reason: 'firestore $code');
        expect(classifyUserError(_fn(code, {'code': 'x'})), kind,
            reason: 'functions $code');
      });
    });

    test('storage errors', () {
      FirebaseException s(String c) =>
          FirebaseException(plugin: 'firebase_storage', code: c);
      expect(classifyUserError(s('unauthorized')),
          UserErrorKind.permissionDenied);
      expect(classifyUserError(s('object-not-found')), UserErrorKind.notFound);
      expect(
          classifyUserError(s('retry-limit-exceeded')), UserErrorKind.network);
      expect(classifyUserError(s('unknown')), UserErrorKind.upload);
    });

    test('auth errors', () {
      expect(classifyUserError(FirebaseAuthException(code: 'wrong-password')),
          UserErrorKind.auth);
      expect(
          classifyUserError(
              FirebaseAuthException(code: 'network-request-failed')),
          UserErrorKind.network);
      expect(
          classifyUserError(FirebaseAuthException(code: 'too-many-requests')),
          UserErrorKind.tooManyRequests);
      expect(classifyUserError(const InvalidCredentialsFailure()),
          UserErrorKind.auth);
    });

    test('parse / type errors are generic', () {
      expect(classifyUserError(const FormatException('error document format')),
          UserErrorKind.generic);
      Object? typeError;
      try {
        final Object v = 'x';
        (v as int).toString();
      } catch (e) {
        typeError = e;
      }
      expect(typeError, isA<TypeError>());
      expect(classifyUserError(typeError), UserErrorKind.generic);
      expect(classifyUserError(Exception('Bad state: document format')),
          UserErrorKind.generic);
      expect(classifyUserError(null), UserErrorKind.generic);
    });

    test('network / timeout', () {
      expect(classifyUserError(const SocketException('Failed host lookup')),
          UserErrorKind.network);
      expect(classifyUserError(TimeoutException('t')), UserErrorKind.timeout);
      expect(classifyUserError(const NetworkFailure()), UserErrorKind.network);
    });

    test('wrapped developer text is classified by cause', () {
      expect(
          classifyUserError(Exception(
              'Failed to send message: [cloud_firestore/permission-denied] '
              'The caller does not have permission')),
          UserErrorKind.permissionDenied);
      expect(
          classifyUserError(
              const ServerFailure('Failed to load: SocketException: x')),
          UserErrorKind.network);
      expect(classifyUserError('Failed to load profile: oops'),
          UserErrorKind.generic);
    });
  });

  group('userErrorMessageForKind', () {
    test('every kind has a localized, non-technical message', () {
      for (final locale in AppLocalizations.supportedLocales) {
        final l10n = lookupAppLocalizations(locale);
        for (final kind in UserErrorKind.values) {
          final msg = userErrorMessageForKind(l10n, kind);
          expect(msg, isNotEmpty);
          expect(msg, isNot(contains('Exception')));
          expect(msg, isNot(contains('{')));
        }
      }
    });
  });

  testWidgets('userErrorMessage never leaks the raw error', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      }),
    ));
    final l10n = lookupAppLocalizations(const Locale('en'));
    final raw = Exception('FormatException: error document format at '
        'users/abc123/profile');
    final msg = userErrorMessage(ctx, raw);
    expect(msg, l10n.userErrorGeneric);
    expect(msg, isNot(contains('users/abc123')));
    expect(userErrorMessage(ctx, FirebaseAuthException(code: 'wrong-password')),
        l10n.authErrorWrongPassword);
    expect(userErrorMessage(ctx, _fn('permission-denied')),
        l10n.userErrorPermissionDenied);
  });
}
