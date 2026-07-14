import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/geo_query.dart';
import '../../domain/entities/event.dart';
import 'event_attendee_model.dart';

/// Event Model
///
/// Data layer model for Event entity with Firestore serialization.
/// Handles all 30+ fields with null-safe parsing.
class EventModel extends Event {
  const EventModel({
    required super.id,
    required super.organizerId,
    required super.organizerName,
    required super.title, required super.description, required super.category, required super.startDate, required super.endDate, required super.locationName, required super.maxAttendees, required super.status, required super.createdAt, super.organizerPhotoUrl,
    super.imageUrl,
    super.photoUrls = const [],
    super.allowedScannerIds = const [],
    super.latitude,
    super.longitude,
    super.address,
    super.price,
    super.currency,
    super.attendees = const [],
    super.tags = const [],
    super.isVerified = false,
    super.requiresApproval = false,
    super.minAge,
    super.maxAge,
    super.genderPreference,
    super.languages = const [],
    super.languagePairs,
    super.city,
    super.country,
    super.attendeeCount = 0,
    super.likeCount = 0,
    super.viewCount = 0,
    super.updatedAt,
    super.visibility = EventVisibility.public,
    super.externalLinks = const [],
    super.isFeatured = false,
    super.featuredUntil,
    super.guestsAllowedPerAttendee = 0,
    super.seriesId,
    super.recurrence,
    super.publishAt,
    super.ticketTiers = const [],
  });

  /// Create from Event entity
  factory EventModel.fromEntity(Event event) {
    return EventModel(
      id: event.id,
      organizerId: event.organizerId,
      organizerName: event.organizerName,
      organizerPhotoUrl: event.organizerPhotoUrl,
      title: event.title,
      description: event.description,
      category: event.category,
      imageUrl: event.imageUrl,
      photoUrls: event.photoUrls,
      allowedScannerIds: event.allowedScannerIds,
      startDate: event.startDate,
      endDate: event.endDate,
      locationName: event.locationName,
      latitude: event.latitude,
      longitude: event.longitude,
      address: event.address,
      maxAttendees: event.maxAttendees,
      price: event.price,
      currency: event.currency,
      status: event.status,
      attendees: event.attendees,
      tags: event.tags,
      isVerified: event.isVerified,
      requiresApproval: event.requiresApproval,
      minAge: event.minAge,
      maxAge: event.maxAge,
      genderPreference: event.genderPreference,
      languages: event.languages,
      languagePairs: event.languagePairs,
      city: event.city,
      country: event.country,
      attendeeCount: event.attendeeCount,
      likeCount: event.likeCount,
      viewCount: event.viewCount,
      createdAt: event.createdAt,
      updatedAt: event.updatedAt,
      visibility: event.visibility,
      externalLinks: event.externalLinks,
      isFeatured: event.isFeatured,
      featuredUntil: event.featuredUntil,
      guestsAllowedPerAttendee: event.guestsAllowedPerAttendee,
      seriesId: event.seriesId,
      recurrence: event.recurrence,
      publishAt: event.publishAt,
      ticketTiers: event.ticketTiers,
    );
  }

  /// Create from Firestore document
  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return EventModel.fromJson({...data, 'id': doc.id});
  }

  /// Create from JSON map
  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as String? ?? '',
      organizerId: json['organizerId'] as String? ?? '',
      organizerName: json['organizerName'] as String? ?? '',
      organizerPhotoUrl: json['organizerPhotoUrl'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: _parseCategoryFromString(json['category'] as String?),
      imageUrl: json['imageUrl'] as String?,
      photoUrls: List<String>.from(json['photoUrls'] as List? ?? []),
      allowedScannerIds:
          List<String>.from(json['allowedScannerIds'] as List? ?? []),
      startDate: _parseDateTime(json['startDate']),
      endDate: _parseDateTime(json['endDate']),
      locationName: json['locationName'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      address: json['address'] as String?,
      maxAttendees: (json['maxAttendees'] as num?)?.toInt() ?? 20,
      price: (json['price'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      status: _parseStatusFromString(json['status'] as String?),
      attendees: _parseAttendees(json['attendees']),
      tags: List<String>.from(json['tags'] as List? ?? []),
      isVerified: json['isVerified'] as bool? ?? false,
      requiresApproval: json['requiresApproval'] as bool? ?? false,
      minAge: (json['minAge'] as num?)?.toInt(),
      maxAge: (json['maxAge'] as num?)?.toInt(),
      genderPreference: json['genderPreference'] as String?,
      languages: List<String>.from(json['languages'] as List? ?? []),
      languagePairs: json['languagePairs'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      attendeeCount: (json['attendeeCount'] as num?)?.toInt() ?? 0,
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? _parseDateTime(json['updatedAt'])
          : null,
      visibility:
          EventVisibilityExtension.fromString(json['visibility'] as String?),
      externalLinks: (json['externalLinks'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(ExternalLink.fromMap)
              .toList() ??
          const [],
      isFeatured: json['isFeatured'] as bool? ?? false,
      featuredUntil:
          json['featuredUntil'] != null ? _parseDateTime(json['featuredUntil']) : null,
      guestsAllowedPerAttendee:
          (json['guestsAllowedPerAttendee'] as num?)?.toInt() ?? 0,
      seriesId: json['seriesId'] as String?,
      recurrence: json['recurrence'] is Map
          ? EventRecurrence.fromMap(
              Map<String, dynamic>.from(json['recurrence'] as Map))
          : null,
      publishAt:
          json['publishAt'] != null ? _parseDateTime(json['publishAt']) : null,
      ticketTiers: (json['ticketTiers'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(TicketTier.fromMap)
              .toList() ??
          const [],
    );
  }

  /// Convert to JSON map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'organizerId': organizerId,
      'organizerName': organizerName,
      'organizerPhotoUrl': organizerPhotoUrl,
      'title': title,
      'description': description,
      'category': category.name,
      'imageUrl': imageUrl,
      'photoUrls': photoUrls,
      'allowedScannerIds': allowedScannerIds,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      // Geohash for nearest-first community queries (matches external_events).
      if (latitude != null && longitude != null)
        'geohash': GeoQuery.encode(latitude!, longitude!),
      'address': address,
      'maxAttendees': maxAttendees,
      'price': price,
      'currency': currency,
      'status': status.name,
      'tags': tags,
      'isVerified': isVerified,
      'requiresApproval': requiresApproval,
      'minAge': minAge,
      'maxAge': maxAge,
      'genderPreference': genderPreference,
      'languages': languages,
      'languagePairs': languagePairs,
      'city': city,
      'country': country,
      'attendeeCount': attendeeCount,
      'likeCount': likeCount,
      // NOTE: `viewCount` is intentionally NOT written here. It is a monotonic
      // counter maintained via FieldValue.increment(1) on event open, so an
      // event create/edit must never overwrite the server-side value. It is
      // read back in fromJson only.
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'visibility': visibility.value,
      'externalLinks': externalLinks.map((e) => e.toMap()).toList(),
      'isFeatured': isFeatured,
      'featuredUntil':
          featuredUntil != null ? Timestamp.fromDate(featuredUntil!) : null,
      'guestsAllowedPerAttendee': guestsAllowedPerAttendee,
      // Recurring series (each occurrence shares seriesId; each is a normal doc).
      'seriesId': seriesId,
      'recurrence': recurrence?.toMap(),
      // Draft & scheduled auto-publish (feeds gate on isLive using publishAt).
      'publishAt': publishAt != null ? Timestamp.fromDate(publishAt!) : null,
      // Ticket tiers (per-tier price + capacity; empty = single implicit tier).
      'ticketTiers': ticketTiers.map((t) => t.toMap()).toList(),
      // Lowercased tokens for name/text search (array-contains, no composite index).
      'searchKeywords': buildSearchKeywords(),
    };
  }

  /// Tokenize title/city/category/tags into lowercased keywords for search.
  List<String> buildSearchKeywords() {
    final tokens = <String>{};
    void add(String? s) {
      if (s == null) return;
      for (final w in s.toLowerCase().split(RegExp(r'[^a-z0-9]+'))) {
        if (w.length >= 2) tokens.add(w);
      }
    }

    add(title);
    add(city);
    add(country);
    add(locationName);
    tokens.add(category.name.toLowerCase());
    for (final t in tags) {
      add(t);
    }
    return tokens.toList();
  }

  /// Parse DateTime from Firestore Timestamp or other formats
  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is DateTime) {
      return value;
    } else if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  /// Parse EventCategory from string
  static EventCategory _parseCategoryFromString(String? value) {
    if (value == null) return EventCategory.other;
    try {
      return EventCategory.values.firstWhere(
        (e) => e.name == value,
        orElse: () => EventCategory.other,
      );
    } catch (_) {
      return EventCategory.other;
    }
  }

  /// Parse EventStatus from string
  static EventStatus _parseStatusFromString(String? value) {
    if (value == null) return EventStatus.draft;
    try {
      return EventStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => EventStatus.draft,
      );
    } catch (_) {
      return EventStatus.draft;
    }
  }

  /// Parse attendees list from JSON
  static List<EventAttendee> _parseAttendees(dynamic value) {
    if (value == null) return [];
    if (value is! List) return [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(EventAttendeeModel.fromJson)
        .toList();
  }
}
