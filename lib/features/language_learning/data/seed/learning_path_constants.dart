/// Constants and helper utilities for the 12-month learning path seed data.
/// Pricing, XP rewards, level mappings, and shared ID generators.
class LearningPathConstants {
  LearningPathConstants._();

  // ---------------------------------------------------------------------------
  // Level names (matching LessonLevel enum string values)
  // ---------------------------------------------------------------------------
  static const String levelBeginner = 'beginner';
  static const String levelElementary = 'elementary';
  static const String levelPreIntermediate = 'pre_intermediate';
  static const String levelIntermediate = 'intermediate';

  // ---------------------------------------------------------------------------
  // Month-to-level mapping
  // ---------------------------------------------------------------------------
  static String levelForMonth(int month) {
    if (month <= 3) return levelBeginner;
    if (month <= 6) return levelElementary;
    if (month <= 9) return levelPreIntermediate;
    return levelIntermediate;
  }

  // ---------------------------------------------------------------------------
  // Coin pricing: first 3 months free, then escalating
  // ---------------------------------------------------------------------------
  static int coinCostForMonth(int month) {
    if (month <= 3) return 0;
    if (month <= 6) return 50;
    if (month <= 9) return 100;
    return 200;
  }

  // ---------------------------------------------------------------------------
  // XP rewards scale with difficulty
  // ---------------------------------------------------------------------------
  static int xpRewardForMonth(int month) {
    if (month <= 3) return 15;
    if (month <= 6) return 25;
    if (month <= 9) return 35;
    return 50;
  }

  // ---------------------------------------------------------------------------
  // Estimated minutes per lesson by level
  // ---------------------------------------------------------------------------
  static int estimatedMinutesForMonth(int month) {
    if (month <= 3) return 10;
    if (month <= 6) return 12;
    if (month <= 9) return 15;
    return 18;
  }

  // ---------------------------------------------------------------------------
  // ID generators  (deterministic, no randomness)
  // ---------------------------------------------------------------------------
  static String lessonId(int month, int module, int lesson) =>
      'lp_m${month}_mod${module}_les$lesson';

  static String sectionId(int month, int module, int lesson, int section) =>
      'lp_m${month}_mod${module}_les${lesson}_sec$section';

  static String contentId(
          int month, int module, int lesson, int section, int item) =>
      'lp_m${month}_mod${module}_les${lesson}_sec${section}_c$item';

  static String exerciseId(
          int month, int module, int lesson, int section, int item) =>
      'lp_m${month}_mod${module}_les${lesson}_sec${section}_ex$item';

  static String flashcardId(int month, int index) =>
      'lp_fc_m${month}_$index';

  static String quizId(int month, [int index = 1]) =>
      'lp_quiz_m${month}_$index';

  static String quizQuestionId(int month, int quizIndex, int questionIndex) =>
      'lp_quiz_m${month}_${quizIndex}_q$questionIndex';

  static String dailyHintId(int month, int day) =>
      'lp_hint_m${month}_d$day';

  // ---------------------------------------------------------------------------
  // Category string constants (matching LessonCategory enum names)
  // ---------------------------------------------------------------------------
  static const String catDatingBasics = 'dating_basics';
  static const String catFirstImpressions = 'first_impressions';
  static const String catComplimentsFlirting = 'compliments_flirting';
  static const String catAskingOut = 'asking_out';
  static const String catRestaurantDates = 'restaurant_dates';
  static const String catCafeConversations = 'cafe_conversations';
  static const String catMoviesEntertainment = 'movies_entertainment';
  static const String catTravelAdventures = 'travel_adventures';
  static const String catCulturalExchange = 'cultural_exchange';
  static const String catVideoCall = 'video_calls';
  static const String catExpressingFeelings = 'expressing_feelings';
  static const String catRelationshipTalk = 'relationship_talk';
  static const String catMeetingFriends = 'meeting_friends';
  static const String catHobbiesInterests = 'hobbies_interests';
  static const String catFoodCooking = 'food_cooking';
  static const String catMusicArts = 'music_arts';
  static const String catSportsFitness = 'sports_fitness';
  static const String catWeekendPlans = 'weekend_plans';
  static const String catHolidaysCelebrations = 'holidays_celebrations';
  static const String catFamilyTalk = 'family_talk';
  static const String catDailyLife = 'daily_life';
  static const String catFunIdioms = 'fun_idioms';
  static const String catHumorJokes = 'humor_jokes';
  static const String catDeepConversations = 'deep_conversations';

  // ---------------------------------------------------------------------------
  // Section type string constants (matching LessonSectionType enum names)
  // ---------------------------------------------------------------------------
  static const String secVocabulary = 'vocabulary';
  static const String secDialogue = 'dialogue';
  static const String secGrammarTip = 'grammar_tip';
  static const String secCulturalNote = 'cultural_note';
  static const String secPronunciation = 'pronunciation';
  static const String secPractice = 'practice';
  static const String secConversationSim = 'conversation_simulation';
  static const String secQuiz = 'quiz';
  static const String secFunFact = 'fun_fact';

  // ---------------------------------------------------------------------------
  // Exercise type string constants (matching ExerciseType enum names)
  // ---------------------------------------------------------------------------
  static const String exMultipleChoice = 'multiple_choice';
  static const String exFillInBlank = 'fill_in_blank';
  static const String exTranslation = 'translation';
  static const String exListening = 'listening';
  static const String exSpeaking = 'speaking';
  static const String exMatching = 'matching';
  static const String exReorderWords = 'reorder_words';
  static const String exTrueFalse = 'true_false';
  static const String exConversationChoice = 'conversation_choice';
  static const String exFreeResponse = 'free_response';

  // ---------------------------------------------------------------------------
  // Content type string constants (matching LessonContentType enum names)
  // ---------------------------------------------------------------------------
  static const String ctText = 'text';
  static const String ctPhrase = 'phrase';
  static const String ctDialogueLine = 'dialogue_line';
  static const String ctGrammarExplanation = 'grammar_explanation';
  static const String ctExample = 'example';
  static const String ctTip = 'tip';
  static const String ctFunFact = 'fun_fact';

  // ---------------------------------------------------------------------------
  // Helper: build a lesson map ready for Firestore
  // ---------------------------------------------------------------------------
  static Map<String, dynamic> buildLesson({
    required String id,
    required String title,
    required String description,
    required String level,
    required String category,
    required int lessonNumber,
    required int weekNumber,
    required int dayNumber,
    required int month,
    required List<String> objectives,
    required List<Map<String, dynamic>> sections,
    List<String> prerequisites = const [],
    int? coinPrice,
    int? xpReward,
    int? estimatedMinutes,
  }) {
    return {
      'id': id,
      'languageCode': '{LANG}',
      'languageName': '{LANG_NAME}',
      'title': title,
      'description': description,
      'level': level,
      'category': category,
      'lessonNumber': lessonNumber,
      'weekNumber': weekNumber,
      'dayNumber': dayNumber,
      'coinPrice': coinPrice ?? coinCostForMonth(month),
      'isFree': (coinPrice ?? coinCostForMonth(month)) == 0,
      'isPremium': month >= 10,
      'estimatedMinutes': estimatedMinutes ?? estimatedMinutesForMonth(month),
      'xpReward': xpReward ?? xpRewardForMonth(month),
      'bonusCoins': dayNumber == 7 ? 10 : 0,
      'sections': sections,
      'objectives': objectives,
      'prerequisites': prerequisites,
      'isPublished': true,
      'averageRating': 0.0,
      'completionCount': 0,
    };
  }

  // ---------------------------------------------------------------------------
  // Helper: build a section map
  // ---------------------------------------------------------------------------
  static Map<String, dynamic> buildSection({
    required String id,
    required String title,
    required String type,
    required int orderIndex,
    String? introduction,
    required List<Map<String, dynamic>> contents,
    required List<Map<String, dynamic>> exercises,
    int xpReward = 10,
  }) {
    return {
      'id': id,
      'title': title,
      'type': type,
      'orderIndex': orderIndex,
      'introduction': introduction,
      'contents': contents,
      'exercises': exercises,
      'xpReward': xpReward,
    };
  }

  // ---------------------------------------------------------------------------
  // Helper: build a content item map
  // ---------------------------------------------------------------------------
  static Map<String, dynamic> buildContent({
    required String id,
    required String type,
    String? text,
    String? translation,
    String? pronunciation,
  }) {
    return {
      'id': id,
      'type': type,
      'text': text,
      'translation': translation,
      'pronunciation': pronunciation,
    };
  }

  // ---------------------------------------------------------------------------
  // Helper: build an exercise map
  // ---------------------------------------------------------------------------
  static Map<String, dynamic> buildExercise({
    required String id,
    required String type,
    required String question,
    String? questionTranslation,
    List<String> options = const [],
    required String correctAnswer,
    List<String>? acceptableAnswers,
    String? explanation,
    String? hint,
    int xpReward = 5,
    required int orderIndex,
  }) {
    return {
      'id': id,
      'type': type,
      'question': question,
      'questionTranslation': questionTranslation,
      'options': options,
      'correctAnswer': correctAnswer,
      'acceptableAnswers': acceptableAnswers,
      'explanation': explanation,
      'hint': hint,
      'xpReward': xpReward,
      'orderIndex': orderIndex,
    };
  }

  // ---------------------------------------------------------------------------
  // Helper: build a flashcard map
  // ---------------------------------------------------------------------------
  static Map<String, dynamic> buildFlashcard({
    required String id,
    required String front,
    required String back,
    required String exampleSentence,
    String? pronunciation,
    required String category,
    required String difficulty,
    int requiredLevel = 1,
  }) {
    return {
      'id': id,
      'phrase': {
        'id': '${id}_phrase',
        'phrase': front,
        'translation': back,
        'languageCode': '{LANG}',
        'languageName': '{LANG_NAME}',
        'pronunciation': pronunciation,
        'category': category,
        'difficulty': difficulty,
        'requiredLevel': requiredLevel,
      },
      'status': 'newCard',
      'reviewCount': 0,
      'correctCount': 0,
      'incorrectCount': 0,
      'streak': 0,
      'easeFactor': 2.5,
    };
  }

  // ---------------------------------------------------------------------------
  // Helper: build a quiz question map
  // ---------------------------------------------------------------------------
  static Map<String, dynamic> buildQuizQuestion({
    required String id,
    required String question,
    required List<String> options,
    required int correctOptionIndex,
    String? explanation,
  }) {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correctOptionIndex': correctOptionIndex,
      'explanation': explanation,
    };
  }

  // ---------------------------------------------------------------------------
  // Helper: build a cultural quiz map
  // ---------------------------------------------------------------------------
  static Map<String, dynamic> buildCulturalQuiz({
    required String id,
    required String title,
    required String description,
    required String difficulty,
    required List<Map<String, dynamic>> questions,
    int timeLimit = 300,
    int minXpReward = 20,
    int maxXpReward = 100,
    int perfectScoreCoins = 50,
  }) {
    return {
      'id': id,
      'title': title,
      'description': description,
      'languageCode': '{LANG}',
      'countryCode': '{COUNTRY}',
      'countryName': '{COUNTRY_NAME}',
      'questions': questions,
      'timeLimit': timeLimit,
      'minXpReward': minXpReward,
      'maxXpReward': maxXpReward,
      'perfectScoreCoins': perfectScoreCoins,
      'difficulty': difficulty,
    };
  }
}
