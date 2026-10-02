import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/error/failures.dart';
import 'package:greengo_chat/features/user_experiences/domain/entities/experience_review.dart';
import 'package:greengo_chat/features/user_experiences/domain/repositories/user_experiences_repository.dart';
import 'package:greengo_chat/features/user_experiences/presentation/bloc/experience_reviews_bloc.dart';

class _Repo extends Fake implements UserExperiencesRepository {
  _Repo({this.eligibility, this.pending, this.mine});
  ReviewEligibility? eligibility;
  PendingReview? pending;
  ExperienceReview? mine;
  final List<String> writes = [];

  @override
  Future<Either<Failure, ExperiencePage<ExperienceReview>>> getReviews(
    String experienceId, {
    Object? cursor,
    int limit = 10,
  }) async =>
      const Right(ExperiencePage(items: [], hasMore: false));

  @override
  Future<Either<Failure, ExperienceReview?>> getMyReview(
          String experienceId, String uid) async =>
      Right(mine);

  @override
  Future<Either<Failure, ReviewEligibility?>> getReviewEligibility(
          String experienceId, String uid) async =>
      Right(eligibility);

  @override
  Future<Either<Failure, PendingReview?>> getPendingReview(
          String experienceId, String uid) async =>
      Right(pending);

  @override
  Future<Either<Failure, void>> savePendingReview({
    required String experienceId,
    required String uid,
    required String bookingId,
    required int rating,
    required String comment,
    required bool isNew,
  }) async {
    writes.add('pending:${isNew ? 'create' : 'update'}:$bookingId:$rating');
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> saveReview({
    required String experienceId,
    required String uid,
    required int rating,
    required String comment,
    required bool isNew,
  }) async {
    writes.add('public:${isNew ? 'create' : 'update'}:$rating');
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> deletePendingReview(
      String experienceId, String uid) async {
    writes.add('pending:delete');
    return const Right(null);
  }

  @override
  Future<Either<Failure, ExperiencePage<ExperienceReply>>> getReplies(
    String experienceId,
    String reviewId, {
    Object? cursor,
    int limit = 10,
  }) async =>
      const Right(ExperiencePage(items: [], hasMore: false));
}

Future<void> settle() async {
  for (var i = 0; i < 6; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  final future = DateTime.now().add(const Duration(days: 20));

  Future<ExperienceReviewsBloc> start(_Repo repo) async {
    final bloc = ExperienceReviewsBloc(repository: repo)
      ..add(const ReviewsStarted(experienceId: 'e1', uid: 'guest'));
    await settle();
    return bloc;
  }

  test('no completed booking: cannot write, submit is refused', () async {
    final repo = _Repo();
    final bloc = await start(repo);
    expect(bloc.state.canWriteAt(DateTime.now()), isFalse);
    bloc.add(const ReviewSubmitted(rating: 5, comment: 'Great'));
    await settle();
    expect(bloc.state.flash, ReviewsFlash.notEligible);
    expect(repo.writes, isEmpty, reason: 'never a direct reviews/{uid} create');
    await bloc.close();
  });

  test('eligible guest writes a BLIND pending review for that booking',
      () async {
    final repo = _Repo(
        eligibility: ReviewEligibility(bookingId: 'bk_7', reviewUntil: future));
    final bloc = await start(repo);
    expect(bloc.state.canWriteAt(DateTime.now()), isTrue);
    bloc.add(const ReviewSubmitted(rating: 4, comment: 'Lovely evening'));
    await settle();
    expect(repo.writes, ['pending:create:bk_7:4']);
    expect(bloc.state.flash, ReviewsFlash.reviewHeld);
    expect(bloc.state.pendingReview?.bookingId, 'bk_7');
    expect(bloc.state.canWriteAt(DateTime.now()), isFalse);

    // Editing the held review updates it in place.
    bloc.add(const ReviewSubmitted(rating: 5, comment: 'Even better'));
    await settle();
    expect(repo.writes.last, 'pending:update:bk_7:5');

    bloc.add(const ReviewDeleteRequested());
    await settle();
    expect(repo.writes.last, 'pending:delete');
    expect(bloc.state.pendingReview, isNull);
    await bloc.close();
  });

  test('a held review is shown (not a second Write button)', () async {
    final repo = _Repo(
      eligibility: ReviewEligibility(bookingId: 'bk_7', reviewUntil: future),
      pending: const PendingReview(
          experienceId: 'e1',
          authorId: 'guest',
          bookingId: 'bk_7',
          rating: 5,
          comment: 'Wow'),
    );
    final bloc = await start(repo);
    expect(bloc.state.pendingReview?.rating, 5);
    expect(bloc.state.canWriteAt(DateTime.now()), isFalse);
    await bloc.close();
  });

  test('expired eligibility window: cannot write', () async {
    final repo = _Repo(
        eligibility: ReviewEligibility(
            bookingId: 'bk_7',
            reviewUntil: DateTime.now().subtract(const Duration(minutes: 1))));
    final bloc = await start(repo);
    expect(bloc.state.canWriteAt(DateTime.now()), isFalse);
    await bloc.close();
  });

  test('a published review is still edited in place', () async {
    final repo = _Repo(
      mine: const ExperienceReview(
          experienceId: 'e1',
          authorId: 'guest',
          rating: 3,
          comment: 'ok',
          status: ReviewStatus.visible),
    );
    final bloc = await start(repo);
    bloc.add(const ReviewSubmitted(rating: 4, comment: 'better'));
    await settle();
    expect(repo.writes, ['public:update:4']);
    await bloc.close();
  });
}
