import '../../../generated/app_localizations.dart';
import '../../membership/domain/entities/membership.dart';
import '../domain/entities/subscription.dart';

/// Localized display names for membership / subscription tiers.
///
/// The domain enums keep their English `displayName` getters for logs,
/// analytics and Firestore fields; UI code must use these helpers instead.

/// Localized long name of a [SubscriptionTier] ("Gold Premium", "Platinum VIP").
String localizedSubscriptionTierName(
    AppLocalizations l10n, SubscriptionTier tier) {
  switch (tier) {
    case SubscriptionTier.basic:
      return l10n.membershipTierNameBasicFree;
    case SubscriptionTier.silver:
      return l10n.membershipTierNameSilverPremium;
    case SubscriptionTier.gold:
      return l10n.membershipTierNameGoldPremium;
    case SubscriptionTier.platinum:
      return l10n.membershipTierNamePlatinumVip;
    case SubscriptionTier.test:
      return l10n.membershipTierNameTester;
  }
}

/// Localized display name of a [MembershipTier] ("Free", "Gold VIP").
String localizedMembershipTierName(AppLocalizations l10n, MembershipTier tier) {
  switch (tier) {
    case MembershipTier.free:
      return l10n.tierFree;
    case MembershipTier.silver:
      return l10n.membershipTierNameSilverVip;
    case MembershipTier.gold:
      return l10n.membershipTierNameGoldVip;
    case MembershipTier.platinum:
      return l10n.membershipTierNamePlatinumVip;
    case MembershipTier.test:
      return l10n.membershipTierNameTester;
  }
}

/// Localized short name for a STORED tier string ('BASIC', 'SILVER', 'GOLD',
/// 'PLATINUM', 'TEST'; case-insensitive). Unknown / empty -> "Basic".
String localizedStoredTierName(AppLocalizations l10n, String? stored) {
  switch ((stored ?? '').trim().toUpperCase()) {
    case 'SILVER':
      return l10n.silver;
    case 'GOLD':
      return l10n.gold;
    case 'PLATINUM':
      return l10n.platinum;
    case 'TEST':
      return l10n.membershipTierNameTester;
    default:
      return l10n.basic;
  }
}
