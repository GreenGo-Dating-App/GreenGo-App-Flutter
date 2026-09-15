import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import 'tier_reveal_dialog.dart';

/// What a given email will receive on registration.
///
/// Mirrors the `checkPreRegistrationOffer` callable. The server is the only
/// authority: this is what the user is TOLD, while `applySignupGrants` is what
/// actually lands at first login. Both read the same coupon data and the same
/// default, so the promise and the grant agree.
class PreRegistrationOffer {
  const PreRegistrationOffer({
    required this.kind,
    this.tier,
    this.membershipDays,
    this.baseMembershipDays,
    this.coins,
  });

  /// 'preRegistration' — the address is on the allowlist.
  /// 'default2026'     — the standard welcome pack everyone else gets.
  /// 'none'            — nothing to announce.
  final String kind;
  final String? tier;
  final int? membershipDays;
  final int? baseMembershipDays;
  final int? coins;

  bool get isPreRegistration => kind == 'preRegistration';
  bool get isWelcome2026 => kind == 'default2026';
  bool get hasSomethingToSay =>
      isPreRegistration || (isWelcome2026 && (coins ?? 0) > 0);

  static PreRegistrationOffer fromMap(Map<Object?, Object?> m) {
    int? asInt(Object? v) => v is num ? v.toInt() : null;
    return PreRegistrationOffer(
      kind: (m['kind'] as String?) ?? 'none',
      tier: m['tier'] as String?,
      membershipDays: asInt(m['membershipDays']),
      baseMembershipDays: asInt(m['baseMembershipDays']),
      coins: asInt(m['coins']),
    );
  }
}

/// Looks up the offer for an email. Never throws: a failed lookup simply means
/// no dialog, because this is a nicety on the way into signup and must never
/// be able to block someone from registering.
class PreRegistrationOfferService {
  const PreRegistrationOfferService();

  Future<PreRegistrationOffer?> lookup(String email) async {
    try {
      final callable = FirebaseFunctions.instance
          .httpsCallable('checkPreRegistrationOffer');
      final res = await callable.call<Map<Object?, Object?>>({'email': email});
      final offer = PreRegistrationOffer.fromMap(res.data);
      return offer.hasSomethingToSay ? offer : null;
    } catch (_) {
      return null;
    }
  }
}

/// Renders a duration the way a person would say it: "1 month", "3 months",
/// "1 year" — not "90 days". Falls back to a day count for anything that is
/// not a whole number of months.
String humaniseDuration(AppLocalizations l10n, int days) {
  switch (days) {
    case 30:
      return l10n.offerDurationOneMonth;
    case 90:
      return l10n.offerDurationMonths(3);
    case 180:
      return l10n.offerDurationMonths(6);
    case 365:
      return l10n.offerDurationOneYear;
    default:
      if (days % 30 == 0 && days > 30) {
        return l10n.offerDurationMonths(days ~/ 30);
      }
      return l10n.offerDurationDays(days);
  }
}

/// The dialog shown once the email is entered on the registration form.
///
/// Delegates to [TierRevealDialog], which animates the tier badge in and then
/// staggers the feature list - read from TierEntitlements, so what is promised
/// here is what the app actually enforces.
Future<void> showPreRegistrationOfferDialog(
  BuildContext context,
  PreRegistrationOffer offer,
) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => TierRevealDialog(offer: offer),
  );
}
