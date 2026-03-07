import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/game_word_model.dart';
import '../models/translation_race_question_model.dart';
import 'game_word_datasource.dart';

/// Firestore implementation of the game word datasource.
class GameWordDatasourceImpl implements GameWordDatasource {
  final FirebaseFirestore _firestore;
  final _random = Random();

  GameWordDatasourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ── Generic Word Queries ──

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

    final snapshot = await query.limit(limit).get().timeout(const Duration(seconds: 10));
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

    final snapshot = await query.limit(1).get().timeout(const Duration(seconds: 10));
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

    final snapshot = await query.limit(limit).get().timeout(const Duration(seconds: 10));
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

  // ── Word Bomb ──

  @override
  Future<String> getWordBombPrompt(String language) async {
    try {
      // Get random words from the database and extract a 2-3 char substring
      final snapshot = await _firestore
          .collection('game_words')
          .where('language', isEqualTo: language)
          .limit(50)
          .get()
          .timeout(const Duration(seconds: 10));

      if (snapshot.docs.isEmpty) {
        return _fallbackPrompt(language);
      }

      // Pick a random word and extract a 2-3 letter prompt from it
      final words = snapshot.docs
          .map((doc) => (doc.data()['word'] as String?) ?? '')
          .where((w) => w.length >= 3)
          .toList();

      if (words.isEmpty) return _fallbackPrompt(language);

      final word = words[_random.nextInt(words.length)];
      final promptLength = _random.nextBool() ? 2 : 3;
      final maxStart = word.length - promptLength;
      if (maxStart <= 0) return word.substring(0, 2).toUpperCase();

      final start = _random.nextInt(maxStart);
      return word.substring(start, start + promptLength).toUpperCase();
    } catch (e) {
      debugPrint('GameWordDatasource: getWordBombPrompt error: $e');
      return _fallbackPrompt(language);
    }
  }

  String _fallbackPrompt(String language) {
    // Japanese uses hiragana-based prompts
    if (language == 'ja') {
      const jaPrompts = [
        'かい', 'たい', 'しん', 'こう', 'せい',
        'けん', 'とう', 'しょ', 'きょ', 'ちょ',
      ];
      return jaPrompts[_random.nextInt(jaPrompts.length)];
    }

    // Latin-script languages share common letter pairs
    const prompts = [
      'TH', 'ST', 'RE', 'IN', 'AN', 'ER', 'OU', 'AL', 'EN', 'AT',
      'ON', 'AR', 'OR', 'IT', 'ES', 'LE', 'SE', 'DE', 'LI', 'RI',
    ];
    return prompts[_random.nextInt(prompts.length)];
  }

  @override
  Future<bool> isValidWordBombWord(
      String word, String prompt, String language) async {
    final normalizedWord = word.toLowerCase().trim();
    final normalizedPrompt = prompt.toLowerCase().trim();

    // Must contain the prompt
    if (!normalizedWord.contains(normalizedPrompt)) return false;

    // Check if word exists in database
    final snapshot = await _firestore
        .collection('game_words')
        .where('language', isEqualTo: language)
        .where('word', isEqualTo: normalizedWord)
        .limit(1)
        .get()
        .timeout(const Duration(seconds: 10));

    return snapshot.docs.isNotEmpty;
  }

  // ── Translation ──

  @override
  Future<MapEntry<String, String>?> getRandomTranslationPair(
      String language) async {
    try {
      // Get words that have translations for this language
      final snapshot = await _firestore
          .collection('game_words')
          .where('language', isEqualTo: 'en')
          .limit(50)
          .get()
          .timeout(const Duration(seconds: 10));

      if (snapshot.docs.isEmpty) return null;

      // Find one that has a translation in the target language
      final docs = snapshot.docs..shuffle();
      for (final doc in docs) {
        final data = doc.data();
        final word = data['word'] as String? ?? '';
        final translations =
            data['translations'] as Map<String, dynamic>? ?? {};
        final langTranslations = translations[language];
        if (langTranslations is List && langTranslations.isNotEmpty) {
          return MapEntry(word, langTranslations.first as String);
        }
      }
      return null;
    } catch (e) {
      debugPrint('GameWordDatasource: getRandomTranslationPair error: $e');
      return null;
    }
  }

  @override
  Future<bool> checkTranslation(String answer, String correctAnswer) async {
    final a = answer.toLowerCase().trim();
    final b = correctAnswer.toLowerCase().trim();
    if (a == b) return true;
    // Close match: allow minor differences (1 char for short words, 2 for longer)
    if (a.isEmpty || b.isEmpty) return false;
    final distance = _levenshtein(a, b);
    final threshold = b.length <= 4 ? 1 : 2;
    return distance <= threshold;
  }

  int _levenshtein(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    final matrix = List.generate(
      a.length + 1,
      (_) => List.filled(b.length + 1, 0),
    );
    for (int i = 0; i <= a.length; i++) matrix[i][0] = i;
    for (int j = 0; j <= b.length; j++) matrix[0][j] = j;
    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    return matrix[a.length][b.length];
  }

  // ── Grammar ──

  @override
  Future<GrammarQuestionModel?> getRandomGrammarQuestion(
      String language) async {
    try {
      final snapshot = await _firestore
          .collection('game_grammar_questions')
          .where('language', isEqualTo: language)
          .limit(30)
          .get()
          .timeout(const Duration(seconds: 10));

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs[_random.nextInt(snapshot.docs.length)];
      final data = doc.data();

      return GrammarQuestionModel(
        id: doc.id,
        question: data['question'] as String? ?? '',
        options: List<String>.from(data['options'] as List? ?? []),
        correctIndex: data['correctIndex'] as int? ?? 0,
        language: data['language'] as String? ?? language,
        category: data['category'] as String? ?? '',
        difficulty: data['difficulty'] as int? ?? 1,
      );
    } catch (e) {
      debugPrint('GameWordDatasource: getRandomGrammarQuestion error: $e');
      return null;
    }
  }

  // ── Vocabulary Chain ──

  @override
  Future<String> getRandomTheme(String language) async {
    const themes = [
      'animals', 'food_drinks', 'household', 'body_health', 'nature',
      'travel', 'work_education', 'technology', 'emotions', 'sports_hobbies',
      'clothing', 'colors_shapes', 'family', 'social',
    ];
    // Pick a random theme that has words in the database
    final shuffled = List<String>.from(themes)..shuffle();
    for (final theme in shuffled) {
      final snapshot = await _firestore
          .collection('game_words')
          .where('language', isEqualTo: language)
          .where('category', isEqualTo: theme)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 10));
      if (snapshot.docs.isNotEmpty) return theme;
    }
    return themes[_random.nextInt(themes.length)];
  }

  @override
  Future<bool> isValidChainWord(
    String word,
    String lastLetter,
    String language,
    String theme,
    List<String> usedWords,
  ) async {
    final normalizedWord = word.toLowerCase().trim();

    // Check not already used
    if (usedWords.map((w) => w.toLowerCase()).contains(normalizedWord)) {
      return false;
    }

    // Check starts with the correct letter (if there is one)
    if (lastLetter.isNotEmpty &&
        !normalizedWord.startsWith(lastLetter.toLowerCase())) {
      return false;
    }

    // Check word exists in database for this language
    final snapshot = await _firestore
        .collection('game_words')
        .where('language', isEqualTo: language)
        .where('word', isEqualTo: normalizedWord)
        .limit(1)
        .get()
        .timeout(const Duration(seconds: 10));

    return snapshot.docs.isNotEmpty;
  }

  // ── Tapples ──

  @override
  Future<String> getTapplesCategory(String language) async {
    const categories = [
      'Animals', 'Food & Drinks', 'Countries', 'Sports', 'Professions',
      'Clothing', 'Colors', 'Fruits', 'Vegetables', 'Musical Instruments',
      'Body Parts', 'Kitchen Items', 'School Subjects', 'Weather',
    ];
    return categories[_random.nextInt(categories.length)];
  }

  @override
  Future<bool> isValidTapplesWord(
    String word,
    String language,
    String category,
    String letter,
  ) async {
    final normalizedWord = word.toLowerCase().trim();

    // Must start with the given letter
    if (normalizedWord.isEmpty ||
        normalizedWord[0] != letter.toLowerCase()) {
      return false;
    }

    // Check word exists in database for this language
    final snapshot = await _firestore
        .collection('game_words')
        .where('language', isEqualTo: language)
        .where('word', isEqualTo: normalizedWord)
        .limit(1)
        .get()
        .timeout(const Duration(seconds: 10));

    return snapshot.docs.isNotEmpty;
  }
}
