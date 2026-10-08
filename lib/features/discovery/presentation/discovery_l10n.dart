import '../../../generated/app_localizations.dart';

/// Display-only localization for discovery preference values.
///
/// Stored values (Firestore `matchPreferences`, profile interests) stay in
/// their canonical English form because filtering compares them verbatim;
/// only what the user SEES is localized here. Unknown values (free text,
/// legacy entries) are returned unchanged.

/// Canonical (stored) deal-breaker values offered in the preferences screen.
const List<String> kDealBreakerOptions = [
  'Smoking',
  'Drinking',
  'No bio',
  'No photos',
  'Different religion',
  'Different politics',
  'Has children',
  'Wants children',
  'Long distance',
  'Non-monogamy',
];

String localizedDealBreaker(AppLocalizations l10n, String value) {
  switch (value) {
    case 'Smoking':
      return l10n.discoveryDealBreakerSmoking;
    case 'Drinking':
      return l10n.discoveryDealBreakerDrinking;
    case 'No bio':
      return l10n.discoveryDealBreakerNoBio;
    case 'No photos':
      return l10n.discoveryDealBreakerNoPhotos;
    case 'Different religion':
      return l10n.discoveryDealBreakerDifferentReligion;
    case 'Different politics':
      return l10n.discoveryDealBreakerDifferentPolitics;
    case 'Has children':
      return l10n.discoveryDealBreakerHasChildren;
    case 'Wants children':
      return l10n.discoveryDealBreakerWantsChildren;
    case 'Long distance':
      return l10n.discoveryDealBreakerLongDistance;
    case 'Non-monogamy':
      return l10n.discoveryDealBreakerNonMonogamy;
    default:
      return value;
  }
}

/// Localized name of a canonical (English) interest value.
String localizedInterestName(AppLocalizations l10n, String value) {
  switch (value) {
    case 'Travel': return l10n.interestTravel;
    case 'Photography': return l10n.interestPhotography;
    case 'Music': return l10n.interestMusic;
    case 'Fitness': return l10n.interestFitness;
    case 'Cooking': return l10n.interestCooking;
    case 'Reading': return l10n.interestReading;
    case 'Movies': return l10n.interestMovies;
    case 'Gaming': return l10n.interestGaming;
    case 'Art': return l10n.interestArt;
    case 'Dance': return l10n.interestDance;
    case 'Dancing': return l10n.interestDancing;
    case 'Yoga': return l10n.interestYoga;
    case 'Hiking': return l10n.interestHiking;
    case 'Swimming': return l10n.interestSwimming;
    case 'Cycling': return l10n.interestCycling;
    case 'Running': return l10n.interestRunning;
    case 'Sports': return l10n.interestSports;
    case 'Fashion': return l10n.interestFashion;
    case 'Technology': return l10n.interestTechnology;
    case 'Writing': return l10n.interestWriting;
    case 'Coffee': return l10n.interestCoffee;
    case 'Wine': return l10n.interestWine;
    case 'Beer': return l10n.interestBeer;
    case 'Food': return l10n.interestFood;
    case 'Vegetarian': return l10n.interestVegetarian;
    case 'Vegan': return l10n.interestVegan;
    case 'Pets': return l10n.interestPets;
    case 'Dogs': return l10n.interestDogs;
    case 'Cats': return l10n.interestCats;
    case 'Nature': return l10n.interestNature;
    case 'Beach': return l10n.interestBeach;
    case 'Mountains': return l10n.interestMountains;
    case 'Camping': return l10n.interestCamping;
    case 'Surfing': return l10n.interestSurfing;
    case 'Skiing': return l10n.interestSkiing;
    case 'Snowboarding': return l10n.interestSnowboarding;
    case 'Meditation': return l10n.interestMeditation;
    case 'Spirituality': return l10n.interestSpirituality;
    case 'Volunteering': return l10n.interestVolunteering;
    case 'Environment': return l10n.interestEnvironment;
    case 'Politics': return l10n.interestPolitics;
    case 'Science': return l10n.interestScience;
    case 'History': return l10n.interestHistory;
    case 'Languages': return l10n.interestLanguages;
    case 'Teaching': return l10n.interestTeaching;
    case 'Poetry': return l10n.interestPoetry;
    case 'Business': return l10n.interestBusiness;
    case 'Entrepreneurship': return l10n.interestEntrepreneurship;
    case 'Investing': return l10n.interestInvesting;
    default: return value;
  }
}
