import 'package:equatable/equatable.dart';

/// Vocabulary statistics for a user in a specific language
class VocabularyStats extends Equatable {
  final String userId;
  final String language;
  final int uniqueWordCount;
  final int totalXpEarned;
  final Map<String, int> rarityDistribution;

  const VocabularyStats({
    required this.userId,
    required this.language,
    this.uniqueWordCount = 0,
    this.totalXpEarned = 0,
    this.rarityDistribution = const {},
  });

  /// Get vocabulary level badge based on unique word count
  String? get vocabularyBadge {
    if (uniqueWordCount >= 5000) return 'vocabulary_master';
    if (uniqueWordCount >= 1000) return 'vocabulary_expert';
    if (uniqueWordCount >= 500) return 'vocabulary_advanced';
    if (uniqueWordCount >= 100) return 'vocabulary_intermediate';
    return null;
  }

  /// Get vocabulary badge label
  String get vocabularyBadgeLabel {
    if (uniqueWordCount >= 5000) return 'Master';
    if (uniqueWordCount >= 1000) return 'Expert';
    if (uniqueWordCount >= 500) return 'Advanced';
    if (uniqueWordCount >= 100) return 'Intermediate';
    return 'Beginner';
  }

  @override
  List<Object?> get props => [
        userId,
        language,
        uniqueWordCount,
        totalXpEarned,
        rarityDistribution,
      ];
}
