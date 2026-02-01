import 'package:equatable/equatable.dart';

/// Vibe Tag Entity
/// Quick mood/intention tags for profiles (Coffee Chat, Serious, Adventurous)
class VibeTag extends Equatable {
  final String id;
  final String name;
  final String emoji;
  final String category;
  final bool isActive;
  final bool isPremium;
  final int sortOrder;

  const VibeTag({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
    this.isActive = true,
    this.isPremium = false,
    this.sortOrder = 0,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        emoji,
        category,
        isActive,
        isPremium,
        sortOrder,
      ];

  /// Copy with method
  VibeTag copyWith({
    String? id,
    String? name,
    String? emoji,
    String? category,
    bool? isActive,
    bool? isPremium,
    int? sortOrder,
  }) {
    return VibeTag(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      isPremium: isPremium ?? this.isPremium,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  /// Get display text with emoji
  String get displayText => '$emoji $name';
}

/// Vibe Tag Category
enum VibeTagCategory {
  mood,
  activity,
  intention,
  lifestyle,
}

extension VibeTagCategoryExtension on VibeTagCategory {
  String get displayName {
    switch (this) {
      case VibeTagCategory.mood:
        return 'Mood';
      case VibeTagCategory.activity:
        return 'Activity';
      case VibeTagCategory.intention:
        return 'Intention';
      case VibeTagCategory.lifestyle:
        return 'Lifestyle';
    }
  }

  static VibeTagCategory fromString(String value) {
    switch (value.toLowerCase()) {
      case 'mood':
        return VibeTagCategory.mood;
      case 'activity':
        return VibeTagCategory.activity;
      case 'intention':
        return VibeTagCategory.intention;
      case 'lifestyle':
        return VibeTagCategory.lifestyle;
      default:
        return VibeTagCategory.mood;
    }
  }
}

/// User Vibe Tags - tags selected by a user
class UserVibeTags extends Equatable {
  final String userId;
  final List<String> selectedTagIds;
  final String? temporaryTagId;
  final DateTime? temporaryTagExpiresAt;
  final DateTime updatedAt;

  const UserVibeTags({
    required this.userId,
    required this.selectedTagIds,
    this.temporaryTagId,
    this.temporaryTagExpiresAt,
    required this.updatedAt,
  });

  /// Check if temporary tag is active
  bool get hasActiveTemporaryTag {
    if (temporaryTagId == null || temporaryTagExpiresAt == null) return false;
    return DateTime.now().isBefore(temporaryTagExpiresAt!);
  }

  /// Get all active tag IDs including temporary
  List<String> get allActiveTagIds {
    final tags = List<String>.from(selectedTagIds);
    if (hasActiveTemporaryTag && !tags.contains(temporaryTagId)) {
      tags.add(temporaryTagId!);
    }
    return tags;
  }

  @override
  List<Object?> get props => [
        userId,
        selectedTagIds,
        temporaryTagId,
        temporaryTagExpiresAt,
        updatedAt,
      ];
}

/// Vibe Tag Limits
class VibeTagLimits {
  /// Free tier: 3 tags
  static const int freeTagLimit = 3;

  /// Premium tier: 5 tags
  static const int premiumTagLimit = 5;

  /// Temporary tag duration: 24 hours
  static const Duration temporaryTagDuration = Duration(hours: 24);

  /// Cost to add extra tag slot
  static const int extraSlotCost = 10;

  /// Get tag limit based on premium status
  static int getTagLimit(bool isPremium) {
    return isPremium ? premiumTagLimit : freeTagLimit;
  }
}
