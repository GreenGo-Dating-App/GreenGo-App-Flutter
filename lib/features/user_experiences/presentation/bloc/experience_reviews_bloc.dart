import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/experience_review.dart';
import '../../domain/repositories/user_experiences_repository.dart';

// ───────────────────────────────────────────────────────────── events

abstract class ExperienceReviewsEvent extends Equatable {
  const ExperienceReviewsEvent();
  @override
  List<Object?> get props => [];
}

class ReviewsStarted extends ExperienceReviewsEvent {
  const ReviewsStarted({required this.experienceId, required this.uid});
  final String experienceId;
  final String uid;
  @override
  List<Object?> get props => [experienceId, uid];
}

class ReviewsMoreRequested extends ExperienceReviewsEvent {
  const ReviewsMoreRequested();
}

class ReviewSubmitted extends ExperienceReviewsEvent {
  const ReviewSubmitted({required this.rating, required this.comment});
  final int rating;
  final String comment;
  @override
  List<Object?> get props => [rating, comment];
}

class ReviewDeleteRequested extends ExperienceReviewsEvent {
  const ReviewDeleteRequested();
}

class ReviewReported extends ExperienceReviewsEvent {
  const ReviewReported(this.review);
  final ExperienceReview review;
  @override
  List<Object?> get props => [review];
}

/// Next page of replies under [reviewId] (first page = first 3).
class RepliesRequested extends ExperienceReviewsEvent {
  const RepliesRequested(this.reviewId);
  final String reviewId;
  @override
  List<Object?> get props => [reviewId];
}

class ReplySubmitted extends ExperienceReviewsEvent {
  const ReplySubmitted({
    required this.reviewId,
    required this.text,
    required this.mentions,
  });
  final String reviewId;
  final String text;
  final List<String> mentions;
  @override
  List<Object?> get props => [reviewId, text, mentions];
}

class ReplyDeleteRequested extends ExperienceReviewsEvent {
  const ReplyDeleteRequested(this.reviewId, this.replyId);
  final String reviewId;
  final String replyId;
  @override
  List<Object?> get props => [reviewId, replyId];
}

class _ReplyStatusArrived extends ExperienceReviewsEvent {
  const _ReplyStatusArrived(this.reviewId, this.replyId, this.status);
  final String reviewId;
  final String replyId;
  final ReviewStatus status;
  @override
  List<Object?> get props => [reviewId, replyId, status];
}

class _MyReviewRefreshed extends ExperienceReviewsEvent {
  const _MyReviewRefreshed();
}

// ───────────────────────────────────────────────────────────── state

/// One-shot outcomes for snackbars.
enum ReviewsFlash { none, reviewSaved, reviewDeleted, replyRejected, reported, failed }

class ExperienceReviewsState extends Equatable {
  const ExperienceReviewsState({
    this.loading = true,
    this.reviews = const [],
    this.myReview,
    this.hasMore = false,
    this.loadingMore = false,
    this.submitting = false,
    this.replies = const {},
    this.repliesHasMore = const {},
    this.repliesLoading = const {},
    this.flash = ReviewsFlash.none,
    this.flashSeq = 0,
  });

  final bool loading;

  /// Visible reviews of OTHER people, newest first (the caller's own review
  /// is [myReview], always shown on top — including when rejected).
  final List<ExperienceReview> reviews;
  final ExperienceReview? myReview;
  final bool hasMore;
  final bool loadingMore;
  final bool submitting;

  /// reviewId → replies loaded so far (oldest first), plus the caller's own
  /// just-posted ones (pending / rejected are only ever the caller's).
  final Map<String, List<ExperienceReply>> replies;
  final Map<String, bool> repliesHasMore;
  final Set<String> repliesLoading;

  final ReviewsFlash flash;
  final int flashSeq;

  ExperienceReviewsState copyWith({
    bool? loading,
    List<ExperienceReview>? reviews,
    ExperienceReview? myReview,
    bool clearMyReview = false,
    bool? hasMore,
    bool? loadingMore,
    bool? submitting,
    Map<String, List<ExperienceReply>>? replies,
    Map<String, bool>? repliesHasMore,
    Set<String>? repliesLoading,
    ReviewsFlash? flash,
  }) =>
      ExperienceReviewsState(
        loading: loading ?? this.loading,
        reviews: reviews ?? this.reviews,
        myReview: clearMyReview ? null : (myReview ?? this.myReview),
        hasMore: hasMore ?? this.hasMore,
        loadingMore: loadingMore ?? this.loadingMore,
        submitting: submitting ?? this.submitting,
        replies: replies ?? this.replies,
        repliesHasMore: repliesHasMore ?? this.repliesHasMore,
        repliesLoading: repliesLoading ?? this.repliesLoading,
        flash: flash ?? ReviewsFlash.none,
        flashSeq: flash != null ? flashSeq + 1 : flashSeq,
      );

  @override
  List<Object?> get props => [
        loading,
        reviews,
        myReview,
        hasMore,
        loadingMore,
        submitting,
        replies,
        repliesHasMore,
        repliesLoading,
        flash,
        flashSeq,
      ];
}

// ───────────────────────────────────────────────────────────── bloc

class ExperienceReviewsBloc
    extends Bloc<ExperienceReviewsEvent, ExperienceReviewsState> {
  ExperienceReviewsBloc({required UserExperiencesRepository repository})
      : _repo = repository,
        super(const ExperienceReviewsState()) {
    on<ReviewsStarted>(_onStarted);
    on<ReviewsMoreRequested>(_onMore);
    on<ReviewSubmitted>(_onSubmit);
    on<ReviewDeleteRequested>(_onDelete);
    on<ReviewReported>(_onReport);
    on<RepliesRequested>(_onReplies);
    on<ReplySubmitted>(_onReply);
    on<ReplyDeleteRequested>(_onReplyDelete);
    on<_ReplyStatusArrived>(_onReplyStatus);
    on<_MyReviewRefreshed>(_onMyReviewRefreshed);
  }

  static const int pageSize = 10;
  static const int firstReplies = 3;
  static const int repliesPage = 10;

  final UserExperiencesRepository _repo;
  String _experienceId = '';
  String _uid = '';
  Object? _cursor;
  final Map<String, Object?> _replyCursors = {};
  final List<StreamSubscription<ReviewStatus>> _subs = [];
  Timer? _myReviewPoll;

  String get uid => _uid;

  Future<void> _onStarted(
      ReviewsStarted e, Emitter<ExperienceReviewsState> emit) async {
    _experienceId = e.experienceId;
    _uid = e.uid;
    _cursor = null;
    _replyCursors.clear();
    emit(const ExperienceReviewsState(loading: true));
    // Both reads in flight at once.
    final pageF = _repo.getReviews(_experienceId, limit: pageSize);
    final mineF = _repo.getMyReview(_experienceId, _uid);
    final page = (await pageF).fold((_) => null, (p) => p);
    final mine = (await mineF).fold((_) => null, (r) => r);
    _cursor = page?.cursor;
    final others =
        (page?.items ?? const <ExperienceReview>[]).where((r) => r.authorId != _uid).toList();
    emit(state.copyWith(
      loading: false,
      reviews: others,
      myReview: mine,
      clearMyReview: mine == null,
      hasMore: page?.hasMore ?? false,
    ));
    await _loadFirstReplies([if (mine != null) mine, ...others], emit);
  }

  Future<void> _loadFirstReplies(
      List<ExperienceReview> reviews, Emitter<ExperienceReviewsState> emit) async {
    if (reviews.isEmpty) return;
    final pages = await Future.wait(reviews.map((r) => _repo
        .getReplies(_experienceId, r.id, limit: firstReplies)
        .then((x) => x.fold((_) => null, (p) => p))));
    final replies = {...state.replies};
    final more = {...state.repliesHasMore};
    for (var i = 0; i < reviews.length; i++) {
      final p = pages[i];
      if (p == null) continue;
      replies[reviews[i].id] = p.items;
      more[reviews[i].id] = p.hasMore;
      _replyCursors[reviews[i].id] = p.cursor;
    }
    emit(state.copyWith(replies: replies, repliesHasMore: more));
  }

  Future<void> _onMore(
      ReviewsMoreRequested e, Emitter<ExperienceReviewsState> emit) async {
    if (state.loadingMore || !state.hasMore) return;
    emit(state.copyWith(loadingMore: true));
    final r = await _repo.getReviews(_experienceId,
        cursor: _cursor, limit: pageSize);
    await r.fold(
      (_) async => emit(state.copyWith(loadingMore: false)),
      (p) async {
        _cursor = p.cursor;
        final known = state.reviews.map((x) => x.id).toSet();
        final fresh = p.items
            .where((x) => x.authorId != _uid && !known.contains(x.id))
            .toList();
        emit(state.copyWith(
          loadingMore: false,
          reviews: [...state.reviews, ...fresh],
          hasMore: p.hasMore,
        ));
        await _loadFirstReplies(fresh, emit);
      },
    );
  }

  Future<void> _onSubmit(
      ReviewSubmitted e, Emitter<ExperienceReviewsState> emit) async {
    if (state.submitting) return;
    emit(state.copyWith(submitting: true));
    final isNew = state.myReview == null;
    final r = await _repo.saveReview(
      experienceId: _experienceId,
      uid: _uid,
      rating: e.rating,
      comment: e.comment.trim(),
      isNew: isNew,
    );
    r.fold(
      (_) => emit(state.copyWith(submitting: false, flash: ReviewsFlash.failed)),
      (_) {
        final now = DateTime.now();
        emit(state.copyWith(
          submitting: false,
          flash: ReviewsFlash.reviewSaved,
          myReview: ExperienceReview(
            experienceId: _experienceId,
            authorId: _uid,
            rating: e.rating,
            comment: e.comment.trim(),
            createdAt: state.myReview?.createdAt ?? now,
            updatedAt: now,
            status: ReviewStatus.pending,
          ),
        ));
        // Pick up the server's moderation verdict shortly after.
        _myReviewPoll?.cancel();
        _myReviewPoll = Timer(const Duration(seconds: 4), () {
          if (!isClosed) add(const _MyReviewRefreshed());
        });
      },
    );
  }

  Future<void> _onMyReviewRefreshed(
      _MyReviewRefreshed e, Emitter<ExperienceReviewsState> emit) async {
    final r = await _repo.getMyReview(_experienceId, _uid);
    r.fold((_) {}, (mine) {
      if (mine != null) emit(state.copyWith(myReview: mine));
    });
  }

  Future<void> _onDelete(
      ReviewDeleteRequested e, Emitter<ExperienceReviewsState> emit) async {
    if (state.myReview == null || state.submitting) return;
    emit(state.copyWith(submitting: true));
    final r = await _repo.deleteReview(_experienceId, _uid);
    r.fold(
      (_) => emit(state.copyWith(submitting: false, flash: ReviewsFlash.failed)),
      (_) {
        final replies = {...state.replies}..remove(_uid);
        emit(state.copyWith(
          submitting: false,
          clearMyReview: true,
          replies: replies,
          flash: ReviewsFlash.reviewDeleted,
        ));
      },
    );
  }

  Future<void> _onReport(
      ReviewReported e, Emitter<ExperienceReviewsState> emit) async {
    final r = await _repo.reportReview(review: e.review, reporterId: _uid);
    emit(state.copyWith(
        flash: r.isRight() ? ReviewsFlash.reported : ReviewsFlash.failed));
  }

  Future<void> _onReplies(
      RepliesRequested e, Emitter<ExperienceReviewsState> emit) async {
    if (state.repliesLoading.contains(e.reviewId)) return;
    emit(state.copyWith(repliesLoading: {...state.repliesLoading, e.reviewId}));
    final r = await _repo.getReplies(_experienceId, e.reviewId,
        cursor: _replyCursors[e.reviewId], limit: repliesPage);
    final loading = {...state.repliesLoading}..remove(e.reviewId);
    r.fold(
      (_) => emit(state.copyWith(repliesLoading: loading)),
      (p) {
        _replyCursors[e.reviewId] = p.cursor;
        final existing = state.replies[e.reviewId] ?? const <ExperienceReply>[];
        final known = existing.map((x) => x.id).toSet();
        emit(state.copyWith(
          repliesLoading: loading,
          replies: {
            ...state.replies,
            e.reviewId: [
              ...existing,
              ...p.items.where((x) => !known.contains(x.id)),
            ],
          },
          repliesHasMore: {...state.repliesHasMore, e.reviewId: p.hasMore},
        ));
      },
    );
  }

  Future<void> _onReply(
      ReplySubmitted e, Emitter<ExperienceReviewsState> emit) async {
    if (state.submitting) return;
    emit(state.copyWith(submitting: true));
    final r = await _repo.addReply(
      experienceId: _experienceId,
      reviewId: e.reviewId,
      authorId: _uid,
      text: e.text.trim(),
      mentions: e.mentions,
    );
    r.fold(
      (_) => emit(state.copyWith(submitting: false, flash: ReviewsFlash.failed)),
      (reply) {
        emit(state.copyWith(
          submitting: false,
          replies: {
            ...state.replies,
            e.reviewId: [...?state.replies[e.reviewId], reply],
          },
        ));
        // Follow the server's moderation verdict for this reply.
        late final StreamSubscription<ReviewStatus> sub;
        sub = _repo
            .watchReplyStatus(_experienceId, e.reviewId, reply.id)
            .where((s) => s != ReviewStatus.pending)
            .timeout(const Duration(seconds: 30), onTimeout: (sink) => sink.close())
            .listen((s) {
          if (!isClosed) add(_ReplyStatusArrived(e.reviewId, reply.id, s));
          sub.cancel();
        }, onError: (_) => sub.cancel());
        _subs.add(sub);
      },
    );
  }

  void _onReplyStatus(
      _ReplyStatusArrived e, Emitter<ExperienceReviewsState> emit) {
    final list = state.replies[e.reviewId];
    if (list == null) return;
    emit(state.copyWith(
      replies: {
        ...state.replies,
        e.reviewId: [
          for (final r in list) r.id == e.replyId ? r.withStatus(e.status) : r,
        ],
      },
      flash: e.status == ReviewStatus.rejected ? ReviewsFlash.replyRejected : null,
    ));
  }

  Future<void> _onReplyDelete(
      ReplyDeleteRequested e, Emitter<ExperienceReviewsState> emit) async {
    final r = await _repo.deleteReply(_experienceId, e.reviewId, e.replyId);
    r.fold(
      (_) => emit(state.copyWith(flash: ReviewsFlash.failed)),
      (_) => emit(state.copyWith(replies: {
        ...state.replies,
        e.reviewId: [
          for (final x in state.replies[e.reviewId] ?? const <ExperienceReply>[])
            if (x.id != e.replyId) x,
        ],
      })),
    );
  }

  @override
  Future<void> close() {
    for (final s in _subs) {
      s.cancel();
    }
    _myReviewPoll?.cancel();
    return super.close();
  }
}
