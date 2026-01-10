import '../../domain/entities/lesson.dart';
import '../../domain/entities/supported_language.dart';

/// Comprehensive lesson seed data generator
/// Creates 1 year of daily lessons (365 lessons per language)
/// Organized into 52 weeks with practical, fun content
class LessonSeedData {
  /// Generate lessons for a specific language
  static List<Lesson> generateLessonsForLanguage(String languageCode) {
    final language = SupportedLanguage.getByCode(languageCode);
    if (language == null) return [];

    final lessons = <Lesson>[];

    // Generate 52 weeks of content
    for (int week = 1; week <= 52; week++) {
      final weekLessons = _generateWeekLessons(
        languageCode: languageCode,
        languageName: language.name,
        weekNumber: week,
      );
      lessons.addAll(weekLessons);
    }

    return lessons;
  }

  /// Generate 7 lessons for a specific week
  static List<Lesson> _generateWeekLessons({
    required String languageCode,
    required String languageName,
    required int weekNumber,
  }) {
    final weekPlan = _getWeekPlan(weekNumber);
    final lessons = <Lesson>[];

    for (int day = 1; day <= 7; day++) {
      final dayPlan = weekPlan[day - 1];
      final lessonNumber = (weekNumber - 1) * 7 + day;

      lessons.add(Lesson(
        id: '${languageCode}_lesson_$lessonNumber',
        languageCode: languageCode,
        languageName: languageName,
        title: dayPlan['title']!,
        description: dayPlan['description']!,
        level: _getLevelForWeek(weekNumber),
        category: dayPlan['category'] as LessonCategory,
        lessonNumber: lessonNumber,
        weekNumber: weekNumber,
        dayNumber: day,
        coinPrice: _getCoinPrice(weekNumber, day),
        isFree: lessonNumber <= 7, // First week free
        isPremium: weekNumber > 40,
        estimatedMinutes: _getEstimatedMinutes(dayPlan['category'] as LessonCategory),
        xpReward: _getXpReward(weekNumber),
        bonusCoins: day == 7 ? 10 : 0, // Bonus for completing week
        sections: _generateSections(
          languageCode: languageCode,
          category: dayPlan['category'] as LessonCategory,
          lessonNumber: lessonNumber,
          weekNumber: weekNumber,
        ),
        objectives: List<String>.from(dayPlan['objectives'] as List),
        prerequisites: lessonNumber > 1
            ? ['${languageCode}_lesson_${lessonNumber - 1}']
            : [],
        createdAt: DateTime.now(),
        isPublished: true,
      ));
    }

    return lessons;
  }

  /// Get the weekly curriculum plan
  static List<Map<String, dynamic>> _getWeekPlan(int weekNumber) {
    // Rotate through different themes based on week
    final themeIndex = (weekNumber - 1) % _weeklyThemes.length;
    return _weeklyThemes[themeIndex];
  }

  /// Determine lesson level based on week number
  static LessonLevel _getLevelForWeek(int weekNumber) {
    if (weekNumber <= 4) return LessonLevel.absolute_beginner;
    if (weekNumber <= 10) return LessonLevel.beginner;
    if (weekNumber <= 18) return LessonLevel.elementary;
    if (weekNumber <= 26) return LessonLevel.pre_intermediate;
    if (weekNumber <= 36) return LessonLevel.intermediate;
    if (weekNumber <= 44) return LessonLevel.upper_intermediate;
    if (weekNumber <= 50) return LessonLevel.advanced;
    return LessonLevel.fluent;
  }

  /// Get coin price based on level progression
  static int _getCoinPrice(int weekNumber, int dayNumber) {
    if (weekNumber <= 1) return 0; // Week 1 free
    if (weekNumber <= 4) return 10;
    if (weekNumber <= 10) return 15;
    if (weekNumber <= 18) return 20;
    if (weekNumber <= 26) return 25;
    if (weekNumber <= 36) return 30;
    if (weekNumber <= 44) return 40;
    return 50;
  }

  /// Get XP reward based on level
  static int _getXpReward(int weekNumber) {
    final level = _getLevelForWeek(weekNumber);
    switch (level) {
      case LessonLevel.absolute_beginner:
        return 15;
      case LessonLevel.beginner:
        return 20;
      case LessonLevel.elementary:
        return 25;
      case LessonLevel.pre_intermediate:
        return 30;
      case LessonLevel.intermediate:
        return 40;
      case LessonLevel.upper_intermediate:
        return 50;
      case LessonLevel.advanced:
        return 60;
      case LessonLevel.fluent:
        return 75;
    }
  }

  /// Get estimated minutes based on category complexity
  static int _getEstimatedMinutes(LessonCategory category) {
    switch (category) {
      case LessonCategory.dating_basics:
      case LessonCategory.daily_life:
        return 10;
      case LessonCategory.first_impressions:
      case LessonCategory.cafe_conversations:
        return 12;
      case LessonCategory.compliments_flirting:
      case LessonCategory.asking_out:
        return 15;
      case LessonCategory.restaurant_dates:
      case LessonCategory.movies_entertainment:
        return 15;
      case LessonCategory.travel_adventures:
      case LessonCategory.cultural_exchange:
        return 18;
      case LessonCategory.video_calls:
      case LessonCategory.expressing_feelings:
        return 15;
      case LessonCategory.relationship_talk:
      case LessonCategory.deep_conversations:
        return 20;
      default:
        return 12;
    }
  }

  /// Generate sections for a lesson
  static List<LessonSection> _generateSections({
    required String languageCode,
    required LessonCategory category,
    required int lessonNumber,
    required int weekNumber,
  }) {
    final sectionTemplates = _getSectionTemplates(category);
    final sections = <LessonSection>[];

    for (int i = 0; i < sectionTemplates.length; i++) {
      final template = sectionTemplates[i];
      sections.add(LessonSection(
        id: '${languageCode}_lesson_${lessonNumber}_section_$i',
        title: template['title'] as String,
        type: template['type'] as LessonSectionType,
        orderIndex: i,
        introduction: template['intro'] as String?,
        contents: _generateContents(
          languageCode: languageCode,
          sectionType: template['type'] as LessonSectionType,
          lessonNumber: lessonNumber,
          sectionIndex: i,
        ),
        exercises: _generateExercises(
          languageCode: languageCode,
          sectionType: template['type'] as LessonSectionType,
          lessonNumber: lessonNumber,
          sectionIndex: i,
        ),
        xpReward: template['xp'] as int? ?? 10,
      ));
    }

    return sections;
  }

  /// Get section templates based on category
  static List<Map<String, dynamic>> _getSectionTemplates(LessonCategory category) {
    return [
      {
        'title': 'Key Vocabulary',
        'type': LessonSectionType.vocabulary,
        'intro': 'Learn these essential words and phrases',
        'xp': 10,
      },
      {
        'title': 'Real Conversation',
        'type': LessonSectionType.dialogue,
        'intro': 'See how natives use these in conversation',
        'xp': 15,
      },
      {
        'title': 'Quick Grammar Tip',
        'type': LessonSectionType.grammar_tip,
        'intro': 'A simple rule to remember',
        'xp': 5,
      },
      {
        'title': 'Practice Time',
        'type': LessonSectionType.practice,
        'intro': 'Test what you learned',
        'xp': 20,
      },
      {
        'title': 'Fun Fact',
        'type': LessonSectionType.fun_fact,
        'intro': 'Something cool about the culture',
        'xp': 5,
      },
    ];
  }

  /// Generate content items for a section
  static List<LessonContent> _generateContents({
    required String languageCode,
    required LessonSectionType sectionType,
    required int lessonNumber,
    required int sectionIndex,
  }) {
    // This would be filled with actual translations
    // For now, return template structure
    return [
      LessonContent(
        id: '${languageCode}_${lessonNumber}_${sectionIndex}_content_0',
        type: LessonContentType.phrase,
        text: '[Phrase in $languageCode]',
        translation: '[English translation]',
        pronunciation: '[Pronunciation guide]',
      ),
    ];
  }

  /// Generate exercises for a section
  static List<LessonExercise> _generateExercises({
    required String languageCode,
    required LessonSectionType sectionType,
    required int lessonNumber,
    required int sectionIndex,
  }) {
    final exerciseTypes = _getExerciseTypesForSection(sectionType);
    final exercises = <LessonExercise>[];

    for (int i = 0; i < exerciseTypes.length; i++) {
      exercises.add(LessonExercise(
        id: '${languageCode}_${lessonNumber}_${sectionIndex}_ex_$i',
        type: exerciseTypes[i],
        question: '[Question placeholder]',
        options: ['Option A', 'Option B', 'Option C', 'Option D'],
        correctAnswer: 'Option A',
        explanation: '[Explanation]',
        hint: '[Hint]',
        xpReward: 5,
        orderIndex: i,
      ));
    }

    return exercises;
  }

  /// Get appropriate exercise types for section type
  static List<ExerciseType> _getExerciseTypesForSection(LessonSectionType type) {
    switch (type) {
      case LessonSectionType.vocabulary:
        return [
          ExerciseType.multiple_choice,
          ExerciseType.matching,
          ExerciseType.fill_in_blank,
        ];
      case LessonSectionType.dialogue:
        return [
          ExerciseType.conversation_choice,
          ExerciseType.reorder_words,
        ];
      case LessonSectionType.grammar_tip:
        return [
          ExerciseType.fill_in_blank,
          ExerciseType.true_false,
        ];
      case LessonSectionType.practice:
        return [
          ExerciseType.translation,
          ExerciseType.multiple_choice,
          ExerciseType.fill_in_blank,
        ];
      default:
        return [ExerciseType.multiple_choice];
    }
  }

  /// Weekly themes - rotates through the year
  /// Each theme has 7 daily lessons
  static final List<List<Map<String, dynamic>>> _weeklyThemes = [
    // Week Theme 1: Getting Started with Dating
    [
      {
        'title': 'Hello Beautiful! - Basic Greetings',
        'description': 'Learn charming ways to say hello and make a great first impression',
        'category': LessonCategory.first_impressions,
        'objectives': ['Greet someone warmly', 'Introduce yourself confidently', 'Ask how someone is doing'],
      },
      {
        'title': 'What\'s Your Name? - Introductions',
        'description': 'Master the art of introducing yourself in a dating context',
        'category': LessonCategory.dating_basics,
        'objectives': ['Share your name', 'Ask for someone\'s name', 'Start a friendly conversation'],
      },
      {
        'title': 'You Look Amazing! - Compliments',
        'description': 'Learn sincere compliments that make people smile',
        'category': LessonCategory.compliments_flirting,
        'objectives': ['Compliment appearance', 'Praise personality', 'Respond to compliments'],
      },
      {
        'title': 'Tell Me About Yourself',
        'description': 'Share interesting things about yourself and ask great questions',
        'category': LessonCategory.dating_basics,
        'objectives': ['Describe your interests', 'Ask engaging questions', 'Keep conversation flowing'],
      },
      {
        'title': 'I Really Like... - Expressing Interests',
        'description': 'Talk about your hobbies and find common ground',
        'category': LessonCategory.hobbies_interests,
        'objectives': ['Discuss hobbies', 'Find shared interests', 'Show enthusiasm'],
      },
      {
        'title': 'Want to Grab Coffee?',
        'description': 'Learn to suggest a casual first date confidently',
        'category': LessonCategory.asking_out,
        'objectives': ['Suggest meeting up', 'Propose date ideas', 'Set a time and place'],
      },
      {
        'title': 'Weekend Review & Practice',
        'description': 'Review everything you learned this week with fun exercises',
        'category': LessonCategory.daily_life,
        'objectives': ['Practice all phrases', 'Build confidence', 'Prepare for next week'],
      },
    ],
    // Week Theme 2: Coffee Date Conversations
    [
      {
        'title': 'At the Cafe - Ordering Drinks',
        'description': 'Navigate the menu and order like a local',
        'category': LessonCategory.cafe_conversations,
        'objectives': ['Order coffee and tea', 'Ask for recommendations', 'Pay and tip politely'],
      },
      {
        'title': 'Do You Come Here Often?',
        'description': 'Classic conversation starters that actually work',
        'category': LessonCategory.cafe_conversations,
        'objectives': ['Start small talk', 'Show interest', 'Avoid awkward silences'],
      },
      {
        'title': 'What Do You Do? - Jobs & Dreams',
        'description': 'Talk about work and aspirations in an interesting way',
        'category': LessonCategory.daily_life,
        'objectives': ['Describe your job', 'Share career dreams', 'Ask about their work'],
      },
      {
        'title': 'This Is Delicious! - Food Talk',
        'description': 'Express opinions about food and discover taste preferences',
        'category': LessonCategory.food_cooking,
        'objectives': ['Describe flavors', 'Share food preferences', 'Suggest dishes'],
      },
      {
        'title': 'I Love This Song! - Music Chat',
        'description': 'Bond over music and discover shared tastes',
        'category': LessonCategory.music_arts,
        'objectives': ['Discuss music genres', 'Share favorites', 'Suggest songs'],
      },
      {
        'title': 'Let\'s Do This Again!',
        'description': 'End dates on a high note and plan the next one',
        'category': LessonCategory.asking_out,
        'objectives': ['Express enjoyment', 'Suggest next date', 'Exchange contact info'],
      },
      {
        'title': 'Coffee Date Mastery',
        'description': 'Put it all together for the perfect cafe date',
        'category': LessonCategory.cafe_conversations,
        'objectives': ['Practice full conversations', 'Handle surprises', 'Build confidence'],
      },
    ],
    // Week Theme 3: Flirting Like a Pro
    [
      {
        'title': 'You Have Beautiful Eyes',
        'description': 'Romantic compliments that feel genuine',
        'category': LessonCategory.compliments_flirting,
        'objectives': ['Compliment physical features', 'Be sincere', 'Read reactions'],
      },
      {
        'title': 'You Make Me Laugh!',
        'description': 'Appreciate someone\'s personality and humor',
        'category': LessonCategory.compliments_flirting,
        'objectives': ['Praise personality', 'Show appreciation', 'Build connection'],
      },
      {
        'title': 'Playful Teasing 101',
        'description': 'Light-hearted teasing that creates chemistry',
        'category': LessonCategory.humor_jokes,
        'objectives': ['Tease playfully', 'Know limits', 'Keep it fun'],
      },
      {
        'title': 'Body Language Phrases',
        'description': 'Words that match flirty body language',
        'category': LessonCategory.compliments_flirting,
        'objectives': ['Express attraction', 'Create tension', 'Read signals'],
      },
      {
        'title': 'Fun Pickup Lines That Work',
        'description': 'Cheesy but effective ice-breakers',
        'category': LessonCategory.humor_jokes,
        'objectives': ['Use pickup lines', 'Make them laugh', 'Break the ice'],
      },
      {
        'title': 'I Can\'t Stop Thinking About You',
        'description': 'Express attraction and interest romantically',
        'category': LessonCategory.expressing_feelings,
        'objectives': ['Share feelings', 'Be vulnerable', 'Create intimacy'],
      },
      {
        'title': 'Flirting Practice Session',
        'description': 'Practice your new flirting skills with confidence',
        'category': LessonCategory.compliments_flirting,
        'objectives': ['Combine techniques', 'Build natural flow', 'Have fun'],
      },
    ],
    // Week Theme 4: Restaurant Dates
    [
      {
        'title': 'Making Reservations',
        'description': 'Book a table like a pro',
        'category': LessonCategory.restaurant_dates,
        'objectives': ['Call to reserve', 'Specify requests', 'Confirm details'],
      },
      {
        'title': 'Reading the Menu',
        'description': 'Navigate any menu with confidence',
        'category': LessonCategory.restaurant_dates,
        'objectives': ['Understand menu items', 'Ask about dishes', 'Handle allergies'],
      },
      {
        'title': 'What Would You Recommend?',
        'description': 'Get great recommendations from servers',
        'category': LessonCategory.restaurant_dates,
        'objectives': ['Ask for suggestions', 'Describe preferences', 'Make decisions'],
      },
      {
        'title': 'Wine and Drinks Selection',
        'description': 'Order drinks like a sommelier',
        'category': LessonCategory.restaurant_dates,
        'objectives': ['Discuss wine', 'Order cocktails', 'Pair with food'],
      },
      {
        'title': 'This Is Amazing! - Food Reactions',
        'description': 'Express your culinary delight',
        'category': LessonCategory.food_cooking,
        'objectives': ['Praise dishes', 'Share bites', 'Discuss flavors'],
      },
      {
        'title': 'Shall We Split Dessert?',
        'description': 'The sweet end to a perfect meal',
        'category': LessonCategory.restaurant_dates,
        'objectives': ['Order dessert', 'Share romantically', 'End on high note'],
      },
      {
        'title': 'Getting the Check',
        'description': 'Handle payment smoothly and gracefully',
        'category': LessonCategory.restaurant_dates,
        'objectives': ['Request bill', 'Discuss splitting', 'Tip appropriately'],
      },
    ],
    // Week Theme 5: Movie & Entertainment Dates
    [
      {
        'title': 'What Movie Should We Watch?',
        'description': 'Discuss film preferences and pick together',
        'category': LessonCategory.movies_entertainment,
        'objectives': ['Suggest movies', 'Describe genres', 'Compromise choices'],
      },
      {
        'title': 'That Was So Good!',
        'description': 'Discuss movies and shows after watching',
        'category': LessonCategory.movies_entertainment,
        'objectives': ['Share opinions', 'Discuss plots', 'Recommend more'],
      },
      {
        'title': 'Concert Night!',
        'description': 'Talk about live music experiences',
        'category': LessonCategory.music_arts,
        'objectives': ['Discuss concerts', 'Share excitement', 'Plan outings'],
      },
      {
        'title': 'Game Night Vocabulary',
        'description': 'Fun phrases for playing games together',
        'category': LessonCategory.hobbies_interests,
        'objectives': ['Explain rules', 'Celebrate wins', 'Be a good sport'],
      },
      {
        'title': 'Did You See That Goal?!',
        'description': 'Sports talk for date nights',
        'category': LessonCategory.sports_fitness,
        'objectives': ['Discuss sports', 'Cheer together', 'Share passion'],
      },
      {
        'title': 'Netflix and Chat',
        'description': 'Cozy night in conversation',
        'category': LessonCategory.movies_entertainment,
        'objectives': ['Suggest shows', 'Create comfort', 'Enjoy together'],
      },
      {
        'title': 'Entertainment Date Master',
        'description': 'Perfect your entertainment date vocabulary',
        'category': LessonCategory.movies_entertainment,
        'objectives': ['Plan outings', 'Discuss preferences', 'Have fun'],
      },
    ],
    // Week Theme 6: Travel & Adventure
    [
      {
        'title': 'Where Should We Go?',
        'description': 'Plan trips and adventures together',
        'category': LessonCategory.travel_adventures,
        'objectives': ['Suggest destinations', 'Discuss preferences', 'Dream big'],
      },
      {
        'title': 'At the Airport',
        'description': 'Navigate airports together',
        'category': LessonCategory.travel_adventures,
        'objectives': ['Check in', 'Find gates', 'Handle delays'],
      },
      {
        'title': 'This Hotel Is Beautiful!',
        'description': 'Hotel and accommodation vocabulary',
        'category': LessonCategory.travel_adventures,
        'objectives': ['Book rooms', 'Request amenities', 'Solve problems'],
      },
      {
        'title': 'Sightseeing Together',
        'description': 'Explore new places as a couple',
        'category': LessonCategory.travel_adventures,
        'objectives': ['Plan activities', 'Take photos', 'Share experiences'],
      },
      {
        'title': 'This View Is Incredible!',
        'description': 'Express wonder at beautiful sights',
        'category': LessonCategory.travel_adventures,
        'objectives': ['Describe scenery', 'Share emotions', 'Create memories'],
      },
      {
        'title': 'Let\'s Try Local Food!',
        'description': 'Culinary adventures while traveling',
        'category': LessonCategory.food_cooking,
        'objectives': ['Try new foods', 'Ask about dishes', 'Share experiences'],
      },
      {
        'title': 'Best Trip Ever!',
        'description': 'Recap and share travel memories',
        'category': LessonCategory.travel_adventures,
        'objectives': ['Share highlights', 'Plan next trip', 'Reminisce'],
      },
    ],
    // Week Theme 7: Video Calls & Long Distance
    [
      {
        'title': 'Can You Hear Me?',
        'description': 'Handle video call basics',
        'category': LessonCategory.video_calls,
        'objectives': ['Start calls', 'Fix tech issues', 'Basic phrases'],
      },
      {
        'title': 'You Look Great Today!',
        'description': 'Compliments over video',
        'category': LessonCategory.video_calls,
        'objectives': ['Video compliments', 'Notice details', 'Create intimacy'],
      },
      {
        'title': 'Show Me Around!',
        'description': 'Virtual tours and sharing spaces',
        'category': LessonCategory.video_calls,
        'objectives': ['Give tours', 'Describe surroundings', 'Share life'],
      },
      {
        'title': 'I Miss You So Much',
        'description': 'Express longing in long-distance',
        'category': LessonCategory.expressing_feelings,
        'objectives': ['Express missing', 'Stay connected', 'Plan visits'],
      },
      {
        'title': 'Virtual Date Night',
        'description': 'Creative long-distance date ideas',
        'category': LessonCategory.video_calls,
        'objectives': ['Plan activities', 'Eat together', 'Watch movies'],
      },
      {
        'title': 'Can\'t Wait to See You',
        'description': 'Plan your next meeting',
        'category': LessonCategory.video_calls,
        'objectives': ['Plan trips', 'Count down', 'Build excitement'],
      },
      {
        'title': 'Staying Connected',
        'description': 'Keep the romance alive remotely',
        'category': LessonCategory.video_calls,
        'objectives': ['Daily check-ins', 'Send surprises', 'Stay close'],
      },
    ],
    // Week Theme 8: Expressing Feelings
    [
      {
        'title': 'I Really Like You',
        'description': 'Express your growing feelings',
        'category': LessonCategory.expressing_feelings,
        'objectives': ['Share attraction', 'Be vulnerable', 'Read responses'],
      },
      {
        'title': 'You Mean So Much to Me',
        'description': 'Deepen emotional expression',
        'category': LessonCategory.expressing_feelings,
        'objectives': ['Express importance', 'Show gratitude', 'Build bonds'],
      },
      {
        'title': 'I\'m Falling for You',
        'description': 'Romantic declarations',
        'category': LessonCategory.expressing_feelings,
        'objectives': ['Confess feelings', 'Create moments', 'Be sincere'],
      },
      {
        'title': 'You Make Me Happy',
        'description': 'Share how they affect your life',
        'category': LessonCategory.expressing_feelings,
        'objectives': ['Express joy', 'Appreciate partner', 'Share impact'],
      },
      {
        'title': 'I\'m Sorry - Making Up',
        'description': 'Apologize and resolve conflicts',
        'category': LessonCategory.relationship_talk,
        'objectives': ['Say sorry', 'Explain feelings', 'Reconcile'],
      },
      {
        'title': 'Let\'s Talk About Us',
        'description': 'Relationship discussions',
        'category': LessonCategory.relationship_talk,
        'objectives': ['Define relationship', 'Share expectations', 'Plan future'],
      },
      {
        'title': 'I Love You',
        'description': 'The three magic words',
        'category': LessonCategory.expressing_feelings,
        'objectives': ['Say I love you', 'Receive love', 'Express depth'],
      },
    ],
  ];

  /// Get all content for a specific language (full 1-year curriculum)
  /// This contains actual phrase translations
  static Map<String, Map<String, String>> getLanguageContent(String languageCode) {
    switch (languageCode) {
      case 'es':
        return _spanishContent;
      case 'fr':
        return _frenchContent;
      case 'de':
        return _germanContent;
      case 'it':
        return _italianContent;
      case 'pt':
      case 'pt-BR':
        return _portugueseContent;
      case 'ja':
        return _japaneseContent;
      case 'ko':
        return _koreanContent;
      case 'zh':
      case 'zh-TW':
        return _chineseContent;
      default:
        return _defaultContent;
    }
  }

  // Spanish Content
  static const Map<String, Map<String, String>> _spanishContent = {
    'greetings': {
      'hello_beautiful': '¡Hola guapa/guapo!',
      'how_are_you': '¿Cómo estás?',
      'nice_to_meet_you': 'Encantado/a de conocerte',
      'good_morning': '¡Buenos días, cariño!',
      'good_night': '¡Buenas noches, mi amor!',
    },
    'compliments': {
      'beautiful_eyes': 'Tienes unos ojos preciosos',
      'lovely_smile': 'Me encanta tu sonrisa',
      'you_look_amazing': 'Estás increíble',
      'so_funny': 'Eres muy gracioso/a',
      'very_smart': 'Eres muy inteligente',
    },
    'flirting': {
      'can_i_buy_drink': '¿Te puedo invitar a una copa?',
      'you_come_here_often': '¿Vienes aquí a menudo?',
      'cant_stop_thinking': 'No puedo dejar de pensar en ti',
      'you_make_me_smile': 'Me haces sonreír',
      'want_to_dance': '¿Quieres bailar?',
    },
    'asking_out': {
      'grab_coffee': '¿Tomamos un café?',
      'dinner_together': '¿Cenamos juntos?',
      'free_this_weekend': '¿Estás libre este fin de semana?',
      'would_love_to_see': 'Me encantaría verte otra vez',
      'lets_meet_up': '¡Quedamos!',
    },
    'restaurant': {
      'table_for_two': 'Una mesa para dos, por favor',
      'menu_please': '¿Nos trae la carta?',
      'what_recommend': '¿Qué nos recomienda?',
      'this_is_delicious': '¡Esto está delicioso!',
      'check_please': 'La cuenta, por favor',
    },
    'feelings': {
      'i_like_you': 'Me gustas',
      'i_love_you': 'Te quiero / Te amo',
      'miss_you': 'Te echo de menos',
      'you_mean_everything': 'Significas todo para mí',
      'falling_for_you': 'Me estoy enamorando de ti',
    },
  };

  // French Content
  static const Map<String, Map<String, String>> _frenchContent = {
    'greetings': {
      'hello_beautiful': 'Bonjour belle/beau!',
      'how_are_you': 'Comment vas-tu?',
      'nice_to_meet_you': 'Enchanté(e) de te rencontrer',
      'good_morning': 'Bonjour mon cœur!',
      'good_night': 'Bonne nuit mon amour!',
    },
    'compliments': {
      'beautiful_eyes': 'Tu as de très beaux yeux',
      'lovely_smile': 'J\'adore ton sourire',
      'you_look_amazing': 'Tu es magnifique',
      'so_funny': 'Tu es tellement drôle',
      'very_smart': 'Tu es très intelligent(e)',
    },
    'flirting': {
      'can_i_buy_drink': 'Je peux t\'offrir un verre?',
      'you_come_here_often': 'Tu viens souvent ici?',
      'cant_stop_thinking': 'Je n\'arrête pas de penser à toi',
      'you_make_me_smile': 'Tu me fais sourire',
      'want_to_dance': 'Tu veux danser?',
    },
    'asking_out': {
      'grab_coffee': 'On prend un café?',
      'dinner_together': 'On dîne ensemble?',
      'free_this_weekend': 'Tu es libre ce week-end?',
      'would_love_to_see': 'J\'aimerais te revoir',
      'lets_meet_up': 'On se voit!',
    },
    'restaurant': {
      'table_for_two': 'Une table pour deux, s\'il vous plaît',
      'menu_please': 'Le menu, s\'il vous plaît',
      'what_recommend': 'Qu\'est-ce que vous recommandez?',
      'this_is_delicious': 'C\'est délicieux!',
      'check_please': 'L\'addition, s\'il vous plaît',
    },
    'feelings': {
      'i_like_you': 'Tu me plais',
      'i_love_you': 'Je t\'aime',
      'miss_you': 'Tu me manques',
      'you_mean_everything': 'Tu es tout pour moi',
      'falling_for_you': 'Je suis en train de tomber amoureux/amoureuse de toi',
    },
  };

  // German Content
  static const Map<String, Map<String, String>> _germanContent = {
    'greetings': {
      'hello_beautiful': 'Hallo Schöne/Schöner!',
      'how_are_you': 'Wie geht es dir?',
      'nice_to_meet_you': 'Freut mich, dich kennenzulernen',
      'good_morning': 'Guten Morgen, Schatz!',
      'good_night': 'Gute Nacht, mein Liebe!',
    },
    'compliments': {
      'beautiful_eyes': 'Du hast wunderschöne Augen',
      'lovely_smile': 'Ich liebe dein Lächeln',
      'you_look_amazing': 'Du siehst toll aus',
      'so_funny': 'Du bist so lustig',
      'very_smart': 'Du bist sehr intelligent',
    },
    'flirting': {
      'can_i_buy_drink': 'Darf ich dir einen Drink ausgeben?',
      'you_come_here_often': 'Kommst du öfter hierher?',
      'cant_stop_thinking': 'Ich muss ständig an dich denken',
      'you_make_me_smile': 'Du bringst mich zum Lächeln',
      'want_to_dance': 'Möchtest du tanzen?',
    },
    'asking_out': {
      'grab_coffee': 'Wollen wir einen Kaffee trinken?',
      'dinner_together': 'Wollen wir zusammen essen?',
      'free_this_weekend': 'Hast du am Wochenende Zeit?',
      'would_love_to_see': 'Ich würde dich gern wiedersehen',
      'lets_meet_up': 'Lass uns treffen!',
    },
    'restaurant': {
      'table_for_two': 'Einen Tisch für zwei, bitte',
      'menu_please': 'Die Speisekarte, bitte',
      'what_recommend': 'Was empfehlen Sie?',
      'this_is_delicious': 'Das ist köstlich!',
      'check_please': 'Die Rechnung, bitte',
    },
    'feelings': {
      'i_like_you': 'Ich mag dich',
      'i_love_you': 'Ich liebe dich',
      'miss_you': 'Ich vermisse dich',
      'you_mean_everything': 'Du bedeutest mir alles',
      'falling_for_you': 'Ich verliebe mich in dich',
    },
  };

  // Italian Content
  static const Map<String, Map<String, String>> _italianContent = {
    'greetings': {
      'hello_beautiful': 'Ciao bella/bello!',
      'how_are_you': 'Come stai?',
      'nice_to_meet_you': 'Piacere di conoscerti',
      'good_morning': 'Buongiorno tesoro!',
      'good_night': 'Buonanotte amore mio!',
    },
    'compliments': {
      'beautiful_eyes': 'Hai degli occhi bellissimi',
      'lovely_smile': 'Adoro il tuo sorriso',
      'you_look_amazing': 'Sei fantastica/o',
      'so_funny': 'Sei molto divertente',
      'very_smart': 'Sei molto intelligente',
    },
    'flirting': {
      'can_i_buy_drink': 'Posso offrirti qualcosa da bere?',
      'you_come_here_often': 'Vieni spesso qui?',
      'cant_stop_thinking': 'Non riesco a smettere di pensare a te',
      'you_make_me_smile': 'Mi fai sorridere',
      'want_to_dance': 'Vuoi ballare?',
    },
    'asking_out': {
      'grab_coffee': 'Prendiamo un caffè?',
      'dinner_together': 'Ceniamo insieme?',
      'free_this_weekend': 'Sei libera/o questo fine settimana?',
      'would_love_to_see': 'Mi piacerebbe rivederti',
      'lets_meet_up': 'Vediamoci!',
    },
    'restaurant': {
      'table_for_two': 'Un tavolo per due, per favore',
      'menu_please': 'Il menu, per favore',
      'what_recommend': 'Cosa ci consiglia?',
      'this_is_delicious': 'È delizioso!',
      'check_please': 'Il conto, per favore',
    },
    'feelings': {
      'i_like_you': 'Mi piaci',
      'i_love_you': 'Ti amo',
      'miss_you': 'Mi manchi',
      'you_mean_everything': 'Sei tutto per me',
      'falling_for_you': 'Mi sto innamorando di te',
    },
  };

  // Portuguese Content
  static const Map<String, Map<String, String>> _portugueseContent = {
    'greetings': {
      'hello_beautiful': 'Olá linda/lindo!',
      'how_are_you': 'Como você está?',
      'nice_to_meet_you': 'Prazer em te conhecer',
      'good_morning': 'Bom dia, amor!',
      'good_night': 'Boa noite, meu amor!',
    },
    'compliments': {
      'beautiful_eyes': 'Você tem olhos lindos',
      'lovely_smile': 'Adoro seu sorriso',
      'you_look_amazing': 'Você está incrível',
      'so_funny': 'Você é muito engraçado/a',
      'very_smart': 'Você é muito inteligente',
    },
    'flirting': {
      'can_i_buy_drink': 'Posso te pagar uma bebida?',
      'you_come_here_often': 'Você vem sempre aqui?',
      'cant_stop_thinking': 'Não consigo parar de pensar em você',
      'you_make_me_smile': 'Você me faz sorrir',
      'want_to_dance': 'Quer dançar?',
    },
    'asking_out': {
      'grab_coffee': 'Vamos tomar um café?',
      'dinner_together': 'Vamos jantar juntos?',
      'free_this_weekend': 'Você está livre nesse fim de semana?',
      'would_love_to_see': 'Adoraria te ver de novo',
      'lets_meet_up': 'Vamos nos encontrar!',
    },
    'restaurant': {
      'table_for_two': 'Uma mesa para dois, por favor',
      'menu_please': 'O cardápio, por favor',
      'what_recommend': 'O que você recomenda?',
      'this_is_delicious': 'Está delicioso!',
      'check_please': 'A conta, por favor',
    },
    'feelings': {
      'i_like_you': 'Eu gosto de você',
      'i_love_you': 'Eu te amo',
      'miss_you': 'Sinto sua falta',
      'you_mean_everything': 'Você significa tudo para mim',
      'falling_for_you': 'Estou me apaixonando por você',
    },
  };

  // Japanese Content
  static const Map<String, Map<String, String>> _japaneseContent = {
    'greetings': {
      'hello_beautiful': 'やあ、かわいいね！(Yaa, kawaii ne!)',
      'how_are_you': '元気？(Genki?)',
      'nice_to_meet_you': 'はじめまして (Hajimemashite)',
      'good_morning': 'おはよう、大好き！(Ohayou, daisuki!)',
      'good_night': 'おやすみ、愛してる (Oyasumi, aishiteru)',
    },
    'compliments': {
      'beautiful_eyes': '目がきれい (Me ga kirei)',
      'lovely_smile': '笑顔が素敵 (Egao ga suteki)',
      'you_look_amazing': 'とてもきれいだね (Totemo kirei da ne)',
      'so_funny': '面白いね (Omoshiroi ne)',
      'very_smart': '頭がいいね (Atama ga ii ne)',
    },
    'flirting': {
      'can_i_buy_drink': '飲み物をおごらせて (Nomimono wo ogorasete)',
      'you_come_here_often': 'よくここに来るの？(Yoku koko ni kuru no?)',
      'cant_stop_thinking': '君のことが頭から離れない (Kimi no koto ga atama kara hanarenai)',
      'you_make_me_smile': '君は私を笑顔にする (Kimi wa watashi wo egao ni suru)',
      'want_to_dance': '踊らない？(Odoranai?)',
    },
    'asking_out': {
      'grab_coffee': 'コーヒー飲まない？(Koohii nomanai?)',
      'dinner_together': '一緒に夕食を食べない？(Issho ni yuushoku wo tabenai?)',
      'free_this_weekend': '週末暇？(Shuumatsu hima?)',
      'would_love_to_see': 'また会いたい (Mata aitai)',
      'lets_meet_up': '会おう！(Aou!)',
    },
    'restaurant': {
      'table_for_two': '二人です (Futari desu)',
      'menu_please': 'メニューをください (Menyuu wo kudasai)',
      'what_recommend': 'おすすめは何ですか？(Osusume wa nan desu ka?)',
      'this_is_delicious': 'おいしい！(Oishii!)',
      'check_please': 'お会計お願いします (Okaikei onegaishimasu)',
    },
    'feelings': {
      'i_like_you': '好きです (Suki desu)',
      'i_love_you': '愛してる (Aishiteru)',
      'miss_you': '会いたい (Aitai)',
      'you_mean_everything': '君は僕のすべて (Kimi wa boku no subete)',
      'falling_for_you': '君に恋してる (Kimi ni koi shiteru)',
    },
  };

  // Korean Content
  static const Map<String, Map<String, String>> _koreanContent = {
    'greetings': {
      'hello_beautiful': '안녕, 예쁜이! (Annyeong, yeppeu-ni!)',
      'how_are_you': '어떻게 지내? (Eotteoke jinae?)',
      'nice_to_meet_you': '만나서 반가워 (Mannaseo bangawo)',
      'good_morning': '좋은 아침, 자기야! (Joeun achim, jagiya!)',
      'good_night': '잘 자, 내 사랑 (Jal ja, nae sarang)',
    },
    'compliments': {
      'beautiful_eyes': '눈이 예뻐요 (Nuni yeppeoyo)',
      'lovely_smile': '웃는 모습이 좋아 (Utneun moseubi joa)',
      'you_look_amazing': '정말 멋져 (Jeongmal meotjyeo)',
      'so_funny': '진짜 웃겨 (Jinjja utgyeo)',
      'very_smart': '똑똒해 (Ttokttokae)',
    },
    'flirting': {
      'can_i_buy_drink': '한 잔 사도 될까요? (Han jan sado doelkkayo?)',
      'you_come_here_often': '여기 자주 와요? (Yeogi jaju wayo?)',
      'cant_stop_thinking': '자꾸 생각나 (Jakku saenggakna)',
      'you_make_me_smile': '나를 웃게 해줘 (Nareul utge haejwo)',
      'want_to_dance': '춤출래요? (Chumchullaeyo?)',
    },
    'asking_out': {
      'grab_coffee': '커피 마실래요? (Keopi masillaeyo?)',
      'dinner_together': '같이 저녁 먹을래요? (Gachi jeonyeok meogeullaeyo?)',
      'free_this_weekend': '이번 주말에 시간 있어요? (Ibeon jumare sigan isseoyo?)',
      'would_love_to_see': '다시 보고 싶어요 (Dasi bogo sipeoyo)',
      'lets_meet_up': '만나요! (Mannayo!)',
    },
    'restaurant': {
      'table_for_two': '두 명이요 (Du myeong-iyo)',
      'menu_please': '메뉴판 주세요 (Menyu-pan juseyo)',
      'what_recommend': '추천해 주세요 (Chucheonhae juseyo)',
      'this_is_delicious': '맛있어요! (Masisseoyo!)',
      'check_please': '계산해 주세요 (Gyesanhae juseyo)',
    },
    'feelings': {
      'i_like_you': '좋아해요 (Joahaeyo)',
      'i_love_you': '사랑해요 (Saranghaeyo)',
      'miss_you': '보고 싶어요 (Bogo sipeoyo)',
      'you_mean_everything': '너는 나의 전부야 (Neoneun naui jeonbuya)',
      'falling_for_you': '너한테 빠지고 있어 (Neohante ppajigo isseo)',
    },
  };

  // Chinese Content
  static const Map<String, Map<String, String>> _chineseContent = {
    'greetings': {
      'hello_beautiful': '你好，美女/帅哥！(Nǐ hǎo, měinǚ/shuàigē!)',
      'how_are_you': '你好吗？(Nǐ hǎo ma?)',
      'nice_to_meet_you': '很高兴认识你 (Hěn gāoxìng rènshi nǐ)',
      'good_morning': '早上好，亲爱的！(Zǎoshang hǎo, qīn\'ài de!)',
      'good_night': '晚安，我的爱 (Wǎn\'ān, wǒ de ài)',
    },
    'compliments': {
      'beautiful_eyes': '你的眼睛很美 (Nǐ de yǎnjīng hěn měi)',
      'lovely_smile': '我喜欢你的笑容 (Wǒ xǐhuān nǐ de xiàoróng)',
      'you_look_amazing': '你真漂亮 (Nǐ zhēn piàoliang)',
      'so_funny': '你很幽默 (Nǐ hěn yōumò)',
      'very_smart': '你很聪明 (Nǐ hěn cōngming)',
    },
    'flirting': {
      'can_i_buy_drink': '我请你喝一杯？(Wǒ qǐng nǐ hē yī bēi?)',
      'you_come_here_often': '你常来这里吗？(Nǐ cháng lái zhèlǐ ma?)',
      'cant_stop_thinking': '我一直在想你 (Wǒ yīzhí zài xiǎng nǐ)',
      'you_make_me_smile': '你让我微笑 (Nǐ ràng wǒ wēixiào)',
      'want_to_dance': '想跳舞吗？(Xiǎng tiàowǔ ma?)',
    },
    'asking_out': {
      'grab_coffee': '一起喝咖啡？(Yīqǐ hē kāfēi?)',
      'dinner_together': '一起吃晚饭？(Yīqǐ chī wǎnfàn?)',
      'free_this_weekend': '这周末有空吗？(Zhè zhōumò yǒu kòng ma?)',
      'would_love_to_see': '我想再见你 (Wǒ xiǎng zài jiàn nǐ)',
      'lets_meet_up': '我们见面吧！(Wǒmen jiànmiàn ba!)',
    },
    'restaurant': {
      'table_for_two': '两位 (Liǎng wèi)',
      'menu_please': '请给我菜单 (Qǐng gěi wǒ càidān)',
      'what_recommend': '你们推荐什么？(Nǐmen tuījiàn shénme?)',
      'this_is_delicious': '很好吃！(Hěn hǎo chī!)',
      'check_please': '买单 (Mǎidān)',
    },
    'feelings': {
      'i_like_you': '我喜欢你 (Wǒ xǐhuān nǐ)',
      'i_love_you': '我爱你 (Wǒ ài nǐ)',
      'miss_you': '我想你 (Wǒ xiǎng nǐ)',
      'you_mean_everything': '你对我来说是一切 (Nǐ duì wǒ lái shuō shì yīqiè)',
      'falling_for_you': '我爱上你了 (Wǒ ài shàng nǐ le)',
    },
  };

  // Default content template for other languages
  static const Map<String, Map<String, String>> _defaultContent = {
    'greetings': {
      'hello_beautiful': '[Hello beautiful]',
      'how_are_you': '[How are you?]',
      'nice_to_meet_you': '[Nice to meet you]',
      'good_morning': '[Good morning, darling]',
      'good_night': '[Good night, my love]',
    },
    'compliments': {
      'beautiful_eyes': '[You have beautiful eyes]',
      'lovely_smile': '[I love your smile]',
      'you_look_amazing': '[You look amazing]',
      'so_funny': '[You are so funny]',
      'very_smart': '[You are very smart]',
    },
    'flirting': {
      'can_i_buy_drink': '[Can I buy you a drink?]',
      'you_come_here_often': '[Do you come here often?]',
      'cant_stop_thinking': '[I can\'t stop thinking about you]',
      'you_make_me_smile': '[You make me smile]',
      'want_to_dance': '[Do you want to dance?]',
    },
    'asking_out': {
      'grab_coffee': '[Let\'s grab a coffee]',
      'dinner_together': '[Let\'s have dinner together]',
      'free_this_weekend': '[Are you free this weekend?]',
      'would_love_to_see': '[I would love to see you again]',
      'lets_meet_up': '[Let\'s meet up!]',
    },
    'restaurant': {
      'table_for_two': '[A table for two, please]',
      'menu_please': '[Menu, please]',
      'what_recommend': '[What do you recommend?]',
      'this_is_delicious': '[This is delicious!]',
      'check_please': '[Check, please]',
    },
    'feelings': {
      'i_like_you': '[I like you]',
      'i_love_you': '[I love you]',
      'miss_you': '[I miss you]',
      'you_mean_everything': '[You mean everything to me]',
      'falling_for_you': '[I\'m falling for you]',
    },
  };
}
