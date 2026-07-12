import 'package:equatable/equatable.dart';

import 'event_scheduling.dart';

export 'event_scheduling.dart';

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
///
/// [scheduled] events are auto-published client-side: every feed treats them as
/// live only once `publishAt <= now` (no backend flip required). Until then they
/// are visible ONLY to their organizer, exactly like [draft].
enum EventStatus {
  draft,
  scheduled,
  published,
  cancelled,
  completed,
}

/// RSVP Status
///
/// [waitlist] means the attendee joined a full tier/event and is queued; they
/// are auto-promoted to [going] (oldest first) when a going attendee cancels.
enum RSVPStatus {
  going,
  interested,
  notGoing,
  waitlist,
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
    this.likeCount = 0,
    this.viewCount = 0,
    this.updatedAt,
    this.visibility = EventVisibility.public,
    this.externalLinks = const [],
    this.isFeatured = false,
    this.featuredUntil,
    this.guestsAllowedPerAttendee = 0,
    this.seriesId,
    this.recurrence,
    this.publishAt,
    this.ticketTiers = const [],
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
  /// Denormalized number of likes (maintained by the onEventLikeWrite CF).
  final int likeCount;

  /// Denormalized number of unique event opens (deduped per-user-per-day at the
  /// call site). Maintained monotonically via `FieldValue.increment(1)` on the
  /// `events/{id}` doc, so it is read-only in the model layer — never written by
  /// `toJson` (an event edit must not clobber the server-incremented counter).
  final int viewCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final EventVisibility visibility;
  final List<ExternalLink> externalLinks;
  // Promotion: featured/boosted events surface first in discovery.
  final bool isFeatured;
  final DateTime? featuredUntil;

  /// Number of guests each attendee may bring (0 = guests not allowed).
  /// Used by the QR check-in flow to compute total headcount.
  final int guestsAllowedPerAttendee;

  // ---- Recurring series ----
  /// Shared across every occurrence of a recurring series (null = standalone).
  /// Each occurrence is still a NORMAL `events` doc so lists/QR/attendees work
  /// unchanged.
  final String? seriesId;

  /// How this event repeats (null / RecurrenceFrequency.none = does not repeat).
  final EventRecurrence? recurrence;

  // ---- Draft & scheduled publishing (auto-publish without a backend) ----
  /// When [status] == scheduled, the event goes live once now >= publishAt.
  final DateTime? publishAt;

  // ---- Ticketing ----
  /// Optional admission tiers. Empty = single implicit tier using [price] /
  /// [maxAttendees]; adding tiers drives per-tier pricing + capacity + waitlist.
  final List<TicketTier> ticketTiers;

  /// Whether attendees are permitted to bring at least one guest.
  bool get guestsAllowed => guestsAllowedPerAttendee > 0;

  /// Whether this event belongs to a recurring series.
  bool get isRecurring =>
      (seriesId != null && seriesId!.isNotEmpty) ||
      (recurrence?.isRecurring ?? false);

  /// Whether the event has organizer-defined ticket tiers.
  bool get hasTicketTiers => ticketTiers.isNotEmpty;

  /// CRITICAL auto-publish gate. An event is "live" (discoverable / joinable) when
  /// it is published, OR scheduled with its publish time reached. Drafts and
  /// not-yet-due scheduled events are NOT live (organizer-only visibility).
  bool get isLive {
    switch (status) {
      case EventStatus.published:
        return true;
      case EventStatus.scheduled:
        return publishAt != null && !publishAt!.isAfter(DateTime.now());
      case EventStatus.draft:
      case EventStatus.cancelled:
      case EventStatus.completed:
        return false;
    }
  }

  /// True for a scheduled event whose publish time is still in the future.
  bool get isPendingSchedule =>
      status == EventStatus.scheduled &&
      publishAt != null &&
      publishAt!.isAfter(DateTime.now());

  /// Whether the event is currently boosted/featured.
  bool get isCurrentlyFeatured =>
      isFeatured &&
      (featuredUntil == null || featuredUntil!.isAfter(DateTime.now()));

  /// Number going. RSVPs live in the `attendees` SUBcollection, so the doc's
  /// denormalized `attendees` array is usually empty on list cards; the
  /// maintained `attendeeCount` counter is the reliable source. Use whichever
  /// is larger so it's correct both on cards (counter) and on the detail screen
  /// (full array loaded).
  int get goingCount {
    final fromList =
        attendees.where((a) => a.status == RSVPStatus.going).length;
    return attendeeCount > fromList ? attendeeCount : fromList;
  }
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
        likeCount,
        viewCount,
        createdAt,
        updatedAt,
        visibility,
        externalLinks,
        isFeatured,
        featuredUntil,
        guestsAllowedPerAttendee,
        seriesId,
        recurrence,
        publishAt,
        ticketTiers,
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
    int? likeCount,
    int? viewCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    EventVisibility? visibility,
    List<ExternalLink>? externalLinks,
    bool? isFeatured,
    DateTime? featuredUntil,
    int? guestsAllowedPerAttendee,
    String? seriesId,
    EventRecurrence? recurrence,
    DateTime? publishAt,
    List<TicketTier>? ticketTiers,
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
      likeCount: likeCount ?? this.likeCount,
      viewCount: viewCount ?? this.viewCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      visibility: visibility ?? this.visibility,
      externalLinks: externalLinks ?? this.externalLinks,
      isFeatured: isFeatured ?? this.isFeatured,
      featuredUntil: featuredUntil ?? this.featuredUntil,
      guestsAllowedPerAttendee:
          guestsAllowedPerAttendee ?? this.guestsAllowedPerAttendee,
      seriesId: seriesId ?? this.seriesId,
      recurrence: recurrence ?? this.recurrence,
      publishAt: publishAt ?? this.publishAt,
      ticketTiers: ticketTiers ?? this.ticketTiers,
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
    this.checkedIn = false,
    this.checkedInAt,
    this.guestCount = 0,
    this.tierId,
  });
  final String id;
  final String eventId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final RSVPStatus status;
  final DateTime rsvpDate;
  final bool isApproved;

  /// Which ticket tier this attendee joined (null = the implicit single tier).
  final String? tierId;

  /// Whether this attendee is queued on the waitlist (tier/event was full).
  bool get isWaitlisted => status == RSVPStatus.waitlist;

  // ---- QR check-in (accountability of who actually attended) ----
  /// Whether the organizer scanned this attendee's ticket at the door.
  final bool checkedIn;
  /// When the attendee was checked in (null until scanned).
  final DateTime? checkedInAt;
  /// How many guests this attendee is bringing (0..event.guestsAllowedPerAttendee).
  final int guestCount;

  /// This attendee's contribution to the headcount (themselves + guests).
  int get headcount => 1 + (guestCount < 0 ? 0 : guestCount);

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
    bool? checkedIn,
    DateTime? checkedInAt,
    int? guestCount,
    String? tierId,
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
      checkedIn: checkedIn ?? this.checkedIn,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      guestCount: guestCount ?? this.guestCount,
      tierId: tierId ?? this.tierId,
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
        checkedIn,
        checkedInAt,
        guestCount,
        tierId,
      ];
}
