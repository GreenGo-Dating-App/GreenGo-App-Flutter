import 'learning_path_constants.dart';

/// Month 2: Daily Life -- "First Steps" (Beginner Level)
/// Modules: 2.1 Family & Relationships, 2.2 Food & Drink, 2.3 Days/Months/Time
class Month02DailyLife {
  Month02DailyLife._();

  static const int _m = 2;
  static final String _level = LearningPathConstants.levelBeginner;

  // =========================================================================
  // MODULE 2.1 -- Family & Relationships (6 lessons)
  // =========================================================================
  static List<Map<String, dynamic>> get module1Lessons {
    final c = LearningPathConstants;
    return [
      c.buildLesson(id: c.lessonId(_m, 1, 1), title: 'My Family -- Parents and Siblings', description: 'Learn the words for your closest family members.', level: _level, category: c.catFamilyTalk, lessonNumber: 23, weekNumber: 4, dayNumber: 3, month: _m, objectives: ['Name immediate family members', 'Say "I have a brother/sister"', 'Ask about someone\'s family'], sections: [
        c.buildSection(id: c.sectionId(_m, 1, 1, 0), title: 'Family Vocabulary', type: c.secVocabulary, orderIndex: 0, introduction: 'Family is one of the first things people ask about when getting to know each other.', contents: [
          c.buildContent(id: c.contentId(_m, 1, 1, 0, 0), type: c.ctPhrase, text: '{mother}', translation: 'Mother / Mom', pronunciation: '{mother_pron}'),
          c.buildContent(id: c.contentId(_m, 1, 1, 0, 1), type: c.ctPhrase, text: '{father}', translation: 'Father / Dad', pronunciation: '{father_pron}'),
          c.buildContent(id: c.contentId(_m, 1, 1, 0, 2), type: c.ctPhrase, text: '{brother}', translation: 'Brother', pronunciation: '{brother_pron}'),
          c.buildContent(id: c.contentId(_m, 1, 1, 0, 3), type: c.ctPhrase, text: '{sister}', translation: 'Sister', pronunciation: '{sister_pron}'),
          c.buildContent(id: c.contentId(_m, 1, 1, 0, 4), type: c.ctPhrase, text: '{i_have}', translation: 'I have...', pronunciation: '{i_have_pron}'),
          c.buildContent(id: c.contentId(_m, 1, 1, 0, 5), type: c.ctPhrase, text: '{do_you_have_siblings}', translation: 'Do you have brothers or sisters?', pronunciation: '{do_you_have_siblings_pron}'),
        ], exercises: [
          c.buildExercise(id: c.exerciseId(_m, 1, 1, 0, 0), type: c.exMultipleChoice, question: 'Your mom\'s sister\'s son is your...', options: ['Cousin', 'Brother', 'Uncle', 'Nephew'], correctAnswer: 'Cousin', orderIndex: 0),
          c.buildExercise(id: c.exerciseId(_m, 1, 1, 0, 1), type: c.exFillInBlank, question: '{i_have} {two} _____. (sisters)', options: [], correctAnswer: '{sister}s', orderIndex: 1),
        ]),
      ]),
      c.buildLesson(id: c.lessonId(_m, 1, 2), title: 'Extended Family', description: 'Grandparents, aunts, uncles, and cousins.', level: _level, category: c.catFamilyTalk, lessonNumber: 24, weekNumber: 4, dayNumber: 4, month: _m, prerequisites: [c.lessonId(_m, 1, 1)], objectives: ['Name extended family members', 'Describe family relationships', 'Talk about family gatherings'], sections: [
        c.buildSection(id: c.sectionId(_m, 1, 2, 0), title: 'Extended Family', type: c.secVocabulary, orderIndex: 0, contents: [
          c.buildContent(id: c.contentId(_m, 1, 2, 0, 0), type: c.ctPhrase, text: '{grandmother}', translation: 'Grandmother', pronunciation: '{grandmother_pron}'),
          c.buildContent(id: c.contentId(_m, 1, 2, 0, 1), type: c.ctPhrase, text: '{grandfather}', translation: 'Grandfather', pronunciation: '{grandfather_pron}'),
          c.buildContent(id: c.contentId(_m, 1, 2, 0, 2), type: c.ctPhrase, text: '{aunt}', translation: 'Aunt', pronunciation: '{aunt_pron}'),
          c.buildContent(id: c.contentId(_m, 1, 2, 0, 3), type: c.ctPhrase, text: '{uncle}', translation: 'Uncle', pronunciation: '{uncle_pron}'),
          c.buildContent(id: c.contentId(_m, 1, 2, 0, 4), type: c.ctPhrase, text: '{cousin}', translation: 'Cousin', pronunciation: '{cousin_pron}'),
        ], exercises: [
          c.buildExercise(id: c.exerciseId(_m, 1, 2, 0, 0), type: c.exMatching, question: 'Match the family member to the relationship.', options: ['{grandmother} -> Mother\'s mother', '{uncle} -> Father\'s brother', '{cousin} -> Aunt\'s child'], correctAnswer: '{grandmother} -> Mother\'s mother', orderIndex: 0),
        ]),
      ]),
      c.buildLesson(id: c.lessonId(_m, 1, 3), title: 'Describing Family Members', description: 'Talk about what your family members are like.', level: _level, category: c.catFamilyTalk, lessonNumber: 25, weekNumber: 4, dayNumber: 5, month: _m, prerequisites: [c.lessonId(_m, 1, 2)], objectives: ['Describe personality traits', 'Use adjectives with family nouns', 'Share what makes your family special'], sections: [
        c.buildSection(id: c.sectionId(_m, 1, 3, 0), title: 'Describing People', type: c.secVocabulary, orderIndex: 0, contents: [
          c.buildContent(id: c.contentId(_m, 1, 3, 0, 0), type: c.ctPhrase, text: '{kind}', translation: 'Kind / Nice', pronunciation: '{kind_pron}'),
          c.buildContent(id: c.contentId(_m, 1, 3, 0, 1), type: c.ctPhrase, text: '{funny}', translation: 'Funny', pronunciation: '{funny_pron}'),
          c.buildContent(id: c.contentId(_m, 1, 3, 0, 2), type: c.ctPhrase, text: '{smart}', translation: 'Smart / Intelligent', pronunciation: '{smart_pron}'),
          c.buildContent(id: c.contentId(_m, 1, 3, 0, 3), type: c.ctPhrase, text: '{tall}', translation: 'Tall', pronunciation: '{tall_pron}'),
          c.buildContent(id: c.contentId(_m, 1, 3, 0, 4), type: c.ctPhrase, text: '{young}', translation: 'Young', pronunciation: '{young_pron}'),
          c.buildContent(id: c.contentId(_m, 1, 3, 0, 5), type: c.ctPhrase, text: '{my_mother_is}', translation: 'My mother is...', pronunciation: '{my_mother_is_pron}'),
        ], exercises: [
          c.buildExercise(id: c.exerciseId(_m, 1, 3, 0, 0), type: c.exFillInBlank, question: '{my_mother_is} very _____. (kind)', options: [], correctAnswer: '{kind}', orderIndex: 0),
          c.buildExercise(id: c.exerciseId(_m, 1, 3, 0, 1), type: c.exTranslation, question: 'Translate: "My brother is funny."', options: [], correctAnswer: '{my_brother_is} {funny}', orderIndex: 1),
        ]),
      ]),
      c.buildLesson(id: c.lessonId(_m, 1, 4), title: 'Relationship Words', description: 'Friend, partner, colleague -- the people in your life.', level: _level, category: c.catMeetingFriends, lessonNumber: 26, weekNumber: 4, dayNumber: 6, month: _m, prerequisites: [c.lessonId(_m, 1, 3)], objectives: ['Use words for different relationship types', 'Introduce people by their relationship to you', 'Understand partner/significant other vocabulary'], sections: [
        c.buildSection(id: c.sectionId(_m, 1, 4, 0), title: 'Relationship Types', type: c.secVocabulary, orderIndex: 0, contents: [
          c.buildContent(id: c.contentId(_m, 1, 4, 0, 0), type: c.ctPhrase, text: '{friend}', translation: 'Friend', pronunciation: '{friend_pron}'),
          c.buildContent(id: c.contentId(_m, 1, 4, 0, 1), type: c.ctPhrase, text: '{best_friend}', translation: 'Best friend', pronunciation: '{best_friend_pron}'),
          c.buildContent(id: c.contentId(_m, 1, 4, 0, 2), type: c.ctPhrase, text: '{boyfriend}', translation: 'Boyfriend', pronunciation: '{boyfriend_pron}'),
          c.buildContent(id: c.contentId(_m, 1, 4, 0, 3), type: c.ctPhrase, text: '{girlfriend}', translation: 'Girlfriend', pronunciation: '{girlfriend_pron}'),
          c.buildContent(id: c.contentId(_m, 1, 4, 0, 4), type: c.ctPhrase, text: '{partner}', translation: 'Partner', pronunciation: '{partner_pron}'),
          c.buildContent(id: c.contentId(_m, 1, 4, 0, 5), type: c.ctPhrase, text: '{colleague}', translation: 'Colleague / Coworker', pronunciation: '{colleague_pron}'),
          c.buildContent(id: c.contentId(_m, 1, 4, 0, 6), type: c.ctPhrase, text: '{neighbor}', translation: 'Neighbor', pronunciation: '{neighbor_pron}'),
          c.buildContent(id: c.contentId(_m, 1, 4, 0, 7), type: c.ctPhrase, text: '{this_is_my}', translation: 'This is my...', pronunciation: '{this_is_my_pron}'),
        ], exercises: [
          c.buildExercise(id: c.exerciseId(_m, 1, 4, 0, 0), type: c.exConversationChoice, question: 'You introduce your date to a friend. You say:', options: ['{this_is_my} {friend}, Ana.', '{this_is_my} {colleague}, Ana.', '{this_is_my} {neighbor}, Ana.', '{this_is_my} {grandmother}, Ana.'], correctAnswer: '{this_is_my} {friend}, Ana.', orderIndex: 0),
        ]),
      ]),
      c.buildLesson(id: c.lessonId(_m, 1, 5), title: 'My Family Is... -- Describing Your Family', description: 'Put it all together and describe your whole family.', level: _level, category: c.catFamilyTalk, lessonNumber: 27, weekNumber: 4, dayNumber: 7, month: _m, prerequisites: [c.lessonId(_m, 1, 4)], objectives: ['Describe your family structure', 'Talk about family size', 'Share what your family likes to do together'], sections: [
        c.buildSection(id: c.sectionId(_m, 1, 5, 0), title: 'Family Description Dialogue', type: c.secDialogue, orderIndex: 0, contents: [
          c.buildContent(id: c.contentId(_m, 1, 5, 0, 0), type: c.ctDialogueLine, text: 'A: {tell_me_about_your_family}.', translation: 'A: Tell me about your family.'),
          c.buildContent(id: c.contentId(_m, 1, 5, 0, 1), type: c.ctDialogueLine, text: 'B: {i_have} {one} {brother} {and} {two} {sister}s. {my_mother_is} {kind} {and} {my_father_is} {funny}.', translation: 'B: I have one brother and two sisters. My mother is kind and my father is funny.'),
          c.buildContent(id: c.contentId(_m, 1, 5, 0, 2), type: c.ctDialogueLine, text: 'A: {that_sounds_nice}! {i_have} a small family -- just me {and} {my_mother}.', translation: 'A: That sounds nice! I have a small family -- just me and my mother.'),
        ], exercises: [
          c.buildExercise(id: c.exerciseId(_m, 1, 5, 0, 0), type: c.exFreeResponse, question: 'Describe your family using at least 3 family words you learned.', options: [], correctAnswer: '{i_have}...', hint: 'Start with "{i_have}" and list your family members.', orderIndex: 0),
        ]),
      ]),
      c.buildLesson(id: c.lessonId(_m, 1, 6), title: 'Family Talk Practice', description: 'Practice discussing family in dating conversations.', level: _level, category: c.catDatingBasics, lessonNumber: 28, weekNumber: 5, dayNumber: 1, month: _m, prerequisites: [c.lessonId(_m, 1, 5)], objectives: ['Answer "Do you have siblings?" naturally', 'Ask about family on a date', 'Share family stories briefly'], sections: [
        c.buildSection(id: c.sectionId(_m, 1, 6, 0), title: 'Date Family Talk', type: c.secConversationSim, orderIndex: 0, introduction: 'Family questions are common on dates. Be ready to share and ask!', contents: [
          c.buildContent(id: c.contentId(_m, 1, 6, 0, 0), type: c.ctText, text: 'On dates, people often ask about family to understand your background. Keep it light and positive.'),
        ], exercises: [
          c.buildExercise(id: c.exerciseId(_m, 1, 6, 0, 0), type: c.exConversationChoice, question: 'Your date asks "{do_you_have_siblings}?" You have a sister. You say:', options: ['{yes}, {i_have} {one} {sister}.', '{no}, {thank_you}.', '{i_dont_understand}.', '{the_bill_please}.'], correctAnswer: '{yes}, {i_have} {one} {sister}.', orderIndex: 0),
          c.buildExercise(id: c.exerciseId(_m, 1, 6, 0, 1), type: c.exConversationChoice, question: 'You want to ask about their family. You say:', options: ['{tell_me_about_your_family}.', '{what_is_your_name}?', '{how_much}?', '{where_is}?'], correctAnswer: '{tell_me_about_your_family}.', orderIndex: 1),
        ]),
      ]),
    ];
  }

  // =========================================================================
  // MODULE 2.2 -- Food & Drink (8 lessons)
  // =========================================================================
  static List<Map<String, dynamic>> get module2Lessons {
    final c = LearningPathConstants;
    return [
      c.buildLesson(id: c.lessonId(_m, 2, 1), title: 'Common Foods: Bread, Rice, Meat', description: 'Learn the staple foods you will encounter everywhere.', level: _level, category: c.catFoodCooking, lessonNumber: 29, weekNumber: 5, dayNumber: 2, month: _m, objectives: ['Name 10+ common foods', 'Identify food groups', 'Read simple menus'], sections: [
        c.buildSection(id: c.sectionId(_m, 2, 1, 0), title: 'Staple Foods', type: c.secVocabulary, orderIndex: 0, contents: [
          c.buildContent(id: c.contentId(_m, 2, 1, 0, 0), type: c.ctPhrase, text: '{bread}', translation: 'Bread', pronunciation: '{bread_pron}'),
          c.buildContent(id: c.contentId(_m, 2, 1, 0, 1), type: c.ctPhrase, text: '{rice}', translation: 'Rice', pronunciation: '{rice_pron}'),
          c.buildContent(id: c.contentId(_m, 2, 1, 0, 2), type: c.ctPhrase, text: '{meat}', translation: 'Meat', pronunciation: '{meat_pron}'),
          c.buildContent(id: c.contentId(_m, 2, 1, 0, 3), type: c.ctPhrase, text: '{chicken}', translation: 'Chicken', pronunciation: '{chicken_pron}'),
          c.buildContent(id: c.contentId(_m, 2, 1, 0, 4), type: c.ctPhrase, text: '{fish}', translation: 'Fish', pronunciation: '{fish_pron}'),
          c.buildContent(id: c.contentId(_m, 2, 1, 0, 5), type: c.ctPhrase, text: '{egg}', translation: 'Egg', pronunciation: '{egg_pron}'),
          c.buildContent(id: c.contentId(_m, 2, 1, 0, 6), type: c.ctPhrase, text: '{cheese}', translation: 'Cheese', pronunciation: '{cheese_pron}'),
          c.buildContent(id: c.contentId(_m, 2, 1, 0, 7), type: c.ctPhrase, text: '{pasta}', translation: 'Pasta', pronunciation: '{pasta_pron}'),
        ], exercises: [
          c.buildExercise(id: c.exerciseId(_m, 2, 1, 0, 0), type: c.exMatching, question: 'Match the food word to its image description.', options: ['{bread} -> Baked grain staple', '{rice} -> Small white grains', '{fish} -> Seafood protein'], correctAnswer: '{bread} -> Baked grain staple', orderIndex: 0),
          c.buildExercise(id: c.exerciseId(_m, 2, 1, 0, 1), type: c.exMultipleChoice, question: 'Which is a vegetarian option?', options: ['{cheese}', '{chicken}', '{fish}', '{meat}'], correctAnswer: '{cheese}', orderIndex: 1),
        ]),
      ]),
      c.buildLesson(id: c.lessonId(_m, 2, 2), title: 'Fruits & Vegetables', description: 'Fresh produce vocabulary for healthy eating and cooking talk.', level: _level, category: c.catFoodCooking, lessonNumber: 30, weekNumber: 5, dayNumber: 3, month: _m, prerequisites: [c.lessonId(_m, 2, 1)], objectives: ['Name common fruits and vegetables', 'Express food preferences', 'Describe food by color and taste'], sections: [
        c.buildSection(id: c.sectionId(_m, 2, 2, 0), title: 'Fruits & Vegetables', type: c.secVocabulary, orderIndex: 0, contents: [
          c.buildContent(id: c.contentId(_m, 2, 2, 0, 0), type: c.ctPhrase, text: '{apple}', translation: 'Apple', pronunciation: '{apple_pron}'),
          c.buildContent(id: c.contentId(_m, 2, 2, 0, 1), type: c.ctPhrase, text: '{banana}', translation: 'Banana', pronunciation: '{banana_pron}'),
          c.buildContent(id: c.contentId(_m, 2, 2, 0, 2), type: c.ctPhrase, text: '{orange}', translation: 'Orange', pronunciation: '{orange_pron}'),
          c.buildContent(id: c.contentId(_m, 2, 2, 0, 3), type: c.ctPhrase, text: '{strawberry}', translation: 'Strawberry', pronunciation: '{strawberry_pron}'),
          c.buildContent(id: c.contentId(_m, 2, 2, 0, 4), type: c.ctPhrase, text: '{tomato}', translation: 'Tomato', pronunciation: '{tomato_pron}'),
          c.buildContent(id: c.contentId(_m, 2, 2, 0, 5), type: c.ctPhrase, text: '{potato}', translation: 'Potato', pronunciation: '{potato_pron}'),
          c.buildContent(id: c.contentId(_m, 2, 2, 0, 6), type: c.ctPhrase, text: '{onion}', translation: 'Onion', pronunciation: '{onion_pron}'),
          c.buildContent(id: c.contentId(_m, 2, 2, 0, 7), type: c.ctPhrase, text: '{salad}', translation: 'Salad / Lettuce', pronunciation: '{salad_pron}'),
        ], exercises: [
          c.buildExercise(id: c.exerciseId(_m, 2, 2, 0, 0), type: c.exMultipleChoice, question: 'Which of these is a fruit?', options: ['{strawberry}', '{potato}', '{onion}', '{rice}'], correctAnswer: '{strawberry}', orderIndex: 0),
        ]),
      ]),
      c.buildLesson(id: c.lessonId(_m, 2, 3), title: 'Drinks: Water, Coffee, Tea, Juice', description: 'All the drinks you need for any occasion.', level: _level, category: c.catCafeConversations, lessonNumber: 31, weekNumber: 5, dayNumber: 4, month: _m, prerequisites: [c.lessonId(_m, 2, 2)], objectives: ['Order any common drink', 'Specify hot/cold, with/without', 'Handle drink-related conversations at cafes and bars'], sections: [
        c.buildSection(id: c.sectionId(_m, 2, 3, 0), title: 'Drink Vocabulary', type: c.secVocabulary, orderIndex: 0, contents: [
          c.buildContent(id: c.contentId(_m, 2, 3, 0, 0), type: c.ctPhrase, text: '{water}', translation: 'Water', pronunciation: '{water_pron}'),
          c.buildContent(id: c.contentId(_m, 2, 3, 0, 1), type: c.ctPhrase, text: '{coffee}', translation: 'Coffee', pronunciation: '{coffee_pron}'),
          c.buildContent(id: c.contentId(_m, 2, 3, 0, 2), type: c.ctPhrase, text: '{tea}', translation: 'Tea', pronunciation: '{tea_pron}'),
          c.buildContent(id: c.contentId(_m, 2, 3, 0, 3), type: c.ctPhrase, text: '{juice}', translation: 'Juice', pronunciation: '{juice_pron}'),
          c.buildContent(id: c.contentId(_m, 2, 3, 0, 4), type: c.ctPhrase, text: '{milk}', translation: 'Milk', pronunciation: '{milk_pron}'),
          c.buildContent(id: c.contentId(_m, 2, 3, 0, 5), type: c.ctPhrase, text: '{beer}', translation: 'Beer', pronunciation: '{beer_pron}'),
          c.buildContent(id: c.contentId(_m, 2, 3, 0, 6), type: c.ctPhrase, text: '{wine}', translation: 'Wine', pronunciation: '{wine_pron}'),
          c.buildContent(id: c.contentId(_m, 2, 3, 0, 7), type: c.ctPhrase, text: '{with_ice}', translation: 'With ice', pronunciation: '{with_ice_pron}'),
          c.buildContent(id: c.contentId(_m, 2, 3, 0, 8), type: c.ctPhrase, text: '{without_sugar}', translation: 'Without sugar', pronunciation: '{without_sugar_pron}'),
        ], exercises: [
          c.buildExercise(id: c.exerciseId(_m, 2, 3, 0, 0), type: c.exConversationChoice, question: 'It is a hot day. You order:', options: ['{water} {with_ice}, {please}.', '{coffee}, {please}.', '{tea}, {please}.', '{the_bill_please}.'], correctAnswer: '{water} {with_ice}, {please}.', orderIndex: 0),
        ]),
      ]),
      c.buildLesson(id: c.lessonId(_m, 2, 4), title: 'Ordering Food: I Would Like...', description: 'Build complete sentences to order meals.', level: _level, category: c.catRestaurantDates, lessonNumber: 32, weekNumber: 5, dayNumber: 5, month: _m, prerequisites: [c.lessonId(_m, 2, 3)], objectives: ['Form complete ordering sentences', 'Specify quantities and preferences', 'Handle the waiter interaction smoothly'], sections: [
        c.buildSection(id: c.sectionId(_m, 2, 4, 0), title: 'Ordering Phrases', type: c.secVocabulary, orderIndex: 0, contents: [
          c.buildContent(id: c.contentId(_m, 2, 4, 0, 0), type: c.ctPhrase, text: '{i_would_like}', translation: 'I would like...', pronunciation: '{i_would_like_pron}'),
          c.buildContent(id: c.contentId(_m, 2, 4, 0, 1), type: c.ctPhrase, text: '{can_i_have}', translation: 'Can I have...', pronunciation: '{can_i_have_pron}'),
          c.buildContent(id: c.contentId(_m, 2, 4, 0, 2), type: c.ctPhrase, text: '{for_me}', translation: 'For me...', pronunciation: '{for_me_pron}'),
          c.buildContent(id: c.contentId(_m, 2, 4, 0, 3), type: c.ctPhrase, text: '{and_for_you}', translation: 'And for you?', pronunciation: '{and_for_you_pron}'),
          c.buildContent(id: c.contentId(_m, 2, 4, 0, 4), type: c.ctPhrase, text: '{anything_else}', translation: 'Anything else?', pronunciation: '{anything_else_pron}'),
          c.buildContent(id: c.contentId(_m, 2, 4, 0, 5), type: c.ctPhrase, text: '{that_is_all}', translation: 'That is all, thank you.', pronunciation: '{that_is_all_pron}'),
        ], exercises: [
          c.buildExercise(id: c.exerciseId(_m, 2, 4, 0, 0), type: c.exReorderWords, question: 'Build a sentence: "{please}" / "{chicken}" / "{i_would_like}"', options: ['{i_would_like}', '{chicken}', '{please}'], correctAnswer: '{i_would_like} {chicken}, {please}.', orderIndex: 0),
          c.buildExercise(id: c.exerciseId(_m, 2, 4, 0, 1), type: c.exConversationChoice, question: 'The waiter asks "{anything_else}?" You want nothing more. You say:', options: ['{that_is_all}, {thank_you}.', '{yes}, more {bread}.', '{i_dont_understand}.', '{the_menu_please}.'], correctAnswer: '{that_is_all}, {thank_you}.', orderIndex: 1),
        ]),
      ]),
      c.buildLesson(id: c.lessonId(_m, 2, 5), title: 'Allergies and Dietary Preferences', description: 'Communicate dietary needs clearly and safely.', level: _level, category: c.catFoodCooking, lessonNumber: 33, weekNumber: 5, dayNumber: 6, month: _m, prerequisites: [c.lessonId(_m, 2, 4)], objectives: ['State food allergies', 'Express dietary preferences (vegetarian, vegan, etc.)', 'Ask about ingredients'], sections: [
        c.buildSection(id: c.sectionId(_m, 2, 5, 0), title: 'Dietary Vocabulary', type: c.secVocabulary, orderIndex: 0, introduction: 'Being able to communicate food allergies can be a matter of safety. Learn these phrases well.', contents: [
          c.buildContent(id: c.contentId(_m, 2, 5, 0, 0), type: c.ctPhrase, text: '{i_am_allergic_to}', translation: 'I am allergic to...', pronunciation: '{i_am_allergic_to_pron}'),
          c.buildContent(id: c.contentId(_m, 2, 5, 0, 1), type: c.ctPhrase, text: '{i_am_vegetarian}', translation: 'I am vegetarian', pronunciation: '{i_am_vegetarian_pron}'),
          c.buildContent(id: c.contentId(_m, 2, 5, 0, 2), type: c.ctPhrase, text: '{i_am_vegan}', translation: 'I am vegan', pronunciation: '{i_am_vegan_pron}'),
          c.buildContent(id: c.contentId(_m, 2, 5, 0, 3), type: c.ctPhrase, text: '{does_this_contain}', translation: 'Does this contain...?', pronunciation: '{does_this_contain_pron}'),
          c.buildContent(id: c.contentId(_m, 2, 5, 0, 4), type: c.ctPhrase, text: '{no_gluten}', translation: 'No gluten, please', pronunciation: '{no_gluten_pron}'),
          c.buildContent(id: c.contentId(_m, 2, 5, 0, 5), type: c.ctPhrase, text: '{nuts}', translation: 'Nuts', pronunciation: '{nuts_pron}'),
        ], exercises: [
          c.buildExercise(id: c.exerciseId(_m, 2, 5, 0, 0), type: c.exConversationChoice, question: 'You are allergic to nuts. You tell the waiter:', options: ['{i_am_allergic_to} {nuts}.', '{i_would_like} {nuts}.', '{how_much} {nuts}?', '{thank_you} {nuts}.'], correctAnswer: '{i_am_allergic_to} {nuts}.', orderIndex: 0),
        ]),
      ]),
      c.buildLesson(id: c.lessonId(_m, 2, 6), title: 'Restaurant Menu Navigation', description: 'Understand menu sections and order a complete meal.', level: _level, category: c.catRestaurantDates, lessonNumber: 34, weekNumber: 5, dayNumber: 7, month: _m, prerequisites: [c.lessonId(_m, 2, 5)], objectives: ['Identify menu sections (appetizer, main, dessert)', 'Order a complete 3-course meal', 'Role-play ordering for two people'], sections: [
        c.buildSection(id: c.sectionId(_m, 2, 6, 0), title: 'Menu Sections', type: c.secVocabulary, orderIndex: 0, contents: [
          c.buildContent(id: c.contentId(_m, 2, 6, 0, 0), type: c.ctPhrase, text: '{appetizer}', translation: 'Appetizer / Starter', pronunciation: '{appetizer_pron}'),
          c.buildContent(id: c.contentId(_m, 2, 6, 0, 1), type: c.ctPhrase, text: '{main_course}', translation: 'Main course', pronunciation: '{main_course_pron}'),
          c.buildContent(id: c.contentId(_m, 2, 6, 0, 2), type: c.ctPhrase, text: '{dessert}', translation: 'Dessert', pronunciation: '{dessert_pron}'),
          c.buildContent(id: c.contentId(_m, 2, 6, 0, 3), type: c.ctPhrase, text: '{drinks_menu}', translation: 'Drinks menu', pronunciation: '{drinks_menu_pron}'),
          c.buildContent(id: c.contentId(_m, 2, 6, 0, 4), type: c.ctPhrase, text: '{special_of_the_day}', translation: 'Special of the day', pronunciation: '{special_of_the_day_pron}'),
        ], exercises: [
          c.buildExercise(id: c.exerciseId(_m, 2, 6, 0, 0), type: c.exReorderWords, question: 'Put the meal courses in the correct order.', options: ['{dessert}', '{appetizer}', '{main_course}'], correctAnswer: '{appetizer}, {main_course}, {dessert}', orderIndex: 0),
        ]),
      ]),
      c.buildLesson(id: c.lessonId(_m, 2, 7), title: 'Restaurant Tips and Bill Splitting', description: 'Handle the end of the meal like a pro.', level: _level, category: c.catRestaurantDates, lessonNumber: 35, weekNumber: 6, dayNumber: 1, month: _m, prerequisites: [c.lessonId(_m, 2, 6)], objectives: ['Ask for the bill', 'Discuss splitting or paying', 'Understand tipping vocabulary'], sections: [
        c.buildSection(id: c.sectionId(_m, 2, 7, 0), title: 'Bill & Tipping', type: c.secVocabulary, orderIndex: 0, contents: [
          c.buildContent(id: c.contentId(_m, 2, 7, 0, 0), type: c.ctPhrase, text: '{the_bill_please}', translation: 'The bill, please', pronunciation: '{the_bill_please_pron}'),
          c.buildContent(id: c.contentId(_m, 2, 7, 0, 1), type: c.ctPhrase, text: '{can_we_split_the_bill}', translation: 'Can we split the bill?', pronunciation: '{can_we_split_the_bill_pron}'),
          c.buildContent(id: c.contentId(_m, 2, 7, 0, 2), type: c.ctPhrase, text: '{i_will_pay}', translation: 'I will pay / It is on me', pronunciation: '{i_will_pay_pron}'),
          c.buildContent(id: c.contentId(_m, 2, 7, 0, 3), type: c.ctPhrase, text: '{tip}', translation: 'Tip / Gratuity', pronunciation: '{tip_pron}'),
          c.buildContent(id: c.contentId(_m, 2, 7, 0, 4), type: c.ctPhrase, text: '{keep_the_change}', translation: 'Keep the change', pronunciation: '{keep_the_change_pron}'),
        ], exercises: [
          c.buildExercise(id: c.exerciseId(_m, 2, 7, 0, 0), type: c.exConversationChoice, question: 'You want to treat your date. You say:', options: ['{i_will_pay}!', '{can_we_split_the_bill}?', '{the_bill_please}.', '{how_much}?'], correctAnswer: '{i_will_pay}!', orderIndex: 0),
        ]),
      ]),
      c.buildLesson(id: c.lessonId(_m, 2, 8), title: 'Food Quiz: Order a Complete Meal', description: 'Test your food vocabulary with a full restaurant role-play.', level: _level, category: c.catRestaurantDates, lessonNumber: 36, weekNumber: 6, dayNumber: 2, month: _m, prerequisites: [c.lessonId(_m, 2, 7)], objectives: ['Order appetizer, main, dessert, and drinks', 'Handle dietary requests', 'Pay the bill confidently'], sections: [
        c.buildSection(id: c.sectionId(_m, 2, 8, 0), title: 'Complete Meal Order', type: c.secQuiz, orderIndex: 0, introduction: 'You are on a date. Order a full meal for both of you!', contents: [], exercises: [
          c.buildExercise(id: c.exerciseId(_m, 2, 8, 0, 0), type: c.exConversationChoice, question: 'Waiter: "{what_would_you_like_to_drink}?" You want water and wine.', options: ['{i_would_like} {water} {and} {wine}, {please}.', '{chicken}, {please}.', '{the_bill_please}.', '{good_night}!'], correctAnswer: '{i_would_like} {water} {and} {wine}, {please}.', orderIndex: 0),
          c.buildExercise(id: c.exerciseId(_m, 2, 8, 0, 1), type: c.exConversationChoice, question: 'You want the fish but need to check for nuts. You say:', options: ['{does_this_contain} {nuts}?', '{i_am_allergic_to} everything.', '{how_much} {fish}?', '{where_is} {fish}?'], correctAnswer: '{does_this_contain} {nuts}?', orderIndex: 1),
          c.buildExercise(id: c.exerciseId(_m, 2, 8, 0, 2), type: c.exConversationChoice, question: 'After a wonderful meal, you want to impress your date by paying. You say:', options: ['{i_will_pay}! {this_is_delicious}!', '{can_we_split_the_bill}?', '{goodbye}!', '{i_dont_understand}.'], correctAnswer: '{i_will_pay}! {this_is_delicious}!', orderIndex: 2),
        ], xpReward: 25),
      ]),
    ];
  }

  // =========================================================================
  // MODULE 2.3 -- Days, Months & Time (6 lessons)
  // =========================================================================
  static List<Map<String, dynamic>> get module3Lessons {
    final c = LearningPathConstants;
    return [
      c.buildLesson(id: c.lessonId(_m, 3, 1), title: 'Days of the Week', description: 'Monday through Sunday -- plan your week.', level: _level, category: c.catWeekendPlans, lessonNumber: 37, weekNumber: 6, dayNumber: 3, month: _m, objectives: ['Name all 7 days', 'Say "on Monday" etc.', 'Plan activities by day'], sections: [
        c.buildSection(id: c.sectionId(_m, 3, 1, 0), title: 'Days of the Week', type: c.secVocabulary, orderIndex: 0, contents: [
          c.buildContent(id: c.contentId(_m, 3, 1, 0, 0), type: c.ctPhrase, text: '{monday}', translation: 'Monday', pronunciation: '{monday_pron}'),
          c.buildContent(id: c.contentId(_m, 3, 1, 0, 1), type: c.ctPhrase, text: '{tuesday}', translation: 'Tuesday', pronunciation: '{tuesday_pron}'),
          c.buildContent(id: c.contentId(_m, 3, 1, 0, 2), type: c.ctPhrase, text: '{wednesday}', translation: 'Wednesday', pronunciation: '{wednesday_pron}'),
          c.buildContent(id: c.contentId(_m, 3, 1, 0, 3), type: c.ctPhrase, text: '{thursday}', translation: 'Thursday', pronunciation: '{thursday_pron}'),
          c.buildContent(id: c.contentId(_m, 3, 1, 0, 4), type: c.ctPhrase, text: '{friday}', translation: 'Friday', pronunciation: '{friday_pron}'),
          c.buildContent(id: c.contentId(_m, 3, 1, 0, 5), type: c.ctPhrase, text: '{saturday}', translation: 'Saturday', pronunciation: '{saturday_pron}'),
          c.buildContent(id: c.contentId(_m, 3, 1, 0, 6), type: c.ctPhrase, text: '{sunday}', translation: 'Sunday', pronunciation: '{sunday_pron}'),
        ], exercises: [
          c.buildExercise(id: c.exerciseId(_m, 3, 1, 0, 0), type: c.exMultipleChoice, question: 'Which day comes after {wednesday}?', options: ['{thursday}', '{tuesday}', '{friday}', '{monday}'], correctAnswer: '{thursday}', orderIndex: 0),
          c.buildExercise(id: c.exerciseId(_m, 3, 1, 0, 1), type: c.exMultipleChoice, question: 'The weekend days are:', options: ['{saturday} {and} {sunday}', '{monday} {and} {tuesday}', '{friday} {and} {monday}', '{wednesday} {and} {thursday}'], correctAnswer: '{saturday} {and} {sunday}', orderIndex: 1),
        ]),
      ]),
      c.buildLesson(id: c.lessonId(_m, 3, 2), title: 'Months of the Year', description: 'January through December and seasonal vocabulary.', level: _level, category: c.catDailyLife, lessonNumber: 38, weekNumber: 6, dayNumber: 4, month: _m, prerequisites: [c.lessonId(_m, 3, 1)], objectives: ['Name all 12 months', 'Say your birthday month', 'Discuss seasons'], sections: [
        c.buildSection(id: c.sectionId(_m, 3, 2, 0), title: 'Months and Seasons', type: c.secVocabulary, orderIndex: 0, contents: [
          c.buildContent(id: c.contentId(_m, 3, 2, 0, 0), type: c.ctPhrase, text: '{january}', translation: 'January', pronunciation: '{january_pron}'),
          c.buildContent(id: c.contentId(_m, 3, 2, 0, 1), type: c.ctPhrase, text: '{february}', translation: 'February', pronunciation: '{february_pron}'),
          c.buildContent(id: c.contentId(_m, 3, 2, 0, 2), type: c.ctPhrase, text: '{march}', translation: 'March', pronunciation: '{march_pron}'),
          c.buildContent(id: c.contentId(_m, 3, 2, 0, 3), type: c.ctPhrase, text: '{spring}', translation: 'Spring', pronunciation: '{spring_pron}'),
          c.buildContent(id: c.contentId(_m, 3, 2, 0, 4), type: c.ctPhrase, text: '{summer}', translation: 'Summer', pronunciation: '{summer_pron}'),
          c.buildContent(id: c.contentId(_m, 3, 2, 0, 5), type: c.ctPhrase, text: '{autumn}', translation: 'Autumn / Fall', pronunciation: '{autumn_pron}'),
          c.buildContent(id: c.contentId(_m, 3, 2, 0, 6), type: c.ctPhrase, text: '{winter}', translation: 'Winter', pronunciation: '{winter_pron}'),
          c.buildContent(id: c.contentId(_m, 3, 2, 0, 7), type: c.ctPhrase, text: '{my_birthday_is_in}', translation: 'My birthday is in...', pronunciation: '{my_birthday_is_in_pron}'),
        ], exercises: [
          c.buildExercise(id: c.exerciseId(_m, 3, 2, 0, 0), type: c.exFillInBlank, question: '{my_birthday_is_in} _____. (July)', options: [], correctAnswer: '{july}', orderIndex: 0),
        ]),
      ]),
      c.buildLesson(id: c.lessonId(_m, 3, 3), title: 'Telling Time: What Time Is It?', description: 'Read clocks and discuss schedules.', level: _level, category: c.catDailyLife, lessonNumber: 39, weekNumber: 6, dayNumber: 5, month: _m, prerequisites: [c.lessonId(_m, 3, 2)], objectives: ['Ask and tell the time', 'Use AM/PM or 24-hour clock', 'Schedule meetings and dates'], sections: [
        c.buildSection(id: c.sectionId(_m, 3, 3, 0), title: 'Time Phrases', type: c.secVocabulary, orderIndex: 0, contents: [
          c.buildContent(id: c.contentId(_m, 3, 3, 0, 0), type: c.ctPhrase, text: '{what_time_is_it}', translation: 'What time is it?', pronunciation: '{what_time_is_it_pron}'),
          c.buildContent(id: c.contentId(_m, 3, 3, 0, 1), type: c.ctPhrase, text: '{it_is_x_oclock}', translation: 'It is ... o\'clock', pronunciation: '{it_is_x_oclock_pron}'),
          c.buildContent(id: c.contentId(_m, 3, 3, 0, 2), type: c.ctPhrase, text: '{half_past}', translation: 'Half past...', pronunciation: '{half_past_pron}'),
          c.buildContent(id: c.contentId(_m, 3, 3, 0, 3), type: c.ctPhrase, text: '{quarter_past}', translation: 'Quarter past...', pronunciation: '{quarter_past_pron}'),
          c.buildContent(id: c.contentId(_m, 3, 3, 0, 4), type: c.ctPhrase, text: '{quarter_to}', translation: 'Quarter to...', pronunciation: '{quarter_to_pron}'),
          c.buildContent(id: c.contentId(_m, 3, 3, 0, 5), type: c.ctPhrase, text: '{at_what_time}', translation: 'At what time?', pronunciation: '{at_what_time_pron}'),
        ], exercises: [
          c.buildExercise(id: c.exerciseId(_m, 3, 3, 0, 0), type: c.exMultipleChoice, question: 'The clock shows 7:30. You say:', options: ['{half_past} {seven}', '{quarter_past} {seven}', '{seven} {it_is_x_oclock}', '{quarter_to} {eight}'], correctAnswer: '{half_past} {seven}', orderIndex: 0),
        ]),
      ]),
      c.buildLesson(id: c.lessonId(_m, 3, 4), title: 'Today, Tomorrow, Yesterday', description: 'Talk about when things happen.', level: _level, category: c.catDailyLife, lessonNumber: 40, weekNumber: 6, dayNumber: 6, month: _m, prerequisites: [c.lessonId(_m, 3, 3)], objectives: ['Use time expressions naturally', 'Plan future events', 'Describe past events simply'], sections: [
        c.buildSection(id: c.sectionId(_m, 3, 4, 0), title: 'Time Expressions', type: c.secVocabulary, orderIndex: 0, contents: [
          c.buildContent(id: c.contentId(_m, 3, 4, 0, 0), type: c.ctPhrase, text: '{today}', translation: 'Today', pronunciation: '{today_pron}'),
          c.buildContent(id: c.contentId(_m, 3, 4, 0, 1), type: c.ctPhrase, text: '{tomorrow}', translation: 'Tomorrow', pronunciation: '{tomorrow_pron}'),
          c.buildContent(id: c.contentId(_m, 3, 4, 0, 2), type: c.ctPhrase, text: '{yesterday}', translation: 'Yesterday', pronunciation: '{yesterday_pron}'),
          c.buildContent(id: c.contentId(_m, 3, 4, 0, 3), type: c.ctPhrase, text: '{this_week}', translation: 'This week', pronunciation: '{this_week_pron}'),
          c.buildContent(id: c.contentId(_m, 3, 4, 0, 4), type: c.ctPhrase, text: '{next_week}', translation: 'Next week', pronunciation: '{next_week_pron}'),
          c.buildContent(id: c.contentId(_m, 3, 4, 0, 5), type: c.ctPhrase, text: '{last_week}', translation: 'Last week', pronunciation: '{last_week_pron}'),
          c.buildContent(id: c.contentId(_m, 3, 4, 0, 6), type: c.ctPhrase, text: '{this_weekend}', translation: 'This weekend', pronunciation: '{this_weekend_pron}'),
        ], exercises: [
          c.buildExercise(id: c.exerciseId(_m, 3, 4, 0, 0), type: c.exConversationChoice, question: 'You want to set up a date for Saturday. You say:', options: ['{are_you_free} {this_weekend}?', '{yesterday} was fun!', '{what_time_is_it}?', '{goodbye}!'], correctAnswer: '{are_you_free} {this_weekend}?', orderIndex: 0),
        ]),
      ]),
      c.buildLesson(id: c.lessonId(_m, 3, 5), title: 'Weather Basics', description: 'Talk about the weather -- the universal conversation starter.', level: _level, category: c.catDailyLife, lessonNumber: 41, weekNumber: 6, dayNumber: 7, month: _m, prerequisites: [c.lessonId(_m, 3, 4)], objectives: ['Describe basic weather conditions', 'Ask about the weather', 'Use weather as a conversation starter'], sections: [
        c.buildSection(id: c.sectionId(_m, 3, 5, 0), title: 'Weather Vocabulary', type: c.secVocabulary, orderIndex: 0, contents: [
          c.buildContent(id: c.contentId(_m, 3, 5, 0, 0), type: c.ctPhrase, text: '{sunny}', translation: 'Sunny', pronunciation: '{sunny_pron}'),
          c.buildContent(id: c.contentId(_m, 3, 5, 0, 1), type: c.ctPhrase, text: '{rainy}', translation: 'Rainy', pronunciation: '{rainy_pron}'),
          c.buildContent(id: c.contentId(_m, 3, 5, 0, 2), type: c.ctPhrase, text: '{cloudy}', translation: 'Cloudy', pronunciation: '{cloudy_pron}'),
          c.buildContent(id: c.contentId(_m, 3, 5, 0, 3), type: c.ctPhrase, text: '{cold}', translation: 'Cold', pronunciation: '{cold_pron}'),
          c.buildContent(id: c.contentId(_m, 3, 5, 0, 4), type: c.ctPhrase, text: '{hot}', translation: 'Hot', pronunciation: '{hot_pron}'),
          c.buildContent(id: c.contentId(_m, 3, 5, 0, 5), type: c.ctPhrase, text: '{nice_weather_today}', translation: 'Nice weather today!', pronunciation: '{nice_weather_today_pron}'),
          c.buildContent(id: c.contentId(_m, 3, 5, 0, 6), type: c.ctPhrase, text: '{what_is_the_weather_like}', translation: 'What is the weather like?', pronunciation: '{what_is_the_weather_like_pron}'),
        ], exercises: [
          c.buildExercise(id: c.exerciseId(_m, 3, 5, 0, 0), type: c.exMultipleChoice, question: 'The sun is shining and it is warm. The weather is:', options: ['{sunny} {and} {hot}', '{rainy} {and} {cold}', '{cloudy}', '{cold}'], correctAnswer: '{sunny} {and} {hot}', orderIndex: 0),
        ]),
      ]),
      c.buildLesson(id: c.lessonId(_m, 3, 6), title: 'Time & Calendar Review', description: 'Put together days, months, time, and weather.', level: _level, category: c.catDailyLife, lessonNumber: 42, weekNumber: 7, dayNumber: 1, month: _m, prerequisites: [c.lessonId(_m, 3, 5)], objectives: ['Schedule a date using day, time, and place', 'Discuss seasonal activities', 'Handle planning conversations'], sections: [
        c.buildSection(id: c.sectionId(_m, 3, 6, 0), title: 'Planning a Date Quiz', type: c.secQuiz, orderIndex: 0, introduction: 'Use everything you learned to plan a perfect date!', contents: [], exercises: [
          c.buildExercise(id: c.exerciseId(_m, 3, 6, 0, 0), type: c.exConversationChoice, question: 'You want to meet on Saturday at 7 PM. You say:', options: ['{are_you_free} {saturday} {at} {seven}?', '{yesterday} {at} {seven}?', '{monday} {at} {seven}?', '{what_time_is_it}?'], correctAnswer: '{are_you_free} {saturday} {at} {seven}?', orderIndex: 0),
          c.buildExercise(id: c.exerciseId(_m, 3, 6, 0, 1), type: c.exFillInBlank, question: 'It is raining. Let us go to a movie _____. (instead of the park)', options: [], correctAnswer: '{instead}', hint: 'What word means "as an alternative"?', orderIndex: 1),
          c.buildExercise(id: c.exerciseId(_m, 3, 6, 0, 2), type: c.exTranslation, question: 'Translate: "See you tomorrow at 8!"', options: [], correctAnswer: '{see_you_tomorrow} {at} {eight}!', orderIndex: 2),
        ], xpReward: 25),
      ]),
    ];
  }

  // =========================================================================
  // FLASHCARD DECK -- "Month 2 Daily Life" (90 cards)
  // =========================================================================
  static List<Map<String, dynamic>> get flashcards {
    final c = LearningPathConstants;
    return [
      // Family (15 cards)
      c.buildFlashcard(id: c.flashcardId(_m, 0), front: '{mother}', back: 'Mother', exampleSentence: '{my_mother_is} {kind}.', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 1), front: '{father}', back: 'Father', exampleSentence: '{my_father_is} {tall}.', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 2), front: '{brother}', back: 'Brother', exampleSentence: '{i_have} {one} {brother}.', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 3), front: '{sister}', back: 'Sister', exampleSentence: '{my} {sister} is {funny}.', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 4), front: '{grandmother}', back: 'Grandmother', exampleSentence: '{my} {grandmother} cooks well.', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 5), front: '{grandfather}', back: 'Grandfather', exampleSentence: '{my} {grandfather} tells stories.', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 6), front: '{friend}', back: 'Friend', exampleSentence: '{this_is_my} {best_friend}.', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 7), front: '{boyfriend}', back: 'Boyfriend', exampleSentence: '{this_is_my} {boyfriend}.', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 8), front: '{girlfriend}', back: 'Girlfriend', exampleSentence: '{this_is_my} {girlfriend}.', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 9), front: '{partner}', back: 'Partner', exampleSentence: '{this_is_my} {partner}.', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 10), front: '{kind}', back: 'Kind / Nice', exampleSentence: 'She is very {kind}.', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 11), front: '{funny}', back: 'Funny', exampleSentence: 'He is so {funny}!', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 12), front: '{smart}', back: 'Smart', exampleSentence: 'She is very {smart}.', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 13), front: '{do_you_have_siblings}', back: 'Do you have siblings?', exampleSentence: '{do_you_have_siblings}?', category: 'conversationStarters', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 14), front: '{tell_me_about_your_family}', back: 'Tell me about your family', exampleSentence: '{tell_me_about_your_family}!', category: 'conversationStarters', difficulty: 'beginner'),

      // Food (30 cards)
      c.buildFlashcard(id: c.flashcardId(_m, 15), front: '{bread}', back: 'Bread', exampleSentence: 'More {bread}, {please}.', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 16), front: '{rice}', back: 'Rice', exampleSentence: '{chicken} with {rice}.', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 17), front: '{meat}', back: 'Meat', exampleSentence: 'I don\'t eat {meat}.', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 18), front: '{chicken}', back: 'Chicken', exampleSentence: '{i_would_like} {chicken}.', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 19), front: '{fish}', back: 'Fish', exampleSentence: 'The {fish} is fresh.', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 20), front: '{egg}', back: 'Egg', exampleSentence: '{two} {egg}s, {please}.', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 21), front: '{cheese}', back: 'Cheese', exampleSentence: 'With {cheese}, {please}.', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 22), front: '{apple}', back: 'Apple', exampleSentence: '{one} {apple}, {please}.', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 23), front: '{banana}', back: 'Banana', exampleSentence: 'I like {banana}s.', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 24), front: '{tomato}', back: 'Tomato', exampleSentence: '{salad} with {tomato}.', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 25), front: '{potato}', back: 'Potato', exampleSentence: '{chicken} with {potato}.', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 26), front: '{i_am_vegetarian}', back: 'I am vegetarian', exampleSentence: '{i_am_vegetarian}. {no} {meat}, {please}.', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 27), front: '{i_am_allergic_to}', back: 'I am allergic to...', exampleSentence: '{i_am_allergic_to} {nuts}.', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 28), front: '{appetizer}', back: 'Appetizer', exampleSentence: '{for_me}, the {salad} as an {appetizer}.', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 29), front: '{main_course}', back: 'Main course', exampleSentence: 'For the {main_course}, {chicken}.', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 30), front: '{dessert}', back: 'Dessert', exampleSentence: 'What {dessert}s do you have?', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 31), front: '{can_we_split_the_bill}', back: 'Can we split the bill?', exampleSentence: '{can_we_split_the_bill}?', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 32), front: '{i_will_pay}', back: 'I will pay / It is on me', exampleSentence: '{i_will_pay}! My treat.', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 33), front: '{keep_the_change}', back: 'Keep the change', exampleSentence: '{thank_you}. {keep_the_change}.', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 34), front: '{juice}', back: 'Juice', exampleSentence: 'Orange {juice}, {please}.', category: 'travelCulture', difficulty: 'beginner'),

      // Days, Months, Time (30 cards)
      c.buildFlashcard(id: c.flashcardId(_m, 35), front: '{monday}', back: 'Monday', exampleSentence: 'See you on {monday}!', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 36), front: '{tuesday}', back: 'Tuesday', exampleSentence: '{tuesday} is good for me.', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 37), front: '{wednesday}', back: 'Wednesday', exampleSentence: 'How about {wednesday}?', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 38), front: '{thursday}', back: 'Thursday', exampleSentence: '{thursday} works!', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 39), front: '{friday}', back: 'Friday', exampleSentence: '{friday} night!', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 40), front: '{saturday}', back: 'Saturday', exampleSentence: '{are_you_free} {saturday}?', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 41), front: '{sunday}', back: 'Sunday', exampleSentence: 'Lazy {sunday}.', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 42), front: '{january}', back: 'January', exampleSentence: '{my_birthday_is_in} {january}.', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 43), front: '{spring}', back: 'Spring', exampleSentence: 'I love {spring}!', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 44), front: '{summer}', back: 'Summer', exampleSentence: '{summer} is {hot}!', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 45), front: '{winter}', back: 'Winter', exampleSentence: '{winter} is {cold}.', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 46), front: '{what_time_is_it}', back: 'What time is it?', exampleSentence: '{excuse_me}, {what_time_is_it}?', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 47), front: '{today}', back: 'Today', exampleSentence: '{today} is {monday}.', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 48), front: '{tomorrow}', back: 'Tomorrow', exampleSentence: '{see_you_tomorrow}!', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 49), front: '{yesterday}', back: 'Yesterday', exampleSentence: '{yesterday} was fun!', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 50), front: '{this_weekend}', back: 'This weekend', exampleSentence: '{are_you_free} {this_weekend}?', category: 'datePlanning', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 51), front: '{sunny}', back: 'Sunny', exampleSentence: 'It is {sunny} {today}!', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 52), front: '{rainy}', back: 'Rainy', exampleSentence: 'It is {rainy}. Stay inside?', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 53), front: '{cold}', back: 'Cold', exampleSentence: 'It is {cold} {today}.', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 54), front: '{hot}', back: 'Hot', exampleSentence: 'It is very {hot}!', category: 'casual', difficulty: 'beginner'),

      // Extra food/drink (35 cards)
      c.buildFlashcard(id: c.flashcardId(_m, 55), front: '{milk}', back: 'Milk', exampleSentence: '{coffee} with {milk}.', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 56), front: '{sugar}', back: 'Sugar', exampleSentence: '{without_sugar}, {please}.', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 57), front: '{salt}', back: 'Salt', exampleSentence: 'More {salt}, {please}.', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 58), front: '{pepper}', back: 'Pepper', exampleSentence: '{salt} {and} {pepper}.', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 59), front: '{soup}', back: 'Soup', exampleSentence: '{i_would_like} {soup}.', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 60), front: '{fruit}', back: 'Fruit', exampleSentence: 'Fresh {fruit} for {dessert}.', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 61), front: '{vegetables}', back: 'Vegetables', exampleSentence: 'With {vegetables}, {please}.', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 62), front: '{ice_cream}', back: 'Ice cream', exampleSentence: '{ice_cream} for {dessert}!', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 63), front: '{cake}', back: 'Cake', exampleSentence: 'Chocolate {cake}, {please}.', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 64), front: '{chocolate}', back: 'Chocolate', exampleSentence: 'I love {chocolate}!', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 65), front: '{breakfast}', back: 'Breakfast', exampleSentence: '{what_time_is_breakfast}?', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 66), front: '{lunch}', back: 'Lunch', exampleSentence: '{lunch} at noon.', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 67), front: '{dinner}', back: 'Dinner', exampleSentence: '{dinner} at {eight}.', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 68), front: '{hungry}', back: 'Hungry', exampleSentence: 'I am {hungry}!', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 69), front: '{thirsty}', back: 'Thirsty', exampleSentence: 'I am {thirsty}.', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 70), front: '{delicious}', back: 'Delicious', exampleSentence: '{this_is_delicious}!', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 71), front: '{spicy}', back: 'Spicy', exampleSentence: 'This is very {spicy}!', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 72), front: '{sweet}', back: 'Sweet', exampleSentence: 'This {dessert} is {sweet}.', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 73), front: '{sour}', back: 'Sour', exampleSentence: 'This lemon is {sour}.', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 74), front: '{bitter}', back: 'Bitter', exampleSentence: '{coffee} {without_sugar} is {bitter}.', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 75), front: '{i_like}', back: 'I like...', exampleSentence: '{i_like} {chocolate}.', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 76), front: '{i_dont_like}', back: 'I don\'t like...', exampleSentence: '{i_dont_like} {spicy} food.', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 77), front: '{i_love}', back: 'I love... (for things)', exampleSentence: '{i_love} {ice_cream}!', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 78), front: '{half_past}', back: 'Half past...', exampleSentence: 'It is {half_past} {seven}.', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 79), front: '{at_what_time}', back: 'At what time?', exampleSentence: '{at_what_time} is dinner?', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 80), front: '{this_week}', back: 'This week', exampleSentence: 'Are you busy {this_week}?', category: 'datePlanning', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 81), front: '{next_week}', back: 'Next week', exampleSentence: 'Let us meet {next_week}.', category: 'datePlanning', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 82), front: '{nice_weather_today}', back: 'Nice weather today!', exampleSentence: '{nice_weather_today}! Let us go for a walk.', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 83), front: '{does_this_contain}', back: 'Does this contain...?', exampleSentence: '{does_this_contain} {nuts}?', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 84), front: '{for_me}', back: 'For me...', exampleSentence: '{for_me}, the {chicken}, {please}.', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 85), front: '{that_is_all}', back: 'That is all', exampleSentence: '{that_is_all}, {thank_you}.', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 86), front: '{special_of_the_day}', back: 'Special of the day', exampleSentence: 'What is the {special_of_the_day}?', category: 'travelCulture', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 87), front: '{are_you_free}', back: 'Are you free?', exampleSentence: '{are_you_free} {this_weekend}?', category: 'datePlanning', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 88), front: '{let_us_go}', back: 'Let us go / Let\'s go', exampleSentence: '{let_us_go} to the restaurant!', category: 'casual', difficulty: 'beginner'),
      c.buildFlashcard(id: c.flashcardId(_m, 89), front: '{i_am_hungry}', back: 'I am hungry', exampleSentence: '{i_am_hungry}! {let_us_go} eat.', category: 'casual', difficulty: 'beginner'),
    ];
  }

  // =========================================================================
  // CULTURAL QUIZ -- "Food Culture Worldwide"
  // =========================================================================
  static Map<String, dynamic> get culturalQuiz {
    final c = LearningPathConstants;
    return c.buildCulturalQuiz(
      id: c.quizId(_m),
      title: 'Food Culture Worldwide',
      description: 'Discover how different cultures approach food, dining, and table manners.',
      difficulty: 'easy',
      questions: [
        c.buildQuizQuestion(id: c.quizQuestionId(_m, 1, 1), question: 'In Italy, what time is dinner typically served?', options: ['5:00 PM', '6:00 PM', '8:00 - 9:00 PM', '11:00 PM'], correctOptionIndex: 2, explanation: 'Italians eat dinner between 8 and 9 PM. Lunch is the bigger meal, around 1 PM.'),
        c.buildQuizQuestion(id: c.quizQuestionId(_m, 1, 2), question: 'What is considered rude when eating sushi in Japan?', options: ['Using chopsticks', 'Mixing wasabi into soy sauce', 'Eating with your hands', 'Drinking soup from the bowl'], correctOptionIndex: 1, explanation: 'Mixing wasabi into soy sauce is considered disrespectful to the chef. Dab wasabi on the sushi directly.'),
        c.buildQuizQuestion(id: c.quizQuestionId(_m, 1, 3), question: 'In South Korea, who should start eating first at a group meal?', options: ['The youngest person', 'The eldest person', 'The host', 'Anyone can start'], correctOptionIndex: 1, explanation: 'In Korean culture, the eldest person at the table should begin eating first.'),
        c.buildQuizQuestion(id: c.quizQuestionId(_m, 1, 4), question: 'In France, what is typically eaten for breakfast?', options: ['A full English breakfast', 'Croissant and coffee', 'Rice and fish', 'Soup'], correctOptionIndex: 1, explanation: 'The French petit-dejeuner is light: a croissant or bread with butter and jam, plus coffee.'),
        c.buildQuizQuestion(id: c.quizQuestionId(_m, 1, 5), question: 'In which country is it polite to leave a little food on your plate to show you are satisfied?', options: ['Japan', 'China', 'France', 'Germany'], correctOptionIndex: 1, explanation: 'In China, leaving a small amount of food shows the host provided more than enough.'),
        c.buildQuizQuestion(id: c.quizQuestionId(_m, 1, 6), question: 'Tipping is NOT customary in which country?', options: ['United States', 'Japan', 'France', 'Mexico'], correctOptionIndex: 1, explanation: 'In Japan, tipping is not customary and can even be considered rude. Good service is the standard.'),
        c.buildQuizQuestion(id: c.quizQuestionId(_m, 1, 7), question: 'What is "tapas" in Spanish dining culture?', options: ['A main course', 'Small shared dishes', 'A dessert', 'A drink'], correctOptionIndex: 1, explanation: 'Tapas are small dishes shared among friends, perfect for socializing over food and drinks.'),
        c.buildQuizQuestion(id: c.quizQuestionId(_m, 1, 8), question: 'In India, which hand should you eat with?', options: ['Left hand', 'Right hand', 'Either hand', 'Both hands'], correctOptionIndex: 1, explanation: 'In India, the right hand is used for eating. The left hand is considered impure.'),
      ],
    );
  }

  // =========================================================================
  // Aggregate
  // =========================================================================
  static List<Map<String, dynamic>> get allLessons =>
      [...module1Lessons, ...module2Lessons, ...module3Lessons];

  static int get totalLessonCount => allLessons.length;
  static int get totalFlashcardCount => flashcards.length;
}
