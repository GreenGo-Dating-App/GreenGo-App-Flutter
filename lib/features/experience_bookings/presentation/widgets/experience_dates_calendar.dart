import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/widgets/gg_calendar.dart';
import '../../../../generated/app_localizations.dart';
import '../../../user_experiences/domain/entities/user_experience.dart';
import '../../data/datasources/experience_availability_service.dart';
import '../../domain/availability_rules.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/bookings_repository.dart';
import '../booking_l10n.dart';
import '../screens/booking_detail_screen.dart';
import '../screens/manage_times_screen.dart';
import 'schedule_tools.dart';

/// A recurring time that is open to book (host local date + 'HH:mm').
class _OpenTime {
  const _OpenTime(this.date, this.time);
  final String date;
  final String time;
}

/// What a slot action asks the "Dates & availability" screen to do.
enum DatesSlotAction { edit, repeat, bookings, delete }

/// Host "Dates & availability" as a calendar (month / week / day):
///  * the bookings people made (requests outlined, confirmed solid) — they
///    can be opened but never deleted from here;
///  * the times still open to book: recurring times (Manage times) and the
///    dates added one by one;
///  * the Manage times tools in place: long-press a day to add a time, edit
///    or close the day; long-press an empty hour (week / day) to add a time
///    there; bulk tools from the screen menu. Schedule edits are kept locally
///    and saved together; a save that would remove a booked time is refused.
class ExperienceDatesCalendar extends StatefulWidget {
  const ExperienceDatesCalendar({
    super.key,
    required this.experience,
    required this.currentUserId,
    required this.slots,
    required this.onAddSlot,
    required this.onSlotAction,
    this.service,
    this.repository,
  });

  final UserExperience experience;
  final String currentUserId;

  /// Dates added one by one (SlotsBloc), cancelled ones included.
  final List<ExperienceSlot> slots;

  /// Add a date (one-off) starting at [at] (null = the sheet's default).
  final void Function(DateTime? at) onAddSlot;
  final void Function(ExperienceSlot slot, DatesSlotAction action) onSlotAction;

  /// Test seams.
  final ExperienceAvailabilityService? service;
  final BookingsRepository? repository;

  @override
  State<ExperienceDatesCalendar> createState() =>
      ExperienceDatesCalendarState();
}

class ExperienceDatesCalendarState extends State<ExperienceDatesCalendar> {
  late final ExperienceAvailabilityService _svc =
      widget.service ?? ExperienceAvailabilityService();
  BookingsRepository get _repo =>
      widget.repository ?? di.sl<BookingsRepository>();

  HostSchedule? _schedule;
  AvailabilityRules? _rules;
  AvailabilityOverrides _ov = const AvailabilityOverrides();
  AvailabilityOverrides _savedOv = const AvailabilityOverrides();
  bool _dirty = false;
  bool _saving = false;

  List<Booking> _bookings = const [];
  bool _loading = false;
  (DateTime, DateTime)? _range;
  int _gen = 0;

  /// Unsaved schedule edits.
  bool get dirty => _dirty;

  /// The experience uses recurring times (Manage times).
  bool get hasRules => _rules != null;

  @override
  void initState() {
    super.initState();
    unawaited(_loadSchedule());
  }

  Future<void> _loadSchedule() async {
    try {
      final s = await _svc.load(widget.experience.id);
      if (!mounted) return;
      setState(() {
        _schedule = s;
        _rules = s.rules;
        _ov = s.overrides;
        _savedOv = s.overrides;
        _dirty = false;
      });
    } catch (_) {
      // No schedule: the calendar still shows bookings and one-off dates.
    }
  }

  void _onRange(DateTime from, DateTime to) {
    _range = (from, to);
    unawaited(_loadBookings());
  }

  Future<void> reload() async {
    await Future.wait([_loadSchedule(), _loadBookings()]);
  }

  Future<void> _loadBookings() async {
    final r = _range;
    if (r == null) return;
    final gen = ++_gen;
    setState(() => _loading = true);
    // One extra day each side: the host's zone may differ from the device's.
    final res = await _repo.hostBookingsInRange(
      hostId: widget.currentUserId,
      experienceId: widget.experience.id,
      from: r.$1.subtract(const Duration(days: 1)),
      to: r.$2.add(const Duration(days: 1)),
    );
    if (!mounted || gen != _gen) return;
    setState(() {
      _loading = false;
      res.fold((_) {}, (list) => _bookings = list);
    });
  }

  // ───────────────────────────────────────────── time zone

  /// null = the device's zone is the host's (or close enough): show local
  /// times. Otherwise booked instants are shown in the host's zone.
  Duration? get _hostOffset {
    final r = _rules;
    if (r == null) return null;
    final h = kCommonTimeZones[r.timezone];
    if (h == null) return null;
    final device = DateTime.now().timeZoneOffset.inMinutes / 60;
    if ((h - device).abs() <= 1) return null;
    return Duration(minutes: (h * 60).round());
  }

  DateTime _wall(DateTime instant) {
    final off = _hostOffset;
    if (off == null) return instant.toLocal();
    final u = instant.toUtc().add(off);
    return DateTime(u.year, u.month, u.day, u.hour, u.minute);
  }

  static bool _active(BookingStatus s) =>
      s == BookingStatus.requested ||
      s == BookingStatus.confirmed ||
      s == BookingStatus.completed ||
      s == BookingStatus.noShow;

  /// Booked start times per host-local date.
  Map<String, Set<String>> get _booked {
    final out = <String, Set<String>>{};
    for (final b in _bookings) {
      if (!_active(b.status)) continue;
      final w = _wall(b.slotStart);
      out
          .putIfAbsent(dateKey(w), () => <String>{})
          .add(hmOf(w.hour * 60 + w.minute));
    }
    return out;
  }

  bool _dayHasBookings(String date) => _booked[date]?.isNotEmpty ?? false;

  // ───────────────────────────────────────────── items

  String? get _photo {
    final p = widget.experience.allPhotos;
    return p.isEmpty ? null : p.first;
  }

  List<GgCalendarItem> _items(AppLocalizations l) {
    final out = <GgCalendarItem>[];
    final photo = _photo;
    final booked = _booked;
    for (final b in _bookings) {
      if (!_active(b.status)) continue;
      out.add(GgCalendarItem(
        id: 'b-${b.id}',
        start: _wall(b.slotStart),
        end: _wall(b.slotEnd),
        title: BookingL10n.status(l, b.status),
        subtitle: l.dcGuestsBooked(b.guests),
        imageUrl: photo,
        color: BookingL10n.statusColor(b.status),
        icon: Icons.person,
        filled: b.status != BookingStatus.requested,
        payload: b,
      ));
    }
    final now = DateTime.now();
    final rules = _rules;
    final r = _range;
    if (rules != null && r != null) {
      for (var d = r.$1;
          d.isBefore(r.$2);
          d = DateTime(d.year, d.month, d.day + 1)) {
        final key = dateKey(d);
        for (final t in effectiveDayTimes(rules, _ov, key)) {
          if (booked[key]?.contains(t) ?? false) continue;
          final m = minutesOf(t)!;
          final start = DateTime(d.year, d.month, d.day, m ~/ 60, m % 60);
          if (start.isBefore(now)) continue;
          out.add(GgCalendarItem(
            id: 'r-${key}T$t',
            start: start,
            end: start.add(Duration(minutes: rules.durationMinutes)),
            title: l.dcOpenTime,
            imageUrl: photo,
            color: AppColors.successGreen,
            icon: Icons.event_available,
            filled: false,
            payload: _OpenTime(key, t),
          ));
        }
      }
    }
    for (final s in widget.slots) {
      if (s.cancelled) continue;
      out.add(GgCalendarItem(
        id: 's-${s.id}',
        start: _wall(s.start),
        end: _wall(s.end),
        title: l.dcOpenTime,
        subtitle: l.bkWindowPeopleBooked(s.bookedCount),
        imageUrl: photo,
        color: AppColors.richGold,
        icon: Icons.event_available,
        filled: false,
        payload: s,
      ));
    }
    return out;
  }

  // ───────────────────────────────────────────── actions

  void _snack(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  void _edit(AvailabilityOverrides ov) => setState(() {
        _ov = ov;
        _dirty = true;
      });

  Future<void> _openBooking(Booking b) async {
    await Navigator.of(context).push(BookingDetailScreen.route(
        bookingId: b.id, currentUserId: widget.currentUserId));
    if (mounted) unawaited(_loadBookings());
  }

  Future<void> _onTap(GgCalendarItem i) async {
    final p = i.payload;
    if (p is Booking) return _openBooking(p);
    return _onLongPress(i);
  }

  Future<void> _onLongPress(GgCalendarItem i) async {
    final l = AppLocalizations.of(context)!;
    final p = i.payload;
    if (p is Booking) {
      await _sheet(
        title: BookingL10n.range(context, p.slotStart, p.slotEnd),
        note: l.dcBookedLocked,
        actions: [
          _Action(Icons.open_in_new, l.dcOpenBooking, () => _openBooking(p),
              key: 'dc-open-booking'),
        ],
      );
    } else if (p is _OpenTime) {
      await _sheet(
        title: '${_dayLabel(parseDateKey(p.date))} · ${p.time}',
        actions: [
          _Action(Icons.event_busy, l.mtRemoveTime, () {
            if (_booked[p.date]?.contains(p.time) ?? false) {
              _snack(l.dcBookedLocked);
              return;
            }
            _edit(removeTime(_ov, p.date, p.time));
          }, key: 'dc-remove-time', danger: true),
          _Action(Icons.edit_calendar, l.dcEditDay, () => _editDay(p.date),
              key: 'dc-edit-day'),
        ],
      );
    } else if (p is ExperienceSlot) {
      await _sheet(
        title: BookingL10n.range(context, p.start, p.end),
        note: p.hasBookings ? l.dcBookedLocked : null,
        actions: [
          _Action(Icons.edit, l.bkEditDate,
              () => widget.onSlotAction(p, DatesSlotAction.edit)),
          _Action(Icons.repeat, l.bkRepeatThisDate,
              () => widget.onSlotAction(p, DatesSlotAction.repeat)),
          if (p.hasBookings)
            _Action(Icons.receipt_long, l.bkViewBookings,
                () => widget.onSlotAction(p, DatesSlotAction.bookings))
          else
            _Action(Icons.delete_outline, l.bkDeleteDate,
                () => widget.onSlotAction(p, DatesSlotAction.delete),
                danger: true),
        ],
      );
    }
  }

  String _dayLabel(DateTime d) =>
      DateFormat.MMMMEEEEd(Localizations.localeOf(context).toString())
          .format(d);

  bool _isPast(DateTime day) {
    final n = DateTime.now();
    return day.isBefore(DateTime(n.year, n.month, n.day));
  }

  Future<void> _onDayLongPress(DateTime day) async {
    final l = AppLocalizations.of(context)!;
    final key = dateKey(day);
    final past = _isPast(day);
    final closed = _ov.dayOverrides[key]?.closed == true;
    final dayBookings = [
      for (final b in _bookings)
        if (_active(b.status) && dateKey(_wall(b.slotStart)) == key) b,
    ];
    await _sheet(
      title: _dayLabel(day),
      actions: [
        if (!past && _rules != null) ...[
          _Action(Icons.more_time, l.dcAddTimeHere, () => _addTimeOn(day),
              key: 'dc-add-time'),
          _Action(Icons.edit_calendar, l.dcEditDay, () => _editDay(key),
              key: 'dc-edit-day'),
          if (closed)
            _Action(Icons.lock_open, l.dcOpenDay,
                () => _edit(setDay(_ov, key, null)),
                key: 'dc-open-day')
          else
            _Action(Icons.block, l.dcCloseDay, () {
              if (_dayHasBookings(key)) {
                _snack(l.dcCloseDayBlocked);
                return;
              }
              _edit(closeRange(_ov, key, key));
            }, key: 'dc-close-day', danger: true),
        ],
        if (!past && _rules == null)
          _Action(
              Icons.add,
              l.bkAddDate,
              () =>
                  widget.onAddSlot(DateTime(day.year, day.month, day.day, 10)),
              key: 'dc-add-date'),
        for (final b in dayBookings)
          _Action(
              Icons.person,
              '${BookingL10n.time(context, _wall(b.slotStart))} · '
              '${BookingL10n.status(l, b.status)} · ${l.dcGuestsBooked(b.guests)}',
              () => _openBooking(b),
              key: 'dc-day-booking-${b.id}'),
      ],
    );
  }

  Future<void> _onEmptyLongPress(DateTime at) async {
    final l = AppLocalizations.of(context)!;
    if (at.isBefore(DateTime.now())) return;
    if (_rules == null) {
      widget.onAddSlot(at);
      return;
    }
    final t = hmOf(at.hour * 60 + at.minute);
    await _sheet(
      title: '${_dayLabel(at)} · $t',
      actions: [
        _Action(Icons.more_time, l.dcAddTimeAt(BookingL10n.time(context, at)),
            () => _addTime(dateKey(at), t),
            key: 'dc-add-time-at'),
      ],
    );
  }

  Future<void> _addTimeOn(DateTime day) async {
    final key = dateKey(day);
    final times = effectiveDayTimes(_rules!, _ov, key);
    final t = await pickScheduleTime(
        context, times.isEmpty ? _rules!.windowStart : times.last);
    if (t != null) _addTime(key, t);
  }

  void _addTime(String date, String t) {
    final l = AppLocalizations.of(context)!;
    final e = addTimeError(_rules!, _ov, date, t);
    if (e != null) {
      _snack(e == 'overlaps'
          ? l.mtErrTimeOverlaps
          : (e == 'exists' ? l.mtErrTimeExists : l.mtErrTimeFit));
      return;
    }
    _edit(addTime(_ov, date, t));
  }

  Future<void> _editDay(String date) async {
    final s = _schedule;
    final r = _rules;
    if (s == null || r == null) return;
    final res = await showScheduleDayEditor(context,
        schedule: s,
        rules: r,
        overrides: _ov,
        date: date,
        bookedTimes: _booked[date] ?? const {});
    if (res != null && mounted) _edit(res);
  }

  /// Bulk: remove a time from every <weekday> (booked ones stay).
  Future<void> bulkRemoveTime() async {
    final r = _rules;
    if (r == null) return openSetup();
    final booked = _booked;
    final res = await showBulkRemoveTime(context,
        rules: r,
        overrides: _ov,
        isBooked: (d, t) => booked[d]?.contains(t) ?? false);
    if (res != null && mounted) _edit(res);
  }

  /// Bulk: close a date range (days with bookings stay open).
  Future<void> bulkCloseRange() async {
    if (_rules == null) return openSetup();
    final res = await showBulkCloseRange(context,
        overrides: _ov, hasBookings: _dayHasBookings);
    if (res != null && mounted) _edit(res);
  }

  /// The full Manage times setup (hours, duration, weekdays…).
  Future<void> openSetup() async {
    if (_dirty && !await confirmLeave()) return;
    if (!mounted) return;
    await Navigator.of(context)
        .push(ManageTimesScreen.route(widget.experience.id));
    if (mounted) await reload();
  }

  Future<bool> save() async {
    final r = _rules;
    if (r == null || !_dirty) return true;
    setState(() => _saving = true);
    try {
      final ok = await saveScheduleKeepingBookings(context,
          service: _svc,
          experienceId: widget.experience.id,
          rules: r,
          overrides: _ov);
      if (ok && mounted) {
        setState(() {
          _savedOv = _ov;
          _dirty = false;
        });
      }
      return ok;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void discard() => setState(() {
        _ov = _savedOv;
        _dirty = false;
      });

  /// Unsaved edits: save them, or discard them. false = stay.
  Future<bool> confirmLeave() async {
    if (!_dirty) return true;
    final l = AppLocalizations.of(context)!;
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(l.dcUnsaved,
            style: const TextStyle(color: AppColors.textPrimary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, 'discard'),
              child: Text(l.dcDiscard,
                  style: const TextStyle(color: AppColors.errorRed))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, 'save'),
              child: Text(l.tpSave)),
        ],
      ),
    );
    if (choice == 'discard') {
      discard();
      return true;
    }
    if (choice == 'save') return save();
    return false;
  }

  // ───────────────────────────────────────────── sheet

  Future<void> _sheet({
    required String title,
    String? note,
    required List<_Action> actions,
  }) async {
    final picked = await showModalBottomSheet<_Action>(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Text(title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ),
              if (note != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lock,
                            size: 16, color: AppColors.richGold),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(note,
                              key: const ValueKey('dc-locked-note'),
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13)),
                        ),
                      ]),
                ),
              for (final a in actions)
                ListTile(
                  key: a.key == null ? null : ValueKey<String>(a.key!),
                  leading: Icon(a.icon,
                      color:
                          a.danger ? AppColors.errorRed : AppColors.richGold),
                  title: Text(a.label,
                      style: TextStyle(
                          color: a.danger
                              ? AppColors.errorRed
                              : AppColors.textPrimary)),
                  onTap: () => Navigator.pop(ctx, a),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked != null && mounted) picked.run();
  }

  // ───────────────────────────────────────────── build

  Widget? _marker(DateTime day) {
    final key = dateKey(day);
    final o = _ov.dayOverrides[key];
    if (o?.closed == true) {
      return const Icon(Icons.block, size: 10, color: AppColors.errorRed);
    }
    if (o?.priceOverride != null) {
      return const Icon(Icons.sell, size: 10, color: AppColors.successGreen);
    }
    if (_ov.hasOverride(key)) {
      return const Icon(Icons.circle, size: 6, color: AppColors.richGold);
    }
    return null;
  }

  bool _dimmed(DateTime day) =>
      _isPast(day) || _ov.dayOverrides[dateKey(day)]?.closed == true;

  Widget _header(AppLocalizations l) {
    Widget legend(Color c, String t, {bool filled = true}) =>
        Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: filled ? c : null,
              border: Border.all(color: c),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 4),
          Text(t,
              style:
                  const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
        ]);
    final zone = _hostOffset == null ? null : _rules?.timezone;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (_dirty)
          Container(
            key: const ValueKey('dc-save-bar'),
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
            decoration: BoxDecoration(
              color: AppColors.richGold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.richGold.withValues(alpha: 0.5)),
            ),
            child: Row(children: [
              const Icon(Icons.edit_note, color: AppColors.richGold, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(l.dcUnsaved,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600)),
              ),
              TextButton(
                key: const ValueKey('dc-discard'),
                onPressed: _saving ? null : discard,
                child: Text(l.dcDiscard,
                    style: const TextStyle(color: AppColors.textSecondary)),
              ),
              FilledButton(
                key: const ValueKey('dc-save'),
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.richGold,
                    foregroundColor: AppColors.deepBlack),
                onPressed: _saving ? null : save,
                child: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(l.tpSave),
              ),
            ]),
          ),
        Wrap(spacing: 12, runSpacing: 4, children: [
          legend(AppColors.successGreen, l.dcLegendOpen, filled: false),
          legend(BookingL10n.statusColor(BookingStatus.requested),
              l.dcLegendRequest,
              filled: false),
          legend(BookingL10n.statusColor(BookingStatus.confirmed),
              l.dcLegendBooked),
          if (_rules != null)
            Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.block, size: 10, color: AppColors.errorRed),
              const SizedBox(width: 4),
              Text(l.dcLegendClosed,
                  style: const TextStyle(
                      color: AppColors.textTertiary, fontSize: 11)),
            ]),
          if (zone != null)
            Text(l.dcTimezoneNote(zone),
                key: const ValueKey('dc-zone'),
                style: const TextStyle(
                    color: AppColors.warningAmber, fontSize: 11)),
        ]),
        const SizedBox(height: 2),
        Text(l.calGesturesHint,
            style:
                const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return GgCalendar(
      key: const ValueKey('dates-calendar'),
      items: _items(l),
      loading: _loading,
      header: _header(l),
      onRangeChanged: _onRange,
      onItemTap: _onTap,
      onItemLongPress: _onLongPress,
      onDayLongPress: _onDayLongPress,
      onEmptyTimeLongPress: _onEmptyLongPress,
      dayMarker: _marker,
      dayDimmed: _dimmed,
    );
  }
}

class _Action {
  const _Action(this.icon, this.label, this.run,
      {this.key, this.danger = false});
  final IconData icon;
  final String label;
  final VoidCallback run;
  final String? key;
  final bool danger;
}
