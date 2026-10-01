import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/experience_review.dart';
import '../entities/user_experience.dart';

/// The host is at their membership tier's experience limit.
class ExperienceLimitFailure extends Failure {
  const ExperienceLimitFailure({this.limit, this.count})
      : super('experience_limit');
  final int? limit;
  final int? count;

  @override
  List<Object?> get props => [message, limit, count];
}

/// The server refused prohibited language in the listing text.
class ExperienceProhibitedFailure extends Failure {
  const ExperienceProhibitedFailure() : super('prohibited_text');
}

/// The server refused the payload (field names in [fields]).
class ExperienceInvalidFailure extends Failure {
  const ExperienceInvalidFailure(this.fields) : super('invalid_experience');
  final List<String> fields;

  @override
  List<Object?> get props => [message, fields];
}

/// Infinite-scroll source: each [next] returns the next page in order.
abstract class ExperienceFeedPager {
  bool get hasMore;
  Future<List<UserExperience>> next();
}

/// A page of items plus the opaque cursor to continue after it.
class ExperiencePage<T> {
  const ExperiencePage({
    required this.items,
    required this.hasMore,
    this.cursor,
  });
  final List<T> items;
  final bool hasMore;

  /// Pass back to fetch the following page.
  final Object? cursor;
}

abstract class UserExperiencesRepository {
  /// Published community experiences: nearest-first around [lat]/[lng] when
  /// known (then the rest, newest first), newest first otherwise; [query]
  /// searches keywords, [category] filters.
  ExperienceFeedPager communityFeed({
    double? lat,
    double? lng,
    ExperienceCategory? category,
    String query = '',
    int pageSize = 20,
  });

  /// Every experience of [hostId] (drafts, published, hidden), newest first.
  ExperienceFeedPager hostFeed(String hostId, {int pageSize = 20});

  Future<Either<Failure, UserExperience?>> getExperience(String id);

  /// How many experiences [hostId] has (any status) — aggregate count().
  Future<Either<Failure, int>> countHostExperiences(String hostId);

  /// Creates via the `createUserExperience` callable (tier limit enforced
  /// server-side). Returns the new id.
  Future<Either<Failure, String>> createExperience(UserExperience draft);

  Future<Either<Failure, void>> updateExperience(UserExperience experience);

  Future<Either<Failure, void>> setStatus(String id, ExperienceStatus status);

  Future<Either<Failure, void>> deleteExperience(String id);

  Future<Either<Failure, void>> reportExperience({
    required UserExperience experience,
    required String reporterId,
  });

  // ── reviews ──

  Future<Either<Failure, ExperiencePage<ExperienceReview>>> getReviews(
    String experienceId, {
    Object? cursor,
    int limit = 10,
  });

  Future<Either<Failure, ExperienceReview?>> getMyReview(
      String experienceId, String uid);

  /// Creates or updates the caller's single review.
  Future<Either<Failure, void>> saveReview({
    required String experienceId,
    required String uid,
    required int rating,
    required String comment,
    required bool isNew,
  });

  Future<Either<Failure, void>> deleteReview(String experienceId, String uid);

  Future<Either<Failure, void>> reportReview({
    required ExperienceReview review,
    required String reporterId,
  });

  // ── replies ──

  Future<Either<Failure, ExperiencePage<ExperienceReply>>> getReplies(
    String experienceId,
    String reviewId, {
    Object? cursor,
    int limit = 10,
  });

  Future<Either<Failure, ExperienceReply>> addReply({
    required String experienceId,
    required String reviewId,
    required String authorId,
    required String text,
    required List<String> mentions,
  });

  Future<Either<Failure, void>> deleteReply(
      String experienceId, String reviewId, String replyId);

  /// Moderation status of a just-posted reply, as the server decides it.
  Stream<ReviewStatus> watchReplyStatus(
      String experienceId, String reviewId, String replyId);
}
