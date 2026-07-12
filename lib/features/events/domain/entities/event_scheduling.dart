import 'package:equatable/equatable.dart';

/// Recurrence frequency for a repeating event series.
enum RecurrenceFrequency { none, daily, weekly, monthly }

extension RecurrenceFrequencyX on RecurrenceFrequency {
  String get value => name;
  static RecurrenceFrequency fromString(String? v) =>
      RecurrenceFrequency.values.firstWhere(
        (e) => e.name == v,
        orElse: () => RecurrenceFrequency.none,
      );
}

/// Hard cap on how many occurrence docs a single series may generate. Keeps
/// fan-out cheap (a series is at most this many normal `events` docs).
const int kMaxSeriesOccurrences = 12;

/// Describes how an event repeats. Stored on every occurrence doc so the UI can
/// show a "Recurring" chip and the organizer can cancel the whole series.
class EventRecurrence extends Equatable {
  const EventRecurrence({
    this.frequency = RecurrenceFrequency.none,
    this.interval = 1,
    this.count = 1,
  });

  /// none / daily / weekly / monthly
  final RecurrenceFrequency frequency;

  /// Repeat every [interval] units (e.g. every 2 weeks). Always >= 1.
  final int interval;

  /// Total occurrences INCLUDING the first, capped at [kMaxSeriesOccurrences].
  final int count;

  /// A series only exists when it repeats and has more than one occurrence.
  bool get isRecurring =>
      frequency != RecurrenceFrequency.none && count > 1;

  int get safeInterval => interval < 1 ? 1 : interval;
  int get safeCount =>
      count < 1 ? 1 : (count > kMaxSeriesOccurrences ? kMaxSeriesOccurrences : count);

  EventRecurrence copyWith({
    RecurrenceFrequency? frequency,
    int? interval,
    int? count,
  }) =>
      EventRecurrence(
        frequency: frequency ?? this.frequency,
        interval: interval ?? this.interval,
        count: count ?? this.count,
      );

  Map<String, dynamic> toMap() => {
        'frequency': frequency.value,
        'interval': safeInterval,
        'count': safeCount,
      };

  factory EventRecurrence.fromMap(Map<String, dynamic> m) => EventRecurrence(
        frequency: RecurrenceFrequencyX.fromString(m['frequency'] as String?),
        interval: (m['interval'] as num?)?.toInt() ?? 1,
        count: (m['count'] as num?)?.toInt() ?? 1,
      );

  @override
  List<Object?> get props => [frequency, interval, count];
}

/// A ticket tier for an event: a named admission level with an optional coin
/// price (0 = free) and an optional capacity cap (0 = unlimited). Waitlisting
/// kicks in per tier when [capacity] going-attendees is reached.
class TicketTier extends Equatable {
  const TicketTier({
    required this.id,
    required this.name,
    this.priceCoins = 0,
    this.capacity = 0,
  });

  final String id;
  final String name;

  /// In-economy coin price. 0 (or less) means the tier is free.
  final int priceCoins;

  /// Max going attendees for this tier. 0 (or less) means unlimited.
  final int capacity;

  bool get isFree => priceCoins <= 0;
  bool get isUnlimited => capacity <= 0;

  TicketTier copyWith({
    String? id,
    String? name,
    int? priceCoins,
    int? capacity,
  }) =>
      TicketTier(
        id: id ?? this.id,
        name: name ?? this.name,
        priceCoins: priceCoins ?? this.priceCoins,
        capacity: capacity ?? this.capacity,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'priceCoins': priceCoins,
        'capacity': capacity,
      };

  factory TicketTier.fromMap(Map<String, dynamic> m) => TicketTier(
        id: m['id'] as String? ?? '',
        name: m['name'] as String? ?? '',
        priceCoins: (m['priceCoins'] as num?)?.toInt() ?? 0,
        capacity: (m['capacity'] as num?)?.toInt() ?? 0,
      );

  @override
  List<Object?> get props => [id, name, priceCoins, capacity];
}
