import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/vibe_tag.dart';

/// Vibe Tag Repository Interface
abstract class VibeTagRepository {
  /// Get all available vibe tags
  Future<Either<Failure, List<VibeTag>>> getVibeTags();

  /// Get vibe tags by category
  Future<Either<Failure, List<VibeTag>>> getVibeTagsByCategory(String category);

  /// Get user's selected vibe tags
  Future<Either<Failure, UserVibeTags>> getUserVibeTags(String userId);

  /// Stream user's vibe tags
  Stream<Either<Failure, UserVibeTags>> streamUserVibeTags(String userId);

  /// Update user's selected vibe tags
  Future<Either<Failure, UserVibeTags>> updateUserVibeTags({
    required String userId,
    required List<String> tagIds,
  });

  /// Set a temporary vibe tag (expires in 24 hours)
  Future<Either<Failure, UserVibeTags>> setTemporaryVibeTag({
    required String userId,
    required String tagId,
  });

  /// Remove a specific tag from user's selection
  Future<Either<Failure, UserVibeTags>> removeVibeTag({
    required String userId,
    required String tagId,
  });

  /// Search users by vibe tags
  Future<Either<Failure, List<String>>> searchUsersByVibeTags({
    required List<String> tagIds,
    int limit = 20,
    String? lastUserId,
  });

  /// Get vibe tag by ID
  Future<Either<Failure, VibeTag>> getVibeTagById(String tagId);
}
