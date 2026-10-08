import '../../../generated/app_localizations.dart';
import '../domain/entities/spot.dart';

/// Localized display name for a [SpotCategory] (the entity's `displayName`
/// stays English for logs only).
extension SpotCategoryL10n on SpotCategory {
  String label(AppLocalizations l10n) {
    switch (this) {
      case SpotCategory.restaurant:
        return l10n.spotsCatRestaurant;
      case SpotCategory.cafe:
        return l10n.spotsCatCafe;
      case SpotCategory.culturalSite:
        return l10n.spotsCatCulturalSite;
      case SpotCategory.market:
        return l10n.spotsCatMarket;
      case SpotCategory.viewpoint:
        return l10n.spotsCatViewpoint;
    }
  }
}
