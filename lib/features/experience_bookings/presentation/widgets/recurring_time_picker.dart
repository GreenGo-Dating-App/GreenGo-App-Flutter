import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../../ticket_payments/domain/ticket_payments.dart' show formatTicketAmount;
import '../../../user_experiences/domain/entities/user_experience.dart';
import '../../data/datasources/experience_availability_service.dart';
import '../../domain/availability_rules.dart' show dateKey, parseDateKey;

/// Buyer: calendar with ONLY bookable days enabled, then the times of the
/// chosen day with what is left and the price of that date ("10:00 – 3
/// seats left · R$ 90"). Times are the host's; when the buyer's own clock
/// differs the local time is shown too. Data: getExperienceAvailability
/// (server-computed, next 60 days).
class RecurringTimePicker extends StatefulWidget {
  const RecurringTimePicker({
    super.key,
    required this.experience,
    required this.onPicked,
    this.selected,
    this.service,
    this.initialPage,
  });

  final UserExperience experience;
  final ValueChanged<AvailableTime> onPicked;
  final AvailableTime? selected;
  final ExperienceAvailabilityService? service;

  /// Test seam.
  final AvailabilityPage? initialPage;

  @override
  State<RecurringTimePicker> createState() => _RecurringTimePickerState();
}

class _RecurringTimePickerState extends State<RecurringTimePicker> {
  late final ExperienceAvailabilityService _svc = widget.service ?? ExperienceAvailabilityService();
  AvailabilityPage? _page;
  bool _failed = false;
  String? _date;

  @override
  void initState() {
    super.initState();
    if (widget.initialPage != null) {
      _setPage(widget.initialPage!);
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final now = DateTime.now();
      final p = await _svc.times(widget.experience.id, now, now.add(const Duration(days: 60)));
      if (mounted) setState(() => _setPage(p));
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _setPage(AvailabilityPage p) {
    _page = p;
    final dates = p.times.map((t) => t.date).toSet();
    _date = widget.selected?.date ?? (dates.isEmpty ? null : (dates.toList()..sort()).first);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final p = _page;
    if (_failed) {
      return Row(children: [
        Expanded(child: Text(l.somethingWentWrong, style: const TextStyle(color: AppColors.textSecondary))),
        TextButton(onPressed: _load, child: Text(l.bkRetry)),
      ]);
    }
    if (p == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(color: AppColors.richGold)),
      );
    }
    if (p.times.isEmpty) {
      return Text(l.bkNoDates, style: const TextStyle(color: AppColors.textSecondary));
    }
    final byDate = <String, List<AvailableTime>>{};
    for (final t in p.times) {
      byDate.putIfAbsent(t.date, () => []).add(t);
    }
    final dates = byDate.keys.toList()..sort();
    final first = parseDateKey(dates.first).toLocal();
    final last = parseDateKey(dates.last).toLocal();
    final selectedDate = _date ?? dates.first;
    final locale = Localizations.localeOf(context).toString();
    final times = byDate[selectedDate] ?? const <AvailableTime>[];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (p.timezone != null)
        Text(l.rtTimesIn(p.timezone!), style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
      Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppColors.richGold),
        ),
        child: CalendarDatePicker(
          key: const ValueKey('recurring-calendar'),
          initialDate: DateTime(parseDateKey(selectedDate).year, parseDateKey(selectedDate).month, parseDateKey(selectedDate).day),
          firstDate: DateTime(first.year, first.month, first.day),
          lastDate: DateTime(last.year, last.month, last.day),
          selectableDayPredicate: (d) => byDate.containsKey(dateKey(d)),
          onDateChanged: (d) => setState(() => _date = dateKey(d)),
        ),
      ),
      const SizedBox(height: 6),
      for (final t in times) _timeTile(l, t, locale),
    ]);
  }

  Widget _timeTile(AppLocalizations l, AvailableTime t, String locale) {
    final e = widget.experience;
    final selected = widget.selected?.key == t.key;
    final local = t.start.toLocal();
    final localTime = DateFormat.Hm(locale).format(local);
    final differs = localTime != t.time || dateKey(local) != t.date;
    final left = e.isPerGroup ? l.rtGroupsLeft(t.remaining) : l.rtSeatsLeft(t.remaining);
    final price = e.isFree || t.currency == null ? null : formatTicketAmount(t.unitAmount, t.currency!);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? AppColors.richGold.withValues(alpha: 0.2) : AppColors.backgroundInput,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: selected ? AppColors.richGold : AppColors.divider),
        ),
        child: ListTile(
          key: ValueKey('recurring-time-${t.key}'),
          onTap: () => widget.onPicked(t),
          title: Text('${t.time} – $left', style: const TextStyle(color: AppColors.textPrimary)),
          subtitle: differs
              ? Text(l.rtYourTime(DateFormat.MMMd(locale).add_Hm().format(local)),
                  style: const TextStyle(color: AppColors.textTertiary, fontSize: 12))
              : null,
          trailing: price == null
              ? null
              : Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(price, style: const TextStyle(color: AppColors.richGold, fontWeight: FontWeight.w600)),
                  if (t.priceRule != 'base')
                    Text(t.priceRule == 'weekend' ? l.rtWeekendPrice : l.rtSpecialPrice,
                        style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                ]),
        ),
      ),
    );
  }
}
