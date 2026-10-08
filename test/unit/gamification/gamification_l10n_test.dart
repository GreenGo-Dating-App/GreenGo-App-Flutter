import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/gamification/data/services/missions_service.dart';
import 'package:greengo_chat/features/gamification/domain/entities/achievement.dart';
import 'package:greengo_chat/features/gamification/domain/entities/daily_challenge.dart';
import 'package:greengo_chat/features/gamification/domain/entities/login_streak.dart';
import 'package:greengo_chat/features/gamification/domain/entities/user_journey.dart';
import 'package:greengo_chat/features/gamification/domain/entities/user_level.dart';
import 'package:greengo_chat/features/gamification/presentation/bloc/gamification_state.dart';
import 'package:greengo_chat/features/gamification/presentation/utils/gamification_l10n.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

/// Every catalogue id must map to an ARB key whose English text equals the
/// entity's English fallback (so the id switch is complete and correct).
void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final de = lookupAppLocalizations(const Locale('de'));

  test('challengeTemplateId strips rotation prefixes/suffixes', () {
    expect(challengeTemplateId('daily_send_3_messages_2026_10_08'),
        'send_3_messages');
    expect(challengeTemplateId('daily_video_call_1_2026_01_02'), 'video_call_1');
    expect(challengeTemplateId('weekly_weekly_messages_30_2026_w05'),
        'weekly_messages_30');
    expect(challengeTemplateId('valentine_matches_2026'), 'valentine_matches');
  });

  test('achievements are fully mapped', () {
    for (final a in Achievements.all) {
      expect(localizedAchievementName(en, a), a.name, reason: a.achievementId);
      expect(localizedAchievementDescription(en, a), a.description,
          reason: a.achievementId);
      expect(localizedAchievementName(de, a), isNot(isEmpty));
    }
  });

  test('daily, weekly and seasonal challenges are fully mapped', () {
    final all = [
      ...DailyChallenges.getRotatingChallenges(),
      ...WeeklyChallenges.getWeeklyChallenges(),
      for (final e in SeasonalEvents.getAllEvents(2026)) ...e.challenges,
    ];
    for (final c in all) {
      expect(localizedChallengeName(en, c), c.name, reason: c.challengeId);
      expect(localizedChallengeDescription(en, c),
          c.description.replaceAll("'", '’'),
          reason: c.challengeId);
    }
    for (final e in SeasonalEvents.getAllEvents(2026)) {
      expect(localizedSeasonalEventName(en, e), e.name.replaceAll("'", '’'));
    }
  });

  test('journey milestones, streak milestones, missions are fully mapped', () {
    for (final m in JourneyMilestones.all) {
      expect(localizedJourneyMilestoneName(en, m), m.name, reason: m.milestoneId);
      expect(localizedJourneyMilestoneDescription(en, m), m.description,
          reason: m.milestoneId);
    }
    for (final m in StreakMilestones.all) {
      expect(localizedStreakMilestoneName(en, m), m.name, reason: m.id);
      expect(localizedStreakMilestoneDescription(en, m), m.description,
          reason: m.id);
    }
    for (final d in MissionsService.catalog) {
      expect(localizedMissionTitle(en, d), d.title, reason: d.id);
    }
  });

  test('level reward names are mapped', () {
    for (final level in StandardLevelRewards.milestoneLevels) {
      for (final r in StandardLevelRewards.getRewardsForLevel(level)) {
        expect(localizedLevelRewardName(en, r), r.name, reason: r.itemId);
      }
    }
  });

  test('notices render localized text', () {
    expect(
      localizedGamificationNotice(
          en,
          const GamificationNotice(GamificationNoticeType.levelRewardsClaimed,
              level: 5, coins: 50)),
      'Level 5 rewards claimed! +50 coins',
    );
    expect(
      localizedGamificationNotice(
          en,
          const GamificationNotice(GamificationNoticeType.featureLocked,
              id: 'profile_video', level: 25, amount: 1)),
      'Profile Video unlocks at level 25. 1 level to go!',
    );
  });
}
