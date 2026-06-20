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
  languageExchange,
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

/// Event visibility: public events are discoverable by anyone; private events
/// are only visible to invitees/attendees and people with the link.
enum EventVisibility {
  public,
  private,
}

extension EventVisibilityExtension on EventVisibility {
  String get value => name;
  static EventVisibility fromString(String? v) => EventVisibility.values
      .firstWhere((e) => e.name == v, orElse: () => EventVisibility.public);
}

/// An external link associated with an event (tickets, website, map, etc.).
class ExternalLink extends Equatable {
  const ExternalLink({required this.url, this.label});
  final String url;
  final String? label;

  Map<String, dynamic> toMap() => {'url': url, 'label': label};
  factory ExternalLink.fromMap(Map<String, dynamic> m) =>
      ExternalLink(url: m['url'] as String? ?? '', label: m['label'] as String?);

  @override
  List<Object?> get props => [url, label];
}

/// Event Entity
/// Local events and activities for users to meet
class Event extends Equatable {

  const Event({
    required this.id,
    required this.organizerId,
    required this.organizerName,
    required this.title, required this.description, required this.category, required this.startDate, required this.endDate, required this.locationName, required this.maxAttendees, required this.status, required this.createdAt, this.organizerPhotoUrl,
    this.imageUrl,
    this.photoUrls = const [],
    this.latitude,
    this.longitude,
    this.address,
    this.price,
    this.currency,
    this.attendees = const [],
    this.tags = const [],
    this.isVerified = false,
    this.requiresApproval = false,
    this.minAge,
    this.maxAge,
    this.genderPreference,
    this.languages = const [],
    this.languagePairs,
    this.city,
    this.country,
    this.attendeeCount = 0,
    this.updatedAt,
    this.visibility = EventVisibility.public,
    this.externalLinks = const [],
  });
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
  final List<String> languages;
  final String? languagePairs;
  final String? city;
  final String? country;
  final int attendeeCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final EventVisibility visibility;
  final List<ExternalLink> externalLinks;

  int get goingCount => attendees.where((a) => a.status == RSVPStatus.going).length;
  int get interestedCount => attendees.where((a) => a.status == RSVPStatus.interested).length;
  /// `maxAttendees <= 0` means unlimited capacity.
  bool get isUnlimited => maxAttendees <= 0;
  int get spotsLeft => maxAttendees - goingCount;
  bool get isFull => !isUnlimited && spotsLeft <= 0;
  bool get isPublic => visibility == EventVisibility.public;
  bool get isPrivate => visibility == EventVisibility.private;
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
        languages,
        languagePairs,
        city,
        country,
        attendeeCount,
        createdAt,
        updatedAt,
        visibility,
        externalLinks,
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
    List<String>? languages,
    String? languagePairs,
    String? city,
    String? country,
    int? attendeeCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    EventVisibility? visibility,
    List<ExternalLink>? externalLinks,
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
      languages: languages ?? this.languages,
      languagePairs: languagePairs ?? this.languagePairs,
      city: city ?? this.city,
      country: country ?? this.country,
      attendeeCount: attendeeCount ?? this.attendeeCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      visibility: visibility ?? this.visibility,
      externalLinks: externalLinks ?? this.externalLinks,
    );
  }
}

/// Event Attendee
class EventAttendee extends Equatable {

  const EventAttendee({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userName,
    required this.status, required this.rsvpDate, this.userPhotoUrl,
    this.isApproved = false,
    this.isInvisible = false,
    this.isAnonymous = false,
    this.muteNotifications = false,
    this.visibleToOrganizerOnly = false,
  });
  final String id;
  final String eventId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final RSVPStatus status;
  final DateTime rsvpDate;
  final bool isApproved;

  // ---- Attendee privacy controls (more control for the user) ----
  /// Hidden from everyone's attendee roster (still counted by the organizer).
  final bool isInvisible;
  /// Shown without name/photo ("Someone") when visible to others.
  final bool isAnonymous;
  /// Opt out of event broadcasts / notifications.
  final bool muteNotifications;
  /// Invisible to other attendees, but the organizer can still see this RSVP.
  final bool visibleToOrganizerOnly;

  /// Whether this RSVP should be shown to [viewerId] given the [organizerId].
  bool isVisibleTo(String viewerId, String organizerId) {
    if (viewerId == userId) return true; // always see yourself
    if (viewerId == organizerId) return true; // organizer sees everyone
    if (isInvisible || visibleToOrganizerOnly) return false;
    return true;
  }

  /// Display name honoring anonymity (use for non-self, non-organizer viewers).
  String displayNameFor(String viewerId, String organizerId) {
    if (viewerId == userId || viewerId == organizerId) return userName;
    return isAnonymous ? 'Someone' : userName;
  }

  EventAttendee copyWith({
    RSVPStatus? status,
    bool? isApproved,
    bool? isInvisible,
    bool? isAnonymous,
    bool? muteNotifications,
    bool? visibleToOrganizerOnly,
  }) {
    return EventAttendee(
      id: id,
      eventId: eventId,
      userId: userId,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      status: status ?? this.status,
      rsvpDate: rsvpDate,
      isApproved: isApproved ?? this.isApproved,
      isInvisible: isInvisible ?? this.isInvisible,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      muteNotifications: muteNotifications ?? this.muteNotifications,
      visibleToOrganizerOnly:
          visibleToOrganizerOnly ?? this.visibleToOrganizerOnly,
    );
  }

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
        isInvisible,
        isAnonymous,
        muteNotifications,
        visibleToOrganizerOnly,
      ];
}
