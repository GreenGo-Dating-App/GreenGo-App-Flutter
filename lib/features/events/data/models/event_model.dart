import 'package:cloud_firestore/cloud_firestore.dart';
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
    super.organizerPhotoUrl,
    required super.title,
    required super.description,
    required super.category,
    super.imageUrl,
    super.photoUrls = const [],
    required super.startDate,
    required super.endDate,
    required super.locationName,
    super.latitude,
    super.longitude,
    super.address,
    required super.maxAttendees,
    super.price,
    super.currency,
    required super.status,
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
    super.attendeeCount = 0,
    required super.createdAt,
    super.updatedAt,
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
      attendeeCount: event.attendeeCount,
      createdAt: event.createdAt,
      updatedAt: event.updatedAt,
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
      attendeeCount: (json['attendeeCount'] as num?)?.toInt() ?? 0,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? _parseDateTime(json['updatedAt'])
          : null,
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
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
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
      'attendeeCount': attendeeCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
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
        .map((json) => EventAttendeeModel.fromJson(json))
        .toList();
  }
}
