import 'package:equatable/equatable.dart';

/// Recurring experience schedule (mirror of functions/src/experience_bookings/
/// availability.ts). Everything here works on the HOST's local dates and times
/// ('YYYY-MM-DD', 'HH:mm'), so previews need no time-zone math; the server
/// converts to UTC with the host's IANA zone.
class AvailabilityRules extends Equatable {
  const AvailabilityRules({
    this.timezone = 'America/Sao_Paulo',
    this.windowStart = '09:00',
    this.windowEnd = '18:00',
    this.durationMinutes = 120,
    this.bufferMinutes = 0,
    this.startEveryMinutes,
    this.weekdays = const [1, 2, 3, 4, 5, 6, 7],
    this.dateFrom,
    this.dateTo,
    this.capacityPerSlot = 10,
    this.minNoticeHours = 24,
    this.maxAdvanceDays = 60,
  });

  final String timezone;
  final String windowStart;
  final String windowEnd;
  final int durationMinutes;
  final int bufferMinutes;

  /// Advanced: null = duration + buffer.
  final int? startEveryMinutes;

  /// 1 = Monday .. 7 = Sunday.
  final List<int> weekdays;
  final String? dateFrom;
  final String? dateTo;

  /// Seats (per person) or groups (per group) per time.
  final int capacityPerSlot;
  final int minNoticeHours;
  final int maxAdvanceDays;

  int get step => startEveryMinutes ?? durationMinutes + bufferMinutes;

  factory AvailabilityRules.fromMap(Map<String, dynamic> m) => AvailabilityRules(
        timezone: m['timezone'] as String? ?? 'UTC',
        windowStart: m['windowStart'] as String? ?? '09:00',
        windowEnd: m['windowEnd'] as String? ?? '18:00',
        durationMinutes: (m['durationMinutes'] as num?)?.toInt() ?? 120,
        bufferMinutes: (m['bufferMinutes'] as num?)?.toInt() ?? 0,
        startEveryMinutes: (m['startEveryMinutes'] as num?)?.toInt(),
        weekdays: (m['weekdays'] as List?)?.whereType<num>().map((e) => e.toInt()).toList() ??
            const [1, 2, 3, 4, 5, 6, 7],
        dateFrom: m['dateFrom'] as String?,
        dateTo: m['dateTo'] as String?,
        capacityPerSlot: (m['capacityPerSlot'] as num?)?.toInt() ?? 10,
        minNoticeHours: (m['minNoticeHours'] as num?)?.toInt() ?? 24,
        maxAdvanceDays: (m['maxAdvanceDays'] as num?)?.toInt() ?? 60,
      );

  Map<String, dynamic> toMap() => {
        'timezone': timezone,
        'windowStart': windowStart,
        'windowEnd': windowEnd,
        'durationMinutes': durationMinutes,
        'bufferMinutes': bufferMinutes,
        if (startEveryMinutes != null) 'startEveryMinutes': startEveryMinutes,
        'weekdays': weekdays,
        'dateFrom': dateFrom,
        'dateTo': dateTo,
        'capacityPerSlot': capacityPerSlot,
        'minNoticeHours': minNoticeHours,
        'maxAdvanceDays': maxAdvanceDays,
      };

  AvailabilityRules copyWith({
    String? timezone,
    String? windowStart,
    String? windowEnd,
    int? durationMinutes,
    int? bufferMinutes,
    int? startEveryMinutes,
    bool clearStartEvery = false,
    List<int>? weekdays,
    String? dateFrom,
    String? dateTo,
    bool clearDateTo = false,
    int? capacityPerSlot,
  }) =>
      AvailabilityRules(
        timezone: timezone ?? this.timezone,
        windowStart: windowStart ?? this.windowStart,
        windowEnd: windowEnd ?? this.windowEnd,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        bufferMinutes: bufferMinutes ?? this.bufferMinutes,
        startEveryMinutes: clearStartEvery ? null : (startEveryMinutes ?? this.startEveryMinutes),
        weekdays: weekdays ?? this.weekdays,
        dateFrom: dateFrom ?? this.dateFrom,
        dateTo: clearDateTo ? null : (dateTo ?? this.dateTo),
        capacityPerSlot: capacityPerSlot ?? this.capacityPerSlot,
        minNoticeHours: minNoticeHours,
        maxAdvanceDays: maxAdvanceDays,
      );

  /// Same checks as the server's rulesError (null = valid).
  String? get error {
    final ws = minutesOf(windowStart);
    final we = minutesOf(windowEnd);
    if (ws == null || we == null || we <= ws) return 'invalid_window';
    if (durationMinutes < 15 || durationMinutes > 24 * 60) return 'invalid_duration';
    if (bufferMinutes < 0 || bufferMinutes > 600) return 'invalid_buffer';
    if (weekdays.isEmpty) return 'invalid_weekdays';
    if (capacityPerSlot < 1 || capacityPerSlot > 500) return 'invalid_capacity';
    if (step < durationMinutes) return 'overlapping_slots';
    return null;
  }

  @override
  List<Object?> get props => [timezone, windowStart, windowEnd, durationMinutes, bufferMinutes,
        startEveryMinutes, weekdays, dateFrom, dateTo, capacityPerSlot, minNoticeHours, maxAdvanceDays];
}

class DayOverride extends Equatable {
  const DayOverride({this.closed = false, this.windowStart, this.windowEnd, this.slots, this.priceOverride});

  final bool closed;
  final String? windowStart;
  final String? windowEnd;

  /// Explicit list: replaces the generated times of that day.
  final List<String>? slots;

  /// Special price for that day (same unit as the listing's base price).
  final double? priceOverride;

  bool get isEmpty => !closed && windowStart == null && windowEnd == null && slots == null && priceOverride == null;

  factory DayOverride.fromMap(Map<String, dynamic> m) => DayOverride(
        closed: m['closed'] == true,
        windowStart: m['windowStart'] as String?,
        windowEnd: m['windowEnd'] as String?,
        slots: (m['slots'] as List?)?.whereType<String>().toList(),
        priceOverride: (m['priceOverride'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toMap() => {
        if (closed) 'closed': true,
        if (windowStart != null) 'windowStart': windowStart,
        if (windowEnd != null) 'windowEnd': windowEnd,
        if (slots != null) 'slots': slots,
        if (priceOverride != null) 'priceOverride': priceOverride,
      };

  @override
  List<Object?> get props => [closed, windowStart, windowEnd, slots, priceOverride];
}

class AvailabilityOverrides extends Equatable {
  const AvailabilityOverrides({
    this.dayOverrides = const {},
    this.removedSlots = const {},
    this.addedSlots = const {},
  });

  final Map<String, DayOverride> dayOverrides;

  /// 'YYYY-MM-DDTHH:mm'.
  final Set<String> removedSlots;
  final Set<String> addedSlots;

  factory AvailabilityOverrides.fromMap(Map<String, dynamic>? m) {
    final d = <String, DayOverride>{};
    final raw = m?['dayOverrides'];
    if (raw is Map) {
      raw.forEach((k, v) {
        if (v is Map) d['$k'] = DayOverride.fromMap(Map<String, dynamic>.from(v));
      });
    }
    Set<String> set(Object? v) => (v is List) ? v.whereType<String>().toSet() : <String>{};
    return AvailabilityOverrides(
        dayOverrides: d, removedSlots: set(m?['removedSlots']), addedSlots: set(m?['addedSlots']));
  }

  Map<String, dynamic> toMap() => {
        'dayOverrides': {
          for (final e in dayOverrides.entries)
            if (!e.value.isEmpty) e.key: e.value.toMap(),
        },
        'removedSlots': removedSlots.toList()..sort(),
        'addedSlots': addedSlots.toList()..sort(),
      };

  AvailabilityOverrides copyWith({
    Map<String, DayOverride>? dayOverrides,
    Set<String>? removedSlots,
    Set<String>? addedSlots,
  }) =>
      AvailabilityOverrides(
        dayOverrides: dayOverrides ?? this.dayOverrides,
        removedSlots: removedSlots ?? this.removedSlots,
        addedSlots: addedSlots ?? this.addedSlots,
      );

  bool hasOverride(String date) =>
      (dayOverrides[date] != null && !dayOverrides[date]!.isEmpty) ||
      removedSlots.any((k) => k.startsWith(date)) ||
      addedSlots.any((k) => k.startsWith(date));

  @override
  List<Object?> get props => [dayOverrides, removedSlots, addedSlots];
}

// ─────────────────────────────────────────────────────────── pure helpers

final RegExp _hm = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');

int? minutesOf(String? hm) {
  final m = hm == null ? null : _hm.firstMatch(hm);
  return m == null ? null : int.parse(m[1]!) * 60 + int.parse(m[2]!);
}

String hmOf(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';

String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime parseDateKey(String k) {
  final p = k.split('-').map(int.parse).toList();
  return DateTime.utc(p[0], p[1], p[2]);
}

/// ISO weekday of a local date key (1 = Monday).
int weekdayOfKey(String date) => parseDateKey(date).weekday;

/// Generated / overridden start times of one day BEFORE single removals and
/// additions. Precedence: closed > explicit slots > window change > generated.
List<String> dayTimes(AvailabilityRules r, String date, [DayOverride? ov]) {
  if (ov?.closed == true) return const [];
  if (ov?.slots != null && ov!.slots!.isNotEmpty) {
    return (ov.slots!.where((t) => minutesOf(t) != null).toSet().toList()..sort());
  }
  final changedWindow = ov?.windowStart != null || ov?.windowEnd != null;
  if (!changedWindow && !r.weekdays.contains(weekdayOfKey(date))) return const [];
  final ws = minutesOf(ov?.windowStart ?? r.windowStart);
  final we = minutesOf(ov?.windowEnd ?? r.windowEnd);
  if (ws == null || we == null || we <= ws || r.durationMinutes <= 0 || r.step <= 0) return const [];
  return [for (var t = ws; t + r.durationMinutes <= we; t += r.step) hmOf(t)];
}

/// What buyers can book that day (without notice / capacity), host local.
List<String> effectiveDayTimes(AvailabilityRules r, AvailabilityOverrides o, String date) {
  if (r.dateFrom != null && date.compareTo(r.dateFrom!) < 0) return const [];
  if (r.dateTo != null && date.compareTo(r.dateTo!) > 0) return const [];
  final ov = o.dayOverrides[date];
  final out = {
    for (final t in dayTimes(r, date, ov))
      if (!o.removedSlots.contains('${date}T$t')) t,
  };
  if (ov?.closed != true) {
    for (final k in o.addedSlots) {
      if (k.startsWith('${date}T')) out.add(k.substring(11));
    }
  }
  return out.toList()..sort();
}

/// Adding [time] on [date]: must fit before midnight and not overlap the
/// day's other times (duration-aware). Returns an error code or null.
String? addTimeError(AvailabilityRules r, AvailabilityOverrides o, String date, String time) {
  final t = minutesOf(time);
  if (t == null) return 'invalid_time';
  if (t + r.durationMinutes > 24 * 60) return 'does_not_fit';
  for (final x in effectiveDayTimes(r, o, date)) {
    final m = minutesOf(x)!;
    if (m == t) return 'exists';
    if (t < m + r.durationMinutes && m < t + r.durationMinutes) return 'overlaps';
  }
  return null;
}

AvailabilityOverrides removeTime(AvailabilityOverrides o, String date, String time) {
  final key = '${date}T$time';
  final added = {...o.addedSlots}..remove(key);
  final ov = o.dayOverrides[date];
  if (ov?.slots != null) {
    final d = {...o.dayOverrides};
    d[date] = DayOverride(
        closed: ov!.closed,
        windowStart: ov.windowStart,
        windowEnd: ov.windowEnd,
        slots: [...ov.slots!]..remove(time),
        priceOverride: ov.priceOverride);
    return o.copyWith(dayOverrides: d, addedSlots: added);
  }
  return o.copyWith(removedSlots: {...o.removedSlots, key}, addedSlots: added);
}

AvailabilityOverrides addTime(AvailabilityOverrides o, String date, String time) {
  final key = '${date}T$time';
  final removed = {...o.removedSlots}..remove(key);
  final ov = o.dayOverrides[date];
  if (ov?.slots != null) {
    final d = {...o.dayOverrides};
    d[date] = DayOverride(
        windowStart: ov!.windowStart,
        windowEnd: ov.windowEnd,
        slots: ([...ov.slots!, time]..sort()),
        priceOverride: ov.priceOverride);
    return o.copyWith(dayOverrides: d, removedSlots: removed);
  }
  return o.copyWith(addedSlots: {...o.addedSlots, key}, removedSlots: removed);
}

AvailabilityOverrides setDay(AvailabilityOverrides o, String date, DayOverride? ov) {
  final d = {...o.dayOverrides};
  if (ov == null || ov.isEmpty) {
    d.remove(date);
  } else {
    d[date] = ov;
  }
  return o.copyWith(dayOverrides: d);
}

/// "Reset to default": the day follows the general rules again.
AvailabilityOverrides resetDay(AvailabilityOverrides o, String date) => o.copyWith(
      dayOverrides: {...o.dayOverrides}..remove(date),
      removedSlots: o.removedSlots.where((k) => !k.startsWith(date)).toSet(),
      addedSlots: o.addedSlots.where((k) => !k.startsWith(date)).toSet(),
    );

/// "Copy this day to…": the targets get the source's exact times (and its
/// special price) as an explicit list.
AvailabilityOverrides copyDay(AvailabilityRules r, AvailabilityOverrides o, String from, Iterable<String> to) {
  final times = effectiveDayTimes(r, o, from);
  final price = o.dayOverrides[from]?.priceOverride;
  var out = o;
  for (final d in to) {
    if (d == from) continue;
    out = resetDay(out, d);
    out = setDay(out, d, times.isEmpty ? const DayOverride(closed: true) : DayOverride(slots: times, priceOverride: price));
  }
  return out;
}

/// Dates between [from] and [to] (inclusive).
List<String> datesBetween(String from, String to) {
  final out = <String>[];
  var d = parseDateKey(from);
  final end = parseDateKey(to);
  while (!d.isAfter(end) && out.length < 400) {
    out.add(dateKey(d));
    d = d.add(const Duration(days: 1));
  }
  return out;
}

/// Bulk: remove [time] from every [weekday] between [from] and [to].
AvailabilityOverrides removeTimeOnWeekday(
    AvailabilityRules r, AvailabilityOverrides o, int weekday, String time, String from, String to) {
  var out = o;
  for (final d in datesBetween(from, to)) {
    if (weekdayOfKey(d) == weekday && effectiveDayTimes(r, out, d).contains(time)) {
      out = removeTime(out, d, time);
    }
  }
  return out;
}

/// Bulk: close every day between [from] and [to] (vacation).
AvailabilityOverrides closeRange(AvailabilityOverrides o, String from, String to) {
  var out = o;
  for (final d in datesBetween(from, to)) {
    final prev = out.dayOverrides[d];
    out = setDay(out, d, DayOverride(closed: true, priceOverride: prev?.priceOverride));
  }
  return out;
}

/// Weekend price applies on [date] (weekend days of the listing).
bool isWeekendDay(String date, List<int> weekendDays) => weekendDays.contains(weekdayOfKey(date));

/// Common IANA zones for the picker; the default follows the device offset.
const Map<String, double> kCommonTimeZones = {
  'America/Los_Angeles': -8, 'America/Denver': -7, 'America/Chicago': -6, 'America/New_York': -5,
  'America/Bogota': -5, 'America/Lima': -5, 'America/Mexico_City': -6, 'America/Santiago': -4,
  'America/Argentina/Buenos_Aires': -3, 'America/Sao_Paulo': -3, 'America/Montevideo': -3,
  'Atlantic/Azores': -1, 'Europe/London': 0, 'Europe/Lisbon': 0, 'Europe/Madrid': 1, 'Europe/Paris': 1,
  'Europe/Berlin': 1, 'Europe/Rome': 1, 'Africa/Johannesburg': 2, 'Europe/Athens': 2, 'Europe/Istanbul': 3,
  'Asia/Dubai': 4, 'Asia/Kolkata': 5.5, 'Asia/Bangkok': 7, 'Asia/Singapore': 8, 'Asia/Tokyo': 9,
  'Australia/Sydney': 10, 'Pacific/Auckland': 12, 'UTC': 0,
};

/// A sensible default zone for this device (standard offset match).
String defaultTimeZone(Duration offset) {
  final h = offset.inMinutes / 60;
  for (final e in kCommonTimeZones.entries) {
    if (e.value == h) return e.key;
  }
  for (final e in kCommonTimeZones.entries) {
    if ((e.value - h).abs() <= 1) return e.key;
  }
  return 'UTC';
}
