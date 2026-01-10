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
}
