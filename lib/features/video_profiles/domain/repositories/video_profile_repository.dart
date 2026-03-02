import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/video_profile.dart';

/// Abstract repository interface for video profile operations.
abstract class VideoProfileRepository {
  /// Upload a video profile for the given user.
  ///
  /// [userId] - The user uploading the video.
  /// [filePath] - Local file path of the video to upload.
  /// [prompt] - Optional prompt the user chose when recording.
  ///
  /// Returns the created [VideoProfile] on success.
  Future<Either<Failure, VideoProfile>> uploadVideoProfile(
    String userId,
    String filePath, {
    String? prompt,
  });

  /// Get the video profile for a specific user.
  ///
  /// Returns null (wrapped in Right) if the user has no video profile.
  Future<Either<Failure, VideoProfile?>> getVideoProfile(String userId);

  /// Delete the video profile for a specific user.
  ///
  /// Removes both the Storage file and Firestore document.
  Future<Either<Failure, void>> deleteVideoProfile(String userId);

  /// Get video profiles for discovery feed (TikTok-style browsing).
  ///
  /// [limit] - Max number of profiles to return per page.
  /// [lastId] - ID of the last loaded profile for pagination.
  ///
  /// Returns a list of active [VideoProfile]s.
  Future<Either<Failure, List<VideoProfile>>> getVideoProfilesForDiscovery({
    int limit = 20,
    String? lastId,
  });
}
