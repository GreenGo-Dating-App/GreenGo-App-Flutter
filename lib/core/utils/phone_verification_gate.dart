import 'package:flutter/material.dart';

import '../../generated/app_localizations.dart';
import '../constants/app_colors.dart';
import '../services/own_profile_store.dart';
import '../services/phone_verification_service.dart';
import '../widgets/info_button.dart';
import '../widgets/phone_verification_panel.dart';

/// Server refusal code when the caller has no verified phone
/// (functions/src/shared/participation.ts PHONE_VERIFICATION_REQUIRED).
const String kPhoneVerificationRequiredCode = 'phone_verification_required';

/// Owner rule (2026-10-17, final): accounts created on/after 16 Oct 2026 need
/// an SMS-verified phone to join / RSVP, buy tickets, book, host / create
/// (incl. community events), publish in communities and use business tools.
/// Accounts created before are NEVER required or blocked.
///
/// Server mirror: rules `phoneVerified()` and `assertPhoneVerified` in the
/// callables (createTicketCheckout, createBooking, createUserExperience).
class PhoneVerificationGate {
  PhoneVerificationGate._();

  /// Tests: replaces the sheet (returns whether the user "verified").
  @visibleForTesting
  static Future<bool> Function(BuildContext context)? debugShowSheet;

  /// True when the account has a verified phone, or is not required to have
  /// one (created before 16 Oct 2026 - never asked here), or it can't be
  /// told (the server decides). Otherwise (a new account without a phone)
  /// shows the verify sheet and returns whether the user verified in it.
  static Future<bool> ensureVerified(BuildContext context) async {
    final has = PhoneVerificationService.currentAccountHasPhone();
    if (has != false) return true;
    if (!PhoneVerificationService.phoneRequiredNow()) return true;
    if (!context.mounted) return false;
    return showSheet(context);
  }

  /// The "Verify your phone" bottom sheet. Returns true once verified.
  static Future<bool> showSheet(BuildContext context, {String? body}) async {
    final hook = debugShowSheet;
    if (hook != null) return hook(context);
    final verified = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => PhoneVerificationSheet(body: body),
    );
    return verified ?? false;
  }

  /// True when [error] / [code] is the server's phone refusal; shows the
  /// sheet in that case (the caller shows nothing else).
  static Future<bool> handleError(BuildContext context, {Object? error, String? code}) async {
    final c = code ?? _codeOf(error);
    if (c != kPhoneVerificationRequiredCode) return false;
    if (context.mounted) await showSheet(context);
    return true;
  }

  static String? _codeOf(Object? error) {
    if (error == null) return null;
    final text = error.toString();
    return text.contains(kPhoneVerificationRequiredCode) ? kPhoneVerificationRequiredCode : null;
  }
}

/// Sheet body: title, why, and the [PhoneVerificationPanel].
class PhoneVerificationSheet extends StatelessWidget {
  const PhoneVerificationSheet({this.body, this.service, super.key});
  final String? body;
  final PhoneVerificationService? service;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profile = OwnProfileStore.instance.profile.value;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.phone_android, color: AppColors.richGold),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.phoneVerifyTitle,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  InfoButton(
                    key: const Key('phone_verify_why'),
                    title: l10n.xplLockedPhoneTitle,
                    message: l10n.xplLockedPhoneBody,
                    bullets: [l10n.xplLockedPhonePrivate],
                  ),
                  IconButton(
                    tooltip: l10n.phoneVerifyDismiss,
                    icon: const Icon(Icons.close, color: AppColors.textTertiary),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                body ?? l10n.phoneVerifyGateBody,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              PhoneVerificationPanel(
                service: service,
                initialCountry: profile?.primaryOrigin,
                onVerified: (_) => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
