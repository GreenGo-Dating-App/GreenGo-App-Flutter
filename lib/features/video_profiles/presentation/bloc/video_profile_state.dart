import 'package:equatable/equatable.dart';
import '../../domain/entities/video_profile.dart';

/// Base state for the VideoProfile BLoC.
abstract class VideoProfileState extends Equatable {
  const VideoProfileState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any action has been taken.
class VideoProfileInitial extends VideoProfileState {
  const VideoProfileInitial();
}

/// Generic loading state (for load/delete operations).
class VideoProfileLoading extends VideoProfileState {
  const VideoProfileLoading();
}

/// Upload in progress with a progress value (0.0 to 1.0).
class VideoProfileUploading extends VideoProfileState {
  final double progress;

  const VideoProfileUploading({required this.progress});

  @override
  List<Object?> get props => [progress];
}

/// Successfully loaded a video profile and/or discovery videos.
class VideoProfileLoaded extends VideoProfileState {
  /// The current user's video profile (null if none exists).
  final VideoProfile? videoProfile;

  /// List of video profiles for the discovery feed.
  final List<VideoProfile> discoveryVideos;

  const VideoProfileLoaded({
    this.videoProfile,
    this.discoveryVideos = const [],
  });

  @override
  List<Object?> get props => [videoProfile, discoveryVideos];

  /// Create a copy with updated fields.
  VideoProfileLoaded copyWith({
    VideoProfile? videoProfile,
    List<VideoProfile>? discoveryVideos,
  }) {
    return VideoProfileLoaded(
      videoProfile: videoProfile ?? this.videoProfile,
      discoveryVideos: discoveryVideos ?? this.discoveryVideos,
    );
  }
}

/// An error occurred during a video profile operation.
class VideoProfileError extends VideoProfileState {
  final String message;

  const VideoProfileError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Video profile was successfully deleted.
class VideoProfileDeleted extends VideoProfileState {
  const VideoProfileDeleted();
}
