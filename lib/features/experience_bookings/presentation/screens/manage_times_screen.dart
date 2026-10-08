import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/datasources/experience_availability_service.dart';
import '../../domain/availability_rules.dart';
import '../../../ticket_payments/domain/ticket_payments.dart' show currencyExponent, isoCurrencyFor, toMinorUnits;

/// Host "Manage times" (recurring availability, mobile + web):
///  1. setup card: available from / until, duration, break, start every
///     (advanced), days of the week, date range, capacity, time zone, with a
///     live preview of the generated times;
///  2. month calendar: the times of each day as chips, a dot on days with
///     changes, closed days greyed, price markers; tap a day to edit it
///     (remove / add a time, change hours, close, special price, reset,
///     copy to…);
///  3. bulk actions: remove a time from every <weekday>, close a date range.
/// Saving goes through updateExperienceAvailability; when booked times would
/// disappear the host sees how many and confirms (bookings are then cancelled,
/// guests notified and refunded by the server).
class ManageTimesScreen extends StatefulWidget {
  const ManageTimesScreen({super.key, required this.experienceId, this.service, this.initial});

  final String experienceId;
  final ExperienceAvailabilityService? service;

  /// Test seam: start from this schedule instead of reading Firestore.
  final HostSchedule? initial;

  static Route<void> route(String experienceId) =>
      MaterialPageRoute(builder: (_) => ManageTimesScreen(experienceId: experienceId));

  @override
  State<ManageTimesScreen> createState() => _ManageTimesScreenState();
}

class _ManageTimesScreenState extends State<ManageTimesScreen> {
  late final ExperienceAvailabilityService _svc = widget.service ?? ExperienceAvailabilityService();
  HostSchedule? _schedule;
  late AvailabilityRules _rules;
  AvailabilityOverrides _ov = const AvailabilityOverrides();
  late DateTime _month;
  bool _saving = false;
  bool _dirty = false;

  static const _durations = [30, 45, 60, 90, 120, 150, 180, 240, 300, 360, 480];
  static const _breaks = [0, 10, 15, 30, 45, 60, 90, 120];
  static const _steps = [15, 30, 45, 60, 90, 120, 180, 240, 300, 360, 480];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    if (widget.initial != null) {
      _apply(widget.initial!);
    } else {
      _svc.load(widget.experienceId).then((s) {
        if (mounted) setState(() => _apply(s));
      });
    }
  }

  void _apply(HostSchedule s) {
    _schedule = s;
    _rules = s.rules ??
        AvailabilityRules(
          timezone: defaultTimeZone(DateTime.now().timeZoneOffset),
          dateFrom: dateKey(DateTime.now()),
        );
    _ov = s.overrides;
  }

  void _set(VoidCallback f) => setState(() {
        f();
        _dirty = true;
      });

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    if (_rules.error != null) {
      messenger.showSnackBar(SnackBar(content: Text(_ruleError(l, _rules.error!))));
      return;
    }
    setState(() => _saving = true);
    try {
      var r = await _svc.save(widget.experienceId, _rules, _ov);
      if (r.needsConfirm && mounted) {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.backgroundCard,
            title: Text(l.mtConfirmTitle, style: const TextStyle(color: AppColors.textPrimary)),
            content: Text(l.mtConfirmBody(r.affected),
                style: const TextStyle(color: AppColors.textSecondary)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(l.mtConfirmCancelBookings, style: const TextStyle(color: AppColors.errorRed))),
            ],
          ),
        );
        if (ok != true) return;
        r = await _svc.save(widget.experienceId, _rules, _ov, confirm: true);
      }
      _dirty = false;
      messenger.showSnackBar(SnackBar(
          content: Text(r.cancelled > 0 ? l.mtSavedCancelled(r.cancelled) : l.mtSaved)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l.tpErrGeneric)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _ruleError(AppLocalizations l, String code) => switch (code) {
        'invalid_window' => l.mtErrWindow,
        'overlapping_slots' => l.mtErrOverlap,
        'invalid_weekdays' => l.mtErrWeekdays,
        _ => l.mtErrRules,
      };

  // ───────────────────────────────────────────── UI

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final s = _schedule;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: Text(l.mtTitle),
        actions: [
          TextButton(
            key: const ValueKey('mt-save'),
            onPressed: s == null || _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l.tpSave, style: TextStyle(color: _dirty ? AppColors.richGold : AppColors.textSecondary)),
          ),
        ],
      ),
      body: s == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.richGold))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView(padding: const EdgeInsets.all(16), children: [
                  _setupCard(l),
                  const SizedBox(height: 16),
                  _calendar(l),
                  const SizedBox(height: 12),
                  _bulk(l),
                ]),
              ),
            ),
    );
  }

  Widget _card(String title, List<Widget> children) => Material(
        color: AppColors.backgroundCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.divider),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 10),
            ...children,
          ]),
        ),
      );

  Future<String?> _pickTime(String initial) async {
    final m = minutesOf(initial) ?? 540;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: m ~/ 60, minute: m % 60));
    return t == null ? null : hmOf(t.hour * 60 + t.minute);
  }

  Future<String?> _pickDate(String? initial) async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: initial == null ? now : parseDateKey(initial).toLocal(),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 730)),
    );
    return d == null ? null : dateKey(d);
  }

  String _weekdayLabel(int wd, {bool short = true}) {
    final locale = Localizations.localeOf(context).toString();
    final d = DateTime(2024, 1, wd); // 1 Jan 2024 is a Monday
    return short ? DateFormat.E(locale).format(d) : DateFormat.EEEE(locale).format(d);
  }

  String _min(AppLocalizations l, int m) =>
      m >= 60 && m % 60 == 0 ? l.mtHours(m ~/ 60) : (m >= 60 ? l.mtHoursMinutes(m ~/ 60, m % 60) : l.mtMinutes(m));

  Widget _setupCard(AppLocalizations l) {
    final r = _rules;
    final preview = dayTimes(r.copyWith(weekdays: const [1, 2, 3, 4, 5, 6, 7]), dateKey(DateTime(2024, 1, 1)));
    final zones = {...kCommonTimeZones.keys, r.timezone}.toList()..sort();
    return _card(l.mtSetupTitle, [
      Row(children: [
        Expanded(
          child: _field(l.mtAvailableFrom, r.windowStart, () async {
            final t = await _pickTime(r.windowStart);
            if (t != null) _set(() => _rules = _rules.copyWith(windowStart: t));
          }, key: 'mt-from'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _field(l.mtAvailableUntil, r.windowEnd, () async {
            final t = await _pickTime(r.windowEnd);
            if (t != null) _set(() => _rules = _rules.copyWith(windowEnd: t));
          }, key: 'mt-until'),
        ),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            key: const ValueKey('mt-duration'),
            value: _durations.contains(r.durationMinutes) ? r.durationMinutes : null,
            dropdownColor: AppColors.backgroundCard,
            decoration: InputDecoration(labelText: l.mtDuration),
            items: [for (final d in _durations) DropdownMenuItem(value: d, child: Text(_min(l, d)))],
            onChanged: (v) => _set(() => _rules = _rules.copyWith(durationMinutes: v)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonFormField<int>(
            key: const ValueKey('mt-break'),
            value: _breaks.contains(r.bufferMinutes) ? r.bufferMinutes : 0,
            dropdownColor: AppColors.backgroundCard,
            decoration: InputDecoration(labelText: l.mtBreak),
            items: [for (final d in _breaks) DropdownMenuItem(value: d, child: Text(d == 0 ? l.mtNoBreak : _min(l, d)))],
            onChanged: (v) => _set(() => _rules = _rules.copyWith(bufferMinutes: v)),
          ),
        ),
      ]),
      ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(l.mtAdvanced, style: const TextStyle(color: AppColors.textSecondary)),
        children: [
          DropdownButtonFormField<int?>(
            key: const ValueKey('mt-step'),
            value: r.startEveryMinutes,
            dropdownColor: AppColors.backgroundCard,
            decoration: InputDecoration(labelText: l.mtStartEvery),
            items: [
              DropdownMenuItem<int?>(value: null, child: Text(l.mtStartEveryAuto)),
              for (final d in _steps.where((d) => d >= r.durationMinutes))
                DropdownMenuItem<int?>(value: d, child: Text(_min(l, d))),
            ],
            onChanged: (v) => _set(() => _rules = v == null
                ? _rules.copyWith(clearStartEvery: true)
                : _rules.copyWith(startEveryMinutes: v)),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: const ValueKey('mt-timezone'),
            value: r.timezone,
            isExpanded: true,
            dropdownColor: AppColors.backgroundCard,
            decoration: InputDecoration(labelText: l.mtTimezone),
            items: [for (final z in zones) DropdownMenuItem(value: z, child: Text(z))],
            onChanged: (v) => _set(() => _rules = _rules.copyWith(timezone: v)),
          ),
        ],
      ),
      const SizedBox(height: 6),
      Text(l.mtDaysOfWeek, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
      Wrap(spacing: 6, children: [
        for (var wd = 1; wd <= 7; wd++)
          FilterChip(
            key: ValueKey('mt-wd-$wd'),
            label: Text(_weekdayLabel(wd)),
            selected: r.weekdays.contains(wd),
            onSelected: (v) => _set(() {
              final w = {...r.weekdays};
              v ? w.add(wd) : w.remove(wd);
              _rules = _rules.copyWith(weekdays: w.toList()..sort());
            }),
          ),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(
          child: _field(l.mtDateFrom, r.dateFrom ?? '—', () async {
            final d = await _pickDate(r.dateFrom);
            if (d != null) _set(() => _rules = _rules.copyWith(dateFrom: d));
          }),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _field(l.mtDateTo, r.dateTo ?? l.mtNoEnd, () async {
            final d = await _pickDate(r.dateTo ?? r.dateFrom);
            _set(() => _rules = d == null ? _rules.copyWith(clearDateTo: true) : _rules.copyWith(dateTo: d));
          }),
        ),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: Text(l.mtCapacity, style: const TextStyle(color: AppColors.textSecondary))),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline, color: AppColors.richGold),
          onPressed: r.capacityPerSlot > 1 ? () => _set(() => _rules = _rules.copyWith(capacityPerSlot: r.capacityPerSlot - 1)) : null,
        ),
        Text('${r.capacityPerSlot}', key: const ValueKey('mt-capacity'), style: const TextStyle(color: AppColors.textPrimary)),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, color: AppColors.richGold),
          onPressed: r.capacityPerSlot < 500 ? () => _set(() => _rules = _rules.copyWith(capacityPerSlot: r.capacityPerSlot + 1)) : null,
        ),
      ]),
      const SizedBox(height: 6),
      Text(l.mtPreview, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
      const SizedBox(height: 4),
      if (r.error != null)
        Text(_ruleError(l, r.error!), key: const ValueKey('mt-rule-error'), style: const TextStyle(color: AppColors.errorRed))
      else
        Wrap(key: const ValueKey('mt-preview'), spacing: 6, runSpacing: 6, children: [
          for (final t in preview) Chip(label: Text(t), visualDensity: VisualDensity.compact),
        ]),
      const SizedBox(height: 10),
      ElevatedButton.icon(
        key: const ValueKey('mt-apply'),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.richGold, foregroundColor: AppColors.deepBlack),
        onPressed: _saving || r.error != null ? null : _save,
        icon: const Icon(Icons.done_all),
        label: Text(l.mtApplyAll),
      ),
    ]);
  }

  Widget _field(String label, String value, VoidCallback onTap, {String? key}) => InkWell(
        key: key == null ? null : ValueKey(key),
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(labelText: label),
          child: Text(value, style: const TextStyle(color: AppColors.textPrimary)),
        ),
      );

  // Month calendar ------------------------------------------------------------

  Widget _calendar(AppLocalizations l) {
    final locale = Localizations.localeOf(context).toString();
    final first = DateTime(_month.year, _month.month);
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final lead = first.weekday - 1;
    final s = _schedule!;
    return _card(l.mtCalendarTitle, [
      Row(children: [
        IconButton(
          tooltip: l.mtPrevMonth,
          icon: const Icon(Icons.chevron_left),
          onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
        ),
        Expanded(
          child: Text(DateFormat.yMMMM(locale).format(first),
              textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        ),
        IconButton(
          tooltip: l.mtNextMonth,
          icon: const Icon(Icons.chevron_right),
          onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
        ),
      ]),
      Row(children: [
        for (var wd = 1; wd <= 7; wd++)
          Expanded(
            child: Text(_weekdayLabel(wd),
                textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
          ),
      ]),
      const SizedBox(height: 4),
      GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 0.72,
        children: [
          for (var i = 0; i < lead; i++) const SizedBox.shrink(),
          for (var d = 1; d <= days; d++) _dayCell(l, s, dateKey(DateTime(_month.year, _month.month, d)), d),
        ],
      ),
      const SizedBox(height: 6),
      Wrap(spacing: 12, children: [
        _legend(Icons.circle, AppColors.richGold, l.mtLegendChanged),
        _legend(Icons.sell, AppColors.successGreen, l.mtLegendSpecialPrice),
        _legend(Icons.weekend, AppColors.infoBlue, l.mtLegendWeekendPrice),
      ]),
    ]);
  }

  Widget _legend(IconData i, Color c, String t) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(i, size: 10, color: c),
        const SizedBox(width: 4),
        Text(t, style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
      ]);

  Widget _dayCell(AppLocalizations l, HostSchedule s, String date, int day) {
    final times = effectiveDayTimes(_rules, _ov, date);
    final closed = times.isEmpty;
    final changed = _ov.hasOverride(date);
    final special = _ov.dayOverrides[date]?.priceOverride != null;
    final weekend = !special && s.weekendPrice != null && isWeekendDay(date, s.weekendDays);
    final past = date.compareTo(dateKey(DateTime.now())) < 0;
    return Semantics(
      button: true,
      label: '$date: ${closed ? l.mtClosed : times.join(', ')}', // i18n-ignore: date + localized status / times
      child: InkWell(
        key: ValueKey('mt-day-$date'),
        onTap: past ? null : () => _editDay(l, date),
        child: Container(
          margin: const EdgeInsets.all(2),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: closed || past ? AppColors.backgroundInput.withValues(alpha: 0.4) : AppColors.backgroundInput,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('$day',
                  style: TextStyle(
                      color: past || closed ? AppColors.textTertiary : AppColors.textPrimary,
                      fontSize: 12, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (changed) const Icon(Icons.circle, size: 6, color: AppColors.richGold),
              if (special) const Icon(Icons.sell, size: 9, color: AppColors.successGreen),
              if (weekend) const Icon(Icons.weekend, size: 9, color: AppColors.infoBlue),
            ]),
            for (final t in times.take(2))
              Text(t, style: const TextStyle(color: AppColors.richGold, fontSize: 9.5)),
            if (times.length > 2)
              Text('+${times.length - 2}', style: const TextStyle(color: AppColors.textTertiary, fontSize: 9.5)),
          ]),
        ),
      ),
    );
  }

  // Day editor ---------------------------------------------------------------

  Future<void> _editDay(AppLocalizations l, String date) async {
    var ov = _ov;
    final s0 = _schedule!;
    final cur = isoCurrencyFor(s0.currency) ?? 'usd';
    double? shown(double? v) => v == null ? null : (s0.perGroup ? v / (currencyExponent(cur) == 0 ? 1 : 100) : v);
    double stored(double v) => s0.perGroup ? toMinorUnits(v, cur).toDouble() : v;
    final priceCtrl = TextEditingController(text: shown(ov.dayOverrides[date]?.priceOverride)?.toString() ?? '');
    final result = await showModalBottomSheet<AvailabilityOverrides>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundCard,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        final times = effectiveDayTimes(_rules, ov, date);
        final day = ov.dayOverrides[date];
        final closed = day?.closed == true;
        DayOverride cur() => day ?? const DayOverride();
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.viewInsetsOf(ctx).bottom),
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
              Text(DateFormat.yMMMMEEEEd(Localizations.localeOf(ctx).toString()).format(parseDateKey(date)),
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
              SwitchListTile(
                key: const ValueKey('mt-day-closed'),
                contentPadding: EdgeInsets.zero,
                title: Text(l.mtCloseDay),
                value: closed,
                onChanged: (v) => setS(() => ov = setDay(ov, date,
                    DayOverride(closed: v, priceOverride: day?.priceOverride, windowStart: v ? null : day?.windowStart, windowEnd: v ? null : day?.windowEnd))),
              ),
              if (!closed) ...[
                Wrap(spacing: 6, runSpacing: 6, children: [
                  for (final t in times)
                    InputChip(
                      key: ValueKey('mt-time-$t'),
                      label: Text(t),
                      onDeleted: () => setS(() => ov = removeTime(ov, date, t)),
                      deleteButtonTooltipMessage: l.mtRemoveTime,
                    ),
                  ActionChip(
                    key: const ValueKey('mt-add-time'),
                    avatar: const Icon(Icons.add, size: 16),
                    label: Text(l.mtAddTime),
                    onPressed: () async {
                      final t = await _pickTime(times.isEmpty ? _rules.windowStart : times.last);
                      if (t == null) return;
                      final e = addTimeError(_rules, ov, date, t);
                      if (e != null) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(e == 'overlaps' ? l.mtErrTimeOverlaps : (e == 'exists' ? l.mtErrTimeExists : l.mtErrTimeFit))));
                        }
                        return;
                      }
                      setS(() => ov = addTime(ov, date, t));
                    },
                  ),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final t = await _pickTime(day?.windowStart ?? _rules.windowStart);
                        if (t != null) {
                          setS(() => ov = setDay(ov, date, DayOverride(windowStart: t, windowEnd: cur().windowEnd ?? _rules.windowEnd, priceOverride: day?.priceOverride)));
                        }
                      },
                      child: Text('${l.mtAvailableFrom}: ${day?.windowStart ?? _rules.windowStart}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final t = await _pickTime(day?.windowEnd ?? _rules.windowEnd);
                        if (t != null) {
                          setS(() => ov = setDay(ov, date, DayOverride(windowStart: cur().windowStart ?? _rules.windowStart, windowEnd: t, priceOverride: day?.priceOverride)));
                        }
                      },
                      child: Text('${l.mtAvailableUntil}: ${day?.windowEnd ?? _rules.windowEnd}'),
                    ),
                  ),
                ]),
              ],
              const SizedBox(height: 8),
              TextField(
                key: const ValueKey('mt-day-price'),
                controller: priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: l.mtSpecialPrice, hintText: l.mtSpecialPriceHint),
                onChanged: (v) {
                  final p = double.tryParse(v.replaceAll(',', '.'));
                  final c = ov.dayOverrides[date] ?? const DayOverride();
                  ov = setDay(ov, date, DayOverride(
                      closed: c.closed, windowStart: c.windowStart, windowEnd: c.windowEnd, slots: c.slots,
                      priceOverride: p != null && p > 0 ? stored(p) : null));
                },
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                TextButton.icon(
                  key: const ValueKey('mt-day-reset'),
                  onPressed: () => setS(() {
                    ov = resetDay(ov, date);
                    priceCtrl.text = '';
                  }),
                  icon: const Icon(Icons.restore),
                  label: Text(l.mtResetDay),
                ),
                TextButton.icon(
                  onPressed: () {
                    final first = DateTime(parseDateKey(date).year, parseDateKey(date).month);
                    final last = DateTime(first.year, first.month + 1, 0);
                    final targets = datesBetween(dateKey(first), dateKey(last))
                        .where((d) => weekdayOfKey(d) == weekdayOfKey(date) && d.compareTo(dateKey(DateTime.now())) >= 0);
                    setS(() => ov = copyDay(_rules, ov, date, targets));
                  },
                  icon: const Icon(Icons.copy_all),
                  label: Text(l.mtCopyToWeekdays(_weekdayLabel(weekdayOfKey(date), short: false))),
                ),
                TextButton.icon(
                  onPressed: () {
                    final first = DateTime(parseDateKey(date).year, parseDateKey(date).month);
                    final last = DateTime(first.year, first.month + 1, 0);
                    final targets = datesBetween(dateKey(first), dateKey(last))
                        .where((d) => d.compareTo(dateKey(DateTime.now())) >= 0);
                    setS(() => ov = copyDay(_rules, ov, date, targets));
                  },
                  icon: const Icon(Icons.calendar_view_month),
                  label: Text(l.mtCopyToMonth),
                ),
              ]),
              const SizedBox(height: 8),
              ElevatedButton(
                key: const ValueKey('mt-day-done'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.richGold, foregroundColor: AppColors.deepBlack),
                onPressed: () => Navigator.pop(ctx, ov),
                child: Text(l.mtDone),
              ),
            ]),
          ),
        );
      }),
    );
    priceCtrl.dispose();
    if (result != null && mounted) _set(() => _ov = result);
  }

  // Bulk actions -------------------------------------------------------------

  Widget _bulk(AppLocalizations l) => _card(l.mtBulkTitle, [
        OutlinedButton.icon(
          key: const ValueKey('mt-bulk-remove'),
          onPressed: _bulkRemove,
          icon: const Icon(Icons.event_busy),
          label: Text(l.mtBulkRemoveTime),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const ValueKey('mt-bulk-close'),
          onPressed: _bulkClose,
          icon: const Icon(Icons.beach_access),
          label: Text(l.mtBulkCloseRange),
        ),
        const SizedBox(height: 6),
        Text(l.mtBulkHint, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
      ]);

  Future<void> _bulkRemove() async {
    final l = AppLocalizations.of(context)!;
    final times = dayTimes(_rules.copyWith(weekdays: const [1, 2, 3, 4, 5, 6, 7]), '2024-01-01');
    if (times.isEmpty) return;
    var wd = _rules.weekdays.isEmpty ? 1 : _rules.weekdays.first;
    var time = times.first;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: AppColors.backgroundCard,
          title: Text(l.mtBulkRemoveTime, style: const TextStyle(color: AppColors.textPrimary)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<int>(
              value: wd,
              dropdownColor: AppColors.backgroundCard,
              decoration: InputDecoration(labelText: l.mtDaysOfWeek),
              items: [for (var i = 1; i <= 7; i++) DropdownMenuItem(value: i, child: Text(_weekdayLabel(i, short: false)))],
              onChanged: (v) => setD(() => wd = v ?? wd),
            ),
            DropdownButtonFormField<String>(
              value: time,
              dropdownColor: AppColors.backgroundCard,
              decoration: InputDecoration(labelText: l.mtTime),
              items: [for (final t in times) DropdownMenuItem(value: t, child: Text(t))],
              onChanged: (v) => setD(() => time = v ?? time),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.mtRemoveTime)),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final from = _rules.dateFrom != null && _rules.dateFrom!.compareTo(dateKey(DateTime.now())) > 0
        ? _rules.dateFrom!
        : dateKey(DateTime.now());
    final to = _rules.dateTo ?? dateKey(DateTime.now().add(Duration(days: _rules.maxAdvanceDays)));
    _set(() => _ov = removeTimeOnWeekday(_rules, _ov, wd, time, from, to));
  }

  Future<void> _bulkClose() async {
    final now = DateTime.now();
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (r == null) return;
    _set(() => _ov = closeRange(_ov, dateKey(r.start), dateKey(r.end)));
  }
}
