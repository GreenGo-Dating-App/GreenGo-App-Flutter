import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/user_directory_service.dart';
import '../../../../core/widgets/translatable_text.dart';
import '../../../../core/widgets/verified_badge.dart';
import '../../../../generated/app_localizations.dart';
import '../../../discovery/presentation/screens/profile_detail_screen.dart';
import '../../../profile/data/datasources/profile_remote_data_source.dart';
import '../../domain/entities/experience_review.dart';
import '../../domain/entities/user_experience.dart';
import '../../domain/experience_validation.dart';
import '../../domain/mention_parser.dart';
import '../../domain/review_moderation.dart';
import '../bloc/experience_reviews_bloc.dart';
import '../experience_l10n.dart';
import 'experience_widgets.dart';
import 'reply_composer.dart';

/// Opens [uid]'s profile (never for the viewer themself).
Future<void> openExperienceUserProfile(
    BuildContext context, String uid, String currentUserId) async {
  if (uid.isEmpty || uid == currentUserId) return;
  try {
    final profile = await di.sl<ProfileRemoteDataSource>().getProfile(uid);
    if (!context.mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) =>
          ProfileDetailScreen(profile: profile, currentUserId: currentUserId),
    ));
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.attendeesProfileFailed)));
  }
}

/// Rating summary + "Write a review" + reviews (10 per page, newest first)
/// with replies (first 3, then "Show more replies") and '@' mentions.
/// Requires an [ExperienceReviewsBloc] above it.
class ExperienceReviewsSection extends StatefulWidget {
  const ExperienceReviewsSection({
    super.key,
    required this.experience,
    required this.currentUserId,
    this.onReviewChanged,
  });

  final UserExperience experience;
  final String currentUserId;

  /// Called after the viewer saved/deleted their review (aggregates are
  /// recomputed server-side; the parent may refresh the experience).
  final VoidCallback? onReviewChanged;

  @override
  State<ExperienceReviewsSection> createState() =>
      _ExperienceReviewsSectionState();
}

class _ExperienceReviewsSectionState extends State<ExperienceReviewsSection> {
  /// Review the reply composer is open under (null = closed).
  String? _replyingTo;
  MentionCandidate? _replyMention;

  bool get _isHost => widget.experience.hostId == widget.currentUserId;

  String get _lang => Localizations.localeOf(context).languageCode;

  // ───────────────────────────────────────────── review editor

  /// [rating] / [comment]: the review being edited (published or blind).
  Future<void> _openReviewEditor({int? rating, String? comment}) async {
    final l = AppLocalizations.of(context)!;
    final bloc = context.read<ExperienceReviewsBloc>();
    final editing = rating != null;
    var stars = rating ?? 0;
    final ctrl = TextEditingController(text: comment ?? '');
    String? error;
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(editing ? l.uexpEditReview : l.uexpWriteReview,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(l.uexpYourRating,
                  style: const TextStyle(color: AppColors.textSecondary)),
              Center(
                child: StarRatingInput(
                  value: stars,
                  onChanged: (v) => setSheet(() {
                    stars = v;
                    error = null;
                  }),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: ctrl,
                minLines: 3,
                maxLines: 6,
                maxLength: ExperienceLimits.reviewMax,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: l.uexpCommentHint,
                  hintStyle: const TextStyle(color: AppColors.textTertiary),
                  errorText: error,
                  filled: true,
                  fillColor: AppColors.backgroundInput,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.richGold,
                  foregroundColor: AppColors.deepBlack,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  if (stars < 1) {
                    setSheet(() => error = l.uexpSelectRating);
                    return;
                  }
                  final v = ReviewModeration.check(ctrl.text,
                      maxLength: ExperienceLimits.reviewMax, allowEmpty: true);
                  final msg = switch (v) {
                    CommentVerdict.ok || CommentVerdict.empty => null,
                    CommentVerdict.tooLong =>
                      l.uexpErrTooLong(ExperienceLimits.reviewMax),
                    CommentVerdict.prohibited => l.uexpErrProhibited,
                    CommentVerdict.containsLink => l.uexpErrNoLinks,
                    CommentVerdict.contactInfo => l.uexpErrContactInfo,
                  };
                  if (msg != null) {
                    setSheet(() => error = msg);
                    return;
                  }
                  Navigator.pop(ctx, true);
                },
                child: Text(l.uexpSubmit),
              ),
            ],
          ),
        ),
      ),
    );
    final text = ctrl.text;
    // The sheet's TextField is still animating out; dispose afterwards.
    Future<void>.delayed(const Duration(seconds: 1), ctrl.dispose);
    if (submitted == true && mounted) {
      bloc.add(ReviewSubmitted(rating: stars, comment: text));
    }
  }

  Future<void> _confirmDeleteReview() async {
    final l = AppLocalizations.of(context)!;
    final bloc = context.read<ExperienceReviewsBloc>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(l.uexpDeleteReviewConfirm,
            style: const TextStyle(color: AppColors.textPrimary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.uexpDelete,
                style: const TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
    if (ok == true) bloc.add(const ReviewDeleteRequested());
  }

  // ───────────────────────────────────────────── replies

  Future<void> _startReply(ExperienceReview review,
      {String? toUid}) async {
    // Make sure the names of everyone in the thread are known for '@'.
    final s = context.read<ExperienceReviewsBloc>().state;
    final uids = _threadUids(review, s);
    await UserDirectoryService.instance.resolve(uids);
    if (!mounted) return;
    final target = toUid ?? review.authorId;
    setState(() {
      _replyingTo = review.id;
      _replyMention = target == widget.currentUserId
          ? null
          : MentionCandidate(
              uid: target,
              name: UserDirectoryService.instance.nameFor(target));
    });
  }

  List<String> _threadUids(ExperienceReview review, ExperienceReviewsState s) =>
      {
        review.authorId,
        widget.experience.hostId,
        for (final r in s.replies[review.id] ?? const <ExperienceReply>[])
          r.authorId,
      }.toList();

  List<MentionCandidate> _candidates(
      ExperienceReview review, ExperienceReviewsState s) {
    final dir = UserDirectoryService.instance;
    return [
      for (final uid in _threadUids(review, s))
        if (dir.nameFor(uid).trim().isNotEmpty)
          MentionCandidate(uid: uid, name: dir.nameFor(uid).trim()),
    ];
  }

  // ───────────────────────────────────────────── build

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocConsumer<ExperienceReviewsBloc, ExperienceReviewsState>(
      listenWhen: (a, b) => a.flashSeq != b.flashSeq,
      listener: (context, s) {
        final msg = switch (s.flash) {
          ReviewsFlash.none => null,
          ReviewsFlash.reviewSaved => l.uexpReviewSaved,
          ReviewsFlash.reviewDeleted => l.uexpReviewDeleted,
          ReviewsFlash.replyRejected => l.uexpReplyRemoved,
          ReviewsFlash.reported => l.uexpReported,
          ReviewsFlash.failed => l.somethingWentWrong,
          ReviewsFlash.reviewHeld => l.bkReviewHeld,
          ReviewsFlash.notEligible => l.bkReviewNeedsBooking,
        };
        if (msg != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(msg),
            backgroundColor: s.flash == ReviewsFlash.failed ||
                    s.flash == ReviewsFlash.replyRejected
                ? AppColors.errorRed
                : (s.flash == ReviewsFlash.notEligible
                    ? AppColors.backgroundCard
                    : AppColors.successGreen),
          ));
        }
        if (s.flash == ReviewsFlash.reviewSaved ||
            s.flash == ReviewsFlash.reviewDeleted ||
            s.flash == ReviewsFlash.reviewHeld) {
          widget.onReviewChanged?.call();
        }
      },
      builder: (context, s) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.uexpReviews,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _summary(l),
            const SizedBox(height: 12),
            if (_isHost)
              Text(l.uexpHostCannotReview,
                  style: const TextStyle(
                      color: AppColors.textTertiary, fontSize: 12))
            else if (s.canWriteAt(DateTime.now()) && !s.loading)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.richGold,
                  side: const BorderSide(color: AppColors.richGold),
                ),
                onPressed: s.submitting ? null : () => _openReviewEditor(),
                icon: const Icon(Icons.rate_review_outlined),
                label: Text(l.uexpWriteReview),
              )
            else if (s.myReview == null &&
                s.pendingReview == null &&
                !s.loading)
              // Reviews need a real booking (checked in / completed).
              Row(children: [
                const Icon(Icons.lock_outline,
                    size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(l.bkReviewNeedsBooking,
                      style: const TextStyle(
                          color: AppColors.textTertiary, fontSize: 12)),
                ),
              ]),
            if (s.loading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                    child: CircularProgressIndicator(color: AppColors.richGold)),
              ),
            if (s.myReview != null) ...[
              const SizedBox(height: 8),
              _reviewTile(s.myReview!, s, mine: true),
            ] else if (s.pendingReview != null) ...[
              const SizedBox(height: 8),
              _pendingTile(s.pendingReview!, s),
            ],
            for (final r in s.reviews) _reviewTile(r, s),
            if (!s.loading &&
                s.reviews.isEmpty &&
                s.myReview == null &&
                s.pendingReview == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(l.uexpNoReviews,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textTertiary)),
              ),
            if (s.hasMore)
              Center(
                child: s.loadingMore
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                            color: AppColors.richGold),
                      )
                    : TextButton(
                        onPressed: () => context
                            .read<ExperienceReviewsBloc>()
                            .add(const ReviewsMoreRequested()),
                        child: Text(l.uexpLoadMoreReviews,
                            style: const TextStyle(color: AppColors.richGold)),
                      ),
              ),
          ],
        );
      },
    );
  }

  Widget _summary(AppLocalizations l) {
    final e = widget.experience;
    final total = e.ratingCount;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.richGold.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(total == 0 ? '–' : e.averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 34,
                      fontWeight: FontWeight.bold)),
              StarRatingDisplay(rating: e.averageRating, size: 16),
              const SizedBox(height: 4),
              Text(l.uexpReviewsCount(total),
                  style: const TextStyle(
                      color: AppColors.textTertiary, fontSize: 12)),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              children: [
                for (var star = 5; star >= 1; star--)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(children: [
                      SizedBox(
                        width: 14,
                        child: Text('$star',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                      ),
                      const Icon(Icons.star_rounded,
                          size: 12, color: AppColors.richGold),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            minHeight: 6,
                            value: total == 0
                                ? 0
                                : ((e.ratingDist[star] ?? 0) / total)
                                    .clamp(0.0, 1.0),
                            backgroundColor: AppColors.backgroundInput,
                            color: AppColors.richGold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 28,
                        child: Text('${e.ratingDist[star] ?? 0}',
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                                color: AppColors.textTertiary, fontSize: 11)),
                      ),
                    ]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewTile(ExperienceReview r, ExperienceReviewsState s,
      {bool mine = false}) {
    final l = AppLocalizations.of(context)!;
    final bloc = context.read<ExperienceReviewsBloc>();
    final replies = s.replies[r.id] ?? const <ExperienceReply>[];
    final isAuthorHost = r.authorId == widget.experience.hostId;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: mine
            ? Border.all(color: AppColors.richGold.withValues(alpha: 0.4))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: UserNameAvatar(
                uid: r.authorId,
                onTap: () => openExperienceUserProfile(
                    context, r.authorId, widget.currentUserId),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  UserVerifiedBadge(
                      uid: r.authorId, size: 14, padding: EdgeInsets.zero),
                  if (isAuthorHost) ...[
                    const SizedBox(width: 4),
                    _hostBadge(l),
                  ],
                ]),
              ),
            ),
            Text(
              [
                ExperienceL10n.date(context, r.createdAt),
                if (r.isEdited) l.uexpEdited,
              ].where((x) => x.isNotEmpty).join(' · '),
              style:
                  const TextStyle(color: AppColors.textTertiary, fontSize: 11),
            ),
            _reviewMenu(r, mine: mine),
          ]),
          const SizedBox(height: 6),
          StarRatingDisplay(rating: r.rating.toDouble()),
          if (mine && r.isRejected) ...[
            const SizedBox(height: 6),
            _notice(l.uexpReviewRemoved),
          ] else if (mine && r.status == ReviewStatus.pending) ...[
            const SizedBox(height: 4),
            Text(l.uexpPendingModeration,
                style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                    fontStyle: FontStyle.italic)),
          ],
          if (r.comment.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            TranslatableText(
              text: r.comment,
              autoTranslate: true,
              targetLang: _lang,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13, height: 1.4),
            ),
          ],
          if (!r.isRejected)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.richGold,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
                onPressed: () => _startReply(r),
                icon: const Icon(Icons.reply, size: 16),
                label: Text(l.uexpReply),
              ),
            ),
          if (replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final rep in replies) _replyTile(r, rep),
                ],
              ),
            ),
          if (s.repliesHasMore[r.id] == true)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: s.repliesLoading.contains(r.id)
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.richGold)),
                    )
                  : TextButton(
                      style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact),
                      onPressed: () => bloc.add(RepliesRequested(r.id)),
                      child: Text(l.uexpShowMoreReplies,
                          style: const TextStyle(
                              color: AppColors.richGold, fontSize: 12)),
                    ),
            ),
          if (_replyingTo == r.id)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ReplyComposer(
                key: ValueKey('composer_${r.id}_${_replyMention?.uid}'),
                candidates: _candidates(r, s),
                currentUserId: widget.currentUserId,
                initialMention: _replyMention,
                busy: s.submitting,
                onSend: (text, mentions) {
                  bloc.add(ReplySubmitted(
                      reviewId: r.id, text: text, mentions: mentions));
                  setState(() => _replyingTo = null);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _replyTile(ExperienceReview review, ExperienceReply rep) {
    final l = AppLocalizations.of(context)!;
    final mine = rep.authorId == widget.currentUserId;
    // Others never see rejected replies (the query filters them); the author
    // sees a notice in place of their removed reply.
    if (rep.isRejected && !mine) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: UserNameAvatar(
                uid: rep.authorId,
                radius: 11,
                textStyle: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  UserVerifiedBadge(
                      uid: rep.authorId, size: 12, padding: EdgeInsets.zero),
                  if (rep.authorId == widget.experience.hostId) ...[
                    const SizedBox(width: 4),
                    _hostBadge(l),
                  ],
                ]),
                onTap: () => openExperienceUserProfile(
                    context, rep.authorId, widget.currentUserId),
              ),
            ),
            Text(ExperienceL10n.date(context, rep.createdAt),
                style: const TextStyle(
                    color: AppColors.textTertiary, fontSize: 10)),
            if (mine)
              IconButton(
                visualDensity: VisualDensity.compact,
                iconSize: 16,
                tooltip: l.uexpDelete,
                onPressed: () => context
                    .read<ExperienceReviewsBloc>()
                    .add(ReplyDeleteRequested(review.id, rep.id)),
                icon: const Icon(Icons.delete_outline,
                    color: AppColors.textTertiary),
              )
            else
              IconButton(
                visualDensity: VisualDensity.compact,
                iconSize: 16,
                tooltip: l.uexpReply,
                onPressed: () => _startReply(review, toUid: rep.authorId),
                icon: const Icon(Icons.reply, color: AppColors.textTertiary),
              ),
          ]),
          const SizedBox(height: 2),
          if (rep.isRejected)
            _notice(l.uexpReplyRemoved)
          else
            MentionText(
              text: rep.text,
              mentions: rep.mentions,
              autoTranslate: true,
              targetLang: _lang,
            ),
          if (mine && rep.status == ReviewStatus.pending)
            Text(l.uexpPendingModeration,
                style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 10,
                    fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _reviewMenu(ExperienceReview r, {required bool mine}) {
    final l = AppLocalizations.of(context)!;
    final bloc = context.read<ExperienceReviewsBloc>();
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textTertiary),
      color: AppColors.backgroundCard,
      onSelected: (v) {
        switch (v) {
          case 'edit':
            _openReviewEditor(rating: r.rating, comment: r.comment);
          case 'delete':
            _confirmDeleteReview();
          case 'report':
            bloc.add(ReviewReported(r));
        }
      },
      itemBuilder: (_) => [
        if (mine) ...[
          PopupMenuItem(
              value: 'edit',
              child: Text(l.uexpEdit,
                  style: const TextStyle(color: AppColors.textPrimary))),
          PopupMenuItem(
              value: 'delete',
              child: Text(l.uexpDeleteReview,
                  style: const TextStyle(color: AppColors.errorRed))),
        ] else
          PopupMenuItem(
              value: 'report',
              child: Text(l.uexpReportReview,
                  style: const TextStyle(color: AppColors.textPrimary))),
      ],
    );
  }

  /// The caller's blind review, waiting for the host's review of them (or
  /// the 14-day reveal).
  Widget _pendingTile(PendingReview r, ExperienceReviewsState s) {
    final l = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.richGold.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: UserNameAvatar(
                uid: r.authorId,
                trailing: UserVerifiedBadge(
                    uid: r.authorId, size: 14, padding: EdgeInsets.zero),
              ),
            ),
            Text(ExperienceL10n.date(context, r.createdAt),
                style: const TextStyle(
                    color: AppColors.textTertiary, fontSize: 11)),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert,
                  size: 18, color: AppColors.textTertiary),
              color: AppColors.backgroundCard,
              enabled: !s.submitting,
              onSelected: (v) {
                if (v == 'edit') {
                  _openReviewEditor(rating: r.rating, comment: r.comment);
                } else if (v == 'delete') {
                  _confirmDeleteReview();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                    value: 'edit',
                    child: Text(l.uexpEdit,
                        style: const TextStyle(color: AppColors.textPrimary))),
                PopupMenuItem(
                    value: 'delete',
                    child: Text(l.uexpDeleteReview,
                        style: const TextStyle(color: AppColors.errorRed))),
              ],
            ),
          ]),
          const SizedBox(height: 6),
          StarRatingDisplay(rating: r.rating.toDouble()),
          if (r.comment.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(r.comment,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
          ],
          const SizedBox(height: 8),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.visibility_off_outlined,
                size: 15, color: AppColors.richGold),
            const SizedBox(width: 6),
            Expanded(
              child: Text(l.bkReviewHeld,
                  style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                      fontStyle: FontStyle.italic)),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _hostBadge(AppLocalizations l) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: AppColors.richGold.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(l.uexpHostBadge,
            style: const TextStyle(
                color: AppColors.richGold,
                fontSize: 10,
                fontWeight: FontWeight.bold)),
      );

  Widget _notice(String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.errorRed.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.4)),
        ),
        child: Row(children: [
          const Icon(Icons.gpp_bad_outlined,
              size: 16, color: AppColors.errorRed),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ),
        ]),
      );
}
