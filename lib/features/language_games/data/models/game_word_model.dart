import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for words stored in the `game_words` Firestore collection.
class GameWordModel {
  final String id;
  final String word;
  final String language;
  final String category;
  final int difficulty;
  final Map<String, List<String>> translations;
  final String partOfSpeech;

  const GameWordModel({
    required this.id,
    required this.word,
    required this.language,
    required this.category,
    required this.difficulty,
    required this.translations,
    required this.partOfSpeech,
  });

  factory GameWordModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GameWordModel(
      id: doc.id,
      word: data['word'] as String? ?? '',
      language: data['language'] as String? ?? '',
      category: data['category'] as String? ?? '',
      difficulty: data['difficulty'] as int? ?? 1,
      translations: (data['translations'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, List<String>.from(value as List)),
          ) ??
          {},
      partOfSpeech: data['partOfSpeech'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'word': word,
        'language': language,
        'category': category,
        'difficulty': difficulty,
        'translations': translations,
        'partOfSpeech': partOfSpeech,
      };
}
