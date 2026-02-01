import 'package:equatable/equatable.dart';

/// Icebreaker Category
enum IcebreakerCategory {
  funnyQuestions,
  deepQuestions,
  wouldYouRather,
  twoTruths,
  dateIdeas,
  compliments,
  hobbies,
  travel,
  food,
  music,
  movies,
  dreams,
  hypothetical,
  personality,
}

/// Icebreaker Entity
/// Conversation starter prompts for new matches
class Icebreaker extends Equatable {
  final String id;
  final String question;
  final IcebreakerCategory category;
  final List<String>? suggestedAnswers;
  final int usageCount;
  final double successRate;
  final bool isPremium;
  final bool isActive;
  final DateTime createdAt;

  const Icebreaker({
    required this.id,
    required this.question,
    required this.category,
    this.suggestedAnswers,
    this.usageCount = 0,
    this.successRate = 0.0,
    this.isPremium = false,
    this.isActive = true,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        question,
        category,
        suggestedAnswers,
        usageCount,
        successRate,
        isPremium,
        isActive,
        createdAt,
      ];
}

/// Icebreaker Response
class IcebreakerResponse extends Equatable {
  final String id;
  final String icebreakerId;
  final String matchId;
  final String senderId;
  final String receiverId;
  final String response;
  final DateTime sentAt;
  final bool wasReplied;

  const IcebreakerResponse({
    required this.id,
    required this.icebreakerId,
    required this.matchId,
    required this.senderId,
    required this.receiverId,
    required this.response,
    required this.sentAt,
    this.wasReplied = false,
  });

  @override
  List<Object?> get props => [
        id,
        icebreakerId,
        matchId,
        senderId,
        receiverId,
        response,
        sentAt,
        wasReplied,
      ];
}

/// Default Icebreakers Database
class IcebreakerDatabase {
  static const List<Map<String, dynamic>> defaultIcebreakers = [
    // Funny Questions
    {
      'question': "If you could have dinner with any fictional character, who would it be and why?",
      'category': IcebreakerCategory.funnyQuestions,
    },
    {
      'question': "What's the most embarrassing song on your playlist?",
      'category': IcebreakerCategory.funnyQuestions,
    },
    {
      'question': "If you were a superhero, what would your useless superpower be?",
      'category': IcebreakerCategory.funnyQuestions,
    },
    {
      'question': "What's your go-to karaoke song?",
      'category': IcebreakerCategory.funnyQuestions,
    },
    // Deep Questions
    {
      'question': "What's something you've always wanted to try but haven't yet?",
      'category': IcebreakerCategory.deepQuestions,
    },
    {
      'question': "What's the best advice you've ever received?",
      'category': IcebreakerCategory.deepQuestions,
    },
    {
      'question': "If you could master any skill instantly, what would it be?",
      'category': IcebreakerCategory.deepQuestions,
    },
    // Would You Rather
    {
      'question': "Would you rather explore space or the deep ocean?",
      'category': IcebreakerCategory.wouldYouRather,
      'suggestedAnswers': ['Space', 'Deep Ocean'],
    },
    {
      'question': "Would you rather be able to fly or be invisible?",
      'category': IcebreakerCategory.wouldYouRather,
      'suggestedAnswers': ['Fly', 'Invisible'],
    },
    {
      'question': "Would you rather have unlimited money or unlimited time?",
      'category': IcebreakerCategory.wouldYouRather,
      'suggestedAnswers': ['Unlimited Money', 'Unlimited Time'],
    },
    // Two Truths
    {
      'question': "Tell me two truths and a lie about yourself!",
      'category': IcebreakerCategory.twoTruths,
    },
    // Date Ideas
    {
      'question': "What's your idea of a perfect first date?",
      'category': IcebreakerCategory.dateIdeas,
    },
    {
      'question': "Coffee date or adventure date?",
      'category': IcebreakerCategory.dateIdeas,
      'suggestedAnswers': ['Coffee date', 'Adventure date'],
    },
    // Travel
    {
      'question': "What's your dream travel destination?",
      'category': IcebreakerCategory.travel,
    },
    {
      'question': "Beach vacation or mountain retreat?",
      'category': IcebreakerCategory.travel,
      'suggestedAnswers': ['Beach', 'Mountains'],
    },
    // Food
    {
      'question': "What's your comfort food?",
      'category': IcebreakerCategory.food,
    },
    {
      'question': "Cooking at home or dining out?",
      'category': IcebreakerCategory.food,
      'suggestedAnswers': ['Cooking at home', 'Dining out'],
    },
    // Music
    {
      'question': "What song always puts you in a good mood?",
      'category': IcebreakerCategory.music,
    },
    {
      'question': "What was the last concert you went to?",
      'category': IcebreakerCategory.music,
    },
    // Hypothetical
    {
      'question': "If you won the lottery tomorrow, what's the first thing you'd do?",
      'category': IcebreakerCategory.hypothetical,
    },
    {
      'question': "If you could live in any era, which would you choose?",
      'category': IcebreakerCategory.hypothetical,
    },
    // Personality
    {
      'question': "Are you more of a morning person or night owl?",
      'category': IcebreakerCategory.personality,
      'suggestedAnswers': ['Morning person', 'Night owl'],
    },
    {
      'question': "Introvert, extrovert, or ambivert?",
      'category': IcebreakerCategory.personality,
      'suggestedAnswers': ['Introvert', 'Extrovert', 'Ambivert'],
    },
    {
      'question': "What's your love language?",
      'category': IcebreakerCategory.personality,
      'suggestedAnswers': ['Words of Affirmation', 'Acts of Service', 'Receiving Gifts', 'Quality Time', 'Physical Touch'],
    },
  ];
}
