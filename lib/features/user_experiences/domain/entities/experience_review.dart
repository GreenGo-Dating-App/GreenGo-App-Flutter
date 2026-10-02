import 'package:equatable/equatable.dart';

/// Moderation state of a review / reply. `pending` = written, not yet checked
/// by the server trigger (only ever seen by the author).
enum ReviewStatus {
  pending,
  visible,
  rejected;

  static ReviewStatus fromWire(Object? v) => ReviewStatus.values
      .firstWhere((s) => s.name == v, orElse: () => ReviewStatus.pending);
}

/// `user_experiences/{experienceId}/reviews/{authorId}` — ONE review per user
/// per experience (the doc id is the reviewer's uid).
class ExperienceReview extends Equatable {
  const ExperienceReview({
    required this.experienceId,
    required this.authorId,
    required this.rating,
    required this.comment,
    this.createdAt,
    this.updatedAt,
    this.status = ReviewStatus.pending,
    this.moderationReason,
  });

  final String experienceId;
  final String authorId;

  /// 1..5 stars.
  final int rating;
  final String comment;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final ReviewStatus status;
  final String? moderationReason;

  String get id => authorId;
  bool get isRejected => status == ReviewStatus.rejected;
  bool get isEdited =>
      createdAt != null &&
      updatedAt != null &&
      updatedAt!.difference(createdAt!).inSeconds > 5;

  @override
  List<Object?> get props => [
        experienceId,
        authorId,
        rating,
        comment,
        createdAt,
        updatedAt,
        status,
        moderationReason,
      ];
}

/// `…/reviews/{reviewId}/replies/{replyId}`.
class ExperienceReply extends Equatable {
  const ExperienceReply({
    required this.id,
    required this.experienceId,
    required this.reviewId,
    required this.authorId,
    required this.text,
    this.mentions = const [],
    this.createdAt,
    this.status = ReviewStatus.pending,
  });

  final String id;
  final String experienceId;
  final String reviewId;
  final String authorId;
  final String text;

  /// Uids tagged with '@' (≤ 10).
  final List<String> mentions;
  final DateTime? createdAt;
  final ReviewStatus status;

  bool get isRejected => status == ReviewStatus.rejected;

  ExperienceReply withStatus(ReviewStatus s) => ExperienceReply(
        id: id,
        experienceId: experienceId,
        reviewId: reviewId,
        authorId: authorId,
        text: text,
        mentions: mentions,
        createdAt: createdAt,
        status: s,
      );

  @override
  List<Object?> get props =>
      [id, experienceId, reviewId, authorId, text, mentions, createdAt, status];
}

/// `user_experiences/{id}/review_eligibility/{guestId}` — server-written once
/// the guest's booking became reviewable (check-in or completion); deleted
/// when a dispute is opened. Only the guest reads it.
class ReviewEligibility extends Equatable {
  const ReviewEligibility({
    required this.bookingId,
    this.hostId,
    this.reviewUntil,
  });

  final String bookingId;
  final String? hostId;
  final DateTime? reviewUntil;

  /// The rules accept a pending review only before [reviewUntil].
  bool isOpenAt(DateTime now) =>
      bookingId.isNotEmpty && (reviewUntil == null || now.isBefore(reviewUntil!));

  @override
  List<Object?> get props => [bookingId, hostId, reviewUntil];
}

/// The guest's BLIND review, `user_experiences/{id}/pending_reviews/{uid}`:
/// only its author can read it; the server publishes it into reviews/{uid}
/// once the host reviewed the guest too, or after 14 days.
class PendingReview extends Equatable {
  const PendingReview({
    required this.experienceId,
    required this.authorId,
    required this.bookingId,
    required this.rating,
    required this.comment,
    this.createdAt,
    this.revealAt,
  });

  final String experienceId;
  final String authorId;
  final String bookingId;
  final int rating;
  final String comment;
  final DateTime? createdAt;

  /// Server field (set by the trigger right after the write).
  final DateTime? revealAt;

  @override
  List<Object?> get props =>
      [experienceId, authorId, bookingId, rating, comment, createdAt, revealAt];
}
