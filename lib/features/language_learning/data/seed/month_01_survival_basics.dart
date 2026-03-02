import 'learning_path_constants.dart';

/// Month 1: Survival Basics -- "First Steps" (Beginner Level)
/// Modules: 1.1 Greetings & Introductions, 1.2 Numbers & Counting,
///          1.3 Essential Phrases for Travel
/// Includes 80-card flashcard deck and "Greeting Customs" cultural quiz.
class Month01SurvivalBasics {
  Month01SurvivalBasics._();

  static const int _m = 1;
  static final String _level = LearningPathConstants.levelBeginner;

  // =========================================================================
  // MODULE 1.1 -- Greetings & Introductions  (8 lessons)
  // =========================================================================
  static List<Map<String, dynamic>> get module1Lessons {
    final c = LearningPathConstants;
    return [
      // Lesson 1: Hello & Hi
      c.buildLesson(
        id: c.lessonId(_m, 1, 1),
        title: 'Hello & Hi -- Your First Words',
        description:
            'Learn the most basic greetings to start any conversation.',
        level: _level,
        category: c.catFirstImpressions,
        lessonNumber: 1,
        weekNumber: 1,
        dayNumber: 1,
        month: _m,
        objectives: [
          'Say hello and hi in the target language',
          'Understand when to use formal vs casual hello',
          'Respond when someone greets you',
        ],
        sections: [
          c.buildSection(
            id: c.sectionId(_m, 1, 1, 0),
            title: 'Key Vocabulary',
            type: c.secVocabulary,
            orderIndex: 0,
            introduction: 'Every conversation starts with a greeting. '
                'Here are the words you will use hundreds of times.',
            contents: [
              c.buildContent(id: c.contentId(_m, 1, 1, 0, 0), type: c.ctPhrase, text: '{hello}', translation: 'Hello', pronunciation: '{hello_pron}'),
              c.buildContent(id: c.contentId(_m, 1, 1, 0, 1), type: c.ctPhrase, text: '{hi_casual}', translation: 'Hi (casual)', pronunciation: '{hi_casual_pron}'),
              c.buildContent(id: c.contentId(_m, 1, 1, 0, 2), type: c.ctPhrase, text: '{hey}', translation: 'Hey', pronunciation: '{hey_pron}'),
              c.buildContent(id: c.contentId(_m, 1, 1, 0, 3), type: c.ctTip, text: 'Use the formal version with strangers and older people. '
                  'Use the casual version with friends and people your age.'),
            ],
            exercises: [
              c.buildExercise(
                id: c.exerciseId(_m, 1, 1, 0, 0),
                type: c.exMultipleChoice,
                question: 'Which greeting is most appropriate when meeting someone for the first time?',
                options: ['{hello}', '{hey}', '{bye}', '{thanks}'],
                correctAnswer: '{hello}',
                explanation: 'The formal hello is best for first meetings.',
                orderIndex: 0,
              ),
              c.buildExercise(
                id: c.exerciseId(_m, 1, 1, 0, 1),
                type: c.exMatching,
                question: 'Match the greeting to its formality level.',
                options: ['{hello} -> Formal', '{hi_casual} -> Casual', '{hey} -> Very casual'],
                correctAnswer: '{hello} -> Formal',
                orderIndex: 1,
              ),
            ],
          ),
          c.buildSection(
            id: c.sectionId(_m, 1, 1, 1),
            title: 'Real Conversation',
            type: c.secDialogue,
            orderIndex: 1,
            introduction: 'See how people actually use these greetings.',
            contents: [
              c.buildContent(id: c.contentId(_m, 1, 1, 1, 0), type: c.ctDialogueLine, text: 'A: {hello}!', translation: 'A: Hello!'),
              c.buildContent(id: c.contentId(_m, 1, 1, 1, 1), type: c.ctDialogueLine, text: 'B: {hi_casual}! {how_are_you}?', translation: 'B: Hi! How are you?'),
              c.buildContent(id: c.contentId(_m, 1, 1, 1, 2), type: c.ctDialogueLine, text: 'A: {im_fine_thanks}. {and_you}?', translation: 'A: I\'m fine, thanks. And you?'),
            ],
            exercises: [
              c.buildExercise(
                id: c.exerciseId(_m, 1, 1, 1, 0),
                type: c.exConversationChoice,
                question: 'Someone says "{hello}" to you. What is the best reply?',
                options: ['{hello}!', '{goodbye}', '{thanks}', '{sorry}'],
                correctAnswer: '{hello}!',
                explanation: 'Simply greeting them back is the most natural response.',
                orderIndex: 0,
              ),
            ],
          ),
          c.buildSection(
            id: c.sectionId(_m, 1, 1, 2),
            title: 'Cultural Note',
            type: c.secCulturalNote,
            orderIndex: 2,
            introduction: 'Greetings vary enormously across cultures.',
            contents: [
              c.buildContent(id: c.contentId(_m, 1, 1, 2, 0), type: c.ctFunFact,
                text: 'In many cultures, a greeting is more than just words. '
                    'Some cultures bow, others kiss cheeks, and some shake hands. '
                    'Learning the right greeting shows respect and makes a great impression.'),
            ],
            exercises: [],
            xpReward: 5,
          ),
        ],
      ),

      // Lesson 2: Good Morning / Afternoon / Evening / Night
      c.buildLesson(
        id: c.lessonId(_m, 1, 2),
        title: 'Good Morning, Good Night',
        description: 'Greet people appropriately at any time of day.',
        level: _level,
        category: c.catFirstImpressions,
        lessonNumber: 2,
        weekNumber: 1,
        dayNumber: 2,
        month: _m,
        prerequisites: [c.lessonId(_m, 1, 1)],
        objectives: [
          'Use time-appropriate greetings',
          'Know the difference between evening and night greetings',
          'Greet someone when arriving and leaving',
        ],
        sections: [
          c.buildSection(
            id: c.sectionId(_m, 1, 2, 0),
            title: 'Time-of-Day Greetings',
            type: c.secVocabulary,
            orderIndex: 0,
            introduction: 'Using the right greeting for the time of day shows awareness and courtesy.',
            contents: [
              c.buildContent(id: c.contentId(_m, 1, 2, 0, 0), type: c.ctPhrase, text: '{good_morning}', translation: 'Good morning', pronunciation: '{good_morning_pron}'),
              c.buildContent(id: c.contentId(_m, 1, 2, 0, 1), type: c.ctPhrase, text: '{good_afternoon}', translation: 'Good afternoon', pronunciation: '{good_afternoon_pron}'),
              c.buildContent(id: c.contentId(_m, 1, 2, 0, 2), type: c.ctPhrase, text: '{good_evening}', translation: 'Good evening', pronunciation: '{good_evening_pron}'),
              c.buildContent(id: c.contentId(_m, 1, 2, 0, 3), type: c.ctPhrase, text: '{good_night}', translation: 'Good night', pronunciation: '{good_night_pron}'),
              c.buildContent(id: c.contentId(_m, 1, 2, 0, 4), type: c.ctTip, text: '"Good night" is used when saying goodbye in the evening or before bed, not as a greeting when arriving.'),
            ],
            exercises: [
              c.buildExercise(id: c.exerciseId(_m, 1, 2, 0, 0), type: c.exMultipleChoice, question: 'It is 8 AM. Which greeting should you use?', options: ['{good_morning}', '{good_evening}', '{good_night}', '{good_afternoon}'], correctAnswer: '{good_morning}', explanation: 'Good morning is used from sunrise until around noon.', orderIndex: 0),
              c.buildExercise(id: c.exerciseId(_m, 1, 2, 0, 1), type: c.exTrueFalse, question: '"Good night" can be used as a greeting when you arrive at a dinner party.', options: ['True', 'False'], correctAnswer: 'False', explanation: 'Good night is a farewell, not an arrival greeting. Use "Good evening" instead.', orderIndex: 1),
            ],
          ),
          c.buildSection(
            id: c.sectionId(_m, 1, 2, 1),
            title: 'Practice Dialogue',
            type: c.secDialogue,
            orderIndex: 1,
            contents: [
              c.buildContent(id: c.contentId(_m, 1, 2, 1, 0), type: c.ctDialogueLine, text: 'A: {good_morning}!', translation: 'A: Good morning!'),
              c.buildContent(id: c.contentId(_m, 1, 2, 1, 1), type: c.ctDialogueLine, text: 'B: {good_morning}! {how_are_you}?', translation: 'B: Good morning! How are you?'),
              c.buildContent(id: c.contentId(_m, 1, 2, 1, 2), type: c.ctDialogueLine, text: 'A: {im_well}. {beautiful_day}!', translation: 'A: I\'m well. Beautiful day!'),
            ],
            exercises: [
              c.buildExercise(id: c.exerciseId(_m, 1, 2, 1, 0), type: c.exReorderWords, question: 'Put these words in order to make a morning greeting.', options: ['{word_good}', '{word_morning}'], correctAnswer: '{good_morning}', hint: 'The adjective comes first.', orderIndex: 0),
            ],
          ),
        ],
      ),

      // Lesson 3: My name is... / What is your name?
      c.buildLesson(
        id: c.lessonId(_m, 1, 3),
        title: 'My Name Is... What Is Yours?',
        description: 'Introduce yourself and ask for someone\'s name.',
        level: _level,
        category: c.catDatingBasics,
        lessonNumber: 3,
        weekNumber: 1,
        dayNumber: 3,
        month: _m,
        prerequisites: [c.lessonId(_m, 1, 2)],
        objectives: [
          'Introduce yourself by name',
          'Ask someone their name politely',
          'Respond when asked your name',
        ],
        sections: [
          c.buildSection(
            id: c.sectionId(_m, 1, 3, 0),
            title: 'Key Phrases',
            type: c.secVocabulary,
            orderIndex: 0,
            introduction: 'Names are personal. Learning to exchange them warmly is the foundation of connection.',
            contents: [
              c.buildContent(id: c.contentId(_m, 1, 3, 0, 0), type: c.ctPhrase, text: '{my_name_is}', translation: 'My name is...', pronunciation: '{my_name_is_pron}'),
              c.buildContent(id: c.contentId(_m, 1, 3, 0, 1), type: c.ctPhrase, text: '{what_is_your_name}', translation: 'What is your name?', pronunciation: '{what_is_your_name_pron}'),
              c.buildContent(id: c.contentId(_m, 1, 3, 0, 2), type: c.ctPhrase, text: '{what_is_your_name_formal}', translation: 'What is your name? (formal)', pronunciation: '{what_is_your_name_formal_pron}'),
              c.buildContent(id: c.contentId(_m, 1, 3, 0, 3), type: c.ctPhrase, text: '{i_am_called}', translation: 'I am called...', pronunciation: '{i_am_called_pron}'),
            ],
            exercises: [
              c.buildExercise(id: c.exerciseId(_m, 1, 3, 0, 0), type: c.exFillInBlank, question: '_____ Ana. (My name is Ana.)', options: [], correctAnswer: '{my_name_is}', explanation: 'This is the standard way to state your name.', orderIndex: 0),
              c.buildExercise(id: c.exerciseId(_m, 1, 3, 0, 1), type: c.exTranslation, question: 'Translate: "What is your name?"', options: [], correctAnswer: '{what_is_your_name}', orderIndex: 1),
            ],
          ),
          c.buildSection(
            id: c.sectionId(_m, 1, 3, 1),
            title: 'Introduction Dialogue',
            type: c.secDialogue,
            orderIndex: 1,
            contents: [
              c.buildContent(id: c.contentId(_m, 1, 3, 1, 0), type: c.ctDialogueLine, text: 'A: {hello}! {my_name_is} Marco.', translation: 'A: Hello! My name is Marco.'),
              c.buildContent(id: c.contentId(_m, 1, 3, 1, 1), type: c.ctDialogueLine, text: 'B: {nice_to_meet_you}, Marco! {my_name_is} Sofia.', translation: 'B: Nice to meet you, Marco! My name is Sofia.'),
              c.buildContent(id: c.contentId(_m, 1, 3, 1, 2), type: c.ctDialogueLine, text: 'A: {nice_to_meet_you_too}, Sofia!', translation: 'A: Nice to meet you too, Sofia!'),
            ],
            exercises: [
              c.buildExercise(id: c.exerciseId(_m, 1, 3, 1, 0), type: c.exConversationChoice, question: 'Someone says "{my_name_is} Luca." How do you respond?', options: ['{nice_to_meet_you}, Luca!', '{goodbye}, Luca', '{how_much}?', '{im_sorry}'], correctAnswer: '{nice_to_meet_you}, Luca!', orderIndex: 0),
            ],
          ),
        ],
      ),

      // Lesson 4: Nice to meet you / How are you? / I'm fine
      c.buildLesson(
        id: c.lessonId(_m, 1, 4),
        title: 'Nice to Meet You! How Are You?',
        description: 'Master the polite phrases that follow every introduction.',
        level: _level,
        category: c.catFirstImpressions,
        lessonNumber: 4,
        weekNumber: 1,
        dayNumber: 4,
        month: _m,
        prerequisites: [c.lessonId(_m, 1, 3)],
        objectives: [
          'Say "nice to meet you" naturally',
          'Ask and answer "how are you?"',
          'Give common responses: fine, good, great, not bad',
        ],
        sections: [
          c.buildSection(
            id: c.sectionId(_m, 1, 4, 0),
            title: 'Polite Meeting Phrases',
            type: c.secVocabulary,
            orderIndex: 0,
            introduction: 'These phrases are the social glue of every culture.',
            contents: [
              c.buildContent(id: c.contentId(_m, 1, 4, 0, 0), type: c.ctPhrase, text: '{nice_to_meet_you}', translation: 'Nice to meet you', pronunciation: '{nice_to_meet_you_pron}'),
              c.buildContent(id: c.contentId(_m, 1, 4, 0, 1), type: c.ctPhrase, text: '{how_are_you}', translation: 'How are you?', pronunciation: '{how_are_you_pron}'),
              c.buildContent(id: c.contentId(_m, 1, 4, 0, 2), type: c.ctPhrase, text: '{im_fine_thanks}', translation: 'I\'m fine, thanks', pronunciation: '{im_fine_thanks_pron}'),
              c.buildContent(id: c.contentId(_m, 1, 4, 0, 3), type: c.ctPhrase, text: '{im_great}', translation: 'I\'m great', pronunciation: '{im_great_pron}'),
              c.buildContent(id: c.contentId(_m, 1, 4, 0, 4), type: c.ctPhrase, text: '{not_bad}', translation: 'Not bad', pronunciation: '{not_bad_pron}'),
              c.buildContent(id: c.contentId(_m, 1, 4, 0, 5), type: c.ctPhrase, text: '{and_you}', translation: 'And you?', pronunciation: '{and_you_pron}'),
            ],
            exercises: [
              c.buildExercise(id: c.exerciseId(_m, 1, 4, 0, 0), type: c.exMultipleChoice, question: 'Someone asks "{how_are_you}?" Which is NOT an appropriate answer?', options: ['{im_fine_thanks}', '{im_great}', '{goodbye}', '{not_bad}'], correctAnswer: '{goodbye}', explanation: '"Goodbye" is a farewell, not a response to "how are you?"', orderIndex: 0),
              c.buildExercise(id: c.exerciseId(_m, 1, 4, 0, 1), type: c.exFillInBlank, question: '{how_are_you}? -- {im_fine_thanks}. _____?', options: [], correctAnswer: '{and_you}', explanation: 'It is polite to ask the same question back.', orderIndex: 1),
            ],
          ),
        ],
      ),

      // Lesson 5: Formal vs Informal Greetings
      c.buildLesson(
        id: c.lessonId(_m, 1, 5),
        title: 'Formal vs Informal -- Know the Difference',
        description: 'Understand when to be formal and when to relax.',
        level: _level,
        category: c.catCulturalExchange,
        lessonNumber: 5,
        weekNumber: 1,
        dayNumber: 5,
        month: _m,
        prerequisites: [c.lessonId(_m, 1, 4)],
        objectives: [
          'Distinguish formal from informal greetings',
          'Choose the right register for different situations',
          'Understand cultural expectations around formality',
        ],
        sections: [
          c.buildSection(
            id: c.sectionId(_m, 1, 5, 0),
            title: 'Formal Greetings',
            type: c.secVocabulary,
            orderIndex: 0,
            introduction: 'Use these with people you do not know well, elders, and in professional settings.',
            contents: [
              c.buildContent(id: c.contentId(_m, 1, 5, 0, 0), type: c.ctPhrase, text: '{hello_formal}', translation: 'Hello (formal)', pronunciation: '{hello_formal_pron}'),
              c.buildContent(id: c.contentId(_m, 1, 5, 0, 1), type: c.ctPhrase, text: '{how_are_you_formal}', translation: 'How are you? (formal)', pronunciation: '{how_are_you_formal_pron}'),
              c.buildContent(id: c.contentId(_m, 1, 5, 0, 2), type: c.ctPhrase, text: '{pleased_to_meet_you}', translation: 'Pleased to meet you', pronunciation: '{pleased_to_meet_you_pron}'),
            ],
            exercises: [
              c.buildExercise(id: c.exerciseId(_m, 1, 5, 0, 0), type: c.exMultipleChoice, question: 'You are meeting your date\'s parents for the first time. Which greeting is best?', options: ['{hello_formal}', '{hey}', '{hi_casual}', '{yo}'], correctAnswer: '{hello_formal}', explanation: 'First meetings with parents call for formal greetings.', orderIndex: 0),
            ],
          ),
          c.buildSection(
            id: c.sectionId(_m, 1, 5, 1),
            title: 'Informal Greetings',
            type: c.secVocabulary,
            orderIndex: 1,
            introduction: 'Use these with friends, family, and people your own age in casual settings.',
            contents: [
              c.buildContent(id: c.contentId(_m, 1, 5, 1, 0), type: c.ctPhrase, text: '{hi_casual}', translation: 'Hi', pronunciation: '{hi_casual_pron}'),
              c.buildContent(id: c.contentId(_m, 1, 5, 1, 1), type: c.ctPhrase, text: '{whats_up}', translation: 'What\'s up?', pronunciation: '{whats_up_pron}'),
              c.buildContent(id: c.contentId(_m, 1, 5, 1, 2), type: c.ctPhrase, text: '{hey_there}', translation: 'Hey there!', pronunciation: '{hey_there_pron}'),
            ],
            exercises: [
              c.buildExercise(id: c.exerciseId(_m, 1, 5, 1, 0), type: c.exMultipleChoice, question: 'Your close friend messages you. Which reply is most natural?', options: ['{hey_there}!', '{pleased_to_meet_you}', '{hello_formal}', '{good_evening}'], correctAnswer: '{hey_there}!', explanation: 'Casual greetings are perfect for close friends.', orderIndex: 0),
            ],
          ),
          c.buildSection(
            id: c.sectionId(_m, 1, 5, 2),
            title: 'Cultural Note',
            type: c.secCulturalNote,
            orderIndex: 2,
            contents: [
              c.buildContent(id: c.contentId(_m, 1, 5, 2, 0), type: c.ctFunFact,
                text: 'Many languages have a special formal "you" (like usted in Spanish, vous in French, Sie in German). '
                    'Using the wrong one can be seen as rude or overly familiar. When in doubt, start formal!'),
            ],
            exercises: [],
            xpReward: 5,
          ),
        ],
      ),

      // Lesson 6: Goodbye & See You Later
      c.buildLesson(
        id: c.lessonId(_m, 1, 6),
        title: 'Goodbye & See You Later',
        description: 'End conversations gracefully with the right farewell.',
        level: _level,
        category: c.catFirstImpressions,
        lessonNumber: 6,
        weekNumber: 1,
        dayNumber: 6,
        month: _m,
        prerequisites: [c.lessonId(_m, 1, 5)],
        objectives: [
          'Say goodbye in formal and informal ways',
          'Use "see you later" and "see you tomorrow"',
          'End conversations warmly',
        ],
        sections: [
          c.buildSection(
            id: c.sectionId(_m, 1, 6, 0),
            title: 'Farewell Phrases',
            type: c.secVocabulary,
            orderIndex: 0,
            contents: [
              c.buildContent(id: c.contentId(_m, 1, 6, 0, 0), type: c.ctPhrase, text: '{goodbye}', translation: 'Goodbye', pronunciation: '{goodbye_pron}'),
              c.buildContent(id: c.contentId(_m, 1, 6, 0, 1), type: c.ctPhrase, text: '{see_you_later}', translation: 'See you later', pronunciation: '{see_you_later_pron}'),
              c.buildContent(id: c.contentId(_m, 1, 6, 0, 2), type: c.ctPhrase, text: '{see_you_tomorrow}', translation: 'See you tomorrow', pronunciation: '{see_you_tomorrow_pron}'),
              c.buildContent(id: c.contentId(_m, 1, 6, 0, 3), type: c.ctPhrase, text: '{see_you_soon}', translation: 'See you soon', pronunciation: '{see_you_soon_pron}'),
              c.buildContent(id: c.contentId(_m, 1, 6, 0, 4), type: c.ctPhrase, text: '{bye_casual}', translation: 'Bye! (casual)', pronunciation: '{bye_casual_pron}'),
              c.buildContent(id: c.contentId(_m, 1, 6, 0, 5), type: c.ctPhrase, text: '{have_a_good_day}', translation: 'Have a good day!', pronunciation: '{have_a_good_day_pron}'),
            ],
            exercises: [
              c.buildExercise(id: c.exerciseId(_m, 1, 6, 0, 0), type: c.exMultipleChoice, question: 'You are leaving a job interview. What is the best farewell?', options: ['{goodbye}', '{bye_casual}', '{see_you_later}', '{whats_up}'], correctAnswer: '{goodbye}', explanation: 'A formal goodbye is appropriate for professional settings.', orderIndex: 0),
              c.buildExercise(id: c.exerciseId(_m, 1, 6, 0, 1), type: c.exTranslation, question: 'Translate: "See you tomorrow!"', options: [], correctAnswer: '{see_you_tomorrow}', orderIndex: 1),
            ],
          ),
        ],
      ),

      // Lesson 7: Greetings Practice & Mini Quiz
      c.buildLesson(
        id: c.lessonId(_m, 1, 7),
        title: 'Greetings Mastery -- Practice Round',
        description: 'Put together everything from this module with interactive practice.',
        level: _level,
        category: c.catDailyLife,
        lessonNumber: 7,
        weekNumber: 1,
        dayNumber: 7,
        month: _m,
        prerequisites: [c.lessonId(_m, 1, 6)],
        objectives: [
          'Use all greetings in context',
          'Match greetings to situations',
          'Complete a full introduction conversation',
        ],
        sections: [
          c.buildSection(
            id: c.sectionId(_m, 1, 7, 0),
            title: 'Situation Practice',
            type: c.secConversationSim,
            orderIndex: 0,
            introduction: 'Choose the right greeting for each situation.',
            contents: [
              c.buildContent(id: c.contentId(_m, 1, 7, 0, 0), type: c.ctText, text: 'Scenario 1: You arrive at a cafe in the morning and see someone you matched with on GreenGo.'),
              c.buildContent(id: c.contentId(_m, 1, 7, 0, 1), type: c.ctText, text: 'Scenario 2: You are leaving a dinner party at 11 PM.'),
              c.buildContent(id: c.contentId(_m, 1, 7, 0, 2), type: c.ctText, text: 'Scenario 3: You bump into a friend at the grocery store.'),
            ],
            exercises: [
              c.buildExercise(id: c.exerciseId(_m, 1, 7, 0, 0), type: c.exConversationChoice, question: 'Morning cafe meeting with a date. You say:', options: ['{good_morning}! {nice_to_meet_you}!', '{good_night}!', '{goodbye}!', '{sorry}!'], correctAnswer: '{good_morning}! {nice_to_meet_you}!', orderIndex: 0),
              c.buildExercise(id: c.exerciseId(_m, 1, 7, 0, 1), type: c.exConversationChoice, question: 'Leaving a dinner party at 11 PM. You say:', options: ['{good_night}! {have_a_good_day}!', '{good_morning}!', '{hello}!', '{what_is_your_name}?'], correctAnswer: '{good_night}! {have_a_good_day}!', orderIndex: 1),
              c.buildExercise(id: c.exerciseId(_m, 1, 7, 0, 2), type: c.exConversationChoice, question: 'You see a friend at the store. You say:', options: ['{hey_there}! {whats_up}?', '{pleased_to_meet_you}', '{good_night}', '{my_name_is}...'], correctAnswer: '{hey_there}! {whats_up}?', orderIndex: 2),
            ],
          ),
          c.buildSection(
            id: c.sectionId(_m, 1, 7, 1),
            title: 'Full Conversation Practice',
            type: c.secQuiz,
            orderIndex: 1,
            introduction: 'Complete this conversation by filling in the blanks.',
            contents: [],
            exercises: [
              c.buildExercise(id: c.exerciseId(_m, 1, 7, 1, 0), type: c.exFillInBlank, question: 'A: _____! {my_name_is} Alex. (Start with a greeting)', options: [], correctAnswer: '{hello}', orderIndex: 0),
              c.buildExercise(id: c.exerciseId(_m, 1, 7, 1, 1), type: c.exFillInBlank, question: 'B: {hello}! _____, Alex! {my_name_is} Jordan.', options: [], correctAnswer: '{nice_to_meet_you}', orderIndex: 1),
              c.buildExercise(id: c.exerciseId(_m, 1, 7, 1, 2), type: c.exFillInBlank, question: 'A: {nice_to_meet_you_too}! _____?', options: [], correctAnswer: '{how_are_you}', orderIndex: 2),
            ],
            xpReward: 20,
          ),
        ],
      ),

      // Lesson 8: Greeting Customs Quiz
      c.buildLesson(
        id: c.lessonId(_m, 1, 8),
        title: 'Greeting Customs Around the World',
        description: 'Discover how different cultures say hello and what to expect.',
        level: _level,
        category: c.catCulturalExchange,
        lessonNumber: 8,
        weekNumber: 2,
        dayNumber: 1,
        month: _m,
        prerequisites: [c.lessonId(_m, 1, 7)],
        objectives: [
          'Learn greeting customs from 5+ cultures',
          'Avoid common greeting mistakes abroad',
          'Understand the meaning behind different greeting styles',
        ],
        sections: [
          c.buildSection(
            id: c.sectionId(_m, 1, 8, 0),
            title: 'Greeting Customs Worldwide',
            type: c.secCulturalNote,
            orderIndex: 0,
            introduction: 'A greeting is your first impression. Getting it right shows respect.',
            contents: [
              c.buildContent(id: c.contentId(_m, 1, 8, 0, 0), type: c.ctText, text: 'France & Southern Europe: Two kisses on the cheeks (la bise). Start with the right cheek in France.'),
              c.buildContent(id: c.contentId(_m, 1, 8, 0, 1), type: c.ctText, text: 'Japan: Bow from the waist. The deeper the bow, the more respect. No physical contact.'),
              c.buildContent(id: c.contentId(_m, 1, 8, 0, 2), type: c.ctText, text: 'Latin America: One kiss on the cheek, sometimes a hug. Warmth is valued.'),
              c.buildContent(id: c.contentId(_m, 1, 8, 0, 3), type: c.ctText, text: 'Middle East: Same-gender handshake is common. Wait for the other person to initiate cross-gender greeting.'),
              c.buildContent(id: c.contentId(_m, 1, 8, 0, 4), type: c.ctText, text: 'Thailand: The "wai" -- palms pressed together with a slight bow. The higher the hands, the more respect.'),
            ],
            exercises: [
              c.buildExercise(id: c.exerciseId(_m, 1, 8, 0, 0), type: c.exMultipleChoice, question: 'In Japan, how do you greet someone formally?', options: ['Bow from the waist', 'Kiss on both cheeks', 'Firm handshake', 'Hug them warmly'], correctAnswer: 'Bow from the waist', explanation: 'Bowing is the traditional Japanese greeting. The depth shows respect.', orderIndex: 0),
              c.buildExercise(id: c.exerciseId(_m, 1, 8, 0, 1), type: c.exMultipleChoice, question: 'In France, "la bise" refers to:', options: ['Kiss greeting on cheeks', 'A type of bread', 'A formal bow', 'A handshake'], correctAnswer: 'Kiss greeting on cheeks', explanation: 'La bise is the French kiss-on-cheeks greeting used between friends and family.', orderIndex: 1),
              c.buildExercise(id: c.exerciseId(_m, 1, 8, 0, 2), type: c.exMultipleChoice, question: 'What is the Thai greeting called?', options: ['Wai', 'Bise', 'Bow', 'Namaste'], correctAnswer: 'Wai', explanation: 'The wai involves pressing palms together and bowing slightly.', orderIndex: 2),
            ],
          ),
        ],
      ),
    ];
  }

  // =========================================================================
  // MODULE 1.2 -- Numbers & Counting  (6 lessons)
  // =========================================================================
  static List<Map<String, dynamic>> get module2Lessons {
    final c = LearningPathConstants;
    return [
      // Lesson 1: Numbers 1-10
      c.buildLesson(
        id: c.lessonId(_m, 2, 1),
        title: 'Numbers 1 to 10',
        description: 'Learn to count from 1 to 10 -- the building blocks of all numbers.',
        level: _level,
        category: c.catDailyLife,
        lessonNumber: 9,
        weekNumber: 2,
        dayNumber: 2,
        month: _m,
        prerequisites: [c.lessonId(_m, 1, 8)],
        objectives: ['Count from 1 to 10', 'Recognize numbers when spoken', 'Use numbers in basic sentences'],
        sections: [
          c.buildSection(
            id: c.sectionId(_m, 2, 1, 0),
            title: 'Numbers 1-10',
            type: c.secVocabulary,
            orderIndex: 0,
            introduction: 'Numbers are everywhere: phone numbers, prices, ages, addresses. Master these ten and you have the foundation.',
            contents: [
              c.buildContent(id: c.contentId(_m, 2, 1, 0, 0), type: c.ctPhrase, text: '{one}', translation: '1 - One', pronunciation: '{one_pron}'),
              c.buildContent(id: c.contentId(_m, 2, 1, 0, 1), type: c.ctPhrase, text: '{two}', translation: '2 - Two', pronunciation: '{two_pron}'),
              c.buildContent(id: c.contentId(_m, 2, 1, 0, 2), type: c.ctPhrase, text: '{three}', translation: '3 - Three', pronunciation: '{three_pron}'),
              c.buildContent(id: c.contentId(_m, 2, 1, 0, 3), type: c.ctPhrase, text: '{four}', translation: '4 - Four', pronunciation: '{four_pron}'),
              c.buildContent(id: c.contentId(_m, 2, 1, 0, 4), type: c.ctPhrase, text: '{five}', translation: '5 - Five', pronunciation: '{five_pron}'),
              c.buildContent(id: c.contentId(_m, 2, 1, 0, 5), type: c.ctPhrase, text: '{six}', translation: '6 - Six', pronunciation: '{six_pron}'),
              c.buildContent(id: c.contentId(_m, 2, 1, 0, 6), type: c.ctPhrase, text: '{seven}', translation: '7 - Seven', pronunciation: '{seven_pron}'),
              c.buildContent(id: c.contentId(_m, 2, 1, 0, 7), type: c.ctPhrase, text: '{eight}', translation: '8 - Eight', pronunciation: '{eight_pron}'),
              c.buildContent(id: c.contentId(_m, 2, 1, 0, 8), type: c.ctPhrase, text: '{nine}', translation: '9 - Nine', pronunciation: '{nine_pron}'),
              c.buildContent(id: c.contentId(_m, 2, 1, 0, 9), type: c.ctPhrase, text: '{ten}', translation: '10 - Ten', pronunciation: '{ten_pron}'),
            ],
            exercises: [
              c.buildExercise(id: c.exerciseId(_m, 2, 1, 0, 0), type: c.exMultipleChoice, question: 'What is the number 7?', options: ['{seven}', '{six}', '{eight}', '{five}'], correctAnswer: '{seven}', orderIndex: 0),
              c.buildExercise(id: c.exerciseId(_m, 2, 1, 0, 1), type: c.exTranslation, question: 'Translate the number: 3', options: [], correctAnswer: '{three}', orderIndex: 1),
              c.buildExercise(id: c.exerciseId(_m, 2, 1, 0, 2), type: c.exReorderWords, question: 'Put these numbers in order: {five}, {two}, {eight}, {one}', options: ['{one}', '{two}', '{five}', '{eight}'], correctAnswer: '{one}, {two}, {five}, {eight}', orderIndex: 2),
            ],
          ),
        ],
      ),

      // Lesson 2: Numbers 11-20
      c.buildLesson(
        id: c.lessonId(_m, 2, 2),
        title: 'Numbers 11 to 20',
        description: 'Expand your number vocabulary to twenty.',
        level: _level,
        category: c.catDailyLife,
        lessonNumber: 10,
        weekNumber: 2,
        dayNumber: 3,
        month: _m,
        prerequisites: [c.lessonId(_m, 2, 1)],
        objectives: ['Count from 11 to 20', 'Understand number patterns', 'Use teen numbers confidently'],
        sections: [
          c.buildSection(
            id: c.sectionId(_m, 2, 2, 0),
            title: 'Numbers 11-20',
            type: c.secVocabulary,
            orderIndex: 0,
            introduction: 'Teen numbers often follow patterns. Look for the pattern as you learn.',
            contents: [
              c.buildContent(id: c.contentId(_m, 2, 2, 0, 0), type: c.ctPhrase, text: '{eleven}', translation: '11', pronunciation: '{eleven_pron}'),
              c.buildContent(id: c.contentId(_m, 2, 2, 0, 1), type: c.ctPhrase, text: '{twelve}', translation: '12', pronunciation: '{twelve_pron}'),
              c.buildContent(id: c.contentId(_m, 2, 2, 0, 2), type: c.ctPhrase, text: '{thirteen}', translation: '13', pronunciation: '{thirteen_pron}'),
              c.buildContent(id: c.contentId(_m, 2, 2, 0, 3), type: c.ctPhrase, text: '{fourteen}', translation: '14', pronunciation: '{fourteen_pron}'),
              c.buildContent(id: c.contentId(_m, 2, 2, 0, 4), type: c.ctPhrase, text: '{fifteen}', translation: '15', pronunciation: '{fifteen_pron}'),
              c.buildContent(id: c.contentId(_m, 2, 2, 0, 5), type: c.ctPhrase, text: '{sixteen}', translation: '16', pronunciation: '{sixteen_pron}'),
              c.buildContent(id: c.contentId(_m, 2, 2, 0, 6), type: c.ctPhrase, text: '{seventeen}', translation: '17', pronunciation: '{seventeen_pron}'),
              c.buildContent(id: c.contentId(_m, 2, 2, 0, 7), type: c.ctPhrase, text: '{eighteen}', translation: '18', pronunciation: '{eighteen_pron}'),
              c.buildContent(id: c.contentId(_m, 2, 2, 0, 8), type: c.ctPhrase, text: '{nineteen}', translation: '19', pronunciation: '{nineteen_pron}'),
              c.buildContent(id: c.contentId(_m, 2, 2, 0, 9), type: c.ctPhrase, text: '{twenty}', translation: '20', pronunciation: '{twenty_pron}'),
            ],
            exercises: [
              c.buildExercise(id: c.exerciseId(_m, 2, 2, 0, 0), type: c.exMultipleChoice, question: 'What number is {fifteen}?', options: ['15', '14', '16', '50'], correctAnswer: '15', orderIndex: 0),
              c.buildExercise(id: c.exerciseId(_m, 2, 2, 0, 1), type: c.exFillInBlank, question: 'After {twelve} comes _____.', options: [], correctAnswer: '{thirteen}', orderIndex: 1),
            ],
          ),
          c.buildSection(
            id: c.sectionId(_m, 2, 2, 1),
            title: 'Grammar Tip',
            type: c.secGrammarTip,
            orderIndex: 1,
            contents: [
              c.buildContent(id: c.contentId(_m, 2, 2, 1, 0), type: c.ctGrammarExplanation, text: 'Many languages form teen numbers by combining the base number with ten. '
                  'For example, in Spanish: diez (10) + seis (6) = dieciseis (16). '
                  'Look for similar patterns in the language you are learning.'),
            ],
            exercises: [],
            xpReward: 5,
          ),
        ],
      ),

      // Lesson 3: Numbers 21-100 (tens)
      c.buildLesson(
        id: c.lessonId(_m, 2, 3),
        title: 'Numbers 21 to 100 -- Tens and Beyond',
        description: 'Master the tens and combine them with units to say any number up to 100.',
        level: _level,
        category: c.catDailyLife,
        lessonNumber: 11,
        weekNumber: 2,
        dayNumber: 4,
        month: _m,
        prerequisites: [c.lessonId(_m, 2, 2)],
        objectives: ['Say every tens number (20, 30, ... 100)', 'Combine tens + units (e.g. 47)', 'Handle prices and ages confidently'],
        sections: [
          c.buildSection(
            id: c.sectionId(_m, 2, 3, 0),
            title: 'Tens: 20-100',
            type: c.secVocabulary,
            orderIndex: 0,
            contents: [
              c.buildContent(id: c.contentId(_m, 2, 3, 0, 0), type: c.ctPhrase, text: '{twenty}', translation: '20', pronunciation: '{twenty_pron}'),
              c.buildContent(id: c.contentId(_m, 2, 3, 0, 1), type: c.ctPhrase, text: '{thirty}', translation: '30', pronunciation: '{thirty_pron}'),
              c.buildContent(id: c.contentId(_m, 2, 3, 0, 2), type: c.ctPhrase, text: '{forty}', translation: '40', pronunciation: '{forty_pron}'),
              c.buildContent(id: c.contentId(_m, 2, 3, 0, 3), type: c.ctPhrase, text: '{fifty}', translation: '50', pronunciation: '{fifty_pron}'),
              c.buildContent(id: c.contentId(_m, 2, 3, 0, 4), type: c.ctPhrase, text: '{sixty}', translation: '60', pronunciation: '{sixty_pron}'),
              c.buildContent(id: c.contentId(_m, 2, 3, 0, 5), type: c.ctPhrase, text: '{seventy}', translation: '70', pronunciation: '{seventy_pron}'),
              c.buildContent(id: c.contentId(_m, 2, 3, 0, 6), type: c.ctPhrase, text: '{eighty}', translation: '80', pronunciation: '{eighty_pron}'),
              c.buildContent(id: c.contentId(_m, 2, 3, 0, 7), type: c.ctPhrase, text: '{ninety}', translation: '90', pronunciation: '{ninety_pron}'),
              c.buildContent(id: c.contentId(_m, 2, 3, 0, 8), type: c.ctPhrase, text: '{one_hundred}', translation: '100', pronunciation: '{one_hundred_pron}'),
            ],
            exercises: [
              c.buildExercise(id: c.exerciseId(_m, 2, 3, 0, 0), type: c.exTranslation, question: 'How do you say 50?', options: [], correctAnswer: '{fifty}', orderIndex: 0),
              c.buildExercise(id: c.exerciseId(_m, 2, 3, 0, 1), type: c.exMultipleChoice, question: 'What is {seventy} + {five}?', options: ['{seventy_five}', '{fifty_seven}', '{seventy}', '{seventeen}'], correctAnswer: '{seventy_five}', orderIndex: 1),
            ],
          ),
        ],
      ),

      // Lesson 4: Phone Numbers, Ages, Prices
      c.buildLesson(
        id: c.lessonId(_m, 2, 4),
        title: 'Real-World Numbers: Phone, Age, Price',
        description: 'Apply your number skills to everyday situations.',
        level: _level,
        category: c.catDailyLife,
        lessonNumber: 12,
        weekNumber: 2,
        dayNumber: 5,
        month: _m,
        prerequisites: [c.lessonId(_m, 2, 3)],
        objectives: ['Give and understand phone numbers', 'Ask and tell your age', 'Understand prices when shopping'],
        sections: [
          c.buildSection(
            id: c.sectionId(_m, 2, 4, 0),
            title: 'Practical Number Phrases',
            type: c.secVocabulary,
            orderIndex: 0,
            contents: [
              c.buildContent(id: c.contentId(_m, 2, 4, 0, 0), type: c.ctPhrase, text: '{my_phone_number_is}', translation: 'My phone number is...', pronunciation: '{my_phone_number_is_pron}'),
              c.buildContent(id: c.contentId(_m, 2, 4, 0, 1), type: c.ctPhrase, text: '{i_am_x_years_old}', translation: 'I am ... years old', pronunciation: '{i_am_x_years_old_pron}'),
              c.buildContent(id: c.contentId(_m, 2, 4, 0, 2), type: c.ctPhrase, text: '{how_old_are_you}', translation: 'How old are you?', pronunciation: '{how_old_are_you_pron}'),
              c.buildContent(id: c.contentId(_m, 2, 4, 0, 3), type: c.ctPhrase, text: '{how_much_does_it_cost}', translation: 'How much does it cost?', pronunciation: '{how_much_does_it_cost_pron}'),
              c.buildContent(id: c.contentId(_m, 2, 4, 0, 4), type: c.ctPhrase, text: '{it_costs_x}', translation: 'It costs...', pronunciation: '{it_costs_x_pron}'),
            ],
            exercises: [
              c.buildExercise(id: c.exerciseId(_m, 2, 4, 0, 0), type: c.exConversationChoice, question: 'You want to know the price of a coffee. You ask:', options: ['{how_much_does_it_cost}?', '{how_old_are_you}?', '{what_is_your_name}?', '{how_are_you}?'], correctAnswer: '{how_much_does_it_cost}?', orderIndex: 0),
              c.buildExercise(id: c.exerciseId(_m, 2, 4, 0, 1), type: c.exFillInBlank, question: '_____ 25 _____. (I am 25 years old.)', options: [], correctAnswer: '{i_am_x_years_old}', hint: 'Fill in the age phrase with 25.', orderIndex: 1),
            ],
          ),
          c.buildSection(
            id: c.sectionId(_m, 2, 4, 1),
            title: 'Date Number Exchange',
            type: c.secDialogue,
            orderIndex: 1,
            introduction: 'Exchanging numbers on a date -- a crucial skill!',
            contents: [
              c.buildContent(id: c.contentId(_m, 2, 4, 1, 0), type: c.ctDialogueLine, text: 'A: {great_time_tonight}! {can_i_have_your_number}?', translation: 'A: Great time tonight! Can I have your number?'),
              c.buildContent(id: c.contentId(_m, 2, 4, 1, 1), type: c.ctDialogueLine, text: 'B: {of_course}! {my_phone_number_is} {five} {five} {five} - {one} {two} {three} {four}.', translation: 'B: Of course! My number is 555-1234.'),
              c.buildContent(id: c.contentId(_m, 2, 4, 1, 2), type: c.ctDialogueLine, text: 'A: {got_it}! {i_will_call_you}.', translation: 'A: Got it! I\'ll call you.'),
            ],
            exercises: [
              c.buildExercise(id: c.exerciseId(_m, 2, 4, 1, 0), type: c.exConversationChoice, question: 'Your date asks for your number. How do you start?', options: ['{my_phone_number_is}...', '{how_much_does_it_cost}?', '{goodbye}!', '{i_am_x_years_old}...'], correctAnswer: '{my_phone_number_is}...', orderIndex: 0),
            ],
          ),
        ],
      ),

      // Lesson 5: Ordinal Numbers
      c.buildLesson(
        id: c.lessonId(_m, 2, 5),
        title: 'First, Second, Third -- Ordinal Numbers',
        description: 'Learn to describe order and rank.',
        level: _level,
        category: c.catDailyLife,
        lessonNumber: 13,
        weekNumber: 2,
        dayNumber: 6,
        month: _m,
        prerequisites: [c.lessonId(_m, 2, 4)],
        objectives: ['Say first through tenth', 'Use ordinals for dates and floors', 'Describe order in everyday contexts'],
        sections: [
          c.buildSection(
            id: c.sectionId(_m, 2, 5, 0),
            title: 'Ordinal Numbers',
            type: c.secVocabulary,
            orderIndex: 0,
            contents: [
              c.buildContent(id: c.contentId(_m, 2, 5, 0, 0), type: c.ctPhrase, text: '{first}', translation: 'First (1st)', pronunciation: '{first_pron}'),
              c.buildContent(id: c.contentId(_m, 2, 5, 0, 1), type: c.ctPhrase, text: '{second}', translation: 'Second (2nd)', pronunciation: '{second_pron}'),
              c.buildContent(id: c.contentId(_m, 2, 5, 0, 2), type: c.ctPhrase, text: '{third}', translation: 'Third (3rd)', pronunciation: '{third_pron}'),
              c.buildContent(id: c.contentId(_m, 2, 5, 0, 3), type: c.ctPhrase, text: '{fourth}', translation: 'Fourth (4th)', pronunciation: '{fourth_pron}'),
              c.buildContent(id: c.contentId(_m, 2, 5, 0, 4), type: c.ctPhrase, text: '{fifth}', translation: 'Fifth (5th)', pronunciation: '{fifth_pron}'),
            ],
            exercises: [
              c.buildExercise(id: c.exerciseId(_m, 2, 5, 0, 0), type: c.exMultipleChoice, question: 'You are on the 3rd floor. How do you say it?', options: ['{third}', '{three}', '{thirty}', '{thirteen}'], correctAnswer: '{third}', explanation: 'Ordinal numbers describe position or order, not quantity.', orderIndex: 0),
              c.buildExercise(id: c.exerciseId(_m, 2, 5, 0, 1), type: c.exFillInBlank, question: 'This is our _____ date! (first)', options: [], correctAnswer: '{first}', orderIndex: 1),
            ],
          ),
        ],
      ),

      // Lesson 6: Numbers Review Quiz
      c.buildLesson(
        id: c.lessonId(_m, 2, 6),
        title: 'Numbers Mastery Quiz',
        description: 'Test your number skills with real-world challenges.',
        level: _level,
        category: c.catDailyLife,
        lessonNumber: 14,
        weekNumber: 2,
        dayNumber: 7,
        month: _m,
        prerequisites: [c.lessonId(_m, 2, 5)],
        objectives: ['Apply all number knowledge', 'Handle numbers in conversations', 'Prepare for travel situations'],
        sections: [
          c.buildSection(
            id: c.sectionId(_m, 2, 6, 0),
            title: 'Number Challenge',
            type: c.secQuiz,
            orderIndex: 0,
            introduction: 'Let us see how well you know your numbers!',
            contents: [],
            exercises: [
              c.buildExercise(id: c.exerciseId(_m, 2, 6, 0, 0), type: c.exTranslation, question: 'How do you say 42?', options: [], correctAnswer: '{forty_two}', orderIndex: 0),
              c.buildExercise(id: c.exerciseId(_m, 2, 6, 0, 1), type: c.exMultipleChoice, question: 'A waiter says the bill is {thirty_five}. How much is that?', options: ['35', '53', '45', '25'], correctAnswer: '35', orderIndex: 1),
              c.buildExercise(id: c.exerciseId(_m, 2, 6, 0, 2), type: c.exFillInBlank, question: '{my_phone_number_is} {nine} {eight} {seven} - _____ {five} {four} {three}.', options: [], correctAnswer: '{six}', hint: 'What number comes between 7 and 5 in this sequence?', orderIndex: 2),
              c.buildExercise(id: c.exerciseId(_m, 2, 6, 0, 3), type: c.exConversationChoice, question: 'Someone asks {how_old_are_you}? You are 28. You say:', options: ['{i_am_x_years_old} {twenty_eight}', '{it_costs_x} {twenty_eight}', '{my_phone_number_is} {twenty_eight}', '{twenty_eight} {goodbye}'], correctAnswer: '{i_am_x_years_old} {twenty_eight}', orderIndex: 3),
            ],
            xpReward: 20,
          ),
        ],
      ),
    ];
  }

  // =========================================================================
  // MODULE 1.3 -- Essential Phrases for Travel  (8 lessons)
  // =========================================================================
  static List<Map<String, dynamic>> get module3Lessons {
    final c = LearningPathConstants;
    return [
      // Lesson 1: Please, Thank you, Excuse me, Sorry
      c.buildLesson(
        id: c.lessonId(_m, 3, 1),
        title: 'Magic Words: Please, Thank You, Sorry',
        description: 'The most important polite phrases in any language.',
        level: _level,
        category: c.catTravelAdventures,
        lessonNumber: 15,
        weekNumber: 3,
        dayNumber: 1,
        month: _m,
        prerequisites: [c.lessonId(_m, 2, 6)],
        objectives: ['Say please and thank you', 'Apologize politely', 'Get someone\'s attention with "excuse me"'],
        sections: [
          c.buildSection(
            id: c.sectionId(_m, 3, 1, 0),
            title: 'Polite Essentials',
            type: c.secVocabulary,
            orderIndex: 0,
            introduction: 'These four phrases will get you through almost any situation. They show respect and open doors.',
            contents: [
              c.buildContent(id: c.contentId(_m, 3, 1, 0, 0), type: c.ctPhrase, text: '{please}', translation: 'Please', pronunciation: '{please_pron}'),
              c.buildContent(id: c.contentId(_m, 3, 1, 0, 1), type: c.ctPhrase, text: '{thank_you}', translation: 'Thank you', pronunciation: '{thank_you_pron}'),
              c.buildContent(id: c.contentId(_m, 3, 1, 0, 2), type: c.ctPhrase, text: '{thank_you_very_much}', translation: 'Thank you very much', pronunciation: '{thank_you_very_much_pron}'),
              c.buildContent(id: c.contentId(_m, 3, 1, 0, 3), type: c.ctPhrase, text: '{excuse_me}', translation: 'Excuse me', pronunciation: '{excuse_me_pron}'),
              c.buildContent(id: c.contentId(_m, 3, 1, 0, 4), type: c.ctPhrase, text: '{sorry}', translation: 'Sorry / I\'m sorry', pronunciation: '{sorry_pron}'),
              c.buildContent(id: c.contentId(_m, 3, 1, 0, 5), type: c.ctPhrase, text: '{youre_welcome}', translation: 'You\'re welcome', pronunciation: '{youre_welcome_pron}'),
            ],
            exercises: [
              c.buildExercise(id: c.exerciseId(_m, 3, 1, 0, 0), type: c.exConversationChoice, question: 'A stranger gives you directions. You say:', options: ['{thank_you_very_much}!', '{sorry}!', '{excuse_me}?', '{please}'], correctAnswer: '{thank_you_very_much}!', orderIndex: 0),
              c.buildExercise(id: c.exerciseId(_m, 3, 1, 0, 1), type: c.exConversationChoice, question: 'You accidentally bump into someone. You say:', options: ['{sorry}!', '{thank_you}!', '{please}', '{youre_welcome}'], correctAnswer: '{sorry}!', orderIndex: 1),
              c.buildExercise(id: c.exerciseId(_m, 3, 1, 0, 2), type: c.exConversationChoice, question: 'You need to get past someone in a crowded place. You say:', options: ['{excuse_me}', '{sorry}', '{goodbye}', '{hello}'], correctAnswer: '{excuse_me}', orderIndex: 2),
            ],
          ),
        ],
      ),

      // Lesson 2: Yes/No, I don't understand, Can you repeat?
      c.buildLesson(
        id: c.lessonId(_m, 3, 2),
        title: 'Yes, No, and I Don\'t Understand',
        description: 'Essential responses when you need help or clarification.',
        level: _level,
        category: c.catTravelAdventures,
        lessonNumber: 16,
        weekNumber: 3,
        dayNumber: 2,
        month: _m,
        prerequisites: [c.lessonId(_m, 3, 1)],
        objectives: ['Say yes and no clearly', 'Tell someone you don\'t understand', 'Ask someone to repeat or speak slowly'],
        sections: [
          c.buildSection(
            id: c.sectionId(_m, 3, 2, 0),
            title: 'Survival Responses',
            type: c.secVocabulary,
            orderIndex: 0,
            introduction: 'Do not panic when you don\'t understand. These phrases will save you.',
            contents: [
              c.buildContent(id: c.contentId(_m, 3, 2, 0, 0), type: c.ctPhrase, text: '{yes}', translation: 'Yes', pronunciation: '{yes_pron}'),
              c.buildContent(id: c.contentId(_m, 3, 2, 0, 1), type: c.ctPhrase, text: '{no}', translation: 'No', pronunciation: '{no_pron}'),
              c.buildContent(id: c.contentId(_m, 3, 2, 0, 2), type: c.ctPhrase, text: '{i_dont_understand}', translation: 'I don\'t understand', pronunciation: '{i_dont_understand_pron}'),
              c.buildContent(id: c.contentId(_m, 3, 2, 0, 3), type: c.ctPhrase, text: '{can_you_repeat}', translation: 'Can you repeat that?', pronunciation: '{can_you_repeat_pron}'),
              c.buildContent(id: c.contentId(_m, 3, 2, 0, 4), type: c.ctPhrase, text: '{speak_slowly_please}', translation: 'Please speak slowly', pronunciation: '{speak_slowly_please_pron}'),
              c.buildContent(id: c.contentId(_m, 3, 2, 0, 5), type: c.ctPhrase, text: '{do_you_speak_english}', translation: 'Do you speak English?', pronunciation: '{do_you_speak_english_pron}'),
            ],
            exercises: [
              c.buildExercise(id: c.exerciseId(_m, 3, 2, 0, 0), type: c.exConversationChoice, question: 'Someone speaks too fast for you. You say:', options: ['{speak_slowly_please}', '{goodbye}', '{yes}', '{no}'], correctAnswer: '{speak_slowly_please}', orderIndex: 0),
              c.buildExercise(id: c.exerciseId(_m, 3, 2, 0, 1), type: c.exConversationChoice, question: 'You did not hear what someone said. You say:', options: ['{can_you_repeat}?', '{i_dont_understand}', '{no}', '{thank_you}'], correctAnswer: '{can_you_repeat}?', explanation: 'Use "repeat" when you did not hear. Use "I don\'t understand" when you heard but did not comprehend.', orderIndex: 1),
            ],
          ),
        ],
      ),

      // Lesson 3: Where is...? How much? I need help
      c.buildLesson(
        id: c.lessonId(_m, 3, 3),
        title: 'Where Is...? How Much? Help!',
        description: 'Ask for directions, prices, and assistance.',
        level: _level,
        category: c.catTravelAdventures,
        lessonNumber: 17,
        weekNumber: 3,
        dayNumber: 3,
        month: _m,
        prerequisites: [c.lessonId(_m, 3, 2)],
        objectives: ['Ask where something is', 'Inquire about prices', 'Ask for help in an emergency'],
        sections: [
          c.buildSection(
            id: c.sectionId(_m, 3, 3, 0),
            title: 'Essential Questions',
            type: c.secVocabulary,
            orderIndex: 0,
            contents: [
              c.buildContent(id: c.contentId(_m, 3, 3, 0, 0), type: c.ctPhrase, text: '{where_is}', translation: 'Where is...?', pronunciation: '{where_is_pron}'),
              c.buildContent(id: c.contentId(_m, 3, 3, 0, 1), type: c.ctPhrase, text: '{where_is_the_bathroom}', translation: 'Where is the bathroom?', pronunciation: '{where_is_the_bathroom_pron}'),
              c.buildContent(id: c.contentId(_m, 3, 3, 0, 2), type: c.ctPhrase, text: '{how_much}', translation: 'How much?', pronunciation: '{how_much_pron}'),
              c.buildContent(id: c.contentId(_m, 3, 3, 0, 3), type: c.ctPhrase, text: '{i_need_help}', translation: 'I need help', pronunciation: '{i_need_help_pron}'),
              c.buildContent(id: c.contentId(_m, 3, 3, 0, 4), type: c.ctPhrase, text: '{can_you_help_me}', translation: 'Can you help me?', pronunciation: '{can_you_help_me_pron}'),
              c.buildContent(id: c.contentId(_m, 3, 3, 0, 5), type: c.ctPhrase, text: '{i_am_lost}', translation: 'I am lost', pronunciation: '{i_am_lost_pron}'),
            ],
            exercises: [
              c.buildExercise(id: c.exerciseId(_m, 3, 3, 0, 0), type: c.exFillInBlank, question: '_____ the train station? (Where is the train station?)', options: [], correctAnswer: '{where_is}', orderIndex: 0),
              c.buildExercise(id: c.exerciseId(_m, 3, 3, 0, 1), type: c.exConversationChoice, question: 'You are lost in a new city. You approach someone and say:', options: ['{excuse_me}, {can_you_help_me}? {i_am_lost}.', '{hello}! {how_are_you}?', '{thank_you}! {goodbye}!', '{how_much}?'], correctAnswer: '{excuse_me}, {can_you_help_me}? {i_am_lost}.', orderIndex: 1),
            ],
          ),
        ],
      ),

      // Lesson 4: At the Airport
      c.buildLesson(
        id: c.lessonId(_m, 3, 4),
        title: 'At the Airport -- Essential Phrases',
        description: 'Navigate airports with confidence.',
        level: _level,
        category: c.catTravelAdventures,
        lessonNumber: 18,
        weekNumber: 3,
        dayNumber: 4,
        month: _m,
        prerequisites: [c.lessonId(_m, 3, 3)],
        objectives: ['Check in for a flight', 'Go through security', 'Find your gate and boarding area'],
        sections: [
          c.buildSection(
            id: c.sectionId(_m, 3, 4, 0),
            title: 'Airport Vocabulary',
            type: c.secVocabulary,
            orderIndex: 0,
            contents: [
              c.buildContent(id: c.contentId(_m, 3, 4, 0, 0), type: c.ctPhrase, text: '{passport}', translation: 'Passport', pronunciation: '{passport_pron}'),
              c.buildContent(id: c.contentId(_m, 3, 4, 0, 1), type: c.ctPhrase, text: '{boarding_pass}', translation: 'Boarding pass', pronunciation: '{boarding_pass_pron}'),
              c.buildContent(id: c.contentId(_m, 3, 4, 0, 2), type: c.ctPhrase, text: '{gate}', translation: 'Gate', pronunciation: '{gate_pron}'),
              c.buildContent(id: c.contentId(_m, 3, 4, 0, 3), type: c.ctPhrase, text: '{flight}', translation: 'Flight', pronunciation: '{flight_pron}'),
              c.buildContent(id: c.contentId(_m, 3, 4, 0, 4), type: c.ctPhrase, text: '{luggage}', translation: 'Luggage / Baggage', pronunciation: '{luggage_pron}'),
              c.buildContent(id: c.contentId(_m, 3, 4, 0, 5), type: c.ctPhrase, text: '{where_is_gate_x}', translation: 'Where is gate ...?', pronunciation: '{where_is_gate_x_pron}'),
              c.buildContent(id: c.contentId(_m, 3, 4, 0, 6), type: c.ctPhrase, text: '{my_flight_is_delayed}', translation: 'My flight is delayed', pronunciation: '{my_flight_is_delayed_pron}'),
            ],
            exercises: [
              c.buildExercise(id: c.exerciseId(_m, 3, 4, 0, 0), type: c.exMatching, question: 'Match the airport term to its meaning.', options: ['{passport} -> ID document for travel', '{boarding_pass} -> Ticket to board plane', '{gate} -> Where you wait to board'], correctAnswer: '{passport} -> ID document for travel', orderIndex: 0),
              c.buildExercise(id: c.exerciseId(_m, 3, 4, 0, 1), type: c.exConversationChoice, question: 'You cannot find your gate. You ask an airport worker:', options: ['{excuse_me}, {where_is_gate_x} B7?', '{how_much}?', '{i_am_x_years_old}', '{good_night}!'], correctAnswer: '{excuse_me}, {where_is_gate_x} B7?', orderIndex: 1),
            ],
          ),
        ],
      ),

      // Lesson 5: At the Hotel
      c.buildLesson(
        id: c.lessonId(_m, 3, 5),
        title: 'At the Hotel -- Check In and Requests',
        description: 'Handle hotel interactions from check-in to room requests.',
        level: _level,
        category: c.catTravelAdventures,
        lessonNumber: 19,
        weekNumber: 3,
        dayNumber: 5,
        month: _m,
        prerequisites: [c.lessonId(_m, 3, 4)],
        objectives: ['Check in at a hotel', 'Request room amenities', 'Report a problem politely'],
        sections: [
          c.buildSection(
            id: c.sectionId(_m, 3, 5, 0),
            title: 'Hotel Phrases',
            type: c.secVocabulary,
            orderIndex: 0,
            contents: [
              c.buildContent(id: c.contentId(_m, 3, 5, 0, 0), type: c.ctPhrase, text: '{i_have_a_reservation}', translation: 'I have a reservation', pronunciation: '{i_have_a_reservation_pron}'),
              c.buildContent(id: c.contentId(_m, 3, 5, 0, 1), type: c.ctPhrase, text: '{check_in}', translation: 'Check in', pronunciation: '{check_in_pron}'),
              c.buildContent(id: c.contentId(_m, 3, 5, 0, 2), type: c.ctPhrase, text: '{check_out}', translation: 'Check out', pronunciation: '{check_out_pron}'),
              c.buildContent(id: c.contentId(_m, 3, 5, 0, 3), type: c.ctPhrase, text: '{room_key}', translation: 'Room key', pronunciation: '{room_key_pron}'),
              c.buildContent(id: c.contentId(_m, 3, 5, 0, 4), type: c.ctPhrase, text: '{what_time_is_breakfast}', translation: 'What time is breakfast?', pronunciation: '{what_time_is_breakfast_pron}'),
              c.buildContent(id: c.contentId(_m, 3, 5, 0, 5), type: c.ctPhrase, text: '{wifi_password}', translation: 'What is the WiFi password?', pronunciation: '{wifi_password_pron}'),
            ],
            exercises: [
              c.buildExercise(id: c.exerciseId(_m, 3, 5, 0, 0), type: c.exConversationChoice, question: 'You arrive at your hotel. You approach the desk and say:', options: ['{hello}, {i_have_a_reservation}.', '{where_is_the_bathroom}?', '{how_much}?', '{goodbye}!'], correctAnswer: '{hello}, {i_have_a_reservation}.', orderIndex: 0),
            ],
          ),
          c.buildSection(
            id: c.sectionId(_m, 3, 5, 1),
            title: 'Hotel Check-In Dialogue',
            type: c.secDialogue,
            orderIndex: 1,
            contents: [
              c.buildContent(id: c.contentId(_m, 3, 5, 1, 0), type: c.ctDialogueLine, text: 'Guest: {hello}! {i_have_a_reservation}. {my_name_is} Smith.', translation: 'Guest: Hello! I have a reservation. My name is Smith.'),
              c.buildContent(id: c.contentId(_m, 3, 5, 1, 1), type: c.ctDialogueLine, text: 'Clerk: {welcome}! {yes}, {i_see_it}. {room} 304. {here_is_your} {room_key}.', translation: 'Clerk: Welcome! Yes, I see it. Room 304. Here is your key.'),
              c.buildContent(id: c.contentId(_m, 3, 5, 1, 2), type: c.ctDialogueLine, text: 'Guest: {thank_you}! {what_time_is_breakfast}?', translation: 'Guest: Thank you! What time is breakfast?'),
              c.buildContent(id: c.contentId(_m, 3, 5, 1, 3), type: c.ctDialogueLine, text: 'Clerk: {from} 7 {to} 10.', translation: 'Clerk: From 7 to 10.'),
            ],
            exercises: [
              c.buildExercise(id: c.exerciseId(_m, 3, 5, 1, 0), type: c.exReorderWords, question: 'Arrange: "{i_have_a_reservation}" / "{hello}" / "Smith" / "{my_name_is}"', options: ['{hello}', '{i_have_a_reservation}', '{my_name_is}', 'Smith'], correctAnswer: '{hello}! {i_have_a_reservation}. {my_name_is} Smith.', orderIndex: 0),
            ],
          ),
        ],
      ),

      // Lesson 6: At the Restaurant
      c.buildLesson(
        id: c.lessonId(_m, 3, 6),
        title: 'At the Restaurant -- Ordering Food',
        description: 'Order food, ask about the menu, and handle the bill.',
        level: _level,
        category: c.catRestaurantDates,
        lessonNumber: 20,
        weekNumber: 3,
        dayNumber: 6,
        month: _m,
        prerequisites: [c.lessonId(_m, 3, 5)],
        objectives: ['Order food and drinks', 'Ask about menu items', 'Request and pay the bill'],
        sections: [
          c.buildSection(
            id: c.sectionId(_m, 3, 6, 0),
            title: 'Restaurant Vocabulary',
            type: c.secVocabulary,
            orderIndex: 0,
            contents: [
              c.buildContent(id: c.contentId(_m, 3, 6, 0, 0), type: c.ctPhrase, text: '{table_for_two}', translation: 'A table for two, please', pronunciation: '{table_for_two_pron}'),
              c.buildContent(id: c.contentId(_m, 3, 6, 0, 1), type: c.ctPhrase, text: '{the_menu_please}', translation: 'The menu, please', pronunciation: '{the_menu_please_pron}'),
              c.buildContent(id: c.contentId(_m, 3, 6, 0, 2), type: c.ctPhrase, text: '{i_would_like}', translation: 'I would like...', pronunciation: '{i_would_like_pron}'),
              c.buildContent(id: c.contentId(_m, 3, 6, 0, 3), type: c.ctPhrase, text: '{what_do_you_recommend}', translation: 'What do you recommend?', pronunciation: '{what_do_you_recommend_pron}'),
              c.buildContent(id: c.contentId(_m, 3, 6, 0, 4), type: c.ctPhrase, text: '{the_bill_please}', translation: 'The bill, please', pronunciation: '{the_bill_please_pron}'),
              c.buildContent(id: c.contentId(_m, 3, 6, 0, 5), type: c.ctPhrase, text: '{this_is_delicious}', translation: 'This is delicious!', pronunciation: '{this_is_delicious_pron}'),
              c.buildContent(id: c.contentId(_m, 3, 6, 0, 6), type: c.ctPhrase, text: '{water}', translation: 'Water', pronunciation: '{water_pron}'),
              c.buildContent(id: c.contentId(_m, 3, 6, 0, 7), type: c.ctPhrase, text: '{coffee}', translation: 'Coffee', pronunciation: '{coffee_pron}'),
            ],
            exercises: [
              c.buildExercise(id: c.exerciseId(_m, 3, 6, 0, 0), type: c.exConversationChoice, question: 'You enter a restaurant with your date. You tell the host:', options: ['{table_for_two}, {please}', '{the_bill_please}', '{goodbye}!', '{where_is}?'], correctAnswer: '{table_for_two}, {please}', orderIndex: 0),
              c.buildExercise(id: c.exerciseId(_m, 3, 6, 0, 1), type: c.exConversationChoice, question: 'You finished eating and want to pay. You say:', options: ['{the_bill_please}', '{the_menu_please}', '{i_would_like} more', '{table_for_two}'], correctAnswer: '{the_bill_please}', orderIndex: 1),
              c.buildExercise(id: c.exerciseId(_m, 3, 6, 0, 2), type: c.exConversationChoice, question: 'The food arrives and it is amazing. You tell your date:', options: ['{this_is_delicious}!', '{i_dont_understand}', '{how_much}?', '{sorry}'], correctAnswer: '{this_is_delicious}!', orderIndex: 2),
            ],
          ),
        ],
      ),

      // Lesson 7: Ordering Complete Meal Role-Play
      c.buildLesson(
        id: c.lessonId(_m, 3, 7),
        title: 'Role-Play: Ordering a Complete Meal',
        description: 'Practice a full restaurant experience from start to finish.',
        level: _level,
        category: c.catRestaurantDates,
        lessonNumber: 21,
        weekNumber: 4,
        dayNumber: 1,
        month: _m,
        prerequisites: [c.lessonId(_m, 3, 6)],
        objectives: ['Navigate an entire restaurant visit', 'Handle unexpected situations', 'Feel confident ordering in another language'],
        sections: [
          c.buildSection(
            id: c.sectionId(_m, 3, 7, 0),
            title: 'Complete Restaurant Dialogue',
            type: c.secConversationSim,
            orderIndex: 0,
            introduction: 'You are on a date at a nice restaurant. Navigate the entire experience.',
            contents: [
              c.buildContent(id: c.contentId(_m, 3, 7, 0, 0), type: c.ctDialogueLine, text: 'Host: {good_evening}! {how_many}?', translation: 'Host: Good evening! How many?'),
              c.buildContent(id: c.contentId(_m, 3, 7, 0, 1), type: c.ctDialogueLine, text: 'You: {table_for_two}, {please}.', translation: 'You: A table for two, please.'),
              c.buildContent(id: c.contentId(_m, 3, 7, 0, 2), type: c.ctDialogueLine, text: 'Waiter: {here_is_the_menu}. {what_would_you_like_to_drink}?', translation: 'Waiter: Here is the menu. What would you like to drink?'),
              c.buildContent(id: c.contentId(_m, 3, 7, 0, 3), type: c.ctDialogueLine, text: 'You: {i_would_like} {water} {and} {coffee}, {please}.', translation: 'You: I would like water and coffee, please.'),
              c.buildContent(id: c.contentId(_m, 3, 7, 0, 4), type: c.ctDialogueLine, text: 'Waiter: {ready_to_order}?', translation: 'Waiter: Ready to order?'),
              c.buildContent(id: c.contentId(_m, 3, 7, 0, 5), type: c.ctDialogueLine, text: 'You: {what_do_you_recommend}?', translation: 'You: What do you recommend?'),
            ],
            exercises: [
              c.buildExercise(id: c.exerciseId(_m, 3, 7, 0, 0), type: c.exConversationChoice, question: 'The host asks how many people. You and your date respond:', options: ['{two}, {please}', '{one}', '{three}', '{ten}'], correctAnswer: '{two}, {please}', orderIndex: 0),
              c.buildExercise(id: c.exerciseId(_m, 3, 7, 0, 1), type: c.exConversationChoice, question: 'The waiter asks what you want to drink. You say:', options: ['{i_would_like} {water}, {please}', '{the_bill_please}', '{where_is_the_bathroom}?', '{goodbye}'], correctAnswer: '{i_would_like} {water}, {please}', orderIndex: 1),
              c.buildExercise(id: c.exerciseId(_m, 3, 7, 0, 2), type: c.exConversationChoice, question: 'You want the waiter\'s suggestion. You ask:', options: ['{what_do_you_recommend}?', '{how_old_are_you}?', '{what_is_your_name}?', '{where_is}?'], correctAnswer: '{what_do_you_recommend}?', orderIndex: 2),
              c.buildExercise(id: c.exerciseId(_m, 3, 7, 0, 3), type: c.exConversationChoice, question: 'You finished your meal and want to leave. You say:', options: ['{the_bill_please}. {thank_you}!', '{the_menu_please}', '{good_morning}!', '{i_am_lost}'], correctAnswer: '{the_bill_please}. {thank_you}!', orderIndex: 3),
            ],
            xpReward: 25,
          ),
        ],
      ),

      // Lesson 8: Month 1 Review
      c.buildLesson(
        id: c.lessonId(_m, 3, 8),
        title: 'Month 1 Final Review -- Survival Ready!',
        description: 'Review everything from Month 1 and prove you are ready to travel.',
        level: _level,
        category: c.catDailyLife,
        lessonNumber: 22,
        weekNumber: 4,
        dayNumber: 2,
        month: _m,
        prerequisites: [c.lessonId(_m, 3, 7)],
        objectives: ['Review all greetings', 'Use numbers confidently', 'Handle basic travel situations'],
        sections: [
          c.buildSection(
            id: c.sectionId(_m, 3, 8, 0),
            title: 'Month 1 Comprehensive Quiz',
            type: c.secQuiz,
            orderIndex: 0,
            introduction: 'Let us see how much you remember from this month!',
            contents: [],
            exercises: [
              c.buildExercise(id: c.exerciseId(_m, 3, 8, 0, 0), type: c.exTranslation, question: 'How do you say "Hello, my name is..."?', options: [], correctAnswer: '{hello}, {my_name_is}...', orderIndex: 0),
              c.buildExercise(id: c.exerciseId(_m, 3, 8, 0, 1), type: c.exTranslation, question: 'How do you say "Where is the bathroom?"', options: [], correctAnswer: '{where_is_the_bathroom}', orderIndex: 1),
              c.buildExercise(id: c.exerciseId(_m, 3, 8, 0, 2), type: c.exMultipleChoice, question: 'You want to order coffee. You say:', options: ['{i_would_like} {coffee}, {please}', '{where_is} {coffee}?', '{coffee} {goodbye}', '{how_much} {coffee}?'], correctAnswer: '{i_would_like} {coffee}, {please}', orderIndex: 2),
              c.buildExercise(id: c.exerciseId(_m, 3, 8, 0, 3), type: c.exMultipleChoice, question: 'What is {thirty} + {seven}?', options: ['{thirty_seven}', '{seventy_three}', '{thirty}', '{seven}'], correctAnswer: '{thirty_seven}', orderIndex: 3),
              c.buildExercise(id: c.exerciseId(_m, 3, 8, 0, 4), type: c.exConversationChoice, question: 'A local speaks too fast. You politely say:', options: ['{speak_slowly_please}', '{goodbye}!', '{this_is_delicious}!', '{how_old_are_you}?'], correctAnswer: '{speak_slowly_please}', orderIndex: 4),
            ],
            xpReward: 30,
          ),
        ],
      ),
    ];
  }

  // =========================================================================
  // FLASHCARD DECK -- "Month 1 Essentials" (80 cards)
  // =========================================================================
  static List<Map<String, dynamic>> get flashcards {
    final c = LearningPathConstants;
    return [
      // Greetings (20 cards)
      c.buildFlashcard(id: c.flashcardId(_m, 0), front: '{hello}', back: 'Hello', exampleSentence: '{hello}! {how_are_you}?', pronunciation: '{hello_pron}', category: 'greetings', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 1), front: '{hi_casual}', back: 'Hi (casual)', exampleSentence: '{hi_casual}! {whats_up}?', pronunciation: '{hi_casual_pron}', category: 'greetings', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 2), front: '{good_morning}', back: 'Good morning', exampleSentence: '{good_morning}! {beautiful_day}!', pronunciation: '{good_morning_pron}', category: 'greetings', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 3), front: '{good_afternoon}', back: 'Good afternoon', exampleSentence: '{good_afternoon}. {how_are_you}?', pronunciation: '{good_afternoon_pron}', category: 'greetings', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 4), front: '{good_evening}', back: 'Good evening', exampleSentence: '{good_evening}. {table_for_two}, {please}.', pronunciation: '{good_evening_pron}', category: 'greetings', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 5), front: '{good_night}', back: 'Good night', exampleSentence: '{good_night}! {see_you_tomorrow}.', pronunciation: '{good_night_pron}', category: 'greetings', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 6), front: '{goodbye}', back: 'Goodbye', exampleSentence: '{goodbye}! {have_a_good_day}!', pronunciation: '{goodbye_pron}', category: 'greetings', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 7), front: '{see_you_later}', back: 'See you later', exampleSentence: '{see_you_later}! {it_was_nice_meeting_you}.', pronunciation: '{see_you_later_pron}', category: 'greetings', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 8), front: '{nice_to_meet_you}', back: 'Nice to meet you', exampleSentence: '{nice_to_meet_you}! {my_name_is} Alex.', pronunciation: '{nice_to_meet_you_pron}', category: 'greetings', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 9), front: '{how_are_you}', back: 'How are you?', exampleSentence: '{hello}! {how_are_you}?', pronunciation: '{how_are_you_pron}', category: 'greetings', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 10), front: '{im_fine_thanks}', back: 'I\'m fine, thanks', exampleSentence: '{im_fine_thanks}. {and_you}?', pronunciation: '{im_fine_thanks_pron}', category: 'greetings', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 11), front: '{my_name_is}', back: 'My name is...', exampleSentence: '{my_name_is} Sofia. {nice_to_meet_you}!', pronunciation: '{my_name_is_pron}', category: 'greetings', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 12), front: '{what_is_your_name}', back: 'What is your name?', exampleSentence: '{hello}! {what_is_your_name}?', pronunciation: '{what_is_your_name_pron}', category: 'greetings', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 13), front: '{please}', back: 'Please', exampleSentence: '{water}, {please}.', pronunciation: '{please_pron}', category: 'greetings', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 14), front: '{thank_you}', back: 'Thank you', exampleSentence: '{thank_you} {very_much}!', pronunciation: '{thank_you_pron}', category: 'greetings', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 15), front: '{youre_welcome}', back: 'You\'re welcome', exampleSentence: 'A: {thank_you}! B: {youre_welcome}!', pronunciation: '{youre_welcome_pron}', category: 'greetings', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 16), front: '{excuse_me}', back: 'Excuse me', exampleSentence: '{excuse_me}, {where_is} the station?', pronunciation: '{excuse_me_pron}', category: 'greetings', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 17), front: '{sorry}', back: 'Sorry / I\'m sorry', exampleSentence: '{sorry}! {i_dont_understand}.', pronunciation: '{sorry_pron}', category: 'greetings', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 18), front: '{yes}', back: 'Yes', exampleSentence: '{yes}, {please}!', pronunciation: '{yes_pron}', category: 'greetings', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 19), front: '{no}', back: 'No', exampleSentence: '{no}, {thank_you}.', pronunciation: '{no_pron}', category: 'greetings', difficulty: 'beginner'),

      // Numbers (20 cards)
      c.buildFlashcard(id: c.flashcardId(_m, 20), front: '{one}', back: '1 - One', exampleSentence: '{one} {coffee}, {please}.', pronunciation: '{one_pron}', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 21), front: '{two}', back: '2 - Two', exampleSentence: '{table_for_two}, {please}.', pronunciation: '{two_pron}', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 22), front: '{three}', back: '3 - Three', exampleSentence: '{three} tickets, {please}.', pronunciation: '{three_pron}', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 23), front: '{four}', back: '4 - Four', exampleSentence: 'Room {four} {zero} {four}.', pronunciation: '{four_pron}', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 24), front: '{five}', back: '5 - Five', exampleSentence: '{five} minutes, {please}.', pronunciation: '{five_pron}', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 25), front: '{six}', back: '6 - Six', exampleSentence: 'Gate {six}.', pronunciation: '{six_pron}', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 26), front: '{seven}', back: '7 - Seven', exampleSentence: 'Breakfast at {seven}.', pronunciation: '{seven_pron}', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 27), front: '{eight}', back: '8 - Eight', exampleSentence: 'Our reservation is at {eight}.', pronunciation: '{eight_pron}', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 28), front: '{nine}', back: '9 - Nine', exampleSentence: 'Flight at {nine} AM.', pronunciation: '{nine_pron}', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 29), front: '{ten}', back: '10 - Ten', exampleSentence: '{ten} dollars.', pronunciation: '{ten_pron}', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 30), front: '{twenty}', back: '20 - Twenty', exampleSentence: '{it_costs_x} {twenty}.', pronunciation: '{twenty_pron}', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 31), front: '{fifty}', back: '50 - Fifty', exampleSentence: '{fifty} percent discount!', pronunciation: '{fifty_pron}', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 32), front: '{one_hundred}', back: '100 - One hundred', exampleSentence: '{it_costs_x} {one_hundred}.', pronunciation: '{one_hundred_pron}', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 33), front: '{first}', back: 'First (1st)', exampleSentence: 'This is our {first} date!', pronunciation: '{first_pron}', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 34), front: '{second}', back: 'Second (2nd)', exampleSentence: 'The {second} floor.', pronunciation: '{second_pron}', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 35), front: '{how_much}', back: 'How much?', exampleSentence: '{how_much} is this?', pronunciation: '{how_much_pron}', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 36), front: '{how_old_are_you}', back: 'How old are you?', exampleSentence: '{how_old_are_you}?', pronunciation: '{how_old_are_you_pron}', category: 'conversationStarters', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 37), front: '{i_am_x_years_old}', back: 'I am ... years old', exampleSentence: '{i_am_x_years_old} {twenty_five}.', pronunciation: '{i_am_x_years_old_pron}', category: 'conversationStarters', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 38), front: '{my_phone_number_is}', back: 'My phone number is...', exampleSentence: '{my_phone_number_is} 555-1234.', pronunciation: '{my_phone_number_is_pron}', category: 'conversationStarters', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 39), front: '{how_much_does_it_cost}', back: 'How much does it cost?', exampleSentence: '{excuse_me}, {how_much_does_it_cost}?', pronunciation: '{how_much_does_it_cost_pron}', category: 'casual', difficulty: 'beginner'),

      // Travel essentials (20 cards)
      c.buildFlashcard(id: c.flashcardId(_m, 40), front: '{where_is}', back: 'Where is...?', exampleSentence: '{where_is} the hotel?', pronunciation: '{where_is_pron}', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 41), front: '{where_is_the_bathroom}', back: 'Where is the bathroom?', exampleSentence: '{excuse_me}, {where_is_the_bathroom}?', pronunciation: '{where_is_the_bathroom_pron}', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 42), front: '{i_need_help}', back: 'I need help', exampleSentence: '{please}, {i_need_help}!', pronunciation: '{i_need_help_pron}', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 43), front: '{i_am_lost}', back: 'I am lost', exampleSentence: '{excuse_me}, {i_am_lost}. {can_you_help_me}?', pronunciation: '{i_am_lost_pron}', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 44), front: '{i_dont_understand}', back: 'I don\'t understand', exampleSentence: '{sorry}, {i_dont_understand}. {speak_slowly_please}.', pronunciation: '{i_dont_understand_pron}', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 45), front: '{can_you_repeat}', back: 'Can you repeat that?', exampleSentence: '{sorry}, {can_you_repeat}?', pronunciation: '{can_you_repeat_pron}', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 46), front: '{speak_slowly_please}', back: 'Please speak slowly', exampleSentence: '{speak_slowly_please}. {i_dont_understand}.', pronunciation: '{speak_slowly_please_pron}', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 47), front: '{do_you_speak_english}', back: 'Do you speak English?', exampleSentence: '{excuse_me}, {do_you_speak_english}?', pronunciation: '{do_you_speak_english_pron}', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 48), front: '{passport}', back: 'Passport', exampleSentence: '{here_is_my} {passport}.', pronunciation: '{passport_pron}', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 49), front: '{boarding_pass}', back: 'Boarding pass', exampleSentence: '{here_is_my} {boarding_pass}.', pronunciation: '{boarding_pass_pron}', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 50), front: '{flight}', back: 'Flight', exampleSentence: 'My {flight} is at {eight}.', pronunciation: '{flight_pron}', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 51), front: '{luggage}', back: 'Luggage', exampleSentence: '{where_is} my {luggage}?', pronunciation: '{luggage_pron}', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 52), front: '{i_have_a_reservation}', back: 'I have a reservation', exampleSentence: '{hello}, {i_have_a_reservation}.', pronunciation: '{i_have_a_reservation_pron}', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 53), front: '{room_key}', back: 'Room key', exampleSentence: '{can_i_have} the {room_key}?', pronunciation: '{room_key_pron}', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 54), front: '{wifi_password}', back: 'WiFi password', exampleSentence: '{what_is} the {wifi_password}?', pronunciation: '{wifi_password_pron}', category: 'travelCulture', difficulty: 'beginner'),

      // Restaurant (15 cards)
      c.buildFlashcard(id: c.flashcardId(_m, 55), front: '{table_for_two}', back: 'A table for two, please', exampleSentence: '{good_evening}! {table_for_two}, {please}.', pronunciation: '{table_for_two_pron}', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 56), front: '{the_menu_please}', back: 'The menu, please', exampleSentence: '{the_menu_please}.', pronunciation: '{the_menu_please_pron}', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 57), front: '{i_would_like}', back: 'I would like...', exampleSentence: '{i_would_like} {coffee}, {please}.', pronunciation: '{i_would_like_pron}', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 58), front: '{what_do_you_recommend}', back: 'What do you recommend?', exampleSentence: '{what_do_you_recommend}?', pronunciation: '{what_do_you_recommend_pron}', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 59), front: '{the_bill_please}', back: 'The bill, please', exampleSentence: '{the_bill_please}. {thank_you}!', pronunciation: '{the_bill_please_pron}', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 60), front: '{this_is_delicious}', back: 'This is delicious!', exampleSentence: '{this_is_delicious}!', pronunciation: '{this_is_delicious_pron}', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 61), front: '{water}', back: 'Water', exampleSentence: '{water}, {please}.', pronunciation: '{water_pron}', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 62), front: '{coffee}', back: 'Coffee', exampleSentence: '{one} {coffee}, {please}.', pronunciation: '{coffee_pron}', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 63), front: '{tea}', back: 'Tea', exampleSentence: '{i_would_like} {tea}.', pronunciation: '{tea_pron}', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 64), front: '{beer}', back: 'Beer', exampleSentence: '{two} {beer}s, {please}.', pronunciation: '{beer_pron}', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 65), front: '{wine}', back: 'Wine', exampleSentence: '{one} glass of {wine}, {please}.', pronunciation: '{wine_pron}', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 66), front: '{bread}', back: 'Bread', exampleSentence: 'More {bread}, {please}.', pronunciation: '{bread_pron}', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 67), front: '{chicken}', back: 'Chicken', exampleSentence: '{i_would_like} {chicken}.', pronunciation: '{chicken_pron}', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 68), front: '{fish}', back: 'Fish', exampleSentence: 'Is the {fish} fresh?', pronunciation: '{fish_pron}', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 69), front: '{salad}', back: 'Salad', exampleSentence: '{one} {salad}, {please}.', pronunciation: '{salad_pron}', category: 'travelCulture', difficulty: 'beginner'),

      // Conversation connectors (10 cards)
      c.buildFlashcard(id: c.flashcardId(_m, 70), front: '{and}', back: 'And', exampleSentence: '{coffee} {and} {water}, {please}.', pronunciation: '{and_pron}', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 71), front: '{or}', back: 'Or', exampleSentence: '{coffee} {or} {tea}?', pronunciation: '{or_pron}', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 72), front: '{but}', back: 'But', exampleSentence: 'I like {coffee} {but} not {tea}.', pronunciation: '{but_pron}', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 73), front: '{also}', back: 'Also / Too', exampleSentence: 'I {also} want {water}.', pronunciation: '{also_pron}', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 74), front: '{very}', back: 'Very', exampleSentence: '{very} good!', pronunciation: '{very_pron}', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 75), front: '{here}', back: 'Here', exampleSentence: '{here}, {please}.', pronunciation: '{here_pron}', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 76), front: '{there}', back: 'There', exampleSentence: 'Over {there}.', pronunciation: '{there_pron}', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 77), front: '{today}', back: 'Today', exampleSentence: '{today} is a beautiful day!', pronunciation: '{today_pron}', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 78), front: '{tomorrow}', back: 'Tomorrow', exampleSentence: '{see_you_tomorrow}!', pronunciation: '{tomorrow_pron}', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 79), front: '{now}', back: 'Now', exampleSentence: 'Let us go {now}!', pronunciation: '{now_pron}', category: 'casual', difficulty: 'beginner'),
    ];
  }

  // =========================================================================
  // CULTURAL QUIZ -- "Greeting Customs Around the World"
  // =========================================================================
  static Map<String, dynamic> get culturalQuiz {
    final c = LearningPathConstants;
    return c.buildCulturalQuiz(
      id: c.quizId(_m),
      title: 'Greeting Customs Around the World',
      description: 'How well do you know how people say hello across the globe?',
      difficulty: 'easy',
      questions: [
        c.buildQuizQuestion(
          id: c.quizQuestionId(_m, 1, 1),
          question: 'In France, how many kisses on the cheek is the standard greeting between friends?',
          options: ['One', 'Two', 'Three', 'Four'],
          correctOptionIndex: 1,
          explanation: 'In most of France, two kisses (la bise) is standard, though it varies by region -- some areas do one, three, or even four!',
        ),
        c.buildQuizQuestion(
          id: c.quizQuestionId(_m, 1, 2),
          question: 'In Japan, what is the traditional way to greet someone?',
          options: ['Handshake', 'Bow', 'Kiss on cheek', 'Hug'],
          correctOptionIndex: 1,
          explanation: 'Bowing (ojigi) is the traditional Japanese greeting. The deeper the bow, the more respect shown.',
        ),
        c.buildQuizQuestion(
          id: c.quizQuestionId(_m, 1, 3),
          question: 'In Thailand, what is the traditional greeting gesture called?',
          options: ['Wai', 'Namaste', 'Salaam', 'Bow'],
          correctOptionIndex: 0,
          explanation: 'The Wai involves pressing palms together at chest level and bowing slightly. It shows respect.',
        ),
        c.buildQuizQuestion(
          id: c.quizQuestionId(_m, 1, 4),
          question: 'What time do most Spaniards eat dinner?',
          options: ['6:00 PM', '7:00 PM', '9:00 - 10:00 PM', '5:00 PM'],
          correctOptionIndex: 2,
          explanation: 'Spaniards eat dinner late, typically between 9 and 10 PM. Some eat even later!',
        ),
        c.buildQuizQuestion(
          id: c.quizQuestionId(_m, 1, 5),
          question: 'In Brazil, how do friends typically greet each other?',
          options: ['Formal bow', 'Kiss on one cheek and a hug', 'Salute', 'Just a wave'],
          correctOptionIndex: 1,
          explanation: 'Brazilians are warm and physically affectionate. A kiss on the cheek and a hug is common among friends.',
        ),
        c.buildQuizQuestion(
          id: c.quizQuestionId(_m, 1, 6),
          question: 'In South Korea, what should you do when receiving a business card?',
          options: ['Put it in your pocket quickly', 'Receive it with both hands and read it', 'Write on it immediately', 'Fold it in half'],
          correctOptionIndex: 1,
          explanation: 'Receiving a card with both hands and taking time to read it shows respect in Korean culture.',
        ),
        c.buildQuizQuestion(
          id: c.quizQuestionId(_m, 1, 7),
          question: 'What does "Namaste" mean in Hindi?',
          options: ['Goodbye', 'I bow to the divine in you', 'How are you?', 'Welcome'],
          correctOptionIndex: 1,
          explanation: 'Namaste roughly translates to "I bow to the divine in you." It is accompanied by pressing palms together.',
        ),
        c.buildQuizQuestion(
          id: c.quizQuestionId(_m, 1, 8),
          question: 'In Germany, what is considered polite when entering a small shop?',
          options: ['Say nothing', 'Greet everyone with "Guten Tag"', 'Wave', 'Shake the shopkeeper\'s hand'],
          correctOptionIndex: 1,
          explanation: 'In Germany, it is polite to greet everyone when entering a small shop or waiting room.',
        ),
        c.buildQuizQuestion(
          id: c.quizQuestionId(_m, 1, 9),
          question: 'In which country is it common to greet by touching noses?',
          options: ['Italy', 'New Zealand (Maori)', 'Canada', 'Egypt'],
          correctOptionIndex: 1,
          explanation: 'The Maori "hongi" involves pressing noses and foreheads together to share the breath of life.',
        ),
        c.buildQuizQuestion(
          id: c.quizQuestionId(_m, 1, 10),
          question: 'When should you NOT use a first name with someone you just met in most European countries?',
          options: ['Never -- always use first names', 'In professional or formal settings', 'Only with children', 'At parties'],
          correctOptionIndex: 1,
          explanation: 'In many European countries, using someone\'s title and last name is expected until they invite you to use their first name.',
        ),
      ],
    );
  }

  // =========================================================================
  // Aggregate accessors
  // =========================================================================
  static List<Map<String, dynamic>> get allLessons =>
      [...module1Lessons, ...module2Lessons, ...module3Lessons];

  static int get totalLessonCount => allLessons.length;
  static int get totalFlashcardCount => flashcards.length;
}
