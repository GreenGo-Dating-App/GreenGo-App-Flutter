import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/event.dart';

/// Generates the occurrence documents for a recurring event series.
///
/// Each occurrence is a NORMAL `events` doc (so lists, QR check-in and attendees
/// keep working unchanged); they only share a common [Event.seriesId]. Generation
/// is capped at [kMaxSeriesOccurrences] to keep fan-out cheap and free to run.
class EventSeriesService {
  EventSeriesService._();
  static final EventSeriesService instance = EventSeriesService._();

  /// Build the occurrences for [base] according to [recurrence]. When the
  /// recurrence does not repeat, returns just `[base]`. Otherwise returns up to
  /// [kMaxSeriesOccurrences] events (the first is [base]'s own date), all sharing
  /// a freshly-minted seriesId.
  List<Event> buildOccurrences(Event base, EventRecurrence recurrence) {
    if (!recurrence.isRecurring) return [base];
    final seriesId =
        FirebaseFirestore.instance.collection('events').doc().id;
    final count = recurrence.safeCount;
    final interval = recurrence.safeInterval;
    final duration = base.endDate.difference(base.startDate);

    final out = <Event>[];
    for (var i = 0; i < count; i++) {
      final start =
          _advance(base.startDate, recurrence.frequency, interval * i);
      out.add(
        base.copyWith(
          startDate: start,
          endDate: start.add(duration),
          seriesId: seriesId,
          recurrence: recurrence,
        ),
      );
    }
    return out;
  }

  DateTime _advance(DateTime from, RecurrenceFrequency f, int units) {
    switch (f) {
      case RecurrenceFrequency.daily:
        return from.add(Duration(days: units));
      case RecurrenceFrequency.weekly:
        return from.add(Duration(days: 7 * units));
      case RecurrenceFrequency.monthly:
        // Keep the same day-of-month/time; month overflow rolls into the year.
        return DateTime(
          from.year,
          from.month + units,
          from.day,
          from.hour,
          from.minute,
        );
      case RecurrenceFrequency.none:
        return from;
    }
  }
}
