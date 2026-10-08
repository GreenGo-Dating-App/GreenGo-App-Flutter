import 'app_l10n_lookup.dart';

/// Form validators. Messages follow the app's current language
/// ([currentAppL10n]); they are used as `validator:` tear-offs, so they have
/// no BuildContext.
class Validators {
  Validators._();

  /// Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return currentAppL10n().emailRequired;
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return currentAppL10n().emailInvalid;
    }

    return null;
  }

  /// Password validation
  /// Must contain:
  /// - At least 8 characters
  /// - At least one uppercase letter
  /// - At least one lowercase letter
  /// - At least one number
  /// - At least one special character
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return currentAppL10n().passwordRequired;
    }

    if (value.length < 8) {
      return currentAppL10n().passwordTooShort;
    }

    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return currentAppL10n().passwordMustContainUppercase;
    }

    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return currentAppL10n().passwordMustContainLowercase;
    }

    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return currentAppL10n().passwordMustContainNumber;
    }

    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return currentAppL10n().passwordMustContainSpecialChar;
    }

    return null;
  }

  /// Confirm password validation
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return currentAppL10n().confirmPasswordRequired;
    }

    if (value != password) {
      return currentAppL10n().passwordsDoNotMatch;
    }

    return null;
  }

  /// Name validation
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return currentAppL10n().validatorNameRequired;
    }

    if (value.length < 2) {
      return currentAppL10n().onboardingNameMinLength;
    }

    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return currentAppL10n().validatorNameLettersOnly;
    }

    return null;
  }

  /// Phone validation
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return currentAppL10n().validatorPhoneRequired;
    }

    // Remove all non-digit characters
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.length < 10) {
      return currentAppL10n().validatorPhoneMinDigits;
    }

    return null;
  }

  /// Age validation
  static String? validateAge(int? value, {int minAge = 18, int maxAge = 100}) {
    if (value == null) {
      return currentAppL10n().validatorAgeRequired;
    }

    if (value < minAge) {
      return currentAppL10n().validatorMinAge(minAge);
    }

    if (value > maxAge) {
      return currentAppL10n().validatorInvalidAge;
    }

    return null;
  }

  /// Bio validation
  static String? validateBio(String? value, {int maxLength = 500}) {
    if (value == null || value.isEmpty) {
      return null; // Bio is optional
    }

    if (value.length > maxLength) {
      return currentAppL10n().validatorBioMaxLength(maxLength);
    }

    return null;
  }

  /// Get password strength (0-4)
  /// 0 = Very Weak
  /// 1 = Weak
  /// 2 = Fair
  /// 3 = Strong
  /// 4 = Very Strong
  static int getPasswordStrength(String password) {
    var strength = 0;

    if (password.isEmpty) return strength;

    // Length check
    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;

    // Character variety checks
    if (RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[A-Z]').hasMatch(password)) {
      strength++;
    }

    if (RegExp(r'[0-9]').hasMatch(password)) {
      strength++;
    }

    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      strength++;
    }

    // Cap at 4
    return strength > 4 ? 4 : strength;
  }

  /// Get password strength label
  static String getPasswordStrengthLabel(int strength) {
    switch (strength) {
      case 0:
        return currentAppL10n().passwordStrengthVeryWeak;
      case 1:
        return currentAppL10n().passwordStrengthWeak;
      case 2:
        return currentAppL10n().passwordStrengthFair;
      case 3:
        return currentAppL10n().passwordStrengthStrong;
      case 4:
        return currentAppL10n().passwordStrengthVeryStrong;
      default:
        return '';
    }
  }
}
