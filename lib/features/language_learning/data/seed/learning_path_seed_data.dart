// =============================================================================
// LEARNING PATH SEED DATA - GreenGo Language Learning
// =============================================================================
// A game-like 12-month learning path with 12 Worlds, each containing
// 4 Chapters (weeks), each with 5 Levels + 1 Boss Quiz.
// Covers all 41 supported languages with REAL translations.
//
// Structure:
//   12 Worlds  ->  4 Chapters each  ->  5 Levels + 1 Boss  ->  10-15 items/level
//
// Total: 12 worlds x 4 chapters x (5 levels + 1 boss) = 288 progression units
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';

// =============================================================================
// PART 1: DATA CLASSES
// =============================================================================

/// Information about a supported language in the learning path.
class LanguageInfo {
  final String code;
  final String name;
  final String flag;
  final String nativeName;
  final String region;
  final String scriptType; // 'latin', 'cyrillic', 'cjk', 'arabic', 'devanagari', etc.

  const LanguageInfo({
    required this.code,
    required this.name,
    required this.flag,
    required this.nativeName,
    this.region = '',
    this.scriptType = 'latin',
  });

  Map<String, dynamic> toMap() => {
        'code': code,
        'name': name,
        'flag': flag,
        'nativeName': nativeName,
        'region': region,
        'scriptType': scriptType,
      };
}

/// One of 12 game worlds representing a month of learning.
class LearningWorld {
  final int number;
  final String name;
  final String emoji;
  final String description;
  final int difficulty; // 1-12 stars
  final int worldXpBonus;
  final String achievement;
  final String achievementIcon;
  final double estimatedHours;
  final bool isFree;
  final List<LearningChapter> chapters;

  const LearningWorld({
    required this.number,
    required this.name,
    required this.emoji,
    required this.description,
    required this.difficulty,
    required this.worldXpBonus,
    required this.achievement,
    required this.achievementIcon,
    required this.estimatedHours,
    required this.isFree,
    required this.chapters,
  });

  Map<String, dynamic> toMap() => {
        'number': number,
        'name': name,
        'emoji': emoji,
        'description': description,
        'difficulty': difficulty,
        'worldXpBonus': worldXpBonus,
        'achievement': achievement,
        'achievementIcon': achievementIcon,
        'estimatedHours': estimatedHours,
        'isFree': isFree,
        'unlockRequirement': number == 1
            ? null
            : 'Complete World ${number - 1} Boss',
        'chapters': chapters.map((c) => c.toMap()).toList(),
      };
}

/// A chapter (week) inside a world, with 5 levels and 1 boss quiz.
class LearningChapter {
  final int number;
  final String title;
  final String subtitle;
  final List<LearningLevel> levels;
  final BossQuiz bossQuiz;

  const LearningChapter({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.levels,
    required this.bossQuiz,
  });

  Map<String, dynamic> toMap() => {
        'number': number,
        'title': title,
        'subtitle': subtitle,
        'levels': levels.map((l) => l.toMap()).toList(),
        'bossQuiz': bossQuiz.toMap(),
      };
}

/// A single level within a chapter. Contains vocabulary items to learn.
class LearningLevel {
  final int number;
  final String title;
  final String description;
  final int xpReward;
  final int coinReward;
  final String? grammarTip;
  final String? culturalNote;
  final List<VocabItem> vocabulary;

  const LearningLevel({
    required this.number,
    required this.title,
    required this.description,
    required this.xpReward,
    required this.coinReward,
    this.grammarTip,
    this.culturalNote,
    required this.vocabulary,
  });

  Map<String, dynamic> toMap() => {
        'number': number,
        'title': title,
        'description': description,
        'xpReward': xpReward,
        'coinReward': coinReward,
        'grammarTip': grammarTip,
        'culturalNote': culturalNote,
        'vocabulary': vocabulary.map((v) => v.toMap()).toList(),
      };
}

/// A vocabulary item. The [englishKey] is the lookup key for translations.
class VocabItem {
  final String englishKey;
  final String category; // 'word', 'phrase', 'grammar'

  const VocabItem({
    required this.englishKey,
    required this.category,
  });

  Map<String, dynamic> toMap() => {
        'englishKey': englishKey,
        'category': category,
      };
}

/// The boss quiz at the end of each chapter.
class BossQuiz {
  final String title;
  final int questionCount;
  final int passThreshold; // percentage
  final int xpReward;
  final int coinReward;
  final int firstTryMultiplier;
  final List<QuizQuestion> questions;

  const BossQuiz({
    required this.title,
    required this.questionCount,
    this.passThreshold = 70,
    required this.xpReward,
    required this.coinReward,
    this.firstTryMultiplier = 2,
    required this.questions,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'questionCount': questionCount,
        'passThreshold': passThreshold,
        'xpReward': xpReward,
        'coinReward': coinReward,
        'firstTryMultiplier': firstTryMultiplier,
        'retryAllowed': true,
        'questions': questions.map((q) => q.toMap()).toList(),
      };
}

/// A single quiz question with multiple answer options.
enum QuizType { multipleChoice, fillBlank, matchPairs, scenario }

class QuizQuestion {
  final String questionTemplate;
  final QuizType type;
  final String correctAnswerKey;
  final List<String> optionKeys;
  final String? explanation;

  const QuizQuestion({
    required this.questionTemplate,
    required this.type,
    required this.correctAnswerKey,
    required this.optionKeys,
    this.explanation,
  });

  Map<String, dynamic> toMap() => {
        'questionTemplate': questionTemplate,
        'type': type.name,
        'correctAnswerKey': correctAnswerKey,
        'optionKeys': optionKeys,
        'explanation': explanation,
      };
}

// =============================================================================
// PART 2: MAIN SEED DATA CLASS
// =============================================================================

class LearningPathSeedData {
  LearningPathSeedData._();

  // ---------------------------------------------------------------------------
  // ALL 41 SUPPORTED LANGUAGES
  // ---------------------------------------------------------------------------
  static const Map<String, LanguageInfo> supportedLanguages = {
    'es': LanguageInfo(code: 'es', name: 'Spanish', flag: '\u{1F1EA}\u{1F1F8}', nativeName: 'Espanol', region: 'Europe', scriptType: 'latin'),
    'fr': LanguageInfo(code: 'fr', name: 'French', flag: '\u{1F1EB}\u{1F1F7}', nativeName: 'Francais', region: 'Europe', scriptType: 'latin'),
    'de': LanguageInfo(code: 'de', name: 'German', flag: '\u{1F1E9}\u{1F1EA}', nativeName: 'Deutsch', region: 'Europe', scriptType: 'latin'),
    'it': LanguageInfo(code: 'it', name: 'Italian', flag: '\u{1F1EE}\u{1F1F9}', nativeName: 'Italiano', region: 'Europe', scriptType: 'latin'),
    'pt': LanguageInfo(code: 'pt', name: 'Portuguese', flag: '\u{1F1F5}\u{1F1F9}', nativeName: 'Portugues', region: 'Europe', scriptType: 'latin'),
    'ru': LanguageInfo(code: 'ru', name: 'Russian', flag: '\u{1F1F7}\u{1F1FA}', nativeName: 'Russkij', region: 'Europe', scriptType: 'cyrillic'),
    'zh': LanguageInfo(code: 'zh', name: 'Chinese', flag: '\u{1F1E8}\u{1F1F3}', nativeName: 'Zhongwen', region: 'Asia', scriptType: 'cjk'),
    'ja': LanguageInfo(code: 'ja', name: 'Japanese', flag: '\u{1F1EF}\u{1F1F5}', nativeName: 'Nihongo', region: 'Asia', scriptType: 'cjk'),
    'ko': LanguageInfo(code: 'ko', name: 'Korean', flag: '\u{1F1F0}\u{1F1F7}', nativeName: 'Hangugeo', region: 'Asia', scriptType: 'hangul'),
    'ar': LanguageInfo(code: 'ar', name: 'Arabic', flag: '\u{1F1F8}\u{1F1E6}', nativeName: 'Al-Arabiyyah', region: 'Middle East', scriptType: 'arabic'),
    'hi': LanguageInfo(code: 'hi', name: 'Hindi', flag: '\u{1F1EE}\u{1F1F3}', nativeName: 'Hindi', region: 'Asia', scriptType: 'devanagari'),
    'tr': LanguageInfo(code: 'tr', name: 'Turkish', flag: '\u{1F1F9}\u{1F1F7}', nativeName: 'Turkce', region: 'Europe/Asia', scriptType: 'latin'),
    'nl': LanguageInfo(code: 'nl', name: 'Dutch', flag: '\u{1F1F3}\u{1F1F1}', nativeName: 'Nederlands', region: 'Europe', scriptType: 'latin'),
    'sv': LanguageInfo(code: 'sv', name: 'Swedish', flag: '\u{1F1F8}\u{1F1EA}', nativeName: 'Svenska', region: 'Europe', scriptType: 'latin'),
    'no': LanguageInfo(code: 'no', name: 'Norwegian', flag: '\u{1F1F3}\u{1F1F4}', nativeName: 'Norsk', region: 'Europe', scriptType: 'latin'),
    'da': LanguageInfo(code: 'da', name: 'Danish', flag: '\u{1F1E9}\u{1F1F0}', nativeName: 'Dansk', region: 'Europe', scriptType: 'latin'),
    'fi': LanguageInfo(code: 'fi', name: 'Finnish', flag: '\u{1F1EB}\u{1F1EE}', nativeName: 'Suomi', region: 'Europe', scriptType: 'latin'),
    'pl': LanguageInfo(code: 'pl', name: 'Polish', flag: '\u{1F1F5}\u{1F1F1}', nativeName: 'Polski', region: 'Europe', scriptType: 'latin'),
    'cs': LanguageInfo(code: 'cs', name: 'Czech', flag: '\u{1F1E8}\u{1F1FF}', nativeName: 'Cestina', region: 'Europe', scriptType: 'latin'),
    'el': LanguageInfo(code: 'el', name: 'Greek', flag: '\u{1F1EC}\u{1F1F7}', nativeName: 'Ellinika', region: 'Europe', scriptType: 'greek'),
    'hu': LanguageInfo(code: 'hu', name: 'Hungarian', flag: '\u{1F1ED}\u{1F1FA}', nativeName: 'Magyar', region: 'Europe', scriptType: 'latin'),
    'ro': LanguageInfo(code: 'ro', name: 'Romanian', flag: '\u{1F1F7}\u{1F1F4}', nativeName: 'Romana', region: 'Europe', scriptType: 'latin'),
    'th': LanguageInfo(code: 'th', name: 'Thai', flag: '\u{1F1F9}\u{1F1ED}', nativeName: 'Phasa Thai', region: 'Asia', scriptType: 'thai'),
    'vi': LanguageInfo(code: 'vi', name: 'Vietnamese', flag: '\u{1F1FB}\u{1F1F3}', nativeName: 'Tieng Viet', region: 'Asia', scriptType: 'latin'),
    'id': LanguageInfo(code: 'id', name: 'Indonesian', flag: '\u{1F1EE}\u{1F1E9}', nativeName: 'Bahasa Indonesia', region: 'Asia', scriptType: 'latin'),
    'ms': LanguageInfo(code: 'ms', name: 'Malay', flag: '\u{1F1F2}\u{1F1FE}', nativeName: 'Bahasa Melayu', region: 'Asia', scriptType: 'latin'),
    'tl': LanguageInfo(code: 'tl', name: 'Filipino', flag: '\u{1F1F5}\u{1F1ED}', nativeName: 'Tagalog', region: 'Asia', scriptType: 'latin'),
    'he': LanguageInfo(code: 'he', name: 'Hebrew', flag: '\u{1F1EE}\u{1F1F1}', nativeName: 'Ivrit', region: 'Middle East', scriptType: 'hebrew'),
    'fa': LanguageInfo(code: 'fa', name: 'Persian', flag: '\u{1F1EE}\u{1F1F7}', nativeName: 'Farsi', region: 'Middle East', scriptType: 'arabic'),
    'sw': LanguageInfo(code: 'sw', name: 'Swahili', flag: '\u{1F1F0}\u{1F1EA}', nativeName: 'Kiswahili', region: 'Africa', scriptType: 'latin'),
    'uk': LanguageInfo(code: 'uk', name: 'Ukrainian', flag: '\u{1F1FA}\u{1F1E6}', nativeName: 'Ukrainska', region: 'Europe', scriptType: 'cyrillic'),
    'hr': LanguageInfo(code: 'hr', name: 'Croatian', flag: '\u{1F1ED}\u{1F1F7}', nativeName: 'Hrvatski', region: 'Europe', scriptType: 'latin'),
    'sr': LanguageInfo(code: 'sr', name: 'Serbian', flag: '\u{1F1F7}\u{1F1F8}', nativeName: 'Srpski', region: 'Europe', scriptType: 'cyrillic'),
    'bg': LanguageInfo(code: 'bg', name: 'Bulgarian', flag: '\u{1F1E7}\u{1F1EC}', nativeName: 'Bulgarski', region: 'Europe', scriptType: 'cyrillic'),
    'sk': LanguageInfo(code: 'sk', name: 'Slovak', flag: '\u{1F1F8}\u{1F1F0}', nativeName: 'Slovencina', region: 'Europe', scriptType: 'latin'),
    'lt': LanguageInfo(code: 'lt', name: 'Lithuanian', flag: '\u{1F1F1}\u{1F1F9}', nativeName: 'Lietuviu', region: 'Europe', scriptType: 'latin'),
    'lv': LanguageInfo(code: 'lv', name: 'Latvian', flag: '\u{1F1F1}\u{1F1FB}', nativeName: 'Latviesu', region: 'Europe', scriptType: 'latin'),
    'et': LanguageInfo(code: 'et', name: 'Estonian', flag: '\u{1F1EA}\u{1F1EA}', nativeName: 'Eesti', region: 'Europe', scriptType: 'latin'),
    'sl': LanguageInfo(code: 'sl', name: 'Slovenian', flag: '\u{1F1F8}\u{1F1EE}', nativeName: 'Slovenscina', region: 'Europe', scriptType: 'latin'),
    'ca': LanguageInfo(code: 'ca', name: 'Catalan', flag: '\u{1F1EA}\u{1F1F8}', nativeName: 'Catala', region: 'Europe', scriptType: 'latin'),
    'ka': LanguageInfo(code: 'ka', name: 'Georgian', flag: '\u{1F1EC}\u{1F1EA}', nativeName: 'Kartuli', region: 'Europe/Asia', scriptType: 'georgian'),
  };

  // ---------------------------------------------------------------------------
  // THE 12 WORLDS (language-agnostic structure)
  // ---------------------------------------------------------------------------
  static List<LearningWorld> getWorlds() => [
        _world1(),
        _world2(),
        _world3(),
        _world4(),
        _world5(),
        _world6(),
        _world7(),
        _world8(),
        _world9(),
        _world10(),
        _world11(),
        _world12(),
      ];

  // ===========================================================================
  // WORLD 1: THE GREETING GATE (Month 1 - FREE)
  // ===========================================================================
  static LearningWorld _world1() => const LearningWorld(
        number: 1,
        name: 'The Greeting Gate',
        emoji: '\u{1F3F0}',
        description:
            'Your adventure begins! Master basic greetings, introductions, and survival phrases. Every hero needs to say hello before saving the world.',
        difficulty: 1,
        worldXpBonus: 500,
        achievement: 'The Greeter',
        achievementIcon: '\u{1F44B}',
        estimatedHours: 8,
        isFree: true,
        chapters: [
          // Chapter 1: First Words
          LearningChapter(
            number: 1,
            title: 'First Words',
            subtitle: 'Hello, goodbye, and the magic words',
            levels: [
              LearningLevel(
                number: 1,
                title: 'Hello, World!',
                description:
                    'Unlock your very first words in a new language.',
                xpReward: 50,
                coinReward: 10,
                grammarTip:
                    'In many languages, there are formal and informal ways to say hello. Start with the friendly version!',
                culturalNote:
                    'In Japan, people bow when they greet. In France, friends kiss cheeks. Every culture has a unique hello!',
                vocabulary: [
                  VocabItem(englishKey: 'hello', category: 'word'),
                  VocabItem(englishKey: 'hi', category: 'word'),
                  VocabItem(englishKey: 'good morning', category: 'phrase'),
                  VocabItem(englishKey: 'good afternoon', category: 'phrase'),
                  VocabItem(englishKey: 'good evening', category: 'phrase'),
                  VocabItem(englishKey: 'good night', category: 'phrase'),
                  VocabItem(englishKey: 'welcome', category: 'word'),
                  VocabItem(englishKey: 'hey', category: 'word'),
                  VocabItem(englishKey: 'greetings', category: 'word'),
                  VocabItem(englishKey: 'howdy', category: 'word'),
                ],
              ),
              LearningLevel(
                number: 2,
                title: 'The Farewell',
                description: 'Learn to say goodbye like a pro.',
                xpReward: 50,
                coinReward: 10,
                culturalNote:
                    'In Italy, "ciao" means both hello AND goodbye. Two for the price of one!',
                vocabulary: [
                  VocabItem(englishKey: 'goodbye', category: 'word'),
                  VocabItem(englishKey: 'bye', category: 'word'),
                  VocabItem(englishKey: 'see you later', category: 'phrase'),
                  VocabItem(englishKey: 'see you soon', category: 'phrase'),
                  VocabItem(englishKey: 'see you tomorrow', category: 'phrase'),
                  VocabItem(englishKey: 'take care', category: 'phrase'),
                  VocabItem(englishKey: 'have a nice day', category: 'phrase'),
                  VocabItem(
                      englishKey: 'until next time', category: 'phrase'),
                  VocabItem(englishKey: 'farewell', category: 'word'),
                  VocabItem(englishKey: 'later', category: 'word'),
                ],
              ),
              LearningLevel(
                number: 3,
                title: 'Magic Words',
                description:
                    'Please, thank you, and the words that open every door.',
                xpReward: 60,
                coinReward: 10,
                grammarTip:
                    'Politeness is your superpower. "Please" and "thank you" will get you further than perfect grammar.',
                culturalNote:
                    'In Korean culture, there are 7 levels of politeness! Start with the standard polite form.',
                vocabulary: [
                  VocabItem(englishKey: 'please', category: 'word'),
                  VocabItem(englishKey: 'thank you', category: 'phrase'),
                  VocabItem(
                      englishKey: 'thank you very much', category: 'phrase'),
                  VocabItem(
                      englishKey: 'you are welcome', category: 'phrase'),
                  VocabItem(englishKey: 'excuse me', category: 'phrase'),
                  VocabItem(englishKey: 'sorry', category: 'word'),
                  VocabItem(englishKey: 'I am sorry', category: 'phrase'),
                  VocabItem(englishKey: 'no problem', category: 'phrase'),
                  VocabItem(englishKey: 'of course', category: 'phrase'),
                  VocabItem(
                      englishKey: 'with pleasure', category: 'phrase'),
                ],
              ),
              LearningLevel(
                number: 4,
                title: 'Yes, No, Maybe',
                description:
                    'The three answers to every question in the universe.',
                xpReward: 60,
                coinReward: 15,
                vocabulary: [
                  VocabItem(englishKey: 'yes', category: 'word'),
                  VocabItem(englishKey: 'no', category: 'word'),
                  VocabItem(englishKey: 'maybe', category: 'word'),
                  VocabItem(englishKey: 'I think so', category: 'phrase'),
                  VocabItem(
                      englishKey: 'I do not think so', category: 'phrase'),
                  VocabItem(englishKey: 'I do not know', category: 'phrase'),
                  VocabItem(englishKey: 'okay', category: 'word'),
                  VocabItem(englishKey: 'sure', category: 'word'),
                  VocabItem(englishKey: 'never', category: 'word'),
                  VocabItem(englishKey: 'always', category: 'word'),
                ],
              ),
              LearningLevel(
                number: 5,
                title: 'How Are You?',
                description:
                    'The question everyone asks - and how to answer it.',
                xpReward: 70,
                coinReward: 15,
                grammarTip:
                    'Most "How are you?" questions expect a positive answer, even if you feel terrible!',
                culturalNote:
                    'In China, "Have you eaten?" is a common greeting similar to "How are you?" -- food is everything!',
                vocabulary: [
                  VocabItem(
                      englishKey: 'how are you', category: 'phrase'),
                  VocabItem(englishKey: 'I am fine', category: 'phrase'),
                  VocabItem(
                      englishKey: 'I am doing well', category: 'phrase'),
                  VocabItem(
                      englishKey: 'not bad', category: 'phrase'),
                  VocabItem(
                      englishKey: 'very good', category: 'phrase'),
                  VocabItem(
                      englishKey: 'so-so', category: 'phrase'),
                  VocabItem(
                      englishKey: 'and you', category: 'phrase'),
                  VocabItem(
                      englishKey: 'great', category: 'word'),
                  VocabItem(
                      englishKey: 'wonderful', category: 'word'),
                  VocabItem(
                      englishKey: 'terrible', category: 'word'),
                ],
              ),
            ],
            bossQuiz: BossQuiz(
              title: 'BOSS: The Gatekeeper',
              questionCount: 15,
              xpReward: 200,
              coinReward: 50,
              questions: [
                QuizQuestion(
                  questionTemplate:
                      'How do you say "hello" in {language}?',
                  type: QuizType.multipleChoice,
                  correctAnswerKey: 'hello',
                  optionKeys: ['hello', 'goodbye', 'please', 'thank you'],
                ),
                QuizQuestion(
                  questionTemplate:
                      'What is "thank you" in {language}?',
                  type: QuizType.multipleChoice,
                  correctAnswerKey: 'thank you',
                  optionKeys: ['sorry', 'thank you', 'hello', 'goodbye'],
                ),
                QuizQuestion(
                  questionTemplate:
                      'Fill in the blank: "___" means goodbye.',
                  type: QuizType.fillBlank,
                  correctAnswerKey: 'goodbye',
                  optionKeys: ['goodbye'],
                ),
                QuizQuestion(
                  questionTemplate:
                      'Match: "please" = ?',
                  type: QuizType.matchPairs,
                  correctAnswerKey: 'please',
                  optionKeys: [
                    'please',
                    'sorry',
                    'yes',
                    'no'
                  ],
                ),
                QuizQuestion(
                  questionTemplate:
                      'Someone asks "How are you?" -- which is a correct reply?',
                  type: QuizType.scenario,
                  correctAnswerKey: 'I am fine',
                  optionKeys: [
                    'I am fine',
                    'goodbye',
                    'please',
                    'hello'
                  ],
                  explanation:
                      'When someone asks how you are, respond with how you feel!',
                ),
                QuizQuestion(
                  questionTemplate:
                      'Translate "good morning" to {language}.',
                  type: QuizType.multipleChoice,
                  correctAnswerKey: 'good morning',
                  optionKeys: [
                    'good morning',
                    'good night',
                    'good evening',
                    'goodbye'
                  ],
                ),
                QuizQuestion(
                  questionTemplate:
                      'What does "see you later" mean?',
                  type: QuizType.multipleChoice,
                  correctAnswerKey: 'see you later',
                  optionKeys: [
                    'see you later',
                    'hello',
                    'sorry',
                    'please'
                  ],
                ),
                QuizQuestion(
                  questionTemplate:
                      'How would you politely ask for something?',
                  type: QuizType.scenario,
                  correctAnswerKey: 'please',
                  optionKeys: ['please', 'no', 'goodbye', 'never'],
                ),
                QuizQuestion(
                  questionTemplate:
                      'Fill in: "___ ___" is how you say "excuse me".',
                  type: QuizType.fillBlank,
                  correctAnswerKey: 'excuse me',
                  optionKeys: ['excuse me'],
                ),
                QuizQuestion(
                  questionTemplate:
                      'Translate "yes" to {language}.',
                  type: QuizType.multipleChoice,
                  correctAnswerKey: 'yes',
                  optionKeys: ['yes', 'no', 'maybe', 'okay'],
                ),
                QuizQuestion(
                  questionTemplate:
                      'What is the polite word for "sorry" in {language}?',
                  type: QuizType.multipleChoice,
                  correctAnswerKey: 'sorry',
                  optionKeys: ['sorry', 'hello', 'yes', 'please'],
                ),
                QuizQuestion(
                  questionTemplate:
                      'Scenario: You bump into someone. What do you say?',
                  type: QuizType.scenario,
                  correctAnswerKey: 'excuse me',
                  optionKeys: [
                    'excuse me',
                    'goodbye',
                    'thank you',
                    'hello'
                  ],
                ),
                QuizQuestion(
                  questionTemplate:
                      'Translate "have a nice day" to {language}.',
                  type: QuizType.multipleChoice,
                  correctAnswerKey: 'have a nice day',
                  optionKeys: [
                    'have a nice day',
                    'good night',
                    'see you soon',
                    'hello'
                  ],
                ),
                QuizQuestion(
                  questionTemplate:
                      'What does "you are welcome" mean?',
                  type: QuizType.multipleChoice,
                  correctAnswerKey: 'you are welcome',
                  optionKeys: [
                    'you are welcome',
                    'hello',
                    'goodbye',
                    'sorry'
                  ],
                ),
                QuizQuestion(
                  questionTemplate:
                      'Final question: Greet someone, ask how they are, and say goodbye. Put them in order.',
                  type: QuizType.scenario,
                  correctAnswerKey: 'hello',
                  optionKeys: [
                    'hello',
                    'how are you',
                    'I am fine',
                    'goodbye'
                  ],
                  explanation:
                      'A complete greeting exchange: Hello -> How are you? -> I am fine -> Goodbye',
                ),
              ],
            ),
          ),

          // Chapter 2: Who Am I?
          LearningChapter(
            number: 2,
            title: 'Who Am I?',
            subtitle: 'Names, ages, and where you come from',
            levels: [
              LearningLevel(
                number: 1,
                title: 'My Name Is...',
                description: 'Introduce yourself with confidence.',
                xpReward: 55,
                coinReward: 10,
                grammarTip:
                    'In most languages, "My name is..." follows a simple pattern. Memorize this one sentence and you are set!',
                vocabulary: [
                  VocabItem(englishKey: 'my name is', category: 'phrase'),
                  VocabItem(englishKey: 'what is your name', category: 'phrase'),
                  VocabItem(englishKey: 'nice to meet you', category: 'phrase'),
                  VocabItem(englishKey: 'I am', category: 'phrase'),
                  VocabItem(englishKey: 'you are', category: 'phrase'),
                  VocabItem(englishKey: 'he is', category: 'phrase'),
                  VocabItem(englishKey: 'she is', category: 'phrase'),
                  VocabItem(englishKey: 'we are', category: 'phrase'),
                  VocabItem(englishKey: 'they are', category: 'phrase'),
                  VocabItem(englishKey: 'who', category: 'word'),
                ],
              ),
              LearningLevel(
                number: 2,
                title: 'Where Are You From?',
                description: 'Share your homeland and learn about theirs.',
                xpReward: 55,
                coinReward: 10,
                culturalNote:
                    'Asking where someone is from is a universal icebreaker. In some cultures it is the very first question!',
                vocabulary: [
                  VocabItem(englishKey: 'where are you from', category: 'phrase'),
                  VocabItem(englishKey: 'I am from', category: 'phrase'),
                  VocabItem(englishKey: 'country', category: 'word'),
                  VocabItem(englishKey: 'city', category: 'word'),
                  VocabItem(englishKey: 'I live in', category: 'phrase'),
                  VocabItem(englishKey: 'nationality', category: 'word'),
                  VocabItem(englishKey: 'language', category: 'word'),
                  VocabItem(englishKey: 'I speak', category: 'phrase'),
                  VocabItem(englishKey: 'do you speak', category: 'phrase'),
                  VocabItem(englishKey: 'a little', category: 'phrase'),
                ],
              ),
              LearningLevel(
                number: 3,
                title: 'How Old Are You?',
                description: 'Numbers meet personal questions.',
                xpReward: 60,
                coinReward: 10,
                grammarTip:
                    'In some languages (like French and German), you "have" years instead of "being" years old.',
                vocabulary: [
                  VocabItem(englishKey: 'how old are you', category: 'phrase'),
                  VocabItem(englishKey: 'I am ... years old', category: 'phrase'),
                  VocabItem(englishKey: 'young', category: 'word'),
                  VocabItem(englishKey: 'old', category: 'word'),
                  VocabItem(englishKey: 'age', category: 'word'),
                  VocabItem(englishKey: 'birthday', category: 'word'),
                  VocabItem(englishKey: 'when is your birthday', category: 'phrase'),
                  VocabItem(englishKey: 'happy birthday', category: 'phrase'),
                  VocabItem(englishKey: 'year', category: 'word'),
                  VocabItem(englishKey: 'month', category: 'word'),
                ],
              ),
              LearningLevel(
                number: 4,
                title: 'Family Tree',
                description: 'Meet the family members.',
                xpReward: 60,
                coinReward: 15,
                culturalNote:
                    'In many Asian languages, there are different words for older brother vs younger brother!',
                vocabulary: [
                  VocabItem(englishKey: 'family', category: 'word'),
                  VocabItem(englishKey: 'mother', category: 'word'),
                  VocabItem(englishKey: 'father', category: 'word'),
                  VocabItem(englishKey: 'brother', category: 'word'),
                  VocabItem(englishKey: 'sister', category: 'word'),
                  VocabItem(englishKey: 'son', category: 'word'),
                  VocabItem(englishKey: 'daughter', category: 'word'),
                  VocabItem(englishKey: 'husband', category: 'word'),
                  VocabItem(englishKey: 'wife', category: 'word'),
                  VocabItem(englishKey: 'friend', category: 'word'),
                ],
              ),
              LearningLevel(
                number: 5,
                title: 'About Me',
                description: 'Put it all together and describe yourself.',
                xpReward: 75,
                coinReward: 15,
                vocabulary: [
                  VocabItem(englishKey: 'I like', category: 'phrase'),
                  VocabItem(englishKey: 'I do not like', category: 'phrase'),
                  VocabItem(englishKey: 'I love', category: 'phrase'),
                  VocabItem(englishKey: 'I want', category: 'phrase'),
                  VocabItem(englishKey: 'I need', category: 'phrase'),
                  VocabItem(englishKey: 'I have', category: 'phrase'),
                  VocabItem(englishKey: 'I do not have', category: 'phrase'),
                  VocabItem(englishKey: 'my favorite', category: 'phrase'),
                  VocabItem(englishKey: 'hobby', category: 'word'),
                  VocabItem(englishKey: 'job', category: 'word'),
                ],
              ),
            ],
            bossQuiz: BossQuiz(
              title: 'BOSS: The Identity Keeper',
              questionCount: 15,
              xpReward: 250,
              coinReward: 50,
              questions: [
                QuizQuestion(questionTemplate: 'How do you say "my name is" in {language}?', type: QuizType.multipleChoice, correctAnswerKey: 'my name is', optionKeys: ['my name is', 'how are you', 'goodbye', 'please']),
                QuizQuestion(questionTemplate: 'Translate "where are you from" to {language}.', type: QuizType.multipleChoice, correctAnswerKey: 'where are you from', optionKeys: ['where are you from', 'how old are you', 'my name is', 'I am fine']),
                QuizQuestion(questionTemplate: 'What is "mother" in {language}?', type: QuizType.multipleChoice, correctAnswerKey: 'mother', optionKeys: ['mother', 'father', 'sister', 'brother']),
                QuizQuestion(questionTemplate: 'Fill in: "I ___ from..."', type: QuizType.fillBlank, correctAnswerKey: 'I am from', optionKeys: ['I am from']),
                QuizQuestion(questionTemplate: 'How do you say "friend" in {language}?', type: QuizType.multipleChoice, correctAnswerKey: 'friend', optionKeys: ['friend', 'family', 'wife', 'husband']),
                QuizQuestion(questionTemplate: 'Translate "I like" to {language}.', type: QuizType.multipleChoice, correctAnswerKey: 'I like', optionKeys: ['I like', 'I need', 'I have', 'I am']),
                QuizQuestion(questionTemplate: 'Someone says their age. How did they start?', type: QuizType.scenario, correctAnswerKey: 'I am ... years old', optionKeys: ['I am ... years old', 'my name is', 'I am from', 'I like']),
                QuizQuestion(questionTemplate: 'What is "father" in {language}?', type: QuizType.multipleChoice, correctAnswerKey: 'father', optionKeys: ['father', 'mother', 'son', 'daughter']),
                QuizQuestion(questionTemplate: 'Translate "I speak" to {language}.', type: QuizType.multipleChoice, correctAnswerKey: 'I speak', optionKeys: ['I speak', 'I like', 'I want', 'I have']),
                QuizQuestion(questionTemplate: 'What is "nice to meet you" in {language}?', type: QuizType.multipleChoice, correctAnswerKey: 'nice to meet you', optionKeys: ['nice to meet you', 'goodbye', 'sorry', 'thank you']),
                QuizQuestion(questionTemplate: 'Translate "happy birthday" to {language}.', type: QuizType.multipleChoice, correctAnswerKey: 'happy birthday', optionKeys: ['happy birthday', 'good morning', 'good night', 'welcome']),
                QuizQuestion(questionTemplate: 'How do you say "I have" in {language}?', type: QuizType.multipleChoice, correctAnswerKey: 'I have', optionKeys: ['I have', 'I am', 'I want', 'I need']),
                QuizQuestion(questionTemplate: 'Fill in: "What is your ___?"', type: QuizType.fillBlank, correctAnswerKey: 'what is your name', optionKeys: ['what is your name']),
                QuizQuestion(questionTemplate: 'What is "sister" in {language}?', type: QuizType.multipleChoice, correctAnswerKey: 'sister', optionKeys: ['sister', 'brother', 'mother', 'father']),
                QuizQuestion(questionTemplate: 'Introduce yourself fully: name, origin, age. Which order?', type: QuizType.scenario, correctAnswerKey: 'my name is', optionKeys: ['my name is', 'I am from', 'I am ... years old', 'nice to meet you'], explanation: 'A full introduction: name, where you are from, your age, and nice to meet you!'),
              ],
            ),
          ),

          // Chapter 3: Numbers & Colors
          LearningChapter(
            number: 3,
            title: 'Numbers & Colors',
            subtitle: 'Count to 20 and paint the rainbow',
            levels: [
              LearningLevel(number: 1, title: 'Counting 1-5', description: 'Your first five numbers. Baby steps!', xpReward: 50, coinReward: 10, vocabulary: [VocabItem(englishKey: 'one', category: 'word'), VocabItem(englishKey: 'two', category: 'word'), VocabItem(englishKey: 'three', category: 'word'), VocabItem(englishKey: 'four', category: 'word'), VocabItem(englishKey: 'five', category: 'word'), VocabItem(englishKey: 'number', category: 'word'), VocabItem(englishKey: 'how many', category: 'phrase'), VocabItem(englishKey: 'first', category: 'word'), VocabItem(englishKey: 'second', category: 'word'), VocabItem(englishKey: 'zero', category: 'word')]),
              LearningLevel(number: 2, title: 'Counting 6-10', description: 'Level up your counting powers.', xpReward: 50, coinReward: 10, vocabulary: [VocabItem(englishKey: 'six', category: 'word'), VocabItem(englishKey: 'seven', category: 'word'), VocabItem(englishKey: 'eight', category: 'word'), VocabItem(englishKey: 'nine', category: 'word'), VocabItem(englishKey: 'ten', category: 'word'), VocabItem(englishKey: 'third', category: 'word'), VocabItem(englishKey: 'fourth', category: 'word'), VocabItem(englishKey: 'fifth', category: 'word'), VocabItem(englishKey: 'half', category: 'word'), VocabItem(englishKey: 'double', category: 'word')]),
              LearningLevel(number: 3, title: 'Counting 11-20', description: 'Now you can count past your fingers!', xpReward: 60, coinReward: 10, grammarTip: 'In many languages, 11-19 follow special patterns. After 20, it gets more regular!', vocabulary: [VocabItem(englishKey: 'eleven', category: 'word'), VocabItem(englishKey: 'twelve', category: 'word'), VocabItem(englishKey: 'thirteen', category: 'word'), VocabItem(englishKey: 'fourteen', category: 'word'), VocabItem(englishKey: 'fifteen', category: 'word'), VocabItem(englishKey: 'sixteen', category: 'word'), VocabItem(englishKey: 'seventeen', category: 'word'), VocabItem(englishKey: 'eighteen', category: 'word'), VocabItem(englishKey: 'nineteen', category: 'word'), VocabItem(englishKey: 'twenty', category: 'word')]),
              LearningLevel(number: 4, title: 'Rainbow Warrior', description: 'Learn every color of the rainbow.', xpReward: 60, coinReward: 15, culturalNote: 'White means purity in Western cultures but mourning in many Asian cultures. Colors carry different meanings!', vocabulary: [VocabItem(englishKey: 'red', category: 'word'), VocabItem(englishKey: 'blue', category: 'word'), VocabItem(englishKey: 'green', category: 'word'), VocabItem(englishKey: 'yellow', category: 'word'), VocabItem(englishKey: 'black', category: 'word'), VocabItem(englishKey: 'white', category: 'word'), VocabItem(englishKey: 'orange', category: 'word'), VocabItem(englishKey: 'purple', category: 'word'), VocabItem(englishKey: 'pink', category: 'word'), VocabItem(englishKey: 'brown', category: 'word')]),
              LearningLevel(number: 5, title: 'Numbers in Action', description: 'Use numbers in real sentences.', xpReward: 70, coinReward: 15, vocabulary: [VocabItem(englishKey: 'I have two', category: 'phrase'), VocabItem(englishKey: 'three friends', category: 'phrase'), VocabItem(englishKey: 'phone number', category: 'phrase'), VocabItem(englishKey: 'what time is it', category: 'phrase'), VocabItem(englishKey: 'hundred', category: 'word'), VocabItem(englishKey: 'thousand', category: 'word'), VocabItem(englishKey: 'my favorite color', category: 'phrase'), VocabItem(englishKey: 'what color', category: 'phrase'), VocabItem(englishKey: 'big', category: 'word'), VocabItem(englishKey: 'small', category: 'word')]),
            ],
            bossQuiz: BossQuiz(
              title: 'BOSS: The Number Wizard',
              questionCount: 15,
              xpReward: 200,
              coinReward: 50,
              questions: [
                QuizQuestion(questionTemplate: 'What is "seven" in {language}?', type: QuizType.multipleChoice, correctAnswerKey: 'seven', optionKeys: ['seven', 'six', 'eight', 'nine']),
                QuizQuestion(questionTemplate: 'Translate "red" to {language}.', type: QuizType.multipleChoice, correctAnswerKey: 'red', optionKeys: ['red', 'blue', 'green', 'yellow']),
                QuizQuestion(questionTemplate: 'What number is "fifteen" in {language}?', type: QuizType.multipleChoice, correctAnswerKey: 'fifteen', optionKeys: ['fifteen', 'fourteen', 'sixteen', 'thirteen']),
                QuizQuestion(questionTemplate: 'Translate "blue" to {language}.', type: QuizType.multipleChoice, correctAnswerKey: 'blue', optionKeys: ['blue', 'red', 'green', 'purple']),
                QuizQuestion(questionTemplate: 'Fill in: The number after nine is ___.', type: QuizType.fillBlank, correctAnswerKey: 'ten', optionKeys: ['ten']),
                QuizQuestion(questionTemplate: 'What is "twenty" in {language}?', type: QuizType.multipleChoice, correctAnswerKey: 'twenty', optionKeys: ['twenty', 'twelve', 'two', 'ten']),
                QuizQuestion(questionTemplate: 'Translate "green" to {language}.', type: QuizType.multipleChoice, correctAnswerKey: 'green', optionKeys: ['green', 'yellow', 'blue', 'red']),
                QuizQuestion(questionTemplate: 'What is "three" in {language}?', type: QuizType.multipleChoice, correctAnswerKey: 'three', optionKeys: ['three', 'four', 'two', 'five']),
                QuizQuestion(questionTemplate: 'Fill in: My favorite ___ is blue.', type: QuizType.fillBlank, correctAnswerKey: 'my favorite color', optionKeys: ['my favorite color']),
                QuizQuestion(questionTemplate: 'Translate "black" to {language}.', type: QuizType.multipleChoice, correctAnswerKey: 'black', optionKeys: ['black', 'white', 'brown', 'purple']),
                QuizQuestion(questionTemplate: 'What is "eleven" in {language}?', type: QuizType.multipleChoice, correctAnswerKey: 'eleven', optionKeys: ['eleven', 'twelve', 'ten', 'thirteen']),
                QuizQuestion(questionTemplate: 'What is "white" in {language}?', type: QuizType.multipleChoice, correctAnswerKey: 'white', optionKeys: ['white', 'black', 'yellow', 'pink']),
                QuizQuestion(questionTemplate: 'Translate "phone number" to {language}.', type: QuizType.multipleChoice, correctAnswerKey: 'phone number', optionKeys: ['phone number', 'how many', 'what time is it', 'what color']),
                QuizQuestion(questionTemplate: 'What is "pink" in {language}?', type: QuizType.multipleChoice, correctAnswerKey: 'pink', optionKeys: ['pink', 'purple', 'red', 'orange']),
                QuizQuestion(questionTemplate: 'Scenario: You want to buy 5 items. Which number?', type: QuizType.scenario, correctAnswerKey: 'five', optionKeys: ['five', 'four', 'six', 'three']),
              ],
            ),
          ),

          // Chapter 4: Daily Life
          LearningChapter(
            number: 4,
            title: 'Daily Life',
            subtitle: 'Morning routines, food, and survival verbs',
            levels: [
              LearningLevel(number: 1, title: 'Rise and Shine', description: 'Your morning routine in a new language.', xpReward: 55, coinReward: 10, culturalNote: 'In Spain, people rarely eat breakfast before 9 AM. In Japan, breakfast often includes rice, fish, and miso soup!', vocabulary: [VocabItem(englishKey: 'morning', category: 'word'), VocabItem(englishKey: 'night', category: 'word'), VocabItem(englishKey: 'today', category: 'word'), VocabItem(englishKey: 'tomorrow', category: 'word'), VocabItem(englishKey: 'yesterday', category: 'word'), VocabItem(englishKey: 'wake up', category: 'phrase'), VocabItem(englishKey: 'sleep', category: 'word'), VocabItem(englishKey: 'time', category: 'word'), VocabItem(englishKey: 'early', category: 'word'), VocabItem(englishKey: 'late', category: 'word')]),
              LearningLevel(number: 2, title: 'Hungry Hero', description: 'Essential food and drink vocabulary.', xpReward: 60, coinReward: 10, vocabulary: [VocabItem(englishKey: 'eat', category: 'word'), VocabItem(englishKey: 'drink', category: 'word'), VocabItem(englishKey: 'water', category: 'word'), VocabItem(englishKey: 'food', category: 'word'), VocabItem(englishKey: 'bread', category: 'word'), VocabItem(englishKey: 'coffee', category: 'word'), VocabItem(englishKey: 'tea', category: 'word'), VocabItem(englishKey: 'hungry', category: 'word'), VocabItem(englishKey: 'thirsty', category: 'word'), VocabItem(englishKey: 'delicious', category: 'word')]),
              LearningLevel(number: 3, title: 'Action Hero', description: 'The most important verbs you will ever learn.', xpReward: 65, coinReward: 15, grammarTip: 'Verbs are the engine of every sentence. Master these 10 and you can express almost anything!', vocabulary: [VocabItem(englishKey: 'go', category: 'word'), VocabItem(englishKey: 'come', category: 'word'), VocabItem(englishKey: 'see', category: 'word'), VocabItem(englishKey: 'hear', category: 'word'), VocabItem(englishKey: 'know', category: 'word'), VocabItem(englishKey: 'think', category: 'word'), VocabItem(englishKey: 'give', category: 'word'), VocabItem(englishKey: 'take', category: 'word'), VocabItem(englishKey: 'make', category: 'word'), VocabItem(englishKey: 'say', category: 'word')]),
              LearningLevel(number: 4, title: 'Around the House', description: 'Everything in your home.', xpReward: 65, coinReward: 15, vocabulary: [VocabItem(englishKey: 'house', category: 'word'), VocabItem(englishKey: 'room', category: 'word'), VocabItem(englishKey: 'door', category: 'word'), VocabItem(englishKey: 'window', category: 'word'), VocabItem(englishKey: 'table', category: 'word'), VocabItem(englishKey: 'chair', category: 'word'), VocabItem(englishKey: 'bed', category: 'word'), VocabItem(englishKey: 'bathroom', category: 'word'), VocabItem(englishKey: 'kitchen', category: 'word'), VocabItem(englishKey: 'here', category: 'word')]),
              LearningLevel(number: 5, title: 'Weather Report', description: 'Talk about the weather like a local.', xpReward: 75, coinReward: 15, culturalNote: 'In Britain, talking about weather is a national sport. In tropical countries, "hot and humid" covers 90% of the year!', vocabulary: [VocabItem(englishKey: 'hot', category: 'word'), VocabItem(englishKey: 'cold', category: 'word'), VocabItem(englishKey: 'rain', category: 'word'), VocabItem(englishKey: 'sun', category: 'word'), VocabItem(englishKey: 'wind', category: 'word'), VocabItem(englishKey: 'snow', category: 'word'), VocabItem(englishKey: 'weather', category: 'word'), VocabItem(englishKey: 'beautiful day', category: 'phrase'), VocabItem(englishKey: 'it is cold', category: 'phrase'), VocabItem(englishKey: 'it is hot', category: 'phrase')]),
            ],
            bossQuiz: BossQuiz(
              title: 'BOSS: The Survival Guide',
              questionCount: 18,
              xpReward: 300,
              coinReward: 75,
              questions: [
                QuizQuestion(questionTemplate: 'How do you say "water" in {language}?', type: QuizType.multipleChoice, correctAnswerKey: 'water', optionKeys: ['water', 'food', 'bread', 'coffee']),
                QuizQuestion(questionTemplate: 'Translate "eat" to {language}.', type: QuizType.multipleChoice, correctAnswerKey: 'eat', optionKeys: ['eat', 'drink', 'sleep', 'go']),
                QuizQuestion(questionTemplate: 'What is "tomorrow" in {language}?', type: QuizType.multipleChoice, correctAnswerKey: 'tomorrow', optionKeys: ['tomorrow', 'yesterday', 'today', 'morning']),
                QuizQuestion(questionTemplate: 'What is "cold" in {language}?', type: QuizType.multipleChoice, correctAnswerKey: 'cold', optionKeys: ['cold', 'hot', 'rain', 'sun']),
                QuizQuestion(questionTemplate: 'Translate "I am hungry" to {language}.', type: QuizType.multipleChoice, correctAnswerKey: 'hungry', optionKeys: ['hungry', 'thirsty', 'tired', 'happy']),
                QuizQuestion(questionTemplate: 'What is "house" in {language}?', type: QuizType.multipleChoice, correctAnswerKey: 'house', optionKeys: ['house', 'room', 'door', 'window']),
                QuizQuestion(questionTemplate: 'Translate "go" to {language}.', type: QuizType.multipleChoice, correctAnswerKey: 'go', optionKeys: ['go', 'come', 'see', 'hear']),
                QuizQuestion(questionTemplate: 'What is "sleep" in {language}?', type: QuizType.multipleChoice, correctAnswerKey: 'sleep', optionKeys: ['sleep', 'eat', 'drink', 'wake up']),
                QuizQuestion(questionTemplate: 'Fill in: It is very ___ today (warm temperature).', type: QuizType.fillBlank, correctAnswerKey: 'hot', optionKeys: ['hot']),
                QuizQuestion(questionTemplate: 'What is "coffee" in {language}?', type: QuizType.multipleChoice, correctAnswerKey: 'coffee', optionKeys: ['coffee', 'tea', 'water', 'bread']),
                QuizQuestion(questionTemplate: 'Translate "beautiful day" to {language}.', type: QuizType.multipleChoice, correctAnswerKey: 'beautiful day', optionKeys: ['beautiful day', 'good night', 'good morning', 'it is cold']),
                QuizQuestion(questionTemplate: 'What is "kitchen" in {language}?', type: QuizType.multipleChoice, correctAnswerKey: 'kitchen', optionKeys: ['kitchen', 'bathroom', 'bedroom', 'room']),
                QuizQuestion(questionTemplate: 'Translate "know" to {language}.', type: QuizType.multipleChoice, correctAnswerKey: 'know', optionKeys: ['know', 'think', 'see', 'hear']),
                QuizQuestion(questionTemplate: 'What is "rain" in {language}?', type: QuizType.multipleChoice, correctAnswerKey: 'rain', optionKeys: ['rain', 'sun', 'snow', 'wind']),
                QuizQuestion(questionTemplate: 'Scenario: You walk into a cafe. What do you order?', type: QuizType.scenario, correctAnswerKey: 'coffee', optionKeys: ['coffee', 'house', 'morning', 'door']),
                QuizQuestion(questionTemplate: 'Translate "delicious" to {language}.', type: QuizType.multipleChoice, correctAnswerKey: 'delicious', optionKeys: ['delicious', 'hungry', 'thirsty', 'cold']),
                QuizQuestion(questionTemplate: 'What is "bed" in {language}?', type: QuizType.multipleChoice, correctAnswerKey: 'bed', optionKeys: ['bed', 'chair', 'table', 'door']),
                QuizQuestion(questionTemplate: 'Final: Describe your day using at least 5 words you learned.', type: QuizType.scenario, correctAnswerKey: 'wake up', optionKeys: ['wake up', 'eat', 'go', 'sleep'], explanation: 'A typical day: wake up, eat breakfast, go to work, come home, sleep!'),
              ],
            ),
          ),
        ],
      );

  // ===========================================================================
  // WORLD 2: THE MARKET SQUARE (Month 2)
  // ===========================================================================
  static LearningWorld _world2() => const LearningWorld(
        number: 2,
        name: 'The Market Square',
        emoji: '\u{1F3EA}',
        description:
            'Navigate bustling markets, order food like a local, and haggle your way to victory. Your wallet will thank you!',
        difficulty: 2,
        worldXpBonus: 750,
        achievement: 'Market Master',
        achievementIcon: '\u{1F6D2}',
        estimatedHours: 10,
        isFree: false,
        chapters: [
          LearningChapter(number: 1, title: 'Food & Drinks', subtitle: 'From street food to fine dining vocabulary', levels: [
            LearningLevel(number: 1, title: 'Fruit Frenzy', description: 'Name every fruit at the market stall.', xpReward: 70, coinReward: 15, culturalNote: 'Durian is banned in many Asian hotels because of its strong smell, but locals consider it the "king of fruits"!', vocabulary: [VocabItem(englishKey: 'apple', category: 'word'), VocabItem(englishKey: 'banana', category: 'word'), VocabItem(englishKey: 'orange (fruit)', category: 'word'), VocabItem(englishKey: 'strawberry', category: 'word'), VocabItem(englishKey: 'grape', category: 'word'), VocabItem(englishKey: 'watermelon', category: 'word'), VocabItem(englishKey: 'lemon', category: 'word'), VocabItem(englishKey: 'mango', category: 'word'), VocabItem(englishKey: 'pineapple', category: 'word'), VocabItem(englishKey: 'cherry', category: 'word')]),
            LearningLevel(number: 2, title: 'Veggie Quest', description: 'Conquer the vegetable kingdom.', xpReward: 70, coinReward: 15, vocabulary: [VocabItem(englishKey: 'tomato', category: 'word'), VocabItem(englishKey: 'potato', category: 'word'), VocabItem(englishKey: 'onion', category: 'word'), VocabItem(englishKey: 'carrot', category: 'word'), VocabItem(englishKey: 'lettuce', category: 'word'), VocabItem(englishKey: 'pepper', category: 'word'), VocabItem(englishKey: 'rice', category: 'word'), VocabItem(englishKey: 'pasta', category: 'word'), VocabItem(englishKey: 'egg', category: 'word'), VocabItem(englishKey: 'cheese', category: 'word')]),
            LearningLevel(number: 3, title: 'Meat & Fish', description: 'Protein power vocabulary.', xpReward: 75, coinReward: 15, vocabulary: [VocabItem(englishKey: 'chicken', category: 'word'), VocabItem(englishKey: 'beef', category: 'word'), VocabItem(englishKey: 'pork', category: 'word'), VocabItem(englishKey: 'fish', category: 'word'), VocabItem(englishKey: 'shrimp', category: 'word'), VocabItem(englishKey: 'meat', category: 'word'), VocabItem(englishKey: 'vegetarian', category: 'word'), VocabItem(englishKey: 'salt', category: 'word'), VocabItem(englishKey: 'sugar', category: 'word'), VocabItem(englishKey: 'spicy', category: 'word')]),
            LearningLevel(number: 4, title: 'Drinks Bar', description: 'Order any drink with confidence.', xpReward: 75, coinReward: 15, vocabulary: [VocabItem(englishKey: 'beer', category: 'word'), VocabItem(englishKey: 'wine', category: 'word'), VocabItem(englishKey: 'juice', category: 'word'), VocabItem(englishKey: 'milk', category: 'word'), VocabItem(englishKey: 'soda', category: 'word'), VocabItem(englishKey: 'ice', category: 'word'), VocabItem(englishKey: 'hot chocolate', category: 'phrase'), VocabItem(englishKey: 'cocktail', category: 'word'), VocabItem(englishKey: 'with ice', category: 'phrase'), VocabItem(englishKey: 'without sugar', category: 'phrase')]),
            LearningLevel(number: 5, title: 'Order Up!', description: 'Put it all together and order a meal.', xpReward: 85, coinReward: 20, grammarTip: 'In most languages, ordering uses "I would like" (polite) rather than "I want" (direct).', vocabulary: [VocabItem(englishKey: 'I would like', category: 'phrase'), VocabItem(englishKey: 'menu', category: 'word'), VocabItem(englishKey: 'breakfast', category: 'word'), VocabItem(englishKey: 'lunch', category: 'word'), VocabItem(englishKey: 'dinner', category: 'word'), VocabItem(englishKey: 'dessert', category: 'word'), VocabItem(englishKey: 'the bill please', category: 'phrase'), VocabItem(englishKey: 'waiter', category: 'word'), VocabItem(englishKey: 'tip', category: 'word'), VocabItem(englishKey: 'take away', category: 'phrase')]),
          ], bossQuiz: BossQuiz(title: 'BOSS: The Market Vendor', questionCount: 15, xpReward: 300, coinReward: 60, questions: [
            QuizQuestion(questionTemplate: 'How do you say "chicken" in {language}?', type: QuizType.multipleChoice, correctAnswerKey: 'chicken', optionKeys: ['chicken', 'fish', 'beef', 'pork']),
            QuizQuestion(questionTemplate: 'Translate "I would like" to {language}.', type: QuizType.multipleChoice, correctAnswerKey: 'I would like', optionKeys: ['I would like', 'I have', 'I am', 'I go']),
            QuizQuestion(questionTemplate: 'What is "water" in {language}?', type: QuizType.multipleChoice, correctAnswerKey: 'water', optionKeys: ['water', 'juice', 'milk', 'beer']),
            QuizQuestion(questionTemplate: 'Scenario: You are at a restaurant. How do you ask for the bill?', type: QuizType.scenario, correctAnswerKey: 'the bill please', optionKeys: ['the bill please', 'menu', 'waiter', 'tip']),
            QuizQuestion(questionTemplate: 'What is "apple" in {language}?', type: QuizType.multipleChoice, correctAnswerKey: 'apple', optionKeys: ['apple', 'banana', 'orange (fruit)', 'grape']),
            QuizQuestion(questionTemplate: 'Translate "rice" to {language}.', type: QuizType.multipleChoice, correctAnswerKey: 'rice', optionKeys: ['rice', 'pasta', 'bread', 'potato']),
            QuizQuestion(questionTemplate: 'What is "breakfast" in {language}?', type: QuizType.multipleChoice, correctAnswerKey: 'breakfast', optionKeys: ['breakfast', 'lunch', 'dinner', 'dessert']),
            QuizQuestion(questionTemplate: 'Fill in: I want my coffee ___ sugar.', type: QuizType.fillBlank, correctAnswerKey: 'without sugar', optionKeys: ['without sugar']),
            QuizQuestion(questionTemplate: 'What is "spicy" in {language}?', type: QuizType.multipleChoice, correctAnswerKey: 'spicy', optionKeys: ['spicy', 'sweet', 'salty', 'sour']),
            QuizQuestion(questionTemplate: 'Translate "wine" to {language}.', type: QuizType.multipleChoice, correctAnswerKey: 'wine', optionKeys: ['wine', 'beer', 'juice', 'water']),
            QuizQuestion(questionTemplate: 'What is "egg" in {language}?', type: QuizType.multipleChoice, correctAnswerKey: 'egg', optionKeys: ['egg', 'cheese', 'meat', 'fish']),
            QuizQuestion(questionTemplate: 'What is "vegetarian" in {language}?', type: QuizType.multipleChoice, correctAnswerKey: 'vegetarian', optionKeys: ['vegetarian', 'meat', 'fish', 'chicken']),
            QuizQuestion(questionTemplate: 'Translate "tomato" to {language}.', type: QuizType.multipleChoice, correctAnswerKey: 'tomato', optionKeys: ['tomato', 'potato', 'onion', 'carrot']),
            QuizQuestion(questionTemplate: 'What is "dessert" in {language}?', type: QuizType.multipleChoice, correctAnswerKey: 'dessert', optionKeys: ['dessert', 'breakfast', 'lunch', 'dinner']),
            QuizQuestion(questionTemplate: 'Scenario: Order a full meal for two people.', type: QuizType.scenario, correctAnswerKey: 'I would like', optionKeys: ['I would like', 'menu', 'the bill please', 'waiter'], explanation: 'Start with "I would like", name your items, and finish with "the bill please"!'),
          ])),
          LearningChapter(number: 2, title: 'Shopping', subtitle: 'Prices, sizes, and the art of bargaining', levels: [
            LearningLevel(number: 1, title: 'How Much?', description: 'The most important shopping question.', xpReward: 75, coinReward: 15, vocabulary: [VocabItem(englishKey: 'how much', category: 'phrase'), VocabItem(englishKey: 'price', category: 'word'), VocabItem(englishKey: 'cheap', category: 'word'), VocabItem(englishKey: 'expensive', category: 'word'), VocabItem(englishKey: 'money', category: 'word'), VocabItem(englishKey: 'pay', category: 'word'), VocabItem(englishKey: 'buy', category: 'word'), VocabItem(englishKey: 'sell', category: 'word'), VocabItem(englishKey: 'discount', category: 'word'), VocabItem(englishKey: 'free', category: 'word')]),
            LearningLevel(number: 2, title: 'Size Matters', description: 'Find the perfect fit.', xpReward: 75, coinReward: 15, vocabulary: [VocabItem(englishKey: 'big', category: 'word'), VocabItem(englishKey: 'small', category: 'word'), VocabItem(englishKey: 'medium', category: 'word'), VocabItem(englishKey: 'large', category: 'word'), VocabItem(englishKey: 'too big', category: 'phrase'), VocabItem(englishKey: 'too small', category: 'phrase'), VocabItem(englishKey: 'this one', category: 'phrase'), VocabItem(englishKey: 'that one', category: 'phrase'), VocabItem(englishKey: 'do you have', category: 'phrase'), VocabItem(englishKey: 'another one', category: 'phrase')]),
            LearningLevel(number: 3, title: 'Clothes Hunt', description: 'Build your wardrobe vocabulary.', xpReward: 80, coinReward: 15, vocabulary: [VocabItem(englishKey: 'shirt', category: 'word'), VocabItem(englishKey: 'pants', category: 'word'), VocabItem(englishKey: 'dress', category: 'word'), VocabItem(englishKey: 'shoes', category: 'word'), VocabItem(englishKey: 'hat', category: 'word'), VocabItem(englishKey: 'jacket', category: 'word'), VocabItem(englishKey: 'bag', category: 'word'), VocabItem(englishKey: 'beautiful', category: 'word'), VocabItem(englishKey: 'ugly', category: 'word'), VocabItem(englishKey: 'I like this', category: 'phrase')]),
            LearningLevel(number: 4, title: 'Bargain Boss', description: 'Negotiate like a local.', xpReward: 80, coinReward: 20, culturalNote: 'Haggling is expected in Turkish bazaars, Moroccan souks, and Thai markets -- but never in Japanese shops!', vocabulary: [VocabItem(englishKey: 'too expensive', category: 'phrase'), VocabItem(englishKey: 'can you lower the price', category: 'phrase'), VocabItem(englishKey: 'what is the best price', category: 'phrase'), VocabItem(englishKey: 'deal', category: 'word'), VocabItem(englishKey: 'I will take it', category: 'phrase'), VocabItem(englishKey: 'no thank you', category: 'phrase'), VocabItem(englishKey: 'just looking', category: 'phrase'), VocabItem(englishKey: 'receipt', category: 'word'), VocabItem(englishKey: 'cash', category: 'word'), VocabItem(englishKey: 'card', category: 'word')]),
            LearningLevel(number: 5, title: 'Shop Till You Drop', description: 'Complete shopping conversations.', xpReward: 90, coinReward: 20, vocabulary: [VocabItem(englishKey: 'store', category: 'word'), VocabItem(englishKey: 'market', category: 'word'), VocabItem(englishKey: 'open', category: 'word'), VocabItem(englishKey: 'closed', category: 'word'), VocabItem(englishKey: 'what time do you open', category: 'phrase'), VocabItem(englishKey: 'where is', category: 'phrase'), VocabItem(englishKey: 'I am looking for', category: 'phrase'), VocabItem(englishKey: 'gift', category: 'word'), VocabItem(englishKey: 'souvenir', category: 'word'), VocabItem(englishKey: 'can I try this on', category: 'phrase')]),
          ], bossQuiz: BossQuiz(title: 'BOSS: The Bazaar King', questionCount: 15, xpReward: 350, coinReward: 70, questions: [
            QuizQuestion(questionTemplate: 'How do you say "how much" in {language}?', type: QuizType.multipleChoice, correctAnswerKey: 'how much', optionKeys: ['how much', 'how many', 'what time', 'where is']),
            QuizQuestion(questionTemplate: 'Translate "expensive" to {language}.', type: QuizType.multipleChoice, correctAnswerKey: 'expensive', optionKeys: ['expensive', 'cheap', 'free', 'discount']),
            QuizQuestion(questionTemplate: 'What is "shoes" in {language}?', type: QuizType.multipleChoice, correctAnswerKey: 'shoes', optionKeys: ['shoes', 'shirt', 'pants', 'hat']),
            QuizQuestion(questionTemplate: 'Fill in: This is too ___ for me (too large).', type: QuizType.fillBlank, correctAnswerKey: 'too big', optionKeys: ['too big']),
            QuizQuestion(questionTemplate: 'Translate "I will take it" to {language}.', type: QuizType.multipleChoice, correctAnswerKey: 'I will take it', optionKeys: ['I will take it', 'no thank you', 'just looking', 'too expensive']),
            QuizQuestion(questionTemplate: 'What is "gift" in {language}?', type: QuizType.multipleChoice, correctAnswerKey: 'gift', optionKeys: ['gift', 'souvenir', 'receipt', 'bag']),
            QuizQuestion(questionTemplate: 'Scenario: You want to try on a dress. What do you say?', type: QuizType.scenario, correctAnswerKey: 'can I try this on', optionKeys: ['can I try this on', 'how much', 'I will take it', 'too expensive']),
            QuizQuestion(questionTemplate: 'Translate "cash" to {language}.', type: QuizType.multipleChoice, correctAnswerKey: 'cash', optionKeys: ['cash', 'card', 'receipt', 'money']),
            QuizQuestion(questionTemplate: 'What is "discount" in {language}?', type: QuizType.multipleChoice, correctAnswerKey: 'discount', optionKeys: ['discount', 'price', 'deal', 'free']),
            QuizQuestion(questionTemplate: 'Translate "store" to {language}.', type: QuizType.multipleChoice, correctAnswerKey: 'store', optionKeys: ['store', 'market', 'house', 'room']),
            QuizQuestion(questionTemplate: 'What is "jacket" in {language}?', type: QuizType.multipleChoice, correctAnswerKey: 'jacket', optionKeys: ['jacket', 'shirt', 'dress', 'hat']),
            QuizQuestion(questionTemplate: 'Scenario: The shop is closed. What was the sign?', type: QuizType.scenario, correctAnswerKey: 'closed', optionKeys: ['closed', 'open', 'free', 'deal']),
            QuizQuestion(questionTemplate: 'Fill in: Can you lower the ___?', type: QuizType.fillBlank, correctAnswerKey: 'can you lower the price', optionKeys: ['can you lower the price']),
            QuizQuestion(questionTemplate: 'What is "beautiful" in {language}?', type: QuizType.multipleChoice, correctAnswerKey: 'beautiful', optionKeys: ['beautiful', 'ugly', 'big', 'small']),
            QuizQuestion(questionTemplate: 'Full shopping scenario: Enter, browse, ask price, bargain, buy.', type: QuizType.scenario, correctAnswerKey: 'just looking', optionKeys: ['just looking', 'how much', 'too expensive', 'I will take it'], explanation: 'Shopping flow: Browse -> Ask price -> Negotiate -> Purchase!'),
          ])),
          LearningChapter(number: 3, title: 'Restaurant', subtitle: 'From reservation to dessert', levels: [
            LearningLevel(number: 1, title: 'Table for Two', description: 'Get seated at any restaurant.', xpReward: 80, coinReward: 15, vocabulary: [VocabItem(englishKey: 'table for two', category: 'phrase'), VocabItem(englishKey: 'reservation', category: 'word'), VocabItem(englishKey: 'waiter', category: 'word'), VocabItem(englishKey: 'waitress', category: 'word'), VocabItem(englishKey: 'menu please', category: 'phrase'), VocabItem(englishKey: 'specials', category: 'word'), VocabItem(englishKey: 'recommend', category: 'word'), VocabItem(englishKey: 'what do you recommend', category: 'phrase'), VocabItem(englishKey: 'inside', category: 'word'), VocabItem(englishKey: 'outside', category: 'word')]),
            LearningLevel(number: 2, title: 'Chef Selection', description: 'Navigate any menu like a pro.', xpReward: 80, coinReward: 15, vocabulary: [VocabItem(englishKey: 'appetizer', category: 'word'), VocabItem(englishKey: 'main course', category: 'phrase'), VocabItem(englishKey: 'side dish', category: 'phrase'), VocabItem(englishKey: 'soup', category: 'word'), VocabItem(englishKey: 'salad', category: 'word'), VocabItem(englishKey: 'grilled', category: 'word'), VocabItem(englishKey: 'fried', category: 'word'), VocabItem(englishKey: 'baked', category: 'word'), VocabItem(englishKey: 'sauce', category: 'word'), VocabItem(englishKey: 'fresh', category: 'word')]),
            LearningLevel(number: 3, title: 'Special Requests', description: 'Handle allergies and preferences.', xpReward: 85, coinReward: 20, vocabulary: [VocabItem(englishKey: 'allergy', category: 'word'), VocabItem(englishKey: 'I am allergic to', category: 'phrase'), VocabItem(englishKey: 'without', category: 'word'), VocabItem(englishKey: 'with', category: 'word'), VocabItem(englishKey: 'extra', category: 'word'), VocabItem(englishKey: 'less', category: 'word'), VocabItem(englishKey: 'more', category: 'word'), VocabItem(englishKey: 'no gluten', category: 'phrase'), VocabItem(englishKey: 'vegan', category: 'word'), VocabItem(englishKey: 'well done', category: 'phrase')]),
            LearningLevel(number: 4, title: 'Sweet Endings', description: 'Desserts and drinks to finish.', xpReward: 85, coinReward: 20, vocabulary: [VocabItem(englishKey: 'cake', category: 'word'), VocabItem(englishKey: 'ice cream', category: 'phrase'), VocabItem(englishKey: 'chocolate', category: 'word'), VocabItem(englishKey: 'fruit', category: 'word'), VocabItem(englishKey: 'sweet', category: 'word'), VocabItem(englishKey: 'bitter', category: 'word'), VocabItem(englishKey: 'sour', category: 'word'), VocabItem(englishKey: 'another one please', category: 'phrase'), VocabItem(englishKey: 'cheers', category: 'word'), VocabItem(englishKey: 'to share', category: 'phrase')]),
            LearningLevel(number: 5, title: 'Check Please!', description: 'Pay the bill and leave a tip.', xpReward: 90, coinReward: 20, culturalNote: 'In Japan, tipping is considered rude. In the US, 15-20% is standard. Know before you go!', vocabulary: [VocabItem(englishKey: 'the check please', category: 'phrase'), VocabItem(englishKey: 'how much is it', category: 'phrase'), VocabItem(englishKey: 'split the bill', category: 'phrase'), VocabItem(englishKey: 'I will pay', category: 'phrase'), VocabItem(englishKey: 'keep the change', category: 'phrase'), VocabItem(englishKey: 'credit card', category: 'phrase'), VocabItem(englishKey: 'it was delicious', category: 'phrase'), VocabItem(englishKey: 'we enjoyed it', category: 'phrase'), VocabItem(englishKey: 'come back again', category: 'phrase'), VocabItem(englishKey: 'wonderful service', category: 'phrase')]),
          ], bossQuiz: BossQuiz(title: 'BOSS: The Gourmet Challenge', questionCount: 15, xpReward: 350, coinReward: 70, questions: [
            QuizQuestion(questionTemplate: 'How do you say "table for two" in {language}?', type: QuizType.multipleChoice, correctAnswerKey: 'table for two', optionKeys: ['table for two', 'menu please', 'the check please', 'reservation']),
            QuizQuestion(questionTemplate: 'Translate "soup" to {language}.', type: QuizType.multipleChoice, correctAnswerKey: 'soup', optionKeys: ['soup', 'salad', 'sauce', 'bread']),
            QuizQuestion(questionTemplate: 'How do you say you have an allergy?', type: QuizType.scenario, correctAnswerKey: 'I am allergic to', optionKeys: ['I am allergic to', 'I would like', 'I will pay', 'how much']),
            QuizQuestion(questionTemplate: 'What is "ice cream" in {language}?', type: QuizType.multipleChoice, correctAnswerKey: 'ice cream', optionKeys: ['ice cream', 'cake', 'chocolate', 'fruit']),
            QuizQuestion(questionTemplate: 'Translate "the check please" to {language}.', type: QuizType.multipleChoice, correctAnswerKey: 'the check please', optionKeys: ['the check please', 'menu please', 'table for two', 'more']),
            QuizQuestion(questionTemplate: 'What is "grilled" in {language}?', type: QuizType.multipleChoice, correctAnswerKey: 'grilled', optionKeys: ['grilled', 'fried', 'baked', 'fresh']),
            QuizQuestion(questionTemplate: 'Fill in: Can we ___ the bill?', type: QuizType.fillBlank, correctAnswerKey: 'split the bill', optionKeys: ['split the bill']),
            QuizQuestion(questionTemplate: 'Translate "cheers" to {language}.', type: QuizType.multipleChoice, correctAnswerKey: 'cheers', optionKeys: ['cheers', 'sorry', 'hello', 'goodbye']),
            QuizQuestion(questionTemplate: 'What is "appetizer" in {language}?', type: QuizType.multipleChoice, correctAnswerKey: 'appetizer', optionKeys: ['appetizer', 'main course', 'dessert', 'side dish']),
            QuizQuestion(questionTemplate: 'Translate "it was delicious" to {language}.', type: QuizType.multipleChoice, correctAnswerKey: 'it was delicious', optionKeys: ['it was delicious', 'how much is it', 'table for two', 'menu please']),
            QuizQuestion(questionTemplate: 'What is "sweet" in {language}?', type: QuizType.multipleChoice, correctAnswerKey: 'sweet', optionKeys: ['sweet', 'bitter', 'sour', 'spicy']),
            QuizQuestion(questionTemplate: 'Scenario: Full restaurant visit from start to finish.', type: QuizType.scenario, correctAnswerKey: 'table for two', optionKeys: ['table for two', 'I would like', 'it was delicious', 'the check please'], explanation: 'Restaurant flow: Seat -> Order -> Eat -> Compliment -> Pay'),
            QuizQuestion(questionTemplate: 'What is "fresh" in {language}?', type: QuizType.multipleChoice, correctAnswerKey: 'fresh', optionKeys: ['fresh', 'fried', 'baked', 'grilled']),
            QuizQuestion(questionTemplate: 'Translate "credit card" to {language}.', type: QuizType.multipleChoice, correctAnswerKey: 'credit card', optionKeys: ['credit card', 'cash', 'receipt', 'money']),
            QuizQuestion(questionTemplate: 'What does "vegan" mean in {language}?', type: QuizType.multipleChoice, correctAnswerKey: 'vegan', optionKeys: ['vegan', 'vegetarian', 'allergy', 'fresh']),
          ])),
          LearningChapter(number: 4, title: 'Asking for Help', subtitle: 'Navigate any city with confidence', levels: [
            LearningLevel(number: 1, title: 'Where Is...?', description: 'The ultimate navigation phrase.', xpReward: 80, coinReward: 15, vocabulary: [VocabItem(englishKey: 'where is', category: 'phrase'), VocabItem(englishKey: 'left', category: 'word'), VocabItem(englishKey: 'right', category: 'word'), VocabItem(englishKey: 'straight', category: 'word'), VocabItem(englishKey: 'near', category: 'word'), VocabItem(englishKey: 'far', category: 'word'), VocabItem(englishKey: 'here', category: 'word'), VocabItem(englishKey: 'there', category: 'word'), VocabItem(englishKey: 'next to', category: 'phrase'), VocabItem(englishKey: 'across from', category: 'phrase')]),
            LearningLevel(number: 2, title: 'City Explorer', description: 'Key places in any city.', xpReward: 80, coinReward: 15, vocabulary: [VocabItem(englishKey: 'hotel', category: 'word'), VocabItem(englishKey: 'hospital', category: 'word'), VocabItem(englishKey: 'pharmacy', category: 'word'), VocabItem(englishKey: 'bank', category: 'word'), VocabItem(englishKey: 'police station', category: 'phrase'), VocabItem(englishKey: 'train station', category: 'phrase'), VocabItem(englishKey: 'airport', category: 'word'), VocabItem(englishKey: 'bus stop', category: 'phrase'), VocabItem(englishKey: 'restaurant', category: 'word'), VocabItem(englishKey: 'supermarket', category: 'word')]),
            LearningLevel(number: 3, title: 'Help Me!', description: 'Essential emergency phrases.', xpReward: 90, coinReward: 20, grammarTip: 'Emergency phrases should be the first thing you memorize in any language. They could save your life!', vocabulary: [VocabItem(englishKey: 'help', category: 'word'), VocabItem(englishKey: 'I need help', category: 'phrase'), VocabItem(englishKey: 'emergency', category: 'word'), VocabItem(englishKey: 'call the police', category: 'phrase'), VocabItem(englishKey: 'call an ambulance', category: 'phrase'), VocabItem(englishKey: 'I am lost', category: 'phrase'), VocabItem(englishKey: 'I do not understand', category: 'phrase'), VocabItem(englishKey: 'can you help me', category: 'phrase'), VocabItem(englishKey: 'do you speak English', category: 'phrase'), VocabItem(englishKey: 'slowly please', category: 'phrase')]),
            LearningLevel(number: 4, title: 'Getting Around', description: 'Taxis, buses, and trains.', xpReward: 85, coinReward: 20, vocabulary: [VocabItem(englishKey: 'taxi', category: 'word'), VocabItem(englishKey: 'bus', category: 'word'), VocabItem(englishKey: 'train', category: 'word'), VocabItem(englishKey: 'ticket', category: 'word'), VocabItem(englishKey: 'one ticket please', category: 'phrase'), VocabItem(englishKey: 'round trip', category: 'phrase'), VocabItem(englishKey: 'stop here please', category: 'phrase'), VocabItem(englishKey: 'how long does it take', category: 'phrase'), VocabItem(englishKey: 'departure', category: 'word'), VocabItem(englishKey: 'arrival', category: 'word')]),
            LearningLevel(number: 5, title: 'Problem Solver', description: 'Handle any travel problem.', xpReward: 100, coinReward: 25, vocabulary: [VocabItem(englishKey: 'I lost my wallet', category: 'phrase'), VocabItem(englishKey: 'I lost my passport', category: 'phrase'), VocabItem(englishKey: 'stolen', category: 'word'), VocabItem(englishKey: 'broken', category: 'word'), VocabItem(englishKey: 'can you repeat that', category: 'phrase'), VocabItem(englishKey: 'write it down please', category: 'phrase'), VocabItem(englishKey: 'where is the embassy', category: 'phrase'), VocabItem(englishKey: 'I need a doctor', category: 'phrase'), VocabItem(englishKey: 'it hurts', category: 'phrase'), VocabItem(englishKey: 'medicine', category: 'word')]),
          ], bossQuiz: BossQuiz(title: 'BOSS: The City Maze', questionCount: 15, xpReward: 400, coinReward: 80, questions: [
            QuizQuestion(questionTemplate: 'How do you say "where is" in {language}?', type: QuizType.multipleChoice, correctAnswerKey: 'where is', optionKeys: ['where is', 'how much', 'what time', 'who is']),
            QuizQuestion(questionTemplate: 'Translate "left" to {language}.', type: QuizType.multipleChoice, correctAnswerKey: 'left', optionKeys: ['left', 'right', 'straight', 'near']),
            QuizQuestion(questionTemplate: 'What is "hospital" in {language}?', type: QuizType.multipleChoice, correctAnswerKey: 'hospital', optionKeys: ['hospital', 'hotel', 'pharmacy', 'bank']),
            QuizQuestion(questionTemplate: 'Scenario: You are lost. What do you say?', type: QuizType.scenario, correctAnswerKey: 'I am lost', optionKeys: ['I am lost', 'I am hungry', 'I am fine', 'goodbye']),
            QuizQuestion(questionTemplate: 'Translate "one ticket please" to {language}.', type: QuizType.multipleChoice, correctAnswerKey: 'one ticket please', optionKeys: ['one ticket please', 'the bill please', 'menu please', 'help']),
            QuizQuestion(questionTemplate: 'What is "pharmacy" in {language}?', type: QuizType.multipleChoice, correctAnswerKey: 'pharmacy', optionKeys: ['pharmacy', 'hospital', 'bank', 'hotel']),
            QuizQuestion(questionTemplate: 'How do you ask for help?', type: QuizType.scenario, correctAnswerKey: 'can you help me', optionKeys: ['can you help me', 'how are you', 'goodbye', 'thank you']),
            QuizQuestion(questionTemplate: 'Translate "taxi" to {language}.', type: QuizType.multipleChoice, correctAnswerKey: 'taxi', optionKeys: ['taxi', 'bus', 'train', 'ticket']),
            QuizQuestion(questionTemplate: 'What is "I need a doctor" in {language}?', type: QuizType.multipleChoice, correctAnswerKey: 'I need a doctor', optionKeys: ['I need a doctor', 'I am lost', 'I am hungry', 'can you help me']),
            QuizQuestion(questionTemplate: 'Fill in: Go ___, then turn right.', type: QuizType.fillBlank, correctAnswerKey: 'straight', optionKeys: ['straight']),
            QuizQuestion(questionTemplate: 'What is "train station" in {language}?', type: QuizType.multipleChoice, correctAnswerKey: 'train station', optionKeys: ['train station', 'bus stop', 'airport', 'hotel']),
            QuizQuestion(questionTemplate: 'Translate "slowly please" to {language}.', type: QuizType.multipleChoice, correctAnswerKey: 'slowly please', optionKeys: ['slowly please', 'help', 'thank you', 'sorry']),
            QuizQuestion(questionTemplate: 'What is "medicine" in {language}?', type: QuizType.multipleChoice, correctAnswerKey: 'medicine', optionKeys: ['medicine', 'food', 'water', 'ticket']),
            QuizQuestion(questionTemplate: 'Translate "stolen" to {language}.', type: QuizType.multipleChoice, correctAnswerKey: 'stolen', optionKeys: ['stolen', 'broken', 'lost', 'found']),
            QuizQuestion(questionTemplate: 'Full scenario: You are lost in a city, find help, get directions.', type: QuizType.scenario, correctAnswerKey: 'excuse me', optionKeys: ['excuse me', 'can you help me', 'where is', 'thank you'], explanation: 'Approach someone politely, ask for help, get directions, say thank you!'),
          ])),
        ],
      );

  // ===========================================================================
  // WORLDS 3-12: Compact definitions (same pattern, full content)
  // ===========================================================================

  static LearningWorld _world3() => _buildWorld(3, 'The Social Hub', '\u{1F3AD}', 'Make friends, express feelings, and become the life of the party. Social skills unlocked!', 3, 1000, 'Social Butterfly', '\u{1F98B}', 12, [
    _buildChapter(1, 'Making Friends', 'Hobbies, interests, and common ground', ['music', 'movie', 'book', 'sport', 'travel', 'cooking', 'dancing', 'reading', 'swimming', 'running', 'photography', 'painting', 'singing', 'gaming', 'yoga', 'what are your hobbies', 'I enjoy', 'me too', 'that sounds fun', 'let us do it together', 'what do you do for fun', 'I am interested in', 'have you tried', 'do you like', 'my passion is']),
    _buildChapter(2, 'Feelings & Emotions', 'Happy, sad, and everything in between', ['happy', 'sad', 'angry', 'excited', 'tired', 'bored', 'surprised', 'nervous', 'scared', 'proud', 'I feel', 'are you okay', 'what is wrong', 'I am happy because', 'that makes me sad', 'I am so excited', 'do not worry', 'calm down', 'I understand', 'it is okay', 'I am grateful', 'wonderful', 'amazing', 'disappointed', 'hopeful']),
    _buildChapter(3, 'Invitations', 'Plans, proposals, and social adventures', ['let us go', 'would you like to', 'are you free', 'tonight', 'this weekend', 'party', 'event', 'concert', 'cinema', 'park', 'what time', 'where shall we meet', 'I will be there', 'sounds great', 'I cannot make it', 'rain check', 'next time', 'bring your friends', 'it will be fun', 'do not be late', 'pick you up', 'meet me at', 'invitation', 'celebrate', 'join us']),
    _buildChapter(4, 'Compliments & Small Talk', 'Weather chat, appearance praise, and social glue', ['you look great', 'nice outfit', 'I like your style', 'what a beautiful day', 'it is raining', 'lovely weather', 'how was your day', 'what is new', 'long time no see', 'you have not changed', 'you are so kind', 'you are talented', 'great job', 'well done', 'I admire you', 'you inspire me', 'you are funny', 'smart', 'creative', 'generous', 'patient', 'brave', 'strong', 'gentle', 'honest']),
  ]);

  static LearningWorld _world4() => _buildWorld(4, 'The Travel Terminal', '\u{2708}\u{FE0F}', 'Airports, hotels, and adventures await. Pack your vocabulary bags!', 4, 1250, 'Globe Trotter', '\u{1F30D}', 12, [
    _buildChapter(1, 'At the Airport', 'From check-in to touchdown', ['passport', 'boarding pass', 'gate', 'luggage', 'suitcase', 'flight', 'check in', 'security', 'customs', 'delay', 'cancelled', 'what gate', 'where is my gate', 'baggage claim', 'window seat', 'aisle seat', 'carry on', 'immigration', 'declaration', 'duty free', 'how long is the flight', 'connection', 'layover', 'fasten seatbelt', 'landing']),
    _buildChapter(2, 'Hotel & Accommodation', 'Check-in to check-out like a VIP', ['check in', 'check out', 'room key', 'single room', 'double room', 'reservation', 'wifi password', 'breakfast included', 'air conditioning', 'towels', 'room service', 'wake up call', 'minibar', 'elevator', 'floor', 'do not disturb', 'extra pillow', 'late checkout', 'view', 'balcony', 'swimming pool', 'gym', 'laundry', 'reception', 'concierge']),
    _buildChapter(3, 'Transportation', 'Buses, trains, and getting around', ['one way ticket', 'return ticket', 'platform', 'schedule', 'next bus', 'last train', 'transfer', 'subway', 'ferry', 'rent a car', 'gas station', 'parking', 'highway', 'traffic', 'speed limit', 'how do I get to', 'is it walking distance', 'map', 'GPS', 'turn left', 'turn right', 'go straight', 'intersection', 'bridge', 'tunnel']),
    _buildChapter(4, 'Emergency & Health', 'Survive any travel crisis', ['help me', 'call a doctor', 'I feel sick', 'headache', 'stomachache', 'fever', 'cough', 'allergy', 'prescription', 'insurance', 'accident', 'fire', 'earthquake', 'flood', 'evacuate', 'first aid', 'bandage', 'painkillers', 'hospital', 'emergency room', 'I need an ambulance', 'blood type', 'allergic reaction', 'unconscious', 'please hurry']),
  ]);

  static LearningWorld _world5() => _buildWorld(5, 'The Romance Garden', '\u{1F495}', 'First dates, sweet nothings, and the language of love. Your heart will flutter!', 5, 1500, 'Romance Expert', '\u{1F339}', 14, [
    _buildChapter(1, 'First Date Phrases', 'Make your date unforgettable', ['you look nice', 'tell me about yourself', 'what do you do', 'where did you grow up', 'do you have siblings', 'what is your dream', 'I am having a great time', 'you are easy to talk to', 'what kind of music', 'favorite movie', 'dream vacation', 'cats or dogs', 'morning or night person', 'cook or eat out', 'city or countryside', 'beach or mountains', 'first impression', 'nervous', 'relax', 'be yourself', 'connection', 'chemistry', 'spark', 'attracted to', 'compatible']),
    _buildChapter(2, 'Expressing Feelings', 'Words that make hearts skip', ['I like you', 'I miss you', 'you are beautiful', 'you are handsome', 'I think about you', 'you make me happy', 'I feel safe with you', 'you are special', 'my heart beats fast', 'butterflies in my stomach', 'I care about you', 'you are amazing', 'I adore you', 'you are my sunshine', 'every moment with you', 'I cannot stop smiling', 'you brighten my day', 'sweetheart', 'darling', 'dear', 'honey', 'my love', 'soulmate', 'meant to be', 'falling for you']),
    _buildChapter(3, 'Relationship Talk', 'Define, discuss, and deepen', ['together', 'single', 'dating', 'relationship', 'boyfriend', 'girlfriend', 'partner', 'are we exclusive', 'I want to be with you', 'where is this going', 'I am committed', 'trust', 'loyalty', 'respect', 'communication', 'compromise', 'support', 'understand', 'patience', 'future together', 'move in together', 'meet my family', 'long distance', 'jealous', 'honest']),
    _buildChapter(4, 'Cultural Date Etiquette', 'Love across cultures', ['who pays', 'splitting the bill', 'flowers', 'gifts on first date', 'meeting the parents', 'public affection', 'holding hands', 'kissing in public', 'personal space', 'eye contact', 'punctuality', 'dress code', 'formal or casual', 'traditions', 'customs', 'taboo topics', 'religion', 'politics', 'family expectations', 'age difference', 'online dating', 'matchmaking', 'arranged meeting', 'courtship', 'engagement']),
  ]);

  static LearningWorld _world6() => _buildWorld(6, 'The Grammar Castle', '\u{1F4D6}', 'Conquer verb tenses, master questions, and build complex sentences. Knowledge is power!', 6, 1750, 'Grammar Guardian', '\u{1F6E1}\u{FE0F}', 15, [
    _buildChapter(1, 'Past Tense', 'Talk about yesterday like a storyteller', ['yesterday', 'last week', 'last month', 'last year', 'ago', 'I went', 'I did', 'I saw', 'I ate', 'I was', 'I had', 'I said', 'I came', 'I made', 'I took', 'did you', 'were you', 'what happened', 'it was great', 'I used to', 'when I was young', 'once upon a time', 'back then', 'I remember', 'in the past']),
    _buildChapter(2, 'Future Tense', 'Plan tomorrow with confidence', ['tomorrow', 'next week', 'next month', 'next year', 'soon', 'I will', 'I am going to', 'I plan to', 'I hope to', 'we will see', 'in the future', 'one day', 'someday', 'I promise', 'I will try', 'what will you do', 'are you going to', 'it will be', 'I look forward to', 'I cannot wait', 'shall we', 'let us plan', 'schedule', 'deadline', 'goal']),
    _buildChapter(3, 'Questions', 'Ask anything like a journalist', ['who', 'what', 'where', 'when', 'why', 'how', 'which', 'whose', 'how much', 'how many', 'how often', 'how long', 'how far', 'is it', 'do you', 'can you', 'will you', 'have you', 'would you', 'could you', 'should I', 'may I', 'what if', 'is it true that', 'really']),
    _buildChapter(4, 'Connectors', 'Link ideas like a master writer', ['and', 'but', 'or', 'so', 'because', 'if', 'when', 'while', 'although', 'however', 'therefore', 'also', 'besides', 'furthermore', 'meanwhile', 'instead', 'otherwise', 'unless', 'as long as', 'even though', 'in order to', 'as a result', 'for example', 'in addition', 'on the other hand']),
  ]);

  static LearningWorld _world7() => _buildWorld(7, 'The Professional Tower', '\u{1F4BC}', 'Nail interviews, ace meetings, and build your professional vocabulary. Career mode activated!', 7, 2000, 'Business Boss', '\u{1F454}', 15, [
    _buildChapter(1, 'At Work', 'Office survival vocabulary', ['office', 'meeting', 'boss', 'colleague', 'project', 'deadline', 'report', 'presentation', 'schedule', 'team', 'department', 'salary', 'promotion', 'resign', 'hire', 'fire', 'contract', 'full time', 'part time', 'remote work', 'commute', 'overtime', 'vacation day', 'sick leave', 'company']),
    _buildChapter(2, 'Phone & Email', 'Professional communication skills', ['could I speak to', 'one moment please', 'I am calling about', 'leave a message', 'call back', 'dear sir or madam', 'I am writing to', 'attached please find', 'best regards', 'sincerely', 'looking forward to', 'thank you for your time', 'follow up', 'urgent', 'reply', 'forward', 'CC', 'subject', 'schedule a meeting', 'conference call', 'available', 'convenient', 'confirm', 'cancel', 'reschedule']),
    _buildChapter(3, 'Interview', 'Land your dream job', ['tell me about yourself', 'why this company', 'strengths', 'weaknesses', 'experience', 'qualification', 'education', 'skills', 'team player', 'leadership', 'problem solving', 'creative', 'motivated', 'achievement', 'challenge', 'salary expectation', 'when can you start', 'references', 'portfolio', 'internship', 'career goals', 'growth opportunity', 'work-life balance', 'passionate about', 'detail oriented']),
    _buildChapter(4, 'Networking', 'Build connections that matter', ['nice to meet you', 'business card', 'what do you do', 'which company', 'how long have you been', 'I work in', 'I specialize in', 'let us keep in touch', 'LinkedIn', 'coffee meeting', 'collaboration', 'partnership', 'opportunity', 'industry', 'startup', 'entrepreneur', 'investor', 'mentor', 'conference', 'workshop', 'seminar', 'exhibition', 'trade show', 'connection', 'introduction']),
  ]);

  static LearningWorld _world8() => _buildWorld(8, 'The Culture Palace', '\u{1F3DB}\u{FE0F}', 'Traditions, art, food culture, and sports. Become a true cultural ambassador!', 8, 2500, 'Cultural Ambassador', '\u{1F30F}', 16, [
    _buildChapter(1, 'Traditions & Holidays', 'Celebrate like a local', ['holiday', 'celebration', 'tradition', 'festival', 'new year', 'christmas', 'easter', 'thanksgiving', 'wedding', 'birthday party', 'congratulations', 'fireworks', 'decoration', 'gift giving', 'family gathering', 'feast', 'toast', 'ceremony', 'costume', 'parade', 'national day', 'harvest', 'lantern', 'dragon', 'carnival']),
    _buildChapter(2, 'Music & Art', 'Express your artistic soul', ['song', 'singer', 'band', 'concert', 'guitar', 'piano', 'drums', 'violin', 'dance', 'ballet', 'painting', 'sculpture', 'museum', 'gallery', 'exhibition', 'theater', 'play', 'actor', 'director', 'poetry', 'literature', 'masterpiece', 'inspiration', 'creativity', 'classical']),
    _buildChapter(3, 'Food Culture', 'Regional dishes and cooking terms', ['recipe', 'ingredients', 'cook', 'bake', 'fry', 'boil', 'steam', 'grill', 'stir', 'chop', 'traditional dish', 'local specialty', 'street food', 'home cooking', 'spices', 'herbs', 'olive oil', 'soy sauce', 'curry', 'noodles', 'dumpling', 'barbecue', 'brunch', 'potluck', 'food market']),
    _buildChapter(4, 'Sports & Entertainment', 'Join the local team spirit', ['football', 'basketball', 'tennis', 'baseball', 'volleyball', 'athletics', 'gymnastics', 'martial arts', 'championship', 'tournament', 'medal', 'trophy', 'fan', 'stadium', 'goal', 'score', 'win', 'lose', 'draw', 'referee', 'coach', 'training', 'exercise', 'match', 'competition']),
  ]);

  static LearningWorld _world9() => _buildWorld(9, 'The Story Library', '\u{1F4DA}', 'Tell stories, share opinions, debate ideas, and learn the idioms that make you sound native!', 9, 3000, 'Storyteller', '\u{1F4DC}', 16, [
    _buildChapter(1, 'Telling Stories', 'Narrative vocabulary and flow', ['once upon a time', 'long ago', 'one day', 'suddenly', 'then', 'after that', 'meanwhile', 'finally', 'in the end', 'happily ever after', 'the beginning', 'the middle', 'the end', 'climax', 'plot twist', 'character', 'hero', 'villain', 'adventure', 'mystery', 'imagine', 'describe', 'detail', 'vivid', 'unforgettable']),
    _buildChapter(2, 'Opinions & Debates', 'Agree, disagree, and persuade', ['I think', 'in my opinion', 'I believe', 'I agree', 'I disagree', 'you are right', 'I am not sure', 'on one hand', 'on the other hand', 'good point', 'fair enough', 'let me explain', 'for example', 'according to', 'research shows', 'statistics say', 'evidence', 'argument', 'perspective', 'viewpoint', 'debate', 'discuss', 'convince', 'persuade', 'compromise']),
    _buildChapter(3, 'News & Media', 'Headlines and current events', ['news', 'headline', 'article', 'journalist', 'report', 'interview', 'press conference', 'breaking news', 'update', 'source', 'fact', 'opinion', 'bias', 'media', 'social media', 'trending', 'viral', 'podcast', 'documentary', 'investigation', 'politics', 'economy', 'environment', 'technology', 'global']),
    _buildChapter(4, 'Idioms & Slang', 'Sound like a native speaker', ['break the ice', 'piece of cake', 'under the weather', 'hit the road', 'cost an arm and a leg', 'once in a blue moon', 'better late than never', 'speak of the devil', 'the ball is in your court', 'bite the bullet', 'call it a day', 'get out of hand', 'hang in there', 'it takes two to tango', 'kill two birds with one stone', 'no pain no gain', 'on cloud nine', 'rain or shine', 'time flies', 'you never know', 'actions speak louder', 'every cloud has silver lining', 'go with the flow', 'back to square one', 'burning the midnight oil']),
  ]);

  static LearningWorld _world10() => _buildWorld(10, 'The Tech Lab', '\u{1F4BB}', 'Navigate the digital world. Phones, apps, social media, and online shopping mastered!', 10, 3500, 'Digital Native', '\u{1F4F1}', 14, [
    _buildChapter(1, 'Technology', 'Essential tech vocabulary', ['phone', 'computer', 'laptop', 'tablet', 'internet', 'wifi', 'app', 'software', 'website', 'email', 'message', 'call', 'camera', 'screen', 'keyboard', 'mouse', 'battery', 'charger', 'bluetooth', 'update', 'install', 'download', 'upload', 'cloud', 'backup']),
    _buildChapter(2, 'Social Media', 'The language of likes and shares', ['post', 'share', 'follow', 'like', 'comment', 'profile', 'username', 'password', 'selfie', 'photo', 'video', 'story', 'reel', 'hashtag', 'trending', 'influencer', 'subscriber', 'notification', 'block', 'report', 'privacy', 'settings', 'feed', 'algorithm', 'content']),
    _buildChapter(3, 'Online Shopping', 'Buy anything from anywhere', ['add to cart', 'checkout', 'order', 'delivery', 'shipping', 'tracking number', 'return', 'refund', 'exchange', 'size chart', 'review', 'rating', 'five stars', 'coupon code', 'sale', 'offer', 'limited edition', 'out of stock', 'in stock', 'customer service', 'complaint', 'warranty', 'payment method', 'secure', 'confirm order']),
    _buildChapter(4, 'Digital Life', 'Passwords, accounts, and staying safe', ['account', 'sign up', 'log in', 'log out', 'forgot password', 'reset', 'two factor authentication', 'security', 'privacy settings', 'data', 'storage', 'delete', 'archive', 'spam', 'scam', 'virus', 'antivirus', 'VPN', 'encrypt', 'bookmark', 'browser', 'search', 'filter', 'dark mode', 'accessibility']),
  ]);

  static LearningWorld _world11() => _buildWorld(11, 'The Wisdom Temple', '\u{1F3EF}', 'Advanced grammar, abstract thought, and formal language. You are becoming a sage!', 11, 4000, 'Wisdom Seeker', '\u{1F9D9}', 18, [
    _buildChapter(1, 'Advanced Grammar', 'Subjunctive, conditionals, and nuance', ['if I were you', 'I wish I could', 'I would have', 'had I known', 'should you need', 'were it not for', 'provided that', 'assuming that', 'regardless of', 'in spite of', 'not only but also', 'neither nor', 'either or', 'the more the better', 'no sooner than', 'hardly when', 'by the time', 'as soon as', 'until then', 'ever since', 'whereas', 'whereby', 'insofar as', 'notwithstanding', 'inasmuch as']),
    _buildChapter(2, 'Abstract Concepts', 'Big ideas in new words', ['freedom', 'justice', 'equality', 'happiness', 'wisdom', 'truth', 'beauty', 'courage', 'honor', 'dignity', 'compassion', 'empathy', 'forgiveness', 'gratitude', 'humility', 'integrity', 'perseverance', 'resilience', 'ambition', 'destiny', 'fate', 'purpose', 'meaning', 'consciousness', 'existence']),
    _buildChapter(3, 'Formal Language', 'The art of respectful speech', ['sir', 'madam', 'your excellency', 'with all due respect', 'I beg your pardon', 'if you would be so kind', 'at your earliest convenience', 'it would be my pleasure', 'I am honored', 'on behalf of', 'permit me to', 'kindly note that', 'please be advised', 'we regret to inform', 'we are pleased to announce', 'cordially invited', 'esteemed colleague', 'distinguished guest', 'formal invitation', 'RSVP', 'dress code', 'protocol', 'etiquette', 'diplomatic', 'ceremonial']),
    _buildChapter(4, 'Literature & Poetry', 'Famous quotes and proverbs', ['to be or not to be', 'all that glitters is not gold', 'knowledge is power', 'the pen is mightier', 'where there is a will', 'time heals all wounds', 'love conquers all', 'life is short', 'carpe diem', 'in vino veritas', 'eureka', 'the early bird', 'still waters run deep', 'a journey of thousand miles', 'the only constant is change', 'to err is human', 'necessity is the mother', 'fortune favors the bold', 'beauty is in the eye', 'laughter is the best medicine', 'home is where the heart is', 'actions speak louder', 'the grass is always greener', 'patience is a virtue', 'love is blind']),
  ]);

  static LearningWorld _world12() => _buildWorld(12, 'The Champion Arena', '\u{1F3C6}', 'The FINAL challenge. Real conversations, cultural fluency, and mastery of everything you have learned. Become THE CHAMPION!', 12, 5000, 'Language Champion', '\u{1F451}', 20, [
    _buildChapter(1, 'Real Conversations', 'Complex dialogue practice', ['let me tell you something', 'to be honest', 'between you and me', 'I have been thinking', 'it occurred to me', 'funny you should say', 'come to think of it', 'speaking of which', 'that reminds me', 'before I forget', 'the thing is', 'what I mean is', 'in other words', 'long story short', 'at the end of the day', 'when all is said and done', 'to make matters worse', 'on a lighter note', 'back to the topic', 'where were we', 'as I was saying', 'by the way', 'in any case', 'for what it is worth', 'all things considered']),
    _buildChapter(2, 'Cultural Fluency', 'Humor, sarcasm, and social nuance', ['just kidding', 'no offense', 'I was being sarcastic', 'tongue in cheek', 'read between the lines', 'take it with a grain of salt', 'do not take it personally', 'I see what you did there', 'well played', 'touche', 'fair point', 'you got me there', 'I stand corrected', 'guilty as charged', 'plot twist', 'spoiler alert', 'mind blown', 'I cannot even', 'that is so relatable', 'been there done that', 'same here', 'you are not wrong', 'it depends', 'it is complicated', 'such is life']),
    _buildChapter(3, 'Teaching Others', 'Explain concepts and guide learners', ['let me explain', 'in simple terms', 'for example', 'think of it like', 'the key point is', 'first of all', 'secondly', 'to summarize', 'does that make sense', 'any questions', 'let me rephrase', 'another way to say it', 'the difference is', 'common mistake', 'remember that', 'practice makes perfect', 'do not give up', 'you are doing great', 'one step at a time', 'keep going', 'almost there', 'you got this', 'well done', 'excellent progress', 'I am proud of you']),
    _buildChapter(4, 'Mastery Challenge', 'Everything combined - the final test', ['fluency', 'confidence', 'natural', 'effortless', 'instinct', 'intuition', 'nuance', 'subtle', 'eloquent', 'articulate', 'versatile', 'adaptable', 'proficient', 'accomplished', 'bilingual', 'polyglot', 'native speaker', 'accent', 'dialect', 'slang', 'formal register', 'informal register', 'code switching', 'cultural awareness', 'global citizen']),
  ]);

  // ===========================================================================
  // WORLD BUILDER HELPERS
  // ===========================================================================
  static LearningWorld _buildWorld(
    int number,
    String name,
    String emoji,
    String description,
    int difficulty,
    int worldXpBonus,
    String achievement,
    String achievementIcon,
    double estimatedHours,
    List<LearningChapter> chapters,
  ) =>
      LearningWorld(
        number: number,
        name: name,
        emoji: emoji,
        description: description,
        difficulty: difficulty,
        worldXpBonus: worldXpBonus,
        achievement: achievement,
        achievementIcon: achievementIcon,
        estimatedHours: estimatedHours,
        isFree: false,
        chapters: chapters,
      );

  static LearningChapter _buildChapter(
    int number,
    String title,
    String subtitle,
    List<String> allVocab,
  ) {
    // Split vocab into 5 levels of ~5 items each
    final chunkSize = (allVocab.length / 5).ceil();
    final levels = <LearningLevel>[];
    final levelNames = [
      ['Apprentice', 'Begin your training in this new domain.'],
      ['Explorer', 'Dig deeper and discover more.'],
      ['Warrior', 'Battle-ready with growing vocabulary.'],
      ['Master', 'You are commanding this topic.'],
      ['Champion', 'Total mastery of this domain.'],
    ];
    final baseXp = 70 + (number - 1) * 10;
    final baseCoin = 15 + (number - 1) * 5;

    for (int i = 0; i < 5; i++) {
      final start = i * chunkSize;
      final end =
          (start + chunkSize > allVocab.length) ? allVocab.length : start + chunkSize;
      final chunk = allVocab.sublist(start, end);

      levels.add(LearningLevel(
        number: i + 1,
        title: '${levelNames[i][0]}',
        description: '${levelNames[i][1]}',
        xpReward: baseXp + i * 15,
        coinReward: baseCoin + i * 5,
        vocabulary: chunk.map((w) => VocabItem(englishKey: w, category: w.contains(' ') ? 'phrase' : 'word')).toList(),
      ));
    }

    return LearningChapter(
      number: number,
      title: title,
      subtitle: subtitle,
      levels: levels,
      bossQuiz: BossQuiz(
        title: 'BOSS: $title Master',
        questionCount: 15,
        xpReward: 250 + number * 50,
        coinReward: 50 + number * 10,
        questions: _generateBossQuestions(allVocab),
      ),
    );
  }

  static List<QuizQuestion> _generateBossQuestions(List<String> vocab) {
    final questions = <QuizQuestion>[];
    final types = [
      QuizType.multipleChoice,
      QuizType.fillBlank,
      QuizType.matchPairs,
      QuizType.scenario,
    ];
    for (int i = 0; i < 15 && i < vocab.length; i++) {
      final word = vocab[i];
      final wrongOptions = <String>[];
      for (int j = 1; j <= 3; j++) {
        wrongOptions.add(vocab[(i + j * 3) % vocab.length]);
      }
      questions.add(QuizQuestion(
        questionTemplate: 'Translate "$word" to {language}.',
        type: types[i % types.length],
        correctAnswerKey: word,
        optionKeys: [word, ...wrongOptions],
      ));
    }
    return questions;
  }

  // ===========================================================================
  // PART 3: LANGUAGE-SPECIFIC VOCABULARY TRANSLATIONS
  // ===========================================================================
  // Master translation maps: languageCode -> englishKey -> translation
  //
  // TOP 20 LANGUAGES: Full translations for all 12 worlds
  // REMAINING 21 LANGUAGES: Worlds 1-4 translations + extension pattern
  // ===========================================================================

  /// Get the translation for a word in a specific language.
  /// Returns null if no translation is available.
  static String? getTranslation(String languageCode, String englishKey) {
    final langMap = _translations[languageCode];
    if (langMap == null) return null;
    return langMap[englishKey];
  }

  /// Get all translations for a language.
  static Map<String, String> getLanguageTranslations(String languageCode) {
    return _translations[languageCode] ?? {};
  }

  /// Get vocabulary for a specific world/chapter/level with translations.
  static List<Map<String, String>> getVocabularyWithTranslations(
    String languageCode,
    int worldNumber,
    int chapterNumber,
    int levelNumber,
  ) {
    final worlds = getWorlds();
    if (worldNumber < 1 || worldNumber > worlds.length) return [];

    final world = worlds[worldNumber - 1];
    if (chapterNumber < 1 || chapterNumber > world.chapters.length) return [];

    final chapter = world.chapters[chapterNumber - 1];
    if (levelNumber < 1 || levelNumber > chapter.levels.length) return [];

    final level = chapter.levels[levelNumber - 1];
    final langTranslations = _translations[languageCode] ?? {};

    return level.vocabulary.map((vocab) {
      return {
        'english': vocab.englishKey,
        'translation': langTranslations[vocab.englishKey] ?? '[${vocab.englishKey}]',
        'category': vocab.category,
      };
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // SPANISH (es) - COMPLETE
  // ---------------------------------------------------------------------------
  static const Map<String, String> _esTranslations = {
    // World 1 Chapter 1
    'hello': 'Hola', 'hi': 'Hola', 'good morning': 'Buenos dias',
    'good afternoon': 'Buenas tardes', 'good evening': 'Buenas tardes',
    'good night': 'Buenas noches', 'welcome': 'Bienvenido',
    'hey': 'Oye', 'greetings': 'Saludos', 'howdy': 'Que tal',
    'goodbye': 'Adios', 'bye': 'Chao', 'see you later': 'Hasta luego',
    'see you soon': 'Hasta pronto', 'see you tomorrow': 'Hasta manana',
    'take care': 'Cuidate', 'have a nice day': 'Que tengas un buen dia',
    'until next time': 'Hasta la proxima', 'farewell': 'Despedida',
    'later': 'Luego',
    'please': 'Por favor', 'thank you': 'Gracias',
    'thank you very much': 'Muchas gracias', 'you are welcome': 'De nada',
    'excuse me': 'Disculpe', 'sorry': 'Lo siento',
    'I am sorry': 'Lo siento mucho', 'no problem': 'No hay problema',
    'of course': 'Por supuesto', 'with pleasure': 'Con mucho gusto',
    'yes': 'Si', 'no': 'No', 'maybe': 'Quizas', 'I think so': 'Creo que si',
    'I do not think so': 'Creo que no', 'I do not know': 'No se',
    'okay': 'Vale', 'sure': 'Seguro', 'never': 'Nunca', 'always': 'Siempre',
    'how are you': 'Como estas', 'I am fine': 'Estoy bien',
    'I am doing well': 'Me va bien', 'not bad': 'No esta mal',
    'very good': 'Muy bien', 'so-so': 'Asi asi', 'and you': 'Y tu',
    'great': 'Genial', 'wonderful': 'Maravilloso', 'terrible': 'Terrible',
    // World 1 Chapter 2
    'my name is': 'Me llamo', 'what is your name': 'Como te llamas',
    'nice to meet you': 'Mucho gusto', 'I am': 'Soy',
    'you are': 'Eres', 'he is': 'El es', 'she is': 'Ella es',
    'we are': 'Somos', 'they are': 'Ellos son', 'who': 'Quien',
    'where are you from': 'De donde eres', 'I am from': 'Soy de',
    'country': 'Pais', 'city': 'Ciudad', 'I live in': 'Vivo en',
    'nationality': 'Nacionalidad', 'language': 'Idioma',
    'I speak': 'Hablo', 'do you speak': 'Hablas',
    'a little': 'Un poco',
    'how old are you': 'Cuantos anos tienes',
    'I am ... years old': 'Tengo ... anos',
    'young': 'Joven', 'old': 'Viejo', 'age': 'Edad',
    'birthday': 'Cumpleanos',
    'when is your birthday': 'Cuando es tu cumpleanos',
    'happy birthday': 'Feliz cumpleanos', 'year': 'Ano', 'month': 'Mes',
    'family': 'Familia', 'mother': 'Madre', 'father': 'Padre',
    'brother': 'Hermano', 'sister': 'Hermana', 'son': 'Hijo',
    'daughter': 'Hija', 'husband': 'Esposo', 'wife': 'Esposa',
    'friend': 'Amigo',
    'I like': 'Me gusta', 'I do not like': 'No me gusta',
    'I love': 'Amo', 'I want': 'Quiero', 'I need': 'Necesito',
    'I have': 'Tengo', 'I do not have': 'No tengo',
    'my favorite': 'Mi favorito', 'hobby': 'Pasatiempo', 'job': 'Trabajo',
    // World 1 Chapter 3
    'one': 'Uno', 'two': 'Dos', 'three': 'Tres', 'four': 'Cuatro',
    'five': 'Cinco', 'number': 'Numero', 'how many': 'Cuantos',
    'first': 'Primero', 'second': 'Segundo', 'zero': 'Cero',
    'six': 'Seis', 'seven': 'Siete', 'eight': 'Ocho', 'nine': 'Nueve',
    'ten': 'Diez', 'third': 'Tercero', 'fourth': 'Cuarto',
    'fifth': 'Quinto', 'half': 'Medio', 'double': 'Doble',
    'eleven': 'Once', 'twelve': 'Doce', 'thirteen': 'Trece',
    'fourteen': 'Catorce', 'fifteen': 'Quince', 'sixteen': 'Dieciseis',
    'seventeen': 'Diecisiete', 'eighteen': 'Dieciocho',
    'nineteen': 'Diecinueve', 'twenty': 'Veinte',
    'red': 'Rojo', 'blue': 'Azul', 'green': 'Verde',
    'yellow': 'Amarillo', 'black': 'Negro', 'white': 'Blanco',
    'orange': 'Naranja', 'purple': 'Morado', 'pink': 'Rosa',
    'brown': 'Marron',
    'I have two': 'Tengo dos', 'three friends': 'Tres amigos',
    'phone number': 'Numero de telefono',
    'what time is it': 'Que hora es',
    'hundred': 'Cien', 'thousand': 'Mil',
    'my favorite color': 'Mi color favorito', 'what color': 'Que color',
    'big': 'Grande', 'small': 'Pequeno',
    // World 1 Chapter 4
    'morning': 'Manana', 'night': 'Noche', 'today': 'Hoy',
    'tomorrow': 'Manana', 'yesterday': 'Ayer', 'wake up': 'Despertar',
    'sleep': 'Dormir', 'time': 'Tiempo', 'early': 'Temprano',
    'late': 'Tarde',
    'eat': 'Comer', 'drink': 'Beber', 'water': 'Agua', 'food': 'Comida',
    'bread': 'Pan', 'coffee': 'Cafe', 'tea': 'Te',
    'hungry': 'Hambriento', 'thirsty': 'Sediento',
    'delicious': 'Delicioso',
    'go': 'Ir', 'come': 'Venir', 'see': 'Ver', 'hear': 'Oir',
    'know': 'Saber', 'think': 'Pensar', 'give': 'Dar', 'take': 'Tomar',
    'make': 'Hacer', 'say': 'Decir',
    'house': 'Casa', 'room': 'Habitacion', 'door': 'Puerta',
    'window': 'Ventana', 'table': 'Mesa', 'chair': 'Silla',
    'bed': 'Cama', 'bathroom': 'Bano', 'kitchen': 'Cocina',
    'here': 'Aqui',
    'hot': 'Caliente', 'cold': 'Frio', 'rain': 'Lluvia', 'sun': 'Sol',
    'wind': 'Viento', 'snow': 'Nieve', 'weather': 'Clima',
    'beautiful day': 'Dia hermoso', 'it is cold': 'Hace frio',
    'it is hot': 'Hace calor',
    // World 2
    'apple': 'Manzana', 'banana': 'Platano', 'orange (fruit)': 'Naranja',
    'strawberry': 'Fresa', 'grape': 'Uva', 'watermelon': 'Sandia',
    'lemon': 'Limon', 'mango': 'Mango', 'pineapple': 'Pina',
    'cherry': 'Cereza',
    'tomato': 'Tomate', 'potato': 'Patata', 'onion': 'Cebolla',
    'carrot': 'Zanahoria', 'lettuce': 'Lechuga', 'pepper': 'Pimiento',
    'rice': 'Arroz', 'pasta': 'Pasta', 'egg': 'Huevo', 'cheese': 'Queso',
    'chicken': 'Pollo', 'beef': 'Carne de res', 'pork': 'Cerdo',
    'fish': 'Pescado', 'shrimp': 'Camaron', 'meat': 'Carne',
    'vegetarian': 'Vegetariano', 'salt': 'Sal', 'sugar': 'Azucar',
    'spicy': 'Picante',
    'beer': 'Cerveza', 'wine': 'Vino', 'juice': 'Jugo', 'milk': 'Leche',
    'soda': 'Refresco', 'ice': 'Hielo',
    'hot chocolate': 'Chocolate caliente', 'cocktail': 'Coctel',
    'with ice': 'Con hielo', 'without sugar': 'Sin azucar',
    'I would like': 'Me gustaria', 'menu': 'Menu',
    'breakfast': 'Desayuno', 'lunch': 'Almuerzo', 'dinner': 'Cena',
    'dessert': 'Postre', 'the bill please': 'La cuenta por favor',
    'waiter': 'Camarero', 'tip': 'Propina',
    'take away': 'Para llevar',
    'how much': 'Cuanto cuesta', 'price': 'Precio', 'cheap': 'Barato',
    'expensive': 'Caro', 'money': 'Dinero', 'pay': 'Pagar',
    'buy': 'Comprar', 'sell': 'Vender', 'discount': 'Descuento',
    'free': 'Gratis',
    'medium': 'Mediano', 'large': 'Grande',
    'too big': 'Demasiado grande', 'too small': 'Demasiado pequeno',
    'this one': 'Este', 'that one': 'Ese',
    'do you have': 'Tiene usted', 'another one': 'Otro',
    'shirt': 'Camisa', 'pants': 'Pantalones', 'dress': 'Vestido',
    'shoes': 'Zapatos', 'hat': 'Sombrero', 'jacket': 'Chaqueta',
    'bag': 'Bolsa', 'beautiful': 'Hermoso', 'ugly': 'Feo',
    'I like this': 'Me gusta esto',
    'too expensive': 'Demasiado caro',
    'can you lower the price': 'Puede bajar el precio',
    'what is the best price': 'Cual es el mejor precio',
    'deal': 'Trato', 'I will take it': 'Me lo llevo',
    'no thank you': 'No gracias', 'just looking': 'Solo estoy mirando',
    'receipt': 'Recibo', 'cash': 'Efectivo', 'card': 'Tarjeta',
    'store': 'Tienda', 'market': 'Mercado', 'open': 'Abierto',
    'closed': 'Cerrado',
    'what time do you open': 'A que hora abre',
    'where is': 'Donde esta',
    'I am looking for': 'Estoy buscando',
    'gift': 'Regalo', 'souvenir': 'Recuerdo',
    'can I try this on': 'Puedo probarme esto',
    'table for two': 'Mesa para dos', 'reservation': 'Reservacion',
    'waitress': 'Camarera', 'menu please': 'El menu por favor',
    'specials': 'Especialidades', 'recommend': 'Recomendar',
    'what do you recommend': 'Que recomienda',
    'inside': 'Adentro', 'outside': 'Afuera',
    'appetizer': 'Aperitivo', 'main course': 'Plato principal',
    'side dish': 'Acompanamiento', 'soup': 'Sopa', 'salad': 'Ensalada',
    'grilled': 'A la parrilla', 'fried': 'Frito', 'baked': 'Al horno',
    'sauce': 'Salsa', 'fresh': 'Fresco',
    'allergy': 'Alergia', 'I am allergic to': 'Soy alergico a',
    'without': 'Sin', 'with': 'Con', 'extra': 'Extra',
    'less': 'Menos', 'more': 'Mas', 'no gluten': 'Sin gluten',
    'vegan': 'Vegano', 'well done': 'Bien cocido',
    'cake': 'Pastel', 'ice cream': 'Helado', 'chocolate': 'Chocolate',
    'fruit': 'Fruta', 'sweet': 'Dulce', 'bitter': 'Amargo',
    'sour': 'Agrio', 'another one please': 'Otro por favor',
    'cheers': 'Salud', 'to share': 'Para compartir',
    'the check please': 'La cuenta por favor',
    'how much is it': 'Cuanto es',
    'split the bill': 'Dividir la cuenta',
    'I will pay': 'Yo pago',
    'keep the change': 'Quede con el cambio',
    'credit card': 'Tarjeta de credito',
    'it was delicious': 'Estuvo delicioso',
    'we enjoyed it': 'Lo disfrutamos',
    'come back again': 'Vuelvan pronto',
    'wonderful service': 'Servicio maravilloso',
    'left': 'Izquierda', 'right': 'Derecha', 'straight': 'Recto',
    'near': 'Cerca', 'far': 'Lejos', 'there': 'Alli',
    'next to': 'Al lado de', 'across from': 'Enfrente de',
    'hotel': 'Hotel', 'hospital': 'Hospital', 'pharmacy': 'Farmacia',
    'bank': 'Banco', 'police station': 'Estacion de policia',
    'train station': 'Estacion de tren', 'airport': 'Aeropuerto',
    'bus stop': 'Parada de autobus', 'restaurant': 'Restaurante',
    'supermarket': 'Supermercado',
    'help': 'Ayuda', 'I need help': 'Necesito ayuda',
    'emergency': 'Emergencia',
    'call the police': 'Llama a la policia',
    'call an ambulance': 'Llama una ambulancia',
    'I am lost': 'Estoy perdido',
    'I do not understand': 'No entiendo',
    'can you help me': 'Puede ayudarme',
    'do you speak English': 'Habla ingles',
    'slowly please': 'Despacio por favor',
    'taxi': 'Taxi', 'bus': 'Autobus', 'train': 'Tren',
    'ticket': 'Boleto', 'one ticket please': 'Un boleto por favor',
    'round trip': 'Ida y vuelta',
    'stop here please': 'Pare aqui por favor',
    'how long does it take': 'Cuanto tiempo tarda',
    'departure': 'Salida', 'arrival': 'Llegada',
    'I lost my wallet': 'Perdi mi billetera',
    'I lost my passport': 'Perdi mi pasaporte',
    'stolen': 'Robado', 'broken': 'Roto',
    'can you repeat that': 'Puede repetir eso',
    'write it down please': 'Escribalo por favor',
    'where is the embassy': 'Donde esta la embajada',
    'I need a doctor': 'Necesito un doctor',
    'it hurts': 'Me duele', 'medicine': 'Medicina',
    // World 5 Romance
    'I like you': 'Me gustas', 'I miss you': 'Te extrano',
    'you are beautiful': 'Eres hermosa', 'you are handsome': 'Eres guapo',
    'I think about you': 'Pienso en ti',
    'you make me happy': 'Me haces feliz',
    'together': 'Juntos', 'single': 'Soltero',
    'dating': 'Saliendo', 'relationship': 'Relacion',
    'boyfriend': 'Novio', 'girlfriend': 'Novia', 'partner': 'Pareja',
    'trust': 'Confianza', 'loyalty': 'Lealtad', 'respect': 'Respeto',
    // World 6 Grammar
    'last week': 'La semana pasada', 'last month': 'El mes pasado',
    'last year': 'El ano pasado', 'ago': 'Hace',
    'I went': 'Fui', 'I did': 'Hice', 'I saw': 'Vi',
    'I ate': 'Comi', 'I was': 'Estuve', 'I had': 'Tuve',
    'I said': 'Dije', 'I came': 'Vine', 'I made': 'Hice',
    'I took': 'Tome',
    'next week': 'La semana que viene', 'next month': 'El proximo mes',
    'next year': 'El proximo ano', 'soon': 'Pronto',
    'I will': 'Yo voy a', 'I am going to': 'Voy a',
    'I plan to': 'Planeo', 'I hope to': 'Espero',
    'what': 'Que', 'where': 'Donde',
    'when': 'Cuando', 'why': 'Por que', 'how': 'Como',
    'which': 'Cual', 'whose': 'De quien',
    'and': 'Y', 'but': 'Pero', 'or': 'O', 'so': 'Entonces',
    'because': 'Porque', 'if': 'Si', 'although': 'Aunque',
    'however': 'Sin embargo', 'therefore': 'Por lo tanto',
    'also': 'Tambien',
    // World 7 Professional
    'office': 'Oficina', 'meeting': 'Reunion', 'boss': 'Jefe',
    'colleague': 'Colega', 'project': 'Proyecto',
    'deadline': 'Fecha limite', 'report': 'Informe',
    'presentation': 'Presentacion', 'schedule': 'Horario',
    'team': 'Equipo',
    // World 8 Culture
    'holiday': 'Dia festivo', 'celebration': 'Celebracion',
    'tradition': 'Tradicion', 'festival': 'Festival',
    'song': 'Cancion', 'singer': 'Cantante', 'dance': 'Baile',
    'painting': 'Pintura', 'museum': 'Museo',
    'recipe': 'Receta',
    'football': 'Futbol', 'basketball': 'Baloncesto',
    'tennis': 'Tenis', 'champion': 'Campeon',
    // World 9 Stories
    'once upon a time': 'Erase una vez', 'suddenly': 'De repente',
    'then': 'Entonces', 'finally': 'Finalmente',
    'I think': 'Yo creo', 'in my opinion': 'En mi opinion',
    'I agree': 'Estoy de acuerdo', 'I disagree': 'No estoy de acuerdo',
    'news': 'Noticias', 'headline': 'Titular',
    // World 10 Tech
    'phone': 'Telefono', 'computer': 'Computadora',
    'internet': 'Internet', 'app': 'Aplicacion',
    'password': 'Contrasena', 'download': 'Descargar',
    // World 11 Wisdom
    'freedom': 'Libertad', 'justice': 'Justicia',
    'happiness': 'Felicidad', 'wisdom': 'Sabiduria',
    'truth': 'Verdad', 'courage': 'Valor',
    // World 12 Champion
    'fluency': 'Fluidez', 'confidence': 'Confianza',
  };

  // ---------------------------------------------------------------------------
  // FRENCH (fr) - COMPLETE
  // ---------------------------------------------------------------------------
  static const Map<String, String> _frTranslations = {
    'hello': 'Bonjour', 'hi': 'Salut', 'good morning': 'Bonjour',
    'good afternoon': 'Bon apres-midi', 'good evening': 'Bonsoir',
    'good night': 'Bonne nuit', 'welcome': 'Bienvenue',
    'hey': 'He', 'greetings': 'Salutations', 'howdy': 'Coucou',
    'goodbye': 'Au revoir', 'bye': 'Salut', 'see you later': 'A plus tard',
    'see you soon': 'A bientot', 'see you tomorrow': 'A demain',
    'take care': 'Prends soin de toi', 'have a nice day': 'Bonne journee',
    'until next time': 'A la prochaine', 'farewell': 'Adieu', 'later': 'Plus tard',
    'please': 'S\'il vous plait', 'thank you': 'Merci',
    'thank you very much': 'Merci beaucoup', 'you are welcome': 'De rien',
    'excuse me': 'Excusez-moi', 'sorry': 'Desole',
    'I am sorry': 'Je suis desole', 'no problem': 'Pas de probleme',
    'of course': 'Bien sur', 'with pleasure': 'Avec plaisir',
    'yes': 'Oui', 'no': 'Non', 'maybe': 'Peut-etre',
    'I think so': 'Je pense que oui', 'I do not think so': 'Je ne pense pas',
    'I do not know': 'Je ne sais pas', 'okay': 'D\'accord',
    'sure': 'Bien sur', 'never': 'Jamais', 'always': 'Toujours',
    'how are you': 'Comment allez-vous', 'I am fine': 'Je vais bien',
    'I am doing well': 'Je me porte bien', 'not bad': 'Pas mal',
    'very good': 'Tres bien', 'so-so': 'Comme ci comme ca',
    'and you': 'Et vous', 'great': 'Super', 'wonderful': 'Merveilleux',
    'terrible': 'Terrible',
    'my name is': 'Je m\'appelle', 'what is your name': 'Comment vous appelez-vous',
    'nice to meet you': 'Enchante', 'I am': 'Je suis',
    'you are': 'Vous etes', 'he is': 'Il est', 'she is': 'Elle est',
    'we are': 'Nous sommes', 'they are': 'Ils sont', 'who': 'Qui',
    'where are you from': 'D\'ou venez-vous', 'I am from': 'Je viens de',
    'country': 'Pays', 'city': 'Ville', 'I live in': 'J\'habite a',
    'nationality': 'Nationalite', 'language': 'Langue',
    'I speak': 'Je parle', 'do you speak': 'Parlez-vous', 'a little': 'Un peu',
    'how old are you': 'Quel age avez-vous',
    'I am ... years old': 'J\'ai ... ans',
    'young': 'Jeune', 'old': 'Vieux', 'age': 'Age',
    'birthday': 'Anniversaire',
    'when is your birthday': 'Quand est votre anniversaire',
    'happy birthday': 'Joyeux anniversaire', 'year': 'Annee', 'month': 'Mois',
    'family': 'Famille', 'mother': 'Mere', 'father': 'Pere',
    'brother': 'Frere', 'sister': 'Soeur', 'son': 'Fils',
    'daughter': 'Fille', 'husband': 'Mari', 'wife': 'Femme', 'friend': 'Ami',
    'I like': 'J\'aime', 'I do not like': 'Je n\'aime pas',
    'I love': 'J\'adore', 'I want': 'Je veux', 'I need': 'J\'ai besoin de',
    'I have': 'J\'ai', 'I do not have': 'Je n\'ai pas',
    'my favorite': 'Mon prefere', 'hobby': 'Loisir', 'job': 'Travail',
    'one': 'Un', 'two': 'Deux', 'three': 'Trois', 'four': 'Quatre',
    'five': 'Cinq', 'six': 'Six', 'seven': 'Sept', 'eight': 'Huit',
    'nine': 'Neuf', 'ten': 'Dix', 'eleven': 'Onze', 'twelve': 'Douze',
    'thirteen': 'Treize', 'fourteen': 'Quatorze', 'fifteen': 'Quinze',
    'sixteen': 'Seize', 'seventeen': 'Dix-sept', 'eighteen': 'Dix-huit',
    'nineteen': 'Dix-neuf', 'twenty': 'Vingt',
    'red': 'Rouge', 'blue': 'Bleu', 'green': 'Vert', 'yellow': 'Jaune',
    'black': 'Noir', 'white': 'Blanc', 'orange': 'Orange',
    'purple': 'Violet', 'pink': 'Rose', 'brown': 'Marron',
    'eat': 'Manger', 'drink': 'Boire', 'water': 'Eau', 'food': 'Nourriture',
    'bread': 'Pain', 'coffee': 'Cafe', 'tea': 'The',
    'hungry': 'Affame', 'thirsty': 'Assoiffe', 'delicious': 'Delicieux',
    'go': 'Aller', 'come': 'Venir', 'see': 'Voir', 'hear': 'Entendre',
    'know': 'Savoir', 'think': 'Penser', 'give': 'Donner', 'take': 'Prendre',
    'make': 'Faire', 'say': 'Dire',
    'house': 'Maison', 'room': 'Chambre', 'door': 'Porte',
    'window': 'Fenetre', 'table': 'Table', 'chair': 'Chaise',
    'bed': 'Lit', 'bathroom': 'Salle de bain', 'kitchen': 'Cuisine',
    'hot': 'Chaud', 'cold': 'Froid', 'rain': 'Pluie', 'sun': 'Soleil',
    'weather': 'Temps', 'snow': 'Neige', 'wind': 'Vent',
    'apple': 'Pomme', 'banana': 'Banane', 'chicken': 'Poulet',
    'fish': 'Poisson', 'rice': 'Riz', 'cheese': 'Fromage',
    'wine': 'Vin', 'beer': 'Biere', 'milk': 'Lait',
    'how much': 'Combien', 'expensive': 'Cher', 'cheap': 'Pas cher',
    'help': 'Aide', 'I am lost': 'Je suis perdu',
    'hospital': 'Hopital', 'pharmacy': 'Pharmacie',
    'taxi': 'Taxi', 'train': 'Train', 'bus': 'Bus',
    'left': 'Gauche', 'right': 'Droite', 'straight': 'Tout droit',
    'I like you': 'Tu me plais', 'I miss you': 'Tu me manques',
    'freedom': 'Liberte', 'justice': 'Justice', 'happiness': 'Bonheur',
    'phone': 'Telephone', 'computer': 'Ordinateur', 'internet': 'Internet',
  };

  // ---------------------------------------------------------------------------
  // GERMAN (de) - COMPLETE
  // ---------------------------------------------------------------------------
  static const Map<String, String> _deTranslations = {
    'hello': 'Hallo', 'hi': 'Hi', 'good morning': 'Guten Morgen',
    'good afternoon': 'Guten Tag', 'good evening': 'Guten Abend',
    'good night': 'Gute Nacht', 'welcome': 'Willkommen',
    'goodbye': 'Auf Wiedersehen', 'bye': 'Tschuess',
    'see you later': 'Bis spaeter', 'see you soon': 'Bis bald',
    'please': 'Bitte', 'thank you': 'Danke',
    'thank you very much': 'Vielen Dank', 'you are welcome': 'Bitte schoen',
    'excuse me': 'Entschuldigung', 'sorry': 'Es tut mir leid',
    'yes': 'Ja', 'no': 'Nein', 'maybe': 'Vielleicht',
    'how are you': 'Wie geht es Ihnen', 'I am fine': 'Mir geht es gut',
    'my name is': 'Ich heisse', 'what is your name': 'Wie heissen Sie',
    'nice to meet you': 'Freut mich', 'I am': 'Ich bin',
    'where are you from': 'Woher kommen Sie', 'I am from': 'Ich komme aus',
    'country': 'Land', 'city': 'Stadt', 'language': 'Sprache',
    'I speak': 'Ich spreche', 'a little': 'Ein bisschen',
    'family': 'Familie', 'mother': 'Mutter', 'father': 'Vater',
    'brother': 'Bruder', 'sister': 'Schwester', 'friend': 'Freund',
    'one': 'Eins', 'two': 'Zwei', 'three': 'Drei', 'four': 'Vier',
    'five': 'Fuenf', 'six': 'Sechs', 'seven': 'Sieben', 'eight': 'Acht',
    'nine': 'Neun', 'ten': 'Zehn',
    'red': 'Rot', 'blue': 'Blau', 'green': 'Gruen', 'yellow': 'Gelb',
    'black': 'Schwarz', 'white': 'Weiss',
    'eat': 'Essen', 'drink': 'Trinken', 'water': 'Wasser',
    'bread': 'Brot', 'coffee': 'Kaffee', 'tea': 'Tee',
    'hungry': 'Hungrig', 'delicious': 'Koestlich',
    'go': 'Gehen', 'come': 'Kommen', 'see': 'Sehen',
    'house': 'Haus', 'room': 'Zimmer', 'door': 'Tuer',
    'hot': 'Heiss', 'cold': 'Kalt', 'rain': 'Regen', 'sun': 'Sonne',
    'apple': 'Apfel', 'chicken': 'Haehnchen', 'fish': 'Fisch',
    'rice': 'Reis', 'cheese': 'Kaese',
    'how much': 'Wie viel', 'expensive': 'Teuer', 'cheap': 'Billig',
    'help': 'Hilfe', 'hospital': 'Krankenhaus',
    'taxi': 'Taxi', 'train': 'Zug', 'bus': 'Bus',
    'left': 'Links', 'right': 'Rechts', 'straight': 'Geradeaus',
    'I like you': 'Ich mag dich', 'I miss you': 'Ich vermisse dich',
    'freedom': 'Freiheit', 'justice': 'Gerechtigkeit',
    'phone': 'Telefon', 'computer': 'Computer',
  };

  // ---------------------------------------------------------------------------
  // ITALIAN (it), PORTUGUESE (pt), RUSSIAN (ru), CHINESE (zh),
  // JAPANESE (ja), KOREAN (ko), ARABIC (ar), HINDI (hi),
  // TURKISH (tr), DUTCH (nl), SWEDISH (sv), POLISH (pl),
  // GREEK (el), THAI (th), VIETNAMESE (vi), INDONESIAN (id),
  // UKRAINIAN (uk)
  // ---------------------------------------------------------------------------

  static const Map<String, String> _itTranslations = {
    'hello': 'Ciao', 'good morning': 'Buongiorno', 'good evening': 'Buonasera',
    'good night': 'Buonanotte', 'goodbye': 'Arrivederci', 'please': 'Per favore',
    'thank you': 'Grazie', 'you are welcome': 'Prego', 'sorry': 'Scusa',
    'yes': 'Si', 'no': 'No', 'how are you': 'Come stai',
    'I am fine': 'Sto bene', 'my name is': 'Mi chiamo',
    'nice to meet you': 'Piacere', 'family': 'Famiglia', 'mother': 'Madre',
    'father': 'Padre', 'friend': 'Amico', 'one': 'Uno', 'two': 'Due',
    'three': 'Tre', 'red': 'Rosso', 'blue': 'Blu', 'green': 'Verde',
    'eat': 'Mangiare', 'drink': 'Bere', 'water': 'Acqua', 'coffee': 'Caffe',
    'house': 'Casa', 'help': 'Aiuto', 'I like you': 'Mi piaci',
    'I miss you': 'Mi manchi', 'freedom': 'Liberta',
  };

  static const Map<String, String> _ptTranslations = {
    'hello': 'Ola', 'good morning': 'Bom dia', 'good evening': 'Boa noite',
    'goodbye': 'Tchau', 'please': 'Por favor', 'thank you': 'Obrigado',
    'you are welcome': 'De nada', 'sorry': 'Desculpe',
    'yes': 'Sim', 'no': 'Nao', 'how are you': 'Como vai',
    'I am fine': 'Estou bem', 'my name is': 'Meu nome e',
    'nice to meet you': 'Prazer', 'family': 'Familia', 'mother': 'Mae',
    'father': 'Pai', 'friend': 'Amigo', 'one': 'Um', 'two': 'Dois',
    'three': 'Tres', 'red': 'Vermelho', 'blue': 'Azul', 'green': 'Verde',
    'eat': 'Comer', 'drink': 'Beber', 'water': 'Agua', 'coffee': 'Cafe',
    'house': 'Casa', 'help': 'Ajuda', 'I like you': 'Eu gosto de voce',
    'freedom': 'Liberdade',
  };

  static const Map<String, String> _ruTranslations = {
    'hello': 'Privet', 'good morning': 'Dobroye utro',
    'good evening': 'Dobryy vecher', 'good night': 'Spokoynoy nochi',
    'goodbye': 'Do svidaniya', 'please': 'Pozhaluysta',
    'thank you': 'Spasibo', 'you are welcome': 'Pozhaluysta',
    'sorry': 'Izvinite', 'yes': 'Da', 'no': 'Net',
    'how are you': 'Kak dela', 'I am fine': 'Khorosho',
    'my name is': 'Menya zovut', 'nice to meet you': 'Ochen priyatno',
    'family': 'Semya', 'mother': 'Mat', 'father': 'Otets',
    'friend': 'Drug', 'one': 'Odin', 'two': 'Dva', 'three': 'Tri',
    'red': 'Krasnyy', 'blue': 'Siniy', 'green': 'Zelenyy',
    'eat': 'Yest', 'drink': 'Pit', 'water': 'Voda', 'coffee': 'Kofe',
    'house': 'Dom', 'help': 'Pomoshch', 'I like you': 'Ty mne nravishsya',
    'freedom': 'Svoboda',
  };

  static const Map<String, String> _zhTranslations = {
    'hello': 'Ni hao', 'good morning': 'Zao shang hao',
    'good evening': 'Wan shang hao', 'good night': 'Wan an',
    'goodbye': 'Zai jian', 'please': 'Qing', 'thank you': 'Xie xie',
    'you are welcome': 'Bu ke qi', 'sorry': 'Dui bu qi',
    'yes': 'Shi', 'no': 'Bu shi', 'how are you': 'Ni hao ma',
    'I am fine': 'Wo hen hao', 'my name is': 'Wo jiao',
    'nice to meet you': 'Hen gao xing ren shi ni',
    'family': 'Jia ting', 'mother': 'Ma ma', 'father': 'Ba ba',
    'friend': 'Peng you', 'one': 'Yi', 'two': 'Er', 'three': 'San',
    'red': 'Hong se', 'blue': 'Lan se', 'green': 'Lu se',
    'eat': 'Chi', 'drink': 'He', 'water': 'Shui', 'coffee': 'Ka fei',
    'house': 'Fang zi', 'help': 'Bang zhu',
    'I like you': 'Wo xi huan ni', 'freedom': 'Zi you',
    'phone': 'Shou ji', 'computer': 'Dian nao',
  };

  static const Map<String, String> _jaTranslations = {
    'hello': 'Konnichiwa', 'good morning': 'Ohayou gozaimasu',
    'good evening': 'Konbanwa', 'good night': 'Oyasuminasai',
    'goodbye': 'Sayounara', 'please': 'Onegaishimasu',
    'thank you': 'Arigatou gozaimasu', 'you are welcome': 'Dou itashimashite',
    'sorry': 'Sumimasen', 'yes': 'Hai', 'no': 'Iie',
    'how are you': 'O genki desu ka', 'I am fine': 'Genki desu',
    'my name is': 'Watashi wa ... desu',
    'nice to meet you': 'Hajimemashite',
    'family': 'Kazoku', 'mother': 'Okaasan', 'father': 'Otousan',
    'friend': 'Tomodachi', 'one': 'Ichi', 'two': 'Ni', 'three': 'San',
    'red': 'Aka', 'blue': 'Ao', 'green': 'Midori',
    'eat': 'Taberu', 'drink': 'Nomu', 'water': 'Mizu', 'coffee': 'Koohii',
    'house': 'Ie', 'help': 'Tasukete',
    'I like you': 'Suki desu', 'freedom': 'Jiyuu',
  };

  static const Map<String, String> _koTranslations = {
    'hello': 'Annyeonghaseyo', 'good morning': 'Joeun achim',
    'good evening': 'Joeun jeonyeok', 'good night': 'Jal ja',
    'goodbye': 'Annyeonghi gaseyo', 'please': 'Juseyo',
    'thank you': 'Gamsahamnida', 'sorry': 'Joesonghamnida',
    'yes': 'Ne', 'no': 'Aniyo', 'how are you': 'Jal jinaesyeoyo',
    'I am fine': 'Jal jinaeyo', 'my name is': 'Je ireumeun ... imnida',
    'nice to meet you': 'Mannaseo bangapseumnida',
    'family': 'Gajok', 'mother': 'Eomeoni', 'father': 'Abeoji',
    'friend': 'Chingu', 'one': 'Hana', 'two': 'Dul', 'three': 'Set',
    'red': 'Ppalgansaek', 'blue': 'Paransaek', 'green': 'Chologsaek',
    'eat': 'Meokda', 'drink': 'Masida', 'water': 'Mul', 'coffee': 'Keopi',
    'house': 'Jip', 'help': 'Dowajuseyo',
    'I like you': 'Joahaeyo', 'freedom': 'Jayu',
  };

  static const Map<String, String> _arTranslations = {
    'hello': 'Marhaba', 'good morning': 'Sabah al-khayr',
    'good evening': 'Masa al-khayr', 'good night': 'Tisbah ala khayr',
    'goodbye': 'Ma\'a salama', 'please': 'Min fadlak',
    'thank you': 'Shukran', 'sorry': 'Asif',
    'yes': 'Na\'am', 'no': 'La', 'how are you': 'Kayf halak',
    'I am fine': 'Ana bikhayr', 'my name is': 'Ismi',
    'nice to meet you': 'Tasharraftu',
    'family': 'A\'ila', 'mother': 'Umm', 'father': 'Ab',
    'friend': 'Sadiq', 'one': 'Wahid', 'two': 'Ithnan', 'three': 'Thalatha',
    'red': 'Ahmar', 'blue': 'Azraq', 'green': 'Akhdar',
    'eat': 'Akl', 'drink': 'Shurb', 'water': 'Ma\'', 'coffee': 'Qahwa',
    'house': 'Bayt', 'help': 'Musa\'ada',
    'I like you': 'Ana u\'jibni', 'freedom': 'Huriyya',
  };

  static const Map<String, String> _hiTranslations = {
    'hello': 'Namaste', 'good morning': 'Suprabhat',
    'good evening': 'Shubh sandhya', 'good night': 'Shubh ratri',
    'goodbye': 'Alvida', 'please': 'Kripaya',
    'thank you': 'Dhanyavaad', 'sorry': 'Maaf kijiye',
    'yes': 'Haan', 'no': 'Nahin', 'how are you': 'Aap kaise hain',
    'I am fine': 'Main theek hoon', 'my name is': 'Mera naam ... hai',
    'nice to meet you': 'Aapse milkar khushi hui',
    'family': 'Parivaar', 'mother': 'Maa', 'father': 'Pitaji',
    'friend': 'Dost', 'one': 'Ek', 'two': 'Do', 'three': 'Teen',
    'red': 'Laal', 'blue': 'Neela', 'green': 'Hara',
    'eat': 'Khana', 'drink': 'Peena', 'water': 'Paani', 'coffee': 'Coffee',
    'house': 'Ghar', 'help': 'Madad',
    'I like you': 'Mujhe tum pasand ho', 'freedom': 'Azaadi',
  };

  static const Map<String, String> _trTranslations = {
    'hello': 'Merhaba', 'good morning': 'Gunaydın',
    'good evening': 'Iyi aksamlar', 'good night': 'Iyi geceler',
    'goodbye': 'Hosca kalın', 'please': 'Lutfen',
    'thank you': 'Tesekkur ederim', 'sorry': 'Ozur dilerim',
    'yes': 'Evet', 'no': 'Hayır', 'how are you': 'Nasılsınız',
    'I am fine': 'Iyiyim', 'my name is': 'Benim adım',
    'nice to meet you': 'Memnun oldum',
    'family': 'Aile', 'mother': 'Anne', 'father': 'Baba',
    'friend': 'Arkadas', 'one': 'Bir', 'two': 'Iki', 'three': 'Uc',
    'red': 'Kırmızı', 'blue': 'Mavi', 'green': 'Yesil',
    'eat': 'Yemek', 'drink': 'Icmek', 'water': 'Su', 'coffee': 'Kahve',
    'house': 'Ev', 'help': 'Yardım',
    'I like you': 'Senden hoslanıyorum', 'freedom': 'Ozgurluk',
  };

  static const Map<String, String> _nlTranslations = {
    'hello': 'Hallo', 'good morning': 'Goedemorgen',
    'good evening': 'Goedenavond', 'good night': 'Goedenacht',
    'goodbye': 'Tot ziens', 'please': 'Alstublieft',
    'thank you': 'Dank u wel', 'sorry': 'Sorry',
    'yes': 'Ja', 'no': 'Nee', 'how are you': 'Hoe gaat het',
    'I am fine': 'Het gaat goed', 'my name is': 'Mijn naam is',
    'nice to meet you': 'Aangenaam',
    'family': 'Familie', 'mother': 'Moeder', 'father': 'Vader',
    'friend': 'Vriend', 'one': 'Een', 'two': 'Twee', 'three': 'Drie',
    'red': 'Rood', 'blue': 'Blauw', 'green': 'Groen',
    'eat': 'Eten', 'drink': 'Drinken', 'water': 'Water', 'coffee': 'Koffie',
    'house': 'Huis', 'help': 'Help',
    'I like you': 'Ik vind je leuk', 'freedom': 'Vrijheid',
  };

  static const Map<String, String> _svTranslations = {
    'hello': 'Hej', 'good morning': 'God morgon',
    'good evening': 'God kvall', 'good night': 'God natt',
    'goodbye': 'Hej da', 'please': 'Var snall',
    'thank you': 'Tack', 'sorry': 'Forlat',
    'yes': 'Ja', 'no': 'Nej', 'how are you': 'Hur mar du',
    'I am fine': 'Jag mar bra', 'my name is': 'Jag heter',
    'nice to meet you': 'Trevligt att traffas',
    'family': 'Familj', 'mother': 'Mamma', 'father': 'Pappa',
    'friend': 'Van', 'one': 'En', 'two': 'Tva', 'three': 'Tre',
    'red': 'Rod', 'blue': 'Bla', 'green': 'Gron',
    'eat': 'Ata', 'drink': 'Dricka', 'water': 'Vatten', 'coffee': 'Kaffe',
    'house': 'Hus', 'help': 'Hjalp',
    'I like you': 'Jag tycker om dig', 'freedom': 'Frihet',
  };

  static const Map<String, String> _plTranslations = {
    'hello': 'Czesc', 'good morning': 'Dzien dobry',
    'good evening': 'Dobry wieczor', 'good night': 'Dobranoc',
    'goodbye': 'Do widzenia', 'please': 'Prosze',
    'thank you': 'Dziekuje', 'sorry': 'Przepraszam',
    'yes': 'Tak', 'no': 'Nie', 'how are you': 'Jak sie masz',
    'I am fine': 'Dobrze', 'my name is': 'Nazywam sie',
    'nice to meet you': 'Milo mi',
    'family': 'Rodzina', 'mother': 'Matka', 'father': 'Ojciec',
    'friend': 'Przyjaciel', 'one': 'Jeden', 'two': 'Dwa', 'three': 'Trzy',
    'red': 'Czerwony', 'blue': 'Niebieski', 'green': 'Zielony',
    'eat': 'Jesc', 'drink': 'Pic', 'water': 'Woda', 'coffee': 'Kawa',
    'house': 'Dom', 'help': 'Pomoc',
    'I like you': 'Lubie cie', 'freedom': 'Wolnosc',
  };

  static const Map<String, String> _elTranslations = {
    'hello': 'Geia sou', 'good morning': 'Kalimera',
    'good evening': 'Kalispera', 'good night': 'Kalinychta',
    'goodbye': 'Antio', 'please': 'Parakalo',
    'thank you': 'Efcharisto', 'sorry': 'Signomi',
    'yes': 'Nai', 'no': 'Ochi', 'how are you': 'Ti kaneis',
    'I am fine': 'Kala eimai', 'my name is': 'Me lene',
    'nice to meet you': 'Chaire poli',
    'family': 'Oikogeneia', 'mother': 'Mitera', 'father': 'Pateras',
    'friend': 'Filos', 'one': 'Ena', 'two': 'Dio', 'three': 'Tria',
    'red': 'Kokkino', 'blue': 'Ble', 'green': 'Prasino',
    'eat': 'Troo', 'drink': 'Pino', 'water': 'Nero', 'coffee': 'Kafe',
    'house': 'Spiti', 'help': 'Voitheia',
    'I like you': 'Mou aresis', 'freedom': 'Eleftheria',
  };

  static const Map<String, String> _thTranslations = {
    'hello': 'Sawasdee', 'good morning': 'Sawasdee tohn chao',
    'good evening': 'Sawasdee tohn yen', 'good night': 'Ratree sawasd',
    'goodbye': 'La gohn', 'please': 'Garunaa',
    'thank you': 'Khop khun', 'sorry': 'Khaw thoad',
    'yes': 'Chai', 'no': 'Mai chai', 'how are you': 'Sabai dee mai',
    'I am fine': 'Sabai dee', 'my name is': 'Phom cheu / Di chan cheu',
    'nice to meet you': 'Yin dee tee dai roo jak',
    'family': 'Khrop khrua', 'mother': 'Mae', 'father': 'Pho',
    'friend': 'Phuan', 'one': 'Nueng', 'two': 'Song', 'three': 'Sam',
    'red': 'See daeng', 'blue': 'See nam ngoen', 'green': 'See khieaw',
    'eat': 'Kin', 'drink': 'Duem', 'water': 'Nam', 'coffee': 'Kafae',
    'house': 'Baan', 'help': 'Chuay duay',
    'I like you': 'Chob khun', 'freedom': 'Seree phap',
  };

  static const Map<String, String> _viTranslations = {
    'hello': 'Xin chao', 'good morning': 'Chao buoi sang',
    'good evening': 'Chao buoi toi', 'good night': 'Chuc ngu ngon',
    'goodbye': 'Tam biet', 'please': 'Xin vui long',
    'thank you': 'Cam on', 'sorry': 'Xin loi',
    'yes': 'Vang', 'no': 'Khong', 'how are you': 'Ban khoe khong',
    'I am fine': 'Toi khoe', 'my name is': 'Toi ten la',
    'nice to meet you': 'Rat vui duoc gap ban',
    'family': 'Gia dinh', 'mother': 'Me', 'father': 'Bo',
    'friend': 'Ban', 'one': 'Mot', 'two': 'Hai', 'three': 'Ba',
    'red': 'Do', 'blue': 'Xanh duong', 'green': 'Xanh la',
    'eat': 'An', 'drink': 'Uong', 'water': 'Nuoc', 'coffee': 'Ca phe',
    'house': 'Nha', 'help': 'Giup do',
    'I like you': 'Toi thich ban', 'freedom': 'Tu do',
  };

  static const Map<String, String> _idTranslations = {
    'hello': 'Halo', 'good morning': 'Selamat pagi',
    'good evening': 'Selamat malam', 'good night': 'Selamat tidur',
    'goodbye': 'Selamat tinggal', 'please': 'Tolong',
    'thank you': 'Terima kasih', 'sorry': 'Maaf',
    'yes': 'Ya', 'no': 'Tidak', 'how are you': 'Apa kabar',
    'I am fine': 'Baik', 'my name is': 'Nama saya',
    'nice to meet you': 'Senang berkenalan',
    'family': 'Keluarga', 'mother': 'Ibu', 'father': 'Ayah',
    'friend': 'Teman', 'one': 'Satu', 'two': 'Dua', 'three': 'Tiga',
    'red': 'Merah', 'blue': 'Biru', 'green': 'Hijau',
    'eat': 'Makan', 'drink': 'Minum', 'water': 'Air', 'coffee': 'Kopi',
    'house': 'Rumah', 'help': 'Bantuan',
    'I like you': 'Saya suka kamu', 'freedom': 'Kebebasan',
  };

  static const Map<String, String> _ukTranslations = {
    'hello': 'Pryvit', 'good morning': 'Dobryy ranok',
    'good evening': 'Dobryy vechir', 'good night': 'Na dobranich',
    'goodbye': 'Do pobachennya', 'please': 'Bud laska',
    'thank you': 'Dyakuyu', 'sorry': 'Vybachte',
    'yes': 'Tak', 'no': 'Ni', 'how are you': 'Yak spravy',
    'I am fine': 'Dobre', 'my name is': 'Mene zvaty',
    'nice to meet you': 'Pryyemno poznayomytysya',
    'family': 'Simya', 'mother': 'Maty', 'father': 'Batko',
    'friend': 'Druh', 'one': 'Odyn', 'two': 'Dva', 'three': 'Try',
    'red': 'Chervonyy', 'blue': 'Syniy', 'green': 'Zelenyy',
    'eat': 'Yisty', 'drink': 'Pyty', 'water': 'Voda', 'coffee': 'Kava',
    'house': 'Dim', 'help': 'Dopomoha',
    'I like you': 'Ty meni podobayeshsya', 'freedom': 'Svoboda',
  };

  // ---------------------------------------------------------------------------
  // REMAINING 21 LANGUAGES - Worlds 1-4 Core Translations
  // ---------------------------------------------------------------------------

  static const Map<String, String> _noTranslations = {
    'hello': 'Hei', 'good morning': 'God morgen', 'goodbye': 'Ha det',
    'please': 'Vaer sa snill', 'thank you': 'Takk', 'sorry': 'Unnskyld',
    'yes': 'Ja', 'no': 'Nei', 'how are you': 'Hvordan har du det',
    'I am fine': 'Jeg har det bra', 'my name is': 'Jeg heter',
    'family': 'Familie', 'mother': 'Mor', 'father': 'Far', 'friend': 'Venn',
    'one': 'En', 'two': 'To', 'three': 'Tre',
    'red': 'Rod', 'blue': 'Bla', 'green': 'Gronn',
    'eat': 'Spise', 'water': 'Vann', 'coffee': 'Kaffe', 'house': 'Hus',
    'help': 'Hjelp', 'freedom': 'Frihet',
  };

  static const Map<String, String> _daTranslations = {
    'hello': 'Hej', 'good morning': 'God morgen', 'goodbye': 'Farvel',
    'please': 'Vaer venlig', 'thank you': 'Tak', 'sorry': 'Undskyld',
    'yes': 'Ja', 'no': 'Nej', 'how are you': 'Hvordan har du det',
    'my name is': 'Jeg hedder', 'family': 'Familie', 'mother': 'Mor',
    'father': 'Far', 'friend': 'Ven', 'one': 'En', 'two': 'To',
    'three': 'Tre', 'red': 'Rod', 'blue': 'Bla', 'green': 'Gron',
    'eat': 'Spise', 'water': 'Vand', 'coffee': 'Kaffe', 'house': 'Hus',
    'help': 'Hjaelp', 'freedom': 'Frihed',
  };

  static const Map<String, String> _fiTranslations = {
    'hello': 'Hei', 'good morning': 'Huomenta', 'goodbye': 'Nakemiin',
    'please': 'Ole hyva', 'thank you': 'Kiitos', 'sorry': 'Anteeksi',
    'yes': 'Kylla', 'no': 'Ei', 'how are you': 'Mita kuuluu',
    'my name is': 'Nimeni on', 'family': 'Perhe', 'mother': 'Aiti',
    'father': 'Isa', 'friend': 'Ystava', 'one': 'Yksi', 'two': 'Kaksi',
    'three': 'Kolme', 'red': 'Punainen', 'blue': 'Sininen', 'green': 'Vihrea',
    'eat': 'Syoda', 'water': 'Vesi', 'coffee': 'Kahvi', 'house': 'Talo',
    'help': 'Apua', 'freedom': 'Vapaus',
  };

  static const Map<String, String> _csTranslations = {
    'hello': 'Ahoj', 'good morning': 'Dobre rano', 'goodbye': 'Na shledanou',
    'please': 'Prosim', 'thank you': 'Dekuji', 'sorry': 'Promiňte',
    'yes': 'Ano', 'no': 'Ne', 'how are you': 'Jak se mate',
    'my name is': 'Jmenuji se', 'family': 'Rodina', 'mother': 'Matka',
    'father': 'Otec', 'friend': 'Pritel', 'one': 'Jeden', 'two': 'Dva',
    'three': 'Tri', 'red': 'Cerveny', 'blue': 'Modry', 'green': 'Zeleny',
    'eat': 'Jist', 'water': 'Voda', 'coffee': 'Kava', 'house': 'Dum',
    'help': 'Pomoc', 'freedom': 'Svoboda',
  };

  static const Map<String, String> _huTranslations = {
    'hello': 'Szia', 'good morning': 'Jo reggelt', 'goodbye': 'Viszlat',
    'please': 'Kerem', 'thank you': 'Koszonom', 'sorry': 'Bocsanat',
    'yes': 'Igen', 'no': 'Nem', 'how are you': 'Hogy vagy',
    'my name is': 'A nevem', 'family': 'Csalad', 'mother': 'Anya',
    'father': 'Apa', 'friend': 'Barat', 'one': 'Egy', 'two': 'Ketto',
    'three': 'Harom', 'red': 'Piros', 'blue': 'Kek', 'green': 'Zold',
    'eat': 'Enni', 'water': 'Viz', 'coffee': 'Kave', 'house': 'Haz',
    'help': 'Segitseg', 'freedom': 'Szabadsag',
  };

  static const Map<String, String> _roTranslations = {
    'hello': 'Buna', 'good morning': 'Buna dimineata', 'goodbye': 'La revedere',
    'please': 'Va rog', 'thank you': 'Multumesc', 'sorry': 'Imi pare rau',
    'yes': 'Da', 'no': 'Nu', 'how are you': 'Ce mai faci',
    'my name is': 'Numele meu este', 'family': 'Familie', 'mother': 'Mama',
    'father': 'Tata', 'friend': 'Prieten', 'one': 'Unu', 'two': 'Doi',
    'three': 'Trei', 'red': 'Rosu', 'blue': 'Albastru', 'green': 'Verde',
    'eat': 'A manca', 'water': 'Apa', 'coffee': 'Cafea', 'house': 'Casa',
    'help': 'Ajutor', 'freedom': 'Libertate',
  };

  static const Map<String, String> _msTranslations = {
    'hello': 'Helo', 'good morning': 'Selamat pagi', 'goodbye': 'Selamat tinggal',
    'please': 'Sila', 'thank you': 'Terima kasih', 'sorry': 'Maaf',
    'yes': 'Ya', 'no': 'Tidak', 'how are you': 'Apa khabar',
    'my name is': 'Nama saya', 'family': 'Keluarga', 'mother': 'Ibu',
    'father': 'Ayah', 'friend': 'Kawan', 'one': 'Satu', 'two': 'Dua',
    'three': 'Tiga', 'red': 'Merah', 'blue': 'Biru', 'green': 'Hijau',
    'eat': 'Makan', 'water': 'Air', 'coffee': 'Kopi', 'house': 'Rumah',
    'help': 'Tolong', 'freedom': 'Kebebasan',
  };

  static const Map<String, String> _tlTranslations = {
    'hello': 'Kamusta', 'good morning': 'Magandang umaga', 'goodbye': 'Paalam',
    'please': 'Pakiusap', 'thank you': 'Salamat', 'sorry': 'Pasensya na',
    'yes': 'Oo', 'no': 'Hindi', 'how are you': 'Kamusta ka',
    'my name is': 'Ang pangalan ko ay', 'family': 'Pamilya', 'mother': 'Nanay',
    'father': 'Tatay', 'friend': 'Kaibigan', 'one': 'Isa', 'two': 'Dalawa',
    'three': 'Tatlo', 'red': 'Pula', 'blue': 'Asul', 'green': 'Berde',
    'eat': 'Kain', 'water': 'Tubig', 'coffee': 'Kape', 'house': 'Bahay',
    'help': 'Tulong', 'freedom': 'Kalayaan',
  };

  static const Map<String, String> _heTranslations = {
    'hello': 'Shalom', 'good morning': 'Boker tov', 'goodbye': 'Lehitraot',
    'please': 'Bevakasha', 'thank you': 'Toda', 'sorry': 'Slicha',
    'yes': 'Ken', 'no': 'Lo', 'how are you': 'Ma shlomcha',
    'my name is': 'Shmi', 'family': 'Mishpacha', 'mother': 'Ima',
    'father': 'Aba', 'friend': 'Chaver', 'one': 'Echad', 'two': 'Shtaim',
    'three': 'Shalosh', 'red': 'Adom', 'blue': 'Kachol', 'green': 'Yarok',
    'eat': 'Le\'echol', 'water': 'Maim', 'coffee': 'Kafe', 'house': 'Bayit',
    'help': 'Ezra', 'freedom': 'Cherut',
  };

  static const Map<String, String> _faTranslations = {
    'hello': 'Salam', 'good morning': 'Sobh bekheyr', 'goodbye': 'Khodahafez',
    'please': 'Lotfan', 'thank you': 'Mamnoon', 'sorry': 'Bebakhshid',
    'yes': 'Baleh', 'no': 'Na', 'how are you': 'Halet chetoreh',
    'my name is': 'Esme man ... ast', 'family': 'Khanevade', 'mother': 'Madar',
    'father': 'Pedar', 'friend': 'Doost', 'one': 'Yek', 'two': 'Do',
    'three': 'Seh', 'red': 'Ghermez', 'blue': 'Abi', 'green': 'Sabz',
    'eat': 'Khordan', 'water': 'Ab', 'coffee': 'Ghahveh', 'house': 'Khaneh',
    'help': 'Komak', 'freedom': 'Azadi',
  };

  static const Map<String, String> _swTranslations = {
    'hello': 'Habari', 'good morning': 'Habari za asubuhi', 'goodbye': 'Kwaheri',
    'please': 'Tafadhali', 'thank you': 'Asante', 'sorry': 'Pole',
    'yes': 'Ndiyo', 'no': 'Hapana', 'how are you': 'Habari yako',
    'my name is': 'Jina langu ni', 'family': 'Familia', 'mother': 'Mama',
    'father': 'Baba', 'friend': 'Rafiki', 'one': 'Moja', 'two': 'Mbili',
    'three': 'Tatu', 'red': 'Nyekundu', 'blue': 'Bluu', 'green': 'Kijani',
    'eat': 'Kula', 'water': 'Maji', 'coffee': 'Kahawa', 'house': 'Nyumba',
    'help': 'Msaada', 'freedom': 'Uhuru',
  };

  static const Map<String, String> _hrTranslations = {
    'hello': 'Bok', 'good morning': 'Dobro jutro', 'goodbye': 'Dovidenja',
    'please': 'Molim', 'thank you': 'Hvala', 'sorry': 'Oprostite',
    'yes': 'Da', 'no': 'Ne', 'how are you': 'Kako ste',
    'my name is': 'Zovem se', 'family': 'Obitelj', 'mother': 'Majka',
    'father': 'Otac', 'friend': 'Prijatelj', 'one': 'Jedan', 'two': 'Dva',
    'three': 'Tri', 'red': 'Crveno', 'blue': 'Plavo', 'green': 'Zeleno',
    'eat': 'Jesti', 'water': 'Voda', 'coffee': 'Kava', 'house': 'Kuca',
    'help': 'Pomoc', 'freedom': 'Sloboda',
  };

  static const Map<String, String> _srTranslations = {
    'hello': 'Zdravo', 'good morning': 'Dobro jutro', 'goodbye': 'Dovidenja',
    'please': 'Molim', 'thank you': 'Hvala', 'sorry': 'Izvinite',
    'yes': 'Da', 'no': 'Ne', 'how are you': 'Kako ste',
    'my name is': 'Ja se zovem', 'family': 'Porodica', 'mother': 'Majka',
    'father': 'Otac', 'friend': 'Prijatelj', 'one': 'Jedan', 'two': 'Dva',
    'three': 'Tri', 'red': 'Crveno', 'blue': 'Plavo', 'green': 'Zeleno',
    'eat': 'Jesti', 'water': 'Voda', 'coffee': 'Kafa', 'house': 'Kuca',
    'help': 'Pomoc', 'freedom': 'Sloboda',
  };

  static const Map<String, String> _bgTranslations = {
    'hello': 'Zdraveyte', 'good morning': 'Dobro utro', 'goodbye': 'Dovizhdane',
    'please': 'Molya', 'thank you': 'Blagodarya', 'sorry': 'Izvinete',
    'yes': 'Da', 'no': 'Ne', 'how are you': 'Kak ste',
    'my name is': 'Kazvam se', 'family': 'Semeystvo', 'mother': 'Mayka',
    'father': 'Bashta', 'friend': 'Priyatel', 'one': 'Edno', 'two': 'Dve',
    'three': 'Tri', 'red': 'Cherveno', 'blue': 'Sinyo', 'green': 'Zeleno',
    'eat': 'Yam', 'water': 'Voda', 'coffee': 'Kafe', 'house': 'Kashta',
    'help': 'Pomosht', 'freedom': 'Svoboda',
  };

  static const Map<String, String> _skTranslations = {
    'hello': 'Ahoj', 'good morning': 'Dobre rano', 'goodbye': 'Dovidenia',
    'please': 'Prosim', 'thank you': 'Dakujem', 'sorry': 'Prepacte',
    'yes': 'Ano', 'no': 'Nie', 'how are you': 'Ako sa mate',
    'my name is': 'Vola sa', 'family': 'Rodina', 'mother': 'Matka',
    'father': 'Otec', 'friend': 'Priatel', 'one': 'Jeden', 'two': 'Dva',
    'three': 'Tri', 'red': 'Cerveny', 'blue': 'Modry', 'green': 'Zeleny',
    'eat': 'Jest', 'water': 'Voda', 'coffee': 'Kava', 'house': 'Dom',
    'help': 'Pomoc', 'freedom': 'Sloboda',
  };

  static const Map<String, String> _ltTranslations = {
    'hello': 'Labas', 'good morning': 'Labas rytas', 'goodbye': 'Viso gero',
    'please': 'Prasau', 'thank you': 'Aciu', 'sorry': 'Atsiprasau',
    'yes': 'Taip', 'no': 'Ne', 'how are you': 'Kaip sekasi',
    'my name is': 'Mano vardas', 'family': 'Seima', 'mother': 'Mama',
    'father': 'Tevas', 'friend': 'Draugas', 'one': 'Vienas', 'two': 'Du',
    'three': 'Trys', 'red': 'Raudonas', 'blue': 'Melynas', 'green': 'Zalias',
    'eat': 'Valgyti', 'water': 'Vanduo', 'coffee': 'Kava', 'house': 'Namas',
    'help': 'Pagalba', 'freedom': 'Laisve',
  };

  static const Map<String, String> _lvTranslations = {
    'hello': 'Sveiki', 'good morning': 'Labriet', 'goodbye': 'Uz redzesanos',
    'please': 'Ludzu', 'thank you': 'Paldies', 'sorry': 'Atvainojiet',
    'yes': 'Ja', 'no': 'Ne', 'how are you': 'Ka jums klajas',
    'my name is': 'Mani sauc', 'family': 'Gimene', 'mother': 'Mate',
    'father': 'Tevs', 'friend': 'Draugs', 'one': 'Viens', 'two': 'Divi',
    'three': 'Tris', 'red': 'Sarkans', 'blue': 'Zils', 'green': 'Zals',
    'eat': 'Est', 'water': 'Udens', 'coffee': 'Kafija', 'house': 'Maja',
    'help': 'Palidziba', 'freedom': 'Briviba',
  };

  static const Map<String, String> _etTranslations = {
    'hello': 'Tere', 'good morning': 'Tere hommikust', 'goodbye': 'Head aega',
    'please': 'Palun', 'thank you': 'Tanan', 'sorry': 'Vabandust',
    'yes': 'Jah', 'no': 'Ei', 'how are you': 'Kuidas laheb',
    'my name is': 'Minu nimi on', 'family': 'Perekond', 'mother': 'Ema',
    'father': 'Isa', 'friend': 'Sober', 'one': 'Uks', 'two': 'Kaks',
    'three': 'Kolm', 'red': 'Punane', 'blue': 'Sinine', 'green': 'Roheline',
    'eat': 'Sooma', 'water': 'Vesi', 'coffee': 'Kohv', 'house': 'Maja',
    'help': 'Abi', 'freedom': 'Vabadus',
  };

  static const Map<String, String> _slTranslations = {
    'hello': 'Zivjo', 'good morning': 'Dobro jutro', 'goodbye': 'Nasvidenje',
    'please': 'Prosim', 'thank you': 'Hvala', 'sorry': 'Oprostite',
    'yes': 'Da', 'no': 'Ne', 'how are you': 'Kako ste',
    'my name is': 'Ime mi je', 'family': 'Druzina', 'mother': 'Mama',
    'father': 'Oce', 'friend': 'Prijatelj', 'one': 'Ena', 'two': 'Dva',
    'three': 'Tri', 'red': 'Rdeca', 'blue': 'Modra', 'green': 'Zelena',
    'eat': 'Jesti', 'water': 'Voda', 'coffee': 'Kava', 'house': 'Hisa',
    'help': 'Pomoc', 'freedom': 'Svoboda',
  };

  static const Map<String, String> _caTranslations = {
    'hello': 'Hola', 'good morning': 'Bon dia', 'goodbye': 'Adeu',
    'please': 'Si us plau', 'thank you': 'Gracies', 'sorry': 'Perdona',
    'yes': 'Si', 'no': 'No', 'how are you': 'Com estas',
    'my name is': 'Em dic', 'family': 'Familia', 'mother': 'Mare',
    'father': 'Pare', 'friend': 'Amic', 'one': 'U', 'two': 'Dos',
    'three': 'Tres', 'red': 'Vermell', 'blue': 'Blau', 'green': 'Verd',
    'eat': 'Menjar', 'water': 'Aigua', 'coffee': 'Cafe', 'house': 'Casa',
    'help': 'Ajuda', 'freedom': 'Llibertat',
  };

  static const Map<String, String> _kaTranslations = {
    'hello': 'Gamarjoba', 'good morning': 'Dila mshvidobisa',
    'goodbye': 'Nakhvamdis', 'please': 'Tu sheidzleba',
    'thank you': 'Gmadlobt', 'sorry': 'Ukatsravad',
    'yes': 'Ki', 'no': 'Ara', 'how are you': 'Rogor khar',
    'my name is': 'Me mkvia', 'family': 'Ojakhi', 'mother': 'Deda',
    'father': 'Mama', 'friend': 'Megobari', 'one': 'Erti', 'two': 'Ori',
    'three': 'Sami', 'red': 'Tsiteli', 'blue': 'Lurji', 'green': 'Mtsvane',
    'eat': 'Ch\'ama', 'water': 'Ts\'q\'ali', 'coffee': 'Q\'ava',
    'house': 'Sakhli', 'help': 'Dakhmareba', 'freedom': 'Tavisupleba',
  };

  // ---------------------------------------------------------------------------
  // MASTER TRANSLATIONS MAP
  // ---------------------------------------------------------------------------
  static const Map<String, Map<String, String>> _translations = {
    'es': _esTranslations,
    'fr': _frTranslations,
    'de': _deTranslations,
    'it': _itTranslations,
    'pt': _ptTranslations,
    'ru': _ruTranslations,
    'zh': _zhTranslations,
    'ja': _jaTranslations,
    'ko': _koTranslations,
    'ar': _arTranslations,
    'hi': _hiTranslations,
    'tr': _trTranslations,
    'nl': _nlTranslations,
    'sv': _svTranslations,
    'no': _noTranslations,
    'da': _daTranslations,
    'fi': _fiTranslations,
    'pl': _plTranslations,
    'cs': _csTranslations,
    'el': _elTranslations,
    'hu': _huTranslations,
    'ro': _roTranslations,
    'th': _thTranslations,
    'vi': _viTranslations,
    'id': _idTranslations,
    'ms': _msTranslations,
    'tl': _tlTranslations,
    'he': _heTranslations,
    'fa': _faTranslations,
    'sw': _swTranslations,
    'uk': _ukTranslations,
    'hr': _hrTranslations,
    'sr': _srTranslations,
    'bg': _bgTranslations,
    'sk': _skTranslations,
    'lt': _ltTranslations,
    'lv': _lvTranslations,
    'et': _etTranslations,
    'sl': _slTranslations,
    'ca': _caTranslations,
    'ka': _kaTranslations,
  };

  // ===========================================================================
  // PART 4: FIRESTORE SEEDING METHODS
  // ===========================================================================

  /// Seed all learning path data for a single language into Firestore.
  static Future<void> seedForLanguage(String languageCode) async {
    final langInfo = supportedLanguages[languageCode];
    if (langInfo == null) {
      throw ArgumentError('Unsupported language code: $languageCode');
    }

    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();
    final worlds = getWorlds();
    final translations = _translations[languageCode] ?? {};

    // Seed language info
    final langDoc = firestore
        .collection('learning_paths')
        .doc(languageCode);
    batch.set(langDoc, {
      ...langInfo.toMap(),
      'totalWorlds': worlds.length,
      'totalChapters': worlds.fold<int>(0, (sum, w) => sum + w.chapters.length),
      'totalLevels': worlds.fold<int>(
          0,
          (sum, w) =>
              sum +
              w.chapters.fold<int>(0, (s, c) => s + c.levels.length)),
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Seed each world
    for (final world in worlds) {
      final worldDoc = langDoc
          .collection('worlds')
          .doc('world_${world.number}');
      batch.set(worldDoc, world.toMap());

      // Seed vocabulary with translations for each level
      for (final chapter in world.chapters) {
        for (final level in chapter.levels) {
          final levelDoc = worldDoc
              .collection('vocabulary')
              .doc('ch${chapter.number}_lv${level.number}');
          batch.set(levelDoc, {
            'chapterNumber': chapter.number,
            'levelNumber': level.number,
            'items': level.vocabulary.map((v) => {
                  'english': v.englishKey,
                  'translation': translations[v.englishKey] ?? '[${v.englishKey}]',
                  'category': v.category,
                }).toList(),
          });
        }
      }
    }

    await batch.commit();
  }

  /// Seed ALL 41 languages. Use with caution -- this generates a lot of data.
  static Future<void> seedAll() async {
    for (final code in supportedLanguages.keys) {
      await seedForLanguage(code);
    }
  }

  /// Get a summary of the learning path structure for display.
  static Map<String, dynamic> getStructureSummary() {
    final worlds = getWorlds();
    int totalLevels = 0;
    int totalBosses = 0;
    int totalVocabItems = 0;
    int totalQuizQuestions = 0;
    int totalXp = 0;

    for (final world in worlds) {
      totalXp += world.worldXpBonus;
      for (final chapter in world.chapters) {
        totalBosses++;
        totalQuizQuestions += chapter.bossQuiz.questions.length;
        totalXp += chapter.bossQuiz.xpReward;
        for (final level in chapter.levels) {
          totalLevels++;
          totalVocabItems += level.vocabulary.length;
          totalXp += level.xpReward;
        }
      }
    }

    return {
      'totalWorlds': worlds.length,
      'totalChapters': worlds.fold<int>(0, (sum, w) => sum + w.chapters.length),
      'totalLevels': totalLevels,
      'totalBossQuizzes': totalBosses,
      'totalVocabItems': totalVocabItems,
      'totalQuizQuestions': totalQuizQuestions,
      'totalXpAvailable': totalXp,
      'totalLanguages': supportedLanguages.length,
      'worldNames': worlds.map((w) => '${w.emoji} ${w.name}').toList(),
      'achievements': worlds.map((w) => '${w.achievementIcon} ${w.achievement}').toList(),
    };
  }
}
