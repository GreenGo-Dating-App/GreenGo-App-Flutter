import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'vocabulary_service.dart';

/// Service for tracking user vocabulary usage in chat messages
///
/// Extracts unique words from messages, looks up frequency scores,
/// and awards XP based on word rarity.
class VocabularyTrackingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// XP awarded based on word frequency score
  static int _xpForFrequencyScore(int? score) {
    if (score == null) return 2; // Unknown word
    if (score >= 90) return 1; // Very common
    if (score >= 50) return 3; // Medium frequency
    return 5; // Rare/advanced
  }

  /// Process a chat message and track vocabulary usage
  ///
  /// Returns total XP earned from new words in this message.
  static Future<int> trackMessage({
    required String userId,
    required String messageText,
    required String language,
  }) async {
    final words = _extractWords(messageText);
    if (words.isEmpty) return 0;

    // Get frequency scores for all words
    final scores = await VocabularyService.getWordFrequencyScores(
      words.toList(),
      language,
    );

    int totalXp = 0;
    final batch = _firestore.batch();
    int batchCount = 0;

    for (final word in words) {
      final userWordRef = _firestore
          .collection('user_vocabulary')
          .doc(userId)
          .collection('words')
          .doc('${language}_$word');

      final existingDoc = await userWordRef.get();

      if (existingDoc.exists) {
        // Word already tracked, increment use count
        batch.update(userWordRef, {
          'useCount': FieldValue.increment(1),
        });
      } else {
        // New word — track it and award XP
        final frequencyScore = scores[word];
        final xp = _xpForFrequencyScore(frequencyScore);
        totalXp += xp;

        batch.set(userWordRef, {
          'word': word,
          'language': language,
          'frequencyScore': frequencyScore ?? 0,
          'firstUsedAt': FieldValue.serverTimestamp(),
          'useCount': 1,
        });
      }

      batchCount++;
      if (batchCount >= 450) {
        await batch.commit();
        batchCount = 0;
      }
    }

    if (batchCount > 0) {
      await batch.commit();
    }

    // Award XP if any new words found
    if (totalXp > 0) {
      await _awardVocabularyXp(userId, totalXp);
    }

    return totalXp;
  }

  /// Extract unique lowercase words from a message
  static Set<String> _extractWords(String text) {
    final words = <String>{};
    final matches = RegExp(r"[a-zA-ZÀ-ÿ\u00C0-\u024F']+").allMatches(text);
    for (final match in matches) {
      final word = match.group(0)?.toLowerCase().trim();
      if (word != null && word.length >= 2) {
        words.add(word);
      }
    }
    return words;
  }

  /// Award vocabulary XP to user's gamification profile
  static Future<void> _awardVocabularyXp(String userId, int xp) async {
    try {
      final userLevelRef = _firestore.collection('user_levels').doc(userId);
      final doc = await userLevelRef.get();

      if (doc.exists) {
        await userLevelRef.update({
          'currentXP': FieldValue.increment(xp),
          'totalXP': FieldValue.increment(xp),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      // Log XP transaction
      await _firestore.collection('xp_transactions').add({
        'userId': userId,
        'actionType': 'vocabulary_usage',
        'xpAmount': xp,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error awarding vocabulary XP: $e');
    }
  }

  /// Get user's vocabulary stats for a language
  static Future<Map<String, dynamic>> getVocabularyStats(
    String userId,
    String language,
  ) async {
    final snapshot = await _firestore
        .collection('user_vocabulary')
        .doc(userId)
        .collection('words')
        .where('language', isEqualTo: language)
        .get();

    int uniqueWords = 0;
    int commonWords = 0;
    int mediumWords = 0;
    int rareWords = 0;
    int unknownWords = 0;

    for (final doc in snapshot.docs) {
      uniqueWords++;
      final score = doc.data()['frequencyScore'] as int? ?? 0;
      if (score >= 90) {
        commonWords++;
      } else if (score >= 50) {
        mediumWords++;
      } else if (score >= 1) {
        rareWords++;
      } else {
        unknownWords++;
      }
    }

    return {
      'uniqueWords': uniqueWords,
      'commonWords': commonWords,
      'mediumWords': mediumWords,
      'rareWords': rareWords,
      'unknownWords': unknownWords,
    };
  }
}
