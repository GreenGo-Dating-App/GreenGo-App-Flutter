import 'package:equatable/equatable.dart';

/// Category of a member-hosted experience. The wire value is the enum name.
enum ExperienceCategory {
  foodDrink,
  cultureHistory,
  natureOutdoors,
  nightlife,
  sportsAdventure,
  wellness,
  languageLearning,
  toursWalks,
  workshopsClasses,
  other;

  static ExperienceCategory fromWire(Object? v) => ExperienceCategory.values
      .firstWhere((c) => c.name == v, orElse: () => ExperienceCategory.other);
}

/// Lifecycle of an experience. `hidden` is moderation-only (server/admin):
/// the host can switch between draft and published, never into or out of
/// hidden.
enum ExperienceStatus {
  draft,
  published,
  hidden;

  static ExperienceStatus fromWire(Object? v) => ExperienceStatus.values
      .firstWhere((s) => s.name == v, orElse: () => ExperienceStatus.draft);
}

/// How the host gets paid. Payment always happens OUTSIDE GreenGo.
enum PaymentLinkType {
  pix,
  paypal,
  venmo,
  stripe,
  other;

  static PaymentLinkType fromWire(Object? v) => PaymentLinkType.values
      .firstWhere((t) => t.name == v, orElse: () => PaymentLinkType.other);
}

/// Fixed cancellation policies (refund the GUEST gets from the HOST — GreenGo
/// never handles the money):
///  - flexible: 100% until 24 h before; 0% after.
///  - moderate (default): 100% until 7 days before, 50% until 24 h, 0% after.
///  - strict: 100% until 7 days before; 0% after.
/// Universal rules on top (shown to guests): host cancels → 100%; cancelling
/// within 24 h of booking when the experience is > 48 h away → 100%; host
/// no-show / not as described → report within 24 h.
enum CancellationPolicy {
  flexible,
  moderate,
  strict;

  static const CancellationPolicy fallback = CancellationPolicy.moderate;

  /// The enum for a stored value, or null when it is not one (legacy free
  /// text from before the fixed policies).
  static CancellationPolicy? tryWire(Object? v) {
    for (final p in CancellationPolicy.values) {
      if (p.name == v) return p;
    }
    return null;
  }
}

/// How a guest may pay the host (always OUTSIDE GreenGo):
///  - cash: in cash, to the host, at the meeting;
///  - link: online via the host's [PaymentLink] (PIX / PayPal / ...).
/// Paid experiences accept at least one; free ones none.
enum PaymentMethod {
  cash,
  link,

  /// Paid ticket bought INSIDE the app ([UserExperience.paymentProvider]:
  /// Stripe / Mercado Pago instant, or the host's own method with host
  /// confirmation). New paid listings use only this.
  online;

  static PaymentMethod? tryWire(Object? v) {
    for (final m in PaymentMethod.values) {
      if (m.name == v) return m;
    }
    return null;
  }
}

class PaymentLink extends Equatable {
  const PaymentLink({required this.type, required this.value});

  final PaymentLinkType type;

  /// A URL — or, for [PaymentLinkType.pix], a PIX key (email / phone / CPF /
  /// random key), which is copied to the clipboard instead of opened.
  final String value;

  /// True when [value] should be opened in the browser (vs copied).
  bool get isOpenable =>
      value.startsWith('https://') || value.startsWith('http://');

  @override
  List<Object?> get props => [type, value];
}

/// A member-hosted experience (`user_experiences/{id}`).
///
/// Rating fields are SERVER-maintained (Cloud Function trigger over the
/// visible reviews); the client never writes them.
class UserExperience extends Equatable {
  const UserExperience({
    required this.id,
    required this.hostId,
    required this.title,
    required this.description,
    required this.category,
    required this.mainPhotoUrl,
    required this.included,
    required this.locationName,
    required this.durationMinutes,
    required this.languages,
    required this.maxGroupSize,
    this.hostName,
    this.hostPhotoUrl,
    this.photoUrls = const [],
    this.notIncluded = const [],
    this.city,
    this.country,
    this.lat,
    this.lng,
    this.geohash,
    this.meetingPoint,
    this.minGroupSize,
    this.price = 0,
    this.currency,
    this.isFree = false,
    this.paymentLink,
    this.paymentMethods = const {},
    this.paymentProvider,
    this.paymentLinkMethod,
    this.paymentInstructions,
    this.pricingMode = 'per_person',
    this.groupPrice,
    this.maxTicketsPerUser = 4,
    this.hasRecurringAvailability = false,
    this.weekendPrice,
    this.weekendDays = const [6, 7],
    this.availability,
    this.cancellationPolicy = CancellationPolicy.moderate,
    this.cancellationNotes,
    this.requestToBook = true,
    this.allowedScannerIds = const [],
    this.status = ExperienceStatus.draft,
    this.createdAt,
    this.updatedAt,
    this.ratingSum = 0,
    this.ratingCount = 0,
    this.ratingAvg = 0,
    this.ratingDist = const {},
    this.reviewCount = 0,
    this.viewCount = 0,
    this.searchKeywords = const [],
    this.moderationReason,
    this.isFeatured = false,
    this.featuredUntil,
    this.communityId,
    this.communityName,
  });

  final String id;
  final String hostId;

  /// Snapshot at creation; display resolves the live name via
  /// UserDirectoryService and only falls back to this.
  final String? hostName;
  final String? hostPhotoUrl;

  final String title;
  final String description;
  final ExperienceCategory category;
  final String mainPhotoUrl;
  final List<String> photoUrls;
  final List<String> included;
  final List<String> notIncluded;

  final String locationName;
  final String? city;
  final String? country;
  final double? lat;
  final double? lng;
  final String? geohash;
  final String? meetingPoint;

  final int durationMinutes;
  final List<String> languages;
  final int? minGroupSize;
  final int maxGroupSize;

  final double price;
  final String? currency;
  final bool isFree;
  final PaymentLink? paymentLink;

  /// Accepted payment methods (empty for free experiences). Legacy docs
  /// without the field read as {link} when they carry a payment link.
  final Set<PaymentMethod> paymentMethods;

  /// In-app ticket payment: 'stripe' | 'mercadopago' | 'link'.
  final String? paymentProvider;

  /// Link mode: Profile > Payment methods key, 'cash' or 'bankTransfer'.
  final String? paymentLinkMethod;
  final String? paymentInstructions;

  /// 'per_person' (default) | 'per_group' (one [groupPrice] for a party of
  /// up to [maxGroupSize]).
  final String pricingMode;

  /// per_group price in MINOR units (same currency).
  final int? groupPrice;

  /// Max tickets (per_group: group bookings) per person; null = no limit.
  final int? maxTicketsPerUser;

  bool get isPerGroup => pricingMode == 'per_group';

  /// Host schedule set in "Manage times" (availabilityRules): buyers pick a
  /// generated time instead of a dated window.
  final bool hasRecurringAvailability;

  /// Price on [weekendDays] (same unit as the base price of the mode).
  final double? weekendPrice;

  /// 1 = Monday .. 7 = Sunday (default Saturday + Sunday).
  final List<int> weekendDays;

  bool get acceptsOnline =>
      !isFree && paymentMethods.contains(PaymentMethod.online) && paymentProvider != null;

  bool get acceptsCash => !isFree && paymentMethods.contains(PaymentMethod.cash);
  bool get acceptsLink =>
      paymentLink != null &&
      (isFree || paymentMethods.contains(PaymentMethod.link));

  /// Guests can be shown a Book / Pay action.
  bool get isBookable => acceptsCash || acceptsLink;

  /// The listing takes money (paid, or carries a payment link) — needs an
  /// APPROVED host ID to be published (mirrors functions safety.ts).
  bool get takesPayment => !isFree || paymentLink != null;

  final String? availability;
  final CancellationPolicy cancellationPolicy;

  /// Optional host notes on the policy (≤ 300). Legacy docs' free-text policy
  /// is shown here (with the policy defaulting to moderate).
  final String? cancellationNotes;

  /// Bookings: true = the host accepts / declines each request; false =
  /// instant booking (functions/src/experience_bookings snapshots it).
  final bool requestToBook;

  /// Door helpers the host authorised to scan guests' check-in codes
  /// (checkInBooking accepts the host or one of these; max 10).
  final List<String> allowedScannerIds;

  final ExperienceStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ── server-owned ──
  final int ratingSum;
  final int ratingCount;
  final double ratingAvg;

  /// Visible reviews per star: {5: n, 4: n, …}.
  final Map<int, int> ratingDist;
  final int reviewCount;
  final int viewCount;
  final List<String> searchKeywords;

  /// Set by the server when the listing was hidden for violating standards.
  final String? moderationReason;

  /// Server-owned (admin `setExperienceFeatured`; never client-writable):
  /// promoted in Explore "Top experiences" while [featuredUntil] is ahead.
  final bool isFeatured;
  final DateTime? featuredUntil;

  /// Server-owned link to the community it was posted in (set only at
  /// creation by createUserExperience; immutable — never in
  /// editablePayload). [communityName] is the denormalised display name.
  final String? communityId;
  final String? communityName;

  bool get isInCommunity => (communityId ?? '').isNotEmpty;

  /// Featured right now: [isFeatured] and [featuredUntil] not yet passed.
  bool isCurrentlyFeaturedAt(DateTime now) =>
      isFeatured && featuredUntil != null && featuredUntil!.isAfter(now);

  bool get isPublished => status == ExperienceStatus.published;
  bool get isHidden => status == ExperienceStatus.hidden;
  bool get hasCoordinates => lat != null && lng != null;

  /// Average rating (0 when unrated); prefers the server avg, else derives it.
  double get averageRating => ratingCount == 0
      ? 0
      : (ratingAvg > 0 ? ratingAvg : ratingSum / ratingCount);

  /// Main photo first, then the gallery (deduplicated).
  List<String> get allPhotos => [
        if (mainPhotoUrl.isNotEmpty) mainPhotoUrl,
        ...photoUrls.where((u) => u.isNotEmpty && u != mainPhotoUrl),
      ];

  /// The same listing made free ("Publish as free"): no price, no methods.
  UserExperience asFree() => UserExperience(
        id: id,
        hostId: hostId,
        hostName: hostName,
        hostPhotoUrl: hostPhotoUrl,
        title: title,
        description: description,
        category: category,
        mainPhotoUrl: mainPhotoUrl,
        photoUrls: photoUrls,
        included: included,
        notIncluded: notIncluded,
        locationName: locationName,
        city: city,
        country: country,
        lat: lat,
        lng: lng,
        geohash: geohash,
        meetingPoint: meetingPoint,
        durationMinutes: durationMinutes,
        languages: languages,
        minGroupSize: minGroupSize,
        maxGroupSize: maxGroupSize,
        price: 0,
        currency: null,
        isFree: true,
        paymentLink: null,
        paymentMethods: const {},
        pricingMode: pricingMode,
        maxTicketsPerUser: maxTicketsPerUser,
        availability: availability,
        cancellationPolicy: cancellationPolicy,
        cancellationNotes: cancellationNotes,
        requestToBook: requestToBook,
        allowedScannerIds: allowedScannerIds,
        status: status,
        createdAt: createdAt,
        updatedAt: updatedAt,
        ratingSum: ratingSum,
        ratingCount: ratingCount,
        ratingAvg: ratingAvg,
        ratingDist: ratingDist,
        reviewCount: reviewCount,
        viewCount: viewCount,
        searchKeywords: searchKeywords,
        moderationReason: moderationReason,
        isFeatured: isFeatured,
        featuredUntil: featuredUntil,
        communityId: communityId,
        communityName: communityName,
      );

  UserExperience copyWith({
    ExperienceStatus? status,
    bool? requestToBook,
    List<String>? allowedScannerIds,
    int? ratingSum,
    int? ratingCount,
    double? ratingAvg,
    Map<int, int>? ratingDist,
    int? reviewCount,
  }) =>
      UserExperience(
        id: id,
        hostId: hostId,
        hostName: hostName,
        hostPhotoUrl: hostPhotoUrl,
        title: title,
        description: description,
        category: category,
        mainPhotoUrl: mainPhotoUrl,
        photoUrls: photoUrls,
        included: included,
        notIncluded: notIncluded,
        locationName: locationName,
        city: city,
        country: country,
        lat: lat,
        lng: lng,
        geohash: geohash,
        meetingPoint: meetingPoint,
        durationMinutes: durationMinutes,
        languages: languages,
        minGroupSize: minGroupSize,
        maxGroupSize: maxGroupSize,
        price: price,
        currency: currency,
        isFree: isFree,
        paymentLink: paymentLink,
        paymentMethods: paymentMethods,
        paymentProvider: paymentProvider,
        paymentLinkMethod: paymentLinkMethod,
        paymentInstructions: paymentInstructions,
        pricingMode: pricingMode,
        groupPrice: groupPrice,
        maxTicketsPerUser: maxTicketsPerUser,
        hasRecurringAvailability: hasRecurringAvailability,
        weekendPrice: weekendPrice,
        weekendDays: weekendDays,
        availability: availability,
        cancellationPolicy: cancellationPolicy,
        cancellationNotes: cancellationNotes,
        requestToBook: requestToBook ?? this.requestToBook,
        allowedScannerIds: allowedScannerIds ?? this.allowedScannerIds,
        status: status ?? this.status,
        createdAt: createdAt,
        updatedAt: updatedAt,
        ratingSum: ratingSum ?? this.ratingSum,
        ratingCount: ratingCount ?? this.ratingCount,
        ratingAvg: ratingAvg ?? this.ratingAvg,
        ratingDist: ratingDist ?? this.ratingDist,
        reviewCount: reviewCount ?? this.reviewCount,
        viewCount: viewCount,
        searchKeywords: searchKeywords,
        moderationReason: moderationReason,
        isFeatured: isFeatured,
        featuredUntil: featuredUntil,
        communityId: communityId,
        communityName: communityName,
      );

  @override
  List<Object?> get props => [
        id,
        hostId,
        hostName,
        hostPhotoUrl,
        title,
        description,
        category,
        mainPhotoUrl,
        photoUrls,
        included,
        notIncluded,
        locationName,
        city,
        country,
        lat,
        lng,
        geohash,
        meetingPoint,
        durationMinutes,
        languages,
        minGroupSize,
        maxGroupSize,
        price,
        currency,
        isFree,
        paymentLink,
        paymentMethods,
        paymentProvider,
        paymentLinkMethod,
        paymentInstructions,
        pricingMode,
        groupPrice,
        maxTicketsPerUser,
        hasRecurringAvailability,
        weekendPrice,
        weekendDays,
        availability,
        cancellationPolicy,
        cancellationNotes,
        requestToBook,
        allowedScannerIds,
        status,
        createdAt,
        updatedAt,
        ratingSum,
        ratingCount,
        ratingAvg,
        ratingDist,
        reviewCount,
        viewCount,
        searchKeywords,
        moderationReason,
        isFeatured,
        featuredUntil,
        communityId,
        communityName,
      ];
}
