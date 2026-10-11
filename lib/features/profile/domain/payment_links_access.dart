import '../../../core/services/effective_tier.dart';
import '../../../core/services/tier_entitlements.dart';
import '../../membership/domain/entities/membership.dart';
import 'entities/payment_links.dart';
import 'entities/profile.dart';

/// Owner rule (2026-10-12): "Business has automatic payment through Stripe or
/// Mercado Pago. Silver, Gold and Platinum have payment links in Account
/// settings. That is visible only when the tier is Silver, Gold or Platinum."
///
/// Personal payment links (`profiles/{uid}.paymentLinks`) may be added /
/// edited and are SHOWN only while the owner's EFFECTIVE tier is Silver, Gold
/// or Platinum (TEST counts as paid). Enforced server-side too:
///   * writes: `paymentLinksWriteOk()` in firestore(.additive).rules;
///   * reads: functions/src/profiles/paymentLinksVisibility.ts moves the links
///     of a lapsed tier to `profiles_private/{uid}.paymentLinksHidden` and
///     back on renewal. The checks here are defence in depth (they also cover
///     the minutes between an end date and the server job).
bool paymentLinksAllowedForTier(MembershipTier effective) =>
    TierEntitlements.paymentLinks(effective);

/// [paymentLinksAllowedForTier] for a profile (its effective tier).
bool paymentLinksAllowed(Profile profile) =>
    paymentLinksAllowedForTier(profile.effectiveTier);

/// [paymentLinksAllowedForTier] for a raw `profiles/{uid}` document.
bool paymentLinksAllowedFromDoc(Map<String, dynamic>? data) =>
    paymentLinksAllowedForTier(effectiveTierFromDoc(data));

/// The links other people may see on [profile]: null unless the owner's tier
/// allows them and at least one is set.
PaymentLinks? visiblePaymentLinks(Profile profile) {
  final links = profile.paymentLinks;
  if (links == null || !links.hasAnyLink) return null;
  return paymentLinksAllowed(profile) ? links : null;
}

/// Field of `profiles_private/{uid}` holding the links of a lapsed tier
/// (server-written; the owner may only clear it).
const String kPaymentLinksHiddenField = 'paymentLinksHidden';

/// The owner's hidden links from their private profile document, or null.
PaymentLinks? hiddenPaymentLinksFromPrivate(Map<String, dynamic>? private) {
  final raw = private?[kPaymentLinksHiddenField];
  if (raw is! Map) return null;
  final values = <PaymentMethod, String>{
    for (final e in raw.entries)
      if (PaymentMethod.fromKey('${e.key}') != null &&
          e.value is String &&
          (e.value as String).isNotEmpty)
        PaymentMethod.fromKey('${e.key}')!: e.value as String,
  };
  return values.isEmpty ? null : PaymentLinks(values);
}

/// Normalised view of a stored links map: provider key -> non-empty value.
Map<String, String> _nonEmpty(Object? raw) => raw is Map
    ? {
        for (final e in raw.entries)
          if (e.value is String && (e.value as String).trim().isNotEmpty)
            '${e.key}': (e.value as String).trim(),
      }
    : const {};

/// What a full-profile save should do with `paymentLinks` (see
/// ProfileRemoteDataSource.updateProfile): every profile save re-sends the
/// whole profile, including the links the app last loaded. Send them only
/// when they really changed AND the change is allowed (any change by an
/// eligible owner, or a removal by anyone) — otherwise a stale copy could be
/// written back after the server hid them, and the rules would refuse the
/// whole save.
bool shouldWritePaymentLinks({
  required Object? stored,
  required Object? next,
  required bool allowed,
}) {
  final a = _nonEmpty(stored);
  final b = _nonEmpty(next);
  final changed =
      a.length != b.length || b.entries.any((e) => a[e.key] != e.value);
  if (!changed) return false;
  if (allowed) return true;
  // Not eligible: only a pure removal goes through.
  return b.entries.every((e) => a[e.key] == e.value);
}
