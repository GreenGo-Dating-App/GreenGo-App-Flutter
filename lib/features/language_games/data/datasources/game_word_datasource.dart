import '../models/game_word_model.dart';
import '../models/translation_race_question_model.dart';

/// Model for grammar questions from Firestore.
class GrammarQuestionModel {
  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String language;
  final String category;
  final int difficulty;

  const GrammarQuestionModel({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.language,
    required this.category,
    required this.difficulty,
  });
}

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

  // ── Word Bomb ──

  /// Get a random 1-2 character prompt from words in the database.
  Future<String> getWordBombPrompt(String language);

  /// Check if a word is valid for Word Bomb (exists and contains the prompt).
  Future<bool> isValidWordBombWord(String word, String prompt, String language);

  // ── Translation ──

  /// Get a random translation pair (sourceWord -> targetWord).
  Future<MapEntry<String, String>?> getRandomTranslationPair(String language);

  /// Check if a translation is correct (exact or close match).
  Future<bool> checkTranslation(String answer, String correctAnswer);

  // ── Grammar ──

  /// Get a random grammar question for a language.
  Future<GrammarQuestionModel?> getRandomGrammarQuestion(String language);

  // ── Vocabulary Chain ──

  /// Get a random vocabulary category/theme name.
  Future<String> getRandomTheme(String language);

  /// Validate a word for vocabulary chain (correct language, category, starts with letter, not used).
  Future<bool> isValidChainWord(
    String word,
    String lastLetter,
    String language,
    String theme,
    List<String> usedWords,
  );

  // ── Tapples ──

  /// Get a random tapples category for a language.
  Future<String> getTapplesCategory(String language);

  /// Validate a tapples word (correct category, starts with letter).
  Future<bool> isValidTapplesWord(
    String word,
    String language,
    String category,
    String letter,
  );
}
