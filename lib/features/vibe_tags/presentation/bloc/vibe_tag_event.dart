import 'package:equatable/equatable.dart';

/// Vibe Tag Events
abstract class VibeTagEvent extends Equatable {
  const VibeTagEvent();

  @override
  List<Object?> get props => [];
}

/// Load all available vibe tags
class LoadVibeTags extends VibeTagEvent {
  const LoadVibeTags();
}

/// Load vibe tags by category
class LoadVibeTagsByCategory extends VibeTagEvent {

  const LoadVibeTagsByCategory(this.category);
  final String category;

  @override
  List<Object?> get props => [category];
}

/// Load user's selected vibe tags
class LoadUserVibeTags extends VibeTagEvent {

  const LoadUserVibeTags(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Subscribe to user's vibe tags stream
class SubscribeToUserVibeTags extends VibeTagEvent {

  const SubscribeToUserVibeTags(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Update user's selected vibe tags
class UpdateUserVibeTagsEvent extends VibeTagEvent {

  const UpdateUserVibeTagsEvent({
    required this.userId,
    required this.tagIds,
  });
  final String userId;
  final List<String> tagIds;

  @override
  List<Object?> get props => [userId, tagIds];
}

/// Add a vibe tag to user's selection
class AddVibeTag extends VibeTagEvent {

  const AddVibeTag({
    required this.userId,
    required this.tagId,
  });
  final String userId;
  final String tagId;

  @override
  List<Object?> get props => [userId, tagId];
}

/// Remove a vibe tag from user's selection
class RemoveVibeTagEvent extends VibeTagEvent {

  const RemoveVibeTagEvent({
    required this.userId,
    required this.tagId,
  });
  final String userId;
  final String tagId;

  @override
  List<Object?> get props => [userId, tagId];
}

/// Set a temporary vibe tag (24 hours)
class SetTemporaryVibeTagEvent extends VibeTagEvent {

  const SetTemporaryVibeTagEvent({
    required this.userId,
    required this.tagId,
  });
  final String userId;
  final String tagId;

  @override
  List<Object?> get props => [userId, tagId];
}

/// Search users by vibe tags
class SearchByVibeTags extends VibeTagEvent {

  const SearchByVibeTags({
    required this.tagIds,
    this.limit = 20,
    this.lastUserId,
  });
  final List<String> tagIds;
  final int limit;
  final String? lastUserId;

  @override
  List<Object?> get props => [tagIds, limit, lastUserId];
}

/// Toggle a vibe tag selection (add if not selected, remove if selected)
class ToggleVibeTag extends VibeTagEvent {

  const ToggleVibeTag({
    required this.userId,
    required this.tagId,
    this.isPremium = false,
  });
  final String userId;
  final String tagId;
  final bool isPremium;

  @override
  List<Object?> get props => [userId, tagId, isPremium];
}
