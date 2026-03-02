import '../entities/safety_lesson.dart';
import '../entities/safety_module.dart';
import '../entities/safety_progress.dart';

/// Abstract repository interface for the Safety Academy feature.
///
/// Defines the contract for data operations including
/// fetching modules/lessons and tracking user progress.
abstract class SafetyAcademyRepository {
  /// Get all available safety modules, ordered by [SafetyModule.order]
  Future<List<SafetyModule>> getModules();

  /// Get a single module by its ID
  Future<SafetyModule?> getModuleById(String id);

  /// Get all lessons belonging to a specific module, ordered by [SafetyLesson.order]
  Future<List<SafetyLesson>> getLessonsForModule(String moduleId);

  /// Get a single lesson by its ID
  Future<SafetyLesson?> getLessonById(String id);

  /// Get the current user's progress through the academy
  Future<SafetyProgress> getUserProgress(String userId);

  /// Mark a lesson as completed, optionally recording a quiz score
  Future<void> completeLesson(String userId, String lessonId, int? quizScore);

  /// Mark a module as completed (all lessons done)
  Future<void> completeModule(String userId, String moduleId);
}
