import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/learning_streak.dart';

class LearningStreakModel extends LearningStreak {
  const LearningStreakModel({
    required super.id,
    required super.odUserId,
    super.currentStreak,
    super.longestStreak,
    super.lastPracticeDate,
    super.practiceHistory,
    super.achievedMilestones,
    super.totalPracticeDays,
  });

  factory LearningStreakModel.fromJson(Map<String, dynamic> json) {
    return LearningStreakModel(
      id: json['id'] as String,
      odUserId: json['odUserId'] as String,
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      lastPracticeDate: json['lastPracticeDate'] != null
          ? (json['lastPracticeDate'] as Timestamp).toDate()
          : null,
      practiceHistory: (json['practiceHistory'] as List<dynamic>?)
              ?.map((e) => (e as Timestamp).toDate())
              .toList() ??
          [],
      achievedMilestones: (json['achievedMilestones'] as List<dynamic>?)
              ?.map((e) => StreakMilestone.allMilestones.firstWhere(
                    (m) => m.requiredDays == e['requiredDays'],
                    orElse: () => StreakMilestone.allMilestones.first,
                  ))
              .toList() ??
          [],
      totalPracticeDays: json['totalPracticeDays'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'odUserId': odUserId,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastPracticeDate': lastPracticeDate != null
          ? Timestamp.fromDate(lastPracticeDate!)
          : null,
      'practiceHistory':
          practiceHistory.map((e) => Timestamp.fromDate(e)).toList(),
      'achievedMilestones': achievedMilestones
          .map((e) => {
                'requiredDays': e.requiredDays,
                'name': e.name,
              })
          .toList(),
      'totalPracticeDays': totalPracticeDays,
    };
  }

  factory LearningStreakModel.fromEntity(LearningStreak entity) {
    return LearningStreakModel(
      id: entity.id,
      odUserId: entity.odUserId,
      currentStreak: entity.currentStreak,
      longestStreak: entity.longestStreak,
      lastPracticeDate: entity.lastPracticeDate,
      practiceHistory: entity.practiceHistory,
      achievedMilestones: entity.achievedMilestones,
      totalPracticeDays: entity.totalPracticeDays,
    );
  }
}
