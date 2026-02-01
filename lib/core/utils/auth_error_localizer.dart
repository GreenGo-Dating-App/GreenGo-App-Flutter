import 'package:flutter/material.dart';
import '../../generated/app_localizations.dart';

/// Utility class to convert auth error messages to localized strings
class AuthErrorLocalizer {
  /// Maps Firebase auth error messages to localized strings
  ///
  /// This function takes the error message from Firebase Auth (which comes in English)
  /// and returns the appropriate localized message based on the current locale.
  static String getLocalizedError(BuildContext context, String errorMessage) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return errorMessage;

    final lowerMessage = errorMessage.toLowerCase();

    // User not found
    if (lowerMessage.contains('no user found') ||
        lowerMessage.contains('user-not-found') ||
        lowerMessage.contains('user not found')) {
      return l10n.authErrorUserNotFound;
    }

    // Wrong password
    if (lowerMessage.contains('wrong password') ||
        lowerMessage.contains('wrong-password') ||
        lowerMessage.contains('incorrect password')) {
      return l10n.authErrorWrongPassword;
    }

    // Invalid email
    if (lowerMessage.contains('invalid email') ||
        lowerMessage.contains('invalid-email') ||
        lowerMessage.contains('badly formatted')) {
      return l10n.authErrorInvalidEmail;
    }

    // Email already in use
    if (lowerMessage.contains('email already in use') ||
        lowerMessage.contains('email-already-in-use') ||
        lowerMessage.contains('already exists')) {
      return l10n.authErrorEmailAlreadyInUse;
    }

    // Weak password
    if (lowerMessage.contains('weak password') ||
        lowerMessage.contains('weak-password') ||
        lowerMessage.contains('password is too weak')) {
      return l10n.authErrorWeakPassword;
    }

    // Too many requests
    if (lowerMessage.contains('too many requests') ||
        lowerMessage.contains('too-many-requests') ||
        lowerMessage.contains('try again later')) {
      return l10n.authErrorTooManyRequests;
    }

    // Network error
    if (lowerMessage.contains('network') ||
        lowerMessage.contains('connection') ||
        lowerMessage.contains('internet')) {
      return l10n.authErrorNetworkError;
    }

    // Invalid credentials (generic login failure)
    if (lowerMessage.contains('invalid credential') ||
        lowerMessage.contains('invalid-credential') ||
        lowerMessage.contains('invalid_login_credentials')) {
      return l10n.authErrorInvalidCredentials;
    }

    // Default generic error
    return l10n.authErrorGeneric;
  }
}
