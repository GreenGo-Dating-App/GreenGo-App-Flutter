import 'package:equatable/equatable.dart';

/// Safety Academy Progress Entity
///
/// Tracks a user's progress through the Safety Academy,
/// including completed modules, lessons, quiz scores, XP, and badges.
class SafetyProgress extends Equatable {
  final String userId;
  final List<String> completedModules;
  final List<String> completedLessons;
  final Map<String, int> quizScores;
  final int totalXpEarned;
  final List<String> badges;

  const SafetyProgress({
    required this.userId,
    this.completedModules = const [],
    this.completedLessons = const [],
    this.quizScores = const {},
    this.totalXpEarned = 0,
    this.badges = const [],
  });

  /// Check if a specific module is completed
  bool isModuleCompleted(String moduleId) =>
      completedModules.contains(moduleId);

  /// Check if a specific lesson is completed
  bool isLessonCompleted(String lessonId) =>
      completedLessons.contains(lessonId);

  /// Get quiz score for a specific lesson (null if not taken)
  int? getQuizScore(String lessonId) => quizScores[lessonId];

  /// Count completed lessons within a module
  int completedLessonsInModule(List<String> moduleLessonIds) {
    return moduleLessonIds
        .where((lessonId) => completedLessons.contains(lessonId))
        .length;
  }

  @override
  List<Object?> get props => [
        userId,
        completedModules,
        completedLessons,
        quizScores,
        totalXpEarned,
        badges,
      ];
}
