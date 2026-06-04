import 'package:equatable/equatable.dart';
import '../../domain/entities/vibe_tag.dart';

/// Vibe Tag States
abstract class VibeTagState extends Equatable {
  const VibeTagState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class VibeTagInitial extends VibeTagState {
  const VibeTagInitial();
}

/// Loading state
class VibeTagLoading extends VibeTagState {
  const VibeTagLoading();
}

/// Error state
class VibeTagError extends VibeTagState {

  const VibeTagError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

/// All vibe tags loaded
class VibeTagsLoaded extends VibeTagState {

  VibeTagsLoaded({
    required this.tags,
    Map<String, List<VibeTag>>? tagsByCategory,
  }) : tagsByCategory = tagsByCategory ?? _groupByCategory(tags);
  final List<VibeTag> tags;
  final Map<String, List<VibeTag>> tagsByCategory;

  static Map<String, List<VibeTag>> _groupByCategory(List<VibeTag> tags) {
    final grouped = <String, List<VibeTag>>{};
    for (final tag in tags) {
      if (!grouped.containsKey(tag.category)) {
        grouped[tag.category] = [];
      }
      grouped[tag.category]!.add(tag);
    }
    return grouped;
  }

  @override
  List<Object?> get props => [tags, tagsByCategory];
}

/// User's vibe tags loaded
class UserVibeTagsLoaded extends VibeTagState {

  const UserVibeTagsLoaded({
    required this.userTags,
    required this.tagLimit, required this.canAddMore, this.availableTags,
  });
  final UserVibeTags userTags;
  final List<VibeTag>? availableTags;
  final int tagLimit;
  final bool canAddMore;

  @override
  List<Object?> get props => [userTags, availableTags, tagLimit, canAddMore];
}

/// Combined state with all data for tag selection UI
class VibeTagSelectionState extends VibeTagState {

  const VibeTagSelectionState({
    required this.allTags,
    required this.tagsByCategory,
    required this.userTags,
    required this.tagLimit,
    required this.isPremium,
  });
  final List<VibeTag> allTags;
  final Map<String, List<VibeTag>> tagsByCategory;
  final UserVibeTags userTags;
  final int tagLimit;
  final bool isPremium;

  /// Get selected tag objects
  List<VibeTag> get selectedTags {
    return allTags
        .where((tag) => userTags.selectedTagIds.contains(tag.id))
        .toList();
  }

  /// Get temporary tag object if exists
  VibeTag? get temporaryTag {
    if (!userTags.hasActiveTemporaryTag) return null;
    try {
      return allTags.firstWhere((tag) => tag.id == userTags.temporaryTagId);
    } catch (_) {
      return null;
    }
  }

  /// Check if can add more tags
  bool get canAddMore => userTags.selectedTagIds.length < tagLimit;

  /// Get remaining tag slots
  int get remainingSlots => tagLimit - userTags.selectedTagIds.length;

  /// Check if a tag is selected
  bool isTagSelected(String tagId) {
    return userTags.selectedTagIds.contains(tagId);
  }

  /// Check if a tag is the temporary tag
  bool isTemporaryTag(String tagId) {
    return userTags.temporaryTagId == tagId && userTags.hasActiveTemporaryTag;
  }

  @override
  List<Object?> get props =>
      [allTags, tagsByCategory, userTags, tagLimit, isPremium];
}

/// User vibe tags updated successfully
class UserVibeTagsUpdated extends VibeTagState {

  const UserVibeTagsUpdated(this.userTags);
  final UserVibeTags userTags;

  @override
  List<Object?> get props => [userTags];
}

/// Temporary tag set successfully
class TemporaryVibeTagSet extends VibeTagState {

  const TemporaryVibeTagSet({
    required this.userTags,
    required this.expiresAt,
  });
  final UserVibeTags userTags;
  final DateTime expiresAt;

  @override
  List<Object?> get props => [userTags, expiresAt];
}

/// Vibe tag removed successfully
class VibeTagRemoved extends VibeTagState {

  const VibeTagRemoved({
    required this.tagId,
    required this.userTags,
  });
  final String tagId;
  final UserVibeTags userTags;

  @override
  List<Object?> get props => [tagId, userTags];
}

/// Search results loaded
class VibeTagSearchResults extends VibeTagState {

  const VibeTagSearchResults({
    required this.userIds,
    required this.searchedTagIds,
    required this.hasMore,
  });
  final List<String> userIds;
  final List<String> searchedTagIds;
  final bool hasMore;

  @override
  List<Object?> get props => [userIds, searchedTagIds, hasMore];
}

/// Tag limit reached - show upgrade prompt
class VibeTagLimitReached extends VibeTagState {

  const VibeTagLimitReached({
    required this.currentCount,
    required this.limit,
    required this.isPremium,
  });
  final int currentCount;
  final int limit;
  final bool isPremium;

  @override
  List<Object?> get props => [currentCount, limit, isPremium];
}
