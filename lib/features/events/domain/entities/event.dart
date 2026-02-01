import 'package:equatable/equatable.dart';

/// Event Category
enum EventCategory {
  dating,
  social,
  sports,
  food,
  nightlife,
  outdoor,
  arts,
  gaming,
  travel,
  wellness,
  other,
}

/// Event Status
enum EventStatus {
  draft,
  published,
  cancelled,
  completed,
}

/// RSVP Status
enum RSVPStatus {
  going,
  interested,
  notGoing,
}

/// Event Entity
/// Local events and activities for users to meet
class Event extends Equatable {
  final String id;
  final String organizerId;
  final String organizerName;
  final String? organizerPhotoUrl;
  final String title;
  final String description;
  final EventCategory category;
  final String? imageUrl;
  final List<String> photoUrls;
  final DateTime startDate;
  final DateTime endDate;
  final String locationName;
  final double? latitude;
  final double? longitude;
  final String? address;
  final int maxAttendees;
  final double? price;
  final String? currency;
  final EventStatus status;
  final List<EventAttendee> attendees;
  final List<String> tags;
  final bool isVerified;
  final bool requiresApproval;
  final int? minAge;
  final int? maxAge;
  final String? genderPreference;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Event({
    required this.id,
    required this.organizerId,
    required this.organizerName,
    this.organizerPhotoUrl,
    required this.title,
    required this.description,
    required this.category,
    this.imageUrl,
    this.photoUrls = const [],
    required this.startDate,
    required this.endDate,
    required this.locationName,
    this.latitude,
    this.longitude,
    this.address,
    required this.maxAttendees,
    this.price,
    this.currency,
    required this.status,
    this.attendees = const [],
    this.tags = const [],
    this.isVerified = false,
    this.requiresApproval = false,
    this.minAge,
    this.maxAge,
    this.genderPreference,
    required this.createdAt,
    this.updatedAt,
  });

  int get goingCount => attendees.where((a) => a.status == RSVPStatus.going).length;
  int get interestedCount => attendees.where((a) => a.status == RSVPStatus.interested).length;
  int get spotsLeft => maxAttendees - goingCount;
  bool get isFull => spotsLeft <= 0;
  bool get isFree => price == null || price == 0;
  bool get isUpcoming => startDate.isAfter(DateTime.now());
  bool get isOngoing => DateTime.now().isAfter(startDate) && DateTime.now().isBefore(endDate);

  @override
  List<Object?> get props => [
        id,
        organizerId,
        organizerName,
        organizerPhotoUrl,
        title,
        description,
        category,
        imageUrl,
        photoUrls,
        startDate,
        endDate,
        locationName,
        latitude,
        longitude,
        address,
        maxAttendees,
        price,
        currency,
        status,
        attendees,
        tags,
        isVerified,
        requiresApproval,
        minAge,
        maxAge,
        genderPreference,
        createdAt,
        updatedAt,
      ];

  Event copyWith({
    String? id,
    String? organizerId,
    String? organizerName,
    String? organizerPhotoUrl,
    String? title,
    String? description,
    EventCategory? category,
    String? imageUrl,
    List<String>? photoUrls,
    DateTime? startDate,
    DateTime? endDate,
    String? locationName,
    double? latitude,
    double? longitude,
    String? address,
    int? maxAttendees,
    double? price,
    String? currency,
    EventStatus? status,
    List<EventAttendee>? attendees,
    List<String>? tags,
    bool? isVerified,
    bool? requiresApproval,
    int? minAge,
    int? maxAge,
    String? genderPreference,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Event(
      id: id ?? this.id,
      organizerId: organizerId ?? this.organizerId,
      organizerName: organizerName ?? this.organizerName,
      organizerPhotoUrl: organizerPhotoUrl ?? this.organizerPhotoUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      photoUrls: photoUrls ?? this.photoUrls,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      locationName: locationName ?? this.locationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      maxAttendees: maxAttendees ?? this.maxAttendees,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      attendees: attendees ?? this.attendees,
      tags: tags ?? this.tags,
      isVerified: isVerified ?? this.isVerified,
      requiresApproval: requiresApproval ?? this.requiresApproval,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      genderPreference: genderPreference ?? this.genderPreference,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Event Attendee
class EventAttendee extends Equatable {
  final String id;
  final String eventId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final RSVPStatus status;
  final DateTime rsvpDate;
  final bool isApproved;

  const EventAttendee({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.status,
    required this.rsvpDate,
    this.isApproved = false,
  });

  @override
  List<Object?> get props => [
        id,
        eventId,
        userId,
        userName,
        userPhotoUrl,
        status,
        rsvpDate,
        isApproved,
      ];
}
