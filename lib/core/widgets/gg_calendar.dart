import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../generated/app_localizations.dart';
import '../constants/app_colors.dart';

/// The three views of [GgCalendar].
enum GgCalendarView { month, week, day }

/// One thing on the calendar: a booking, an open time, an event…
class GgCalendarItem {
  const GgCalendarItem({
    required this.id,
    required this.start,
    required this.end,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.color = AppColors.richGold,
    this.icon = Icons.event,
    this.filled = true,
    this.payload,
  });

  final String id;

  /// Local wall-clock times.
  final DateTime start;
  final DateTime end;
  final String title;
  final String? subtitle;

  /// Shown as a tiny square; [icon] on [color] when null or broken.
  final String? imageUrl;
  final Color color;
  final IconData icon;

  /// true = solid (booked, going…); false = outlined (open time).
  final bool filled;
  final Object? payload;
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Month / week / day calendar shared by "Dates & availability" and My Space.
///
/// Gestures:
///  * tap a day (month) — select it; its agenda shows below the grid
///  * double-tap a day (month) or a week day header — open the day view
///  * long-press a day — [onDayLongPress] (day actions)
///  * long-press an empty time (week / day) — [onEmptyTimeLongPress]
///  * double-tap the time grid — zoom the hours in / out
///  * swipe left / right — next / previous month, week or day
///  * tap / long-press an item — [onItemTap] / [onItemLongPress]
///
/// The parent owns the data: [onRangeChanged] reports the visible range each
/// time it changes so only that range is loaded.
class GgCalendar extends StatefulWidget {
  const GgCalendar({
    super.key,
    required this.items,
    this.initialDate,
    this.initialView = GgCalendarView.month,
    this.onRangeChanged,
    this.onItemTap,
    this.onItemLongPress,
    this.onDayLongPress,
    this.onEmptyTimeLongPress,
    this.dayMarker,
    this.dayDimmed,
    this.emptyText,
    this.loading = false,
    this.header,
  });

  final List<GgCalendarItem> items;
  final DateTime? initialDate;
  final GgCalendarView initialView;

  /// [from] inclusive, [to] exclusive (local midnights).
  final void Function(DateTime from, DateTime to)? onRangeChanged;
  final void Function(GgCalendarItem item)? onItemTap;
  final void Function(GgCalendarItem item)? onItemLongPress;
  final void Function(DateTime day)? onDayLongPress;

  /// The time is rounded down to the half hour.
  final void Function(DateTime at)? onEmptyTimeLongPress;

  /// A small extra mark in a month cell (closed day, special price…).
  final Widget? Function(DateTime day)? dayMarker;

  /// Greyed day (closed, past…).
  final bool Function(DateTime day)? dayDimmed;

  /// Agenda text for a day with nothing on it.
  final String? emptyText;
  final bool loading;

  /// Extra widget between the toolbar and the grid (filters…).
  final Widget? header;

  @override
  State<GgCalendar> createState() => GgCalendarState();
}

class GgCalendarState extends State<GgCalendar> {
  late GgCalendarView _view = widget.initialView;
  late DateTime _focus = _day(widget.initialDate ?? DateTime.now());
  late DateTime _selected = _focus;
  double _hourHeight = 52;
  final ScrollController _grid = ScrollController();
  bool _gridPositioned = false;

  GgCalendarView get view => _view;
  DateTime get selectedDay => _selected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reportRange());
  }

  @override
  void dispose() {
    _grid.dispose();
    super.dispose();
  }

  int get _firstWeekday {
    // MaterialLocalizations: 0 = Sunday; DateTime: monday = 1 .. sunday = 7.
    final i = MaterialLocalizations.of(context).firstDayOfWeekIndex;
    return i == 0 ? 7 : i;
  }

  DateTime _weekStart(DateTime d) {
    final back = (d.weekday - _firstWeekday + 7) % 7;
    return _day(d).subtract(Duration(days: back));
  }

  /// [from, to) of what is on screen.
  (DateTime, DateTime) get range {
    switch (_view) {
      case GgCalendarView.month:
        final first = DateTime(_focus.year, _focus.month);
        final from = _weekStart(first);
        final last = DateTime(_focus.year, _focus.month + 1);
        var to = _weekStart(last);
        if (to.isBefore(last)) to = to.add(const Duration(days: 7));
        return (from, to);
      case GgCalendarView.week:
        final from = _weekStart(_focus);
        return (from, from.add(const Duration(days: 7)));
      case GgCalendarView.day:
        return (_focus, _focus.add(const Duration(days: 1)));
    }
  }

  void _reportRange() {
    if (!mounted) return;
    final r = range;
    widget.onRangeChanged?.call(r.$1, r.$2);
  }

  void setView(GgCalendarView v, {DateTime? day}) {
    setState(() {
      _view = v;
      if (day != null) {
        _focus = _day(day);
        _selected = _focus;
      } else if (v != GgCalendarView.month) {
        _focus = _selected;
      }
      _gridPositioned = false;
    });
    _reportRange();
  }

  void _shift(int dir) {
    setState(() {
      switch (_view) {
        case GgCalendarView.month:
          _focus = DateTime(_focus.year, _focus.month + dir);
          final days = DateTime(_focus.year, _focus.month + 1, 0).day;
          _selected =
              DateTime(_focus.year, _focus.month, _selected.day.clamp(1, days));
        case GgCalendarView.week:
          _focus = DateTime(_focus.year, _focus.month, _focus.day + 7 * dir);
          _selected = _focus;
        case GgCalendarView.day:
          _focus = DateTime(_focus.year, _focus.month, _focus.day + dir);
          _selected = _focus;
      }
    });
    _reportRange();
  }

  void _today() {
    final t = _day(DateTime.now());
    setState(() {
      _focus = t;
      _selected = t;
      _gridPositioned = false;
    });
    _reportRange();
  }

  List<GgCalendarItem> _itemsOn(DateTime day) {
    final from = _day(day);
    final to = from.add(const Duration(days: 1));
    return widget.items
        .where((i) => i.start.isBefore(to) && i.end.isAfter(from) ||
            _sameDay(i.start, from))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  String get _locale => Localizations.localeOf(context).toString();

  String _title() {
    switch (_view) {
      case GgCalendarView.month:
        return DateFormat.yMMMM(_locale).format(_focus);
      case GgCalendarView.week:
        final r = range;
        final end = r.$2.subtract(const Duration(days: 1));
        return '${DateFormat.MMMd(_locale).format(r.$1)} – '
            '${DateFormat.yMMMd(_locale).format(end)}';
      case GgCalendarView.day:
        return DateFormat.yMMMMEEEEd(_locale).format(_focus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _toolbar(l),
        if (widget.header != null) widget.header!,
        if (widget.loading)
          const LinearProgressIndicator(
              minHeight: 2, color: AppColors.richGold),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: (d) {
              final v = d.primaryVelocity ?? 0;
              if (v.abs() < 250) return;
              _shift(v < 0 ? 1 : -1);
            },
            child: switch (_view) {
              GgCalendarView.month => _month(l),
              GgCalendarView.week => _timeGrid(l, week: true),
              GgCalendarView.day => _timeGrid(l, week: false),
            },
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────── toolbar

  Widget _toolbar(AppLocalizations l) {
    Widget seg(GgCalendarView v, String label) {
      final on = _view == v;
      return Expanded(
        child: InkWell(
          key: ValueKey('cal-view-${v.name}'),
          borderRadius: BorderRadius.circular(10),
          onTap: () => setView(v),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            constraints: const BoxConstraints(minHeight: 36),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: on
                  ? const LinearGradient(
                      colors: [AppColors.richGold, AppColors.accentGold])
                  : null,
            ),
            child: Text(label,
                style: TextStyle(
                    color: on ? AppColors.deepBlack : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(13),
            border:
                Border.all(color: AppColors.richGold.withValues(alpha: 0.18)),
          ),
          child: Row(children: [
            seg(GgCalendarView.month, l.calViewMonth),
            const SizedBox(width: 3),
            seg(GgCalendarView.week, l.calViewWeek),
            const SizedBox(width: 3),
            seg(GgCalendarView.day, l.calViewDay),
          ]),
        ),
        Row(children: [
          IconButton(
            key: const ValueKey('cal-prev'),
            tooltip: l.calPrevious,
            icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
            onPressed: () => _shift(-1),
          ),
          Expanded(
            child: Text(_title(),
                key: const ValueKey('cal-title'),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
          ),
          TextButton(
            key: const ValueKey('cal-today'),
            onPressed: _today,
            style: TextButton.styleFrom(
                foregroundColor: AppColors.richGold,
                minimumSize: const Size(44, 40)),
            child: Text(l.calToday),
          ),
          IconButton(
            key: const ValueKey('cal-next'),
            tooltip: l.calNext,
            icon:
                const Icon(Icons.chevron_right, color: AppColors.textPrimary),
            onPressed: () => _shift(1),
          ),
        ]),
      ]),
    );
  }

  List<String> _weekdayNames() {
    final fmt = DateFormat.E(_locale);
    // 2024-01-01 was a Monday, so day N of that month is weekday N.
    return [
      for (var i = 0; i < 7; i++)
        fmt.format(DateTime(2024, 1, ((_firstWeekday - 1 + i) % 7) + 1)),
    ];
  }

  // ───────────────────────────────────────────── month

  Widget _month(AppLocalizations l) {
    final r = range;
    final days = r.$2.difference(r.$1).inDays;
    final names = _weekdayNames();
    final agenda = _itemsOn(_selected);
    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 720;
      final cellH = wide ? 92.0 : 64.0;
      final grid = Column(children: [
        Row(children: [
          for (final n in names)
            Expanded(
              child: Text(n,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textTertiary, fontSize: 11)),
            ),
        ]),
        const SizedBox(height: 4),
        for (var w = 0; w < days ~/ 7; w++)
          SizedBox(
            height: cellH,
            child: Row(children: [
              for (var d = 0; d < 7; d++)
                Expanded(
                  child: _monthCell(
                      DateTime(r.$1.year, r.$1.month, r.$1.day + w * 7 + d),
                      wide),
                ),
            ]),
          ),
      ]);
      final list = _agenda(l, agenda);
      if (wide) {
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              flex: 3,
              child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: grid)),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: list),
        ]);
      }
      return CustomScrollView(slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          sliver: SliverToBoxAdapter(child: grid),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(DateFormat.MMMMEEEEd(_locale).format(_selected),
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700)),
          ),
        ),
        if (agenda.isEmpty)
          SliverToBoxAdapter(child: _emptyAgenda(l))
        else
          SliverList.list(children: [
            for (final i in agenda) _agendaTile(i),
            const SizedBox(height: 96),
          ]),
      ]);
    });
  }

  Widget _monthCell(DateTime day, bool wide) {
    final inMonth = day.month == _focus.month;
    final today = _sameDay(day, DateTime.now());
    final selected = _sameDay(day, _selected);
    final dimmed = !inMonth || (widget.dayDimmed?.call(day) ?? false);
    final items = _itemsOn(day);
    final marker = widget.dayMarker?.call(day);
    final max = wide ? 6 : 3;
    return Semantics(
      button: true,
      selected: selected,
      label: '${DateFormat.yMMMMd(_locale).format(day)}, ${items.length}',
      child: GestureDetector(
        key: ValueKey('cal-day-${day.year}-${day.month}-${day.day}'),
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _selected = day),
        onDoubleTap: () => setView(GgCalendarView.day, day: day),
        onLongPress: widget.onDayLongPress == null
            ? null
            : () {
                setState(() => _selected = day);
                widget.onDayLongPress!(day);
              },
        child: Container(
          margin: const EdgeInsets.all(1.5),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.richGold.withValues(alpha: 0.16)
                : AppColors.backgroundInput
                    .withValues(alpha: dimmed ? 0.35 : 1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: today
                  ? AppColors.richGold
                  : selected
                      ? AppColors.richGold.withValues(alpha: 0.5)
                      : Colors.transparent,
              width: today ? 1.4 : 1,
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('${day.day}',
                  style: TextStyle(
                      color: dimmed
                          ? AppColors.textTertiary
                          : AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: today ? FontWeight.w800 : FontWeight.w600)),
              const Spacer(),
              if (marker != null) marker,
            ]),
            const SizedBox(height: 2),
            Expanded(
              child: Wrap(
                spacing: 2,
                runSpacing: 2,
                clipBehavior: Clip.hardEdge,
                children: [
                  for (final i in items.take(max)) GgCalendarThumb(item: i, size: 13),
                  if (items.length > max)
                    Text('+${items.length - max}',
                        style: const TextStyle(
                            color: AppColors.textTertiary, fontSize: 9.5)),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _agenda(AppLocalizations l, List<GgCalendarItem> items) => ListView(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 96),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Text(DateFormat.MMMMEEEEd(_locale).format(_selected),
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700)),
          ),
          if (items.isEmpty) _emptyAgenda(l) else ...items.map(_agendaTile),
        ],
      );

  Widget _emptyAgenda(AppLocalizations l) => Padding(
        padding: const EdgeInsets.all(24),
        child: Text(widget.emptyText ?? l.calNothingThisDay,
            key: const ValueKey('cal-empty-day'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textTertiary)),
      );

  String _hm(DateTime d) => DateFormat.jm(_locale).format(d);

  Widget _agendaTile(GgCalendarItem i) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Material(
          color: AppColors.backgroundCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
                color: i.color.withValues(alpha: i.filled ? 0.5 : 0.25)),
          ),
          child: InkWell(
            key: ValueKey('cal-item-${i.id}'),
            borderRadius: BorderRadius.circular(12),
            onTap: widget.onItemTap == null ? null : () => widget.onItemTap!(i),
            onLongPress: widget.onItemLongPress == null
                ? null
                : () => widget.onItemLongPress!(i),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(children: [
                GgCalendarThumb(item: i, size: 40),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(i.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(
                            [
                              '${_hm(i.start)} – ${_hm(i.end)}',
                              if (i.subtitle != null && i.subtitle!.isNotEmpty)
                                i.subtitle!,
                            ].join(' · '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.textTertiary, fontSize: 12)),
                      ]),
                ),
                if (widget.onItemLongPress != null)
                  IconButton(
                    tooltip: MaterialLocalizations.of(context)
                        .showMenuTooltip,
                    icon: const Icon(Icons.more_vert,
                        color: AppColors.textTertiary),
                    onPressed: () => widget.onItemLongPress!(i),
                  ),
              ]),
            ),
          ),
        ),
      );

  // ───────────────────────────────────────────── week / day

  Widget _timeGrid(AppLocalizations l, {required bool week}) {
    final r = range;
    final days = [
      for (var i = 0; i < (week ? 7 : 1); i++)
        DateTime(r.$1.year, r.$1.month, r.$1.day + i),
    ];
    if (!_gridPositioned) {
      _gridPositioned = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_grid.hasClients) return;
        // Scroll to the first item of the range, or 7:00.
        final first = widget.items
            .where((i) => !i.start.isBefore(r.$1) && i.start.isBefore(r.$2))
            .map((i) => i.start.hour)
            .fold<int?>(null, (m, h) => m == null || h < m ? h : m);
        final h = ((first ?? 7) - 1).clamp(0, 23);
        _grid.jumpTo(
            (h * _hourHeight).clamp(0.0, _grid.position.maxScrollExtent));
      });
    }
    const gutter = 44.0;
    return Column(children: [
      // Day headers.
      Row(children: [
        const SizedBox(width: gutter),
        for (final d in days)
          Expanded(
            child: InkWell(
              key: ValueKey('cal-head-${d.year}-${d.month}-${d.day}'),
              onTap: week ? () => setView(GgCalendarView.day, day: d) : null,
              onLongPress: widget.onDayLongPress == null
                  ? null
                  : () => widget.onDayLongPress!(d),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(children: [
                  Text(DateFormat.E(_locale).format(d),
                      style: const TextStyle(
                          color: AppColors.textTertiary, fontSize: 11)),
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _sameDay(d, DateTime.now())
                          ? AppColors.richGold
                          : Colors.transparent,
                    ),
                    child: Text('${d.day}',
                        style: TextStyle(
                            color: _sameDay(d, DateTime.now())
                                ? AppColors.deepBlack
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ),
                  if (widget.dayMarker?.call(d) case final m?) m,
                ]),
              ),
            ),
          ),
      ]),
      const Divider(height: 1, color: AppColors.divider),
      Expanded(
        child: GestureDetector(
          onDoubleTap: () =>
              setState(() => _hourHeight = _hourHeight > 60 ? 44 : 84),
          child: SingleChildScrollView(
            key: const ValueKey('cal-grid'),
            controller: _grid,
            padding: const EdgeInsets.only(bottom: 96),
            child: SizedBox(
              height: 24 * _hourHeight,
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(
                  width: gutter,
                  child: Stack(children: [
                    for (var h = 1; h < 24; h++)
                      Positioned(
                        top: h * _hourHeight - 7,
                        right: 6,
                        child: Text(
                            DateFormat.j(_locale).format(DateTime(2024, 1, 1, h)),
                            style: const TextStyle(
                                color: AppColors.textTertiary, fontSize: 10)),
                      ),
                  ]),
                ),
                for (final d in days)
                  Expanded(child: _dayColumn(d, compact: week)),
              ]),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _dayColumn(DateTime day, {required bool compact}) {
    final items = _itemsOn(day);
    final dimmed = widget.dayDimmed?.call(day) ?? false;
    // Greedy lanes so overlapping items sit side by side.
    final lanes = <List<GgCalendarItem>>[];
    final laneOf = <GgCalendarItem, int>{};
    for (final i in items) {
      var placed = false;
      for (var k = 0; k < lanes.length; k++) {
        if (!lanes[k].last.end.isAfter(i.start)) {
          lanes[k].add(i);
          laneOf[i] = k;
          placed = true;
          break;
        }
      }
      if (!placed) {
        lanes.add([i]);
        laneOf[i] = lanes.length - 1;
      }
    }
    final n = lanes.isEmpty ? 1 : lanes.length;
    final from = _day(day);
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPressStart: widget.onEmptyTimeLongPress == null
            ? null
            : (d) {
                final mins = (d.localPosition.dy / _hourHeight * 60).floor();
                final half = (mins ~/ 30) * 30;
                widget.onEmptyTimeLongPress!(
                    from.add(Duration(minutes: half.clamp(0, 23 * 60 + 30))));
              },
        child: Container(
          decoration: BoxDecoration(
            color: dimmed
                ? AppColors.backgroundInput.withValues(alpha: 0.25)
                : null,
            border: const Border(
                left: BorderSide(color: AppColors.divider, width: 0.5)),
          ),
          child: Stack(children: [
            for (var h = 1; h < 24; h++)
              Positioned(
                top: h * _hourHeight,
                left: 0,
                right: 0,
                child: Container(height: 0.5, color: AppColors.divider),
              ),
            if (_sameDay(day, DateTime.now()))
              Positioned(
                top: (DateTime.now().hour * 60 + DateTime.now().minute) /
                    60 *
                    _hourHeight,
                left: 0,
                right: 0,
                child: Container(height: 1.5, color: AppColors.errorRed),
              ),
            for (final i in items)
              _block(i, from, laneOf[i]!, n, w, compact),
          ]),
        ),
      );
    });
  }

  Widget _block(GgCalendarItem i, DateTime dayStart, int lane, int lanes,
      double width, bool compact) {
    final s = i.start.isBefore(dayStart) ? dayStart : i.start;
    final dayEnd = dayStart.add(const Duration(days: 1));
    final e = i.end.isAfter(dayEnd) ? dayEnd : i.end;
    final top = s.difference(dayStart).inMinutes / 60 * _hourHeight;
    final h = (e.difference(s).inMinutes / 60 * _hourHeight)
        .clamp(compact ? 18.0 : 22.0, 24 * _hourHeight);
    final laneW = width / lanes;
    return Positioned(
      top: top,
      left: lane * laneW + 1,
      width: laneW - 2,
      height: h,
      child: Tooltip(
        message: '${i.title} · ${_hm(i.start)}',
        child: Material(
          color: i.filled
              ? i.color.withValues(alpha: 0.85)
              : AppColors.backgroundCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(color: i.color, width: i.filled ? 0 : 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: ValueKey('cal-block-${i.id}'),
            onTap: widget.onItemTap == null ? null : () => widget.onItemTap!(i),
            onLongPress: widget.onItemLongPress == null
                ? null
                : () => widget.onItemLongPress!(i),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: compact || laneW < 70
                  ? Align(
                      alignment: Alignment.topLeft,
                      child: GgCalendarThumb(item: i, size: 14))
                  : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      GgCalendarThumb(item: i, size: h >= 40 ? 28 : 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${_hm(i.start)} ${i.title}'
                          '${i.subtitle == null ? '' : '\n${i.subtitle}'}',
                          maxLines: (h / 14).floor().clamp(1, 4),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: i.filled
                                  ? AppColors.deepBlack
                                  : AppColors.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              height: 1.2),
                        ),
                      ),
                    ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// The tiny square of an item: its image, or its icon on its color.
class GgCalendarThumb extends StatelessWidget {
  const GgCalendarThumb({super.key, required this.item, this.size = 14});

  final GgCalendarItem item;
  final double size;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(size <= 16 ? 3 : 8);
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: item.filled ? item.color : AppColors.backgroundCard,
        borderRadius: r,
        border: item.filled ? null : Border.all(color: item.color),
      ),
      child: size >= 20
          ? Icon(item.icon,
              size: size * 0.55,
              color: item.filled ? AppColors.deepBlack : item.color)
          : null,
    );
    final url = item.imageUrl;
    if (url == null || url.isEmpty) return fallback;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: r,
        border: Border.all(color: item.color, width: size <= 16 ? 1 : 1.5),
      ),
      child: ClipRRect(
        borderRadius: r,
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          memCacheWidth: (size * 3).round(),
          placeholder: (_, __) => fallback,
          errorWidget: (_, __, ___) => fallback,
        ),
      ),
    );
  }
}
