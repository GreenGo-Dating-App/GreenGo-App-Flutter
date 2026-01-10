import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/daily_hint.dart';
import '../../domain/entities/language_phrase.dart';
import 'language_phrase_model.dart';

class DailyHintModel extends DailyHint {
  const DailyHintModel({
    required super.id,
    required super.phrase,
    required super.date,
    super.isViewed,
    super.isLearned,
    super.viewXpReward,
    super.learnXpReward,
  });

  factory DailyHintModel.fromJson(Map<String, dynamic> json) {
    return DailyHintModel(
      id: json['id'] as String,
      phrase: LanguagePhraseModel.fromJson(json['phrase'] as Map<String, dynamic>),
      date: (json['date'] as Timestamp).toDate(),
      isViewed: json['isViewed'] as bool? ?? false,
      isLearned: json['isLearned'] as bool? ?? false,
      viewXpReward: json['viewXpReward'] as int? ?? 5,
      learnXpReward: json['learnXpReward'] as int? ?? 10,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phrase': (phrase is LanguagePhraseModel)
          ? (phrase as LanguagePhraseModel).toJson()
          : LanguagePhraseModel.fromEntity(phrase).toJson(),
      'date': Timestamp.fromDate(date),
      'isViewed': isViewed,
      'isLearned': isLearned,
      'viewXpReward': viewXpReward,
      'learnXpReward': learnXpReward,
    };
  }

  factory DailyHintModel.fromEntity(DailyHint entity) {
    return DailyHintModel(
      id: entity.id,
      phrase: entity.phrase,
      date: entity.date,
      isViewed: entity.isViewed,
      isLearned: entity.isLearned,
      viewXpReward: entity.viewXpReward,
      learnXpReward: entity.learnXpReward,
    );
  }
}
