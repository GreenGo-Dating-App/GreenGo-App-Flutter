import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game_word_model.dart';
import '../models/translation_race_question_model.dart';
import 'game_word_datasource.dart';

/// Firestore implementation of the game word datasource.
class GameWordDatasourceImpl implements GameWordDatasource {
  final FirebaseFirestore _firestore;

  GameWordDatasourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<GameWordModel>> getWords({
    required String language,
    String? category,
    int? minDifficulty,
    int? maxDifficulty,
    int limit = 20,
  }) async {
    Query query = _firestore
        .collection('game_words')
        .where('language', isEqualTo: language);

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }
    if (minDifficulty != null) {
      query = query.where('difficulty', isGreaterThanOrEqualTo: minDifficulty);
    }
    if (maxDifficulty != null) {
      query = query.where('difficulty', isLessThanOrEqualTo: maxDifficulty);
    }

    final snapshot = await query.limit(limit).get();
    return snapshot.docs.map((doc) => GameWordModel.fromFirestore(doc)).toList();
  }

  @override
  Future<bool> validateWord({
    required String word,
    required String language,
    String? category,
  }) async {
    Query query = _firestore
        .collection('game_words')
        .where('language', isEqualTo: language)
        .where('word', isEqualTo: word.toLowerCase());

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    final snapshot = await query.limit(1).get();
    return snapshot.docs.isNotEmpty;
  }

  @override
  Future<List<TranslationRaceQuestionModel>> getTranslationRaceQuestions({
    required String sourceLang,
    required String targetLang,
    int? minDifficulty,
    int? maxDifficulty,
    int limit = 35,
  }) async {
    Query query = _firestore
        .collection('game_translation_race')
        .where('sourceLang', isEqualTo: sourceLang)
        .where('targetLang', isEqualTo: targetLang);

    if (minDifficulty != null) {
      query = query.where('difficulty', isGreaterThanOrEqualTo: minDifficulty);
    }
    if (maxDifficulty != null) {
      query = query.where('difficulty', isLessThanOrEqualTo: maxDifficulty);
    }

    final snapshot = await query.limit(limit).get();
    return snapshot.docs
        .map((doc) => TranslationRaceQuestionModel.fromFirestore(doc))
        .toList();
  }

  @override
  Future<void> reportWord({
    required String word,
    required String reportedBy,
    required String roomId,
    required String reason,
  }) async {
    await _firestore.collection('game_reported_words').add({
      'word': word,
      'reportedBy': reportedBy,
      'roomId': roomId,
      'reason': reason,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
