import 'package:equatable/equatable.dart';

/// A single node in a constellation (learning path).
///
/// Stored in the Firestore `constellation` collection.
/// Each document defines one node: its position within a unit,
/// its type (ClassicLesson, AICoaching, Quiz, Flashcard, FinalQuiz),
/// title, and XP reward.
class ConstellationNode extends Equatable {
  final String id;

  /// Language pair
  final String languageSource; // e.g. "IT"
  final String languageTarget; // e.g. "EN"

  /// Unit number (1-based)
  final int unit;

  /// Node position within the unit (1-based, sequential)
  final int nodeIndex;

  /// Display title for the unit (e.g. "Hello & Greetings")
  final String unitTitle;

  /// Node type: ClassicLesson, AICoaching, Quiz, Flashcard, FinalQuiz
  final String nodeType;

  /// Display title for the node (e.g. "First Appointment", "AI Coach", "Quiz 1")
  final String nodeTitle;

  /// XP reward for completing this node
  final int xp;

  /// Coin cost to unlock (0 = free)
  final int coinCost;

  const ConstellationNode({
    required this.id,
    required this.languageSource,
    required this.languageTarget,
    required this.unit,
    required this.nodeIndex,
    required this.unitTitle,
    required this.nodeType,
    required this.nodeTitle,
    this.xp = 15,
    this.coinCost = 0,
  });

  @override
  List<Object?> get props => [
        id,
        languageSource,
        languageTarget,
        unit,
        nodeIndex,
        unitTitle,
        nodeType,
        nodeTitle,
        xp,
        coinCost,
      ];
}
