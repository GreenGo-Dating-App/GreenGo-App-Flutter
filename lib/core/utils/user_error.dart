import 'dart:async';
import 'dart:io' show HttpException, SocketException;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' show ClientException;

import '../../generated/app_localizations.dart';
import '../constants/app_colors.dart';
import '../error/failures.dart';
import '../widgets/connection_error_dialog.dart';
import 'auth_error_localizer.dart';
import '../services/analytics_consent_service.dart';

/// User-facing error handling.
///
/// The rule: an error the user sees is a POPUP with friendly, localized text.
/// Never a snackbar with `e.toString()`, an exception class name, a Firestore
/// path or English developer text ("Failed to load: FormatException...").
///
/// * [userErrorMessage] maps any thrown object to localized text (use it for
///   inline full-screen error states).
/// * [showUserError] logs the raw error and shows the popup.
/// * [showUserErrorMessage] shows the popup for a message the caller already
///   localized (e.g. a domain-specific refusal such as a booking failure).

/// What kind of problem an error represents, independent of the language.
enum UserErrorKind {
  generic,
  network,
  timeout,
  serverUnavailable,
  permissionDenied,
  notFound,
  tooManyRequests,
  sessionExpired,
  invalidInput,
  notAllowed,
  upload,
  auth,

  /// Coin refusals from the server (spendCoins / gift callables). Matched on
  /// the reason code the server puts in `details.reason` and the message.
  insufficientCoins,
  giftPurchaseHold,
  giftVelocityLimit,
}

/// Server coin refusal reason code -> kind.
const Map<String, UserErrorKind> _coinReasonKinds = {
  'insufficient-coins': UserErrorKind.insufficientCoins,
  'gift-purchase-hold': UserErrorKind.giftPurchaseHold,
  'gift-velocity-limit': UserErrorKind.giftVelocityLimit,
};

UserErrorKind? _coinKindForText(String text) {
  for (final e in _coinReasonKinds.entries) {
    if (text.contains(e.key)) return e.value;
  }
  return null;
}

/// Classifies [error] without needing a [BuildContext] (pure; unit-tested).
UserErrorKind classifyUserError(Object? error) {
  if (error == null) return UserErrorKind.generic;

  if (error is FirebaseAuthException) {
    if (error.code == 'network-request-failed') return UserErrorKind.network;
    if (error.code == 'too-many-requests') return UserErrorKind.tooManyRequests;
    if (error.code == 'requires-recent-login' ||
        error.code == 'user-token-expired') {
      return UserErrorKind.sessionExpired;
    }
    return UserErrorKind.auth;
  }
  if (error is FirebaseFunctionsException) {
    final details = error.details;
    final reason = details is Map ? details['reason'] : null;
    if (reason is String && _coinReasonKinds.containsKey(reason)) {
      return _coinReasonKinds[reason]!;
    }
    return _coinKindForText(error.message ?? '') ??
        _kindForCode(error.code) ??
        UserErrorKind.generic;
  }
  if (error is FirebaseException) {
    if (error.plugin == 'firebase_storage') {
      switch (error.code) {
        case 'unauthorized':
          return UserErrorKind.permissionDenied;
        case 'unauthenticated':
          return UserErrorKind.sessionExpired;
        case 'object-not-found':
          return UserErrorKind.notFound;
        case 'retry-limit-exceeded':
          return UserErrorKind.network;
        default:
          return UserErrorKind.upload;
      }
    }
    return _kindForCode(error.code) ?? UserErrorKind.generic;
  }

  if (error is SocketException ||
      error is HttpException ||
      error is ClientException) {
    return UserErrorKind.network;
  }
  if (error is TimeoutException) return UserErrorKind.timeout;
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return UserErrorKind.timeout;
      case DioExceptionType.connectionError:
        return UserErrorKind.network;
      default:
        final status = error.response?.statusCode ?? 0;
        if (status == 401) return UserErrorKind.sessionExpired;
        if (status == 403) return UserErrorKind.permissionDenied;
        if (status == 404) return UserErrorKind.notFound;
        if (status == 429) return UserErrorKind.tooManyRequests;
        if (status >= 500) return UserErrorKind.serverUnavailable;
        return UserErrorKind.generic;
    }
  }
  // Data-shape problems are bugs, never something the user can act on.
  if (error is FormatException || error is TypeError) {
    return UserErrorKind.generic;
  }

  if (error is NetworkFailure) return UserErrorKind.network;
  if (error is PermissionDeniedFailure) return UserErrorKind.permissionDenied;
  if (error is UploadFailure) return UserErrorKind.upload;
  if (error is ValidationFailure) return UserErrorKind.invalidInput;
  if (error is AuthenticationFailure ||
      error is InvalidCredentialsFailure ||
      error is UserNotFoundFailure ||
      error is EmailAlreadyInUseFailure ||
      error is WeakPasswordFailure ||
      error is InvalidEmailFailure) {
    return UserErrorKind.auth;
  }
  if (error is Failure) return _kindForText(error.message);

  // Wrapped exceptions (`Exception('Failed to send: $e')`), raw strings from
  // BLoC states, etc.: look for a known cause in the text, otherwise generic.
  return _kindForText(error.toString());
}

UserErrorKind? _kindForCode(String code) {
  switch (code) {
    case 'permission-denied':
      return UserErrorKind.permissionDenied;
    case 'unavailable':
      return UserErrorKind.serverUnavailable;
    case 'deadline-exceeded':
      return UserErrorKind.timeout;
    case 'not-found':
      return UserErrorKind.notFound;
    case 'resource-exhausted':
      return UserErrorKind.tooManyRequests;
    case 'unauthenticated':
      return UserErrorKind.sessionExpired;
    case 'failed-precondition':
      return UserErrorKind.notAllowed;
    case 'invalid-argument':
    case 'out-of-range':
      return UserErrorKind.invalidInput;
    case 'network-request-failed':
      return UserErrorKind.network;
  }
  return null;
}

UserErrorKind _kindForText(String raw) {
  final coinKind = _coinKindForText(raw);
  if (coinKind != null) return coinKind;
  final s = raw.toLowerCase();
  bool has(String p) => s.contains(p);
  if (has('permission-denied') || has('permission_denied') ||
      has('permission denied') || has('insufficient permissions')) {
    return UserErrorKind.permissionDenied;
  }
  if (has('unauthenticated') || has('not authenticated') ||
      has('not logged in') || has('not signed in') ||
      has('user not authenticated')) {
    return UserErrorKind.sessionExpired;
  }
  if (has('socketexception') || has('failed host lookup') ||
      has('network-request-failed') || has('network error') ||
      has('no internet') || has('connection refused') ||
      has('connection reset') || has('connection closed') ||
      has('clientexception')) {
    return UserErrorKind.network;
  }
  if (has('deadline-exceeded') || has('timeoutexception') ||
      has('timed out') || has('timeout')) {
    return UserErrorKind.timeout;
  }
  if (has('[cloud_firestore/unavailable]') || has('unavailable')) {
    return UserErrorKind.serverUnavailable;
  }
  if (has('resource-exhausted') || has('too many requests') ||
      has('too-many-requests') || has('rate limit')) {
    return UserErrorKind.tooManyRequests;
  }
  if (has('[firebase_storage/')) return UserErrorKind.upload;
  if (has('not-found') || has('object-not-found')) {
    return UserErrorKind.notFound;
  }
  if (has('failed-precondition')) return UserErrorKind.notAllowed;
  if (has('invalid-argument')) return UserErrorKind.invalidInput;
  return UserErrorKind.generic;
}

/// Localized, user-friendly text for [error]. Never returns raw error text.
String userErrorMessage(BuildContext context, Object? error) {
  final l10n = AppLocalizations.of(context);
  if (l10n == null) return 'Something went wrong. Please try again.';
  final kind = classifyUserError(error);
  if (kind == UserErrorKind.auth) {
    final code = error is FirebaseAuthException
        ? error.code
        : error is Failure
            ? error.message
            : '';
    return AuthErrorLocalizer.getLocalizedError(context, code);
  }
  return userErrorMessageForKind(l10n, kind);
}

/// Localized text for an already-classified [kind].
String userErrorMessageForKind(AppLocalizations l10n, UserErrorKind kind) {
  switch (kind) {
    case UserErrorKind.network:
      return l10n.connectionErrorMessage;
    case UserErrorKind.timeout:
      return l10n.userErrorTimeout;
    case UserErrorKind.serverUnavailable:
      return l10n.serverUnavailableMessage;
    case UserErrorKind.permissionDenied:
      return l10n.userErrorPermissionDenied;
    case UserErrorKind.notFound:
      return l10n.userErrorNotFound;
    case UserErrorKind.tooManyRequests:
      return l10n.userErrorTooManyRequests;
    case UserErrorKind.sessionExpired:
      return l10n.userErrorSessionExpired;
    case UserErrorKind.invalidInput:
      return l10n.userErrorInvalidInput;
    case UserErrorKind.notAllowed:
      return l10n.userErrorNotAllowed;
    case UserErrorKind.upload:
      return l10n.userErrorUploadFailed;
    case UserErrorKind.auth:
      return l10n.authErrorGeneric;
    case UserErrorKind.insufficientCoins:
      return l10n.coinsInsufficientCoins;
    case UserErrorKind.giftPurchaseHold:
      return l10n.coinsGiftPurchaseHold;
    case UserErrorKind.giftVelocityLimit:
      return l10n.coinsGiftDailyLimit;
    case UserErrorKind.generic:
      return l10n.userErrorGeneric;
  }
}

/// Popup title for [error].
String userErrorTitle(BuildContext context, Object? error) {
  final l10n = AppLocalizations.of(context);
  if (l10n == null) return 'Oops!';
  switch (classifyUserError(error)) {
    case UserErrorKind.network:
      return l10n.connectionErrorTitle;
    case UserErrorKind.serverUnavailable:
      return l10n.serverUnavailableTitle;
    default:
      return l10n.userErrorTitle;
  }
}

/// Logs the raw [error] for developers (console + Crashlytics non-fatal for
/// unexpected errors). Never shown to the user.
void reportUserError(Object? error, [StackTrace? stackTrace]) {
  debugPrint('[UserError] ${error.runtimeType}: $error');
  if (stackTrace != null) debugPrint(stackTrace.toString());
  if (kIsWeb || kDebugMode || error == null) return;
  final kind = classifyUserError(error);
  // Connectivity / permission / quota problems are expected in the field;
  // only unexpected failures are worth a Crashlytics report.
  if (kind != UserErrorKind.generic && kind != UserErrorKind.upload) return;
  try {
    if (Firebase.apps.isEmpty) return;
    if (!AnalyticsConsentService.instance.collectionAllowed) return;
    FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace ?? StackTrace.current,
      reason: 'user-facing error',
      fatal: false,
    );
  } catch (_) {
    // Crashlytics unavailable: logging must never break the UI.
  }
}

bool _userErrorDialogOpen = false;

/// Whether a user-error popup is currently on screen (for tests).
@visibleForTesting
bool get isUserErrorDialogOpen => _userErrorDialogOpen;

@visibleForTesting
void resetUserErrorDialogGuard() => _userErrorDialogOpen = false;

/// Logs [error] and shows a friendly, localized error popup.
///
/// No-op when [context] is unmounted or another error popup is already open
/// (no stacked duplicates).
Future<void> showUserError(
  BuildContext context,
  Object? error, {
  String? title,
  VoidCallback? onRetry,
  StackTrace? stackTrace,
}) {
  reportUserError(error, stackTrace);
  if (!context.mounted) return Future<void>.value();
  final kind = classifyUserError(error);
  return _showErrorDialog(
    context,
    title: title ?? userErrorTitle(context, error),
    message: userErrorMessage(context, error),
    icon: kind == UserErrorKind.network
        ? Icons.wifi_off
        : kind == UserErrorKind.serverUnavailable
            ? Icons.cloud_off
            : Icons.error_outline,
    iconColor: kind == UserErrorKind.network
        ? AppColors.errorRed
        : AppColors.warningAmber,
    onRetry: onRetry,
  );
}

/// Shows the error popup for a [message] the caller already localized.
Future<void> showUserErrorMessage(
  BuildContext context,
  String message, {
  String? title,
  VoidCallback? onRetry,
}) {
  if (!context.mounted) return Future<void>.value();
  final l10n = AppLocalizations.of(context);
  return _showErrorDialog(
    context,
    title: title ?? l10n?.userErrorTitle ?? 'Oops!',
    message: message,
    icon: Icons.error_outline,
    iconColor: AppColors.warningAmber,
    onRetry: onRetry,
  );
}

Future<void> _showErrorDialog(
  BuildContext context, {
  required String title,
  required String message,
  required IconData icon,
  required Color iconColor,
  VoidCallback? onRetry,
}) async {
  if (_userErrorDialogOpen) return;
  final navigator = Navigator.maybeOf(context, rootNavigator: true);
  if (navigator == null) return;
  _userErrorDialogOpen = true;
  try {
    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierColor: Colors.black54,
      builder: (ctx) => ConnectionErrorDialog(
        title: title,
        message: message,
        icon: icon,
        iconColor: iconColor,
        onRetry: onRetry,
        showRetryButton: onRetry != null,
        dismissLabel: AppLocalizations.of(ctx)?.ok,
      ),
    );
  } finally {
    _userErrorDialogOpen = false;
  }
}
