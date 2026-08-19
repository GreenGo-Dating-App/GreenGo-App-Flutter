import '../../../generated/app_localizations.dart';

/// Localised names for the spreadsheet's `Category` column.
///
/// The categories are DATA — a future sheet can introduce one we have never
/// seen. So this resolves in two steps:
///   1. a translated label for the 26 categories we ship, or
///   2. the raw English value from Firestore, unchanged.
///
/// That means a new category still renders (in English) instead of showing a
/// blank chip or crashing, and can be promoted to a translated key later
/// without any data migration.
class CategoryLabels {
  const CategoryLabels._();

  static String of(AppLocalizations l10n, String? rawCategory) {
    switch (rawCategory) {
      case 'Religious':
        return l10n.attrCatReligious;
      case 'Historic Site':
        return l10n.attrCatHistoricSite;
      case 'Museum':
        return l10n.attrCatMuseum;
      case 'Nature':
        return l10n.attrCatNature;
      case 'Neighborhood':
        return l10n.attrCatNeighborhood;
      case 'Beach':
        return l10n.attrCatBeach;
      case 'Garden':
        return l10n.attrCatGarden;
      case 'Monument':
        return l10n.attrCatMonument;
      case 'Square':
        return l10n.attrCatSquare;
      case 'Street':
        return l10n.attrCatStreet;
      case 'Architecture':
        return l10n.attrCatArchitecture;
      case 'Observation Deck':
        return l10n.attrCatObservationDeck;
      case 'Castle':
        return l10n.attrCatCastle;
      case 'Market':
        return l10n.attrCatMarket;
      case 'Mountain':
        return l10n.attrCatMountain;
      case 'Palace':
        return l10n.attrCatPalace;
      case 'Island':
        return l10n.attrCatIsland;
      case 'Lake':
        return l10n.attrCatLake;
      case 'National Park':
        return l10n.attrCatNationalPark;
      case 'Bridge':
        return l10n.attrCatBridge;
      case 'Theme Park':
        return l10n.attrCatThemePark;
      case 'Waterfall':
        return l10n.attrCatWaterfall;
      case 'Zoo':
        return l10n.attrCatZoo;
      case 'Shopping':
        return l10n.attrCatShopping;
      case 'Aquarium':
        return l10n.attrCatAquarium;
      case 'Other':
        return l10n.attrCatOther;
      default:
        // Unknown category from a newer dataset — show it as stored rather than
        // hiding it.
        return rawCategory ?? l10n.attrCatOther;
    }
  }
}
