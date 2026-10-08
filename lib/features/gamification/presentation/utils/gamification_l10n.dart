/// Localized display text for gamification content.
///
/// Domain entities keep stable ids (persisted in Firestore progress docs) plus
/// an English fallback name/description. The UI maps ids to ARB strings here so
/// nothing user-visible depends on the English text in the entities.
library;

import '../../../../generated/app_localizations.dart';
import '../../data/services/missions_service.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/entities/daily_challenge.dart';
import '../../domain/entities/login_streak.dart';
import '../../domain/entities/user_journey.dart';
import '../../domain/entities/user_level.dart';
import '../bloc/gamification_state.dart';

// ===== Achievements =====

String localizedAchievementName(AppLocalizations l10n, Achievement a) {
  switch (a.achievementId) {
    case 'first_match':
      return l10n.gamificationAchFirstMatchName;
    case 'conversation_starter':
      return l10n.gamificationAchConversationStarterName;
    case 'video_champion':
      return l10n.gamificationAchVideoChampionName;
    case 'profile_master':
      return l10n.gamificationAchProfileMasterName;
    case 'globe_trotter':
      return l10n.gamificationAchGlobeTrotterName;
    case 'generous_heart':
      return l10n.gamificationAchGenerousHeartName;
    case 'daily_dedication':
      return l10n.gamificationAchDailyDedicationName;
    case 'super_star':
      return l10n.gamificationAchSuperStarName;
    case 'social_butterfly':
      return l10n.gamificationAchSocialButterflyName;
    case 'perfect_week':
      return l10n.gamificationAchPerfectWeekName;
    case 'early_bird':
      return l10n.gamificationAchEarlyBirdName;
    case 'night_owl':
      return l10n.gamificationAchNightOwlName;
    case 'centurion':
      return l10n.gamificationAchCenturionName;
    case 'speed_dater':
      return l10n.gamificationAchSpeedDaterName;
    case 'photo_collector':
      return l10n.gamificationAchPhotoCollectorName;
    case 'trend_setter':
      return l10n.gamificationAchTrendSetterName;
    case 'verified':
      return l10n.gamificationAchVerifiedName;
    case 'premium_member':
      return l10n.gamificationAchPremiumMemberName;
    case 'coin_collector':
      return l10n.gamificationAchCoinCollectorName;
    case 'monthly_streak':
      return l10n.gamificationAchMonthlyStreakName;
    case 'vocabulary_beginner':
      return l10n.gamificationAchVocabularyBeginnerName;
    case 'vocabulary_intermediate':
      return l10n.gamificationAchVocabularyIntermediateName;
    case 'vocabulary_advanced':
      return l10n.gamificationAchVocabularyAdvancedName;
    case 'vocabulary_master':
      return l10n.gamificationAchVocabularyMasterName;
    case 'rare_word_hunter':
      return l10n.gamificationAchRareWordHunterName;
    default:
      return a.name;
  }
}

String localizedAchievementDescription(AppLocalizations l10n, Achievement a) {
  switch (a.achievementId) {
    case 'first_match':
      return l10n.gamificationAchFirstMatchDesc;
    case 'conversation_starter':
      return l10n.gamificationAchConversationStarterDesc;
    case 'video_champion':
      return l10n.gamificationAchVideoChampionDesc;
    case 'profile_master':
      return l10n.gamificationAchProfileMasterDesc;
    case 'globe_trotter':
      return l10n.gamificationAchGlobeTrotterDesc;
    case 'generous_heart':
      return l10n.gamificationAchGenerousHeartDesc;
    case 'daily_dedication':
      return l10n.gamificationAchDailyDedicationDesc;
    case 'super_star':
      return l10n.gamificationAchSuperStarDesc;
    case 'social_butterfly':
      return l10n.gamificationAchSocialButterflyDesc;
    case 'perfect_week':
      return l10n.gamificationAchPerfectWeekDesc;
    case 'early_bird':
      return l10n.gamificationAchEarlyBirdDesc;
    case 'night_owl':
      return l10n.gamificationAchNightOwlDesc;
    case 'centurion':
      return l10n.gamificationAchCenturionDesc;
    case 'speed_dater':
      return l10n.gamificationAchSpeedDaterDesc;
    case 'photo_collector':
      return l10n.gamificationAchPhotoCollectorDesc;
    case 'trend_setter':
      return l10n.gamificationAchTrendSetterDesc;
    case 'verified':
      return l10n.gamificationAchVerifiedDesc;
    case 'premium_member':
      return l10n.gamificationAchPremiumMemberDesc;
    case 'coin_collector':
      return l10n.gamificationAchCoinCollectorDesc;
    case 'monthly_streak':
      return l10n.gamificationAchMonthlyStreakDesc;
    case 'vocabulary_beginner':
      return l10n.gamificationAchVocabularyBeginnerDesc;
    case 'vocabulary_intermediate':
      return l10n.gamificationAchVocabularyIntermediateDesc;
    case 'vocabulary_advanced':
      return l10n.gamificationAchVocabularyAdvancedDesc;
    case 'vocabulary_master':
      return l10n.gamificationAchVocabularyMasterDesc;
    case 'rare_word_hunter':
      return l10n.gamificationAchRareWordHunterDesc;
    default:
      return a.description;
  }
}

/// Achievement name by id (falls back to the id for unknown achievements).
String localizedAchievementNameById(AppLocalizations l10n, String achievementId) {
  final a = Achievements.getById(achievementId);
  return a == null ? achievementId : localizedAchievementName(l10n, a);
}

String localizedAchievementCategory(
    AppLocalizations l10n, AchievementCategory category) {
  switch (category) {
    case AchievementCategory.social:
      return l10n.gamificationSocial;
    case AchievementCategory.engagement:
      return l10n.gamificationEngagement;
    case AchievementCategory.premium:
      return l10n.gamificationPremium;
    case AchievementCategory.milestones:
      return l10n.gamificationMilestones;
    case AchievementCategory.special:
      return l10n.gamificationSpecial;
  }
}

String localizedAchievementRarity(
    AppLocalizations l10n, AchievementRarity rarity) {
  switch (rarity) {
    case AchievementRarity.common:
      return l10n.achievementRarityCommon;
    case AchievementRarity.uncommon:
      return l10n.achievementRarityUncommon;
    case AchievementRarity.rare:
      return l10n.achievementRarityRare;
    case AchievementRarity.epic:
      return l10n.achievementRarityEpic;
    case AchievementRarity.legendary:
      return l10n.achievementRarityLegendary;
  }
}

// ===== Rewards =====

/// "+50 XP", "+20 coins", "+1 badge", "+3 boosts" for a reward type id.
String localizedRewardAmount(AppLocalizations l10n, String type, int amount) {
  switch (type) {
    case 'xp':
      return l10n.xpRewardLabel('$amount');
    case 'coins':
      return l10n.gamificationRewardCoinsPlus(amount);
    case 'badge':
      return l10n.gamificationRewardBadgePlus(amount);
    case 'boost':
      return l10n.gamificationRewardBoostPlus(amount);
    default:
      return '+$amount';
  }
}

// ===== Challenges =====

/// Strips the rotation prefix/suffix from a runtime challenge id
/// (`daily_send_3_messages_2026_10_08`, `weekly_weekly_messages_30_2026_w05`,
/// `valentine_matches_2026`) to get the stable template id.
String challengeTemplateId(String challengeId) {
  var id = challengeId;
  if (id.startsWith('daily_')) {
    id = id.substring('daily_'.length);
  } else if (id.startsWith('weekly_weekly_')) {
    id = id.substring('weekly_'.length);
  }
  return id.replaceFirst(RegExp(r'_\d{4}(_\d{2}_\d{2}|_w\d{2})?$'), '');
}

String localizedChallengeName(AppLocalizations l10n, DailyChallenge c) {
  switch (challengeTemplateId(c.challengeId)) {
    case 'send_3_messages':
      return l10n.gamificationChallengeSend3MessagesName;
    case 'send_5_messages':
      return l10n.gamificationChallengeSend5MessagesName;
    case 'send_10_messages':
      return l10n.gamificationChallengeSend10MessagesName;
    case 'send_15_messages':
      return l10n.gamificationChallengeSend15MessagesName;
    case 'get_1_match':
      return l10n.gamificationChallengeGet1MatchName;
    case 'get_3_matches':
      return l10n.gamificationChallengeGet3MatchesName;
    case 'get_5_matches':
      return l10n.gamificationChallengeGet5MatchesName;
    case 'send_1_superlike':
      return l10n.gamificationChallengeSend1SuperlikeName;
    case 'send_3_superlikes':
      return l10n.gamificationChallengeSend3SuperlikesName;
    case 'send_5_superlikes':
      return l10n.gamificationChallengeSend5SuperlikesName;
    case 'video_call_1':
      return l10n.gamificationChallengeVideoCall1Name;
    case 'video_call_2':
      return l10n.gamificationChallengeVideoCall2Name;
    case 'add_photo':
      return l10n.gamificationChallengeAddPhotoName;
    case 'add_2_photos':
      return l10n.gamificationChallengeAdd2PhotosName;
    case 'send_1_gift':
      return l10n.gamificationChallengeSend1GiftName;
    case 'send_3_gifts':
      return l10n.gamificationChallengeSend3GiftsName;
    case 'send_5_gifts':
      return l10n.gamificationChallengeSend5GiftsName;
    case 'chat_starter':
      return l10n.gamificationChallengeChatStarterName;
    case 'social_butterfly':
      return l10n.gamificationChallengeSocialButterflyName;
    case 'match_rush':
      return l10n.gamificationChallengeMatchRushName;
    case 'video_marathon':
      return l10n.gamificationChallengeVideoMarathonName;
    case 'weekly_messages_30':
      return l10n.gamificationChallengeWeeklyMessages30Name;
    case 'weekly_messages_50':
      return l10n.gamificationChallengeWeeklyMessages50Name;
    case 'weekly_messages_100':
      return l10n.gamificationChallengeWeeklyMessages100Name;
    case 'weekly_matches_10':
      return l10n.gamificationChallengeWeeklyMatches10Name;
    case 'weekly_matches_20':
      return l10n.gamificationChallengeWeeklyMatches20Name;
    case 'weekly_matches_30':
      return l10n.gamificationChallengeWeeklyMatches30Name;
    case 'weekly_superlikes_5':
      return l10n.gamificationChallengeWeeklySuperlikes5Name;
    case 'weekly_superlikes_10':
      return l10n.gamificationChallengeWeeklySuperlikes10Name;
    case 'weekly_superlikes_15':
      return l10n.gamificationChallengeWeeklySuperlikes15Name;
    case 'weekly_video_3':
      return l10n.gamificationChallengeWeeklyVideo3Name;
    case 'weekly_video_5':
      return l10n.gamificationChallengeWeeklyVideo5Name;
    case 'weekly_gifts_5':
      return l10n.gamificationChallengeWeeklyGifts5Name;
    case 'weekly_gifts_10':
      return l10n.gamificationChallengeWeeklyGifts10Name;
    case 'weekly_photos_3':
      return l10n.gamificationChallengeWeeklyPhotos3Name;
    case 'weekly_perfect':
      return l10n.gamificationChallengeWeeklyPerfectName;
    case 'valentine_matches':
      return l10n.gamificationChallengeValentineMatchesName;
    case 'valentine_video':
      return l10n.gamificationChallengeValentineVideoName;
    case 'summer_matches':
      return l10n.gamificationChallengeSummerMatchesName;
    case 'holiday_gifts':
      return l10n.gamificationChallengeHolidayGiftsName;
    case 'holiday_messages':
      return l10n.gamificationChallengeHolidayMessagesName;
    default:
      return c.name;
  }
}

String localizedChallengeDescription(AppLocalizations l10n, DailyChallenge c) {
  switch (challengeTemplateId(c.challengeId)) {
    case 'send_3_messages':
      return l10n.gamificationChallengeSend3MessagesDesc;
    case 'send_5_messages':
      return l10n.gamificationChallengeSend5MessagesDesc;
    case 'send_10_messages':
      return l10n.gamificationChallengeSend10MessagesDesc;
    case 'send_15_messages':
      return l10n.gamificationChallengeSend15MessagesDesc;
    case 'get_1_match':
      return l10n.gamificationChallengeGet1MatchDesc;
    case 'get_3_matches':
      return l10n.gamificationChallengeGet3MatchesDesc;
    case 'get_5_matches':
      return l10n.gamificationChallengeGet5MatchesDesc;
    case 'send_1_superlike':
      return l10n.gamificationChallengeSend1SuperlikeDesc;
    case 'send_3_superlikes':
      return l10n.gamificationChallengeSend3SuperlikesDesc;
    case 'send_5_superlikes':
      return l10n.gamificationChallengeSend5SuperlikesDesc;
    case 'video_call_1':
      return l10n.gamificationChallengeVideoCall1Desc;
    case 'video_call_2':
      return l10n.gamificationChallengeVideoCall2Desc;
    case 'add_photo':
      return l10n.gamificationChallengeAddPhotoDesc;
    case 'add_2_photos':
      return l10n.gamificationChallengeAdd2PhotosDesc;
    case 'send_1_gift':
      return l10n.gamificationChallengeSend1GiftDesc;
    case 'send_3_gifts':
      return l10n.gamificationChallengeSend3GiftsDesc;
    case 'send_5_gifts':
      return l10n.gamificationChallengeSend5GiftsDesc;
    case 'chat_starter':
      return l10n.gamificationChallengeChatStarterDesc;
    case 'social_butterfly':
      return l10n.gamificationChallengeSocialButterflyDesc;
    case 'match_rush':
      return l10n.gamificationChallengeMatchRushDesc;
    case 'video_marathon':
      return l10n.gamificationChallengeVideoMarathonDesc;
    case 'weekly_messages_30':
      return l10n.gamificationChallengeWeeklyMessages30Desc;
    case 'weekly_messages_50':
      return l10n.gamificationChallengeWeeklyMessages50Desc;
    case 'weekly_messages_100':
      return l10n.gamificationChallengeWeeklyMessages100Desc;
    case 'weekly_matches_10':
      return l10n.gamificationChallengeWeeklyMatches10Desc;
    case 'weekly_matches_20':
      return l10n.gamificationChallengeWeeklyMatches20Desc;
    case 'weekly_matches_30':
      return l10n.gamificationChallengeWeeklyMatches30Desc;
    case 'weekly_superlikes_5':
      return l10n.gamificationChallengeWeeklySuperlikes5Desc;
    case 'weekly_superlikes_10':
      return l10n.gamificationChallengeWeeklySuperlikes10Desc;
    case 'weekly_superlikes_15':
      return l10n.gamificationChallengeWeeklySuperlikes15Desc;
    case 'weekly_video_3':
      return l10n.gamificationChallengeWeeklyVideo3Desc;
    case 'weekly_video_5':
      return l10n.gamificationChallengeWeeklyVideo5Desc;
    case 'weekly_gifts_5':
      return l10n.gamificationChallengeWeeklyGifts5Desc;
    case 'weekly_gifts_10':
      return l10n.gamificationChallengeWeeklyGifts10Desc;
    case 'weekly_photos_3':
      return l10n.gamificationChallengeWeeklyPhotos3Desc;
    case 'weekly_perfect':
      return l10n.gamificationChallengeWeeklyPerfectDesc;
    case 'valentine_matches':
      return l10n.gamificationChallengeValentineMatchesDesc;
    case 'valentine_video':
      return l10n.gamificationChallengeValentineVideoDesc;
    case 'summer_matches':
      return l10n.gamificationChallengeSummerMatchesDesc;
    case 'holiday_gifts':
      return l10n.gamificationChallengeHolidayGiftsDesc;
    case 'holiday_messages':
      return l10n.gamificationChallengeHolidayMessagesDesc;
    default:
      return c.description;
  }
}

/// Challenge name by runtime id; [fallback] is used for unknown ids.
String localizedChallengeNameById(
    AppLocalizations l10n, String challengeId, String fallback) {
  switch (challengeTemplateId(challengeId)) {
    case 'send_3_messages':
      return l10n.gamificationChallengeSend3MessagesName;
    case 'send_5_messages':
      return l10n.gamificationChallengeSend5MessagesName;
    case 'send_10_messages':
      return l10n.gamificationChallengeSend10MessagesName;
    case 'send_15_messages':
      return l10n.gamificationChallengeSend15MessagesName;
    case 'get_1_match':
      return l10n.gamificationChallengeGet1MatchName;
    case 'get_3_matches':
      return l10n.gamificationChallengeGet3MatchesName;
    case 'get_5_matches':
      return l10n.gamificationChallengeGet5MatchesName;
    case 'send_1_superlike':
      return l10n.gamificationChallengeSend1SuperlikeName;
    case 'send_3_superlikes':
      return l10n.gamificationChallengeSend3SuperlikesName;
    case 'send_5_superlikes':
      return l10n.gamificationChallengeSend5SuperlikesName;
    case 'video_call_1':
      return l10n.gamificationChallengeVideoCall1Name;
    case 'video_call_2':
      return l10n.gamificationChallengeVideoCall2Name;
    case 'add_photo':
      return l10n.gamificationChallengeAddPhotoName;
    case 'add_2_photos':
      return l10n.gamificationChallengeAdd2PhotosName;
    case 'send_1_gift':
      return l10n.gamificationChallengeSend1GiftName;
    case 'send_3_gifts':
      return l10n.gamificationChallengeSend3GiftsName;
    case 'send_5_gifts':
      return l10n.gamificationChallengeSend5GiftsName;
    case 'chat_starter':
      return l10n.gamificationChallengeChatStarterName;
    case 'social_butterfly':
      return l10n.gamificationChallengeSocialButterflyName;
    case 'match_rush':
      return l10n.gamificationChallengeMatchRushName;
    case 'video_marathon':
      return l10n.gamificationChallengeVideoMarathonName;
    case 'weekly_messages_30':
      return l10n.gamificationChallengeWeeklyMessages30Name;
    case 'weekly_messages_50':
      return l10n.gamificationChallengeWeeklyMessages50Name;
    case 'weekly_messages_100':
      return l10n.gamificationChallengeWeeklyMessages100Name;
    case 'weekly_matches_10':
      return l10n.gamificationChallengeWeeklyMatches10Name;
    case 'weekly_matches_20':
      return l10n.gamificationChallengeWeeklyMatches20Name;
    case 'weekly_matches_30':
      return l10n.gamificationChallengeWeeklyMatches30Name;
    case 'weekly_superlikes_5':
      return l10n.gamificationChallengeWeeklySuperlikes5Name;
    case 'weekly_superlikes_10':
      return l10n.gamificationChallengeWeeklySuperlikes10Name;
    case 'weekly_superlikes_15':
      return l10n.gamificationChallengeWeeklySuperlikes15Name;
    case 'weekly_video_3':
      return l10n.gamificationChallengeWeeklyVideo3Name;
    case 'weekly_video_5':
      return l10n.gamificationChallengeWeeklyVideo5Name;
    case 'weekly_gifts_5':
      return l10n.gamificationChallengeWeeklyGifts5Name;
    case 'weekly_gifts_10':
      return l10n.gamificationChallengeWeeklyGifts10Name;
    case 'weekly_photos_3':
      return l10n.gamificationChallengeWeeklyPhotos3Name;
    case 'weekly_perfect':
      return l10n.gamificationChallengeWeeklyPerfectName;
    case 'valentine_matches':
      return l10n.gamificationChallengeValentineMatchesName;
    case 'valentine_video':
      return l10n.gamificationChallengeValentineVideoName;
    case 'summer_matches':
      return l10n.gamificationChallengeSummerMatchesName;
    case 'holiday_gifts':
      return l10n.gamificationChallengeHolidayGiftsName;
    case 'holiday_messages':
      return l10n.gamificationChallengeHolidayMessagesName;
    default:
      return fallback;
  }
}

String localizedChallengeDifficulty(
    AppLocalizations l10n, ChallengeDifficulty difficulty) {
  switch (difficulty) {
    case ChallengeDifficulty.easy:
      return l10n.gamificationEasy;
    case ChallengeDifficulty.medium:
      return l10n.gamificationMedium;
    case ChallengeDifficulty.hard:
      return l10n.gamificationHard;
    case ChallengeDifficulty.epic:
      return l10n.gamificationEpic;
  }
}

// ===== Seasonal events =====

String localizedSeasonalEventName(AppLocalizations l10n, SeasonalEvent e) {
  switch (e.theme) {
    case 'valentine':
      return l10n.gamificationEventValentinesName;
    case 'summer':
      return l10n.gamificationEventSummerName;
    case 'holiday':
      return l10n.gamificationEventHolidayName;
    default:
      return e.name;
  }
}

String localizedSeasonalEventDescription(
    AppLocalizations l10n, SeasonalEvent e) {
  switch (e.theme) {
    case 'valentine':
      return l10n.gamificationEventValentinesDesc;
    case 'summer':
      return l10n.gamificationEventSummerDesc;
    case 'holiday':
      return l10n.gamificationEventHolidayDesc;
    default:
      return e.description;
  }
}

// ===== Login-streak milestones =====

String localizedStreakMilestoneName(AppLocalizations l10n, StreakMilestone m) {
  switch (m.id) {
    case 'streak_3':
      return l10n.gamificationStreakMilestone3Name;
    case 'streak_7':
      return l10n.gamificationStreakMilestone7Name;
    case 'streak_14':
      return l10n.gamificationStreakMilestone14Name;
    case 'streak_30':
      return l10n.gamificationStreakMilestone30Name;
    case 'streak_60':
      return l10n.gamificationStreakMilestone60Name;
    case 'streak_90':
      return l10n.gamificationStreakMilestone90Name;
    case 'streak_180':
      return l10n.gamificationStreakMilestone180Name;
    case 'streak_365':
      return l10n.gamificationStreakMilestone365Name;
    default:
      return m.name;
  }
}

String localizedStreakMilestoneDescription(
        AppLocalizations l10n, StreakMilestone m) =>
    l10n.gamificationStreakMilestoneDesc(m.daysRequired);

// ===== Journey =====

String localizedJourneyCategoryName(AppLocalizations l10n, JourneyCategory c) {
  switch (c) {
    case JourneyCategory.gettingStarted:
      return l10n.gamificationJourneyCatGettingStarted;
    case JourneyCategory.socializing:
      return l10n.gamificationJourneyCatSocializing;
    case JourneyCategory.premium:
      return l10n.gamificationPremium;
    case JourneyCategory.mastery:
      return l10n.gamificationJourneyCatMastery;
    case JourneyCategory.special:
      return l10n.gamificationSpecial;
  }
}

String localizedJourneyCategoryDescription(
    AppLocalizations l10n, JourneyCategory c) {
  switch (c) {
    case JourneyCategory.gettingStarted:
      return l10n.gamificationJourneyCatGettingStartedDesc;
    case JourneyCategory.socializing:
      return l10n.gamificationJourneyCatSocializingDesc;
    case JourneyCategory.premium:
      return l10n.gamificationJourneyCatPremiumDesc;
    case JourneyCategory.mastery:
      return l10n.gamificationJourneyCatMasteryDesc;
    case JourneyCategory.special:
      return l10n.gamificationJourneyCatSpecialDesc;
  }
}

/// Short tab label for a journey category.
String localizedJourneyCategoryShort(AppLocalizations l10n, JourneyCategory c) {
  switch (c) {
    case JourneyCategory.gettingStarted:
      return l10n.gamificationJourneyTabStart;
    case JourneyCategory.socializing:
      return l10n.gamificationSocial;
    case JourneyCategory.premium:
      return l10n.gamificationVip;
    case JourneyCategory.mastery:
      return l10n.gamificationJourneyTabMaster;
    case JourneyCategory.special:
      return l10n.gamificationSpecial;
  }
}

String localizedJourneyMilestoneName(
    AppLocalizations l10n, JourneyMilestone m) {
  switch (m.milestoneId) {
    case 'complete_profile':
      return l10n.gamificationJourneyCompleteProfileName;
    case 'add_photos':
      return l10n.gamificationJourneyAddPhotosName;
    case 'get_verified':
      return l10n.gamificationJourneyGetVerifiedName;
    case 'first_match':
      return l10n.gamificationJourneyFirstMatchName;
    case 'ten_matches':
      return l10n.gamificationJourneyTenMatchesName;
    case 'fifty_matches':
      return l10n.gamificationJourneyFiftyMatchesName;
    case 'first_message':
      return l10n.gamificationJourneyFirstMessageName;
    case 'hundred_messages':
      return l10n.gamificationJourneyHundredMessagesName;
    case 'first_video_call':
      return l10n.gamificationJourneyFirstVideoCallName;
    case 'ten_video_calls':
      return l10n.gamificationJourneyTenVideoCallsName;
    case 'week_streak':
      return l10n.gamificationJourneyWeekStreakName;
    case 'month_streak':
      return l10n.gamificationJourneyMonthStreakName;
    case 'upgrade_silver':
      return l10n.gamificationJourneyUpgradeSilverName;
    case 'upgrade_gold':
      return l10n.gamificationJourneyUpgradeGoldName;
    case 'upgrade_platinum':
      return l10n.gamificationJourneyUpgradePlatinumName;
    case 'ten_achievements':
      return l10n.gamificationJourneyTenAchievementsName;
    case 'fifty_achievements':
      return l10n.gamificationJourneyFiftyAchievementsName;
    case 'hundred_matches':
      return l10n.gamificationJourneyHundredMatchesName;
    default:
      return m.name;
  }
}

String localizedJourneyMilestoneDescription(
    AppLocalizations l10n, JourneyMilestone m) {
  switch (m.milestoneId) {
    case 'complete_profile':
      return l10n.gamificationJourneyCompleteProfileDesc;
    case 'add_photos':
      return l10n.gamificationJourneyAddPhotosDesc;
    case 'get_verified':
      return l10n.gamificationJourneyGetVerifiedDesc;
    case 'first_match':
      return l10n.gamificationJourneyFirstMatchDesc;
    case 'ten_matches':
      return l10n.gamificationJourneyTenMatchesDesc;
    case 'fifty_matches':
      return l10n.gamificationJourneyFiftyMatchesDesc;
    case 'first_message':
      return l10n.gamificationJourneyFirstMessageDesc;
    case 'hundred_messages':
      return l10n.gamificationJourneyHundredMessagesDesc;
    case 'first_video_call':
      return l10n.gamificationJourneyFirstVideoCallDesc;
    case 'ten_video_calls':
      return l10n.gamificationJourneyTenVideoCallsDesc;
    case 'week_streak':
      return l10n.gamificationJourneyWeekStreakDesc;
    case 'month_streak':
      return l10n.gamificationJourneyMonthStreakDesc;
    case 'upgrade_silver':
      return l10n.gamificationJourneyUpgradeSilverDesc;
    case 'upgrade_gold':
      return l10n.gamificationJourneyUpgradeGoldDesc;
    case 'upgrade_platinum':
      return l10n.gamificationJourneyUpgradePlatinumDesc;
    case 'ten_achievements':
      return l10n.gamificationJourneyTenAchievementsDesc;
    case 'fifty_achievements':
      return l10n.gamificationJourneyFiftyAchievementsDesc;
    case 'hundred_matches':
      return l10n.gamificationJourneyHundredMatchesDesc;
    default:
      return m.description;
  }
}

// ===== Level rewards / level-gated features =====

String localizedLevelRewardName(AppLocalizations l10n, LevelReward r) {
  if (r.type == 'coins') {
    final amount = int.tryParse(RegExp(r'^\d+').stringMatch(r.name) ?? '');
    if (amount != null) return l10n.gamificationLevelRewardBonusCoins(amount);
  }
  if (r.type == 'feature') return localizedFeatureName(l10n, r.itemId, r.name);
  if (r.itemId == 'max_level_badge') {
    return l10n.gamificationLevelRewardMaxLevelBadge(100);
  }
  switch (r.itemId) {
    case 'bronze_frame':
      return l10n.gamificationLevelRewardBronzeFrame;
    case 'silver_frame':
      return l10n.gamificationLevelRewardSilverFrame;
    case 'gold_frame':
      return l10n.gamificationLevelRewardGoldFrame;
    case 'platinum_frame':
      return l10n.gamificationLevelRewardPlatinumFrame;
    case 'diamond_frame':
      return l10n.gamificationLevelRewardDiamondFrame;
    case 'legendary_frame':
      return l10n.gamificationLevelRewardLegendaryFrame;
    case 'vip_crown':
      return l10n.gamificationLevelRewardVipCrown;
    default:
      return r.name;
  }
}

String localizedFeatureName(
    AppLocalizations l10n, String featureId, String fallback) {
  switch (featureId) {
    case 'custom_chat_themes':
      return l10n.gamificationFeatureCustomChatThemes;
    case 'profile_video':
      return l10n.gamificationFeatureProfileVideo;
    case 'advanced_filters':
      return l10n.gamificationFeatureAdvancedFilters;
    case 'unlimited_rewinds':
      return l10n.gamificationFeatureUnlimitedRewinds;
    case 'vip_badge':
      return l10n.gamificationFeatureVipBadge;
    case 'priority_likes':
      return l10n.gamificationFeaturePriorityLikes;
    default:
      return fallback;
  }
}

// ===== Missions =====

String localizedMissionTitle(AppLocalizations l10n, MissionDef def) {
  switch (def.id) {
    case 'attend_3_events':
      return l10n.gamificationMissionAttend3Events;
    case 'connect_3_countries':
      return l10n.gamificationMissionConnect3Countries;
    case 'join_community':
      return l10n.gamificationMissionJoinCommunity;
    case 'complete_profile':
      return l10n.gamificationMissionCompleteProfile;
    case 'add_5_people':
      return l10n.gamificationMissionAdd5People;
    default:
      return def.title;
  }
}

// ===== Bloc notices =====

/// Text for a [GamificationNotice] emitted by the bloc.
String localizedGamificationNotice(
    AppLocalizations l10n, GamificationNotice n) {
  final rewards = [
    if (n.xp > 0) l10n.xpRewardLabel('${n.xp}'),
    if (n.coins > 0) l10n.gamificationRewardCoinsPlus(n.coins),
  ].join(' ');
  switch (n.type) {
    case GamificationNoticeType.achievementUnlocked:
      return l10n
          .gamificationNoticeAchievementUnlocked(
            localizedAchievementNameById(l10n, n.id ?? ''),
            n.rewardType == null
                ? ''
                : localizedRewardAmount(l10n, n.rewardType!, n.amount),
          )
          .trim();
    case GamificationNoticeType.achievementReady:
      return l10n.gamificationNoticeAchievementReady(
          localizedAchievementNameById(l10n, n.id ?? ''));
    case GamificationNoticeType.levelUp:
      return l10n.gamificationNoticeLevelUp(n.level);
    case GamificationNoticeType.vipAchieved:
      return l10n.gamificationNoticeVip;
    case GamificationNoticeType.levelRewardsClaimed:
      return l10n.gamificationNoticeLevelRewardsClaimed(n.level, rewards).trim();
    case GamificationNoticeType.featureLocked:
      return l10n.gamificationNoticeFeatureLocked(
        n.amount,
        localizedFeatureName(l10n, n.id ?? '', n.fallbackName ?? n.id ?? ''),
        n.level,
      );
    case GamificationNoticeType.challengeCompleted:
      return l10n.gamificationChallengeCompleted(localizedChallengeNameById(
          l10n, n.id ?? '', n.fallbackName ?? ''));
    case GamificationNoticeType.challengeRewardsClaimed:
      return l10n
          .gamificationNoticeChallengeRewardsClaimed(
            localizedChallengeNameById(l10n, n.id ?? '', n.fallbackName ?? ''),
            rewards,
          )
          .trim();
  }
}
