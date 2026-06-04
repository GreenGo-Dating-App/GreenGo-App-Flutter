import 'package:equatable/equatable.dart';

/// Base event for the VideoProfile BLoC.
abstract class VideoProfileEvent extends Equatable {
  const VideoProfileEvent();

  @override
  List<Object?> get props => [];
}

/// Upload a new video profile for the given user.
class UploadVideoProfile extends VideoProfileEvent {

  const UploadVideoProfile({
    required this.userId,
    required this.filePath,
    this.prompt,
  });
  final String userId;
  final String filePath;
  final String? prompt;

  @override
  List<Object?> get props => [userId, filePath, prompt];
}

/// Load the video profile for a specific user.
class LoadVideoProfile extends VideoProfileEvent {

  const LoadVideoProfile({required this.userId});
  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Delete the video profile for a specific user.
class DeleteVideoProfile extends VideoProfileEvent {

  const DeleteVideoProfile({required this.userId});
  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Load video profiles for the TikTok-style discovery feed.
class LoadDiscoveryVideos extends VideoProfileEvent {

  const LoadDiscoveryVideos({
    this.limit = 20,
    this.lastId,
  });
  final int limit;
  final String? lastId;

  @override
  List<Object?> get props => [limit, lastId];
}
