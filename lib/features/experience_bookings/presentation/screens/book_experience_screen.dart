import '../../../ticket_payments/domain/ticket_payments.dart' show formatTicketAmount;
import '../widgets/recurring_time_picker.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/utils/user_error.dart';
import '../../../../generated/app_localizations.dart';
import '../../../user_experiences/domain/entities/user_experience.dart';
import '../../../user_experiences/domain/repositories/user_experiences_repository.dart';
import '../../../user_experiences/presentation/experience_l10n.dart';
import '../../../user_experiences/presentation/experience_safety_flow.dart';
import '../../../user_experiences/presentation/widgets/booking_consent_dialog.dart';
import '../../../user_experiences/presentation/widgets/experience_policy_widgets.dart';
import '../../domain/booking_failure.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/bookings_repository.dart';
import '../bloc/booking_flow_bloc.dart';
import '../booking_l10n.dart';
import '../widgets/booking_widgets.dart';
import 'booking_detail_screen.dart';
import 'booking_result_screen.dart';

/// Guest booking: date (seats left) → guests → payment method (when the
/// listing accepts both) → ID document gate → consent → createBooking.
class BookExperienceScreen extends StatelessWidget {
  const BookExperienceScreen({
    super.key,
    required this.experience,
    required this.currentUserId,
    this.initialSlotId,
    this.initialSlots,
    this.initialSlotsAt,
  });

  final UserExperience experience;
  final String currentUserId;
  final String? initialSlotId;

  /// Dates the caller already read, and when (see [BookingFlowStarted]).
  final List<ExperienceSlot>? initialSlots;
  final DateTime? initialSlotsAt;

  static Route<void> route({
    required UserExperience experience,
    required String currentUserId,
    String? initialSlotId,
    List<ExperienceSlot>? initialSlots,
    DateTime? initialSlotsAt,
  }) =>
      MaterialPageRoute(
        builder: (_) => BookExperienceScreen(
          experience: experience,
          currentUserId: currentUserId,
          initialSlotId: initialSlotId,
          initialSlots: initialSlots,
          initialSlotsAt: initialSlotsAt,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BookingFlowBloc(repository: di.sl<BookingsRepository>())
        ..add(BookingFlowStarted(
          experience,
          initialSlotId: initialSlotId,
          initialSlots: initialSlots,
          initialSlotsAt: initialSlotsAt,
        )),
      child: _BookView(currentUserId: currentUserId),
    );
  }
}

class _BookView extends StatefulWidget {
  const _BookView({required this.currentUserId});
  final String currentUserId;

  @override
  State<_BookView> createState() => _BookViewState();
}

class _BookViewState extends State<_BookView> {
  bool _preparing = false;

  /// ID gate + consent (paid), then submit. The server checks both again.
  Future<void> _continue() async {
    final bloc = context.read<BookingFlowBloc>();
    final s = bloc.state;
    final e = s.experience;
    if (e == null || !s.canSubmit || _preparing) return;
    setState(() => _preparing = true);
    try {
      if (!await ExperienceSafetyFlow.ensureIdDocument(
          context, widget.currentUserId, IdDocPurpose.payAsGuest)) {
        return;
      }
      if (!mounted) return;
      if (!e.isFree) {
        final method =
            await BookingConsentDialog.show(context, e, only: s.effectiveMethod);
        if (method == null || !mounted) return;
        final saved =
            await di.sl<UserExperiencesRepository>().recordBookingConsent(
                  experienceId: e.id,
                  uid: widget.currentUserId,
                  policy: e.cancellationPolicy,
                  version: BookingConsentDialog.version,
                  method: method,
                );
        if (!mounted) return;
        if (saved.isLeft()) {
          unawaited(showUserError(context, saved.fold((f) => f, (_) => null)));
          return;
        }
      }
      bloc.add(const BookingSubmitted(
          consentVersion: BookingConsentDialog.version));
    } finally {
      if (mounted) setState(() => _preparing = false);
    }
  }

  Future<void> _onFailure(BookingFailure f) async {
    final l = AppLocalizations.of(context)!;
    final bloc = context.read<BookingFlowBloc>();
    switch (f.code) {
      case 'id_document_required':
        // Upload in place, then try again automatically.
        if (await ExperienceSafetyFlow.ensureIdDocument(
                context, widget.currentUserId, IdDocPurpose.payAsGuest) &&
            mounted) {
          bloc.add(const BookingSubmitted(
              consentVersion: BookingConsentDialog.version));
        }
        return;
      case 'already_booked':
        final id = f.existingBookingId;
        final open = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.backgroundCard,
            icon: const Icon(Icons.event_available,
                color: AppColors.richGold, size: 32),
            content: Text(l.bkErrAlreadyBooked,
                style: const TextStyle(color: AppColors.textSecondary)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l.bkDone)),
              if (id != null)
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(l.bkViewBooking)),
            ],
          ),
        );
        if (open == true && id != null && mounted) {
          await Navigator.of(context).pushReplacement(BookingDetailScreen.route(
              bookingId: id, currentUserId: widget.currentUserId));
        }
        return;
      case 'slot_full':
      case 'slot_closed':
      case 'slot_started':
        showBookingFailure(context, f);
        bloc.add(const BookingSlotsRefreshed());
        return;
    }
    if (!mounted) return;
    if (!f.definitive) {
      // Same requestId on retry: a booking that went through is returned.
      unawaited(showUserErrorMessage(
        context,
        BookingL10n.error(l, f),
        onRetry: () => bloc.add(const BookingSubmitted(
            consentVersion: BookingConsentDialog.version)),
      ));
      return;
    }
    showBookingFailure(context, f);
  }

  /// "€ 25 × 2" total of the listing price (major units, as listed).
  String _total(AppLocalizations l, UserExperience e, int guests) {
    if (e.isFree || e.price <= 0) return l.uexpFree;
    final t = e.price * guests;
    final txt =
        t == t.roundToDouble() ? t.toStringAsFixed(0) : t.toStringAsFixed(2);
    final c = e.currency ?? '';
    return c.isEmpty ? txt : '$c $txt';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocConsumer<BookingFlowBloc, BookingFlowState>(
      listenWhen: (a, b) =>
          a.failureSeq != b.failureSeq || (a.result == null && b.result != null),
      listener: (context, s) {
        if (s.result != null) {
          Navigator.of(context).pushReplacement(BookingResultScreen.route(
            booking: s.result!,
            experience: s.experience!,
            currentUserId: widget.currentUserId,
          ));
          return;
        }
        if (s.failure != null) _onFailure(s.failure!);
      },
      builder: (context, s) {
        final e = s.experience;
        if (e == null) {
          return const Scaffold(
            backgroundColor: AppColors.backgroundDark,
            body: Center(
                child: CircularProgressIndicator(color: AppColors.richGold)),
          );
        }
        final busy = s.submitting || _preparing;
        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          appBar: AppBar(
            backgroundColor: AppColors.backgroundDark,
            title: Text(e.requestToBook ? l.bkRequestToBook : l.uexpBook,
                style: const TextStyle(color: AppColors.textPrimary)),
          ),
          body: AbsorbPointer(
            absorbing: busy,
            child: RefreshIndicator(
              color: AppColors.richGold,
              onRefresh: () async => context
                  .read<BookingFlowBloc>()
                  .add(const BookingSlotsRefreshed()),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Text(e.title,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    [e.locationName, ExperienceL10n.duration(l, e.durationMinutes)]
                        .where((x) => x.isNotEmpty)
                        .join(' · '),
                    style: const TextStyle(
                        color: AppColors.textTertiary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  if (s.isRecurring)
                    BookingSection(
                      title: l.bkChooseDate,
                      icon: Icons.calendar_month_outlined,
                      children: [
                        RecurringTimePicker(
                          experience: e,
                          selected: s.recurringTime,
                          onPicked: (t) => context.read<BookingFlowBloc>().add(BookingRecurringTimePicked(t)),
                        ),
                      ],
                    )
                  else ...[
                    _slotsSection(l, s),
                    if (s.selectedSlot != null) _timesSection(l, s),
                  ],
                  if (s.selectedTime != null || s.recurringTime != null) _guestsSection(l, s),
                  if (s.needsMethodChoice) _methodSection(l, s),
                  _summary(l, s, e),
                ],
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: BookingPrimaryButton(
                  key: const ValueKey('booking-submit'),
                  label: e.requestToBook ? l.bkSendRequest : l.bkConfirmBooking,
                  icon: e.requestToBook
                      ? Icons.send_rounded
                      : Icons.event_available,
                  busy: busy,
                  onPressed: s.canSubmit ? _continue : null,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _slotsSection(AppLocalizations l, BookingFlowState s) {
    Widget body;
    if (s.slotsLoading && s.slots.isEmpty) {
      body = const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
            child: CircularProgressIndicator(color: AppColors.richGold)),
      );
    } else if (s.slotsFailed && s.slots.isEmpty) {
      body = Row(children: [
        Expanded(
          child: Text(l.somethingWentWrong,
              style: const TextStyle(color: AppColors.textSecondary)),
        ),
        TextButton(
          onPressed: () => context
              .read<BookingFlowBloc>()
              .add(const BookingSlotsRefreshed()),
          child: Text(l.bkRetry,
              style: const TextStyle(color: AppColors.richGold)),
        ),
      ]);
    } else if (s.slots.isEmpty) {
      body = Text(l.bkNoDates,
          style: const TextStyle(color: AppColors.textSecondary));
    } else {
      body = Column(children: [
        for (final slot in s.slots) _slotTile(l, s, slot),
      ]);
    }
    return BookingSection(
      title: l.bkChooseDate,
      icon: Icons.calendar_month_outlined,
      children: [body],
    );
  }

  /// Private time slots: the free start times of the selected window, each
  /// lasting the experience's duration. Taken times show greyed out.
  Widget _timesSection(AppLocalizations l, BookingFlowState s) {
    final bloc = context.read<BookingFlowBloc>();
    final a = s.availability;
    Widget body;
    if (s.timesLoading && a == null) {
      body = const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
            child: CircularProgressIndicator(color: AppColors.richGold)),
      );
    } else if (s.timesFailed && a == null) {
      body = Row(children: [
        Expanded(
          child: Text(l.somethingWentWrong,
              style: const TextStyle(color: AppColors.textSecondary)),
        ),
        TextButton(
          onPressed: () => bloc.add(const BookingTimesRefreshed()),
          child: Text(l.bkRetry,
              style: const TextStyle(color: AppColors.richGold)),
        ),
      ]);
    } else if (a == null || a.freeTimes.isEmpty) {
      body = Text(l.bkNoFreeTimes,
          style: const TextStyle(color: AppColors.textSecondary));
    } else {
      body = Wrap(spacing: 8, runSpacing: 8, children: [
        for (final t in a.times)
          ChoiceChip(
            key: ValueKey('time-${t.start.millisecondsSinceEpoch}'),
            label: Text(
              '${BookingL10n.time(context, t.start.toLocal())}'
              '\u2013${BookingL10n.time(context, t.end.toLocal())}',
              style: TextStyle(
                color: !t.free
                    ? AppColors.textTertiary
                    : (s.selectedStart != null &&
                            t.start.isAtSameMomentAs(s.selectedStart!)
                        ? AppColors.deepBlack
                        : AppColors.textPrimary),
                decoration: t.free ? null : TextDecoration.lineThrough,
                fontWeight: FontWeight.w600,
              ),
            ),
            selected: s.selectedStart != null &&
                t.start.isAtSameMomentAs(s.selectedStart!),
            selectedColor: AppColors.richGold,
            backgroundColor: AppColors.backgroundInput,
            showCheckmark: false,
            onSelected:
                t.free ? (_) => bloc.add(BookingTimeSelected(t.start)) : null,
          ),
      ]);
    }
    return BookingSection(
      title: l.bkChooseTime,
      icon: Icons.schedule,
      children: [
        if (a != null && a.lengthMinutes > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              l.bkTimesHint(
                  ExperienceL10n.duration(l, a.lengthMinutes)),
              style: const TextStyle(
                  color: AppColors.textTertiary, fontSize: 12.5),
            ),
          ),
        body,
      ],
    );
  }

  Widget _slotTile(AppLocalizations l, BookingFlowState s, ExperienceSlot slot) {
    final selected = s.selectedSlotId == slot.id;
    // Private time slots: a window has no seats any more; its free times
    // show once it is selected.
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        key: ValueKey('slot-${slot.id}'),
        borderRadius: BorderRadius.circular(12),
        onTap: () =>
            context.read<BookingFlowBloc>().add(BookingSlotSelected(slot.id)),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.backgroundInput,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? AppColors.richGold : Colors.transparent,
                width: 1.5),
          ),
          child: Row(children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 20,
              color: selected ? AppColors.richGold : AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                BookingL10n.range(context, slot.start, slot.end),
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _guestsSection(AppLocalizations l, BookingFlowState s) {
    final bloc = context.read<BookingFlowBloc>();
    final max = s.maxGuests;
    return BookingSection(
      title: l.bkGuests,
      icon: Icons.groups_outlined,
      children: [
        Row(children: [
          IconButton(
            key: const ValueKey('guests-minus'),
            onPressed: s.guests > 1
                ? () => bloc.add(BookingGuestsChanged(s.guests - 1))
                : null,
            icon: const Icon(Icons.remove_circle_outline),
            color: AppColors.richGold,
          ),
          SizedBox(
            width: 40,
            child: Text('${s.guests}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
          ),
          IconButton(
            key: const ValueKey('guests-plus'),
            onPressed: s.guests < max
                ? () => bloc.add(BookingGuestsChanged(s.guests + 1))
                : null,
            icon: const Icon(Icons.add_circle_outline),
            color: AppColors.richGold,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(l.bkMaxGuests(max),
                style: const TextStyle(
                    color: AppColors.textTertiary, fontSize: 12)),
          ),
        ]),
      ],
    );
  }

  Widget _methodSection(AppLocalizations l, BookingFlowState s) {
    final bloc = context.read<BookingFlowBloc>();
    return BookingSection(
      title: l.uexpConsentPickMethod,
      icon: Icons.payments_outlined,
      children: [
        Wrap(spacing: 8, runSpacing: 6, children: [
          for (final m in s.methods)
            ChoiceChip(
              key: ValueKey('method-${m.name}'),
              selected: s.method == m,
              onSelected: (_) => bloc.add(BookingMethodChanged(m)),
              selectedColor: AppColors.richGold.withValues(alpha: 0.25),
              backgroundColor: AppColors.backgroundInput,
              avatar: Icon(ExperienceL10n.paymentMethodIcon(m),
                  size: 16, color: AppColors.richGold),
              label: Text(ExperienceL10n.paymentMethod(l, m),
                  style: const TextStyle(color: AppColors.textPrimary)),
            ),
        ]),
      ],
    );
  }

  Widget _summary(AppLocalizations l, BookingFlowState s, UserExperience e) {
    const muted = TextStyle(color: AppColors.textSecondary, fontSize: 13);
    return BookingSection(
      title: l.bkSummary,
      icon: Icons.receipt_long_outlined,
      children: [
        Row(children: [
          Expanded(child: Text(l.bkGuestsCount(s.guests), style: muted)),
          Text(s.recurringTime != null && !e.isFree && s.recurringTime!.currency != null
                  ? formatTicketAmount(
                      s.recurringTime!.unitAmount * (e.isPerGroup ? 1 : s.guests), s.recurringTime!.currency!)
                  : _total(l, e, s.guests),
              style: const TextStyle(
                  color: AppColors.richGold,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(e.requestToBook ? Icons.hourglass_top_rounded : Icons.bolt,
              size: 16, color: AppColors.richGold),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
                e.requestToBook ? l.bkRequestInfo : l.bkInstantInfo,
                style: muted),
          ),
        ]),
        if (!e.isFree) ...[
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
                child: Text(l.uexpCancellationLabel,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600))),
            PolicyChip(policy: e.cancellationPolicy),
          ]),
          const SizedBox(height: 4),
          Text(ExperienceL10n.policyDescription(l, e.cancellationPolicy),
              style: muted),
          const SizedBox(height: 8),
          Text(l.uexpPaymentDisclaimer,
              style: const TextStyle(
                  color: AppColors.textTertiary, fontSize: 11)),
        ],
      ],
    );
  }
}
