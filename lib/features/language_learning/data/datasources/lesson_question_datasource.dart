import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/cache_service.dart';
import '../models/lesson_question_model.dart';

class LessonQuestionDatasource {
  final FirebaseFirestore firestore;
  final CacheService cacheService;

  static const Duration _cacheTTL = Duration(hours: 12);

  LessonQuestionDatasource({
    required this.firestore,
    required this.cacheService,
  });

  CollectionReference get _col => firestore.collection('lessons');

  String _cacheKey(String src, String tgt, int unit, int lesson) =>
      'lesson_q_${src}_${tgt}_u${unit}_l$lesson';

  /// Fetches questions for a specific language pair + unit + lesson,
  /// ordered by questionNumber. Uses local cache when available.
  Future<List<LessonQuestionModel>> getQuestions({
    required String langSource,
    required String langTarget,
    required int unit,
    required int lesson,
  }) async {
    final key = _cacheKey(langSource, langTarget, unit, lesson);

    // Check cache first
    final cached = cacheService.getList(key);
    if (cached != null) {
      return cached
          .map((json) => LessonQuestionModel.fromJson(json))
          .toList();
    }

    // Fetch from Firestore
    final snap = await _col
        .where('languageSource', isEqualTo: langSource)
        .where('languageTarget', isEqualTo: langTarget)
        .where('unit', isEqualTo: unit)
        .where('lesson', isEqualTo: lesson)
        .orderBy('questionNumber')
        .get();

    final models = snap.docs
        .map((doc) => LessonQuestionModel.fromFirestore(doc))
        .toList();

    // Cache results
    if (models.isNotEmpty) {
      await cacheService.cacheList(
        key,
        models.map((m) => m.toJson()).toList(),
        ttl: _cacheTTL,
      );
    }

    return models;
  }

  /// Invalidate cached questions for a specific lesson.
  Future<void> invalidateCache({
    required String langSource,
    required String langTarget,
    required int unit,
    required int lesson,
  }) async {
    await cacheService.remove(_cacheKey(langSource, langTarget, unit, lesson));
  }
}
