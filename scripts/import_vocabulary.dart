/// Standalone script to import vocabulary data into Firestore
///
/// Run with: dart run scripts/import_vocabulary.dart
///
/// This downloads word frequency data from OpenSubtitles GitHub repo,
/// filters to words with 3+ letters, randomly samples 100k per language,
/// and batch-writes to Firestore collections.

import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/firebase_options.dart';

const String baseUrl =
    'https://raw.githubusercontent.com/orgtre/top-open-subtitles-sentences/main/bld';

const List<String> languages = ['en', 'es', 'de', 'fr', 'it', 'pt', 'pt_br'];
const int targetWordsPerLanguage = 100000;
const int batchSize = 450;

final Random random = Random();

Future<void> main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final firestore = FirebaseFirestore.instance;

  for (final lang in languages) {
    print('\n=== Processing language: $lang ===');

    // Import words
    print('Downloading words for $lang...');
    final words = await downloadAndParse(
      '$baseUrl/top_words/${lang}_top_words.csv',
    );
    print('Parsed ${words.length} words with 3+ letters');

    final sampledWords = randomSample(words, targetWordsPerLanguage);
    sampledWords.sort((a, b) => b.count.compareTo(a.count));
    print('Sampled ${sampledWords.length} words');

    await batchWriteEntries(
      firestore,
      'vocabulary_words',
      lang,
      sampledWords,
    );

    // Import sentences
    print('Downloading sentences for $lang...');
    final sentences = await downloadAndParse(
      '$baseUrl/top_sentences/${lang}_top_sentences.csv',
    );
    print('Parsed ${sentences.length} sentences');

    await batchWriteEntries(
      firestore,
      'vocabulary_sentences',
      lang,
      sentences,
    );
  }

  print('\n=== Import complete! ===');
}

Future<List<CsvEntry>> downloadAndParse(String url) async {
  final response = await http.get(Uri.parse(url));
  if (response.statusCode != 200) {
    print('Failed to download $url: ${response.statusCode}');
    return [];
  }

  final lines = response.body.split('\n');
  final entries = <CsvEntry>[];

  for (int i = 1; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) continue;

    final lastComma = line.lastIndexOf(',');
    if (lastComma <= 0) continue;

    final text = line.substring(0, lastComma).trim();
    final countStr = line.substring(lastComma + 1).trim();
    final count = int.tryParse(countStr);
    if (count == null || text.isEmpty) continue;
    if (text.length < 3) continue;

    entries.add(CsvEntry(text: text, count: count));
  }

  entries.sort((a, b) => b.count.compareTo(a.count));
  return entries;
}

List<CsvEntry> randomSample(List<CsvEntry> source, int count) {
  if (source.length <= count) return List.from(source);

  final list = List<CsvEntry>.from(source);
  for (int i = 0; i < count; i++) {
    final j = i + random.nextInt(list.length - i);
    final temp = list[i];
    list[i] = list[j];
    list[j] = temp;
  }
  return list.sublist(0, count);
}

int computeFrequencyScore(int rank, int total) {
  if (total <= 1) return 100;
  return max(1, 100 - ((rank - 1) * 100 ~/ total));
}

Future<void> batchWriteEntries(
  FirebaseFirestore firestore,
  String collection,
  String language,
  List<CsvEntry> entries,
) async {
  final total = entries.length;
  int written = 0;
  WriteBatch batch = firestore.batch();
  int batchCount = 0;

  for (int i = 0; i < entries.length; i++) {
    final entry = entries[i];
    final rank = i + 1;
    final score = computeFrequencyScore(rank, total);

    final docRef = firestore.collection(collection).doc();
    batch.set(docRef, {
      'text': entry.text,
      'language': language,
      'count': entry.count,
      'rank': rank,
      'frequencyScore': score,
    });

    batchCount++;
    if (batchCount >= batchSize) {
      await batch.commit();
      written += batchCount;
      print('  $collection/$language: $written/$total written');
      batch = firestore.batch();
      batchCount = 0;
    }
  }

  if (batchCount > 0) {
    await batch.commit();
    written += batchCount;
  }
  print('  $collection/$language: $written/$total complete');
}

class CsvEntry {
  final String text;
  final int count;
  const CsvEntry({required this.text, required this.count});
}
