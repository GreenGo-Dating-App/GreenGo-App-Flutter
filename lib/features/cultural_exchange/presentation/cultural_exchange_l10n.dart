import '../../../generated/app_localizations.dart';
import '../domain/entities/country_spotlight.dart';
import '../domain/entities/cultural_tip.dart';

/// Localized label for a cultural tip category (the domain keeps the enum).
String localizedTipCategory(AppLocalizations l10n, TipCategory category) {
  switch (category) {
    case TipCategory.food:
      return l10n.culturalExchangeCategoryFood;
    case TipCategory.transportation:
      return l10n.culturalExchangeCategoryTransportation;
    case TipCategory.dating:
      return l10n.culturalExchangeCategoryDating;
    case TipCategory.customs:
      return l10n.culturalExchangeCategoryCustoms;
    case TipCategory.language:
      return l10n.culturalExchangeCategoryLanguage;
    case TipCategory.safety:
      return l10n.culturalExchangeCategorySafety;
  }
}

/// Localized title for a country-spotlight section type.
String localizedSpotlightSection(
    AppLocalizations l10n, SpotlightSectionType type) {
  switch (type) {
    case SpotlightSectionType.cuisine:
      return l10n.culturalExchangeSectionCuisine;
    case SpotlightSectionType.customs:
      return l10n.culturalExchangeSectionCustoms;
    case SpotlightSectionType.datingEtiquette:
      return l10n.culturalExchangeDatingEtiquette;
    case SpotlightSectionType.keyPhrases:
      return l10n.culturalExchangeSectionKeyPhrases;
  }
}

/// Localized relative time ("5m ago", "3w ago"…).
String localizedTimeAgo(AppLocalizations l10n, DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inMinutes < 1) return l10n.chatJustNow;
  if (diff.inMinutes < 60) return l10n.chatSupportMinutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return l10n.chatSupportHoursAgo(diff.inHours);
  if (diff.inDays < 7) return l10n.chatSupportDaysAgo(diff.inDays);
  if (diff.inDays < 30) {
    return l10n.culturalExchangeWeeksAgo((diff.inDays / 7).floor());
  }
  return l10n.culturalExchangeMonthsAgo((diff.inDays / 30).floor());
}
