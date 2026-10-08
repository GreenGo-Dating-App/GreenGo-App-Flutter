import '../../generated/app_localizations.dart';

/// Canonical business/venue categories used across the Business feature
/// (business account editor + storefront editor).
///
/// Stored on `profiles/{uid}.businessCategory` as the raw English string — this
/// is a canonical data value (like a country code), so it is intentionally NOT
/// localized; the surrounding labels/hints are localized as usual.
///
/// Keep this list stable and append-only where possible: changing an existing
/// entry would orphan businesses already saved under the old string.
class BusinessCategories {
  const BusinessCategories._();

  /// 50 curated categories spanning food, nightlife, hospitality, culture,
  /// wellness, travel, retail and services — the segments GreenGo businesses
  /// actually operate in.
  static const List<String> all = <String>[
    'Restaurant',
    'Bar',
    'Cafe',
    'Nightclub',
    'Lounge',
    'Hotel',
    'Hostel',
    'Guesthouse',
    'Resort',
    'Bed & Breakfast',
    'Gym',
    'Yoga Studio',
    'Fitness Studio',
    'Spa',
    'Wellness Center',
    'Beauty Salon',
    'Barbershop',
    'Museum',
    'Art Gallery',
    'Theater',
    'Cinema',
    'Live Music Venue',
    'Cultural Center',
    'Tour Operator',
    'Travel Agency',
    'Language School',
    'Cooking School',
    'Dance Studio',
    'Coworking Space',
    'Event Venue',
    'Conference Center',
    'Shop / Retail',
    'Boutique',
    'Bookstore',
    'Market',
    'Winery',
    'Brewery',
    'Distillery',
    'Food Truck',
    'Bakery',
    'Coffee Roastery',
    'Sports Club',
    'Adventure & Outdoor',
    'Diving Center',
    'Photography Studio',
    'Coaching & Consulting',
    'Nonprofit & NGO',
    'Community Center',
    'Transportation Service',
    'Other',
  ];

  /// The same 50 categories organised into user-facing sections, used to render
  /// an easy grouped-chip picker (instead of a long flat dropdown). Every value
  /// here also appears in [all]; section names are organisational labels.
  static const Map<String, List<String>> grouped = <String, List<String>>{
    'Food & Drink': [
      'Restaurant', 'Bar', 'Cafe', 'Bakery', 'Food Truck',
      'Coffee Roastery', 'Winery', 'Brewery', 'Distillery',
    ],
    'Nightlife': ['Nightclub', 'Lounge', 'Live Music Venue'],
    'Stay': ['Hotel', 'Hostel', 'Guesthouse', 'Resort', 'Bed & Breakfast'],
    'Wellness': [
      'Gym', 'Yoga Studio', 'Fitness Studio', 'Spa', 'Wellness Center',
      'Beauty Salon', 'Barbershop',
    ],
    'Culture': [
      'Museum', 'Art Gallery', 'Theater', 'Cinema', 'Cultural Center',
    ],
    'Travel & Tours': [
      'Tour Operator', 'Travel Agency', 'Adventure & Outdoor', 'Diving Center',
    ],
    'Learn & Work': [
      'Language School', 'Cooking School', 'Dance Studio', 'Coworking Space',
      'Photography Studio', 'Coaching & Consulting',
    ],
    'Events': ['Event Venue', 'Conference Center'],
    'Retail': ['Shop / Retail', 'Boutique', 'Bookstore', 'Market'],
    'Community & Services': [
      'Sports Club', 'Nonprofit & NGO', 'Community Center',
      'Transportation Service', 'Other',
    ],
  };
}

/// Localized display label for a stored [BusinessCategories] value (the raw
/// English string stays the stored/canonical value). Unknown values (legacy or
/// free-text) are returned unchanged.
String localizedBusinessCategory(AppLocalizations l10n, String value) {
  switch (value) {
    case 'Restaurant':
      return l10n.bizCatRestaurant;
    case 'Bar':
      return l10n.bizCatBar;
    case 'Cafe':
      return l10n.bizCatCafe;
    case 'Nightclub':
      return l10n.bizCatNightclub;
    case 'Lounge':
      return l10n.bizCatLounge;
    case 'Hotel':
      return l10n.bizCatHotel;
    case 'Hostel':
      return l10n.bizCatHostel;
    case 'Guesthouse':
      return l10n.bizCatGuesthouse;
    case 'Resort':
      return l10n.bizCatResort;
    case 'Bed & Breakfast':
      return l10n.bizCatBedAndBreakfast;
    case 'Gym':
      return l10n.bizCatGym;
    case 'Yoga Studio':
      return l10n.bizCatYogaStudio;
    case 'Fitness Studio':
      return l10n.bizCatFitnessStudio;
    case 'Spa':
      return l10n.bizCatSpa;
    case 'Wellness Center':
      return l10n.bizCatWellnessCenter;
    case 'Beauty Salon':
      return l10n.bizCatBeautySalon;
    case 'Barbershop':
      return l10n.bizCatBarbershop;
    case 'Museum':
      return l10n.bizCatMuseum;
    case 'Art Gallery':
      return l10n.bizCatArtGallery;
    case 'Theater':
      return l10n.bizCatTheater;
    case 'Cinema':
      return l10n.bizCatCinema;
    case 'Live Music Venue':
      return l10n.bizCatLiveMusicVenue;
    case 'Cultural Center':
      return l10n.bizCatCulturalCenter;
    case 'Tour Operator':
      return l10n.bizCatTourOperator;
    case 'Travel Agency':
      return l10n.bizCatTravelAgency;
    case 'Language School':
      return l10n.bizCatLanguageSchool;
    case 'Cooking School':
      return l10n.bizCatCookingSchool;
    case 'Dance Studio':
      return l10n.bizCatDanceStudio;
    case 'Coworking Space':
      return l10n.bizCatCoworkingSpace;
    case 'Event Venue':
      return l10n.bizCatEventVenue;
    case 'Conference Center':
      return l10n.bizCatConferenceCenter;
    case 'Shop / Retail':
      return l10n.bizCatShopRetail;
    case 'Boutique':
      return l10n.bizCatBoutique;
    case 'Bookstore':
      return l10n.bizCatBookstore;
    case 'Market':
      return l10n.bizCatMarket;
    case 'Winery':
      return l10n.bizCatWinery;
    case 'Brewery':
      return l10n.bizCatBrewery;
    case 'Distillery':
      return l10n.bizCatDistillery;
    case 'Food Truck':
      return l10n.bizCatFoodTruck;
    case 'Bakery':
      return l10n.bizCatBakery;
    case 'Coffee Roastery':
      return l10n.bizCatCoffeeRoastery;
    case 'Sports Club':
      return l10n.bizCatSportsClub;
    case 'Adventure & Outdoor':
      return l10n.bizCatAdventureAndOutdoor;
    case 'Diving Center':
      return l10n.bizCatDivingCenter;
    case 'Photography Studio':
      return l10n.bizCatPhotographyStudio;
    case 'Coaching & Consulting':
      return l10n.bizCatCoachingAndConsulting;
    case 'Nonprofit & NGO':
      return l10n.bizCatNonprofitAndNGO;
    case 'Community Center':
      return l10n.bizCatCommunityCenter;
    case 'Transportation Service':
      return l10n.bizCatTransportationService;
    case 'Other':
      return l10n.bizCatOther;
    default:
      return value;
  }
}

/// Localized label for a [BusinessCategories.grouped] section name.
String localizedBusinessCategoryGroup(AppLocalizations l10n, String group) {
  switch (group) {
    case 'Food & Drink':
      return l10n.bizCatGroupFoodAndDrink;
    case 'Nightlife':
      return l10n.bizCatGroupNightlife;
    case 'Stay':
      return l10n.bizCatGroupStay;
    case 'Wellness':
      return l10n.bizCatGroupWellness;
    case 'Culture':
      return l10n.bizCatGroupCulture;
    case 'Travel & Tours':
      return l10n.bizCatGroupTravelAndTours;
    case 'Learn & Work':
      return l10n.bizCatGroupLearnAndWork;
    case 'Events':
      return l10n.bizCatGroupEvents;
    case 'Retail':
      return l10n.bizCatGroupRetail;
    case 'Community & Services':
      return l10n.bizCatGroupCommunityAndServices;
    default:
      return group;
  }
}
