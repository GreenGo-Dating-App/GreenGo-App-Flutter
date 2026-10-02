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

/// The server refused off-platform contact / payment info in the text.
class ExperienceContactInfoFailure extends Failure {
  const ExperienceContactInfoFailure() : super('contact_info');
}

/// A Phase 1 safety refusal; [code] is one of
/// ExperienceCreateException.safetyCodes (id_document_required,
/// id_document_not_approved, host_agreement_required, new_host_paid_limit,
/// host_banned, hidden, agreement_outdated).
class ExperienceSafetyFailure extends Failure {
  const ExperienceSafetyFailure(this.code) : super(code);
  final String code;

  @override
  List<Object?> get props => [message, code];
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

  /// Saves edits; Right(true) = the caller must still [publishExperience]
  /// (see UserExperiencesRemoteDataSource.update).
  Future<Either<Failure, bool>> updateExperience(
    UserExperience experience, {
    bool publish = false,
    bool wasPublished = false,
  });

  /// Publishes via the server (safety checks); [asFree] makes it free first.
  Future<Either<Failure, void>> publishExperience(String id,
      {bool asFree = false});

  Future<Either<Failure, void>> acceptHostAgreement(int version);

  /// Guest consent before paying the host (immutable record).
  Future<Either<Failure, void>> recordBookingConsent({
    required String experienceId,
    required String uid,
    required CancellationPolicy policy,
    required int version,
    required PaymentMethod method,
  });

  Future<Either<Failure, void>> setStatus(String id, ExperienceStatus status);

  Future<Either<Failure, void>> deleteExperience(String id);

  /// [reason]: scam | off_platform_payment | misleading | no_show |
  /// inappropriate | other. Three DISTINCT reporters auto-hide the listing.
  Future<Either<Failure, void>> reportExperience({
    required UserExperience experience,
    required String reporterId,
    String reason = 'other',
    String details = '',
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

  // ── booking-gated reviews (double-blind) ──

  /// The caller's review eligibility (a completed / checked-in booking), or
  /// null when they have none.
  Future<Either<Failure, ReviewEligibility?>> getReviewEligibility(
      String experienceId, String uid);

  /// The caller's blind review not yet published, or null.
  Future<Either<Failure, PendingReview?>> getPendingReview(
      String experienceId, String uid);

  /// Creates ([isNew]) or edits the caller's blind review.
  Future<Either<Failure, void>> savePendingReview({
    required String experienceId,
    required String uid,
    required String bookingId,
    required int rating,
    required String comment,
    required bool isNew,
  });

  Future<Either<Failure, void>> deletePendingReview(
      String experienceId, String uid);

  /// Host: instant booking (false) or request to book (true).
  Future<Either<Failure, void>> setRequestToBook(String id, bool value);

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
