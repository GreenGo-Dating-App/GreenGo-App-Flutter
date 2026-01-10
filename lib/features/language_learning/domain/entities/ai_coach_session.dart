import 'package:equatable/equatable.dart';

/// Represents an AI conversation coach session
class AiCoachSession extends Equatable {
  final String id;
  final String odUserId;
  final String targetLanguageCode;
  final String targetLanguageName;
  final CoachScenario scenario;
  final List<CoachMessage> messages;
  final int coinCost;
  final int xpReward;
  final bool isCompleted;
  final DateTime startedAt;
  final DateTime? completedAt;
  final CoachSessionScore? score;

  const AiCoachSession({
    required this.id,
    required this.odUserId,
    required this.targetLanguageCode,
    required this.targetLanguageName,
    required this.scenario,
    this.messages = const [],
    this.coinCost = 10,
    this.xpReward = 25,
    this.isCompleted = false,
    required this.startedAt,
    this.completedAt,
    this.score,
  });

  AiCoachSession copyWith({
    String? id,
    String? odUserId,
    String? targetLanguageCode,
    String? targetLanguageName,
    CoachScenario? scenario,
    List<CoachMessage>? messages,
    int? coinCost,
    int? xpReward,
    bool? isCompleted,
    DateTime? startedAt,
    DateTime? completedAt,
    CoachSessionScore? score,
  }) {
    return AiCoachSession(
      id: id ?? this.id,
      odUserId: odUserId ?? this.odUserId,
      targetLanguageCode: targetLanguageCode ?? this.targetLanguageCode,
      targetLanguageName: targetLanguageName ?? this.targetLanguageName,
      scenario: scenario ?? this.scenario,
      messages: messages ?? this.messages,
      coinCost: coinCost ?? this.coinCost,
      xpReward: xpReward ?? this.xpReward,
      isCompleted: isCompleted ?? this.isCompleted,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      score: score ?? this.score,
    );
  }

  Duration? get sessionDuration {
    if (completedAt == null) return null;
    return completedAt!.difference(startedAt);
  }

  int get messageCount => messages.length;

  @override
  List<Object?> get props => [
        id,
        odUserId,
        targetLanguageCode,
        targetLanguageName,
        scenario,
        messages,
        coinCost,
        xpReward,
        isCompleted,
        startedAt,
        completedAt,
        score,
      ];
}

class CoachMessage extends Equatable {
  final String id;
  final String content;
  final String? translation;
  final bool isUserMessage;
  final DateTime timestamp;
  final String? correction;
  final String? feedback;
  final List<String>? suggestedResponses;

  const CoachMessage({
    required this.id,
    required this.content,
    this.translation,
    required this.isUserMessage,
    required this.timestamp,
    this.correction,
    this.feedback,
    this.suggestedResponses,
  });

  @override
  List<Object?> get props => [
        id,
        content,
        translation,
        isUserMessage,
        timestamp,
        correction,
        feedback,
        suggestedResponses,
      ];
}

class CoachSessionScore extends Equatable {
  final double grammarAccuracy;
  final double vocabularyUsage;
  final double fluency;
  final double overallScore;
  final List<String> strengths;
  final List<String> areasToImprove;

  const CoachSessionScore({
    required this.grammarAccuracy,
    required this.vocabularyUsage,
    required this.fluency,
    required this.overallScore,
    this.strengths = const [],
    this.areasToImprove = const [],
  });

  String get grade {
    if (overallScore >= 90) return 'A';
    if (overallScore >= 80) return 'B';
    if (overallScore >= 70) return 'C';
    if (overallScore >= 60) return 'D';
    return 'F';
  }

  @override
  List<Object?> get props => [
        grammarAccuracy,
        vocabularyUsage,
        fluency,
        overallScore,
        strengths,
        areasToImprove,
      ];
}

enum CoachScenario {
  firstDate,
  gettingToKnow,
  videoCallPrep,
  askingOut,
  complimenting,
  discussingInterests,
  travelPlanning,
  casualChat,
}

extension CoachScenarioExtension on CoachScenario {
  String get displayName {
    switch (this) {
      case CoachScenario.firstDate:
        return 'First Date Conversation';
      case CoachScenario.gettingToKnow:
        return 'Getting to Know Someone';
      case CoachScenario.videoCallPrep:
        return 'Video Call Preparation';
      case CoachScenario.askingOut:
        return 'Asking Someone Out';
      case CoachScenario.complimenting:
        return 'Giving Compliments';
      case CoachScenario.discussingInterests:
        return 'Discussing Interests';
      case CoachScenario.travelPlanning:
        return 'Planning a Trip Together';
      case CoachScenario.casualChat:
        return 'Casual Chatting';
    }
  }

  String get description {
    switch (this) {
      case CoachScenario.firstDate:
        return 'Practice conversation skills for a first date';
      case CoachScenario.gettingToKnow:
        return 'Learn to ask and answer common questions';
      case CoachScenario.videoCallPrep:
        return 'Prepare for your first video call';
      case CoachScenario.askingOut:
        return 'Learn how to ask someone on a date';
      case CoachScenario.complimenting:
        return 'Practice giving sincere compliments';
      case CoachScenario.discussingInterests:
        return 'Talk about hobbies and passions';
      case CoachScenario.travelPlanning:
        return 'Discuss travel plans and destinations';
      case CoachScenario.casualChat:
        return 'Free-form casual conversation practice';
    }
  }

  String get icon {
    switch (this) {
      case CoachScenario.firstDate:
        return '💑';
      case CoachScenario.gettingToKnow:
        return '🤝';
      case CoachScenario.videoCallPrep:
        return '📹';
      case CoachScenario.askingOut:
        return '💌';
      case CoachScenario.complimenting:
        return '💫';
      case CoachScenario.discussingInterests:
        return '🎯';
      case CoachScenario.travelPlanning:
        return '✈️';
      case CoachScenario.casualChat:
        return '💬';
    }
  }

  String get startingPrompt {
    switch (this) {
      case CoachScenario.firstDate:
        return 'You\'re meeting someone for the first time at a coffee shop. Start the conversation!';
      case CoachScenario.gettingToKnow:
        return 'You\'ve just matched with someone. Ask them about themselves!';
      case CoachScenario.videoCallPrep:
        return 'You\'re about to have your first video call. How would you start?';
      case CoachScenario.askingOut:
        return 'You want to ask this person to meet in person. How would you approach it?';
      case CoachScenario.complimenting:
        return 'You want to compliment something about them. What would you say?';
      case CoachScenario.discussingInterests:
        return 'Share your hobbies and ask about theirs!';
      case CoachScenario.travelPlanning:
        return 'Discuss a place you\'d both like to visit together.';
      case CoachScenario.casualChat:
        return 'Just have a casual conversation about your day!';
    }
  }
}
