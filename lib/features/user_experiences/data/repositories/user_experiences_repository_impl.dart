import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/experience_review.dart';
import '../../domain/entities/user_experience.dart';
import '../../domain/repositories/user_experiences_repository.dart';
import '../datasources/user_experiences_remote_datasource.dart';

class UserExperiencesRepositoryImpl implements UserExperiencesRepository {
  UserExperiencesRepositoryImpl({UserExperiencesRemoteDataSource? remote})
      : _remote = remote ?? UserExperiencesRemoteDataSource();

  final UserExperiencesRemoteDataSource _remote;

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Right(await run());
    } on ExperienceCreateException catch (e) {
      switch (e.code) {
        case 'experience_limit':
          return Left(ExperienceLimitFailure(limit: e.limit, count: e.count));
        case 'prohibited_text':
          return const Left(ExperienceProhibitedFailure());
        case 'contact_info':
          return const Left(ExperienceContactInfoFailure());
        case 'invalid_experience':
          return Left(ExperienceInvalidFailure(e.fields));
        case 'community_not_allowed':
        case 'community_not_found':
        case 'invalid_community':
          return Left(ExperienceCommunityFailure(e.code));
        default:
          if (ExperienceCreateException.safetyCodes.contains(e.code)) {
            return Left(ExperienceSafetyFailure(e.code));
          }
          return Left(ServerFailure(e.code));
      }
    } catch (e) {
      debugPrint('UserExperiencesRepository: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ExperienceFeedPager communityFeed({
    double? lat,
    double? lng,
    ExperienceCategory? category,
    String query = '',
    int pageSize = 20,
  }) =>
      _remote.communityFeed(
        lat: lat,
        lng: lng,
        category: category,
        query: query,
        pageSize: pageSize,
      );

  @override
  ExperienceFeedPager hostFeed(String hostId, {int pageSize = 20}) =>
      _remote.hostFeed(hostId, pageSize: pageSize);

  @override
  ExperienceFeedPager communityExperiences(String communityId,
          {int pageSize = 20}) =>
      _remote.communityExperiences(communityId, pageSize: pageSize);

  @override
  Future<List<UserExperience>> hostCommunityDrafts(
          String communityId, String hostId) =>
      _remote.hostCommunityDrafts(communityId, hostId);

  @override
  Future<Either<Failure, UserExperience?>> getExperience(String id) =>
      _guard(() => _remote.get(id));

  @override
  Future<Either<Failure, int>> countHostExperiences(String hostId) =>
      _guard(() => _remote.countByHost(hostId));

  @override
  Future<Either<Failure, String>> createExperience(UserExperience draft) =>
      _guard(() => _remote.create(draft));

  @override
  Future<Either<Failure, bool>> updateExperience(
    UserExperience experience, {
    bool publish = false,
    bool wasPublished = false,
  }) =>
      _guard(() => _remote.update(experience,
          publish: publish, wasPublished: wasPublished));

  @override
  Future<Either<Failure, void>> publishExperience(String id,
          {bool asFree = false}) =>
      _guard(() => _remote.publish(id, asFree: asFree));

  @override
  Future<Either<Failure, void>> acceptHostAgreement(int version) =>
      _guard(() => _remote.acceptHostAgreement(version));

  @override
  Future<Either<Failure, void>> recordBookingConsent({
    required String experienceId,
    required String uid,
    required CancellationPolicy policy,
    required int version,
    required PaymentMethod method,
  }) =>
      _guard(() => _remote.recordBookingConsent(
          experienceId: experienceId,
          uid: uid,
          policy: policy,
          version: version,
          method: method));

  @override
  Future<Either<Failure, void>> setStatus(String id, ExperienceStatus status) =>
      _guard(() => _remote.setStatus(id, status));

  @override
  Future<Either<Failure, void>> deleteExperience(String id) =>
      _guard(() => _remote.delete(id));

  @override
  Future<Either<Failure, void>> reportExperience({
    required UserExperience experience,
    required String reporterId,
    String reason = 'other',
    String details = '',
  }) {
    final d = details.trim();
    return _guard(() => _remote.report({
          'type': 'user_experience',
          'experienceId': experience.id,
          'hostId': experience.hostId,
          'experienceTitle': experience.title,
          'reporterId': reporterId,
          'reason': reason,
          if (d.isNotEmpty) 'details': d.length > 1000 ? d.substring(0, 1000) : d,
        }));
  }

  @override
  Future<Either<Failure, ExperiencePage<ExperienceReview>>> getReviews(
    String experienceId, {
    Object? cursor,
    int limit = 10,
  }) =>
      _guard(() => _remote.reviews(experienceId, cursor: cursor, limit: limit));

  @override
  Future<Either<Failure, ExperienceReview?>> getMyReview(
          String experienceId, String uid) =>
      _guard(() => _remote.myReview(experienceId, uid));

  @override
  Future<Either<Failure, void>> saveReview({
    required String experienceId,
    required String uid,
    required int rating,
    required String comment,
    required bool isNew,
  }) =>
      _guard(() => _remote.saveReview(
            experienceId: experienceId,
            uid: uid,
            rating: rating,
            comment: comment,
            isNew: isNew,
          ));

  @override
  Future<Either<Failure, void>> deleteReview(String experienceId, String uid) =>
      _guard(() => _remote.deleteReview(experienceId, uid));

  @override
  Future<Either<Failure, ReviewEligibility?>> getReviewEligibility(
          String experienceId, String uid) =>
      _guard(() => _remote.reviewEligibility(experienceId, uid));

  @override
  Future<Either<Failure, PendingReview?>> getPendingReview(
          String experienceId, String uid) =>
      _guard(() => _remote.pendingReview(experienceId, uid));

  @override
  Future<Either<Failure, void>> savePendingReview({
    required String experienceId,
    required String uid,
    required String bookingId,
    required int rating,
    required String comment,
    required bool isNew,
  }) =>
      _guard(() => _remote.savePendingReview(
            experienceId: experienceId,
            uid: uid,
            bookingId: bookingId,
            rating: rating,
            comment: comment,
            isNew: isNew,
          ));

  @override
  Future<Either<Failure, void>> deletePendingReview(
          String experienceId, String uid) =>
      _guard(() => _remote.deletePendingReview(experienceId, uid));

  @override
  Future<Either<Failure, void>> reportReview({
    required ExperienceReview review,
    required String reporterId,
  }) =>
      _guard(() => _remote.report({
            'type': 'user_experience_review',
            'experienceId': review.experienceId,
            'reviewAuthorId': review.authorId,
            'comment': review.comment.length > 300
                ? review.comment.substring(0, 300)
                : review.comment,
            'reporterId': reporterId,
          }));

  @override
  Future<Either<Failure, ExperiencePage<ExperienceReply>>> getReplies(
    String experienceId,
    String reviewId, {
    Object? cursor,
    int limit = 10,
  }) =>
      _guard(() => _remote.replies(experienceId, reviewId,
          cursor: cursor, limit: limit));

  @override
  Future<Either<Failure, ExperienceReply>> addReply({
    required String experienceId,
    required String reviewId,
    required String authorId,
    required String text,
    required List<String> mentions,
  }) =>
      _guard(() => _remote.addReply(
            experienceId: experienceId,
            reviewId: reviewId,
            authorId: authorId,
            text: text,
            mentions: mentions,
          ));

  @override
  Future<Either<Failure, void>> deleteReply(
          String experienceId, String reviewId, String replyId) =>
      _guard(() => _remote.deleteReply(experienceId, reviewId, replyId));

  @override
  Stream<ReviewStatus> watchReplyStatus(
          String experienceId, String reviewId, String replyId) =>
      _remote.watchReplyStatus(experienceId, reviewId, replyId);
}
