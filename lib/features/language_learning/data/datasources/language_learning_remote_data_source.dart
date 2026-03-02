import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/entities.dart';
import '../models/models.dart';

abstract class LanguageLearningRemoteDataSource {
  // Daily Hints
  Future<DailyHintModel> getDailyHint();
  Future<void> markHintAsViewed(String hintId);
  Future<void> markHintAsLearned(String hintId);

  // Phrases
  Future<List<LanguagePhraseModel>> getPhrasesForLanguage(
    String languageCode, {
    PhraseCategory? category,
    PhraseDifficulty? difficulty,
    int? limit,
    int? offset,
  });
  Future<LanguagePhraseModel> getPhraseById(String phraseId);
  Future<void> markPhraseAsLearned(String phraseId);
  Future<void> addPhraseToFavorites(String phraseId);
  Future<void> removePhraseFromFavorites(String phraseId);
  Future<List<LanguagePhraseModel>> getFavoritePhrases();

  // Language Progress
  Future<LanguageProgressModel> getLanguageProgress(String languageCode);
  Future<List<LanguageProgressModel>> getAllLanguageProgress();
  Future<void> updateLanguageProgress(LanguageProgressModel progress);

  // Learning Streak
  Future<LearningStreakModel> getLearningStreak();
  Future<LearningStreakModel> updateLearningStreak();
  Future<void> claimStreakMilestone(int milestoneDay);

  // Flashcards
  Future<List<FlashcardDeckModel>> getFlashcardDecks({
    String? languageCode,
    bool? includePremium,
  });
  Future<FlashcardDeckModel> getFlashcardDeckById(String deckId);
  Future<List<FlashcardModel>> getDueFlashcards({String? languageCode, int? limit});
  Future<void> updateFlashcardReview(String flashcardId, FlashcardAnswer answer);
  Future<void> purchaseFlashcardDeck(String deckId);

  // Cultural Quizzes
  Future<List<CulturalQuizModel>> getAvailableQuizzes({
    String? languageCode,
    QuizDifficulty? difficulty,
  });
  Future<CulturalQuizModel> getQuizById(String quizId);
  Future<QuizResultModel> submitQuizResult(QuizResultModel result);
  Future<List<QuizResultModel>> getQuizHistory();

  // Achievements
  Future<List<LanguageAchievementModel>> getLanguageAchievements();
  Future<List<LanguageAchievementModel>> getUnlockedAchievements();
  Future<void> updateAchievementProgress(String achievementId, int progress);
  Future<void> claimAchievementReward(String achievementId);

  // Translation tracking
  Future<void> trackTranslation(String fromLanguage, String toLanguage);
  Future<int> getTranslationCount();

  // Lessons
  Future<List<Lesson>> getLessonsForLanguage(
    String languageCode, {
    LessonLevel? level,
    LessonCategory? category,
    int? limit,
    int? offset,
  });
  Future<Lesson> getLessonById(String lessonId);
  Future<UserLessonAccess> purchaseLesson(String lessonId);
  Future<List<UserLessonAccess>> getPurchasedLessons();
  Future<void> updateLessonProgress(String lessonId, LessonSectionProgress progress);
  Future<List<LessonSectionProgress>> getLessonProgress(String lessonId);
  Future<void> rateLesson(String lessonId, int rating, String? review);

  // Teachers
  Future<TeacherApplication> submitTeacherApplication(TeacherApplication application);
  Future<Teacher> getTeacherProfile(String teacherId);
  Future<List<Lesson>> getLessonsByTeacher(String teacherId);
  Future<List<TeacherEarning>> getTeacherEarnings();
  Future<TeacherStats> getTeacherStats();

  // User Learning Progress
  Future<UserLearningProgress> getUserLearningProgress(String languageCode);
  Future<List<UserLearningProgress>> getAllUserProgress();
  Future<void> setLearningGoal(LearningGoal goal);
  Future<List<LearningGoal>> getLearningGoals();
  Future<void> updateGoalProgress(String goalId, int progress);

  // Icebreakers
  Future<List<Icebreaker>> getIcebreakersForCountry(String countryCode);
  Future<void> markIcebreakerAsUsed(String icebreakerId);
  Future<Icebreaker> getRandomIcebreaker(String matchCountryCode);

  // Leaderboard
  Future<LanguageLeaderboard> getLeaderboard({
    LeaderboardType type = LeaderboardType.totalXp,
    LeaderboardPeriod period = LeaderboardPeriod.weekly,
  });
  Future<LeaderboardEntry> getUserLeaderboardRank();

  // AI Coach Sessions
  Future<AiCoachSession> startCoachSession({
    required String languageCode,
    required CoachScenario scenario,
  });
  Future<AiCoachSession> saveCoachSession(AiCoachSession session);
  Future<AiCoachSession?> getCoachSession(String sessionId);
  Future<AiCoachSession> endCoachSession(String sessionId);
  Future<List<AiCoachSession>> getCoachSessionHistory();
  Future<void> addCoachMessage(String sessionId, CoachMessage message);

  // Language Packs
  Future<void> purchaseLanguagePack(String packId);
  Future<List<LanguagePack>> getPurchasedPacks();

  // Challenges
  Future<void> updateChallengeProgress(String challengeId, int progress);
  Future<void> claimChallengeReward(String challengeId);

  // Seasonal Events
  Future<void> updateSeasonalChallengeProgress(
    String eventId,
    String challengeId,
    int progress,
  );
  Future<void> claimSeasonalChallengeReward(
    String eventId,
    String challengeId,
  );

  // Video Call Language Tracking
  Future<void> trackVideoCallLanguageUse(String languageCode, Duration duration);
}

class LanguageLearningRemoteDataSourceImpl
    implements LanguageLearningRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  LanguageLearningRemoteDataSourceImpl({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  String get _userId => _auth.currentUser?.uid ?? '';

  CollectionReference get _phrasesCollection =>
      _firestore.collection('language_phrases');

  CollectionReference get _userProgressCollection =>
      _firestore.collection('users').doc(_userId).collection('language_progress');

  CollectionReference get _dailyHintsCollection =>
      _firestore.collection('daily_hints');

  CollectionReference get _flashcardDecksCollection =>
      _firestore.collection('flashcard_decks');

  CollectionReference get _quizzesCollection =>
      _firestore.collection('cultural_quizzes');

  CollectionReference get _achievementsCollection =>
      _firestore.collection('users').doc(_userId).collection('language_achievements');

  DocumentReference get _userStreakDoc =>
      _firestore.collection('users').doc(_userId).collection('streaks').doc('language_learning');

  @override
  Future<DailyHintModel> getDailyHint() async {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    // Try to get today's hint
    final snapshot = await _dailyHintsCollection
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final hintData = snapshot.docs.first.data() as Map<String, dynamic>;

      // Check if user has viewed/learned
      final userHintDoc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('daily_hints_progress')
          .doc(snapshot.docs.first.id)
          .get();

      if (userHintDoc.exists) {
        final userData = userHintDoc.data()!;
        hintData['isViewed'] = userData['isViewed'] ?? false;
        hintData['isLearned'] = userData['isLearned'] ?? false;
      }

      hintData['id'] = snapshot.docs.first.id;
      return DailyHintModel.fromJson(hintData);
    }

    // Generate a random hint if none exists for today
    return _generateDailyHint(todayStart);
  }

  Future<DailyHintModel> _generateDailyHint(DateTime date) async {
    // Get a random phrase for today's hint
    final phrasesSnapshot = await _phrasesCollection.limit(50).get();

    if (phrasesSnapshot.docs.isEmpty) {
      // Return default hint
      return DailyHintModel(
        id: 'default_${date.millisecondsSinceEpoch}',
        phrase: const LanguagePhraseModel(
          id: 'default_phrase',
          phrase: 'Hola',
          translation: 'Hello',
          languageCode: 'es',
          languageName: 'Spanish',
          pronunciation: 'OH-lah',
          category: PhraseCategory.greetings,
          difficulty: PhraseDifficulty.beginner,
        ),
        date: date,
      );
    }

    // Select random phrase based on day
    final index = date.day % phrasesSnapshot.docs.length;
    final phraseData = phrasesSnapshot.docs[index].data() as Map<String, dynamic>;
    phraseData['id'] = phrasesSnapshot.docs[index].id;

    final hint = DailyHintModel(
      id: 'hint_${date.millisecondsSinceEpoch}',
      phrase: LanguagePhraseModel.fromJson(phraseData),
      date: date,
    );

    // Save the hint
    await _dailyHintsCollection.doc(hint.id).set({
      ...hint.toJson(),
      'date': Timestamp.fromDate(date),
    });

    return hint;
  }

  @override
  Future<void> markHintAsViewed(String hintId) async {
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('daily_hints_progress')
        .doc(hintId)
        .set({'isViewed': true}, SetOptions(merge: true));
  }

  @override
  Future<void> markHintAsLearned(String hintId) async {
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('daily_hints_progress')
        .doc(hintId)
        .set({
      'isViewed': true,
      'isLearned': true,
      'learnedAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  @override
  Future<List<LanguagePhraseModel>> getPhrasesForLanguage(
    String languageCode, {
    PhraseCategory? category,
    PhraseDifficulty? difficulty,
    int? limit,
    int? offset,
  }) async {
    Query query = _phrasesCollection.where('languageCode', isEqualTo: languageCode);

    if (category != null) {
      query = query.where('category', isEqualTo: category.name);
    }

    if (difficulty != null) {
      query = query.where('difficulty', isEqualTo: difficulty.name);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return LanguagePhraseModel.fromJson(data);
    }).toList();
  }

  @override
  Future<LanguagePhraseModel> getPhraseById(String phraseId) async {
    final doc = await _phrasesCollection.doc(phraseId).get();
    if (!doc.exists) {
      throw Exception('Phrase not found');
    }
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return LanguagePhraseModel.fromJson(data);
  }

  @override
  Future<void> markPhraseAsLearned(String phraseId) async {
    final phrase = await getPhraseById(phraseId);

    await _userProgressCollection.doc(phrase.languageCode).set({
      'learnedPhraseIds': FieldValue.arrayUnion([phraseId]),
      'phrasesLearned': FieldValue.increment(1),
      'wordsLearned': FieldValue.increment(1),
      'lastPracticeDate': Timestamp.now(),
    }, SetOptions(merge: true));

    // Update learning streak
    await updateLearningStreak();
  }

  @override
  Future<void> addPhraseToFavorites(String phraseId) async {
    final phrase = await getPhraseById(phraseId);

    await _userProgressCollection.doc(phrase.languageCode).set({
      'favoritesPhraseIds': FieldValue.arrayUnion([phraseId]),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> removePhraseFromFavorites(String phraseId) async {
    final phrase = await getPhraseById(phraseId);

    await _userProgressCollection.doc(phrase.languageCode).update({
      'favoritesPhraseIds': FieldValue.arrayRemove([phraseId]),
    });
  }

  @override
  Future<List<LanguagePhraseModel>> getFavoritePhrases() async {
    final progressSnapshot = await _userProgressCollection.get();
    final favoriteIds = <String>[];

    for (final doc in progressSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final ids = (data['favoritesPhraseIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [];
      favoriteIds.addAll(ids);
    }

    if (favoriteIds.isEmpty) return [];

    final phrases = <LanguagePhraseModel>[];
    for (final id in favoriteIds) {
      try {
        final phrase = await getPhraseById(id);
        phrases.add(phrase);
      } catch (_) {}
    }
    return phrases;
  }

  @override
  Future<LanguageProgressModel> getLanguageProgress(String languageCode) async {
    final doc = await _userProgressCollection.doc(languageCode).get();

    if (!doc.exists) {
      // Return default progress
      return LanguageProgressModel(
        userId: _userId,
        languageCode: languageCode,
        languageName: SupportedLanguage.getByCode(languageCode)?.name ?? languageCode,
      );
    }

    final data = doc.data() as Map<String, dynamic>;
    data['userId'] = _userId;
    data['languageCode'] = languageCode;
    data['languageName'] = SupportedLanguage.getByCode(languageCode)?.name ?? languageCode;
    return LanguageProgressModel.fromJson(data);
  }

  @override
  Future<List<LanguageProgressModel>> getAllLanguageProgress() async {
    final snapshot = await _userProgressCollection.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['userId'] = _userId;
      data['languageCode'] = doc.id;
      data['languageName'] = SupportedLanguage.getByCode(doc.id)?.name ?? doc.id;
      return LanguageProgressModel.fromJson(data);
    }).toList();
  }

  @override
  Future<void> updateLanguageProgress(LanguageProgressModel progress) async {
    await _userProgressCollection.doc(progress.languageCode).set(
      progress.toJson(),
      SetOptions(merge: true),
    );
  }

  @override
  Future<LearningStreakModel> getLearningStreak() async {
    final doc = await _userStreakDoc.get();

    if (!doc.exists) {
      return LearningStreakModel(
        id: 'language_learning',
        odUserId: _userId,
      );
    }

    final data = doc.data() as Map<String, dynamic>;
    data['id'] = 'language_learning';
    data['odUserId'] = _userId;
    return LearningStreakModel.fromJson(data);
  }

  @override
  Future<LearningStreakModel> updateLearningStreak() async {
    final currentStreak = await getLearningStreak();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (currentStreak.isPracticedToday) {
      return currentStreak;
    }

    int newStreak = currentStreak.currentStreak;

    if (currentStreak.lastPracticeDate != null) {
      final lastPractice = currentStreak.lastPracticeDate!;
      final lastPracticeDay = DateTime(lastPractice.year, lastPractice.month, lastPractice.day);
      final difference = today.difference(lastPracticeDay).inDays;

      if (difference == 1) {
        newStreak += 1;
      } else if (difference > 1) {
        newStreak = 1;
      }
    } else {
      newStreak = 1;
    }

    final newLongestStreak = newStreak > currentStreak.longestStreak
        ? newStreak
        : currentStreak.longestStreak;

    final updatedStreak = LearningStreakModel(
      id: 'language_learning',
      odUserId: _userId,
      currentStreak: newStreak,
      longestStreak: newLongestStreak,
      lastPracticeDate: now,
      practiceHistory: [...currentStreak.practiceHistory, now],
      achievedMilestones: currentStreak.achievedMilestones,
      totalPracticeDays: currentStreak.totalPracticeDays + 1,
    );

    await _userStreakDoc.set(updatedStreak.toJson());
    return updatedStreak;
  }

  @override
  Future<void> claimStreakMilestone(int milestoneDay) async {
    final milestone = StreakMilestone.allMilestones.firstWhere(
      (m) => m.requiredDays == milestoneDay,
    );

    await _userStreakDoc.update({
      'achievedMilestones': FieldValue.arrayUnion([
        {'requiredDays': milestone.requiredDays, 'name': milestone.name}
      ]),
    });
  }

  @override
  Future<List<FlashcardDeckModel>> getFlashcardDecks({
    String? languageCode,
    bool? includePremium,
  }) async {
    Query query = _flashcardDecksCollection;

    if (languageCode != null) {
      query = query.where('languageCode', isEqualTo: languageCode);
    }

    if (includePremium == false) {
      query = query.where('isPremium', isEqualTo: false);
    }

    final snapshot = await query.get();

    // Get user's purchased decks
    final purchasedSnapshot = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('purchased_decks')
        .get();
    final purchasedIds = purchasedSnapshot.docs.map((d) => d.id).toSet();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      data['isOwned'] = purchasedIds.contains(doc.id);
      return FlashcardDeckModel.fromJson(data);
    }).toList();
  }

  @override
  Future<FlashcardDeckModel> getFlashcardDeckById(String deckId) async {
    final doc = await _flashcardDecksCollection.doc(deckId).get();
    if (!doc.exists) {
      throw Exception('Deck not found');
    }
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return FlashcardDeckModel.fromJson(data);
  }

  @override
  Future<List<FlashcardModel>> getDueFlashcards({
    String? languageCode,
    int? limit,
  }) async {
    final now = DateTime.now();
    Query query = _firestore
        .collection('users')
        .doc(_userId)
        .collection('flashcards')
        .where('nextReviewAt', isLessThanOrEqualTo: Timestamp.fromDate(now));

    if (languageCode != null) {
      query = query.where('phrase.languageCode', isEqualTo: languageCode);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return FlashcardModel.fromJson(data);
    }).toList();
  }

  @override
  Future<void> updateFlashcardReview(String flashcardId, FlashcardAnswer answer) async {
    final doc = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('flashcards')
        .doc(flashcardId)
        .get();

    if (!doc.exists) {
      throw Exception('Flashcard not found');
    }

    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    final flashcard = FlashcardModel.fromJson(data);

    final isCorrect = answer != FlashcardAnswer.again;
    final newStreak = isCorrect ? flashcard.streak + 1 : 0;
    final newEaseFactor = _calculateNewEaseFactor(flashcard.easeFactor, answer);
    final newStatus = _calculateNewStatus(flashcard, answer);

    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('flashcards')
        .doc(flashcardId)
        .update({
      'reviewCount': FieldValue.increment(1),
      'correctCount': isCorrect ? FieldValue.increment(1) : flashcard.correctCount,
      'incorrectCount': !isCorrect ? FieldValue.increment(1) : flashcard.incorrectCount,
      'lastReviewedAt': Timestamp.now(),
      'nextReviewAt': Timestamp.fromDate(flashcard.calculateNextReview(answer)),
      'streak': newStreak,
      'easeFactor': newEaseFactor,
      'status': newStatus.name,
    });

    // Update learning streak
    await updateLearningStreak();
  }

  double _calculateNewEaseFactor(double current, FlashcardAnswer answer) {
    switch (answer) {
      case FlashcardAnswer.again:
        return (current - 0.2).clamp(1.3, 2.5);
      case FlashcardAnswer.hard:
        return (current - 0.15).clamp(1.3, 2.5);
      case FlashcardAnswer.good:
        return current;
      case FlashcardAnswer.easy:
        return (current + 0.15).clamp(1.3, 2.5);
    }
  }

  FlashcardStatus _calculateNewStatus(Flashcard flashcard, FlashcardAnswer answer) {
    if (answer == FlashcardAnswer.again) {
      return FlashcardStatus.learning;
    }
    if (flashcard.streak >= 3 && answer == FlashcardAnswer.easy) {
      return FlashcardStatus.mastered;
    }
    if (flashcard.reviewCount >= 2) {
      return FlashcardStatus.reviewing;
    }
    return FlashcardStatus.learning;
  }

  @override
  Future<void> purchaseFlashcardDeck(String deckId) async {
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('purchased_decks')
        .doc(deckId)
        .set({
      'purchasedAt': Timestamp.now(),
    });
  }

  @override
  Future<List<CulturalQuizModel>> getAvailableQuizzes({
    String? languageCode,
    QuizDifficulty? difficulty,
  }) async {
    Query query = _quizzesCollection;

    if (languageCode != null) {
      query = query.where('languageCode', isEqualTo: languageCode);
    }

    if (difficulty != null) {
      query = query.where('difficulty', isEqualTo: difficulty.name);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return CulturalQuizModel.fromJson(data);
    }).toList();
  }

  @override
  Future<CulturalQuizModel> getQuizById(String quizId) async {
    final doc = await _quizzesCollection.doc(quizId).get();
    if (!doc.exists) {
      throw Exception('Quiz not found');
    }
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return CulturalQuizModel.fromJson(data);
  }

  @override
  Future<QuizResultModel> submitQuizResult(QuizResultModel result) async {
    final docRef = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('quiz_results')
        .add(result.toJson());

    // Update language progress
    await _userProgressCollection.doc(result.quizId.split('_').first).set({
      'quizzesTaken': FieldValue.increment(1),
      'quizzesPerfect': result.isPerfect ? FieldValue.increment(1) : 0,
      'totalXpEarned': FieldValue.increment(result.xpEarned),
    }, SetOptions(merge: true));

    // Update learning streak
    await updateLearningStreak();

    return result;
  }

  @override
  Future<List<QuizResultModel>> getQuizHistory() async {
    final snapshot = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('quiz_results')
        .orderBy('completedAt', descending: true)
        .limit(50)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return QuizResultModel.fromJson(data);
    }).toList();
  }

  @override
  Future<List<LanguageAchievementModel>> getLanguageAchievements() async {
    final snapshot = await _achievementsCollection.get();

    // Get all predefined achievements and merge with user progress
    final achievements = LanguageAchievement.allAchievements.map((achievement) {
      final userDoc = snapshot.docs.where((d) => d.id == achievement.id).firstOrNull;

      if (userDoc != null) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return LanguageAchievementModel(
          id: achievement.id,
          name: achievement.name,
          description: achievement.description,
          category: achievement.category,
          rarity: achievement.rarity,
          requiredProgress: achievement.requiredProgress,
          currentProgress: userData['currentProgress'] as int? ?? 0,
          xpReward: achievement.xpReward,
          coinReward: achievement.coinReward,
          iconEmoji: achievement.iconEmoji,
          isUnlocked: userData['isUnlocked'] as bool? ?? false,
          unlockedAt: userData['unlockedAt'] != null
              ? (userData['unlockedAt'] as Timestamp).toDate()
              : null,
          isSecret: achievement.isSecret,
        );
      }

      return LanguageAchievementModel.fromEntity(achievement);
    }).toList();

    return achievements;
  }

  @override
  Future<List<LanguageAchievementModel>> getUnlockedAchievements() async {
    final achievements = await getLanguageAchievements();
    return achievements.where((a) => a.isUnlocked).toList();
  }

  @override
  Future<void> updateAchievementProgress(String achievementId, int progress) async {
    final achievement = LanguageAchievement.allAchievements
        .firstWhere((a) => a.id == achievementId);

    final isUnlocked = progress >= achievement.requiredProgress;

    await _achievementsCollection.doc(achievementId).set({
      'currentProgress': progress,
      'isUnlocked': isUnlocked,
      if (isUnlocked) 'unlockedAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> claimAchievementReward(String achievementId) async {
    await _achievementsCollection.doc(achievementId).update({
      'rewardClaimed': true,
      'rewardClaimedAt': Timestamp.now(),
    });
  }

  @override
  Future<void> trackTranslation(String fromLanguage, String toLanguage) async {
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('translation_history')
        .add({
      'fromLanguage': fromLanguage,
      'toLanguage': toLanguage,
      'timestamp': Timestamp.now(),
    });

    // Update translation count in progress
    await _userProgressCollection.doc(toLanguage).set({
      'translationsCount': FieldValue.increment(1),
    }, SetOptions(merge: true));

    // Update translation achievement progress
    final count = await getTranslationCount();

    // Check translation achievements
    for (final achievement in LanguageAchievement.allAchievements
        .where((a) => a.category == LanguageAchievementCategory.translation)) {
      if (count >= achievement.requiredProgress) {
        await updateAchievementProgress(achievement.id, count);
      }
    }
  }

  @override
  Future<int> getTranslationCount() async {
    final snapshot = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('translation_history')
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  // ==================== Lessons ====================

  CollectionReference get _lessonsCollection =>
      _firestore.collection('lessons');

  CollectionReference get _teachersCollection =>
      _firestore.collection('teachers');

  CollectionReference get _teacherApplicationsCollection =>
      _firestore.collection('teacher_applications');

  @override
  Future<List<Lesson>> getLessonsForLanguage(
    String languageCode, {
    LessonLevel? level,
    LessonCategory? category,
    int? limit,
    int? offset,
  }) async {
    // Simple query - just filter by languageCode to avoid composite index issues
    // We'll sort client-side for flexibility
    Query query = _lessonsCollection
        .where('languageCode', isEqualTo: languageCode);

    if (limit != null) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();

    // Filter and sort client-side to avoid composite index requirements
    var docs = snapshot.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final isPublished = data['isPublished'] as bool? ?? true;
      if (!isPublished) return false;

      if (level != null && data['level'] != level.name) return false;
      if (category != null && data['category'] != category.name) return false;

      return true;
    }).toList();

    // Sort by weekNumber, then dayNumber
    docs.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;
      final weekCompare = (aData['weekNumber'] as int? ?? 0).compareTo(bData['weekNumber'] as int? ?? 0);
      if (weekCompare != 0) return weekCompare;
      return (aData['dayNumber'] as int? ?? 0).compareTo(bData['dayNumber'] as int? ?? 0);
    });

    // Get user's purchased lessons
    final purchasedSnapshot = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('purchased_lessons')
        .get();
    final purchasedIds = purchasedSnapshot.docs.map((d) => d.id).toSet();

    // Return the filtered and sorted docs
    return docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
      data['id'] = doc.id;
      data['isPurchased'] = purchasedIds.contains(doc.id);
      return _lessonFromJson(data);
    }).toList();
  }

  @override
  Future<Lesson> getLessonById(String lessonId) async {
    final doc = await _lessonsCollection.doc(lessonId).get();
    if (!doc.exists) {
      throw Exception('Lesson not found');
    }
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;

    // Check if purchased
    final purchasedDoc = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('purchased_lessons')
        .doc(lessonId)
        .get();
    data['isPurchased'] = purchasedDoc.exists;

    return _lessonFromJson(data);
  }

  Lesson _lessonFromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      languageCode: json['languageCode'] as String,
      languageName: json['languageName'] as String? ?? '',
      level: LessonLevel.values.firstWhere(
        (e) => e.name == json['level'],
        orElse: () => LessonLevel.beginner,
      ),
      category: LessonCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => LessonCategory.dating_basics,
      ),
      lessonNumber: json['lessonNumber'] as int? ?? 0,
      weekNumber: json['weekNumber'] as int? ?? 1,
      dayNumber: json['dayNumber'] as int? ?? 1,
      coinPrice: json['coinPrice'] as int? ?? 0,
      isFree: json['isFree'] as bool? ?? false,
      isPremium: json['isPremium'] as bool? ?? false,
      estimatedMinutes: json['estimatedMinutes'] as int? ?? 15,
      xpReward: json['xpReward'] as int? ?? 100,
      bonusCoins: json['bonusCoins'] as int? ?? 0,
      sections: (json['sections'] as List<dynamic>?)
              ?.map((s) => _lessonSectionFromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      objectives: (json['objectives'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      prerequisites: (json['prerequisites'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      teacherId: json['teacherId'] as String?,
      teacherName: json['teacherName'] as String?,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
      isPublished: json['isPublished'] as bool? ?? false,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      completionCount: json['completionCount'] as int? ?? 0,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  LessonSection _lessonSectionFromJson(Map<String, dynamic> json) {
    return LessonSection(
      id: json['id'] as String,
      title: json['title'] as String,
      type: LessonSectionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => LessonSectionType.vocabulary,
      ),
      orderIndex: json['orderIndex'] as int? ?? json['order'] as int? ?? 0,
      introduction: json['introduction'] as String?,
      contents: (json['contents'] as List<dynamic>?)
              ?.map((e) => _lessonContentFromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      exercises: (json['exercises'] as List<dynamic>?)
              ?.map((e) => _lessonExerciseFromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      xpReward: json['xpReward'] as int? ?? 10,
    );
  }

  LessonContent _lessonContentFromJson(Map<String, dynamic> json) {
    return LessonContent(
      id: json['id'] as String? ?? '',
      type: LessonContentType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => LessonContentType.text,
      ),
      text: json['text'] as String?,
      translation: json['translation'] as String?,
      pronunciation: json['pronunciation'] as String?,
      audioUrl: json['audioUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      extras: json['extras'] as Map<String, dynamic>?,
    );
  }

  LessonExercise _lessonExerciseFromJson(Map<String, dynamic> json) {
    return LessonExercise(
      id: json['id'] as String,
      type: ExerciseType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ExerciseType.multiple_choice,
      ),
      question: json['question'] as String,
      questionTranslation: json['questionTranslation'] as String?,
      audioUrl: json['audioUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      options: (json['options'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      correctAnswer: json['correctAnswer'] as String,
      acceptableAnswers: (json['acceptableAnswers'] as List<dynamic>?)?.map((e) => e as String).toList(),
      explanation: json['explanation'] as String?,
      hint: json['hint'] as String?,
      xpReward: json['xpReward'] as int? ?? 5,
      orderIndex: json['orderIndex'] as int? ?? json['order'] as int? ?? 0,
    );
  }

  @override
  Future<UserLessonAccess> purchaseLesson(String lessonId) async {
    final lesson = await getLessonById(lessonId);

    // Check if already purchased
    final existingPurchase = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('purchased_lessons')
        .doc(lessonId)
        .get();

    if (existingPurchase.exists) {
      throw Exception('Lesson already purchased');
    }

    final accessId = '${_userId}_$lessonId';
    final access = UserLessonAccess(
      id: accessId,
      odUserId: _userId,
      lessonId: lessonId,
      purchasedAt: DateTime.now(),
      coinsPaid: lesson.coinPrice,
    );

    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('purchased_lessons')
        .doc(lessonId)
        .set({
      'id': accessId,
      'purchasedAt': Timestamp.now(),
      'coinsPaid': lesson.coinPrice,
      'isCompleted': false,
      'progressPercent': 0.0,
      'earnedXp': 0,
    });

    return access;
  }

  @override
  Future<List<UserLessonAccess>> getPurchasedLessons() async {
    final snapshot = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('purchased_lessons')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return UserLessonAccess(
        id: data['id'] as String? ?? doc.id,
        odUserId: _userId,
        lessonId: doc.id,
        purchasedAt: data['purchasedAt'] is Timestamp
            ? (data['purchasedAt'] as Timestamp).toDate()
            : DateTime.now(),
        coinsPaid: data['coinsPaid'] as int? ?? 0,
        isCompleted: data['isCompleted'] as bool? ?? false,
        completedAt: data['completedAt'] is Timestamp
            ? (data['completedAt'] as Timestamp).toDate()
            : null,
        progressPercent: (data['progressPercent'] as num?)?.toDouble() ?? 0.0,
        earnedXp: data['earnedXp'] as int? ?? 0,
      );
    }).toList();
  }

  @override
  Future<void> updateLessonProgress(String lessonId, LessonSectionProgress progress) async {
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('lesson_progress')
        .doc('${lessonId}_${progress.sectionId}')
        .set({
      'lessonId': lessonId,
      'sectionId': progress.sectionId,
      'isCompleted': progress.isCompleted,
      'correctAnswers': progress.correctAnswers,
      'totalExercises': progress.totalExercises,
      'attempts': progress.attempts,
      'lastAttemptAt': progress.lastAttemptAt != null ? Timestamp.fromDate(progress.lastAttemptAt!) : null,
    }, SetOptions(merge: true));

    // Update learning streak
    await updateLearningStreak();
  }

  @override
  Future<List<LessonSectionProgress>> getLessonProgress(String lessonId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('lesson_progress')
        .where('lessonId', isEqualTo: lessonId)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return LessonSectionProgress(
        sectionId: data['sectionId'] as String,
        isCompleted: data['isCompleted'] as bool? ?? false,
        correctAnswers: data['correctAnswers'] as int? ?? 0,
        totalExercises: data['totalExercises'] as int? ?? 0,
        attempts: data['attempts'] as int? ?? 0,
        lastAttemptAt: data['lastAttemptAt'] is Timestamp
            ? (data['lastAttemptAt'] as Timestamp).toDate()
            : null,
      );
    }).toList();
  }

  @override
  Future<void> rateLesson(String lessonId, int rating, String? review) async {
    await _firestore
        .collection('lesson_ratings')
        .doc('${lessonId}_$_userId')
        .set({
      'lessonId': lessonId,
      'userId': _userId,
      'rating': rating,
      'review': review,
      'createdAt': Timestamp.now(),
    });

    // Update average rating on lesson (handled by cloud function for accuracy)
  }

  // ==================== Teachers ====================

  @override
  Future<TeacherApplication> submitTeacherApplication(TeacherApplication application) async {
    final docRef = await _teacherApplicationsCollection.add({
      'userId': _userId,
      'fullName': application.fullName,
      'email': application.email,
      'bio': application.bio,
      'teachingExperience': application.teachingExperience,
      'teachingLanguages': application.teachingLanguages,
      'nativeLanguages': application.nativeLanguages,
      'yearsExperience': application.yearsExperience,
      'sampleLessonIdea': application.sampleLessonIdea,
      'certificationUrls': application.certificationUrls,
      'portfolioUrl': application.portfolioUrl,
      'linkedinUrl': application.linkedinUrl,
      'videoIntroUrl': application.videoIntroUrl,
      'motivation': application.motivation,
      'status': 'pending',
      'submittedAt': Timestamp.now(),
    });

    return TeacherApplication(
      id: docRef.id,
      odUserId: _userId,
      fullName: application.fullName,
      email: application.email,
      bio: application.bio,
      teachingExperience: application.teachingExperience,
      teachingLanguages: application.teachingLanguages,
      nativeLanguages: application.nativeLanguages,
      yearsExperience: application.yearsExperience,
      sampleLessonIdea: application.sampleLessonIdea,
      certificationUrls: application.certificationUrls,
      portfolioUrl: application.portfolioUrl,
      linkedinUrl: application.linkedinUrl,
      videoIntroUrl: application.videoIntroUrl,
      motivation: application.motivation,
      status: TeacherStatus.pending,
      submittedAt: DateTime.now(),
    );
  }

  @override
  Future<Teacher> getTeacherProfile(String teacherId) async {
    final doc = await _teachersCollection.doc(teacherId).get();
    if (!doc.exists) {
      throw Exception('Teacher not found');
    }
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return _teacherFromJson(data);
  }

  Teacher _teacherFromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['id'] as String,
      odUserId: json['userId'] as String? ?? json['id'] as String,
      displayName: json['displayName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      bio: json['bio'] as String? ?? '',
      teachingLanguages: (json['teachingLanguages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      nativeLanguages: (json['nativeLanguages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          ['en'],
      status: TeacherStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TeacherStatus.pending,
      ),
      tier: TeacherTier.values.firstWhere(
        (e) => e.name == json['tier'],
        orElse: () => TeacherTier.starter,
      ),
      certifications: (json['certifications'] as List<dynamic>?)
              ?.map((e) => _teacherCertificationFromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      stats: json['stats'] != null
          ? _teacherStatsFromJson(json['stats'] as Map<String, dynamic>)
          : const TeacherStats(),
      paymentInfo: json['paymentInfo'] != null
          ? _teacherPaymentInfoFromJson(json['paymentInfo'] as Map<String, dynamic>)
          : null,
      applicationDate: json['applicationDate'] is Timestamp
          ? (json['applicationDate'] as Timestamp).toDate()
          : DateTime.now(),
      approvalDate: json['approvalDate'] is Timestamp
          ? (json['approvalDate'] as Timestamp).toDate()
          : null,
      approvedBy: json['approvedBy'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
      isActive: json['isActive'] as bool? ?? true,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  TeacherCertification _teacherCertificationFromJson(Map<String, dynamic> json) {
    return TeacherCertification(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      issuingOrganization: json['issuingOrganization'] as String? ?? '',
      issuedDate: json['issuedDate'] is Timestamp
          ? (json['issuedDate'] as Timestamp).toDate()
          : null,
      expiryDate: json['expiryDate'] is Timestamp
          ? (json['expiryDate'] as Timestamp).toDate()
          : null,
      certificateUrl: json['certificateUrl'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      verifiedBy: json['verifiedBy'] as String?,
      verifiedAt: json['verifiedAt'] is Timestamp
          ? (json['verifiedAt'] as Timestamp).toDate()
          : null,
    );
  }

  TeacherStats _teacherStatsFromJson(Map<String, dynamic> json) {
    return TeacherStats(
      totalLessons: json['totalLessons'] as int? ?? 0,
      publishedLessons: json['publishedLessons'] as int? ?? 0,
      totalStudents: json['totalStudents'] as int? ?? 0,
      activeStudents: json['activeStudents'] as int? ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: json['totalRatings'] as int? ?? 0,
      totalCompletions: json['totalCompletions'] as int? ?? 0,
      totalCoinsEarned: json['totalCoinsEarned'] as int? ?? 0,
      totalXpAwarded: json['totalXpAwarded'] as int? ?? 0,
      lessonsByLanguage: (json['lessonsByLanguage'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as int),
          ) ??
          {},
      ratingsByLanguage: (json['ratingsByLanguage'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          ) ??
          {},
      lastLessonCreated: json['lastLessonCreated'] is Timestamp
          ? (json['lastLessonCreated'] as Timestamp).toDate()
          : null,
      lessonsThisMonth: json['lessonsThisMonth'] as int? ?? 0,
    );
  }

  TeacherPaymentInfo _teacherPaymentInfoFromJson(Map<String, dynamic> json) {
    return TeacherPaymentInfo(
      paypalEmail: json['paypalEmail'] as String?,
      stripeAccountId: json['stripeAccountId'] as String?,
      bankAccountNumber: json['bankAccountNumber'] as String?,
      bankRoutingNumber: json['bankRoutingNumber'] as String?,
      bankName: json['bankName'] as String?,
      accountHolderName: json['accountHolderName'] as String?,
      preferredPaymentMethod: json['preferredPaymentMethod'] as String? ?? 'paypal',
      taxId: json['taxId'] as String?,
      country: json['country'] as String?,
      pendingBalance: (json['pendingBalance'] as num?)?.toDouble() ?? 0.0,
      totalEarnings: (json['totalEarnings'] as num?)?.toDouble() ?? 0.0,
      lastPayoutDate: json['lastPayoutDate'] is Timestamp
          ? (json['lastPayoutDate'] as Timestamp).toDate()
          : null,
      lastPayoutAmount: (json['lastPayoutAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  Future<List<Lesson>> getLessonsByTeacher(String teacherId) async {
    final snapshot = await _lessonsCollection
        .where('teacherId', isEqualTo: teacherId)
        .where('isPublished', isEqualTo: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return _lessonFromJson(data);
    }).toList();
  }

  @override
  Future<List<TeacherEarning>> getTeacherEarnings() async {
    final snapshot = await _firestore
        .collection('teachers')
        .doc(_userId)
        .collection('earnings')
        .orderBy('earnedAt', descending: true)
        .limit(100)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return TeacherEarning(
        id: doc.id,
        teacherId: _userId,
        lessonId: data['lessonId'] as String? ?? '',
        lessonTitle: data['lessonTitle'] as String? ?? '',
        purchasedByUserId: data['purchasedByUserId'] as String? ?? '',
        coinAmount: data['coinAmount'] as int? ?? 0,
        teacherShare: (data['teacherShare'] as num?)?.toDouble() ?? 0.5,
        teacherCoins: data['teacherCoins'] as int? ?? 0,
        usdEquivalent: (data['usdEquivalent'] as num?)?.toDouble() ?? 0.0,
        earnedAt: data['earnedAt'] is Timestamp
            ? (data['earnedAt'] as Timestamp).toDate()
            : DateTime.now(),
        isPaidOut: data['isPaidOut'] as bool? ?? false,
        payoutId: data['payoutId'] as String?,
        paidOutAt: data['paidOutAt'] is Timestamp
            ? (data['paidOutAt'] as Timestamp).toDate()
            : null,
      );
    }).toList();
  }

  @override
  Future<TeacherStats> getTeacherStats() async {
    final doc = await _teachersCollection.doc(_userId).get();
    if (!doc.exists) {
      return const TeacherStats();
    }
    final data = doc.data() as Map<String, dynamic>;
    if (data['stats'] != null) {
      return _teacherStatsFromJson(data['stats'] as Map<String, dynamic>);
    }
    return const TeacherStats();
  }

  // ==================== User Learning Progress ====================

  @override
  Future<UserLearningProgress> getUserLearningProgress(String languageCode) async {
    final doc = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('learning_progress')
        .doc(languageCode)
        .get();

    if (!doc.exists) {
      return UserLearningProgress(
        id: '${_userId}_$languageCode',
        odUserId: _userId,
        languageCode: languageCode,
        languageName: SupportedLanguage.getByCode(languageCode)?.name ?? languageCode,
        startedAt: DateTime.now(),
      );
    }

    final data = doc.data() as Map<String, dynamic>;
    return _userLearningProgressFromJson(data, languageCode);
  }

  UserLearningProgress _userLearningProgressFromJson(Map<String, dynamic> json, String languageCode) {
    return UserLearningProgress(
      id: json['id'] as String? ?? '${_userId}_$languageCode',
      odUserId: _userId,
      languageCode: languageCode,
      languageName: SupportedLanguage.getByCode(languageCode)?.name ?? languageCode,
      currentLevel: LessonLevel.values.firstWhere(
        (e) => e.name == json['currentLevel'],
        orElse: () => LessonLevel.absolute_beginner,
      ),
      totalXp: json['totalXp'] as int? ?? 0,
      lessonsCompleted: json['lessonsCompleted'] as int? ?? 0,
      exercisesCompleted: json['exercisesCompleted'] as int? ?? 0,
      totalMinutesLearned: json['totalMinutesLearned'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      correctAnswers: json['correctAnswers'] as int? ?? 0,
      totalAnswers: json['totalAnswers'] as int? ?? 0,
      startedAt: json['startedAt'] is Timestamp
          ? (json['startedAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastActivityAt: json['lastActivityAt'] is Timestamp
          ? (json['lastActivityAt'] as Timestamp).toDate()
          : null,
      completedLessonIds: (json['completedLessonIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      purchasedLessonIds: (json['purchasedLessonIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      categoryProgress: (json['categoryProgress'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(
              LessonCategory.values.firstWhere(
                (e) => e.name == k,
                orElse: () => LessonCategory.dating_basics,
              ),
              CategoryProgress(
                category: LessonCategory.values.firstWhere(
                  (e) => e.name == k,
                  orElse: () => LessonCategory.dating_basics,
                ),
                lessonsCompleted: (v as Map<String, dynamic>)['lessonsCompleted'] as int? ?? 0,
                totalLessons: v['totalLessons'] as int? ?? 0,
                xpEarned: v['xpEarned'] as int? ?? 0,
                averageScore: (v['averageScore'] as num?)?.toDouble() ?? 0.0,
              ),
            ),
          ) ??
          {},
      weeklyHistory: (json['weeklyHistory'] as List<dynamic>?)?.map((w) {
            final wp = w as Map<String, dynamic>;
            return WeeklyProgress(
              weekNumber: wp['weekNumber'] as int? ?? 1,
              year: wp['year'] as int? ?? DateTime.now().year,
              weekStart: wp['weekStart'] is Timestamp
                  ? (wp['weekStart'] as Timestamp).toDate()
                  : DateTime.now(),
              weekEnd: wp['weekEnd'] is Timestamp
                  ? (wp['weekEnd'] as Timestamp).toDate()
                  : DateTime.now(),
              lessonsCompleted: wp['lessonsCompleted'] as int? ?? 0,
              xpEarned: wp['xpEarned'] as int? ?? 0,
              minutesLearned: wp['minutesLearned'] as int? ?? 0,
              dailyActivities: (wp['dailyActivities'] as List<dynamic>?)?.map(
                    (v) => DailyActivity(
                      date: (v as Map<String, dynamic>)['date'] is Timestamp
                          ? ((v)['date'] as Timestamp).toDate()
                          : DateTime.now(),
                      lessonsCompleted: v['lessonsCompleted'] as int? ?? 0,
                      exercisesCompleted: v['exercisesCompleted'] as int? ?? 0,
                      xpEarned: v['xpEarned'] as int? ?? 0,
                      minutesLearned: v['minutesLearned'] as int? ?? 0,
                    ),
                  ).toList() ??
                  [],
            );
          }).toList() ??
          [],
      milestones: (json['milestones'] as List<dynamic>?)?.map((m) {
            final milestone = m as Map<String, dynamic>;
            return LearningMilestone(
              id: milestone['id'] as String? ?? '',
              type: MilestoneType.values.firstWhere(
                (e) => e.name == milestone['type'],
                orElse: () => MilestoneType.first_lesson,
              ),
              title: milestone['title'] as String? ?? '',
              description: milestone['description'] as String? ?? '',
              achievedAt: milestone['achievedAt'] is Timestamp
                  ? (milestone['achievedAt'] as Timestamp).toDate()
                  : DateTime.now(),
              xpReward: milestone['xpReward'] as int? ?? 0,
              coinReward: milestone['coinReward'] as int? ?? 0,
            );
          }).toList() ??
          [],
    );
  }

  @override
  Future<List<UserLearningProgress>> getAllUserProgress() async {
    final snapshot = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('learning_progress')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return _userLearningProgressFromJson(data, doc.id);
    }).toList();
  }

  @override
  Future<void> setLearningGoal(LearningGoal goal) async {
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('learning_goals')
        .doc(goal.id)
        .set({
      'id': goal.id,
      'type': goal.type.name,
      'targetValue': goal.targetValue,
      'currentValue': goal.currentValue,
      'period': goal.period.name,
      'startDate': Timestamp.fromDate(goal.startDate),
      'endDate': Timestamp.fromDate(goal.endDate),
      'isCompleted': goal.isCompleted,
      'xpReward': goal.xpReward,
      'coinReward': goal.coinReward,
    });
  }

  @override
  Future<List<LearningGoal>> getLearningGoals() async {
    final snapshot = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('learning_goals')
        .where('isCompleted', isEqualTo: false)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return LearningGoal(
        id: doc.id,
        type: LearningGoalType.values.firstWhere(
          (e) => e.name == data['type'],
          orElse: () => LearningGoalType.weekly_lessons,
        ),
        targetValue: data['targetValue'] as int? ?? 0,
        currentValue: data['currentValue'] as int? ?? 0,
        period: GoalPeriod.values.firstWhere(
          (e) => e.name == data['period'],
          orElse: () => GoalPeriod.weekly,
        ),
        startDate: data['startDate'] is Timestamp
            ? (data['startDate'] as Timestamp).toDate()
            : DateTime.now(),
        endDate: data['endDate'] is Timestamp
            ? (data['endDate'] as Timestamp).toDate()
            : DateTime.now(),
        isCompleted: data['isCompleted'] as bool? ?? false,
        xpReward: data['xpReward'] as int? ?? 0,
        coinReward: data['coinReward'] as int? ?? 0,
      );
    }).toList();
  }

  @override
  Future<void> updateGoalProgress(String goalId, int progress) async {
    final goalDoc = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('learning_goals')
        .doc(goalId)
        .get();

    if (!goalDoc.exists) return;

    final data = goalDoc.data()!;
    final targetValue = data['targetValue'] as int? ?? 0;
    final isCompleted = progress >= targetValue;

    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('learning_goals')
        .doc(goalId)
        .update({
      'currentValue': progress,
      'isCompleted': isCompleted,
      if (isCompleted) 'completedAt': Timestamp.now(),
    });
  }

  // ==================== Icebreakers ====================

  CollectionReference get _icebreakersCollection =>
      _firestore.collection('icebreakers');

  @override
  Future<List<Icebreaker>> getIcebreakersForCountry(String countryCode) async {
    try {
      // First try Firestore for custom/admin-added icebreakers
      final snapshot = await _icebreakersCollection
          .where('countryCode', isEqualTo: countryCode.toUpperCase())
          .get();

      if (snapshot.docs.isNotEmpty) {
        // Merge Firestore icebreakers with user usage data
        final usageSnapshot = await _firestore
            .collection('users')
            .doc(_userId)
            .collection('icebreaker_usage')
            .get();
        final usedIds = <String, DateTime>{};
        for (final doc in usageSnapshot.docs) {
          final data = doc.data();
          usedIds[doc.id] = data['usedAt'] is Timestamp
              ? (data['usedAt'] as Timestamp).toDate()
              : DateTime.now();
        }

        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Icebreaker(
            id: doc.id,
            phrase: data['phrase'] as String? ?? '',
            translation: data['translation'] as String? ?? '',
            languageCode: data['languageCode'] as String? ?? '',
            languageName: data['languageName'] as String? ?? '',
            pronunciation: data['pronunciation'] as String?,
            audioUrl: data['audioUrl'] as String?,
            countryCode: data['countryCode'] as String? ?? countryCode,
            countryName: data['countryName'] as String? ?? '',
            culturalContext: data['culturalContext'] as String? ?? '',
            type: IcebreakerType.values.firstWhere(
              (e) => e.name == data['type'],
              orElse: () => IcebreakerType.greeting,
            ),
            xpReward: data['xpReward'] as int? ?? 15,
            isUsed: usedIds.containsKey(doc.id),
            usedAt: usedIds[doc.id],
          );
        }).toList();
      }

      // Fall back to static icebreakers
      final staticIcebreakers = Icebreaker.getIcebreakersForCountry(countryCode);

      // Check usage for static icebreakers too
      final usageSnapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('icebreaker_usage')
          .get();
      final usedIds = <String, DateTime>{};
      for (final doc in usageSnapshot.docs) {
        final data = doc.data();
        usedIds[doc.id] = data['usedAt'] is Timestamp
            ? (data['usedAt'] as Timestamp).toDate()
            : DateTime.now();
      }

      return staticIcebreakers.map((ib) {
        if (usedIds.containsKey(ib.id)) {
          return ib.copyWith(isUsed: true, usedAt: usedIds[ib.id]);
        }
        return ib;
      }).toList();
    } catch (e) {
      // Fall back to static data on error
      return Icebreaker.getIcebreakersForCountry(countryCode);
    }
  }

  @override
  Future<void> markIcebreakerAsUsed(String icebreakerId) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('icebreaker_usage')
          .doc(icebreakerId)
          .set({
        'usedAt': Timestamp.now(),
        'icebreakerId': icebreakerId,
      });

      // Update learning streak when using icebreakers
      await updateLearningStreak();
    } catch (e) {
      throw Exception('Failed to mark icebreaker as used: $e');
    }
  }

  @override
  Future<Icebreaker> getRandomIcebreaker(String matchCountryCode) async {
    try {
      final icebreakers = await getIcebreakersForCountry(matchCountryCode);

      if (icebreakers.isEmpty) {
        throw Exception('No icebreakers available for country: $matchCountryCode');
      }

      // Prefer unused icebreakers
      final unused = icebreakers.where((ib) => !ib.isUsed).toList();
      final pool = unused.isNotEmpty ? unused : icebreakers;

      final random = Random();
      return pool[random.nextInt(pool.length)];
    } catch (e) {
      // Last resort: fall back to static data
      final staticIcebreakers = Icebreaker.getIcebreakersForCountry(matchCountryCode);
      if (staticIcebreakers.isEmpty) {
        throw Exception('No icebreakers available for country: $matchCountryCode');
      }
      return staticIcebreakers[Random().nextInt(staticIcebreakers.length)];
    }
  }

  // ==================== Leaderboard ====================

  CollectionReference get _leaderboardCollection =>
      _firestore.collection('language_leaderboard');

  @override
  Future<LanguageLeaderboard> getLeaderboard({
    LeaderboardType type = LeaderboardType.totalXp,
    LeaderboardPeriod period = LeaderboardPeriod.weekly,
  }) async {
    try {
      // Determine the date filter based on period
      DateTime? periodStart;
      final now = DateTime.now();

      switch (period) {
        case LeaderboardPeriod.weekly:
          periodStart = now.subtract(Duration(days: now.weekday - 1));
          periodStart = DateTime(periodStart.year, periodStart.month, periodStart.day);
          break;
        case LeaderboardPeriod.monthly:
          periodStart = DateTime(now.year, now.month, 1);
          break;
        case LeaderboardPeriod.allTime:
          periodStart = null;
          break;
      }

      // Determine sort field based on leaderboard type
      String sortField;
      switch (type) {
        case LeaderboardType.wordsLearned:
          sortField = 'wordsLearned';
          break;
        case LeaderboardType.languagesMastered:
          sortField = 'languagesCount';
          break;
        case LeaderboardType.quizzes:
          sortField = 'quizzesCompleted';
          break;
        case LeaderboardType.streak:
          sortField = 'currentStreak';
          break;
        case LeaderboardType.totalXp:
          sortField = 'totalXp';
          break;
      }

      // Build the leaderboard document ID for caching
      final leaderboardDocId = '${type.name}_${period.name}';

      // Try to get cached leaderboard first
      final cachedDoc = await _leaderboardCollection.doc(leaderboardDocId).get();

      if (cachedDoc.exists) {
        final cachedData = cachedDoc.data() as Map<String, dynamic>;
        final lastUpdated = cachedData['lastUpdated'] is Timestamp
            ? (cachedData['lastUpdated'] as Timestamp).toDate()
            : DateTime.now();

        // Use cache if less than 5 minutes old
        if (DateTime.now().difference(lastUpdated).inMinutes < 5) {
          final entries = _parseLeaderboardEntries(
            cachedData['entries'] as List<dynamic>? ?? [],
          );
          return LanguageLeaderboard(
            type: type,
            period: period,
            entries: entries,
            lastUpdated: lastUpdated,
            currentUserRank: _findUserRank(entries),
          );
        }
      }

      // Query user progress aggregation
      Query query = _firestore.collection('user_language_stats');

      if (periodStart != null) {
        query = query.where(
          'lastActivityAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(periodStart),
        );
      }

      query = query.orderBy(sortField, descending: true).limit(50);

      final snapshot = await query.get();

      final entries = <LeaderboardEntry>[];
      int rank = 1;

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        entries.add(LeaderboardEntry(
          odUserId: doc.id,
          username: data['username'] as String? ?? 'Anonymous',
          photoUrl: data['photoUrl'] as String?,
          rank: rank,
          wordsLearned: data['wordsLearned'] as int? ?? 0,
          languagesCount: data['languagesCount'] as int? ?? 0,
          quizzesCompleted: data['quizzesCompleted'] as int? ?? 0,
          totalXp: data['totalXp'] as int? ?? 0,
          currentStreak: data['currentStreak'] as int? ?? 0,
          highestProficiency: LanguageProficiency.values.firstWhere(
            (e) => e.name == data['highestProficiency'],
            orElse: () => LanguageProficiency.beginner,
          ),
          isCurrentUser: doc.id == _userId,
          primaryLanguage: data['primaryLanguage'] as String?,
          countryFlag: data['countryFlag'] as String?,
        ));
        rank++;
      }

      // Cache the leaderboard
      await _leaderboardCollection.doc(leaderboardDocId).set({
        'type': type.name,
        'period': period.name,
        'lastUpdated': Timestamp.now(),
        'entries': entries.map((e) => {
          'odUserId': e.odUserId,
          'username': e.username,
          'photoUrl': e.photoUrl,
          'rank': e.rank,
          'wordsLearned': e.wordsLearned,
          'languagesCount': e.languagesCount,
          'quizzesCompleted': e.quizzesCompleted,
          'totalXp': e.totalXp,
          'currentStreak': e.currentStreak,
          'highestProficiency': e.highestProficiency.name,
          'primaryLanguage': e.primaryLanguage,
          'countryFlag': e.countryFlag,
        }).toList(),
      });

      return LanguageLeaderboard(
        type: type,
        period: period,
        entries: entries,
        lastUpdated: DateTime.now(),
        currentUserRank: _findUserRank(entries),
      );
    } catch (e) {
      // Return empty leaderboard on error
      return LanguageLeaderboard(
        type: type,
        period: period,
        entries: const [],
        lastUpdated: DateTime.now(),
      );
    }
  }

  List<LeaderboardEntry> _parseLeaderboardEntries(List<dynamic> entriesData) {
    return entriesData.map((e) {
      final data = e as Map<String, dynamic>;
      return LeaderboardEntry(
        odUserId: data['odUserId'] as String? ?? '',
        username: data['username'] as String? ?? 'Anonymous',
        photoUrl: data['photoUrl'] as String?,
        rank: data['rank'] as int? ?? 0,
        wordsLearned: data['wordsLearned'] as int? ?? 0,
        languagesCount: data['languagesCount'] as int? ?? 0,
        quizzesCompleted: data['quizzesCompleted'] as int? ?? 0,
        totalXp: data['totalXp'] as int? ?? 0,
        currentStreak: data['currentStreak'] as int? ?? 0,
        highestProficiency: LanguageProficiency.values.firstWhere(
          (v) => v.name == data['highestProficiency'],
          orElse: () => LanguageProficiency.beginner,
        ),
        isCurrentUser: data['odUserId'] == _userId,
        primaryLanguage: data['primaryLanguage'] as String?,
        countryFlag: data['countryFlag'] as String?,
      );
    }).toList();
  }

  String? _findUserRank(List<LeaderboardEntry> entries) {
    final userEntry = entries.where((e) => e.isCurrentUser).firstOrNull;
    return userEntry?.rank.toString();
  }

  @override
  Future<LeaderboardEntry> getUserLeaderboardRank() async {
    try {
      // Get user's language stats
      final statsDoc = await _firestore
          .collection('user_language_stats')
          .doc(_userId)
          .get();

      if (!statsDoc.exists) {
        // Return default entry for user with no stats
        return LeaderboardEntry(
          odUserId: _userId,
          username: _auth.currentUser?.displayName ?? 'You',
          photoUrl: _auth.currentUser?.photoURL,
          rank: 0,
          wordsLearned: 0,
          languagesCount: 0,
          quizzesCompleted: 0,
          totalXp: 0,
          isCurrentUser: true,
        );
      }

      final data = statsDoc.data() as Map<String, dynamic>;

      // Calculate rank by counting users with more XP
      final higherRanked = await _firestore
          .collection('user_language_stats')
          .where('totalXp', isGreaterThan: data['totalXp'] ?? 0)
          .count()
          .get();

      final rank = (higherRanked.count ?? 0) + 1;

      return LeaderboardEntry(
        odUserId: _userId,
        username: data['username'] as String? ?? _auth.currentUser?.displayName ?? 'You',
        photoUrl: data['photoUrl'] as String? ?? _auth.currentUser?.photoURL,
        rank: rank,
        wordsLearned: data['wordsLearned'] as int? ?? 0,
        languagesCount: data['languagesCount'] as int? ?? 0,
        quizzesCompleted: data['quizzesCompleted'] as int? ?? 0,
        totalXp: data['totalXp'] as int? ?? 0,
        currentStreak: data['currentStreak'] as int? ?? 0,
        highestProficiency: LanguageProficiency.values.firstWhere(
          (e) => e.name == data['highestProficiency'],
          orElse: () => LanguageProficiency.beginner,
        ),
        isCurrentUser: true,
        primaryLanguage: data['primaryLanguage'] as String?,
        countryFlag: data['countryFlag'] as String?,
      );
    } catch (e) {
      throw Exception('Failed to get user leaderboard rank: $e');
    }
  }

  // ==================== AI Coach Sessions ====================

  CollectionReference get _coachSessionsCollection =>
      _firestore.collection('users').doc(_userId).collection('coach_sessions');

  @override
  Future<AiCoachSession> startCoachSession({
    required String languageCode,
    required CoachScenario scenario,
  }) async {
    try {
      final sessionData = {
        'odUserId': _userId,
        'targetLanguageCode': languageCode,
        'targetLanguageName': SupportedLanguage.getByCode(languageCode)?.name ?? languageCode,
        'scenario': scenario.name,
        'messages': <Map<String, dynamic>>[],
        'coinCost': 10,
        'xpReward': 25,
        'isCompleted': false,
        'startedAt': Timestamp.now(),
        'completedAt': null,
        'score': null,
      };

      final docRef = await _coachSessionsCollection.add(sessionData);

      return AiCoachSession(
        id: docRef.id,
        odUserId: _userId,
        targetLanguageCode: languageCode,
        targetLanguageName: SupportedLanguage.getByCode(languageCode)?.name ?? languageCode,
        scenario: scenario,
        messages: const [],
        coinCost: 10,
        xpReward: 25,
        isCompleted: false,
        startedAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to start coach session: $e');
    }
  }

  @override
  Future<AiCoachSession> saveCoachSession(AiCoachSession session) async {
    try {
      final sessionData = {
        'odUserId': session.odUserId,
        'targetLanguageCode': session.targetLanguageCode,
        'targetLanguageName': session.targetLanguageName,
        'scenario': session.scenario.name,
        'messages': session.messages.map((m) => {
          'id': m.id,
          'content': m.content,
          'translation': m.translation,
          'isUserMessage': m.isUserMessage,
          'timestamp': Timestamp.fromDate(m.timestamp),
          'correction': m.correction,
          'feedback': m.feedback,
          'suggestedResponses': m.suggestedResponses,
        }).toList(),
        'coinCost': session.coinCost,
        'xpReward': session.xpReward,
        'isCompleted': session.isCompleted,
        'startedAt': Timestamp.fromDate(session.startedAt),
        'completedAt': session.completedAt != null
            ? Timestamp.fromDate(session.completedAt!)
            : null,
        'score': session.score != null
            ? {
                'grammarAccuracy': session.score!.grammarAccuracy,
                'vocabularyUsage': session.score!.vocabularyUsage,
                'fluency': session.score!.fluency,
                'overallScore': session.score!.overallScore,
                'strengths': session.score!.strengths,
                'areasToImprove': session.score!.areasToImprove,
              }
            : null,
      };

      await _coachSessionsCollection.doc(session.id).set(
        sessionData,
        SetOptions(merge: true),
      );

      return session;
    } catch (e) {
      throw Exception('Failed to save coach session: $e');
    }
  }

  @override
  Future<AiCoachSession?> getCoachSession(String sessionId) async {
    try {
      final doc = await _coachSessionsCollection.doc(sessionId).get();

      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      return _coachSessionFromJson(data, doc.id);
    } catch (e) {
      throw Exception('Failed to get coach session: $e');
    }
  }

  @override
  Future<void> addCoachMessage(String sessionId, CoachMessage message) async {
    try {
      await _coachSessionsCollection.doc(sessionId).update({
        'messages': FieldValue.arrayUnion([
          {
            'id': message.id,
            'content': message.content,
            'translation': message.translation,
            'isUserMessage': message.isUserMessage,
            'timestamp': Timestamp.fromDate(message.timestamp),
            'correction': message.correction,
            'feedback': message.feedback,
            'suggestedResponses': message.suggestedResponses,
          }
        ]),
      });
    } catch (e) {
      throw Exception('Failed to add coach message: $e');
    }
  }

  @override
  Future<AiCoachSession> endCoachSession(String sessionId) async {
    try {
      final doc = await _coachSessionsCollection.doc(sessionId).get();

      if (!doc.exists) {
        throw Exception('Coach session not found: $sessionId');
      }

      final data = doc.data() as Map<String, dynamic>;
      final session = _coachSessionFromJson(data, doc.id);

      // Calculate a basic score from messages
      final userMessages = session.messages.where((m) => m.isUserMessage).toList();
      final messagesWithCorrections = session.messages
          .where((m) => !m.isUserMessage && m.correction != null)
          .length;

      final totalUserMessages = userMessages.length.clamp(1, 999);
      final grammarAccuracy = totalUserMessages > 0
          ? ((totalUserMessages - messagesWithCorrections) / totalUserMessages * 100)
              .clamp(0.0, 100.0)
          : 80.0;

      final score = CoachSessionScore(
        grammarAccuracy: grammarAccuracy,
        vocabularyUsage: (grammarAccuracy * 0.9).clamp(0.0, 100.0),
        fluency: (grammarAccuracy * 0.85).clamp(0.0, 100.0),
        overallScore: grammarAccuracy,
        strengths: grammarAccuracy >= 70
            ? ['Good conversation flow', 'Consistent practice']
            : ['Willingness to practice'],
        areasToImprove: grammarAccuracy < 80
            ? ['Grammar accuracy', 'Vocabulary variety']
            : ['Advanced expressions'],
      );

      await _coachSessionsCollection.doc(sessionId).update({
        'isCompleted': true,
        'completedAt': Timestamp.now(),
        'score': {
          'grammarAccuracy': score.grammarAccuracy,
          'vocabularyUsage': score.vocabularyUsage,
          'fluency': score.fluency,
          'overallScore': score.overallScore,
          'strengths': score.strengths,
          'areasToImprove': score.areasToImprove,
        },
      });

      // Update learning streak
      await updateLearningStreak();

      return session.copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
        score: score,
      );
    } catch (e) {
      throw Exception('Failed to end coach session: $e');
    }
  }

  @override
  Future<List<AiCoachSession>> getCoachSessionHistory() async {
    try {
      final snapshot = await _coachSessionsCollection
          .orderBy('startedAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _coachSessionFromJson(data, doc.id);
      }).toList();
    } catch (e) {
      // Return empty list on error
      return [];
    }
  }

  AiCoachSession _coachSessionFromJson(Map<String, dynamic> json, String docId) {
    final messagesData = json['messages'] as List<dynamic>? ?? [];
    final messages = messagesData.map((m) {
      final msgData = m as Map<String, dynamic>;
      return CoachMessage(
        id: msgData['id'] as String? ?? '',
        content: msgData['content'] as String? ?? '',
        translation: msgData['translation'] as String?,
        isUserMessage: msgData['isUserMessage'] as bool? ?? false,
        timestamp: msgData['timestamp'] is Timestamp
            ? (msgData['timestamp'] as Timestamp).toDate()
            : DateTime.now(),
        correction: msgData['correction'] as String?,
        feedback: msgData['feedback'] as String?,
        suggestedResponses: (msgData['suggestedResponses'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList(),
      );
    }).toList();

    CoachSessionScore? score;
    if (json['score'] != null) {
      final scoreData = json['score'] as Map<String, dynamic>;
      score = CoachSessionScore(
        grammarAccuracy: (scoreData['grammarAccuracy'] as num?)?.toDouble() ?? 0.0,
        vocabularyUsage: (scoreData['vocabularyUsage'] as num?)?.toDouble() ?? 0.0,
        fluency: (scoreData['fluency'] as num?)?.toDouble() ?? 0.0,
        overallScore: (scoreData['overallScore'] as num?)?.toDouble() ?? 0.0,
        strengths: (scoreData['strengths'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        areasToImprove: (scoreData['areasToImprove'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
      );
    }

    return AiCoachSession(
      id: docId,
      odUserId: json['odUserId'] as String? ?? _userId,
      targetLanguageCode: json['targetLanguageCode'] as String? ?? '',
      targetLanguageName: json['targetLanguageName'] as String? ?? '',
      scenario: CoachScenario.values.firstWhere(
        (e) => e.name == json['scenario'],
        orElse: () => CoachScenario.casualChat,
      ),
      messages: messages,
      coinCost: json['coinCost'] as int? ?? 10,
      xpReward: json['xpReward'] as int? ?? 25,
      isCompleted: json['isCompleted'] as bool? ?? false,
      startedAt: json['startedAt'] is Timestamp
          ? (json['startedAt'] as Timestamp).toDate()
          : DateTime.now(),
      completedAt: json['completedAt'] is Timestamp
          ? (json['completedAt'] as Timestamp).toDate()
          : null,
      score: score,
    );
  }

  // ==================== Language Packs ====================

  @override
  Future<void> purchaseLanguagePack(String packId) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('purchased_packs')
          .doc(packId)
          .set({
        'purchasedAt': Timestamp.now(),
        'packId': packId,
      });
    } catch (e) {
      throw Exception('Failed to purchase language pack: $e');
    }
  }

  @override
  Future<List<LanguagePack>> getPurchasedPacks() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('purchased_packs')
          .get();

      final purchasedIds = snapshot.docs.map((d) => d.id).toSet();
      final purchasedDates = <String, DateTime>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        purchasedDates[doc.id] = data['purchasedAt'] is Timestamp
            ? (data['purchasedAt'] as Timestamp).toDate()
            : DateTime.now();
      }

      // Return matching packs from the available packs catalog
      return LanguagePack.availablePacks
          .where((pack) => purchasedIds.contains(pack.id))
          .map((pack) => LanguagePack(
                id: pack.id,
                name: pack.name,
                description: pack.description,
                languageCode: pack.languageCode,
                languageName: pack.languageName,
                category: pack.category,
                phraseCount: pack.phraseCount,
                coinPrice: pack.coinPrice,
                isPurchased: true,
                purchasedAt: purchasedDates[pack.id],
                iconEmoji: pack.iconEmoji,
                previewPhrases: pack.previewPhrases,
                tier: pack.tier,
              ))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ==================== Challenges ====================

  @override
  Future<void> updateChallengeProgress(String challengeId, int progress) async {
    try {
      final challengeDoc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('challenge_progress')
          .doc(challengeId)
          .get();

      // Find the challenge definition to check target
      final challenge = [
        ...LanguageChallenge.dailyChallenges,
        ...LanguageChallenge.weeklyChallenges,
      ].where((c) => c.id == challengeId).firstOrNull;

      final targetCount = challenge?.targetCount ?? progress;
      final isCompleted = progress >= targetCount;

      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('challenge_progress')
          .doc(challengeId)
          .set({
        'challengeId': challengeId,
        'currentProgress': progress,
        'targetCount': targetCount,
        'isCompleted': isCompleted,
        'lastUpdatedAt': Timestamp.now(),
        if (isCompleted && !(challengeDoc.exists && (challengeDoc.data()?['isCompleted'] as bool? ?? false)))
          'completedAt': Timestamp.now(),
      }, SetOptions(merge: true));

      // Update learning streak on challenge progress
      await updateLearningStreak();
    } catch (e) {
      throw Exception('Failed to update challenge progress: $e');
    }
  }

  @override
  Future<void> claimChallengeReward(String challengeId) async {
    try {
      final challengeDoc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('challenge_progress')
          .doc(challengeId)
          .get();

      if (!challengeDoc.exists) {
        throw Exception('Challenge progress not found');
      }

      final data = challengeDoc.data()!;
      if (!(data['isCompleted'] as bool? ?? false)) {
        throw Exception('Challenge not completed yet');
      }

      if (data['isRewardClaimed'] as bool? ?? false) {
        throw Exception('Reward already claimed');
      }

      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('challenge_progress')
          .doc(challengeId)
          .update({
        'isRewardClaimed': true,
        'rewardClaimedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to claim challenge reward: $e');
    }
  }

  // ==================== Seasonal Events ====================

  @override
  Future<void> updateSeasonalChallengeProgress(
    String eventId,
    String challengeId,
    int progress,
  ) async {
    try {
      final docId = '${eventId}_$challengeId';

      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('seasonal_challenge_progress')
          .doc(docId)
          .set({
        'eventId': eventId,
        'challengeId': challengeId,
        'currentProgress': progress,
        'lastUpdatedAt': Timestamp.now(),
      }, SetOptions(merge: true));

      // Check if the challenge target is met
      final event = SeasonalLanguageEvent.allEvents
          .where((e) => e.id == eventId)
          .firstOrNull;

      if (event != null) {
        final challenge = event.challenges
            .where((c) => c.id == challengeId)
            .firstOrNull;

        if (challenge != null && progress >= challenge.targetCount) {
          await _firestore
              .collection('users')
              .doc(_userId)
              .collection('seasonal_challenge_progress')
              .doc(docId)
              .update({
            'isCompleted': true,
            'completedAt': Timestamp.now(),
          });
        }
      }
    } catch (e) {
      throw Exception('Failed to update seasonal challenge progress: $e');
    }
  }

  @override
  Future<void> claimSeasonalChallengeReward(
    String eventId,
    String challengeId,
  ) async {
    try {
      final docId = '${eventId}_$challengeId';

      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('seasonal_challenge_progress')
          .doc(docId)
          .get();

      if (!doc.exists) {
        throw Exception('Seasonal challenge progress not found');
      }

      final data = doc.data()!;
      if (!(data['isCompleted'] as bool? ?? false)) {
        throw Exception('Seasonal challenge not completed yet');
      }

      if (data['isRewardClaimed'] as bool? ?? false) {
        throw Exception('Seasonal reward already claimed');
      }

      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('seasonal_challenge_progress')
          .doc(docId)
          .update({
        'isRewardClaimed': true,
        'rewardClaimedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to claim seasonal challenge reward: $e');
    }
  }

  // ==================== Video Call Language Tracking ====================

  @override
  Future<void> trackVideoCallLanguageUse(String languageCode, Duration duration) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('video_call_language_usage')
          .add({
        'languageCode': languageCode,
        'durationSeconds': duration.inSeconds,
        'trackedAt': Timestamp.now(),
      });

      // Update language progress with video call practice time
      await _userProgressCollection.doc(languageCode).set({
        'videoCallMinutes': FieldValue.increment(duration.inMinutes),
        'lastPracticeDate': Timestamp.now(),
      }, SetOptions(merge: true));

      // Update learning streak
      await updateLearningStreak();
    } catch (e) {
      throw Exception('Failed to track video call language use: $e');
    }
  }
}
