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
    this.availability,
    this.cancellationPolicy,
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

  final String? availability;
  final String? cancellationPolicy;

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

  UserExperience copyWith({
    ExperienceStatus? status,
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
        availability: availability,
        cancellationPolicy: cancellationPolicy,
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
        availability,
        cancellationPolicy,
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
      ];
}
