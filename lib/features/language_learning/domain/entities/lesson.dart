import 'package:equatable/equatable.dart';
import 'language_phrase.dart';

/// Represents a complete lesson unit in the language learning system
/// Designed for 1 year of content with practical daily conversation focus
class Lesson extends Equatable {
  final String id;
  final String languageCode;
  final String languageName;
  final String title;
  final String description;
  final LessonLevel level;
  final LessonCategory category;
  final int lessonNumber; // Sequential number within the level
  final int weekNumber; // Week of the year (1-52)
  final int dayNumber; // Day of the week (1-7)
  final int coinPrice; // Cost to unlock
  final bool isFree; // First lessons are free
  final bool isPremium;
  final int estimatedMinutes;
  final int xpReward;
  final int bonusCoins; // Reward for completion
  final List<LessonSection> sections;
  final List<String> objectives; // What user will learn
  final List<String> prerequisites; // Required lesson IDs
  final String? teacherId; // Creator teacher
  final String? teacherName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isPublished;
  final double averageRating;
  final int completionCount;
  final Map<String, dynamic>? metadata;

  const Lesson({
    required this.id,
    required this.languageCode,
    required this.languageName,
    required this.title,
    required this.description,
    required this.level,
    required this.category,
    required this.lessonNumber,
    required this.weekNumber,
    required this.dayNumber,
    required this.coinPrice,
    this.isFree = false,
    this.isPremium = false,
    required this.estimatedMinutes,
    required this.xpReward,
    this.bonusCoins = 0,
    required this.sections,
    required this.objectives,
    this.prerequisites = const [],
    this.teacherId,
    this.teacherName,
    required this.createdAt,
    this.updatedAt,
    this.isPublished = false,
    this.averageRating = 0.0,
    this.completionCount = 0,
    this.metadata,
  });

  int get totalExercises => sections.fold(
        0,
        (sum, section) => sum + section.exercises.length,
      );

  bool get isLocked => !isFree && coinPrice > 0;

  @override
  List<Object?> get props => [
        id,
        languageCode,
        title,
        level,
        category,
        lessonNumber,
        weekNumber,
        dayNumber,
        coinPrice,
        isFree,
        isPremium,
        isPublished,
      ];
}

/// Lesson difficulty levels
enum LessonLevel {
  absolute_beginner,
  beginner,
  elementary,
  pre_intermediate,
  intermediate,
  upper_intermediate,
  advanced,
  fluent;

  String get displayName {
    switch (this) {
      case LessonLevel.absolute_beginner:
        return 'Absolute Beginner';
      case LessonLevel.beginner:
        return 'Beginner';
      case LessonLevel.elementary:
        return 'Elementary';
      case LessonLevel.pre_intermediate:
        return 'Pre-Intermediate';
      case LessonLevel.intermediate:
        return 'Intermediate';
      case LessonLevel.upper_intermediate:
        return 'Upper-Intermediate';
      case LessonLevel.advanced:
        return 'Advanced';
      case LessonLevel.fluent:
        return 'Fluent';
    }
  }

  String get emoji {
    switch (this) {
      case LessonLevel.absolute_beginner:
        return '🌱';
      case LessonLevel.beginner:
        return '🌿';
      case LessonLevel.elementary:
        return '🌳';
      case LessonLevel.pre_intermediate:
        return '🌴';
      case LessonLevel.intermediate:
        return '🏔️';
      case LessonLevel.upper_intermediate:
        return '⛰️';
      case LessonLevel.advanced:
        return '🏆';
      case LessonLevel.fluent:
        return '👑';
    }
  }

  int get requiredXp {
    switch (this) {
      case LessonLevel.absolute_beginner:
        return 0;
      case LessonLevel.beginner:
        return 500;
      case LessonLevel.elementary:
        return 1500;
      case LessonLevel.pre_intermediate:
        return 3500;
      case LessonLevel.intermediate:
        return 7000;
      case LessonLevel.upper_intermediate:
        return 12000;
      case LessonLevel.advanced:
        return 20000;
      case LessonLevel.fluent:
        return 35000;
    }
  }
}

/// Categories for practical daily conversation
enum LessonCategory {
  dating_basics,
  first_impressions,
  compliments_flirting,
  asking_out,
  restaurant_dates,
  cafe_conversations,
  movies_entertainment,
  travel_adventures,
  cultural_exchange,
  video_calls,
  expressing_feelings,
  relationship_talk,
  meeting_friends,
  hobbies_interests,
  food_cooking,
  music_arts,
  sports_fitness,
  weekend_plans,
  holidays_celebrations,
  family_talk,
  daily_life,
  fun_idioms,
  humor_jokes,
  deep_conversations;

  String get displayName {
    switch (this) {
      case LessonCategory.dating_basics:
        return 'Dating Basics';
      case LessonCategory.first_impressions:
        return 'First Impressions';
      case LessonCategory.compliments_flirting:
        return 'Compliments & Flirting';
      case LessonCategory.asking_out:
        return 'Asking Someone Out';
      case LessonCategory.restaurant_dates:
        return 'Restaurant Dates';
      case LessonCategory.cafe_conversations:
        return 'Cafe Conversations';
      case LessonCategory.movies_entertainment:
        return 'Movies & Entertainment';
      case LessonCategory.travel_adventures:
        return 'Travel Adventures';
      case LessonCategory.cultural_exchange:
        return 'Cultural Exchange';
      case LessonCategory.video_calls:
        return 'Video Calls';
      case LessonCategory.expressing_feelings:
        return 'Expressing Feelings';
      case LessonCategory.relationship_talk:
        return 'Relationship Talk';
      case LessonCategory.meeting_friends:
        return 'Meeting Friends';
      case LessonCategory.hobbies_interests:
        return 'Hobbies & Interests';
      case LessonCategory.food_cooking:
        return 'Food & Cooking';
      case LessonCategory.music_arts:
        return 'Music & Arts';
      case LessonCategory.sports_fitness:
        return 'Sports & Fitness';
      case LessonCategory.weekend_plans:
        return 'Weekend Plans';
      case LessonCategory.holidays_celebrations:
        return 'Holidays & Celebrations';
      case LessonCategory.family_talk:
        return 'Family Talk';
      case LessonCategory.daily_life:
        return 'Daily Life';
      case LessonCategory.fun_idioms:
        return 'Fun Idioms';
      case LessonCategory.humor_jokes:
        return 'Humor & Jokes';
      case LessonCategory.deep_conversations:
        return 'Deep Conversations';
    }
  }

  String get emoji {
    switch (this) {
      case LessonCategory.dating_basics:
        return '💕';
      case LessonCategory.first_impressions:
        return '👋';
      case LessonCategory.compliments_flirting:
        return '😍';
      case LessonCategory.asking_out:
        return '💌';
      case LessonCategory.restaurant_dates:
        return '🍽️';
      case LessonCategory.cafe_conversations:
        return '☕';
      case LessonCategory.movies_entertainment:
        return '🎬';
      case LessonCategory.travel_adventures:
        return '✈️';
      case LessonCategory.cultural_exchange:
        return '🌍';
      case LessonCategory.video_calls:
        return '📱';
      case LessonCategory.expressing_feelings:
        return '❤️';
      case LessonCategory.relationship_talk:
        return '💑';
      case LessonCategory.meeting_friends:
        return '👥';
      case LessonCategory.hobbies_interests:
        return '🎯';
      case LessonCategory.food_cooking:
        return '🍳';
      case LessonCategory.music_arts:
        return '🎵';
      case LessonCategory.sports_fitness:
        return '⚽';
      case LessonCategory.weekend_plans:
        return '🌞';
      case LessonCategory.holidays_celebrations:
        return '🎉';
      case LessonCategory.family_talk:
        return '👨‍👩‍👧‍👦';
      case LessonCategory.daily_life:
        return '🏠';
      case LessonCategory.fun_idioms:
        return '🗣️';
      case LessonCategory.humor_jokes:
        return '😄';
      case LessonCategory.deep_conversations:
        return '💭';
    }
  }
}

/// A section within a lesson (e.g., vocabulary, dialogue, practice)
class LessonSection extends Equatable {
  final String id;
  final String title;
  final LessonSectionType type;
  final int orderIndex;
  final String? introduction;
  final List<LessonContent> contents;
  final List<LessonExercise> exercises;
  final int xpReward;

  const LessonSection({
    required this.id,
    required this.title,
    required this.type,
    required this.orderIndex,
    this.introduction,
    required this.contents,
    required this.exercises,
    this.xpReward = 10,
  });

  @override
  List<Object?> get props => [id, title, type, orderIndex];
}

enum LessonSectionType {
  vocabulary,
  dialogue,
  grammar_tip,
  cultural_note,
  pronunciation,
  practice,
  conversation_simulation,
  quiz,
  fun_fact;

  String get displayName {
    switch (this) {
      case LessonSectionType.vocabulary:
        return 'Vocabulary';
      case LessonSectionType.dialogue:
        return 'Dialogue';
      case LessonSectionType.grammar_tip:
        return 'Grammar Tip';
      case LessonSectionType.cultural_note:
        return 'Cultural Note';
      case LessonSectionType.pronunciation:
        return 'Pronunciation';
      case LessonSectionType.practice:
        return 'Practice';
      case LessonSectionType.conversation_simulation:
        return 'Conversation';
      case LessonSectionType.quiz:
        return 'Quiz';
      case LessonSectionType.fun_fact:
        return 'Fun Fact';
    }
  }

  String get icon {
    switch (this) {
      case LessonSectionType.vocabulary:
        return '📚';
      case LessonSectionType.dialogue:
        return '💬';
      case LessonSectionType.grammar_tip:
        return '📝';
      case LessonSectionType.cultural_note:
        return '🌍';
      case LessonSectionType.pronunciation:
        return '🗣️';
      case LessonSectionType.practice:
        return '✏️';
      case LessonSectionType.conversation_simulation:
        return '🎭';
      case LessonSectionType.quiz:
        return '❓';
      case LessonSectionType.fun_fact:
        return '💡';
    }
  }
}

/// Content item within a section
class LessonContent extends Equatable {
  final String id;
  final LessonContentType type;
  final String? text;
  final String? translation;
  final String? pronunciation; // IPA or phonetic
  final String? audioUrl;
  final String? imageUrl;
  final String? videoUrl;
  final Map<String, dynamic>? extras;

  const LessonContent({
    required this.id,
    required this.type,
    this.text,
    this.translation,
    this.pronunciation,
    this.audioUrl,
    this.imageUrl,
    this.videoUrl,
    this.extras,
  });

  @override
  List<Object?> get props => [id, type, text];
}

enum LessonContentType {
  text,
  phrase,
  dialogue_line,
  grammar_explanation,
  example,
  image,
  audio,
  video,
  tip,
  warning,
  fun_fact,
}

/// Interactive exercise within a lesson
class LessonExercise extends Equatable {
  final String id;
  final ExerciseType type;
  final String question;
  final String? questionTranslation;
  final String? audioUrl;
  final String? imageUrl;
  final List<String> options; // For multiple choice
  final String correctAnswer;
  final List<String>? acceptableAnswers; // Alternative correct answers
  final String? explanation;
  final String? hint;
  final int xpReward;
  final int orderIndex;

  const LessonExercise({
    required this.id,
    required this.type,
    required this.question,
    this.questionTranslation,
    this.audioUrl,
    this.imageUrl,
    this.options = const [],
    required this.correctAnswer,
    this.acceptableAnswers,
    this.explanation,
    this.hint,
    this.xpReward = 5,
    required this.orderIndex,
  });

  @override
  List<Object?> get props => [id, type, question, correctAnswer];
}

enum ExerciseType {
  multiple_choice,
  fill_in_blank,
  translation,
  listening,
  speaking,
  matching,
  reorder_words,
  true_false,
  conversation_choice,
  free_response;

  String get displayName {
    switch (this) {
      case ExerciseType.multiple_choice:
        return 'Multiple Choice';
      case ExerciseType.fill_in_blank:
        return 'Fill in the Blank';
      case ExerciseType.translation:
        return 'Translation';
      case ExerciseType.listening:
        return 'Listening';
      case ExerciseType.speaking:
        return 'Speaking';
      case ExerciseType.matching:
        return 'Matching';
      case ExerciseType.reorder_words:
        return 'Reorder Words';
      case ExerciseType.true_false:
        return 'True or False';
      case ExerciseType.conversation_choice:
        return 'Conversation Choice';
      case ExerciseType.free_response:
        return 'Free Response';
    }
  }
}

/// User's purchased lesson access
class UserLessonAccess extends Equatable {
  final String id;
  final String odUserId;
  final String lessonId;
  final DateTime purchasedAt;
  final int coinsPaid;
  final bool isCompleted;
  final DateTime? completedAt;
  final double progressPercent;
  final int earnedXp;
  final Map<String, LessonSectionProgress> sectionProgress;

  const UserLessonAccess({
    required this.id,
    required this.odUserId,
    required this.lessonId,
    required this.purchasedAt,
    required this.coinsPaid,
    this.isCompleted = false,
    this.completedAt,
    this.progressPercent = 0.0,
    this.earnedXp = 0,
    this.sectionProgress = const {},
  });

  @override
  List<Object?> get props => [id, odUserId, lessonId, isCompleted];
}

/// Progress within a specific lesson section
class LessonSectionProgress extends Equatable {
  final String sectionId;
  final bool isCompleted;
  final int correctAnswers;
  final int totalExercises;
  final int attempts;
  final DateTime? lastAttemptAt;

  const LessonSectionProgress({
    required this.sectionId,
    this.isCompleted = false,
    this.correctAnswers = 0,
    this.totalExercises = 0,
    this.attempts = 0,
    this.lastAttemptAt,
  });

  double get accuracy =>
      totalExercises > 0 ? correctAnswers / totalExercises : 0.0;

  @override
  List<Object?> get props =>
      [sectionId, isCompleted, correctAnswers, totalExercises];
}
