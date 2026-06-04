import 'package:equatable/equatable.dart';

/// Story Type Enum
enum StoryType { image, video }

/// Story Entity
/// 24-hour ephemeral content like Instagram Stories
class Story extends Equatable {

  const Story({
    required this.id,
    required this.userId,
    required this.userDisplayName,
    required this.type, required this.mediaUrl, required this.createdAt, required this.expiresAt, this.userPhotoUrl,
    this.thumbnailUrl,
    this.caption,
    this.viewedBy = const [],
    this.reactions = const [],
    this.isActive = true,
    this.musicTrackId,
    this.locationName,
  });
  final String id;
  final String userId;
  final String userDisplayName;
  final String? userPhotoUrl;
  final StoryType type;
  final String mediaUrl;
  final String? thumbnailUrl;
  final String? caption;
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<String> viewedBy;
  final List<StoryReaction> reactions;
  final bool isActive;
  final String? musicTrackId;
  final String? locationName;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  int get viewCount => viewedBy.length;
  Duration get remainingTime => expiresAt.difference(DateTime.now());

  @override
  List<Object?> get props => [
        id,
        userId,
        userDisplayName,
        userPhotoUrl,
        type,
        mediaUrl,
        thumbnailUrl,
        caption,
        createdAt,
        expiresAt,
        viewedBy,
        reactions,
        isActive,
        musicTrackId,
        locationName,
      ];

  Story copyWith({
    String? id,
    String? userId,
    String? userDisplayName,
    String? userPhotoUrl,
    StoryType? type,
    String? mediaUrl,
    String? thumbnailUrl,
    String? caption,
    DateTime? createdAt,
    DateTime? expiresAt,
    List<String>? viewedBy,
    List<StoryReaction>? reactions,
    bool? isActive,
    String? musicTrackId,
    String? locationName,
  }) {
    return Story(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userDisplayName: userDisplayName ?? this.userDisplayName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      type: type ?? this.type,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      caption: caption ?? this.caption,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      viewedBy: viewedBy ?? this.viewedBy,
      reactions: reactions ?? this.reactions,
      isActive: isActive ?? this.isActive,
      musicTrackId: musicTrackId ?? this.musicTrackId,
      locationName: locationName ?? this.locationName,
    );
  }
}

/// Story Reaction
class StoryReaction extends Equatable {

  const StoryReaction({
    required this.id,
    required this.storyId,
    required this.userId,
    required this.emoji,
    required this.createdAt,
  });
  final String id;
  final String storyId;
  final String userId;
  final String emoji;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, storyId, userId, emoji, createdAt];
}

/// User Stories Collection
class UserStories extends Equatable {

  const UserStories({
    required this.userId,
    required this.userDisplayName,
    required this.stories, this.userPhotoUrl,
    this.hasUnviewedStories = false,
  });
  final String userId;
  final String userDisplayName;
  final String? userPhotoUrl;
  final List<Story> stories;
  final bool hasUnviewedStories;

  List<Story> get activeStories =>
      stories.where((s) => !s.isExpired && s.isActive).toList();

  @override
  List<Object?> get props => [
        userId,
        userDisplayName,
        userPhotoUrl,
        stories,
        hasUnviewedStories,
      ];
}
