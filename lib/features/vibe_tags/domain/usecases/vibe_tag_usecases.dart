import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/vibe_tag.dart';
import '../repositories/vibe_tag_repository.dart';

/// Get all available vibe tags
class GetVibeTags {
  final VibeTagRepository repository;

  GetVibeTags(this.repository);

  Future<Either<Failure, List<VibeTag>>> call() {
    return repository.getVibeTags();
  }
}

/// Get vibe tags by category
class GetVibeTagsByCategory {
  final VibeTagRepository repository;

  GetVibeTagsByCategory(this.repository);

  Future<Either<Failure, List<VibeTag>>> call(String category) {
    return repository.getVibeTagsByCategory(category);
  }
}

/// Get user's selected vibe tags
class GetUserVibeTags {
  final VibeTagRepository repository;

  GetUserVibeTags(this.repository);

  Future<Either<Failure, UserVibeTags>> call(String userId) {
    return repository.getUserVibeTags(userId);
  }

  Stream<Either<Failure, UserVibeTags>> stream(String userId) {
    return repository.streamUserVibeTags(userId);
  }
}

/// Update user's selected vibe tags
class UpdateUserVibeTags {
  final VibeTagRepository repository;

  UpdateUserVibeTags(this.repository);

  Future<Either<Failure, UserVibeTags>> call({
    required String userId,
    required List<String> tagIds,
  }) {
    return repository.updateUserVibeTags(userId: userId, tagIds: tagIds);
  }
}

/// Set a temporary vibe tag
class SetTemporaryVibeTag {
  final VibeTagRepository repository;

  SetTemporaryVibeTag(this.repository);

  Future<Either<Failure, UserVibeTags>> call({
    required String userId,
    required String tagId,
  }) {
    return repository.setTemporaryVibeTag(userId: userId, tagId: tagId);
  }
}

/// Remove a vibe tag from user's selection
class RemoveVibeTag {
  final VibeTagRepository repository;

  RemoveVibeTag(this.repository);

  Future<Either<Failure, UserVibeTags>> call({
    required String userId,
    required String tagId,
  }) {
    return repository.removeVibeTag(userId: userId, tagId: tagId);
  }
}

/// Search users by vibe tags
class SearchUsersByVibeTags {
  final VibeTagRepository repository;

  SearchUsersByVibeTags(this.repository);

  Future<Either<Failure, List<String>>> call({
    required List<String> tagIds,
    int limit = 20,
    String? lastUserId,
  }) {
    return repository.searchUsersByVibeTags(
      tagIds: tagIds,
      limit: limit,
      lastUserId: lastUserId,
    );
  }
}

/// Get vibe tag by ID
class GetVibeTagById {
  final VibeTagRepository repository;

  GetVibeTagById(this.repository);

  Future<Either<Failure, VibeTag>> call(String tagId) {
    return repository.getVibeTagById(tagId);
  }
}
