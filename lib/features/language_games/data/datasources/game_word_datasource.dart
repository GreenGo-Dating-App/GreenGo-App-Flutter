import '../models/game_word_model.dart';
import '../models/translation_race_question_model.dart';

/// Interface for accessing the game word database.
abstract class GameWordDatasource {
  /// Get random words for a given language/category/difficulty.
  Future<List<GameWordModel>> getWords({
    required String language,
    String? category,
    int? minDifficulty,
    int? maxDifficulty,
    int limit = 20,
  });

  /// Validate whether a word exists in the database.
  Future<bool> validateWord({
    required String word,
    required String language,
    String? category,
  });

  /// Get pre-built Translation Race questions.
  Future<List<TranslationRaceQuestionModel>> getTranslationRaceQuestions({
    required String sourceLang,
    required String targetLang,
    int? minDifficulty,
    int? maxDifficulty,
    int limit = 35,
  });

  /// Report a word as incorrect or inappropriate.
  Future<void> reportWord({
    required String word,
    required String reportedBy,
    required String roomId,
    required String reason,
  });
}
