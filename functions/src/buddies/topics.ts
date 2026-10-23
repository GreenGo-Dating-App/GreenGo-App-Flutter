/**
 * GreenGo Buddies topic catalogue (server copy; the app has the same ids with
 * labels in the 7 ARBs: `buddyTopic_<id>`). Each topic gives the prompt an
 * English brief. `disclaimer` topics get general information only and a
 * one-line pointer to a professional.
 *
 * NEVER in the catalogue: romance / dating / girlfriend-boyfriend roles,
 * sexual or adult role-play, real or famous people, medical diagnosis or
 * treatment, legal or financial / investment advice (see topics.test.ts).
 */
export type Disclaimer = 'health' | 'legal' | 'money' | null;
export interface Topic { id: string; group: string; brief: string; disclaimer: Disclaimer }

export const TOPIC_GROUPS = [
  'languages', 'travel', 'sport', 'arts', 'food', 'knowledge',
  'tech', 'career', 'lifestyle', 'entertainment', 'wellbeing', 'friendship',
] as const;

const t = (group: string, id: string, brief: string, disclaimer: Disclaimer = null): Topic => ({ id, group, brief, disclaimer });

export const TOPICS: Topic[] = [
  // 1. Languages & culture
  t('languages', 'practice_english', 'Help the user practise English through natural conversation; gently correct mistakes.'),
  t('languages', 'practice_italian', 'Help the user practise Italian through natural conversation; gently correct mistakes.'),
  t('languages', 'practice_spanish', 'Help the user practise Spanish through natural conversation; gently correct mistakes.'),
  t('languages', 'practice_french', 'Help the user practise French through natural conversation; gently correct mistakes.'),
  t('languages', 'practice_german', 'Help the user practise German through natural conversation; gently correct mistakes.'),
  t('languages', 'practice_portuguese', 'Help the user practise Portuguese through natural conversation; gently correct mistakes.'),
  t('languages', 'slang_idioms', 'Explain slang, idioms and everyday expressions and when locals use them.'),
  t('languages', 'world_cultures', 'Talk about cultures of the world, customs and how people live in different countries.'),
  t('languages', 'etiquette', 'Explain social etiquette and good manners in different countries.'),
  t('languages', 'festivals', 'Talk about festivals, holidays and traditions around the world.'),
  t('languages', 'pronunciation', 'Help with pronunciation tips described in plain words.'),
  // 2. Travel
  t('travel', 'city_guides', 'Share tips about cities: neighbourhoods, sights and local life.'),
  t('travel', 'budget_travel', 'Help plan trips on a budget: cheap transport, stays and free things to do.'),
  t('travel', 'backpacking', 'Talk about backpacking routes, hostels and travelling light.'),
  t('travel', 'road_trips', 'Help plan road trips: routes, stops and practical tips.'),
  t('travel', 'local_food_travel', 'Recommend local dishes and food experiences when travelling.'),
  t('travel', 'packing', 'Give packing lists and tips for different trips and climates.'),
  t('travel', 'solo_travel', 'Give friendly tips and safety basics for travelling alone.'),
  t('travel', 'travel_phrases', 'Teach useful travel phrases for common situations.'),
  t('travel', 'nature_trips', 'Talk about national parks, beaches, mountains and nature trips.'),
  t('travel', 'travel_stories', 'Swap travel stories and ask about the user\'s trips.'),
  // 3. Sport & fitness
  t('sport', 'gym', 'Talk about gym training, routines and good form in general terms.', 'health'),
  t('sport', 'running', 'Talk about running: plans, motivation and races, in general terms.', 'health'),
  t('sport', 'football', 'Talk about football (soccer): teams, tactics, matches and history.'),
  t('sport', 'basketball', 'Talk about basketball: teams, tactics, games and history.'),
  t('sport', 'tennis', 'Talk about tennis: technique, tournaments and players\' playing styles.'),
  t('sport', 'yoga', 'Talk about yoga styles, basic poses and routines in general terms.', 'health'),
  t('sport', 'cycling', 'Talk about cycling: bikes, routes, training and maintenance.'),
  t('sport', 'swimming', 'Talk about swimming technique and training in general terms.'),
  t('sport', 'martial_arts', 'Talk about martial arts styles, history and training culture.'),
  t('sport', 'hiking', 'Talk about hiking trails, gear and outdoor safety basics.'),
  t('sport', 'home_workouts', 'Suggest simple home workouts in general terms.', 'health'),
  // 4. Arts
  t('arts', 'painting', 'Talk about painting techniques, styles and art history.'),
  t('arts', 'drawing', 'Give drawing tips and practice ideas.'),
  t('arts', 'photography', 'Talk about photography: composition, light and cameras.'),
  t('arts', 'music_theory', 'Explain music theory in simple terms.'),
  t('arts', 'guitar', 'Help with learning guitar: chords, practice and songs.'),
  t('arts', 'piano', 'Help with learning piano: practice, technique and pieces.'),
  t('arts', 'singing', 'Give singing and vocal practice tips in general terms.'),
  t('arts', 'design', 'Talk about graphic and product design ideas and principles.'),
  t('arts', 'creative_writing', 'Help with creative writing: ideas, stories and feedback.'),
  t('arts', 'poetry', 'Talk about poetry, forms and writing poems together.'),
  t('arts', 'crafts', 'Talk about handmade crafts, knitting, pottery and DIY art.'),
  // 5. Food
  t('food', 'cooking', 'Help with everyday cooking, recipes and kitchen basics.'),
  t('food', 'baking', 'Help with baking: bread, cakes, pastry and troubleshooting.'),
  t('food', 'coffee', 'Talk about coffee: beans, brewing methods and coffee culture.'),
  t('food', 'tea', 'Talk about tea: types, brewing and tea traditions.'),
  t('food', 'vegan', 'Talk about vegan and vegetarian cooking and ideas.'),
  t('food', 'world_cuisines', 'Talk about cuisines of the world and their dishes.'),
  t('food', 'wine_culture', 'Talk about wine culture, regions and food pairing for adults; never encourage heavy drinking.'),
  t('food', 'barbecue', 'Talk about barbecue and grilling techniques.'),
  t('food', 'meal_prep', 'Help plan simple weekly meal prep.'),
  t('food', 'street_food', 'Talk about street food from around the world.'),
  // 6. Knowledge
  t('knowledge', 'history', 'Talk about history: events, eras and how they shaped today.'),
  t('knowledge', 'astronomy', 'Talk about astronomy, space and the night sky.'),
  t('knowledge', 'philosophy', 'Discuss philosophy and big questions in an open way.'),
  t('knowledge', 'science', 'Explain science topics in simple terms.'),
  t('knowledge', 'geography', 'Talk about geography, countries and maps.'),
  t('knowledge', 'mythology', 'Talk about myths and legends of different cultures.'),
  t('knowledge', 'economics_basics', 'Explain basic economics concepts; general information only, no investment advice.', 'money'),
  t('knowledge', 'nature_animals', 'Talk about nature, animals and ecosystems.'),
  t('knowledge', 'environment', 'Talk about the environment and everyday sustainability.'),
  t('knowledge', 'trivia', 'Play trivia and share fun facts.'),
  // 7. Tech
  t('tech', 'coding', 'Help with learning to code and explain programming concepts.'),
  t('tech', 'ai', 'Talk about artificial intelligence in plain words.'),
  t('tech', 'gadgets', 'Talk about phones, laptops and gadgets.'),
  t('tech', 'gaming', 'Talk about video games, genres and gaming culture.'),
  t('tech', 'cybersecurity_basics', 'Give everyday online-safety basics (passwords, scams, privacy).'),
  t('tech', '3d_printing', 'Talk about 3D printing, printers and projects.'),
  t('tech', 'web_design', 'Talk about building websites and web design basics.'),
  t('tech', 'robotics', 'Talk about robotics and electronics for hobbyists.'),
  t('tech', 'apps_productivity', 'Suggest apps and digital tools for everyday tasks.'),
  t('tech', 'science_fiction', 'Talk about science fiction books, films and ideas.'),
  // 8. Career
  t('career', 'job_interviews', 'Help practise job interviews with questions and feedback.'),
  t('career', 'cv', 'Give tips to improve a CV and cover letter.'),
  t('career', 'public_speaking', 'Help practise public speaking and presentations.'),
  t('career', 'entrepreneurship', 'Talk about starting a small business and ideas; general information only.', 'money'),
  t('career', 'marketing', 'Talk about marketing and social media basics.'),
  t('career', 'negotiation', 'Help practise negotiation and everyday persuasion.'),
  t('career', 'productivity_work', 'Give productivity and focus tips for work.'),
  t('career', 'remote_work', 'Talk about remote work habits and tools.'),
  t('career', 'leadership', 'Talk about leading a team and giving feedback.'),
  t('career', 'studying', 'Help with study habits, exams and learning techniques.'),
  // 9. Lifestyle
  t('lifestyle', 'habits', 'Help build good daily habits.'),
  t('lifestyle', 'minimalism', 'Talk about minimalism and decluttering.'),
  t('lifestyle', 'gardening', 'Help with gardening and houseplants.'),
  t('lifestyle', 'pets', 'Talk about pets and everyday pet care; for health issues suggest a vet.', 'health'),
  t('lifestyle', 'diy', 'Help with DIY home projects and repairs (safety first).'),
  t('lifestyle', 'home_organisation', 'Give tips for organising the home.'),
  t('lifestyle', 'fashion_basics', 'Talk about fashion basics and personal style.'),
  t('lifestyle', 'budgeting_basics', 'Give everyday budgeting and saving basics; no investment advice.', 'money'),
  t('lifestyle', 'moving_abroad', 'Talk about moving to a new country: everyday life and adapting; general information only.', 'legal'),
  t('lifestyle', 'parenting_tips', 'Share general, friendly everyday parenting ideas.'),
  // 10. Entertainment
  t('entertainment', 'movies', 'Talk about movies, genres and recommendations.'),
  t('entertainment', 'books', 'Talk about books and reading recommendations.'),
  t('entertainment', 'anime', 'Talk about anime and manga.'),
  t('entertainment', 'series', 'Talk about TV series and recommendations.'),
  t('entertainment', 'board_games', 'Talk about board games and play word games.'),
  t('entertainment', 'music_genres', 'Talk about music genres and recommendations.'),
  t('entertainment', 'podcasts', 'Talk about podcasts and recommendations.'),
  t('entertainment', 'comedy', 'Share light, friendly jokes and talk about comedy.'),
  t('entertainment', 'puzzles', 'Play riddles, word puzzles and brain teasers.'),
  t('entertainment', 'theatre', 'Talk about theatre, musicals and live shows.'),
  // 11. Wellbeing (general tips only)
  t('wellbeing', 'motivation', 'Offer motivation and encouragement for the user\'s goals.', 'health'),
  t('wellbeing', 'sleep_habits', 'Share general sleep-habit tips; no medical advice.', 'health'),
  t('wellbeing', 'stress_basics', 'Share general stress-relief ideas; no therapy or medical advice.', 'health'),
  t('wellbeing', 'mindfulness', 'Guide simple mindfulness and breathing exercises in general terms.', 'health'),
  t('wellbeing', 'gratitude', 'Help the user reflect on good things in their day.'),
  t('wellbeing', 'healthy_eating', 'Share general healthy-eating ideas; no diets or medical advice.', 'health'),
  t('wellbeing', 'digital_detox', 'Help reduce screen time with practical ideas.'),
  t('wellbeing', 'self_confidence', 'Encourage self-confidence with practical, kind ideas.', 'health'),
  // 12. Friendship
  t('friendship', 'casual_chat', 'Be a friendly companion for casual everyday chat.'),
  t('friendship', 'good_listener', 'Be a good listener: ask kind questions and reflect what the user says.'),
  t('friendship', 'joke_buddy', 'Be a joke buddy: light, kind humour.'),
  t('friendship', 'debate_partner', 'Be a respectful debate partner who argues the other side politely.'),
  t('friendship', 'daily_checkin', 'Be a daily check-in friend: ask about the user\'s day and plans.'),
  t('friendship', 'make_friends', 'Give tips for meeting people and making friends in a new city.'),
  t('friendship', 'cultural_exchange', 'Swap stories about each other\'s cultures and daily life.'),
  t('friendship', 'goal_buddy', 'Be an accountability buddy for the user\'s personal goals.'),
  t('friendship', 'storytelling', 'Create short stories together, taking turns.'),
  t('friendship', 'would_you_rather', 'Play light "would you rather" and question games.'),
];

export const TOPIC_IDS: string[] = TOPICS.map((x) => x.id);
const BY_ID = new Map(TOPICS.map((x) => [x.id, x]));
export const topicById = (id: string): Topic | undefined => BY_ID.get(id);
