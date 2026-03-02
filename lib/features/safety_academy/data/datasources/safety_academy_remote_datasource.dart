import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/safety_lesson_model.dart';
import '../models/safety_module_model.dart';
import '../models/safety_progress_model.dart';

/// Remote datasource for the Safety Academy feature.
///
/// Handles all Firestore CRUD operations for safety modules,
/// lessons, and user progress tracking.
class SafetyAcademyRemoteDatasource {
  final FirebaseFirestore _firestore;

  SafetyAcademyRemoteDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // Collection references
  // ---------------------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> get _modulesCollection =>
      _firestore.collection('safety_modules');

  CollectionReference<Map<String, dynamic>> get _lessonsCollection =>
      _firestore.collection('safety_lessons');

  DocumentReference<Map<String, dynamic>> _progressDoc(String userId) =>
      _firestore
          .collection('users')
          .doc(userId)
          .collection('safety_progress')
          .doc('progress');

  // ---------------------------------------------------------------------------
  // Module operations
  // ---------------------------------------------------------------------------

  /// Fetch all safety modules ordered by [order] field
  Future<List<SafetyModuleModel>> getModules() async {
    try {
      final snapshot =
          await _modulesCollection.orderBy('order', descending: false).get();

      return snapshot.docs
          .map((doc) => SafetyModuleModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch safety modules: $e');
    }
  }

  /// Fetch a single module by ID
  Future<SafetyModuleModel?> getModuleById(String id) async {
    try {
      final doc = await _modulesCollection.doc(id).get();
      if (!doc.exists) return null;
      return SafetyModuleModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to fetch safety module $id: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Lesson operations
  // ---------------------------------------------------------------------------

  /// Fetch all lessons for a given module, ordered by [order] field
  Future<List<SafetyLessonModel>> getLessonsForModule(String moduleId) async {
    try {
      final snapshot = await _lessonsCollection
          .where('moduleId', isEqualTo: moduleId)
          .orderBy('order', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => SafetyLessonModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch lessons for module $moduleId: $e');
    }
  }

  /// Fetch a single lesson by ID
  Future<SafetyLessonModel?> getLessonById(String id) async {
    try {
      final doc = await _lessonsCollection.doc(id).get();
      if (!doc.exists) return null;
      return SafetyLessonModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to fetch lesson $id: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Progress operations
  // ---------------------------------------------------------------------------

  /// Fetch the user's safety academy progress, creating a default if none exists
  Future<SafetyProgressModel> getUserProgress(String userId) async {
    try {
      final doc = await _progressDoc(userId).get();
      if (!doc.exists) {
        return SafetyProgressModel.empty(userId);
      }
      return SafetyProgressModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to fetch safety progress for user $userId: $e');
    }
  }

  /// Mark a lesson as completed and optionally record a quiz score.
  /// Also increments total XP earned.
  Future<void> completeLesson(
    String userId,
    String lessonId,
    int? quizScore,
    int xpReward,
  ) async {
    try {
      final docRef = _progressDoc(userId);
      final doc = await docRef.get();

      if (!doc.exists) {
        // Create initial progress document
        final progress = SafetyProgressModel(
          userId: userId,
          completedLessons: [lessonId],
          quizScores:
              quizScore != null ? {lessonId: quizScore} : {},
          totalXpEarned: xpReward,
        );
        await docRef.set(progress.toJson());
      } else {
        // Update existing progress
        final updates = <String, dynamic>{
          'completedLessons': FieldValue.arrayUnion([lessonId]),
          'totalXpEarned': FieldValue.increment(xpReward),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (quizScore != null) {
          updates['quizScores.$lessonId'] = quizScore;
        }

        await docRef.update(updates);
      }
    } catch (e) {
      throw Exception('Failed to complete lesson $lessonId: $e');
    }
  }

  /// Mark a module as completed and award the "Safety Champion" badge
  /// if all modules are done.
  Future<void> completeModule(
    String userId,
    String moduleId,
    int totalModuleCount,
  ) async {
    try {
      final docRef = _progressDoc(userId);
      final doc = await docRef.get();

      if (!doc.exists) {
        final progress = SafetyProgressModel(
          userId: userId,
          completedModules: [moduleId],
        );
        await docRef.set(progress.toJson());
      } else {
        final updates = <String, dynamic>{
          'completedModules': FieldValue.arrayUnion([moduleId]),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Check if this completion means all modules are done
        final currentData = doc.data() ?? {};
        final completedModules =
            (currentData['completedModules'] as List<dynamic>?)
                    ?.map((e) => e as String)
                    .toList() ??
                [];

        if (!completedModules.contains(moduleId)) {
          completedModules.add(moduleId);
        }

        if (completedModules.length >= totalModuleCount) {
          updates['badges'] =
              FieldValue.arrayUnion(['safety_champion']);
        }

        await docRef.update(updates);
      }
    } catch (e) {
      throw Exception('Failed to complete module $moduleId: $e');
    }
  }
}
