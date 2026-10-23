import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../../ticket_payments/domain/ticket_payments.dart'
    show currencyExponent, isoCurrencyFor, toMinorUnits;
import '../../data/datasources/experience_availability_service.dart';
import '../../domain/availability_rules.dart';
import '../../../../core/services/sound_feedback.dart';

/// The "Manage times" tools shared by the Manage times screen and the
/// "Dates & availability" calendar: day editor, bulk actions and the save
/// that never deletes booked appointments.

Future<String?> pickScheduleTime(BuildContext context, String initial) async {
  final m = minutesOf(initial) ?? 540;
  final t = await showTimePicker(
      context: context, initialTime: TimeOfDay(hour: m ~/ 60, minute: m % 60));
  return t == null ? null : hmOf(t.hour * 60 + t.minute);
}

String scheduleWeekdayLabel(BuildContext context, int wd, {bool short = true}) {
  final locale = Localizations.localeOf(context).toString();
  final d = DateTime(2024, 1, wd); // 1 Jan 2024 is a Monday
  return short
      ? DateFormat.E(locale).format(d)
      : DateFormat.EEEE(locale).format(d);
}

String scheduleRuleError(AppLocalizations l, String code) => switch (code) {
      'invalid_window' => l.mtErrWindow,
      'overlapping_slots' => l.mtErrOverlap,
      'invalid_weekdays' => l.mtErrWeekdays,
      _ => l.mtErrRules,
    };

/// Saves the schedule. When booked times would disappear the server reports
/// how many; booked appointments are never deleted from here, so the host is
/// told to keep those times (or cancel each booking first) and nothing is
/// saved. Returns true when saved.
Future<bool> saveScheduleKeepingBookings(
  BuildContext context, {
  required ExperienceAvailabilityService service,
  required String experienceId,
  required AvailabilityRules rules,
  required AvailabilityOverrides overrides,
}) async {
  final l = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  if (rules.error != null) {
    messenger.showSnackBar(
        SnackBar(content: Text(scheduleRuleError(l, rules.error!))));
    return false;
  }
  try {
    final r = await service.save(experienceId, rules, overrides);
    if (r.needsConfirm) {
      if (context.mounted) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            key: const ValueKey('schedule-save-blocked'),
            backgroundColor: AppColors.backgroundCard,
            icon: const Icon(Icons.lock_clock,
                color: AppColors.warningAmber, size: 32),
            title: Text(l.dcSaveBlockedTitle,
                style: const TextStyle(color: AppColors.textPrimary)),
            content: Text(l.dcSaveBlockedBody(r.affected),
                style: const TextStyle(color: AppColors.textSecondary)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx), child: Text(l.ok)),
            ],
          ),
        );
      }
      return false;
    }
    messenger.showSnackBar(SnackBar(
        content: Text(
            r.cancelled > 0 ? l.mtSavedCancelled(r.cancelled) : l.mtSaved)));
    return true;
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(l.tpErrGeneric)));
    return false;
  }
}

/// Edits one day: close it, remove / add a time, change its hours, special
/// price, reset, copy to the same weekday / the whole month. [bookedTimes]
/// ('HH:mm', host local) cannot be removed and keep the day open.
Future<AvailabilityOverrides?> showScheduleDayEditor(
  BuildContext context, {
  required HostSchedule schedule,
  required AvailabilityRules rules,
  required AvailabilityOverrides overrides,
  required String date,
  Set<String> bookedTimes = const {},
}) async {
  final l = AppLocalizations.of(context)!;
  var ov = overrides;
  final cur = isoCurrencyFor(schedule.currency) ?? 'usd';
  double? shown(double? v) => v == null
      ? null
      : (schedule.perGroup
          ? v / (currencyExponent(cur) == 0 ? 1 : 100)
          : v);
  double stored(double v) =>
      schedule.perGroup ? toMinorUnits(v, cur).toDouble() : v;
  final priceCtrl = TextEditingController(
      text: shown(ov.dayOverrides[date]?.priceOverride)?.toString() ?? '');
  final messenger = ScaffoldMessenger.of(context);
  void snack(String text) =>
      messenger.showSnackBar(SnackBar(content: Text(text)));
  final today = dateKey(DateTime.now());
  final result = await showModalBottomSheet<AvailabilityOverrides>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.backgroundCard,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
      final times = effectiveDayTimes(rules, ov, date);
      final day = ov.dayOverrides[date];
      final closed = day?.closed == true;
      final booked = bookedTimes.isNotEmpty;
      DayOverride cur() => day ?? const DayOverride();
      return Padding(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, 16 + MediaQuery.viewInsetsOf(ctx).bottom),
        child: SingleChildScrollView(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    DateFormat.yMMMMEEEEd(
                            Localizations.localeOf(ctx).toString())
                        .format(parseDateKey(date)),
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                SwitchListTile(
                  key: const ValueKey('mt-day-closed'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.mtCloseDay),
                  subtitle: booked && !closed
                      ? Text(l.dcCloseDayBlocked,
                          style: const TextStyle(
                              color: AppColors.textTertiary, fontSize: 12))
                      : null,
                  value: closed,
                  onChanged: withToggleSound(booked && !closed
                      ? null
                      : (v) => setS(() => ov = setDay(
                          ov,
                          date,
                          DayOverride(
                              closed: v,
                              priceOverride: day?.priceOverride,
                              windowStart: v ? null : day?.windowStart,
                              windowEnd: v ? null : day?.windowEnd)))),
                ),
                if (!closed) ...[
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    for (final t in times)
                      bookedTimes.contains(t)
                          ? InputChip(
                              key: ValueKey('mt-time-$t'),
                              avatar: const Icon(Icons.lock,
                                  size: 14, color: AppColors.richGold),
                              label: Text(t),
                              tooltip: l.dcBookedLocked,
                              onPressed: () => snack(l.dcBookedLocked),
                            )
                          : InputChip(
                              key: ValueKey('mt-time-$t'),
                              label: Text(t),
                              onDeleted: () =>
                                  setS(() => ov = removeTime(ov, date, t)),
                              deleteButtonTooltipMessage: l.mtRemoveTime,
                            ),
                    ActionChip(
                      key: const ValueKey('mt-add-time'),
                      avatar: const Icon(Icons.add, size: 16),
                      label: Text(l.mtAddTime),
                      onPressed: () async {
                        final t = await pickScheduleTime(
                            ctx, times.isEmpty ? rules.windowStart : times.last);
                        if (t == null) return;
                        final e = addTimeError(rules, ov, date, t);
                        if (e != null) {
                          snack(e == 'overlaps'
                              ? l.mtErrTimeOverlaps
                              : (e == 'exists'
                                  ? l.mtErrTimeExists
                                  : l.mtErrTimeFit));
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
                          final t = await pickScheduleTime(
                              ctx, day?.windowStart ?? rules.windowStart);
                          if (t != null) {
                            setS(() => ov = setDay(
                                ov,
                                date,
                                DayOverride(
                                    windowStart: t,
                                    windowEnd:
                                        cur().windowEnd ?? rules.windowEnd,
                                    priceOverride: day?.priceOverride)));
                          }
                        },
                        child: Text(
                            '${l.mtAvailableFrom}: ${day?.windowStart ?? rules.windowStart}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final t = await pickScheduleTime(
                              ctx, day?.windowEnd ?? rules.windowEnd);
                          if (t != null) {
                            setS(() => ov = setDay(
                                ov,
                                date,
                                DayOverride(
                                    windowStart:
                                        cur().windowStart ?? rules.windowStart,
                                    windowEnd: t,
                                    priceOverride: day?.priceOverride)));
                          }
                        },
                        child: Text(
                            '${l.mtAvailableUntil}: ${day?.windowEnd ?? rules.windowEnd}'),
                      ),
                    ),
                  ]),
                ],
                const SizedBox(height: 8),
                TextField(
                  key: const ValueKey('mt-day-price'),
                  controller: priceCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                      labelText: l.mtSpecialPrice,
                      hintText: l.mtSpecialPriceHint),
                  onChanged: (v) {
                    final p = double.tryParse(v.replaceAll(',', '.'));
                    final c = ov.dayOverrides[date] ?? const DayOverride();
                    ov = setDay(
                        ov,
                        date,
                        DayOverride(
                            closed: c.closed,
                            windowStart: c.windowStart,
                            windowEnd: c.windowEnd,
                            slots: c.slots,
                            priceOverride:
                                p != null && p > 0 ? stored(p) : null));
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
                      final first = DateTime(parseDateKey(date).year,
                          parseDateKey(date).month);
                      final last = DateTime(first.year, first.month + 1, 0);
                      final targets = datesBetween(
                              dateKey(first), dateKey(last))
                          .where((d) =>
                              weekdayOfKey(d) == weekdayOfKey(date) &&
                              d.compareTo(today) >= 0);
                      setS(() => ov = copyDay(rules, ov, date, targets));
                    },
                    icon: const Icon(Icons.copy_all),
                    label: Text(l.mtCopyToWeekdays(scheduleWeekdayLabel(
                        ctx, weekdayOfKey(date),
                        short: false))),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      final first = DateTime(parseDateKey(date).year,
                          parseDateKey(date).month);
                      final last = DateTime(first.year, first.month + 1, 0);
                      final targets =
                          datesBetween(dateKey(first), dateKey(last))
                              .where((d) => d.compareTo(today) >= 0);
                      setS(() => ov = copyDay(rules, ov, date, targets));
                    },
                    icon: const Icon(Icons.calendar_view_month),
                    label: Text(l.mtCopyToMonth),
                  ),
                ]),
                const SizedBox(height: 8),
                ElevatedButton(
                  key: const ValueKey('mt-day-done'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.richGold,
                      foregroundColor: AppColors.deepBlack),
                  onPressed: () => Navigator.pop(ctx, ov),
                  child: Text(l.mtDone),
                ),
              ]),
        ),
      );
    }),
  );
  priceCtrl.dispose();
  return result;
}

/// Bulk: remove one time from every chosen weekday (from today / the rules'
/// start to their end or the booking horizon). [isBooked] ('date', 'HH:mm')
/// keeps booked appointments.
Future<AvailabilityOverrides?> showBulkRemoveTime(
  BuildContext context, {
  required AvailabilityRules rules,
  required AvailabilityOverrides overrides,
  bool Function(String date, String time)? isBooked,
}) async {
  final l = AppLocalizations.of(context)!;
  final times = dayTimes(
      rules.copyWith(weekdays: const [1, 2, 3, 4, 5, 6, 7]), '2024-01-01');
  if (times.isEmpty) return null;
  var wd = rules.weekdays.isEmpty ? 1 : rules.weekdays.first;
  var time = times.first;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(l.mtBulkRemoveTime,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<int>(
            value: wd,
            dropdownColor: AppColors.backgroundCard,
            decoration: InputDecoration(labelText: l.mtDaysOfWeek),
            items: [
              for (var i = 1; i <= 7; i++)
                DropdownMenuItem(
                    value: i,
                    child: Text(scheduleWeekdayLabel(ctx, i, short: false)))
            ],
            onChanged: (v) => setD(() => wd = v ?? wd),
          ),
          DropdownButtonFormField<String>(
            value: time,
            dropdownColor: AppColors.backgroundCard,
            decoration: InputDecoration(labelText: l.mtTime),
            items: [
              for (final t in times) DropdownMenuItem(value: t, child: Text(t))
            ],
            onChanged: (v) => setD(() => time = v ?? time),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.mtRemoveTime)),
        ],
      ),
    ),
  );
  if (ok != true) return null;
  final today = dateKey(DateTime.now());
  final from = rules.dateFrom != null && rules.dateFrom!.compareTo(today) > 0
      ? rules.dateFrom!
      : today;
  final to = rules.dateTo ??
      dateKey(DateTime.now().add(Duration(days: rules.maxAdvanceDays)));
  var out = overrides;
  for (final d in datesBetween(from, to)) {
    if (weekdayOfKey(d) != wd) continue;
    if (isBooked?.call(d, time) ?? false) continue;
    if (effectiveDayTimes(rules, out, d).contains(time)) {
      out = removeTime(out, d, time);
    }
  }
  return out;
}

/// Bulk: close a date range (vacation). Days with bookings stay open.
Future<AvailabilityOverrides?> showBulkCloseRange(
  BuildContext context, {
  required AvailabilityOverrides overrides,
  bool Function(String date)? hasBookings,
}) async {
  final now = DateTime.now();
  final r = await showDateRangePicker(
    context: context,
    firstDate: DateTime(now.year, now.month, now.day),
    lastDate: now.add(const Duration(days: 730)),
  );
  if (r == null) return null;
  var out = overrides;
  for (final d in datesBetween(dateKey(r.start), dateKey(r.end))) {
    if (hasBookings?.call(d) ?? false) continue;
    out = closeRange(out, d, d);
  }
  return out;
}
