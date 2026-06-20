import 'package:equatable/equatable.dart';

/// A lightweight event preview shown on the globe (from the per-country
/// aggregate `event_country_stats/{country}.topEvents`).
class EventPreview extends Equatable {
  const EventPreview({
    required this.id,
    required this.title,
    this.imageUrl,
    this.city,
    this.attendeeCount = 0,
  });

  final String id;
  final String title;
  final String? imageUrl;
  final String? city;
  final int attendeeCount;

  factory EventPreview.fromMap(Map<String, dynamic> m) => EventPreview(
        id: m['id'] as String? ?? '',
        title: m['title'] as String? ?? '',
        imageUrl: m['imageUrl'] as String?,
        city: m['city'] as String?,
        attendeeCount: (m['attendeeCount'] as num?)?.toInt() ?? 0,
      );

  @override
  List<Object?> get props => [id, title, imageUrl, city, attendeeCount];
}

/// Per-country aggregate for the globe: total public events + a top-N preview.
/// Maintained server-side by the `onEventWriteUpdateCountryStats` function.
class EventCountryStat extends Equatable {
  const EventCountryStat({
    required this.country,
    required this.count,
    this.topEvents = const [],
  });

  final String country;
  final int count;
  final List<EventPreview> topEvents;

  @override
  List<Object?> get props => [country, count, topEvents];
}
