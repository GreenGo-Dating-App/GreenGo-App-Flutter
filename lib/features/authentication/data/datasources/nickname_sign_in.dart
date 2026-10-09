import 'package:cloud_functions/cloud_functions.dart';

import '../../../../core/error/exceptions.dart';

/// Fetches a Firebase custom token for `nickname` + `password` from the
/// `signInWithNickname` callable. Injectable for tests.
typedef NicknameTokenFetcher = Future<String> Function(
  String nickname,
  String password,
);

/// Nickname sign-in (INC-2026-001).
///
/// The app used to read `nicknames/{nick}.email` (publicly readable) and sign
/// in with email + password on the client, which exposed every account email
/// to anyone who knew the nickname. Now the server verifies the password and
/// returns a custom token; the email never reaches the client before sign-in.
class NicknameSignIn {
  NicknameSignIn._();

  /// Stable messages understood by `AuthErrorLocalizer`.
  static const invalidCredentials = 'Invalid credentials';
  static const tooManyRequests = 'Too many requests. Please try again later';
  static const accountDisabled = 'This account has been disabled';
  static const mfaRequired = 'NICKNAME_MFA_REQUIRED';
  static const signInFailed = 'NICKNAME_SIGNIN_FAILED';
  static const networkError =
      'NETWORK_ERROR: Please check your internet connection';

  /// The nickname typed in the "Email / Nickname" field (leading `@`
  /// stripped, lower-cased), or null when the identifier is an email.
  static String? nicknameFromIdentifier(String input) {
    var s = input.trim();
    if (s.startsWith('@')) s = s.substring(1);
    if (s.isEmpty || s.contains('@')) return null;
    return s.toLowerCase();
  }

  /// Default fetcher: the `signInWithNickname` callable.
  static Future<String> fetchToken(String nickname, String password) async {
    final result = await FirebaseFunctions.instance
        .httpsCallable('signInWithNickname')
        .call(<String, dynamic>{'nickname': nickname, 'password': password});
    final data = result.data;
    final token = data is Map ? data['token'] : null;
    if (token is! String || token.isEmpty) {
      throw AuthenticationException(signInFailed);
    }
    return token;
  }

  /// Maps a callable failure to an [AuthenticationException] whose message
  /// `AuthErrorLocalizer` / the login screen understand. Never includes
  /// server text verbatim except the fixed messages above.
  static AuthenticationException mapError(String code, Object? details) {
    final reason = details is Map ? details['code'] : null;
    switch (code) {
      case 'unauthenticated':
      case 'invalid-argument':
        return AuthenticationException(invalidCredentials);
      case 'resource-exhausted':
        return AuthenticationException(tooManyRequests);
      case 'permission-denied':
        return AuthenticationException(accountDisabled);
      case 'failed-precondition':
        return AuthenticationException(
          reason == 'MFA_REQUIRED' ? mfaRequired : signInFailed,
        );
      case 'unavailable':
      case 'deadline-exceeded':
        // The server answers 'unavailable' with details.code UNAVAILABLE when
        // its own config is broken; without details it is the network.
        return AuthenticationException(
          reason == 'UNAVAILABLE' ? signInFailed : networkError,
        );
      default:
        return AuthenticationException(signInFailed);
    }
  }
}
