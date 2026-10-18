import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../generated/app_localizations.dart';
import '../constants/phone_verification_countries.dart';

/// Links an SMS-verified phone number to the signed-in account (owner rule
/// 2026-10-17: mandatory for new accounts; required for joining, booking,
/// buying tickets, hosting and business tools).
///
/// Flow: [checkAllowed] (server: supported country, not a banned / taken
/// number) -> [sendCode] -> [confirmCode] (links the credential, refreshes the
/// ID token so `phone_number` reaches the rules / callables, then lets the
/// server record it in profiles_private + phone_index).
///
/// Mobile uses verifyPhoneNumber + linkWithCredential; web uses
/// linkWithPhoneNumber (invisible reCAPTCHA) + ConfirmationResult.confirm.
class PhoneVerificationService {
  PhoneVerificationService({FirebaseAuth? auth, FirebaseFunctions? functions})
      : _authOverride = auth,
        _functionsOverride = functions;

  final FirebaseAuth? _authOverride;
  final FirebaseFunctions? _functionsOverride;

  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;
  FirebaseFunctions get _functions =>
      _functionsOverride ?? FirebaseFunctions.instance;

  /// Tests: overrides [currentAccountHasPhone] without Firebase.
  @visibleForTesting
  static bool? Function()? debugHasPhone;

  /// Tests: overrides the account creation time.
  @visibleForTesting
  static DateTime? Function()? debugCreatedAt;

  /// Whether the signed-in account must have a verified phone: only accounts
  /// created on/after 16 Oct 2026 (older accounts: optional, never blocked).
  static bool phoneRequiredNow() {
    DateTime? created;
    if (debugCreatedAt != null) {
      created = debugCreatedAt!();
    } else {
      try {
        created = FirebaseAuth.instance.currentUser?.metadata.creationTime;
      } catch (_) {}
    }
    return phoneRequiredFor(created);
  }

  String? _verificationId;
  int? _resendToken;
  ConfirmationResult? _webConfirmation;

  /// True / false when known; null when Firebase is unavailable (the caller
  /// lets the action through and the server decides).
  static bool? currentAccountHasPhone() {
    final hook = debugHasPhone;
    if (hook != null) return hook();
    try {
      final phone = FirebaseAuth.instance.currentUser?.phoneNumber;
      return phone != null && phone.isNotEmpty;
    } catch (_) {
      return null;
    }
  }

  /// The verified phone of the signed-in account, or null.
  String? get currentPhone {
    try {
      final p = _auth.currentUser?.phoneNumber;
      return (p == null || p.isEmpty) ? null : p;
    } catch (_) {
      return null;
    }
  }

  /// Server pre-check before any SMS is sent. Returns null when allowed,
  /// otherwise a [PhoneVerificationError] code.
  Future<String?> checkAllowed(String e164) async {
    if (!isPhoneNumberSupported(e164)) return PhoneVerificationError.unsupportedCountry;
    try {
      final res = await _functions
          .httpsCallable('checkPhoneAllowed')
          .call<Map<String, dynamic>>({'phone': e164});
      final data = Map<String, dynamic>.from(res.data);
      if (data['allowed'] == true) return null;
      return PhoneVerificationError.fromServerReason(data['reason'] as String?);
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'resource-exhausted') return PhoneVerificationError.tooManyAttempts;
      return PhoneVerificationError.generic;
    } catch (_) {
      return PhoneVerificationError.generic;
    }
  }

  /// Sends the SMS. [onCodeSent] fires when the code is on its way;
  /// [onAutoVerified] when Android verified it without typing (already
  /// linked); [onError] with a [PhoneVerificationError] code.
  Future<void> sendCode(
    String e164, {
    required VoidCallback onCodeSent,
    required VoidCallback onAutoVerified,
    required void Function(String code) onError,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      onError(PhoneVerificationError.generic);
      return;
    }
    if (kIsWeb) {
      try {
        _webConfirmation = await user.linkWithPhoneNumber(e164);
        onCodeSent();
      } on FirebaseAuthException catch (e) {
        onError(PhoneVerificationError.fromAuthCode(e.code));
      } catch (_) {
        onError(PhoneVerificationError.generic);
      }
      return;
    }
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: e164,
        forceResendingToken: _resendToken,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          try {
            await _link(credential);
            onAutoVerified();
          } on FirebaseAuthException catch (e) {
            onError(PhoneVerificationError.fromAuthCode(e.code));
          } catch (_) {
            onError(PhoneVerificationError.generic);
          }
        },
        verificationFailed: (e) => onError(PhoneVerificationError.fromAuthCode(e.code)),
        codeSent: (verificationId, resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          onCodeSent();
        },
        codeAutoRetrievalTimeout: (verificationId) => _verificationId = verificationId,
      );
    } on FirebaseAuthException catch (e) {
      onError(PhoneVerificationError.fromAuthCode(e.code));
    } catch (_) {
      onError(PhoneVerificationError.generic);
    }
  }

  /// Confirms the 6-digit [smsCode]. Returns null on success, else an error
  /// code ([PhoneVerificationError]).
  Future<String?> confirmCode(String smsCode) async {
    try {
      if (kIsWeb) {
        final c = _webConfirmation;
        if (c == null) return PhoneVerificationError.codeExpired;
        await c.confirm(smsCode);
        await _afterLink();
        return null;
      }
      final id = _verificationId;
      if (id == null) return PhoneVerificationError.codeExpired;
      await _link(PhoneAuthProvider.credential(verificationId: id, smsCode: smsCode));
      return null;
    } on FirebaseAuthException catch (e) {
      return PhoneVerificationError.fromAuthCode(e.code);
    } catch (_) {
      return PhoneVerificationError.generic;
    }
  }

  Future<void> _link(PhoneAuthCredential credential) async {
    final user = _auth.currentUser;
    if (user == null) throw FirebaseAuthException(code: 'user-not-found');
    final existing = user.phoneNumber;
    if (existing == null || existing.isEmpty) {
      await user.linkWithCredential(credential);
    }
    await _afterLink();
  }

  /// Refresh the ID token (the `phone_number` claim) and let the server
  /// record the number. The record is best-effort: the rules and callables
  /// read the token claim, not the record.
  Future<void> _afterLink() async {
    final user = _auth.currentUser;
    try {
      await user?.reload();
    } catch (_) {}
    try {
      await _auth.currentUser?.getIdToken(true);
    } catch (_) {}
    try {
      await _functions.httpsCallable('recordVerifiedPhone').call<dynamic>();
    } catch (e) {
      debugPrint('recordVerifiedPhone failed: $e');
    }
  }
}

/// Error codes of the phone verification flow (mapped to text by
/// [phoneVerificationErrorText]).
abstract final class PhoneVerificationError {
  static const invalidNumber = 'invalid_number';
  static const unsupportedCountry = 'unsupported_country';
  static const alreadyUsed = 'phone_in_use';
  static const banned = 'phone_banned';
  static const tooManyAttempts = 'too_many_attempts';
  static const invalidCode = 'invalid_code';
  static const codeExpired = 'code_expired';
  static const generic = 'generic';

  static String fromServerReason(String? reason) => switch (reason) {
        'invalid_number' => invalidNumber,
        'unsupported_country' => unsupportedCountry,
        'phone_in_use' => alreadyUsed,
        'phone_banned' => banned,
        _ => generic,
      };

  static String fromAuthCode(String code) => switch (code) {
        'invalid-phone-number' || 'missing-phone-number' => invalidNumber,
        // Firebase Auth: the phone credential belongs to another account.
        'credential-already-in-use' || 'account-exists-with-different-credential' => alreadyUsed,
        'too-many-requests' || 'quota-exceeded' => tooManyAttempts,
        'invalid-verification-code' || 'missing-verification-code' => invalidCode,
        'session-expired' || 'code-expired' || 'invalid-verification-id' => codeExpired,
        // SMS region policy refused the country (Identity Platform).
        'operation-not-allowed' || 'unsupported-country' || 'admin-restricted-operation' => unsupportedCountry,
        _ => generic,
      };
}

/// User-facing text for a [PhoneVerificationError] code.
String phoneVerificationErrorText(AppLocalizations l10n, String code) => switch (code) {
      PhoneVerificationError.invalidNumber => l10n.phoneVerifyInvalidNumber,
      PhoneVerificationError.unsupportedCountry =>
        l10n.phoneVerifyUnsupportedCountry(kPhoneVerificationSupportEmail),
      PhoneVerificationError.alreadyUsed => l10n.phoneVerifyAlreadyUsed,
      PhoneVerificationError.banned => l10n.phoneVerifyBlocked(kPhoneVerificationSupportEmail),
      PhoneVerificationError.tooManyAttempts => l10n.phoneVerifyTooManyAttempts,
      PhoneVerificationError.invalidCode => l10n.phoneVerifyInvalidCode,
      PhoneVerificationError.codeExpired => l10n.phoneVerifyCodeExpired,
      _ => l10n.phoneVerifyGenericError,
    };
