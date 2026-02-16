/**
 * Gamification Remote Data Source
 * Points 176-200: Firestore operations for gamification
 */

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/entities/user_level.dart';
import '../../domain/entities/daily_challenge.dart';
import '../../domain/repositories/gamification_repository.dart';
import '../models/achievement_model.dart';
import '../models/user_level_model.dart';
import '../models/daily_challenge_model.dart';

abstract class GamificationRemoteDataSource {
  // Achievement Operations
  Future<List<Achievement>> getAllAchievements();
  Future<List<UserAchievementProgressModel>> getUserAchievementProgress(
      String userId);
  Future<UserAchievementProgressModel> getAchievementProgress(
    String userId,
    String achievementId,
  );
  Future<UserAchievementProgressModel> unlockAchievement(
    String userId,
    String achievementId,
  );
  Future<UserAchievementProgressModel> trackAchievementProgress(
    String userId,
    String achievementId,
    int incrementBy,
  );

  // Level & XP Operations
  Future<UserLevelModel> getUserLevel(String userId);
  Future<UserLevelModel> grantXP(String userId, int xpAmount, String reason);
  Future<List<XPTransactionModel>> getXPHistory(String userId, int limit);
  Future<List<LeaderboardEntryModel>> getLeaderboard({
    required LeaderboardType type,
    String? region,
    required int limit,
  });
  Future<int> getUserRank(String userId, LeaderboardType type);
  Future<List<LevelReward>> getLevelRewards(int level);
  Future<bool> claimLevelRewards(String userId, int level);
  Future<bool> checkVIPStatus(String userId);
  Future<bool> isFeatureUnlocked(String userId, String featureId);

  // Challenge Operations
  Future<List<DailyChallenge>> getDailyChallenges(String userId);
  Future<List<UserChallengeProgressModel>> getChallengeProgress(String userId);
  Future<UserChallengeProgressModel> trackChallengeProgress(
    String userId,
    String challengeId,
    int incrementBy,
  );
  Future<List<ChallengeReward>> claimChallengeReward(
    String userId,
    String challengeId,
  );
  Future<List<DailyChallenge>> getWeeklyChallenges(String userId);
  Future<SeasonalEventModel?> getActiveSeasonalEvent();
  Future<List<DailyChallenge>> getSeasonalChallenges(
    String userId,
    String eventId,
  );
  Future<Map<String, dynamic>> getSeasonalThemeConfig();

  // User Initialization
  Future<void> initializeUserGamification(String userId);
}

class GamificationRemoteDataSourceImpl
    implements GamificationRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseFunctions functions;

  GamificationRemoteDataSourceImpl({
    required this.firestore,
    required this.functions,
  });

  // Collections
  CollectionReference get _achievementProgressCollection =>
      firestore.collection('achievement_progress');
  CollectionReference get _userLevelsCollection =>
      firestore.collection('user_levels');
  CollectionReference get _xpTransactionsCollection =>
      firestore.collection('xp_transactions');
  CollectionReference get _challengeProgressCollection =>
      firestore.collection('challenge_progress');
  CollectionReference get _seasonalEventsCollection =>
      firestore.collection('seasonal_events');
  CollectionReference get _levelRewardsClaimedCollection =>
      firestore.collection('level_rewards_claimed');

  // ===== Achievement Operations =====

  @override
  Future<List<Achievement>> getAllAchievements() async {
    // Achievements are defined in code, not in database
    return Achievements.getAllAchievements();
  }

  @override
  Future<List<UserAchievementProgressModel>> getUserAchievementProgress(
    String userId,
  ) async {
    final snapshot = await _achievementProgressCollection
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs
        .map((doc) => UserAchievementProgressModel.fromFirestore(doc))
        .toList();
  }

  @override
  Future<UserAchievementProgressModel> getAchievementProgress(
    String userId,
    String achievementId,
  ) async {
    final docId = '${userId}_$achievementId';
    final doc = await _achievementProgressCollection.doc(docId).get();

    if (!doc.exists) {
      // Initialize progress
      final achievement = Achievements.getAllAchievements()
          .firstWhere((a) => a.achievementId == achievementId);

      final initialProgress = UserAchievementProgressModel(
        userId: userId,
        achievementId: achievementId,
        progress: 0,
        requiredCount: achievement.requiredCount,
        isUnlocked: false,
        rewardsClaimed: false,
      );

      await _achievementProgressCollection.doc(docId).set(initialProgress.toMap());
      return initialProgress;
    }

    return UserAchievementProgressModel.fromFirestore(doc);
  }

  @override
  Future<UserAchievementProgressModel> unlockAchievement(
    String userId,
    String achievementId,
  ) async {
    final docId = '${userId}_$achievementId';

    final updatedProgress = await firestore.runTransaction((transaction) async {
      final docRef = _achievementProgressCollection.doc(docId);
      final doc = await transaction.get(docRef);

      if (!doc.exists) {
        throw Exception('Achievement progress not found');
      }

      final currentProgress = UserAchievementProgressModel.fromFirestore(doc as DocumentSnapshot<Object?>);

      if (currentProgress.isUnlocked) {
        throw Exception('Achievement already unlocked');
      }

      final updated = currentProgress.copyWith(
        isUnlocked: true,
        unlockedAt: DateTime.now(),
      );

      transaction.update(docRef, updated.toMap());
      return updated;
    });

    // Call Cloud Function to grant rewards
    await functions.httpsCallable('unlockAchievementReward').call({
      'userId': userId,
      'achievementId': achievementId,
    });

    return updatedProgress;
  }

  @override
  Future<UserAchievementProgressModel> trackAchievementProgress(
    String userId,
    String achievementId,
    int incrementBy,
  ) async {
    final docId = '${userId}_$achievementId';

    final updatedProgress = await firestore.runTransaction((transaction) async {
      final docRef = _achievementProgressCollection.doc(docId);
      final doc = await transaction.get(docRef);

      UserAchievementProgressModel currentProgress;

      if (!doc.exists) {
        // Initialize if doesn't exist
        final achievement = Achievements.getAllAchievements()
            .firstWhere((a) => a.achievementId == achievementId);

        currentProgress = UserAchievementProgressModel(
          userId: userId,
          achievementId: achievementId,
          progress: 0,
          requiredCount: achievement.requiredCount,
          isUnlocked: false,
          rewardsClaimed: false,
        );
      } else {
        currentProgress = UserAchievementProgressModel.fromFirestore(doc as DocumentSnapshot<Object?>);
      }

      final updated = currentProgress.copyWith(
        progress: currentProgress.progress + incrementBy,
      );

      transaction.set(docRef, updated.toMap());
      return updated;
    });

    return updatedProgress;
  }

  // ===== Level & XP Operations =====

  @override
  Future<UserLevelModel> getUserLevel(String userId) async {
    final doc = await _userLevelsCollection.doc(userId).get();

    if (!doc.exists) {
      // Fetch profile data to include in leaderboard
      String? displayName;
      String? photoUrl;
      String? region;
      try {
        final profileDoc = await firestore.collection('profiles').doc(userId).get();
        if (profileDoc.exists) {
          final data = profileDoc.data();
          displayName = data?['displayName'] as String?;
          final photoUrls = data?['photoUrls'] as List<dynamic>?;
          photoUrl = (photoUrls != null && photoUrls.isNotEmpty) ? photoUrls.first as String : null;
          final location = data?['location'] as Map<String, dynamic>?;
          region = location?['country'] as String?;
        }
      } catch (_) {}

      // Initialize level with profile data for leaderboard
      final initialLevel = UserLevelModel(
        userId: userId,
        level: 1,
        currentXP: 0,
        totalXP: 0,
        isVIP: false,
      );

      final levelMap = initialLevel.toMap();
      levelMap['displayName'] = displayName ?? 'Unknown';
      levelMap['photoUrl'] = photoUrl;
      levelMap['region'] = region ?? '';

      await _userLevelsCollection.doc(userId).set(levelMap);
      return initialLevel;
    }

    return UserLevelModel.fromFirestore(doc);
  }

  @override
  Future<UserLevelModel> grantXP(
    String userId,
    int xpAmount,
    String reason,
  ) async {
    final updatedLevel = await firestore.runTransaction((transaction) async {
      final docRef = _userLevelsCollection.doc(userId);
      final doc = await transaction.get(docRef);

      UserLevelModel currentLevel;

      if (!doc.exists) {
        currentLevel = UserLevelModel(
          userId: userId,
          level: 1,
          currentXP: 0,
          totalXP: 0,
          isVIP: false,
        );
      } else {
        currentLevel = UserLevelModel.fromFirestore(doc as DocumentSnapshot<Object?>);
      }

      final newTotalXP = currentLevel.totalXP + xpAmount;
      final newLevel = LevelSystem.levelFromXP(newTotalXP);
      final newCurrentXP = LevelSystem.xpIntoCurrentLevel(newTotalXP);

      // Check for VIP status (Point 193: Level 50+)
      final isVIP = newLevel >= 50;

      final updated = currentLevel.copyWith(
        level: newLevel,
        currentXP: newCurrentXP,
        totalXP: newTotalXP,
        isVIP: isVIP,
      );

      transaction.set(docRef, updated.toMap());

      // Record XP transaction
      final xpTransaction = XPTransactionModel(
        transactionId: '',
        userId: userId,
        actionType: reason,
        xpAmount: xpAmount,
        createdAt: DateTime.now(),
        levelBefore: currentLevel.level,
        levelAfter: newLevel,
      );

      final xpTransactionRef = _xpTransactionsCollection.doc();
      transaction.set(xpTransactionRef, xpTransaction.toMap());

      return updated;
    });

    return updatedLevel;
  }

  @override
  Future<List<XPTransactionModel>> getXPHistory(
    String userId,
    int limit,
  ) async {
    final snapshot = await _xpTransactionsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => XPTransactionModel.fromFirestore(doc))
        .toList();
  }

  @override
  Future<List<LeaderboardEntryModel>> getLeaderboard({
    required LeaderboardType type,
    String? region,
    required int limit,
  }) async {
    Query query = _userLevelsCollection
        .orderBy('totalXP', descending: true)
        .limit(limit);

    if (type == LeaderboardType.regional && region != null) {
      query = query.where('region', isEqualTo: region);
    }

    final snapshot = await query.get();

    final entries = <LeaderboardEntryModel>[];
    int rank = 1;

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      entries.add(LeaderboardEntryModel(
        rank: rank++,
        userId: doc.id,
        username: data['displayName'] as String? ?? data['username'] as String? ?? 'Unknown',
        level: data['level'] as int,
        totalXP: data['totalXP'] as int,
        region: data['region'] as String? ?? '',
        isVIP: data['isVIP'] as bool? ?? false,
        photoUrl: data['photoUrl'] as String?,
      ));
    }

    return entries;
  }

  @override
  Future<int> getUserRank(String userId, LeaderboardType type) async {
    final userLevel = await getUserLevel(userId);

    // Count users with higher XP
    final higherXPCount = await _userLevelsCollection
        .where('totalXP', isGreaterThan: userLevel.totalXP)
        .count()
        .get();

    return higherXPCount.count! + 1;
  }

  @override
  Future<List<LevelReward>> getLevelRewards(int level) async {
    // Level rewards are defined in code
    return StandardLevelRewards.getRewardsForLevel(level);
  }

  @override
  Future<bool> claimLevelRewards(String userId, int level) async {
    final docId = '${userId}_$level';

    // Check if already claimed
    final doc = await _levelRewardsClaimedCollection.doc(docId).get();
    if (doc.exists) {
      return false; // Already claimed
    }

    // Mark as claimed
    await _levelRewardsClaimedCollection.doc(docId).set({
      'userId': userId,
      'level': level,
      'claimedAt': FieldValue.serverTimestamp(),
    });

    // Call Cloud Function to grant rewards
    await functions.httpsCallable('claimLevelRewards').call({
      'userId': userId,
      'level': level,
    });

    return true;
  }

  @override
  Future<bool> checkVIPStatus(String userId) async {
    final userLevel = await getUserLevel(userId);
    return userLevel.isVIP;
  }

  @override
  Future<bool> isFeatureUnlocked(String userId, String featureId) async {
    final userLevel = await getUserLevel(userId);

    // Point 195: Level-gated features
    final featureRequirements = {
      'custom_chat_themes': 10,
      'profile_video': 25,
      'advanced_filters': 15,
      'unlimited_rewinds': 30,
      'vip_badge': 50,
      'priority_likes': 40,
    };

    final requiredLevel = featureRequirements[featureId];
    if (requiredLevel == null) {
      return true; // Feature doesn't require level
    }

    return userLevel.level >= requiredLevel;
  }

  // ===== Challenge Operations =====

  @override
  Future<List<DailyChallenge>> getDailyChallenges(String userId) async {
    // Get rotating challenges based on current date
    return DailyChallenges.getRotatingChallenges();
  }

  @override
  Future<List<UserChallengeProgressModel>> getChallengeProgress(
    String userId,
  ) async {
    final snapshot = await _challengeProgressCollection
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs
        .map((doc) => UserChallengeProgressModel.fromFirestore(doc))
        .toList();
  }

  @override
  Future<UserChallengeProgressModel> trackChallengeProgress(
    String userId,
    String challengeId,
    int incrementBy,
  ) async {
    final docId = '${userId}_$challengeId';

    final updatedProgress = await firestore.runTransaction((transaction) async {
      final docRef = _challengeProgressCollection.doc(docId);
      final doc = await transaction.get(docRef);

      UserChallengeProgressModel currentProgress;

      if (!doc.exists) {
        // Find challenge to get required count
        final allChallenges = [
          ...DailyChallenges.getRotatingChallenges(),
          ...WeeklyChallenges.getAllWeeklyChallenges(),
        ];

        final challenge = allChallenges.firstWhere(
          (c) => c.challengeId == challengeId,
        );

        currentProgress = UserChallengeProgressModel(
          userId: userId,
          challengeId: challengeId,
          progress: 0,
          requiredCount: challenge.requiredCount,
          isCompleted: false,
          rewardsClaimed: false,
        );
      } else {
        currentProgress = UserChallengeProgressModel.fromFirestore(doc as DocumentSnapshot<Object?>);
      }

      final newProgress = currentProgress.progress + incrementBy;
      final isCompleted = newProgress >= currentProgress.requiredCount;

      final updated = currentProgress.copyWith(
        progress: newProgress,
        isCompleted: isCompleted,
        completedAt: isCompleted && !currentProgress.isCompleted
            ? DateTime.now()
            : currentProgress.completedAt,
      );

      transaction.set(docRef, updated.toMap());
      return updated;
    });

    return updatedProgress;
  }

  @override
  Future<List<ChallengeReward>> claimChallengeReward(
    String userId,
    String challengeId,
  ) async {
    final docId = '${userId}_$challengeId';

    await firestore.runTransaction((transaction) async {
      final docRef = _challengeProgressCollection.doc(docId);
      final doc = await transaction.get(docRef);

      if (!doc.exists) {
        throw Exception('Challenge progress not found');
      }

      final progress = UserChallengeProgressModel.fromFirestore(doc as DocumentSnapshot<Object?>);

      if (!progress.isCompleted) {
        throw Exception('Challenge not completed');
      }

      if (progress.rewardsClaimed) {
        throw Exception('Rewards already claimed');
      }

      final updated = progress.copyWith(rewardsClaimed: true);
      transaction.update(docRef, updated.toMap());
    });

    // Call Cloud Function to grant rewards
    final result = await functions.httpsCallable('claimChallengeReward').call({
      'userId': userId,
      'challengeId': challengeId,
    });

    final rewardsData = result.data['rewards'] as List<dynamic>;
    return rewardsData
        .map((r) => ChallengeReward(
              type: r['type'] as String,
              amount: r['amount'] as int,
              itemId: r['itemId'] as String?,
            ))
        .toList();
  }

  @override
  Future<List<DailyChallenge>> getWeeklyChallenges(String userId) async {
    return WeeklyChallenges.getAllWeeklyChallenges();
  }

  @override
  Future<SeasonalEventModel?> getActiveSeasonalEvent() async {
    final now = DateTime.now();

    final snapshot = await _seasonalEventsCollection
        .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
        .where('endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return SeasonalEventModel.fromFirestore(snapshot.docs.first);
  }

  @override
  Future<List<DailyChallenge>> getSeasonalChallenges(
    String userId,
    String eventId,
  ) async {
    final eventDoc = await _seasonalEventsCollection.doc(eventId).get();

    if (!eventDoc.exists) {
      return [];
    }

    final event = SeasonalEventModel.fromFirestore(eventDoc);
    return event.challenges;
  }

  @override
  Future<Map<String, dynamic>> getSeasonalThemeConfig() async {
    final event = await getActiveSeasonalEvent();

    if (event == null) {
      return {}; // No active event
    }

    return event.themeConfig;
  }

  // ===== User Initialization =====

  /// Initialize gamification data for a new user
  /// This should be called after profile creation in onboarding
  @override
  Future<void> initializeUserGamification(String userId) async {
    // Check if already initialized
    final existingLevel = await _userLevelsCollection.doc(userId).get();
    if (existingLevel.exists) {
      return; // Already initialized
    }

    // Initialize user level document
    final initialLevel = UserLevelModel(
      userId: userId,
      level: 1,
      currentXP: 0,
      totalXP: 0,
      isVIP: false,
    );

    await _userLevelsCollection.doc(userId).set(initialLevel.toMap());

    // Initialize all achievement progress documents
    final allAchievements = Achievements.getAllAchievements();

    final batch = firestore.batch();

    for (final achievement in allAchievements) {
      final docId = '${userId}_${achievement.achievementId}';
      final progressRef = _achievementProgressCollection.doc(docId);

      final initialProgress = UserAchievementProgressModel(
        userId: userId,
        achievementId: achievement.achievementId,
        progress: 0,
        requiredCount: achievement.requiredCount,
        isUnlocked: false,
        rewardsClaimed: false,
      );

      batch.set(progressRef, initialProgress.toMap());
    }

    await batch.commit();

    // Grant welcome XP bonus
    await grantXP(userId, 50, 'welcome_bonus');
  }
}
