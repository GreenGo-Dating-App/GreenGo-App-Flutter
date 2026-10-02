import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../generated/app_localizations.dart';
import '../../../user_experiences/domain/entities/user_experience.dart';
import '../../domain/booking_failure.dart';
import '../../domain/booking_rules.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/bookings_repository.dart';
import '../bloc/slots_bloc.dart';
import '../booking_l10n.dart';
import '../widgets/booking_widgets.dart';
import 'bookings_list_screen.dart';

/// Host: "Dates & availability" — add / edit / delete / cancel the dates
/// guests can book, seats booked per date, and the "Request to book" switch.
/// Pops with the experience as last saved.
class ExperienceSlotsScreen extends StatelessWidget {
  const ExperienceSlotsScreen({
    super.key,
    required this.experience,
    required this.currentUserId,
  });

  final UserExperience experience;
  final String currentUserId;

  static Route<UserExperience> route({
    required UserExperience experience,
    required String currentUserId,
  }) =>
      MaterialPageRoute(
        builder: (_) => ExperienceSlotsScreen(
            experience: experience, currentUserId: currentUserId),
      );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SlotsBloc(
        repository: di.sl<BookingsRepository>(),
      )..add(SlotsStarted(experience)),
      child: _SlotsView(currentUserId: currentUserId),
    );
  }
}

class _SlotsView extends StatefulWidget {
  const _SlotsView({required this.currentUserId});
  final String currentUserId;

  @override
  State<_SlotsView> createState() => _SlotsViewState();
}

class _SlotsViewState extends State<_SlotsView> {
  SlotsBloc get _bloc => context.read<SlotsBloc>();

  void _pop() => Navigator.of(context).pop(_bloc.state.experience);

  Future<void> _edit({ExperienceSlot? existing}) async {
    final e = _bloc.state.experience;
    if (e == null) return;
    final draft = await showModalBottomSheet<SlotDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _SlotEditorSheet(experience: e, existing: existing),
    );
    if (draft != null && mounted) {
      _bloc.add(SlotSaveRequested(draft, existing: existing));
    }
  }

  Future<void> _cancelSlot(ExperienceSlot slot) async {
    final l = AppLocalizations.of(context)!;
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        icon: const Icon(Icons.warning_amber_rounded,
            color: AppColors.errorRed, size: 32),
        title: Text(l.bkCancelDateTitle,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(l.bkCancelDateBody(slot.bookedCount),
                style: const TextStyle(
                    color: AppColors.textSecondary, height: 1.4)),
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
              ),
            ),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.bkKeepDate)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.bkCancelDate,
                style: const TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
    final text = reason.text;
    Future<void>.delayed(const Duration(seconds: 1), reason.dispose);
    if (ok == true && mounted) {
      _bloc.add(SlotCancelRequested(slot, reason: text));
    }
  }

  Future<void> _delete(ExperienceSlot slot) async {
    final l = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(l.bkDeleteDate,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(BookingL10n.range(context, slot.start, slot.end),
            style: const TextStyle(color: AppColors.textSecondary)),
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
    if (ok == true && mounted) _bloc.add(SlotDeleteRequested(slot));
  }

  void _bookings(UserExperience e) => Navigator.of(context).push(
        BookingsListScreen.route(
          role: BookingRole.host,
          currentUserId: widget.currentUserId,
          experienceId: e.id,
          title: e.title,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocConsumer<SlotsBloc, SlotsState>(
      listenWhen: (a, b) => a.seq != b.seq,
      listener: (context, s) {
        switch (s.flash) {
          case SlotsFlash.saved:
            showBookingSnack(context, l.bkDateSaved);
          case SlotsFlash.deleted:
            showBookingSnack(context, l.bkDateDeleted);
          case SlotsFlash.cancelled:
            showBookingSnack(
                context, l.bkDateCancelled(s.cancelledBookings));
          case SlotsFlash.invalid:
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(s.errors.isEmpty
                  ? l.somethingWentWrong
                  : BookingL10n.slotError(l, s.errors.first)),
              backgroundColor: AppColors.errorRed,
            ));
          case SlotsFlash.failed:
            final f = s.failure;
            if (f is BookingFailure &&
                f.code != 'permission-denied' &&
                f.code != BookingFailure.network) {
              showBookingFailure(context, f);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(l.bkSlotSaveFailed),
                backgroundColor: AppColors.errorRed,
              ));
            }
          case null:
            break;
        }
      },
      builder: (context, s) {
        final e = s.experience;
        if (e == null) {
          return const Scaffold(backgroundColor: AppColors.backgroundDark);
        }
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
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.bkDatesTitle,
                      style: const TextStyle(color: AppColors.textPrimary)),
                  Text(e.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.textTertiary, fontSize: 12)),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: l.bkBookings,
                  icon: const Icon(Icons.receipt_long_outlined),
                  onPressed: () => _bookings(e),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              key: const ValueKey('slot-add'),
              backgroundColor: AppColors.richGold,
              foregroundColor: AppColors.deepBlack,
              onPressed: s.busy ? null : () => _edit(),
              icon: const Icon(Icons.add),
              label: Text(l.bkAddDate),
            ),
            body: RefreshIndicator(
              color: AppColors.richGold,
              onRefresh: () async => _bloc.add(const SlotsRefreshed()),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
                children: [
                  if (s.busy) const LinearProgressIndicator(color: AppColors.richGold),
                  if (s.loading && s.slots.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                          child: CircularProgressIndicator(
                              color: AppColors.richGold)),
                    )
                  else if (s.slots.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        s.failed ? l.somethingWentWrong : l.bkNoDatesHost,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  else
                    for (final slot in s.slots) _slotTile(l, s, e, slot),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _slotTile(
      AppLocalizations l, SlotsState s, UserExperience e, ExperienceSlot slot) {
    final ratio = slot.capacity == 0 ? 0.0 : slot.bookedCount / slot.capacity;
    return Card(
      color: AppColors.backgroundCard,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(BookingL10n.range(context, slot.start, slot.end),
                    style: TextStyle(
                        color: slot.cancelled
                            ? AppColors.textTertiary
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        decoration: slot.cancelled
                            ? TextDecoration.lineThrough
                            : null)),
                const SizedBox(height: 6),
                if (slot.cancelled)
                  Text(l.bkSlotCancelled,
                      style: const TextStyle(
                          color: AppColors.errorRed, fontSize: 12))
                else ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      value: ratio.clamp(0.0, 1.0),
                      backgroundColor: AppColors.backgroundInput,
                      color: ratio >= 1
                          ? AppColors.errorRed
                          : AppColors.richGold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(l.bkBookedOf(slot.bookedCount, slot.capacity),
                      style: const TextStyle(
                          color: AppColors.textTertiary, fontSize: 12)),
                ],
              ],
            ),
          ),
          if (!slot.cancelled)
            PopupMenuButton<String>(
              key: ValueKey('slot-menu-${slot.id}'),
              enabled: !s.busy,
              color: AppColors.backgroundCard,
              icon: const Icon(Icons.more_vert, color: AppColors.textTertiary),
              onSelected: (v) {
                switch (v) {
                  case 'edit':
                    _edit(existing: slot);
                  case 'bookings':
                    _bookings(e);
                  case 'delete':
                    _delete(slot);
                  case 'cancel':
                    _cancelSlot(slot);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                    value: 'edit',
                    child: Text(l.bkEditDate,
                        style: const TextStyle(color: AppColors.textPrimary))),
                if (slot.hasBookings)
                  PopupMenuItem(
                      value: 'bookings',
                      child: Text(l.bkViewBookings,
                          style:
                              const TextStyle(color: AppColors.textPrimary))),
                if (!slot.hasBookings)
                  PopupMenuItem(
                      value: 'delete',
                      child: Text(l.bkDeleteDate,
                          style: const TextStyle(color: AppColors.errorRed)))
                else
                  PopupMenuItem(
                      value: 'cancel',
                      child: Text(l.bkCancelDate,
                          style: const TextStyle(color: AppColors.errorRed))),
              ],
            ),
        ]),
      ),
    );
  }
}

/// Date + start / end time + seats. Validates with [BookingRules.validateSlot]
/// before popping the [SlotDraft]. A booked slot only changes its seats.
class _SlotEditorSheet extends StatefulWidget {
  const _SlotEditorSheet({required this.experience, this.existing});
  final UserExperience experience;
  final ExperienceSlot? existing;

  @override
  State<_SlotEditorSheet> createState() => _SlotEditorSheetState();
}

class _SlotEditorSheetState extends State<_SlotEditorSheet> {
  late DateTime _date;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late final TextEditingController _capacity;
  List<SlotError> _errors = const [];

  bool get _frozen => widget.existing?.hasBookings ?? false;

  @override
  void initState() {
    super.initState();
    final x = widget.existing;
    if (x != null) {
      final s = x.start.toLocal();
      final e = x.end.toLocal();
      _date = DateTime(s.year, s.month, s.day);
      _startTime = TimeOfDay.fromDateTime(s);
      _endTime = TimeOfDay.fromDateTime(e);
      _capacity = TextEditingController(text: '${x.capacity}');
    } else {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      _date = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
      _startTime = const TimeOfDay(hour: 10, minute: 0);
      final end = DateTime(2000, 1, 1, 10)
          .add(Duration(minutes: widget.experience.durationMinutes.clamp(15, 24 * 60)));
      _endTime = TimeOfDay.fromDateTime(end);
      _capacity =
          TextEditingController(text: '${widget.experience.maxGroupSize}');
    }
  }

  @override
  void dispose() {
    _capacity.dispose();
    super.dispose();
  }

  DateTime get _start => DateTime(_date.year, _date.month, _date.day,
      _startTime.hour, _startTime.minute);

  /// Ends after midnight when the end time is not after the start time.
  DateTime get _end {
    var e = DateTime(
        _date.year, _date.month, _date.day, _endTime.hour, _endTime.minute);
    if (!e.isAfter(_start)) e = e.add(const Duration(days: 1));
    return e;
  }

  SlotDraft get _draft {
    final x = widget.existing;
    return SlotDraft(
      // Booked slots keep their exact stored times.
      start: _frozen ? x!.start : _start,
      end: _frozen ? x!.end : _end,
      capacity: int.tryParse(_capacity.text.trim()) ?? 0,
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(now) ? now : _date,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(BookingConfig.slotMaxAhead),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime(bool start) async {
    final t = await showTimePicker(
        context: context, initialTime: start ? _startTime : _endTime);
    if (t == null) return;
    setState(() {
      if (start) {
        final diff = _end.difference(_start);
        _startTime = t;
        _endTime = TimeOfDay.fromDateTime(_start.add(diff));
      } else {
        _endTime = t;
      }
    });
  }

  void _save() {
    final errors = BookingRules.validateSlot(_draft, DateTime.now(),
        existing: widget.existing);
    if (errors.isNotEmpty) {
      setState(() => _errors = errors);
      return;
    }
    Navigator.pop(context, _draft);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    Widget field(String label, String value, VoidCallback? onTap,
            {Key? key}) =>
        InkWell(
          key: key,
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.backgroundInput,
              enabled: onTap != null,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
            child: Text(value,
                style: TextStyle(
                    color: onTap != null
                        ? AppColors.textPrimary
                        : AppColors.textTertiary)),
          ),
        );
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.existing == null ? l.bkAddDate : l.bkEditDate,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            if (_frozen) ...[
              const SizedBox(height: 6),
              Text(l.bkTimesFrozen,
                  style: const TextStyle(
                      color: AppColors.warningAmber, fontSize: 12)),
            ],
            const SizedBox(height: 14),
            field(l.bkDate, BookingL10n.day(context, _date),
                _frozen ? null : _pickDate,
                key: const ValueKey('slot-date')),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: field(l.bkStartTime, _startTime.format(context),
                    _frozen ? null : () => _pickTime(true)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: field(l.bkEndTime, _endTime.format(context),
                    _frozen ? null : () => _pickTime(false)),
              ),
            ]),
            const SizedBox(height: 6),
            Text(BookingL10n.range(context, _draft.start, _draft.end),
                style: const TextStyle(
                    color: AppColors.textTertiary, fontSize: 12)),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('slot-capacity'),
              controller: _capacity,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: l.bkCapacity,
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                helperText: widget.existing?.hasBookings == true
                    ? l.bkBookedOf(widget.existing!.bookedCount,
                        widget.existing!.capacity)
                    : null,
                filled: true,
                fillColor: AppColors.backgroundInput,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            for (final err in _errors)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                    BookingL10n.slotError(l, err,
                        booked: widget.existing?.bookedCount ?? 0),
                    style: const TextStyle(
                        color: AppColors.errorRed, fontSize: 12)),
              ),
            const SizedBox(height: 14),
            BookingPrimaryButton(
              key: const ValueKey('slot-save'),
              label: l.uexpSaveChanges,
              icon: Icons.check,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
