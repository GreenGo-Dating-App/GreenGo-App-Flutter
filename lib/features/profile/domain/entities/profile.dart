import 'package:equatable/equatable.dart';

import '../../../membership/domain/entities/membership.dart';
import 'location.dart';
import 'social_links.dart';

/// Controls how the user appears on the Globe map for discovery.
enum GlobeDiscoverability {
  exact,
  approximate,
  country,
  hidden,
}

/// Verification status for identity verification
enum VerificationStatus {
  notSubmitted,  // User hasn't submitted verification yet
  pending,       // Verification submitted, waiting for admin review
  approved,      // Admin approved the verification
  rejected,      // Admin rejected the verification
  needsResubmission, // Admin requested better photo/document
}

class Profile extends Equatable {

  const Profile({
    required this.userId,
    required this.displayName,
    required this.dateOfBirth, required this.gender, required this.photoUrls, required this.bio, required this.interests, required this.location, required this.languages, required this.createdAt, required this.updatedAt, required this.isComplete, this.nickname,
    this.sexualOrientation,
    this.accountStatus = 'active',
    this.isBoosted = false,
    this.boostExpiry,
    this.isIncognito = false,
    this.incognitoExpiry,
    this.isGhostMode = false,
    this.isTraveler = false,
    this.travelerExpiry,
    this.travelerLocation,
    this.privatePhotoUrls = const [],
    this.voiceRecordingUrl,
    this.personalityTraits,
    this.education,
    this.occupation,
    this.lookingFor,
    this.height,
    this.weight,
    this.verificationStatus = VerificationStatus.notSubmitted,
    this.verificationPhotoUrl,
    this.verificationMethod,
    this.verificationPhone,
    this.verificationRejectionReason,
    this.verificationSubmittedAt,
    this.verificationReviewedAt,
    this.verificationReviewedBy,
    this.isAdmin = false,
    this.isSupport = false,
    this.is2FAEnabled = false,
    this.socialLinks,
    this.membershipTier = MembershipTier.free,
    this.membershipStartDate,
    this.membershipEndDate,
    this.hasBaseMembership = false,
    this.baseMembershipEndDate,
    this.isOnline = false,
    this.lastSeen,
    this.preferredLanguages = const [],
    this.nativeLanguage,
    this.travelPreference,
    this.primaryOrigin,
    this.secondaryOrigin,
    this.isLocalGuide = false,
    this.localGuideCity,
    this.videoProfileUrl,
    this.hasVideoProfile = false,
    this.showOnMap = true,
    this.globeDiscoverability = GlobeDiscoverability.approximate,
    this.completedSafetyModules = const [],
    this.signupGrantsApplied = const [],
    this.signupGrantsAppliedAt,
    this.isBusiness = false,
    this.businessName,
    this.businessLegalName,
    this.businessCategory,
    this.businessWhatsapp,
    this.businessVerified = false,
    this.galleryImages = const [],
    this.openingHours = const [],
    this.storefrontBio,
    this.storefrontLinks = const [],
    this.coverImageUrl,
    this.isBanned = false,
  });
  final String userId;
  final String displayName;
  final String? nickname; // Unique username, format: lowercase alphanumeric + underscores, 3-20 chars
  final DateTime dateOfBirth;
  final String gender;
  final String? sexualOrientation;
  final String accountStatus; // active, suspended, banned, deleted
  final bool isBoosted;
  final DateTime? boostExpiry;
  final bool isIncognito;
  final DateTime? incognitoExpiry;
  final bool isGhostMode; // Ghost Mode: enhanced incognito (Gold/Platinum) - hidden from discovery + nickname search, unlimited
  final bool isTraveler;
  final DateTime? travelerExpiry;
  final Location? travelerLocation; // Temporary location while traveling
  final List<String> photoUrls;
  final List<String> privatePhotoUrls;
  final String bio;
  final List<String> interests;
  final Location location;
  final List<String> languages;
  final String? voiceRecordingUrl;
  final PersonalityTraits? personalityTraits;
  final String? education;
  final String? occupation;
  final String? lookingFor;
  final int? height;
  final int? weight;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isComplete;

  // Verification fields
  final VerificationStatus verificationStatus;
  final String? verificationPhotoUrl;  // Photo of user holding ID
  final String? verificationMethod; // 'photo' or 'phone'
  final String? verificationPhone; // Phone number if verified by SMS
  final String? verificationRejectionReason;
  final DateTime? verificationSubmittedAt;
  final DateTime? verificationReviewedAt;
  final String? verificationReviewedBy;  // Admin user ID
  final bool isAdmin;  // Whether this user is an admin
  final bool isSupport;  // Whether this user is a support agent
  final bool is2FAEnabled;  // Whether 2FA login is enabled

  // Social media links
  final SocialLinks? socialLinks;

  // Membership fields
  final MembershipTier membershipTier;
  final DateTime? membershipStartDate;
  final DateTime? membershipEndDate;

  // Base membership fields (yearly Google Play subscription)
  final bool hasBaseMembership;
  final DateTime? baseMembershipEndDate;

  // Online presence fields
  final bool isOnline;
  final DateTime? lastSeen;

  // Language learning fields
  final List<String> preferredLanguages; // Languages the user wants to learn
  final String? nativeLanguage; // User's native language

  // Travel preference
  final String? travelPreference; // 'learn_travel', 'help_travelers', 'both'

  // Origin fields (ISO 3166-1 alpha-2 country codes)
  final String? primaryOrigin;
  final String? secondaryOrigin;

  // Local guide fields
  final bool isLocalGuide;
  final String? localGuideCity;

  // Video profile fields
  final String? videoProfileUrl;
  final bool hasVideoProfile;

  // Map visibility
  final bool showOnMap;

  // Globe discoverability -- controls how (or if) user appears on 3D globe
  final GlobeDiscoverability globeDiscoverability;

  // Safety academy progress
  final List<String> completedSafetyModules;

  // Signup auto-grants (applied server-side by applySignupGrants trigger).
  // The client renders a one-time welcome banner per grant where dismissed == false.
  final List<SignupGrant> signupGrantsApplied;
  final DateTime? signupGrantsAppliedAt;

  // Business/venue account fields (revenue: featured event placements).
  // Stored on the same profiles/{uid} doc; owner may write isBusiness /
  // businessName / businessLegalName / businessCategory. businessVerified is
  // admin-granted. `businessName` is the STOREFRONT display name (what people
  // see); `businessLegalName` is the registered legal company name.
  final bool isBusiness;
  final String? businessName;
  final String? businessLegalName;
  final String? businessCategory;

  /// Business WhatsApp number (digits, may include country code). When set, the
  /// storefront/profile shows a WhatsApp button that opens wa.me/<number>.
  final String? businessWhatsapp;
  final bool businessVerified;

  // Storefront fields (business/venue accounts). All optional & default
  // empty/null so existing docs stay backward-compatible.
  //  * galleryImages  — dedicated storefront gallery, separate from photoUrls
  //    (which are the owner's personal profile photos). A venue can showcase
  //    products / rooms / dishes here without mixing them into the avatar set.
  //  * openingHours   — structured per-weekday open/close (see OpeningHours).
  //  * storefrontBio  — long-form storefront description (falls back to bio).
  //  * storefrontLinks — arbitrary website/booking/menu URLs (in addition to
  //    the social handles kept in socialLinks).
  final List<String> galleryImages;
  final List<OpeningHours> openingHours;
  final String? storefrontBio;
  final List<String> storefrontLinks;

  // Featured/cover (hero) image for the storefront. Rendered as the top hero
  // banner on the public storefront; distinct from the avatar (photoUrls.first)
  // and the gallery. Optional & null by default so existing docs stay
  // backward-compatible. A legacy empty string is treated as "no cover".
  final String? coverImageUrl;

  // Moderation flag — set by admins elsewhere (Cloud Function / admin tools).
  // The app only READS it (e.g. to hide or gate a banned account). Default false.
  final bool isBanned;

  /// Get formatted nickname with @ prefix
  String? get formattedNickname => nickname != null ? '@$nickname' : null;

  /// Check if user can access full app features
  bool get isVerified => verificationStatus == VerificationStatus.approved;

  /// Check if verification is pending review
  bool get isVerificationPending => verificationStatus == VerificationStatus.pending;

  /// Check if traveler mode is active
  bool get isTravelerActive =>
      isTraveler &&
      travelerExpiry != null &&
      travelerExpiry!.isAfter(DateTime.now());

  /// Get the effective location (traveler location if active, otherwise real location)
  Location get effectiveLocation =>
      isTravelerActive && travelerLocation != null
          ? travelerLocation!
          : location;

  /// Check if any membership is currently active
  /// Checks both legacy base membership fields AND general membership tier fields
  bool get isBaseMembershipActive {
    if (membershipTier == MembershipTier.test) return true;
    // Check general membership tier (set by subscription purchase flow)
    if (membershipTier != MembershipTier.free &&
        membershipEndDate != null &&
        membershipEndDate!.isAfter(DateTime.now())) {
      return true;
    }
    // Check legacy base membership fields
    if (hasBaseMembership &&
        baseMembershipEndDate != null &&
        baseMembershipEndDate!.isAfter(DateTime.now())) {
      return true;
    }
    return false;
  }

  /// Check if verification was rejected or needs resubmission
  bool get needsVerificationAction =>
      verificationStatus == VerificationStatus.rejected ||
      verificationStatus == VerificationStatus.needsResubmission ||
      verificationStatus == VerificationStatus.notSubmitted;

  int get age {
    final now = DateTime.now();
    var age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  @override
  List<Object?> get props => [
        userId,
        displayName,
        nickname,
        dateOfBirth,
        gender,
        sexualOrientation,
        accountStatus,
        isBoosted,
        boostExpiry,
        isIncognito,
        incognitoExpiry,
        isGhostMode,
        isTraveler,
        travelerExpiry,
        travelerLocation,
        photoUrls,
        privatePhotoUrls,
        bio,
        interests,
        location,
        languages,
        voiceRecordingUrl,
        personalityTraits,
        education,
        occupation,
        lookingFor,
        height,
        weight,
        createdAt,
        updatedAt,
        isComplete,
        verificationStatus,
        verificationPhotoUrl,
        verificationMethod,
        verificationPhone,
        verificationRejectionReason,
        verificationSubmittedAt,
        verificationReviewedAt,
        verificationReviewedBy,
        isAdmin,
        isSupport,
        is2FAEnabled,
        socialLinks,
        membershipTier,
        membershipStartDate,
        membershipEndDate,
        hasBaseMembership,
        baseMembershipEndDate,
        isOnline,
        lastSeen,
        preferredLanguages,
        nativeLanguage,
        travelPreference,
        primaryOrigin,
        secondaryOrigin,
        isLocalGuide,
        localGuideCity,
        videoProfileUrl,
        hasVideoProfile,
        showOnMap,
        globeDiscoverability,
        completedSafetyModules,
        signupGrantsApplied,
        signupGrantsAppliedAt,
        isBusiness,
        businessName,
        businessLegalName,
        businessCategory,
        businessWhatsapp,
        businessVerified,
        galleryImages,
        openingHours,
        storefrontBio,
        storefrontLinks,
        coverImageUrl,
        isBanned,
      ];

  /// Copy with updated fields
  Profile copyWith({
    String? userId,
    String? displayName,
    String? nickname,
    DateTime? dateOfBirth,
    String? gender,
    String? sexualOrientation,
    String? accountStatus,
    bool? isBoosted,
    DateTime? boostExpiry,
    bool? isIncognito,
    DateTime? incognitoExpiry,
    bool? isGhostMode,
    bool? isTraveler,
    DateTime? travelerExpiry,
    Location? travelerLocation,
    List<String>? photoUrls,
    List<String>? privatePhotoUrls,
    String? bio,
    List<String>? interests,
    Location? location,
    List<String>? languages,
    String? voiceRecordingUrl,
    PersonalityTraits? personalityTraits,
    String? education,
    String? occupation,
    String? lookingFor,
    int? height,
    int? weight,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isComplete,
    VerificationStatus? verificationStatus,
    String? verificationPhotoUrl,
    String? verificationMethod,
    String? verificationPhone,
    String? verificationRejectionReason,
    DateTime? verificationSubmittedAt,
    DateTime? verificationReviewedAt,
    String? verificationReviewedBy,
    bool? isAdmin,
    bool? isSupport,
    bool? is2FAEnabled,
    SocialLinks? socialLinks,
    MembershipTier? membershipTier,
    DateTime? membershipStartDate,
    DateTime? membershipEndDate,
    bool? hasBaseMembership,
    DateTime? baseMembershipEndDate,
    bool? isOnline,
    DateTime? lastSeen,
    List<String>? preferredLanguages,
    String? nativeLanguage,
    String? travelPreference,
    String? primaryOrigin,
    String? secondaryOrigin,
    bool? isLocalGuide,
    String? localGuideCity,
    String? videoProfileUrl,
    bool? hasVideoProfile,
    bool? showOnMap,
    GlobeDiscoverability? globeDiscoverability,
    List<String>? completedSafetyModules,
    List<SignupGrant>? signupGrantsApplied,
    DateTime? signupGrantsAppliedAt,
    bool? isBusiness,
    String? businessName,
    String? businessLegalName,
    String? businessCategory,
    String? businessWhatsapp,
    bool? businessVerified,
    List<String>? galleryImages,
    List<OpeningHours>? openingHours,
    String? storefrontBio,
    List<String>? storefrontLinks,
    String? coverImageUrl,
    bool? isBanned,
  }) {
    return Profile(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      nickname: nickname ?? this.nickname,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      sexualOrientation: sexualOrientation ?? this.sexualOrientation,
      accountStatus: accountStatus ?? this.accountStatus,
      isBoosted: isBoosted ?? this.isBoosted,
      boostExpiry: boostExpiry ?? this.boostExpiry,
      isIncognito: isIncognito ?? this.isIncognito,
      incognitoExpiry: incognitoExpiry ?? this.incognitoExpiry,
      isGhostMode: isGhostMode ?? this.isGhostMode,
      isTraveler: isTraveler ?? this.isTraveler,
      travelerExpiry: travelerExpiry ?? this.travelerExpiry,
      travelerLocation: travelerLocation ?? this.travelerLocation,
      photoUrls: photoUrls ?? this.photoUrls,
      privatePhotoUrls: privatePhotoUrls ?? this.privatePhotoUrls,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      location: location ?? this.location,
      languages: languages ?? this.languages,
      voiceRecordingUrl: voiceRecordingUrl ?? this.voiceRecordingUrl,
      personalityTraits: personalityTraits ?? this.personalityTraits,
      education: education ?? this.education,
      occupation: occupation ?? this.occupation,
      lookingFor: lookingFor ?? this.lookingFor,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isComplete: isComplete ?? this.isComplete,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verificationPhotoUrl: verificationPhotoUrl ?? this.verificationPhotoUrl,
      verificationMethod: verificationMethod ?? this.verificationMethod,
      verificationPhone: verificationPhone ?? this.verificationPhone,
      verificationRejectionReason: verificationRejectionReason ?? this.verificationRejectionReason,
      verificationSubmittedAt: verificationSubmittedAt ?? this.verificationSubmittedAt,
      verificationReviewedAt: verificationReviewedAt ?? this.verificationReviewedAt,
      verificationReviewedBy: verificationReviewedBy ?? this.verificationReviewedBy,
      isAdmin: isAdmin ?? this.isAdmin,
      isSupport: isSupport ?? this.isSupport,
      is2FAEnabled: is2FAEnabled ?? this.is2FAEnabled,
      socialLinks: socialLinks ?? this.socialLinks,
      membershipTier: membershipTier ?? this.membershipTier,
      membershipStartDate: membershipStartDate ?? this.membershipStartDate,
      membershipEndDate: membershipEndDate ?? this.membershipEndDate,
      hasBaseMembership: hasBaseMembership ?? this.hasBaseMembership,
      baseMembershipEndDate: baseMembershipEndDate ?? this.baseMembershipEndDate,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      preferredLanguages: preferredLanguages ?? this.preferredLanguages,
      nativeLanguage: nativeLanguage ?? this.nativeLanguage,
      travelPreference: travelPreference ?? this.travelPreference,
      primaryOrigin: primaryOrigin ?? this.primaryOrigin,
      secondaryOrigin: secondaryOrigin ?? this.secondaryOrigin,
      isLocalGuide: isLocalGuide ?? this.isLocalGuide,
      localGuideCity: localGuideCity ?? this.localGuideCity,
      videoProfileUrl: videoProfileUrl ?? this.videoProfileUrl,
      hasVideoProfile: hasVideoProfile ?? this.hasVideoProfile,
      showOnMap: showOnMap ?? this.showOnMap,
      globeDiscoverability: globeDiscoverability ?? this.globeDiscoverability,
      completedSafetyModules: completedSafetyModules ?? this.completedSafetyModules,
      signupGrantsApplied: signupGrantsApplied ?? this.signupGrantsApplied,
      signupGrantsAppliedAt: signupGrantsAppliedAt ?? this.signupGrantsAppliedAt,
      isBusiness: isBusiness ?? this.isBusiness,
      businessName: businessName ?? this.businessName,
      businessLegalName: businessLegalName ?? this.businessLegalName,
      businessWhatsapp: businessWhatsapp ?? this.businessWhatsapp,
      businessCategory: businessCategory ?? this.businessCategory,
      businessVerified: businessVerified ?? this.businessVerified,
      galleryImages: galleryImages ?? this.galleryImages,
      openingHours: openingHours ?? this.openingHours,
      storefrontBio: storefrontBio ?? this.storefrontBio,
      storefrontLinks: storefrontLinks ?? this.storefrontLinks,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      isBanned: isBanned ?? this.isBanned,
    );
  }
}

/// Structured opening hours for a single weekday of a business storefront.
///
/// [weekday] follows Dart's `DateTime.weekday` convention (1 = Monday …
/// 7 = Sunday). [open] / [close] are 24h "HH:mm" strings. When [isClosed] is
/// true the day is shown as closed and open/close are ignored.
class OpeningHours extends Equatable {
  const OpeningHours({
    required this.weekday,
    this.open,
    this.close,
    this.isClosed = false,
  });

  factory OpeningHours.fromMap(Map<String, dynamic> m) => OpeningHours(
        weekday: (m['weekday'] as num?)?.toInt() ?? 1,
        open: m['open'] as String?,
        close: m['close'] as String?,
        isClosed: (m['isClosed'] as bool?) ?? false,
      );

  final int weekday;
  final String? open;
  final String? close;
  final bool isClosed;

  OpeningHours copyWith({
    int? weekday,
    String? open,
    String? close,
    bool? isClosed,
  }) =>
      OpeningHours(
        weekday: weekday ?? this.weekday,
        open: open ?? this.open,
        close: close ?? this.close,
        isClosed: isClosed ?? this.isClosed,
      );

  Map<String, dynamic> toMap() => {
        'weekday': weekday,
        'open': open,
        'close': close,
        'isClosed': isClosed,
      };

  @override
  List<Object?> get props => [weekday, open, close, isClosed];
}

/// A grant applied automatically at signup based on the email allowlist.
/// Written by the applySignupGrants Cloud Function trigger.
class SignupGrant extends Equatable {

  const SignupGrant({
    required this.couponId,
    required this.couponCode,
    required this.grantSummary,
    this.dismissed = false,
  });

  factory SignupGrant.fromMap(Map<String, dynamic> m) => SignupGrant(
        couponId: (m['couponId'] as String?) ?? '',
        couponCode: (m['couponCode'] as String?) ?? '',
        grantSummary: (m['grantSummary'] as String?) ?? '',
        dismissed: (m['dismissed'] as bool?) ?? false,
      );
  final String couponId;
  final String couponCode;
  final String grantSummary; // e.g. "GOLD +30d + BASE +30d" or "+500 coins"
  final bool dismissed;

  SignupGrant copyWith({bool? dismissed}) => SignupGrant(
        couponId: couponId,
        couponCode: couponCode,
        grantSummary: grantSummary,
        dismissed: dismissed ?? this.dismissed,
      );

  Map<String, dynamic> toMap() => {
        'couponId': couponId,
        'couponCode': couponCode,
        'grantSummary': grantSummary,
        'dismissed': dismissed,
      };

  @override
  List<Object?> get props => [couponId, couponCode, grantSummary, dismissed];
}

class PersonalityTraits extends Equatable {

  const PersonalityTraits({
    required this.openness,
    required this.conscientiousness,
    required this.extraversion,
    required this.agreeableness,
    required this.neuroticism,
  });
  final int openness;
  final int conscientiousness;
  final int extraversion;
  final int agreeableness;
  final int neuroticism;

  @override
  List<Object?> get props => [
        openness,
        conscientiousness,
        extraversion,
        agreeableness,
        neuroticism,
      ];
}
