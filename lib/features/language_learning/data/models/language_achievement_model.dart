import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/language_achievement.dart';

class LanguageAchievementModel extends LanguageAchievement {
  const LanguageAchievementModel({
    required super.id,
    required super.name,
    required super.description,
    required super.category,
    required super.rarity,
    required super.requiredProgress,
    super.currentProgress,
    super.xpReward,
    super.coinReward,
    required super.iconEmoji,
    super.isUnlocked,
    super.unlockedAt,
    super.isSecret,
  });

  factory LanguageAchievementModel.fromJson(Map<String, dynamic> json) {
    return LanguageAchievementModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: LanguageAchievementCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => LanguageAchievementCategory.learning,
      ),
      rarity: AchievementRarity.values.firstWhere(
        (e) => e.name == json['rarity'],
        orElse: () => AchievementRarity.common,
      ),
      requiredProgress: json['requiredProgress'] as int,
      currentProgress: json['currentProgress'] as int? ?? 0,
      xpReward: json['xpReward'] as int? ?? 0,
      coinReward: json['coinReward'] as int? ?? 0,
      iconEmoji: json['iconEmoji'] as String,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? (json['unlockedAt'] as Timestamp).toDate()
          : null,
      isSecret: json['isSecret'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category.name,
      'rarity': rarity.name,
      'requiredProgress': requiredProgress,
      'currentProgress': currentProgress,
      'xpReward': xpReward,
      'coinReward': coinReward,
      'iconEmoji': iconEmoji,
      'isUnlocked': isUnlocked,
      'unlockedAt':
          unlockedAt != null ? Timestamp.fromDate(unlockedAt!) : null,
      'isSecret': isSecret,
    };
  }

  factory LanguageAchievementModel.fromEntity(LanguageAchievement entity) {
    return LanguageAchievementModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      category: entity.category,
      rarity: entity.rarity,
      requiredProgress: entity.requiredProgress,
      currentProgress: entity.currentProgress,
      xpReward: entity.xpReward,
      coinReward: entity.coinReward,
      iconEmoji: entity.iconEmoji,
      isUnlocked: entity.isUnlocked,
      unlockedAt: entity.unlockedAt,
      isSecret: entity.isSecret,
    );
  }
}
