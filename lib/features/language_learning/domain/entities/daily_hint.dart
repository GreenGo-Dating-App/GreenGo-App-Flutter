import 'package:equatable/equatable.dart';
import 'language_phrase.dart';

/// Represents the daily language hint/word of the day
class DailyHint extends Equatable {
  final String id;
  final LanguagePhrase phrase;
  final DateTime date;
  final bool isViewed;
  final bool isLearned;
  final int viewXpReward;
  final int learnXpReward;

  const DailyHint({
    required this.id,
    required this.phrase,
    required this.date,
    this.isViewed = false,
    this.isLearned = false,
    this.viewXpReward = 5,
    this.learnXpReward = 10,
  });

  DailyHint copyWith({
    String? id,
    LanguagePhrase? phrase,
    DateTime? date,
    bool? isViewed,
    bool? isLearned,
    int? viewXpReward,
    int? learnXpReward,
  }) {
    return DailyHint(
      id: id ?? this.id,
      phrase: phrase ?? this.phrase,
      date: date ?? this.date,
      isViewed: isViewed ?? this.isViewed,
      isLearned: isLearned ?? this.isLearned,
      viewXpReward: viewXpReward ?? this.viewXpReward,
      learnXpReward: learnXpReward ?? this.learnXpReward,
    );
  }

  int get totalXpEarned {
    int total = 0;
    if (isViewed) total += viewXpReward;
    if (isLearned) total += learnXpReward;
    return total;
  }

  @override
  List<Object?> get props => [
        id,
        phrase,
        date,
        isViewed,
        isLearned,
        viewXpReward,
        learnXpReward,
      ];
}
