import '../../domain/entities/safety_lesson.dart';
import '../../domain/entities/safety_module.dart';
import '../../domain/entities/safety_progress.dart';
import '../../domain/repositories/safety_academy_repository.dart';
import '../datasources/safety_academy_remote_datasource.dart';

/// Concrete implementation of [SafetyAcademyRepository].
///
/// Delegates all operations to the remote datasource and handles
/// XP reward calculation for lesson completion.
class SafetyAcademyRepositoryImpl implements SafetyAcademyRepository {
  final SafetyAcademyRemoteDatasource _remoteDatasource;

  SafetyAcademyRepositoryImpl({
    required SafetyAcademyRemoteDatasource remoteDatasource,
  }) : _remoteDatasource = remoteDatasource;

  @override
  Future<List<SafetyModule>> getModules() async {
    return _remoteDatasource.getModules();
  }

  @override
  Future<SafetyModule?> getModuleById(String id) async {
    return _remoteDatasource.getModuleById(id);
  }

  @override
  Future<List<SafetyLesson>> getLessonsForModule(String moduleId) async {
    return _remoteDatasource.getLessonsForModule(moduleId);
  }

  @override
  Future<SafetyLesson?> getLessonById(String id) async {
    return _remoteDatasource.getLessonById(id);
  }

  @override
  Future<SafetyProgress> getUserProgress(String userId) async {
    return _remoteDatasource.getUserProgress(userId);
  }

  @override
  Future<void> completeLesson(
    String userId,
    String lessonId,
    int? quizScore,
  ) async {
    // Fetch the lesson to get its XP reward value
    final lesson = await _remoteDatasource.getLessonById(lessonId);
    final xpReward = lesson?.xpReward ?? 10;

    await _remoteDatasource.completeLesson(
      userId,
      lessonId,
      quizScore,
      xpReward,
    );
  }

  @override
  Future<void> completeModule(String userId, String moduleId) async {
    // Fetch total module count for badge awarding logic
    final modules = await _remoteDatasource.getModules();
    await _remoteDatasource.completeModule(
      userId,
      moduleId,
      modules.length,
    );
  }
}
