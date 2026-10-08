import '../../../../../generated/app_localizations.dart';

// Onboarding stores gender, interests and languages as stable English values
// (matching/search compare on them). These helpers map a stored value to its
// display label in the user's app language; unknown values are shown as-is.

String localizedOnboardingGender(AppLocalizations l10n, String value) {
  switch (value) {
    case 'Male':
      return l10n.onboardingGenderMale;
    case 'Female':
      return l10n.onboardingGenderFemale;
    case 'Non-binary':
      return l10n.onboardingGenderNonBinary;
    case 'Other':
      return l10n.onboardingGenderOther;
    default:
      return value;
  }
}

String localizedOnboardingInterest(AppLocalizations l10n, String value) {
  switch (value) {
    case 'Travel':
      return l10n.interestTravel;
    case 'Photography':
      return l10n.interestPhotography;
    case 'Music':
      return l10n.interestMusic;
    case 'Movies':
      return l10n.interestMovies;
    case 'Sports':
      return l10n.interestSports;
    case 'Fitness':
      return l10n.interestFitness;
    case 'Cooking':
      return l10n.interestCooking;
    case 'Reading':
      return l10n.interestReading;
    case 'Art':
      return l10n.interestArt;
    case 'Gaming':
      return l10n.interestGaming;
    case 'Technology':
      return l10n.interestTechnology;
    case 'Fashion':
      return l10n.interestFashion;
    case 'Dancing':
      return l10n.interestDancing;
    case 'Yoga':
      return l10n.interestYoga;
    case 'Hiking':
      return l10n.interestHiking;
    case 'Swimming':
      return l10n.interestSwimming;
    case 'Running':
      return l10n.interestRunning;
    case 'Cycling':
      return l10n.interestCycling;
    case 'Meditation':
      return l10n.interestMeditation;
    case 'Writing':
      return l10n.interestWriting;
    case 'Poetry':
      return l10n.interestPoetry;
    case 'Coffee':
      return l10n.interestCoffee;
    case 'Wine':
      return l10n.interestWine;
    case 'Beer':
      return l10n.interestBeer;
    case 'Food':
      return l10n.interestFood;
    case 'Vegetarian':
      return l10n.interestVegetarian;
    case 'Vegan':
      return l10n.interestVegan;
    case 'Pets':
      return l10n.interestPets;
    case 'Dogs':
      return l10n.interestDogs;
    case 'Cats':
      return l10n.interestCats;
    case 'Nature':
      return l10n.interestNature;
    case 'Environment':
      return l10n.interestEnvironment;
    case 'Volunteering':
      return l10n.interestVolunteering;
    case 'Languages':
      return l10n.interestLanguages;
    case 'History':
      return l10n.interestHistory;
    case 'Science':
      return l10n.interestScience;
    case 'Politics':
      return l10n.interestPolitics;
    case 'Business':
      return l10n.interestBusiness;
    case 'Entrepreneurship':
      return l10n.interestEntrepreneurship;
    case 'Investing':
      return l10n.interestInvesting;
    default:
      return value;
  }
}

String localizedOnboardingLanguage(AppLocalizations l10n, String value) {
  switch (value) {
    case 'English':
      return l10n.languageNameEnglish;
    case 'Spanish':
      return l10n.languageNameSpanish;
    case 'French':
      return l10n.languageNameFrench;
    case 'German':
      return l10n.languageNameGerman;
    case 'Italian':
      return l10n.languageNameItalian;
    case 'Portuguese':
      return l10n.languageNamePortuguese;
    case 'Portuguese (Brazil)':
      return l10n.languageNamePortugueseBrazil;
    case 'Russian':
      return l10n.languageNameRussian;
    case 'Chinese':
      return l10n.languageNameChinese;
    case 'Japanese':
      return l10n.languageNameJapanese;
    case 'Korean':
      return l10n.languageNameKorean;
    case 'Arabic':
      return l10n.languageNameArabic;
    case 'Hindi':
      return l10n.languageNameHindi;
    case 'Dutch':
      return l10n.languageNameDutch;
    case 'Swedish':
      return l10n.languageNameSwedish;
    case 'Norwegian':
      return l10n.languageNameNorwegian;
    case 'Danish':
      return l10n.languageNameDanish;
    case 'Finnish':
      return l10n.languageNameFinnish;
    case 'Polish':
      return l10n.languageNamePolish;
    case 'Turkish':
      return l10n.languageNameTurkish;
    case 'Greek':
      return l10n.languageNameGreek;
    default:
      return value;
  }
}
