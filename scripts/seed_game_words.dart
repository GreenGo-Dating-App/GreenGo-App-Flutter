/// Seed script for game word database.
///
/// Run from project root:
///   dart run scripts/seed_game_words.dart
///
/// This script:
/// 1. Uploads words to `game_words` collection
/// 2. Generates `game_translation_race` pre-built questions
/// 3. Expands `game_grammar_questions` from existing content
///
/// Target: 10,000 words per language x 7 languages = 70,000 docs
/// Uses Firestore batch writes (max 500 per batch).
/// Idempotent: checks counts before inserting.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIGURATION
// ─────────────────────────────────────────────────────────────────────────────

const kLanguages = ['EN', 'IT', 'ES', 'FR', 'DE', 'PT', 'JA'];

/// Category structure with target word counts and difficulty ranges.
const kCategories = <String, Map<String, dynamic>>{
  'animals': {'count': 800, 'minDiff': 1, 'maxDiff': 8},
  'food_drinks': {'count': 1000, 'minDiff': 1, 'maxDiff': 8},
  'household': {'count': 700, 'minDiff': 2, 'maxDiff': 7},
  'body_health': {'count': 600, 'minDiff': 2, 'maxDiff': 8},
  'nature': {'count': 700, 'minDiff': 1, 'maxDiff': 8},
  'travel': {'count': 800, 'minDiff': 2, 'maxDiff': 8},
  'work_education': {'count': 800, 'minDiff': 3, 'maxDiff': 9},
  'technology': {'count': 600, 'minDiff': 3, 'maxDiff': 9},
  'emotions': {'count': 500, 'minDiff': 2, 'maxDiff': 8},
  'sports_hobbies': {'count': 600, 'minDiff': 2, 'maxDiff': 7},
  'clothing': {'count': 400, 'minDiff': 1, 'maxDiff': 6},
  'colors_shapes': {'count': 300, 'minDiff': 1, 'maxDiff': 4},
  'time_calendar': {'count': 400, 'minDiff': 1, 'maxDiff': 5},
  'family': {'count': 400, 'minDiff': 1, 'maxDiff': 5},
  'social': {'count': 500, 'minDiff': 2, 'maxDiff': 7},
  'verbs_common': {'count': 1000, 'minDiff': 1, 'maxDiff': 10},
  'adjectives': {'count': 800, 'minDiff': 2, 'maxDiff': 9},
};

// ─────────────────────────────────────────────────────────────────────────────
// STARTER WORD DATA (subset — full data comes from CSV files in word_data/)
// ─────────────────────────────────────────────────────────────────────────────

/// Starter vocabulary organized by category.
/// Each entry: word key -> { lang: translation, ... }
/// This is the programmatic seed; the full 10K/language comes from CSV imports.
const kStarterWords = <String, List<Map<String, dynamic>>>{
  'animals': [
    {'word': {'EN': 'dog', 'IT': 'cane', 'ES': 'perro', 'FR': 'chien', 'DE': 'Hund', 'PT': 'cão', 'JA': '犬'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'cat', 'IT': 'gatto', 'ES': 'gato', 'FR': 'chat', 'DE': 'Katze', 'PT': 'gato', 'JA': '猫'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'bird', 'IT': 'uccello', 'ES': 'pájaro', 'FR': 'oiseau', 'DE': 'Vogel', 'PT': 'pássaro', 'JA': '鳥'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'fish', 'IT': 'pesce', 'ES': 'pez', 'FR': 'poisson', 'DE': 'Fisch', 'PT': 'peixe', 'JA': '魚'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'horse', 'IT': 'cavallo', 'ES': 'caballo', 'FR': 'cheval', 'DE': 'Pferd', 'PT': 'cavalo', 'JA': '馬'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'cow', 'IT': 'mucca', 'ES': 'vaca', 'FR': 'vache', 'DE': 'Kuh', 'PT': 'vaca', 'JA': '牛'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'pig', 'IT': 'maiale', 'ES': 'cerdo', 'FR': 'cochon', 'DE': 'Schwein', 'PT': 'porco', 'JA': '豚'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'rabbit', 'IT': 'coniglio', 'ES': 'conejo', 'FR': 'lapin', 'DE': 'Kaninchen', 'PT': 'coelho', 'JA': 'うさぎ'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'bear', 'IT': 'orso', 'ES': 'oso', 'FR': 'ours', 'DE': 'Bär', 'PT': 'urso', 'JA': '熊'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'lion', 'IT': 'leone', 'ES': 'león', 'FR': 'lion', 'DE': 'Löwe', 'PT': 'leão', 'JA': 'ライオン'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'elephant', 'IT': 'elefante', 'ES': 'elefante', 'FR': 'éléphant', 'DE': 'Elefant', 'PT': 'elefante', 'JA': '象'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'monkey', 'IT': 'scimmia', 'ES': 'mono', 'FR': 'singe', 'DE': 'Affe', 'PT': 'macaco', 'JA': '猿'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'butterfly', 'IT': 'farfalla', 'ES': 'mariposa', 'FR': 'papillon', 'DE': 'Schmetterling', 'PT': 'borboleta', 'JA': '蝶'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'snake', 'IT': 'serpente', 'ES': 'serpiente', 'FR': 'serpent', 'DE': 'Schlange', 'PT': 'cobra', 'JA': '蛇'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'turtle', 'IT': 'tartaruga', 'ES': 'tortuga', 'FR': 'tortue', 'DE': 'Schildkröte', 'PT': 'tartaruga', 'JA': '亀'}, 'difficulty': 3, 'pos': 'noun'},
  ],
  'food_drinks': [
    {'word': {'EN': 'water', 'IT': 'acqua', 'ES': 'agua', 'FR': 'eau', 'DE': 'Wasser', 'PT': 'água', 'JA': '水'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'bread', 'IT': 'pane', 'ES': 'pan', 'FR': 'pain', 'DE': 'Brot', 'PT': 'pão', 'JA': 'パン'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'milk', 'IT': 'latte', 'ES': 'leche', 'FR': 'lait', 'DE': 'Milch', 'PT': 'leite', 'JA': '牛乳'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'rice', 'IT': 'riso', 'ES': 'arroz', 'FR': 'riz', 'DE': 'Reis', 'PT': 'arroz', 'JA': '米'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'apple', 'IT': 'mela', 'ES': 'manzana', 'FR': 'pomme', 'DE': 'Apfel', 'PT': 'maçã', 'JA': 'りんご'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'coffee', 'IT': 'caffè', 'ES': 'café', 'FR': 'café', 'DE': 'Kaffee', 'PT': 'café', 'JA': 'コーヒー'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'cheese', 'IT': 'formaggio', 'ES': 'queso', 'FR': 'fromage', 'DE': 'Käse', 'PT': 'queijo', 'JA': 'チーズ'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'chicken', 'IT': 'pollo', 'ES': 'pollo', 'FR': 'poulet', 'DE': 'Huhn', 'PT': 'frango', 'JA': '鶏肉'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'egg', 'IT': 'uovo', 'ES': 'huevo', 'FR': 'œuf', 'DE': 'Ei', 'PT': 'ovo', 'JA': '卵'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'sugar', 'IT': 'zucchero', 'ES': 'azúcar', 'FR': 'sucre', 'DE': 'Zucker', 'PT': 'açúcar', 'JA': '砂糖'}, 'difficulty': 2, 'pos': 'noun'},
  ],
  'colors_shapes': [
    {'word': {'EN': 'red', 'IT': 'rosso', 'ES': 'rojo', 'FR': 'rouge', 'DE': 'rot', 'PT': 'vermelho', 'JA': '赤'}, 'difficulty': 1, 'pos': 'adjective'},
    {'word': {'EN': 'blue', 'IT': 'blu', 'ES': 'azul', 'FR': 'bleu', 'DE': 'blau', 'PT': 'azul', 'JA': '青'}, 'difficulty': 1, 'pos': 'adjective'},
    {'word': {'EN': 'green', 'IT': 'verde', 'ES': 'verde', 'FR': 'vert', 'DE': 'grün', 'PT': 'verde', 'JA': '緑'}, 'difficulty': 1, 'pos': 'adjective'},
    {'word': {'EN': 'yellow', 'IT': 'giallo', 'ES': 'amarillo', 'FR': 'jaune', 'DE': 'gelb', 'PT': 'amarelo', 'JA': '黄色'}, 'difficulty': 1, 'pos': 'adjective'},
    {'word': {'EN': 'black', 'IT': 'nero', 'ES': 'negro', 'FR': 'noir', 'DE': 'schwarz', 'PT': 'preto', 'JA': '黒'}, 'difficulty': 1, 'pos': 'adjective'},
    {'word': {'EN': 'white', 'IT': 'bianco', 'ES': 'blanco', 'FR': 'blanc', 'DE': 'weiß', 'PT': 'branco', 'JA': '白'}, 'difficulty': 1, 'pos': 'adjective'},
    {'word': {'EN': 'circle', 'IT': 'cerchio', 'ES': 'círculo', 'FR': 'cercle', 'DE': 'Kreis', 'PT': 'círculo', 'JA': '丸'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'square', 'IT': 'quadrato', 'ES': 'cuadrado', 'FR': 'carré', 'DE': 'Quadrat', 'PT': 'quadrado', 'JA': '四角'}, 'difficulty': 2, 'pos': 'noun'},
  ],
  'family': [
    {'word': {'EN': 'mother', 'IT': 'madre', 'ES': 'madre', 'FR': 'mère', 'DE': 'Mutter', 'PT': 'mãe', 'JA': '母'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'father', 'IT': 'padre', 'ES': 'padre', 'FR': 'père', 'DE': 'Vater', 'PT': 'pai', 'JA': '父'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'brother', 'IT': 'fratello', 'ES': 'hermano', 'FR': 'frère', 'DE': 'Bruder', 'PT': 'irmão', 'JA': '兄弟'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'sister', 'IT': 'sorella', 'ES': 'hermana', 'FR': 'sœur', 'DE': 'Schwester', 'PT': 'irmã', 'JA': '姉妹'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'son', 'IT': 'figlio', 'ES': 'hijo', 'FR': 'fils', 'DE': 'Sohn', 'PT': 'filho', 'JA': '息子'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'daughter', 'IT': 'figlia', 'ES': 'hija', 'FR': 'fille', 'DE': 'Tochter', 'PT': 'filha', 'JA': '娘'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'grandmother', 'IT': 'nonna', 'ES': 'abuela', 'FR': 'grand-mère', 'DE': 'Großmutter', 'PT': 'avó', 'JA': '祖母'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'grandfather', 'IT': 'nonno', 'ES': 'abuelo', 'FR': 'grand-père', 'DE': 'Großvater', 'PT': 'avô', 'JA': '祖父'}, 'difficulty': 2, 'pos': 'noun'},
  ],
};

// ─────────────────────────────────────────────────────────────────────────────
// MAIN
// ─────────────────────────────────────────────────────────────────────────────

Future<void> main() async {
  await Firebase.initializeApp();
  final firestore = FirebaseFirestore.instance;

  print('=== SEEDING GAME WORDS ===\n');

  int totalWords = 0;
  int totalQuestions = 0;

  for (final language in kLanguages) {
    print('Processing language: $language');

    // Check existing count
    final existingCount = await firestore
        .collection('game_words')
        .where('language', isEqualTo: language)
        .count()
        .get();
    final existing = existingCount.count ?? 0;
    print('  Existing words: $existing');

    if (existing > 100) {
      print('  Sufficient data exists, skipping word seed.');
      continue;
    }

    WriteBatch batch = firestore.batch();
    int batchCount = 0;
    int langWordCount = 0;

    for (final entry in kStarterWords.entries) {
      final category = entry.key;
      final words = entry.value;

      for (final wordData in words) {
        final translations = wordData['word'] as Map<String, dynamic>;
        final word = (translations[language] as String?) ?? '';
        if (word.isEmpty) continue;

        // Build translation map (all other languages)
        final translationMap = <String, List<String>>{};
        for (final otherLang in kLanguages) {
          if (otherLang == language) continue;
          final trans = translations[otherLang] as String?;
          if (trans != null) {
            translationMap[otherLang] = [trans];
          }
        }

        final docRef = firestore.collection('game_words').doc();
        batch.set(docRef, {
          'word': word.toLowerCase(),
          'language': language,
          'category': category,
          'difficulty': wordData['difficulty'],
          'translations': translationMap,
          'partOfSpeech': wordData['pos'],
          'createdAt': FieldValue.serverTimestamp(),
        });

        batchCount++;
        langWordCount++;
        totalWords++;

        if (batchCount >= 490) {
          await batch.commit();
          batch = firestore.batch();
          batchCount = 0;
        }
      }
    }

    if (batchCount > 0) {
      await batch.commit();
    }

    print('  Seeded $langWordCount words for $language');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GENERATE TRANSLATION RACE QUESTIONS
  // ─────────────────────────────────────────────────────────────────────────

  print('\n=== GENERATING TRANSLATION RACE QUESTIONS ===\n');

  for (final source in kLanguages) {
    for (final target in kLanguages) {
      if (source == target) continue;

      final pairId = '${source.toLowerCase()}_${target.toLowerCase()}';

      // Check existing
      final existingQ = await firestore
          .collection('game_translation_race')
          .where('sourceLang', isEqualTo: source)
          .where('targetLang', isEqualTo: target)
          .count()
          .get();

      if ((existingQ.count ?? 0) > 10) {
        continue;
      }

      print('Generating TR questions: $source -> $target');

      WriteBatch batch = firestore.batch();
      int batchCount = 0;
      int questionCount = 0;

      // For each word in our starter data, create a TR question
      for (final entry in kStarterWords.entries) {
        final words = entry.value;
        final allTargetWords = words
            .map((w) => (w['word'] as Map<String, dynamic>)[target] as String?)
            .where((w) => w != null && w.isNotEmpty)
            .cast<String>()
            .toList();

        for (final wordData in words) {
          final translations = wordData['word'] as Map<String, dynamic>;
          final sourceWord = translations[source] as String?;
          final correctAnswer = translations[target] as String?;
          if (sourceWord == null || correctAnswer == null) continue;

          // Pick 11 wrong options from same category
          final wrongOptions = allTargetWords
              .where((w) => w != correctAnswer)
              .take(11)
              .toList();

          // Pad with words from other categories if needed
          if (wrongOptions.length < 11) {
            for (final otherEntry in kStarterWords.entries) {
              if (wrongOptions.length >= 11) break;
              for (final w in otherEntry.value) {
                if (wrongOptions.length >= 11) break;
                final t = (w['word'] as Map<String, dynamic>)[target] as String?;
                if (t != null && t != correctAnswer && !wrongOptions.contains(t)) {
                  wrongOptions.add(t);
                }
              }
            }
          }

          final docRef = firestore.collection('game_translation_race').doc();
          batch.set(docRef, {
            'word': sourceWord,
            'sourceLang': source,
            'targetLang': target,
            'correctAnswer': correctAnswer,
            'wrongOptions': wrongOptions,
            'difficulty': wordData['difficulty'],
            'category': entry.key,
            'createdAt': FieldValue.serverTimestamp(),
          });

          batchCount++;
          questionCount++;
          totalQuestions++;

          if (batchCount >= 490) {
            await batch.commit();
            batch = firestore.batch();
            batchCount = 0;
          }
        }
      }

      if (batchCount > 0) {
        await batch.commit();
      }

      print('  Generated $questionCount questions');
    }
  }

  print('\n=== SEED COMPLETE ===');
  print('Total words seeded: $totalWords');
  print('Total TR questions: $totalQuestions');
  print('\nNote: For full 10K words/language, import CSV data from scripts/word_data/');
}
