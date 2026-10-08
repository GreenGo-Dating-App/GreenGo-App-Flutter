import 'manage_times_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/utils/user_error.dart';
import '../../../../generated/app_localizations.dart';
import '../../../user_experiences/domain/entities/user_experience.dart';
import '../../domain/booking_failure.dart';
import '../../../user_experiences/presentation/experience_l10n.dart';
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

  /// Add / edit one date, or — with [repeatFrom], or the sheet's Repeat
  /// switch — add the same times on many dates.
  Future<void> _edit({ExperienceSlot? existing, ExperienceSlot? repeatFrom}) async {
    final e = _bloc.state.experience;
    if (e == null) return;
    final result = await showModalBottomSheet<_SlotSheetResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _SlotEditorSheet(
        experience: e,
        existing: existing,
        repeatFrom: repeatFrom,
        existingStarts: [
          for (final s in _bloc.state.slots)
            if (!s.cancelled) s.start,
        ],
      ),
    );
    if (result == null || !mounted) return;
    if (result.repeat) {
      _bloc.add(SlotsRepeatRequested(result.drafts));
    } else if (result.drafts.isNotEmpty) {
      _bloc.add(SlotSaveRequested(result.drafts.first, existing: existing));
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
          case SlotsFlash.repeated:
            showBookingSnack(
                context,
                s.repeatSkipped > 0
                    ? '${l.bkRepeatAdded(s.repeatCreated)} · '
                        '${l.bkRepeatSkipped(s.repeatSkipped)}'
                    : l.bkRepeatAdded(s.repeatCreated));
          case SlotsFlash.deleted:
            showBookingSnack(context, l.bkDateDeleted);
          case SlotsFlash.cancelled:
            showBookingSnack(
                context, l.bkDateCancelled(s.cancelledBookings));
          case SlotsFlash.invalid:
            showUserErrorMessage(
                context,
                s.errors.isEmpty
                    ? l.userErrorGeneric
                    : BookingL10n.slotError(l, s.errors.first));
          case SlotsFlash.failed:
            final f = s.failure;
            if (f is BookingFailure &&
                f.code != 'permission-denied' &&
                f.code != BookingFailure.network) {
              showBookingFailure(context, f);
            } else {
              showUserErrorMessage(context, l.bkSlotSaveFailed);
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
                  key: const ValueKey('slots-manage-times'),
                  tooltip: l.mtTitle,
                  icon: const Icon(Icons.edit_calendar_outlined),
                  onPressed: () => Navigator.of(context).push(ManageTimesScreen.route(e.id)),
                ),
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
                else
                  Text(l.bkWindowPeopleBooked(slot.bookedCount),
                      style: const TextStyle(
                          color: AppColors.textTertiary, fontSize: 12)),
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
                  case 'repeat':
                    _edit(repeatFrom: slot);
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
                PopupMenuItem(
                    key: ValueKey('slot-repeat-${slot.id}'),
                    value: 'repeat',
                    child: Text(l.bkRepeatThisDate,
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

/// What the date sheet returns: one draft, or every date of a "Repeat".
typedef _SlotSheetResult = ({List<SlotDraft> drafts, bool repeat});

/// Date + start / end time + seats. Validates with [BookingRules.validateSlot]
/// before popping. A booked slot only changes its seats. When adding, the
/// "Repeat" switch applies the same times and seats to every chosen weekday
/// in a date range picked on a calendar ([BookingRules.repeatSlot]).
class _SlotEditorSheet extends StatefulWidget {
  const _SlotEditorSheet({
    required this.experience,
    this.existing,
    this.repeatFrom,
    this.existingStarts = const [],
  });
  final UserExperience experience;
  final ExperienceSlot? existing;

  /// "Repeat this date": prefill from this slot with Repeat switched on.
  final ExperienceSlot? repeatFrom;

  /// Open slots already listed (skipped by Repeat, shown in its preview).
  final List<DateTime> existingStarts;

  @override
  State<_SlotEditorSheet> createState() => _SlotEditorSheetState();
}

class _SlotEditorSheetState extends State<_SlotEditorSheet> {
  late DateTime _date;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late final TextEditingController _capacity;
  List<SlotError> _errors = const [];
  bool _repeat = false;
  DateTimeRange? _range;
  final Set<int> _weekdays = {};
  bool _noMatch = false;

  bool get _frozen => widget.existing?.hasBookings ?? false;

  @override
  void initState() {
    super.initState();
    final x = widget.existing ?? widget.repeatFrom;
    if (widget.repeatFrom != null) {
      _repeat = true;
      final d = widget.repeatFrom!.start.toLocal();
      final from = DateTime(d.year, d.month, d.day + 1);
      _range = DateTimeRange(
          start: from, end: DateTime(from.year, from.month, from.day + 27));
      _weekdays.add(d.weekday);
    }
    if (x != null) {
      final s = x.start.toLocal();
      final e = x.end.toLocal();
      _date = DateTime(s.year, s.month, s.day);
      _startTime = TimeOfDay.fromDateTime(s);
      _endTime = TimeOfDay.fromDateTime(e);
      // Private time slots: a window is booked one time at a time, so seats
      // no longer limit it; keep the stored value valid (>= people booked).
      _capacity = TextEditingController(
          text: '${x.capacity > BookingConfig.slotCapacityMax ? x.capacity : BookingConfig.slotCapacityMax}');
    } else {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      _date = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
      _weekdays.add(_date.weekday);
      _startTime = const TimeOfDay(hour: 10, minute: 0);
      final end = DateTime(2000, 1, 1, 10)
          .add(Duration(minutes: widget.experience.durationMinutes.clamp(15, 24 * 60)));
      _endTime = TimeOfDay.fromDateTime(end);
      _capacity =
          TextEditingController(text: '${BookingConfig.slotCapacityMax}');
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

  /// Dates a Repeat would add right now, soonest first — one past the cap,
  /// so the preview can say the range was cut.
  List<SlotDraft> _repeatDrafts() {
    final r = _range;
    if (r == null || _weekdays.isEmpty) return const [];
    return BookingRules.repeatSlot(
      _draft,
      from: r.start,
      to: r.end,
      weekdays: _weekdays,
      now: DateTime.now(),
      existingStarts: widget.existingStarts,
      max: BookingConfig.maxRepeatDates + 1,
    );
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final first = DateTime(now.year, now.month, now.day);
    final last = now.add(BookingConfig.slotMaxAhead);
    final initial = _range ??
        DateTimeRange(
            start: _date,
            end: DateTime(_date.year, _date.month, _date.day + 27));
    final start = initial.start.isBefore(first) ? first : initial.start;
    final end = initial.end.isAfter(last) ? last : initial.end;
    final r = await showDateRangePicker(
      context: context,
      firstDate: first,
      lastDate: last,
      initialDateRange:
          DateTimeRange(start: start, end: end.isBefore(start) ? start : end),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (r != null) {
      setState(() {
        _range = r;
        _noMatch = false;
      });
    }
  }

  void _save() {
    if (_repeat) {
      // Times and seats are checked on the template; past / too-far days are
      // simply not generated, so those two errors don't apply here.
      final errors = BookingRules.validateSlot(_draft, DateTime.now())
          .where((e) =>
              e != SlotError.startInPast && e != SlotError.tooFarAhead)
          .toList();
      final drafts =
          _repeatDrafts().take(BookingConfig.maxRepeatDates).toList();
      setState(() {
        _errors = errors;
        _noMatch = drafts.isEmpty;
      });
      if (errors.isNotEmpty || drafts.isEmpty) return;
      Navigator.pop<_SlotSheetResult>(context, (drafts: drafts, repeat: true));
      return;
    }
    final errors = BookingRules.validateSlot(_draft, DateTime.now(),
        existing: widget.existing);
    if (errors.isNotEmpty) {
      setState(() => _errors = errors);
      return;
    }
    Navigator.pop<_SlotSheetResult>(
        context, (drafts: [_draft], repeat: false));
  }

  /// Weekday chips in the locale's week order (Mon.. or Sun..).
  Widget _weekdayChips(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    DateFormat fmt;
    try {
      fmt = DateFormat.E(locale);
    } catch (_) {
      fmt = DateFormat.E();
    }
    // MaterialLocalizations: 0 = Sunday; DateTime: monday = 1 .. sunday = 7.
    final firstIndex = MaterialLocalizations.of(context).firstDayOfWeekIndex;
    final order = [
      for (var i = 0; i < 7; i++) ((firstIndex + i + 6) % 7) + 1,
    ];
    // 2024-01-01 was a Monday, so day N of that month is weekday N.
    String name(int wd) => fmt.format(DateTime(2024, 1, wd));
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final wd in order)
          FilterChip(
            key: ValueKey('slot-repeat-day-$wd'),
            label: Text(name(wd)),
            selected: _weekdays.contains(wd),
            showCheckmark: false,
            selectedColor: AppColors.richGold,
            backgroundColor: AppColors.backgroundInput,
            labelStyle: TextStyle(
                color: _weekdays.contains(wd)
                    ? AppColors.deepBlack
                    : AppColors.textPrimary),
            onSelected: (on) => setState(() {
              on ? _weekdays.add(wd) : _weekdays.remove(wd);
              _noMatch = false;
            }),
          ),
      ],
    );
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
            if (widget.existing == null) ...[
              SwitchListTile(
                key: const ValueKey('slot-repeat'),
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppColors.richGold,
                secondary: const Icon(Icons.repeat, color: AppColors.richGold),
                title: Text(l.bkRepeat,
                    style: const TextStyle(color: AppColors.textPrimary)),
                subtitle: Text(l.bkRepeatHint,
                    style: const TextStyle(
                        color: AppColors.textTertiary, fontSize: 12)),
                value: _repeat,
                onChanged: (v) => setState(() {
                  _repeat = v;
                  _noMatch = false;
                  _range ??= DateTimeRange(
                      start: _date,
                      end: DateTime(_date.year, _date.month, _date.day + 27));
                }),
              ),
              const SizedBox(height: 6),
            ],
            if (_repeat) ...[
              field(
                  l.bkRepeatDates,
                  _range == null
                      ? l.bkRepeatPickRange
                      : '${BookingL10n.day(context, _range!.start)} – '
                          '${BookingL10n.day(context, _range!.end)}',
                  _pickRange,
                  key: const ValueKey('slot-repeat-range')),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: Text(l.bkRepeatOnDays,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _weekdays.length == 7
                        ? _weekdays.clear()
                        : _weekdays.addAll(const [1, 2, 3, 4, 5, 6, 7]);
                    _noMatch = false;
                  }),
                  child: Text(l.bkRepeatEveryDay,
                      style: const TextStyle(color: AppColors.richGold)),
                ),
              ]),
              _weekdayChips(context),
              const SizedBox(height: 10),
            ] else ...[
              field(l.bkDate, BookingL10n.day(context, _date),
                  _frozen ? null : _pickDate,
                  key: const ValueKey('slot-date')),
              const SizedBox(height: 10),
            ],
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
            if (_repeat)
              Builder(builder: (context) {
                final n = _repeatDrafts().length;
                final capped = n > BookingConfig.maxRepeatDates;
                return Text(
                  capped
                      ? '${l.bkRepeatPreview(BookingConfig.maxRepeatDates)} · '
                          '${l.bkRepeatCapped(BookingConfig.maxRepeatDates)}'
                      : l.bkRepeatPreview(n),
                  key: const ValueKey('slot-repeat-preview'),
                  style: TextStyle(
                      color: n == 0 || _noMatch
                          ? AppColors.errorRed
                          : AppColors.textTertiary,
                      fontSize: 12),
                );
              })
            else
              Text(BookingL10n.range(context, _draft.start, _draft.end),
                  style: const TextStyle(
                      color: AppColors.textTertiary, fontSize: 12)),
            const SizedBox(height: 10),
            // Private time slots: the window is the host's availability;
            // guests each book one time of the experience's duration in it.
            Text(
              l.bkWindowHint(ExperienceL10n.duration(
                  l, widget.experience.durationMinutes)),
              key: const ValueKey('slot-window-hint'),
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12.5),
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
              label: _repeat
                  ? l.bkRepeatAddButton(_repeatDrafts()
                      .take(BookingConfig.maxRepeatDates)
                      .length)
                  : l.uexpSaveChanges,
              icon: Icons.check,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
