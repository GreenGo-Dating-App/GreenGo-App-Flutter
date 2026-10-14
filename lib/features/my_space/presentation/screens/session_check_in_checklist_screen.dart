import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/user_error.dart';
import '../../../../generated/app_localizations.dart';
import '../../../experience_bookings/domain/booking_failure.dart';
import '../../../experience_bookings/domain/entities/booking.dart';
import '../../../experience_bookings/presentation/booking_l10n.dart';
import '../../../experience_bookings/presentation/screens/booking_detail_screen.dart';
import '../../../experience_bookings/presentation/widgets/booking_widgets.dart';
import '../../../explore/presentation/screens/qr_hub_screen.dart';
import '../../data/my_space_repository.dart';
import '../../domain/my_space_models.dart';
import '../widgets/check_in_widgets.dart';
import '../widgets/space_widgets.dart';

/// Host's check-in CHECKLIST for one experience session (one experience at
/// one start time): each booking with its guest, party size and a tick.
/// Unticked guests can be checked in by hand (manualCheckInBooking: host
/// only, audited); "Scan" opens the door scanner preset to this experience.
/// A booking check-in cannot be undone (it opens the guest's review window),
/// so ticked rows are final; tap a row for the full booking.
class SessionCheckInChecklistScreen extends StatefulWidget {
  const SessionCheckInChecklistScreen({
    super.key,
    required this.session,
    required this.currentUserId,
    required this.repository,
    this.guestBuilder,
    this.openScanner,
  });

  final CheckInSession session;
  final String currentUserId;
  final MySpaceRepository repository;

  /// Avatar + name of a guest (defaults to [BookingPartyRow]; tests stub it).
  final Widget Function(BuildContext context, String guestId)? guestBuilder;

  /// Test hook; defaults to pushing [QrScanScreen] for this experience.
  final Future<void> Function(BuildContext context)? openScanner;

  static Route<void> route({
    required CheckInSession session,
    required String currentUserId,
    required MySpaceRepository repository,
  }) =>
      MaterialPageRoute<void>(
        builder: (_) => SessionCheckInChecklistScreen(
          session: session,
          currentUserId: currentUserId,
          repository: repository,
        ),
      );

  @override
  State<SessionCheckInChecklistScreen> createState() =>
      _SessionCheckInChecklistScreenState();
}

class _SessionCheckInChecklistScreenState
    extends State<SessionCheckInChecklistScreen> {
  late List<Booking> _bookings = widget.session.bookings;
  final Set<String> _busy = {};
  CheckInFilter _filter = CheckInFilter.all;
  final _search = TextEditingController();

  CheckInSession get _s => widget.session;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    try {
      final fresh = await widget.repository.sessionBookings(
          hostId: widget.currentUserId,
          experienceId: _s.experienceId,
          slotStart: _s.start);
      if (mounted) setState(() => _bookings = fresh);
    } catch (_) {/* keep what is shown */}
  }

  Future<void> _scan() async {
    final open = widget.openScanner;
    if (open != null) {
      await open(context);
    } else {
      await Navigator.of(context).push(QrScanScreen.route(
          currentUserId: widget.currentUserId,
          experienceId: _s.experienceId,
          title: _s.title.isEmpty ? null : _s.title));
    }
    if (mounted) await _reload();
  }

  Future<void> _checkIn(Booking b) async {
    final l = AppLocalizations.of(context)!;
    final ok = await confirmCheckInChange(context,
        title: l.msCheckInConfirmTitle,
        body: l.msCheckInBookingConfirmBody,
        action: l.msCheckIn);
    if (!ok || !mounted) return;
    setState(() => _busy.add(b.id));
    final r = await widget.repository.manualCheckInBooking(b);
    if (!mounted) return;
    setState(() => _busy.remove(b.id));
    r.fold(
      (f) => f is BookingFailure
          ? showBookingFailure(context, f)
          : showUserError(context, f),
      (updated) {
        setState(() => _bookings = [
              for (final x in _bookings)
                x.id == updated.id
                    ? (updated.isCheckedIn
                        ? updated
                        : updated.copyWith(checkedInAt: DateTime.now()))
                    : x,
            ]);
        showBookingSnack(context, l.msCheckedInSnack(l.msGuest));
      },
    );
  }

  Future<void> _open(Booking b) async {
    final updated = await Navigator.of(context).push(BookingDetailScreen.route(
        bookingId: b.id, currentUserId: widget.currentUserId, initial: b));
    if (updated != null && mounted) {
      setState(() => _bookings = [
            for (final x in _bookings) x.id == updated.id ? updated : x,
          ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final checked = _bookings.where((b) => b.isCheckedIn).length;
    final visible = _bookings.where((b) {
      if (_filter == CheckInFilter.pending) return !b.isCheckedIn;
      if (_filter == CheckInFilter.checkedIn) return b.isCheckedIn;
      return true;
    }).toList();
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(l.msCheckInTitle),
      ),
      body: RefreshIndicator(
        color: AppColors.richGold,
        onRefresh: _reload,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            SpaceMaxWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(_s.title.isEmpty ? l.bkDetailTitle : _s.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(BookingL10n.range(context, _s.start, _s.end),
                      style: const TextStyle(
                          color: AppColors.textTertiary, fontSize: 13)),
                  const SizedBox(height: 14),
                  CheckInSummaryCard(
                    checkedIn: checked,
                    total: _bookings.length,
                    subtitle: l.bkGuestsCount(
                        _bookings.fold<int>(0, (n, b) => n + b.guests)),
                    onScan: _scan,
                  ),
                  const SizedBox(height: 14),
                  // Sessions are small: filters only (no name search needed).
                  Wrap(spacing: 8, children: [
                    for (final (f, label) in [
                      (CheckInFilter.all, l.msFilterAll),
                      (CheckInFilter.pending, l.eventNotCheckedIn),
                      (CheckInFilter.checkedIn, l.eventCheckedIn),
                    ])
                      ChoiceChip(
                        key: ValueKey('checklist-filter-${f.name}'),
                        label: Text(label),
                        selected: _filter == f,
                        onSelected: (_) => setState(() => _filter = f),
                        showCheckmark: false,
                        backgroundColor: AppColors.backgroundCard,
                        selectedColor: AppColors.richGold,
                        side: BorderSide(
                            color: AppColors.richGold.withValues(alpha: 0.35)),
                        labelStyle: TextStyle(
                          color: _filter == f
                              ? AppColors.deepBlack
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ]),
                  const SizedBox(height: 12),
                  if (_bookings.isEmpty)
                    Padding(
                      key: const ValueKey('checklist-empty'),
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text(l.msNoSessionGuests,
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(color: AppColors.textSecondary)),
                    )
                  else
                    for (final b in visible)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _row(l, b),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(AppLocalizations l, Booking b) {
    final canTick = !b.isCheckedIn && b.status == BookingStatus.confirmed;
    final who = widget.guestBuilder?.call(context, b.guestId) ??
        BookingPartyRow(uid: b.guestId, radius: 18, guestName: b.guestName);
    return InkWell(
      key: ValueKey('row-${b.id}'),
      borderRadius: BorderRadius.circular(14),
      onTap: () => _open(b),
      child: CheckInRow(
        toggleKey: ValueKey('check-${b.id}'),
        name: l.msGuest,
        who: who,
        detail: [
          l.bkGuestsCount(b.guests),
          if (b.status != BookingStatus.confirmed)
            BookingL10n.status(l, b.status),
        ].join(' · '),
        checkedIn: b.isCheckedIn,
        busy: _busy.contains(b.id),
        onToggle: canTick ? () => _checkIn(b) : null,
      ),
    );
  }
}
