import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/safety_progress.dart';

/// Firestore data model for [SafetyProgress]
class SafetyProgressModel extends SafetyProgress {
  const SafetyProgressModel({
    required super.userId,
    super.completedModules,
    super.completedLessons,
    super.quizScores,
    super.totalXpEarned,
    super.badges,
  });

  factory SafetyProgressModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return SafetyProgressModel(
      userId: data['userId'] as String? ?? doc.id,
      completedModules: (data['completedModules'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      completedLessons: (data['completedLessons'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      quizScores: (data['quizScores'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(key, value as int)) ??
          {},
      totalXpEarned: data['totalXpEarned'] as int? ?? 0,
      badges: (data['badges'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  factory SafetyProgressModel.fromMap(Map<String, dynamic> map) {
    return SafetyProgressModel(
      userId: map['userId'] as String? ?? '',
      completedModules: (map['completedModules'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      completedLessons: (map['completedLessons'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      quizScores: (map['quizScores'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(key, value as int)) ??
          {},
      totalXpEarned: map['totalXpEarned'] as int? ?? 0,
      badges: (map['badges'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  factory SafetyProgressModel.fromEntity(SafetyProgress entity) {
    return SafetyProgressModel(
      userId: entity.userId,
      completedModules: entity.completedModules,
      completedLessons: entity.completedLessons,
      quizScores: entity.quizScores,
      totalXpEarned: entity.totalXpEarned,
      badges: entity.badges,
    );
  }

  /// Create an empty progress for a new user
  factory SafetyProgressModel.empty(String userId) {
    return SafetyProgressModel(userId: userId);
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'completedModules': completedModules,
      'completedLessons': completedLessons,
      'quizScores': quizScores,
      'totalXpEarned': totalXpEarned,
      'badges': badges,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
