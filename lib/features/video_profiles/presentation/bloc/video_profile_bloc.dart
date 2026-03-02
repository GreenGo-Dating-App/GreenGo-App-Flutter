import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/video_profile_repository_impl.dart';
import '../../domain/repositories/video_profile_repository.dart';
import 'video_profile_event.dart';
import 'video_profile_state.dart';

/// BLoC for managing video profile state.
///
/// Handles uploading, loading, deleting, and browsing video profiles.
class VideoProfileBloc extends Bloc<VideoProfileEvent, VideoProfileState> {
  final VideoProfileRepository repository;

  VideoProfileBloc({required this.repository})
      : super(const VideoProfileInitial()) {
    on<UploadVideoProfile>(_onUploadVideoProfile);
    on<LoadVideoProfile>(_onLoadVideoProfile);
    on<DeleteVideoProfile>(_onDeleteVideoProfile);
    on<LoadDiscoveryVideos>(_onLoadDiscoveryVideos);
  }

  Future<void> _onUploadVideoProfile(
    UploadVideoProfile event,
    Emitter<VideoProfileState> emit,
  ) async {
    emit(const VideoProfileUploading(progress: 0.0));

    // Set up progress tracking if the repository supports it
    if (repository is VideoProfileRepositoryImpl) {
      (repository as VideoProfileRepositoryImpl).onUploadProgress =
          (progress) {
        // We cannot emit inside a callback, so we use add() to dispatch
        // a progress update. However, since BLoC events are sequential,
        // we track progress through the repository callback pattern.
        // The UI should also listen to the uploading state.
        debugPrint(
            '[VideoProfileBloc] Upload progress: ${(progress * 100).toStringAsFixed(0)}%');
      };
    }

    final result = await repository.uploadVideoProfile(
      event.userId,
      event.filePath,
      prompt: event.prompt,
    );

    result.fold(
      (failure) {
        debugPrint('[VideoProfileBloc] Upload failed: ${failure.message}');
        emit(VideoProfileError(message: failure.message));
      },
      (videoProfile) {
        debugPrint(
            '[VideoProfileBloc] Upload success for user ${event.userId}');
        emit(VideoProfileLoaded(videoProfile: videoProfile));
      },
    );
  }

  Future<void> _onLoadVideoProfile(
    LoadVideoProfile event,
    Emitter<VideoProfileState> emit,
  ) async {
    emit(const VideoProfileLoading());

    final result = await repository.getVideoProfile(event.userId);

    result.fold(
      (failure) {
        debugPrint(
            '[VideoProfileBloc] Load failed: ${failure.message}');
        emit(VideoProfileError(message: failure.message));
      },
      (videoProfile) {
        // Preserve discovery videos if previously loaded
        final currentDiscovery = state is VideoProfileLoaded
            ? (state as VideoProfileLoaded).discoveryVideos
            : <dynamic>[];
        emit(VideoProfileLoaded(
          videoProfile: videoProfile,
          discoveryVideos: currentDiscovery.cast(),
        ));
      },
    );
  }

  Future<void> _onDeleteVideoProfile(
    DeleteVideoProfile event,
    Emitter<VideoProfileState> emit,
  ) async {
    emit(const VideoProfileLoading());

    final result = await repository.deleteVideoProfile(event.userId);

    result.fold(
      (failure) {
        debugPrint(
            '[VideoProfileBloc] Delete failed: ${failure.message}');
        emit(VideoProfileError(message: failure.message));
      },
      (_) {
        debugPrint(
            '[VideoProfileBloc] Deleted video profile for ${event.userId}');
        emit(const VideoProfileDeleted());
      },
    );
  }

  Future<void> _onLoadDiscoveryVideos(
    LoadDiscoveryVideos event,
    Emitter<VideoProfileState> emit,
  ) async {
    // If paginating (lastId provided), keep current state while loading
    final currentProfile = state is VideoProfileLoaded
        ? (state as VideoProfileLoaded).videoProfile
        : null;
    final currentVideos = state is VideoProfileLoaded
        ? (state as VideoProfileLoaded).discoveryVideos
        : <dynamic>[];

    if (event.lastId == null) {
      // Fresh load
      emit(const VideoProfileLoading());
    }

    final result = await repository.getVideoProfilesForDiscovery(
      limit: event.limit,
      lastId: event.lastId,
    );

    result.fold(
      (failure) {
        debugPrint(
            '[VideoProfileBloc] Discovery load failed: ${failure.message}');
        emit(VideoProfileError(message: failure.message));
      },
      (newVideos) {
        final allVideos = event.lastId != null
            ? [...currentVideos.cast<VideoProfile>(), ...newVideos]
            : newVideos;

        emit(VideoProfileLoaded(
          videoProfile: currentProfile,
          discoveryVideos: allVideos,
        ));
      },
    );
  }
}
