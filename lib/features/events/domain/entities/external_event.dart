import 'package:cloud_firestore/cloud_firestore.dart';

/// A read-only experience sourced from a third-party provider (Tiqets museums &
/// attractions, Viator tours & experiences). Cached in `external_events` by a
/// scheduled Cloud Function; the app only reads it and deep-links out to the
/// provider to book (ToS: we never resell as a native event).
class ExternalEvent {
  const ExternalEvent({
    required this.id,
    required this.source,
    required this.title,
    required this.bookingUrl,
    this.description,
    this.imageUrl,
    this.category,
    this.city,
    this.country,
    this.fromPrice,
    this.currency,
    this.rating,
    this.reviewCount,
    this.durationMinutes,
    this.lat,
    this.lng,
  });

  final String id;
  final String source; // 'tiqets' | 'viator'
  final String title;
  final String bookingUrl;
  final String? description;
  final String? imageUrl;
  final String? category;
  final String? city;
  final String? country;
  final double? fromPrice;
  final String? currency;
  final double? rating;
  final int? reviewCount;
  final int? durationMinutes;
  final double? lat;
  final double? lng;

  String get sourceLabel => source == 'tiqets' ? 'Tiqets' : 'Viator';

  factory ExternalEvent.fromFirestore(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    final geoPrice = d['fromPrice'];
    final rating = d['rating'];
    return ExternalEvent(
      id: doc.id,
      source: d['source'] as String? ?? 'viator',
      title: d['title'] as String? ?? '',
      bookingUrl: d['bookingUrl'] as String? ?? '',
      description: d['description'] as String?,
      imageUrl: d['imageUrl'] as String?,
      category: d['category'] as String?,
      city: d['city'] as String?,
      country: d['country'] as String?,
      fromPrice: geoPrice is num ? geoPrice.toDouble() : null,
      currency: d['currency'] as String?,
      rating: rating is num ? rating.toDouble() : null,
      reviewCount: (d['reviewCount'] as num?)?.toInt(),
      durationMinutes: (d['durationMinutes'] as num?)?.toInt(),
      lat: (d['lat'] as num?)?.toDouble(),
      lng: (d['lng'] as num?)?.toDouble(),
    );
  }

  /// Real, public experiences shown as a preview until the ingester has pulled
  /// live data (or as a graceful fallback if the collection is empty).
  static const List<ExternalEvent> samples = [
    ExternalEvent(
      id: 'tiqets_sample_colosseum',
      source: 'tiqets',
      title: 'Skip-the-Line: Colosseum, Roman Forum & Palatine Hill',
      category: 'museum',
      city: 'Rome',
      country: 'IT',
      imageUrl:
          'https://images.unsplash.com/photo-1552832230-c0197dd311b5?w=800&q=80',
      fromPrice: 18.0,
      currency: 'EUR',
      rating: 4.7,
      reviewCount: 5312,
      bookingUrl: 'https://www.tiqets.com/en/rome-attractions-c66903/',
    ),
    ExternalEvent(
      id: 'tiqets_sample_louvre',
      source: 'tiqets',
      title: 'Louvre Museum — Timed-Entrance Ticket',
      category: 'museum',
      city: 'Paris',
      country: 'FR',
      imageUrl:
          'https://images.unsplash.com/photo-1565099824688-e93eb20fe622?w=800&q=80',
      fromPrice: 22.0,
      currency: 'EUR',
      rating: 4.6,
      reviewCount: 8740,
      bookingUrl: 'https://www.tiqets.com/en/paris-attractions-c66746/',
    ),
    ExternalEvent(
      id: 'viator_sample_opera',
      source: 'viator',
      title: 'Sydney Opera House Official Guided Walking Tour',
      category: 'tour',
      city: 'Sydney',
      country: 'AU',
      imageUrl:
          'https://images.unsplash.com/photo-1506973035872-a4ec16b8e8d9?w=800&q=80',
      fromPrice: 42.5,
      currency: 'AUD',
      rating: 4.6,
      reviewCount: 1847,
      durationMinutes: 60,
      bookingUrl: 'https://www.viator.com/Sydney-tours/d357',
    ),
    ExternalEvent(
      id: 'viator_sample_tokyo',
      source: 'viator',
      title: 'Tokyo by Night: Food & Culture Walking Tour',
      category: 'experience',
      city: 'Tokyo',
      country: 'JP',
      imageUrl:
          'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=800&q=80',
      fromPrice: 89.0,
      currency: 'USD',
      rating: 4.9,
      reviewCount: 2103,
      durationMinutes: 180,
      bookingUrl: 'https://www.viator.com/Tokyo-tours/d334',
    ),
    ExternalEvent(
      id: 'tiqets_sample_sagrada',
      source: 'tiqets',
      title: 'Sagrada Família — Fast-Track Entry',
      category: 'attraction',
      city: 'Barcelona',
      country: 'ES',
      imageUrl:
          'https://images.unsplash.com/photo-1583779457094-ab6f9164a1c8?w=800&q=80',
      fromPrice: 26.0,
      currency: 'EUR',
      rating: 4.8,
      reviewCount: 12450,
      bookingUrl: 'https://www.tiqets.com/en/barcelona-attractions-c71993/',
    ),
    ExternalEvent(
      id: 'viator_sample_nyc',
      source: 'viator',
      title: 'New York City: Skip-the-Line Empire State Building',
      category: 'attraction',
      city: 'New York',
      country: 'US',
      imageUrl:
          'https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9?w=800&q=80',
      fromPrice: 48.0,
      currency: 'USD',
      rating: 4.5,
      reviewCount: 9981,
      bookingUrl: 'https://www.viator.com/New-York-City-tours/d687',
    ),
  ];
}
