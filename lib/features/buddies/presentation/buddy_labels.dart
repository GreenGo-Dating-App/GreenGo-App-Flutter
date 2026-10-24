// Buddy enum ids -> localized labels (generated once from the catalogue;
// test/unit/buddies/buddy_catalog_test.dart checks every id has an ARB key).
import 'package:intl/intl.dart';

import '../../../generated/app_localizations.dart';

/// The quota line under the Buddy chat and in the Buddies tab, from the
/// server's numbers (never a hard-coded price):
/// "7 free replies left today · then 0.2 coins per reply (1 coin = 5
/// replies) · 4 prepaid replies".
String buddyQuotaLine(
  AppLocalizations l10n, {
  required int freeRepliesLeft,
  required num coinsPerReply,
  required int repliesPerCoin,
  int replyCredits = 0,
}) {
  final price = repliesPerCoin > 1
      ? l10n.buddyThenPricePerReply(
          NumberFormat.decimalPattern(l10n.localeName).format(coinsPerReply), repliesPerCoin)
      : l10n.buddyThenCoinsPerReply(coinsPerReply.ceil());
  return [
    l10n.buddyFreeRepliesLeft(freeRepliesLeft),
    price,
    if (replyCredits > 0) l10n.buddyPrepaidReplies(replyCredits),
  ].join(' · ');
}

/// Localized topic label (`buddyTopic_<id>`).
String buddyTopicLabel(AppLocalizations l10n, String id) {
  switch (id) {
    case 'practice_english':
      return l10n.buddyTopic_practice_english;
    case 'practice_italian':
      return l10n.buddyTopic_practice_italian;
    case 'practice_spanish':
      return l10n.buddyTopic_practice_spanish;
    case 'practice_french':
      return l10n.buddyTopic_practice_french;
    case 'practice_german':
      return l10n.buddyTopic_practice_german;
    case 'practice_portuguese':
      return l10n.buddyTopic_practice_portuguese;
    case 'slang_idioms':
      return l10n.buddyTopic_slang_idioms;
    case 'world_cultures':
      return l10n.buddyTopic_world_cultures;
    case 'etiquette':
      return l10n.buddyTopic_etiquette;
    case 'festivals':
      return l10n.buddyTopic_festivals;
    case 'pronunciation':
      return l10n.buddyTopic_pronunciation;
    case 'city_guides':
      return l10n.buddyTopic_city_guides;
    case 'budget_travel':
      return l10n.buddyTopic_budget_travel;
    case 'backpacking':
      return l10n.buddyTopic_backpacking;
    case 'road_trips':
      return l10n.buddyTopic_road_trips;
    case 'local_food_travel':
      return l10n.buddyTopic_local_food_travel;
    case 'packing':
      return l10n.buddyTopic_packing;
    case 'solo_travel':
      return l10n.buddyTopic_solo_travel;
    case 'travel_phrases':
      return l10n.buddyTopic_travel_phrases;
    case 'nature_trips':
      return l10n.buddyTopic_nature_trips;
    case 'travel_stories':
      return l10n.buddyTopic_travel_stories;
    case 'gym':
      return l10n.buddyTopic_gym;
    case 'running':
      return l10n.buddyTopic_running;
    case 'football':
      return l10n.buddyTopic_football;
    case 'basketball':
      return l10n.buddyTopic_basketball;
    case 'tennis':
      return l10n.buddyTopic_tennis;
    case 'yoga':
      return l10n.buddyTopic_yoga;
    case 'cycling':
      return l10n.buddyTopic_cycling;
    case 'swimming':
      return l10n.buddyTopic_swimming;
    case 'martial_arts':
      return l10n.buddyTopic_martial_arts;
    case 'hiking':
      return l10n.buddyTopic_hiking;
    case 'home_workouts':
      return l10n.buddyTopic_home_workouts;
    case 'painting':
      return l10n.buddyTopic_painting;
    case 'drawing':
      return l10n.buddyTopic_drawing;
    case 'photography':
      return l10n.buddyTopic_photography;
    case 'music_theory':
      return l10n.buddyTopic_music_theory;
    case 'guitar':
      return l10n.buddyTopic_guitar;
    case 'piano':
      return l10n.buddyTopic_piano;
    case 'singing':
      return l10n.buddyTopic_singing;
    case 'design':
      return l10n.buddyTopic_design;
    case 'creative_writing':
      return l10n.buddyTopic_creative_writing;
    case 'poetry':
      return l10n.buddyTopic_poetry;
    case 'crafts':
      return l10n.buddyTopic_crafts;
    case 'cooking':
      return l10n.buddyTopic_cooking;
    case 'baking':
      return l10n.buddyTopic_baking;
    case 'coffee':
      return l10n.buddyTopic_coffee;
    case 'tea':
      return l10n.buddyTopic_tea;
    case 'vegan':
      return l10n.buddyTopic_vegan;
    case 'world_cuisines':
      return l10n.buddyTopic_world_cuisines;
    case 'wine_culture':
      return l10n.buddyTopic_wine_culture;
    case 'barbecue':
      return l10n.buddyTopic_barbecue;
    case 'meal_prep':
      return l10n.buddyTopic_meal_prep;
    case 'street_food':
      return l10n.buddyTopic_street_food;
    case 'history':
      return l10n.buddyTopic_history;
    case 'astronomy':
      return l10n.buddyTopic_astronomy;
    case 'philosophy':
      return l10n.buddyTopic_philosophy;
    case 'science':
      return l10n.buddyTopic_science;
    case 'geography':
      return l10n.buddyTopic_geography;
    case 'mythology':
      return l10n.buddyTopic_mythology;
    case 'economics_basics':
      return l10n.buddyTopic_economics_basics;
    case 'nature_animals':
      return l10n.buddyTopic_nature_animals;
    case 'environment':
      return l10n.buddyTopic_environment;
    case 'trivia':
      return l10n.buddyTopic_trivia;
    case 'coding':
      return l10n.buddyTopic_coding;
    case 'ai':
      return l10n.buddyTopic_ai;
    case 'gadgets':
      return l10n.buddyTopic_gadgets;
    case 'gaming':
      return l10n.buddyTopic_gaming;
    case 'cybersecurity_basics':
      return l10n.buddyTopic_cybersecurity_basics;
    case '3d_printing':
      return l10n.buddyTopic_3d_printing;
    case 'web_design':
      return l10n.buddyTopic_web_design;
    case 'robotics':
      return l10n.buddyTopic_robotics;
    case 'apps_productivity':
      return l10n.buddyTopic_apps_productivity;
    case 'science_fiction':
      return l10n.buddyTopic_science_fiction;
    case 'job_interviews':
      return l10n.buddyTopic_job_interviews;
    case 'cv':
      return l10n.buddyTopic_cv;
    case 'public_speaking':
      return l10n.buddyTopic_public_speaking;
    case 'entrepreneurship':
      return l10n.buddyTopic_entrepreneurship;
    case 'marketing':
      return l10n.buddyTopic_marketing;
    case 'negotiation':
      return l10n.buddyTopic_negotiation;
    case 'productivity_work':
      return l10n.buddyTopic_productivity_work;
    case 'remote_work':
      return l10n.buddyTopic_remote_work;
    case 'leadership':
      return l10n.buddyTopic_leadership;
    case 'studying':
      return l10n.buddyTopic_studying;
    case 'habits':
      return l10n.buddyTopic_habits;
    case 'minimalism':
      return l10n.buddyTopic_minimalism;
    case 'gardening':
      return l10n.buddyTopic_gardening;
    case 'pets':
      return l10n.buddyTopic_pets;
    case 'diy':
      return l10n.buddyTopic_diy;
    case 'home_organisation':
      return l10n.buddyTopic_home_organisation;
    case 'fashion_basics':
      return l10n.buddyTopic_fashion_basics;
    case 'budgeting_basics':
      return l10n.buddyTopic_budgeting_basics;
    case 'moving_abroad':
      return l10n.buddyTopic_moving_abroad;
    case 'parenting_tips':
      return l10n.buddyTopic_parenting_tips;
    case 'movies':
      return l10n.buddyTopic_movies;
    case 'books':
      return l10n.buddyTopic_books;
    case 'anime':
      return l10n.buddyTopic_anime;
    case 'series':
      return l10n.buddyTopic_series;
    case 'board_games':
      return l10n.buddyTopic_board_games;
    case 'music_genres':
      return l10n.buddyTopic_music_genres;
    case 'podcasts':
      return l10n.buddyTopic_podcasts;
    case 'comedy':
      return l10n.buddyTopic_comedy;
    case 'puzzles':
      return l10n.buddyTopic_puzzles;
    case 'theatre':
      return l10n.buddyTopic_theatre;
    case 'motivation':
      return l10n.buddyTopic_motivation;
    case 'sleep_habits':
      return l10n.buddyTopic_sleep_habits;
    case 'stress_basics':
      return l10n.buddyTopic_stress_basics;
    case 'mindfulness':
      return l10n.buddyTopic_mindfulness;
    case 'gratitude':
      return l10n.buddyTopic_gratitude;
    case 'healthy_eating':
      return l10n.buddyTopic_healthy_eating;
    case 'digital_detox':
      return l10n.buddyTopic_digital_detox;
    case 'self_confidence':
      return l10n.buddyTopic_self_confidence;
    case 'casual_chat':
      return l10n.buddyTopic_casual_chat;
    case 'good_listener':
      return l10n.buddyTopic_good_listener;
    case 'joke_buddy':
      return l10n.buddyTopic_joke_buddy;
    case 'debate_partner':
      return l10n.buddyTopic_debate_partner;
    case 'daily_checkin':
      return l10n.buddyTopic_daily_checkin;
    case 'make_friends':
      return l10n.buddyTopic_make_friends;
    case 'cultural_exchange':
      return l10n.buddyTopic_cultural_exchange;
    case 'goal_buddy':
      return l10n.buddyTopic_goal_buddy;
    case 'storytelling':
      return l10n.buddyTopic_storytelling;
    case 'would_you_rather':
      return l10n.buddyTopic_would_you_rather;
    default:
      return id;
  }
}

/// Localized topic group label (`buddyTopicGroup_<id>`).
String buddyTopicGroupLabel(AppLocalizations l10n, String id) {
  switch (id) {
    case 'languages':
      return l10n.buddyTopicGroup_languages;
    case 'travel':
      return l10n.buddyTopicGroup_travel;
    case 'sport':
      return l10n.buddyTopicGroup_sport;
    case 'arts':
      return l10n.buddyTopicGroup_arts;
    case 'food':
      return l10n.buddyTopicGroup_food;
    case 'knowledge':
      return l10n.buddyTopicGroup_knowledge;
    case 'tech':
      return l10n.buddyTopicGroup_tech;
    case 'career':
      return l10n.buddyTopicGroup_career;
    case 'lifestyle':
      return l10n.buddyTopicGroup_lifestyle;
    case 'entertainment':
      return l10n.buddyTopicGroup_entertainment;
    case 'wellbeing':
      return l10n.buddyTopicGroup_wellbeing;
    case 'friendship':
      return l10n.buddyTopicGroup_friendship;
    default:
      return id;
  }
}

/// Localized tone.
String buddyToneLabel(AppLocalizations l10n, String id) {
  switch (id) {
    case 'warm':
      return l10n.buddyTone_warm;
    case 'funny':
      return l10n.buddyTone_funny;
    case 'calm':
      return l10n.buddyTone_calm;
    case 'direct':
      return l10n.buddyTone_direct;
    case 'formal':
      return l10n.buddyTone_formal;
    case 'playful':
      return l10n.buddyTone_playful;
    default:
      return id;
  }
}

/// Localized name of a Buddy language.
String buddyLanguageLabel(AppLocalizations l10n, String id) {
  switch (id) {
    case 'en':
      return l10n.buddyLang_en;
    case 'de':
      return l10n.buddyLang_de;
    case 'es':
      return l10n.buddyLang_es;
    case 'fr':
      return l10n.buddyLang_fr;
    case 'it':
      return l10n.buddyLang_it;
    case 'pt':
      return l10n.buddyLang_pt;
    case 'pt_BR':
      return l10n.buddyLang_pt_BR;
    default:
      return id;
  }
}
