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

/// Who may see the list of people attending.
///
/// Separate from [EventVisibility], which is about finding the EVENT. An event
/// can be public while its guest list is not: "come along" and "here is
/// everyone who is coming" are different invitations.
enum AttendeeListVisibility {
  /// Nobody but the organiser. Attendees cannot see each other.
  private,

  /// The people attending, plus the organiser. The default.
  participants,

  /// Anyone who can see the event.
  public,
}

extension AttendeeListVisibilityExtension on AttendeeListVisibility {
  String get value => name;

  static AttendeeListVisibility fromString(String? v) =>
      AttendeeListVisibility.values.firstWhere(
        (e) => e.name == v,
        // Unknown or absent - including every event created before this
        // existed - falls back to the middle setting rather than the most open
        // one.
        orElse: () => AttendeeListVisibility.participants,
      );
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

/// Maximum number of co-owners (besides the creator) an event may have.
/// Mirrored by the `events` Firestore rule (`coOrganizerIds.size() <= 5`).
const int kMaxEventCoOrganizers = 5;

/// Event-doc fields only the creator may change. A co-owner's edit never
/// writes them (stripped client-side) and the `events` rule rejects any
/// co-owner update touching them.
const List<String> kEventCreatorOnlyFields = [
  'organizerId',
  'organizerName',
  'organizerPhotoUrl',
  'coOrganizerIds',
];

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
    this.allowedScannerIds = const [],
    this.coOrganizerIds = const [],
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
    this.attendeeListVisibility = AttendeeListVisibility.participants,
    this.externalLinks = const [],
    this.isFeatured = false,
    this.featuredUntil,
    this.guestsAllowedPerAttendee = 0,
    this.seriesId,
    this.recurrence,
    this.publishAt,
    this.ticketTiers = const [],
    this.communityId,
    this.ticketProvider,
    this.ticketLinkMethod,
    this.ticketPaymentInstructions,
    this.currencyCode,
    this.maxTicketsPerUser = 4,
  });
  final String id;
  final String organizerId;
  final String organizerName;

  /// When non-null, this event belongs to a community (shows in that
  /// community's Events tab). Null = a personal/business event as before.
  final String? communityId;
  final String? organizerPhotoUrl;
  final String title;
  final String description;
  final EventCategory category;
  final String? imageUrl;
  final List<String> photoUrls;

  /// Users (besides the organizer) who are allowed to scan/redeem this event's
  /// QR tickets at the door. Owner is always allowed implicitly.
  final List<String> allowedScannerIds;

  /// Co-owners added by the creator ([organizerId]), max
  /// [kMaxEventCoOrganizers]. A co-owner may do everything the creator can
  /// (edit, attendance list, QR check-in, see the full guest list) EXCEPT
  /// delete the event, change this list, or spend coins boosting it.
  final List<String> coOrganizerIds;
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

  /// Who may see the attendee roster. See [canViewAttendeeList].
  final AttendeeListVisibility attendeeListVisibility;
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

  // ---- Paid tickets (functions/src/ticket_payments) ----
  /// How a paid event is sold: 'link' (organizer's own payment method,
  /// organizer confirms), 'stripe' / 'mercadopago' (instant, connected
  /// account). Null on free events and on legacy coin-priced events.
  final String? ticketProvider;

  /// Link mode: Profile > Payment methods key ('pix', 'paypal', ...) or
  /// 'cash' / 'bankTransfer'.
  final String? ticketLinkMethod;

  /// Link mode: extra payment instructions (required for bank transfer).
  final String? ticketPaymentInstructions;

  /// ISO 4217 code of [price] (lower case), e.g. 'brl'. [currency] keeps the
  /// display symbol for older clients.
  final String? currencyCode;

  /// Max paid tickets one person may buy (null = no limit; default 4).
  final int? maxTicketsPerUser;

  /// Paid event that can actually be bought (a ticket provider is set).
  bool get sellsTickets => !isFree && ticketProvider != null;

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

  /// The creator of the event. Only the creator may delete it, manage
  /// [coOrganizerIds] or boost it.
  bool isCreator(String uid) => uid.isNotEmpty && uid == organizerId;

  /// Whether [uid] owns this event: the creator or one of its co-owners.
  bool isOwner(String uid) =>
      uid.isNotEmpty && (uid == organizerId || coOrganizerIds.contains(uid));

  /// The id to pass as the "organizer" to [EventAttendee.isVisibleTo] /
  /// [EventAttendee.displayNameFor] for [viewerId]: an owner (creator or
  /// co-owner) sees the roster exactly as the creator does.
  String organizerViewIdFor(String viewerId) =>
      isOwner(viewerId) ? viewerId : organizerId;
  /// Whether [viewerId] may see who is attending.
  ///
  /// The organiser (and every co-owner) always can - they need the list to run
  /// the event, and they chose the setting. Everyone else is judged by that setting; a participant
  /// is anyone with an RSVP, including the waitlist, since they have committed
  /// to the event either way.
  bool canViewAttendeeList(String viewerId) {
    if (isOwner(viewerId)) return true;
    switch (attendeeListVisibility) {
      case AttendeeListVisibility.public:
        return true;
      case AttendeeListVisibility.participants:
        return attendees.any((a) => a.userId == viewerId);
      case AttendeeListVisibility.private:
        return false;
    }
  }

  bool get isPublic => visibility == EventVisibility.public;
  bool get isPrivate => visibility == EventVisibility.private;
  bool get isFree => price == null || price == 0;
  bool get isUpcoming => startDate.isAfter(DateTime.now());
  bool get isOngoing => DateTime.now().isAfter(startDate) && DateTime.now().isBefore(endDate);

  /// The event has finished. Everything that would CHANGE or PROMOTE it is
  /// withdrawn past this point - editing, boosting, joining, check-in - while
  /// deleting, reporting and reading the attendance list remain.
  bool get hasEnded => DateTime.now().isAfter(endDate);

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
        allowedScannerIds,
        coOrganizerIds,
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
        attendeeListVisibility,
        externalLinks,
        isFeatured,
        featuredUntil,
        guestsAllowedPerAttendee,
        seriesId,
        recurrence,
        publishAt,
        ticketTiers,
        communityId,
        ticketProvider,
        ticketLinkMethod,
        ticketPaymentInstructions,
        currencyCode,
        maxTicketsPerUser,
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
    List<String>? allowedScannerIds,
    List<String>? coOrganizerIds,
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
    AttendeeListVisibility? attendeeListVisibility,
    List<ExternalLink>? externalLinks,
    bool? isFeatured,
    DateTime? featuredUntil,
    int? guestsAllowedPerAttendee,
    String? seriesId,
    EventRecurrence? recurrence,
    DateTime? publishAt,
    List<TicketTier>? ticketTiers,
    String? communityId,
    String? ticketProvider,
    String? ticketLinkMethod,
    String? ticketPaymentInstructions,
    String? currencyCode,
    int? maxTicketsPerUser,
    bool clearMaxTicketsPerUser = false,
    bool clearTicketing = false,
    bool clearCommunityId = false,
    // Drops latitude/longitude/city/country (a manually typed location that
    // could not be geocoded). Explicit values passed alongside are ignored.
    bool clearCoordinates = false,
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
      allowedScannerIds: allowedScannerIds ?? this.allowedScannerIds,
      coOrganizerIds: coOrganizerIds ?? this.coOrganizerIds,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      locationName: locationName ?? this.locationName,
      latitude: clearCoordinates ? null : (latitude ?? this.latitude),
      longitude: clearCoordinates ? null : (longitude ?? this.longitude),
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
      city: clearCoordinates ? null : (city ?? this.city),
      country: clearCoordinates ? null : (country ?? this.country),
      attendeeCount: attendeeCount ?? this.attendeeCount,
      likeCount: likeCount ?? this.likeCount,
      viewCount: viewCount ?? this.viewCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      visibility: visibility ?? this.visibility,
      attendeeListVisibility:
          attendeeListVisibility ?? this.attendeeListVisibility,
      externalLinks: externalLinks ?? this.externalLinks,
      isFeatured: isFeatured ?? this.isFeatured,
      featuredUntil: featuredUntil ?? this.featuredUntil,
      guestsAllowedPerAttendee:
          guestsAllowedPerAttendee ?? this.guestsAllowedPerAttendee,
      seriesId: seriesId ?? this.seriesId,
      recurrence: recurrence ?? this.recurrence,
      publishAt: publishAt ?? this.publishAt,
      ticketTiers: ticketTiers ?? this.ticketTiers,
      communityId:
          clearCommunityId ? null : (communityId ?? this.communityId),
      ticketProvider:
          clearTicketing ? null : (ticketProvider ?? this.ticketProvider),
      ticketLinkMethod:
          clearTicketing ? null : (ticketLinkMethod ?? this.ticketLinkMethod),
      ticketPaymentInstructions: clearTicketing
          ? null
          : (ticketPaymentInstructions ?? this.ticketPaymentInstructions),
      currencyCode: currencyCode ?? this.currencyCode,
      maxTicketsPerUser: clearMaxTicketsPerUser
          ? null
          : (maxTicketsPerUser ?? this.maxTicketsPerUser),
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
