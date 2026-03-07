/// Seed script for Unit 1 (Greetings & Introductions) across all 42 language pairs.
///
/// Run from project root:
///   dart run scripts/seed_unit1_lessons.dart
///
/// This script generates:
/// - ~1,890 lesson question documents (42 pairs x ~45 questions)
/// - 294 constellation node documents (42 pairs x 7 nodes)
///
/// Uses Firestore batch writes (max 500 per batch).
/// Idempotent: skips if data already exists for a language pair.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIGURATION
// ─────────────────────────────────────────────────────────────────────────────

const kLanguages = ['EN', 'IT', 'ES', 'FR', 'DE', 'PT', 'JA'];

const kUnit1Id = 'unit_01_greetings';
const kUnit1Title = 'Greetings & Introductions';

/// Lesson structure: 5 lessons per language pair.
const kLessons = [
  {'id': 'lesson_01', 'title': 'Hello & Goodbye', 'index': 1},
  {'id': 'lesson_02', 'title': 'My Name Is...', 'index': 2},
  {'id': 'lesson_03', 'title': 'How Are You?', 'index': 3},
  {'id': 'lesson_04', 'title': 'Where Are You From?', 'index': 4},
  {'id': 'lesson_05', 'title': 'Nice to Meet You', 'index': 5},
];

/// Core vocabulary for Unit 1 per language.
const kVocabulary = <String, Map<String, String>>{
  'hello': {
    'EN': 'Hello', 'IT': 'Ciao', 'ES': 'Hola', 'FR': 'Bonjour',
    'DE': 'Hallo', 'PT': 'Olá', 'JA': 'こんにちは',
  },
  'goodbye': {
    'EN': 'Goodbye', 'IT': 'Arrivederci', 'ES': 'Adiós', 'FR': 'Au revoir',
    'DE': 'Auf Wiedersehen', 'PT': 'Adeus', 'JA': 'さようなら',
  },
  'good_morning': {
    'EN': 'Good morning', 'IT': 'Buongiorno', 'ES': 'Buenos días', 'FR': 'Bonjour',
    'DE': 'Guten Morgen', 'PT': 'Bom dia', 'JA': 'おはようございます',
  },
  'good_evening': {
    'EN': 'Good evening', 'IT': 'Buonasera', 'ES': 'Buenas tardes', 'FR': 'Bonsoir',
    'DE': 'Guten Abend', 'PT': 'Boa noite', 'JA': 'こんばんは',
  },
  'good_night': {
    'EN': 'Good night', 'IT': 'Buonanotte', 'ES': 'Buenas noches', 'FR': 'Bonne nuit',
    'DE': 'Gute Nacht', 'PT': 'Boa noite', 'JA': 'おやすみなさい',
  },
  'my_name_is': {
    'EN': 'My name is', 'IT': 'Mi chiamo', 'ES': 'Me llamo', 'FR': 'Je m\'appelle',
    'DE': 'Ich heiße', 'PT': 'Meu nome é', 'JA': '私の名前は',
  },
  'what_is_your_name': {
    'EN': 'What is your name?', 'IT': 'Come ti chiami?', 'ES': '¿Cómo te llamas?',
    'FR': 'Comment tu t\'appelles?', 'DE': 'Wie heißt du?',
    'PT': 'Qual é o seu nome?', 'JA': 'お名前は何ですか？',
  },
  'how_are_you': {
    'EN': 'How are you?', 'IT': 'Come stai?', 'ES': '¿Cómo estás?',
    'FR': 'Comment vas-tu?', 'DE': 'Wie geht es dir?',
    'PT': 'Como você está?', 'JA': 'お元気ですか？',
  },
  'i_am_fine': {
    'EN': 'I am fine', 'IT': 'Sto bene', 'ES': 'Estoy bien', 'FR': 'Je vais bien',
    'DE': 'Mir geht es gut', 'PT': 'Estou bem', 'JA': '元気です',
  },
  'thank_you': {
    'EN': 'Thank you', 'IT': 'Grazie', 'ES': 'Gracias', 'FR': 'Merci',
    'DE': 'Danke', 'PT': 'Obrigado', 'JA': 'ありがとう',
  },
  'please': {
    'EN': 'Please', 'IT': 'Per favore', 'ES': 'Por favor', 'FR': 'S\'il vous plaît',
    'DE': 'Bitte', 'PT': 'Por favor', 'JA': 'お願いします',
  },
  'yes': {
    'EN': 'Yes', 'IT': 'Sì', 'ES': 'Sí', 'FR': 'Oui',
    'DE': 'Ja', 'PT': 'Sim', 'JA': 'はい',
  },
  'no': {
    'EN': 'No', 'IT': 'No', 'ES': 'No', 'FR': 'Non',
    'DE': 'Nein', 'PT': 'Não', 'JA': 'いいえ',
  },
  'excuse_me': {
    'EN': 'Excuse me', 'IT': 'Scusi', 'ES': 'Disculpe', 'FR': 'Excusez-moi',
    'DE': 'Entschuldigung', 'PT': 'Com licença', 'JA': 'すみません',
  },
  'sorry': {
    'EN': 'Sorry', 'IT': 'Mi dispiace', 'ES': 'Lo siento', 'FR': 'Désolé',
    'DE': 'Es tut mir leid', 'PT': 'Desculpe', 'JA': 'ごめんなさい',
  },
  'where_are_you_from': {
    'EN': 'Where are you from?', 'IT': 'Di dove sei?', 'ES': '¿De dónde eres?',
    'FR': 'D\'où viens-tu?', 'DE': 'Woher kommst du?',
    'PT': 'De onde você é?', 'JA': 'どこの出身ですか？',
  },
  'i_am_from': {
    'EN': 'I am from', 'IT': 'Sono di', 'ES': 'Soy de', 'FR': 'Je suis de',
    'DE': 'Ich komme aus', 'PT': 'Eu sou de', 'JA': '出身は',
  },
  'nice_to_meet_you': {
    'EN': 'Nice to meet you', 'IT': 'Piacere di conoscerti', 'ES': 'Mucho gusto',
    'FR': 'Enchanté', 'DE': 'Freut mich',
    'PT': 'Prazer em conhecê-lo', 'JA': 'はじめまして',
  },
  'see_you_later': {
    'EN': 'See you later', 'IT': 'A dopo', 'ES': 'Hasta luego', 'FR': 'À plus tard',
    'DE': 'Bis später', 'PT': 'Até logo', 'JA': 'また後で',
  },
  'welcome': {
    'EN': 'Welcome', 'IT': 'Benvenuto', 'ES': 'Bienvenido', 'FR': 'Bienvenue',
    'DE': 'Willkommen', 'PT': 'Bem-vindo', 'JA': 'ようこそ',
  },
};

// ─────────────────────────────────────────────────────────────────────────────
// QUESTION GENERATORS
// ─────────────────────────────────────────────────────────────────────────────

/// Generate questions for a single lesson in a language pair.
///
/// Uses the app's field format:
///   - questionType: multiple_choice, fill_in_blank, translation, true_false, matching
///   - question: the prompt text
///   - answers: pipe-separated options (for multiple_choice/true_false) or
///              "Left:Right|Left:Right" for matching
///   - rightAnswer: the correct answer string
List<Map<String, dynamic>> generateLessonQuestions({
  required String source,
  required String target,
  required int lessonIndex,
}) {
  final vocabKeys = kVocabulary.keys.toList();
  // Each lesson uses a slice of vocabulary
  final startIdx = ((lessonIndex - 1) * 4) % vocabKeys.length;
  final lessonVocab = <String>[];
  for (int i = 0; i < 8; i++) {
    lessonVocab.add(vocabKeys[(startIdx + i) % vocabKeys.length]);
  }

  final questions = <Map<String, dynamic>>[];
  int qIdx = 0;

  // 3 multiple_choice
  for (int i = 0; i < 3 && i < lessonVocab.length; i++) {
    final key = lessonVocab[i];
    final word = kVocabulary[key]![source]!;
    final correct = kVocabulary[key]![target]!;
    final wrongKeys = vocabKeys.where((k) => k != key).take(3).toList();
    final options = [
      correct,
      ...wrongKeys.map((k) => kVocabulary[k]![target]!),
    ]..shuffle();

    questions.add({
      'questionIndex': qIdx++,
      'questionType': 'multiple_choice',
      'question': 'What is "$word" in ${_langName(target)}?',
      'answers': options.join('|'),
      'rightAnswer': correct,
    });
  }

  // 2 fill_in_blank
  for (int i = 3; i < 5 && i < lessonVocab.length; i++) {
    final key = lessonVocab[i];
    final word = kVocabulary[key]![source]!;
    final correct = kVocabulary[key]![target]!;

    questions.add({
      'questionIndex': qIdx++,
      'questionType': 'fill_in_blank',
      'question': 'Translate "$word" to ${_langName(target)}:',
      'answers': '',
      'rightAnswer': correct,
    });
  }

  // 2 translation
  for (int i = 5; i < 7 && i < lessonVocab.length; i++) {
    final key = lessonVocab[i];
    final word = kVocabulary[key]![target]!;
    final correct = kVocabulary[key]![source]!;

    questions.add({
      'questionIndex': qIdx++,
      'questionType': 'translation',
      'question': 'What does "$word" mean in ${_langName(source)}?',
      'answers': '',
      'rightAnswer': correct,
    });
  }

  // 1 true_false
  if (lessonVocab.length >= 2) {
    final key1 = lessonVocab[0];
    final key2 = lessonVocab[1];
    final word = kVocabulary[key1]![source]!;
    final wrongTranslation = kVocabulary[key2]![target]!;

    questions.add({
      'questionIndex': qIdx++,
      'questionType': 'true_false',
      'question': '"$word" translates to "$wrongTranslation" in ${_langName(target)}.',
      'answers': 'True|False',
      'rightAnswer': 'False',
    });
  }

  // 1 matching (pair 4 words)
  final matchPairs = <String>[];
  for (int i = 0; i < 4 && i < lessonVocab.length; i++) {
    final key = lessonVocab[i];
    matchPairs.add('${kVocabulary[key]![source]!}:${kVocabulary[key]![target]!}');
  }
  questions.add({
    'questionIndex': qIdx++,
    'questionType': 'matching',
    'question': 'Match the words:',
    'answers': matchPairs.join('|'),
    'rightAnswer': matchPairs.join('|'),
  });

  return questions;
}

String _langName(String code) {
  const names = {
    'EN': 'English', 'IT': 'Italian', 'ES': 'Spanish',
    'FR': 'French', 'DE': 'German', 'PT': 'Portuguese', 'JA': 'Japanese',
  };
  return names[code] ?? code;
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SEED FUNCTION
// ─────────────────────────────────────────────────────────────────────────────

Future<void> main() async {
  await Firebase.initializeApp();
  final firestore = FirebaseFirestore.instance;

  int totalQuestions = 0;
  int totalNodes = 0;
  int pairsProcessed = 0;

  for (final source in kLanguages) {
    for (final target in kLanguages) {
      if (source == target) continue;

      final pairId = '${source.toLowerCase()}_${target.toLowerCase()}';
      print('Processing pair: $source -> $target ($pairId)...');

      // Check if already seeded
      final existingCheck = await firestore
          .collection('lessons')
          .where('languageSource', isEqualTo: source)
          .where('languageTarget', isEqualTo: target)
          .where('unit', isEqualTo: 1)
          .limit(1)
          .get();

      if (existingCheck.docs.isNotEmpty) {
        print('  Already seeded, skipping.');
        pairsProcessed++;
        continue;
      }

      // Generate and write lesson questions
      WriteBatch batch = firestore.batch();
      int batchCount = 0;

      for (final lesson in kLessons) {
        final questions = generateLessonQuestions(
          source: source,
          target: target,
          lessonIndex: lesson['index'] as int,
        );

        for (final q in questions) {
          final docRef = firestore.collection('lessons').doc();
          batch.set(docRef, {
            ...q,
            'questionNumber': q['questionIndex'],
            'languageSource': source,
            'languageTarget': target,
            'unit': 1,
            'lesson': lesson['index'],
            'createdAt': FieldValue.serverTimestamp(),
          });
          batchCount++;
          totalQuestions++;

          if (batchCount >= 490) {
            await batch.commit();
            batch = firestore.batch();
            batchCount = 0;
          }
        }
      }

      // Generate constellation nodes (7 per pair)
      final nodeTypes = [
        {'type': 'ClassicLesson', 'lessonId': 'lesson_01', 'order': 1},
        {'type': 'ClassicLesson', 'lessonId': 'lesson_02', 'order': 2},
        {'type': 'Flashcard', 'lessonId': null, 'order': 3},
        {'type': 'ClassicLesson', 'lessonId': 'lesson_03', 'order': 4},
        {'type': 'ClassicLesson', 'lessonId': 'lesson_04', 'order': 5},
        {'type': 'ClassicLesson', 'lessonId': 'lesson_05', 'order': 6},
        {'type': 'FinalQuiz', 'lessonId': null, 'order': 7},
      ];

      for (final node in nodeTypes) {
        final docRef = firestore.collection('constellation').doc();
        batch.set(docRef, {
          'languageSource': source,
          'languageTarget': target,
          'unit': 1,
          'nodeIndex': node['order'],
          'nodeType': node['type'],
          'lessonId': node['lessonId'],
          'isLocked': (node['order'] as int) > 1,
          'createdAt': FieldValue.serverTimestamp(),
        });
        batchCount++;
        totalNodes++;
      }

      if (batchCount > 0) {
        await batch.commit();
      }

      pairsProcessed++;
      print('  Done. Questions: ${totalQuestions}, Nodes: $totalNodes');
    }
  }

  print('\n=== SEED COMPLETE ===');
  print('Language pairs processed: $pairsProcessed');
  print('Total questions created: $totalQuestions');
  print('Total constellation nodes created: $totalNodes');
}
