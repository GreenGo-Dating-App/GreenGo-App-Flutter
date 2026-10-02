import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../generated/app_localizations.dart';
import '../../../user_experiences/domain/repositories/user_experiences_repository.dart';
import '../../../user_experiences/domain/review_moderation.dart';
import '../../../user_experiences/presentation/experience_l10n.dart';
import '../../../user_experiences/presentation/screens/experience_detail_screen.dart';
import '../../../user_experiences/presentation/widgets/experience_policy_widgets.dart';
import '../../../user_experiences/presentation/widgets/experience_reviews_section.dart';
import '../../../user_experiences/presentation/widgets/experience_widgets.dart';
import '../../domain/booking_rules.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/bookings_repository.dart';
import '../bloc/booking_detail_bloc.dart';
import '../booking_l10n.dart';
import '../widgets/booking_widgets.dart';
import '../widgets/payment_link_actions.dart';
import 'booking_check_in_scanner_screen.dart';

/// One booking, for its guest or its host: when / where, the other party,
/// payment (link: "Mark as paid"; cash: host "Cash received"), the refund
/// policy with what cancelling NOW would owe, and every action the booking
/// allows at this moment (accept / decline, cancel, check-in QR / scan,
/// no-show, report a problem, review the guest). Pops with the latest
/// [Booking] so lists can patch the row.
class BookingDetailScreen extends StatelessWidget {
  const BookingDetailScreen({
    super.key,
    required this.bookingId,
    required this.currentUserId,
    this.initial,
  });

  final String bookingId;
  final String currentUserId;
  final Booking? initial;

  /// By id (notifications) or from a list row ([initial] paints at once).
  static Route<Booking> route({
    required String bookingId,
    required String currentUserId,
    Booking? initial,
  }) =>
      MaterialPageRoute(
        builder: (_) => BookingDetailScreen(
          bookingId: bookingId,
          currentUserId: currentUserId,
          initial: initial,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BookingDetailBloc(
        repository: di.sl<BookingsRepository>(),
        experiences: di.sl<UserExperiencesRepository>(),
        currentUserId: currentUserId,
      )..add(BookingDetailRequested(bookingId, initial: initial)),
      child: _DetailView(currentUserId: currentUserId),
    );
  }
}

class _DetailView extends StatefulWidget {
  const _DetailView({required this.currentUserId});
  final String currentUserId;

  @override
  State<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<_DetailView> {
  String get _uid => widget.currentUserId;

  BookingDetailBloc get _bloc => context.read<BookingDetailBloc>();

  void _pop() => Navigator.of(context).pop(_bloc.state.booking);

  // ───────────────────────────────────────────── dialogs

  Future<bool> _confirm(String title, String body,
      {required String action, Color color = AppColors.richGold}) async {
    final l = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(body,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.4)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(action, style: TextStyle(color: color))),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _cancel(Booking b) async {
    final l = AppLocalizations.of(context)!;
    final asHost = b.isHost(_uid);
    final preview =
        BookingRules.cancelPreview(b, DateTime.now(), byHost: asHost);
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(l.bkCancelConfirmTitle,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_refundText(l, preview, b),
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      height: 1.4)),
              if (asHost && b.status == BookingStatus.confirmed) ...[
                const SizedBox(height: 8),
                Text(l.bkHostCancelWarning,
                    style: const TextStyle(
                        color: AppColors.warningAmber, fontSize: 13)),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: reason,
                maxLength: 500,
                maxLines: 3,
                minLines: 1,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: l.bkCancelReasonHint,
                  hintStyle: const TextStyle(color: AppColors.textTertiary),
                  filled: true,
                  fillColor: AppColors.backgroundInput,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.bkKeepBooking)),
          TextButton(
            key: const ValueKey('cancel-confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.bkCancelBooking,
                style: const TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
    final text = reason.text;
    Future<void>.delayed(const Duration(seconds: 1), reason.dispose);
    if (ok == true && mounted) {
      _bloc.add(BookingActionRequested(BookingAction.cancel, reason: text));
    }
  }

  /// "If you cancel now: 50% back (€ 29.99)" for [preview].
  String _refundText(AppLocalizations l, RefundDue? preview, Booking b) {
    if (b.status == BookingStatus.requested) return l.bkCancelRequestNoCharge;
    if (preview == null || b.isFree) return l.bkIfCancelNowFree;
    if (preview.cashUnpaid) return l.bkIfCancelNowCash;
    if (preview.percent <= 0) return l.bkIfCancelNowNothing;
    return l.bkIfCancelNow(BookingL10n.percent(context, preview.percent),
        BookingL10n.money(context, preview.amount, preview.currency));
  }

  Future<void> _dispute() async {
    final l = AppLocalizations.of(context)!;
    final ctrl = TextEditingController();
    String? error;
    final reason = await showModalBottomSheet<String>(
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
              Text(l.bkReportProblem,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(l.bkDisputeIntro,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                minLines: 3,
                maxLines: 6,
                maxLength: BookingConfig.disputeReasonMax,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: l.bkDisputeHint,
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
              BookingPrimaryButton(
                label: l.bkSendReport,
                color: AppColors.errorRed,
                onPressed: () {
                  if (ctrl.text.trim().length < BookingConfig.disputeReasonMin) {
                    setSheet(() => error =
                        l.bkErrReasonRequired(BookingConfig.disputeReasonMin));
                    return;
                  }
                  Navigator.pop(ctx, ctrl.text.trim());
                },
              ),
            ],
          ),
        ),
      ),
    );
    Future<void>.delayed(const Duration(seconds: 1), ctrl.dispose);
    if (reason != null && mounted) {
      _bloc.add(BookingActionRequested(BookingAction.dispute, reason: reason));
    }
  }

  Future<void> _checkIn(Booking b) async {
    final l = AppLocalizations.of(context)!;
    final how = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading:
                const Icon(Icons.qr_code_scanner, color: AppColors.richGold),
            title: Text(l.bkScanQr,
                style: const TextStyle(color: AppColors.textPrimary)),
            onTap: () => Navigator.pop(ctx, 'scan'),
          ),
          ListTile(
            leading: const Icon(Icons.keyboard, color: AppColors.richGold),
            title: Text(l.bkTypeCode,
                style: const TextStyle(color: AppColors.textPrimary)),
            onTap: () => Navigator.pop(ctx, 'type'),
          ),
        ]),
      ),
    );
    if (how == null || !mounted) return;
    String? code;
    if (how == 'scan') {
      code = await Navigator.of(context)
          .push(BookingCheckInScannerScreen.route(b.id));
    } else {
      code = await _typeCode();
    }
    if (code == null || !mounted) return;
    var cash = false;
    if (b.payment.mode == BookingPaymentMode.cash &&
        b.payment.hostConfirmedPaidAt == null) {
      final r = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.backgroundCard,
          icon: const Icon(Icons.payments_outlined,
              color: AppColors.richGold, size: 30),
          content: Text(l.bkCashReceivedQuestion,
              style: const TextStyle(color: AppColors.textPrimary)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l.bkCashNo)),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l.bkCashYes,
                    style: const TextStyle(color: AppColors.richGold))),
          ],
        ),
      );
      if (r == null || !mounted) return;
      cash = r;
    }
    _bloc.add(BookingActionRequested(BookingAction.checkIn,
        code: code, cashReceived: cash));
  }

  Future<String?> _typeCode() async {
    final l = AppLocalizations.of(context)!;
    final ctrl = TextEditingController();
    String? error;
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: AppColors.backgroundCard,
          title: Text(l.bkTypeCode,
              style: const TextStyle(color: AppColors.textPrimary)),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            maxLength: 8,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
            ],
            style: const TextStyle(
                color: AppColors.textPrimary,
                letterSpacing: 4,
                fontSize: 20,
                fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: l.bkCodeLabel,
              errorText: error,
              filled: true,
              fillColor: AppColors.backgroundInput,
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l.cancel)),
            TextButton(
              onPressed: () {
                final v = ctrl.text.trim().toUpperCase();
                if (!BookingRules.isCheckInCode(v)) {
                  setD(() => error = l.bkErrInvalidCode);
                  return;
                }
                Navigator.pop(ctx, v);
              },
              child: Text(l.bkCheckInGuest,
                  style: const TextStyle(color: AppColors.richGold)),
            ),
          ],
        ),
      ),
    );
    Future<void>.delayed(const Duration(seconds: 1), ctrl.dispose);
    return code;
  }

  void _showCode(BookingCheckInCode code) {
    final l = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(l.bkCodeTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(
              data: code.qrPayload,
              version: QrVersions.auto,
              size: 220,
              gapless: false,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: AppColors.deepBlack,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: AppColors.deepBlack,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SelectableText(
            code.code,
            style: const TextStyle(
                color: AppColors.richGold,
                fontSize: 26,
                letterSpacing: 6,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(l.bkCodeHint,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l.bkDone)),
        ],
      ),
    );
  }

  Future<void> _reviewGuest() async {
    final l = AppLocalizations.of(context)!;
    var stars = 0;
    final ctrl = TextEditingController();
    String? error;
    final ok = await showModalBottomSheet<bool>(
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
              Text(l.bkReviewGuest,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(l.bkReviewGuestIntro,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
              Center(
                child: StarRatingInput(
                  value: stars,
                  onChanged: (v) => setSheet(() {
                    stars = v;
                    error = null;
                  }),
                ),
              ),
              TextField(
                controller: ctrl,
                minLines: 2,
                maxLines: 5,
                maxLength: BookingConfig.guestReviewMax,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: l.bkReviewGuestHint,
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
              BookingPrimaryButton(
                label: l.uexpSubmit,
                onPressed: () {
                  if (stars < 1) {
                    setSheet(() => error = l.uexpSelectRating);
                    return;
                  }
                  final v = ReviewModeration.check(ctrl.text,
                      maxLength: BookingConfig.guestReviewMax,
                      allowEmpty: true);
                  final msg = switch (v) {
                    CommentVerdict.ok || CommentVerdict.empty => null,
                    CommentVerdict.tooLong =>
                      l.uexpErrTooLong(BookingConfig.guestReviewMax),
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
              ),
            ],
          ),
        ),
      ),
    );
    final comment = ctrl.text;
    Future<void>.delayed(const Duration(seconds: 1), ctrl.dispose);
    if (ok == true && mounted) {
      _bloc.add(GuestReviewSubmitted(rating: stars, comment: comment));
    }
  }

  // ───────────────────────────────────────────── build

  String? _doneMessage(AppLocalizations l, BookingAction a) =>
      switch (a) {
        BookingAction.accept => l.bkAccepted,
        BookingAction.decline => l.bkDeclined,
        BookingAction.cancel => l.bkCancelled,
        BookingAction.markPaid => l.bkPaidMarked,
        BookingAction.confirmCash => l.bkPaymentConfirmedSnack,
        BookingAction.checkIn => l.bkCheckedInSnack,
        BookingAction.noShow => l.bkNoShowMarked,
        BookingAction.dispute => l.bkDisputeSent,
        BookingAction.reviewGuest => l.bkGuestReviewSaved,
        BookingAction.checkInCode => null,
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocConsumer<BookingDetailBloc, BookingDetailState>(
      listenWhen: (a, b) => a.seq != b.seq,
      listener: (context, s) {
        if (s.failure != null) {
          showBookingFailure(context, s.failure!);
          return;
        }
        final a = s.done;
        if (a == BookingAction.checkInCode && s.checkInCode != null) {
          _showCode(s.checkInCode!);
          return;
        }
        final msg = a == null ? null : _doneMessage(l, a);
        if (msg != null) showBookingSnack(context, msg);
      },
      builder: (context, s) {
        final b = s.booking;
        if (b == null) {
          return Scaffold(
            backgroundColor: AppColors.backgroundDark,
            appBar: AppBar(backgroundColor: AppColors.backgroundDark),
            body: Center(
              child: s.load == BookingDetailLoad.loading
                  ? const CircularProgressIndicator(color: AppColors.richGold)
                  : Text(
                      s.load == BookingDetailLoad.notFound
                          ? l.bkNotFound
                          : l.somethingWentWrong,
                      style: const TextStyle(color: AppColors.textSecondary)),
            ),
          );
        }
        final now = DateTime.now();
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _pop();
          },
          child: Scaffold(
            backgroundColor: AppColors.backgroundDark,
            appBar: AppBar(
              backgroundColor: AppColors.backgroundDark,
              leading: BackButton(onPressed: _pop),
              title: Text(l.bkDetailTitle,
                  style: const TextStyle(color: AppColors.textPrimary)),
            ),
            body: RefreshIndicator(
              color: AppColors.richGold,
              onRefresh: () async =>
                  _bloc.add(BookingDetailRequested(b.id, initial: b)),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  _header(l, s, b),
                  if (b.isHost(_uid) && BookingRules.canRespond(b, now))
                    _requestActions(l, s, b),
                  _party(l, b),
                  _checkInSection(l, s, b, now),
                  if (!b.isFree) _paymentSection(l, s, b, now),
                  if (b.refundDue != null) _refundSection(l, b.refundDue!),
                  _policySection(l, s, b, now),
                  if (b.dispute != null ||
                      (b.isGuest(_uid) && BookingRules.canDispute(b, now)))
                    _disputeSection(l, s, b, now),
                  _reviewSection(l, s, b, now),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _header(AppLocalizations l, BookingDetailState s, Booking b) {
    final e = s.experience;
    const muted = TextStyle(color: AppColors.textSecondary, fontSize: 13);
    return BookingSection(
      title: b.experienceTitle ?? e?.title ?? l.bkDetailTitle,
      icon: Icons.local_activity_outlined,
      children: [
        Row(children: [
          BookingStatusChip(status: b.status),
          if (b.isCheckedIn) ...[
            const SizedBox(width: 6),
            const Icon(Icons.how_to_reg, size: 16, color: AppColors.successGreen),
            const SizedBox(width: 3),
            Text(l.bkCheckedIn,
                style: const TextStyle(
                    color: AppColors.successGreen, fontSize: 12)),
          ],
        ]),
        const SizedBox(height: 10),
        _line(Icons.event, BookingL10n.range(context, b.slotStart, b.slotEnd)),
        _line(Icons.groups_outlined, l.bkGuestsCount(b.guests)),
        if (e != null) ...[
          _line(Icons.place_outlined, e.locationName),
          if (e.meetingPoint != null)
            _line(Icons.flag_circle_outlined,
                '${l.uexpMeetingPointLabel}: ${e.meetingPoint}'),
        ] else if (s.load == BookingDetailLoad.ready && s.guestReviewLoaded)
          Text(l.bkExperienceGone, style: muted),
        if (b.status == BookingStatus.requested && b.requestExpiresAt != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              b.isHost(_uid)
                  ? l.bkAnswerBefore(
                      BookingL10n.dateTime(context, b.requestExpiresAt!))
                  : l.bkWaitingForHost,
              style: const TextStyle(color: AppColors.warningAmber, fontSize: 13),
            ),
          ),
        if (e != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.richGold,
                  padding: EdgeInsets.zero),
              onPressed: () => Navigator.of(context).push(
                  ExperienceDetailScreen.route(
                      experienceId: e.id, currentUserId: _uid, initial: e)),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text(l.bkOpenExperience),
            ),
          ),
      ],
    );
  }

  Widget _line(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 16, color: AppColors.richGold),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 14)),
          ),
        ]),
      );

  Widget _requestActions(AppLocalizations l, BookingDetailState s, Booking b) {
    return BookingSection(
      title: l.bkRequestTitle,
      icon: Icons.mark_email_unread_outlined,
      children: [
        Text(l.bkRequestHostHint,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: BookingOutlineButton(
              label: l.bkDecline,
              color: AppColors.errorRed,
              busy: s.busy == BookingAction.decline,
              onPressed: s.busy != null
                  ? null
                  : () async {
                      if (await _confirm(l.bkDeclineConfirm, l.bkDeclineBody,
                          action: l.bkDecline, color: AppColors.errorRed)) {
                        _bloc.add(
                            const BookingActionRequested(BookingAction.decline));
                      }
                    },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: BookingPrimaryButton(
              key: const ValueKey('booking-accept'),
              label: l.bkAccept,
              icon: Icons.check,
              busy: s.busy == BookingAction.accept,
              onPressed: s.busy != null
                  ? null
                  : () => _bloc
                      .add(const BookingActionRequested(BookingAction.accept)),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _party(AppLocalizations l, Booking b) {
    final asHost = b.isHost(_uid);
    final other = b.counterpartOf(_uid);
    return BookingSection(
      title: asHost ? l.bkGuest : l.uexpHostedBy,
      icon: Icons.person_outline,
      children: [
        BookingPartyRow(
          uid: other,
          radius: 18,
          showGuestRating: asHost,
          onTap: () => openExperienceUserProfile(context, other, _uid),
        ),
      ],
    );
  }

  Widget _checkInSection(
      AppLocalizations l, BookingDetailState s, Booking b, DateTime now) {
    final buttons = <Widget>[];
    if (b.isGuest(_uid) && BookingRules.canShowCheckInCode(b, now)) {
      buttons.add(BookingPrimaryButton(
        key: const ValueKey('booking-show-code'),
        label: l.bkShowCode,
        icon: Icons.qr_code_2,
        busy: s.busy == BookingAction.checkInCode,
        onPressed: s.busy != null
            ? null
            : () => s.checkInCode != null
                ? _showCode(s.checkInCode!)
                : _bloc.add(
                    const BookingActionRequested(BookingAction.checkInCode)),
      ));
    }
    if (b.isHost(_uid) && BookingRules.canCheckIn(b, now)) {
      buttons.add(BookingPrimaryButton(
        key: const ValueKey('booking-check-in'),
        label: l.bkCheckInGuest,
        icon: Icons.qr_code_scanner,
        busy: s.busy == BookingAction.checkIn,
        onPressed: s.busy != null ? null : () => _checkIn(b),
      ));
    }
    if (b.isHost(_uid) && BookingRules.canMarkNoShow(b, now)) {
      buttons.add(BookingOutlineButton(
        label: l.bkMarkNoShow,
        icon: Icons.person_off_outlined,
        color: AppColors.errorRed,
        busy: s.busy == BookingAction.noShow,
        onPressed: s.busy != null
            ? null
            : () async {
                if (await _confirm(l.bkMarkNoShow, l.bkNoShowConfirm,
                    action: l.bkMarkNoShow, color: AppColors.errorRed)) {
                  _bloc.add(const BookingActionRequested(BookingAction.noShow));
                }
              },
      ));
    }
    if (buttons.isEmpty) return const SizedBox.shrink();
    return BookingSection(
      title: l.bkCheckInTitle,
      icon: Icons.how_to_reg_outlined,
      children: [
        if (b.isGuest(_uid))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(l.bkCodeHint,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
          ),
        for (final w in buttons)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SizedBox(width: double.infinity, child: w),
          ),
      ],
    );
  }

  Widget _paymentSection(
      AppLocalizations l, BookingDetailState s, Booking b, DateTime now) {
    final p = b.payment;
    final asHost = b.isHost(_uid);
    const muted = TextStyle(color: AppColors.textSecondary, fontSize: 13);
    final lines = <Widget>[
      Row(children: [
        Expanded(
          child: Text(BookingL10n.paymentMode(l, p.mode),
              style: const TextStyle(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        ),
        Text(BookingL10n.total(context, b.price),
            style: const TextStyle(
                color: AppColors.richGold,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 6),
    ];
    if (p.hostConfirmedPaidAt != null) {
      lines.add(_state(Icons.verified, AppColors.successGreen,
          p.mode == BookingPaymentMode.cash ? l.bkCashConfirmed : l.bkPaymentConfirmed));
    } else if (p.guestMarkedPaidAt != null) {
      lines.add(_state(Icons.schedule, AppColors.warningAmber,
          asHost ? l.bkGuestSaysPaid : l.bkYouMarkedPaid));
    } else {
      lines.add(Text(
          p.mode == BookingPaymentMode.cash ? l.bkCashAtMeeting : l.bkNotPaidYet,
          style: muted));
    }
    final buttons = <Widget>[];
    if (!asHost &&
        p.mode == BookingPaymentMode.link &&
        p.link != null &&
        b.status == BookingStatus.confirmed &&
        p.hostConfirmedPaidAt == null) {
      buttons.add(BookingOutlineButton(
        label: p.link!.isOpenable ? l.bkPayNow : l.bkCopyPixKey,
        icon: p.link!.isOpenable ? Icons.open_in_new : Icons.copy_rounded,
        onPressed: () => openBookingPaymentLink(context, p.link!),
      ));
    }
    if (!asHost && BookingRules.guestCanMarkPaid(b)) {
      buttons.add(BookingPrimaryButton(
        key: const ValueKey('booking-mark-paid'),
        label: l.bkMarkPaid,
        icon: Icons.done_all,
        busy: s.busy == BookingAction.markPaid,
        onPressed: s.busy != null
            ? null
            : () => _bloc
                .add(const BookingActionRequested(BookingAction.markPaid)),
      ));
    }
    if (asHost && BookingRules.hostCanConfirmPaid(b, now)) {
      final cash = p.mode == BookingPaymentMode.cash;
      buttons.add(BookingPrimaryButton(
        key: const ValueKey('booking-host-paid'),
        label: cash ? l.bkCashReceived : l.bkConfirmPayment,
        icon: Icons.payments,
        busy: s.busy ==
            (cash ? BookingAction.confirmCash : BookingAction.markPaid),
        onPressed: s.busy != null
            ? null
            : () => _bloc.add(BookingActionRequested(
                cash ? BookingAction.confirmCash : BookingAction.markPaid)),
      ));
    }
    return BookingSection(
      title: l.bkPayment,
      icon: Icons.payments_outlined,
      children: [
        ...lines,
        for (final w in buttons)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SizedBox(width: double.infinity, child: w),
          ),
        const SizedBox(height: 6),
        Text(l.uexpPaymentDisclaimer,
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
      ],
    );
  }

  Widget _state(IconData icon, Color color, String text) => Row(children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
            child: Text(text, style: TextStyle(color: color, fontSize: 13))),
      ]);

  Widget _refundSection(AppLocalizations l, RefundDue r) {
    final text = r.cashUnpaid
        ? l.bkRefundCashUnpaid
        : (r.percent <= 0
            ? l.bkRefundNone
            : (r.linkUnconfirmed ? l.bkRefundIfPaid : l.bkRefundOwed)(
                BookingL10n.percent(context, r.percent),
                BookingL10n.money(context, r.amount, r.currency)));
    return BookingSection(
      title: l.bkRefundTitle,
      icon: Icons.currency_exchange,
      children: [
        Text(text,
            style: const TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(l.bkRefundOffPlatform,
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
      ],
    );
  }

  Widget _policySection(
      AppLocalizations l, BookingDetailState s, Booking b, DateTime now) {
    final canCancel = BookingRules.canCancel(b, now);
    if (!canCancel && b.isFree) return const SizedBox.shrink();
    final asHost = b.isHost(_uid);
    final preview = BookingRules.cancelPreview(b, now, byHost: asHost);
    return BookingSection(
      title: l.uexpCancellationLabel,
      icon: Icons.policy_outlined,
      children: [
        if (!b.isFree) ...[
          Row(children: [
            PolicyChip(policy: b.policy),
          ]),
          const SizedBox(height: 6),
          Text(ExperienceL10n.policyDescription(l, b.policy),
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
        ],
        if (canCancel) ...[
          Text(_refundText(l, preview, b),
              key: const ValueKey('booking-refund-preview'),
              style: const TextStyle(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: BookingOutlineButton(
              key: const ValueKey('booking-cancel'),
              label: l.bkCancelBooking,
              icon: Icons.event_busy,
              color: AppColors.errorRed,
              busy: s.busy == BookingAction.cancel,
              onPressed: s.busy != null ? null : () => _cancel(b),
            ),
          ),
        ],
      ],
    );
  }

  Widget _disputeSection(
      AppLocalizations l, BookingDetailState s, Booking b, DateTime now) {
    final d = b.dispute;
    return BookingSection(
      title: l.bkReportProblem,
      icon: Icons.report_gmailerrorred_outlined,
      children: [
        if (d != null)
          Text(
            d.isOpen
                ? l.bkDisputeOpen
                : l.bkDisputeResolved(
                    BookingL10n.percent(context, d.refundPercent ?? 0)),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          )
        else ...[
          Text(l.bkDisputeIntro,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: BookingOutlineButton(
              key: const ValueKey('booking-dispute'),
              label: l.bkReportProblem,
              icon: Icons.flag_outlined,
              color: AppColors.errorRed,
              busy: s.busy == BookingAction.dispute,
              onPressed: s.busy != null ? null : _dispute,
            ),
          ),
        ],
      ],
    );
  }

  Widget _reviewSection(
      AppLocalizations l, BookingDetailState s, Booking b, DateTime now) {
    if (b.isHost(_uid)) {
      if (!s.guestReviewLoaded) return const SizedBox.shrink();
      final r = s.guestReview;
      if (r != null) {
        return BookingSection(
          title: l.bkGuestReviewed,
          icon: Icons.rate_review_outlined,
          children: [
            StarRatingDisplay(rating: r.rating.toDouble()),
            if (r.comment.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(r.comment,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
            ],
            if (r.status != 'visible') ...[
              const SizedBox(height: 6),
              Text(l.bkGuestReviewHeld,
                  style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                      fontStyle: FontStyle.italic)),
            ],
          ],
        );
      }
      if (!BookingRules.hostCanReviewGuest(b, now)) {
        return const SizedBox.shrink();
      }
      return BookingSection(
        title: l.bkReviewGuest,
        icon: Icons.rate_review_outlined,
        children: [
          Text(l.bkReviewGuestIntro,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: BookingPrimaryButton(
              key: const ValueKey('booking-review-guest'),
              label: l.bkReviewGuest,
              icon: Icons.star_outline,
              busy: s.busy == BookingAction.reviewGuest,
              onPressed: s.busy != null ? null : _reviewGuest,
            ),
          ),
        ],
      );
    }
    // Guest: the review composer lives on the experience page.
    final reviewable = b.status == BookingStatus.completed ||
        (b.status == BookingStatus.confirmed && b.isCheckedIn);
    if (!reviewable || s.experience == null) return const SizedBox.shrink();
    return BookingSection(
      title: l.bkReviewExperience,
      icon: Icons.rate_review_outlined,
      children: [
        Text(l.bkReviewExperienceHint,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: BookingOutlineButton(
            label: l.bkReviewExperience,
            icon: Icons.star_outline,
            onPressed: () => Navigator.of(context).push(
                ExperienceDetailScreen.route(
                    experienceId: b.experienceId,
                    currentUserId: _uid,
                    initial: s.experience)),
          ),
        ),
      ],
    );
  }
}
