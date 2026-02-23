import 'package:equatable/equatable.dart';
import 'location.dart';
import 'social_links.dart';
import '../../../membership/domain/entities/membership.dart';

/// Verification status for identity verification
enum VerificationStatus {
  notSubmitted,  // User hasn't submitted verification yet
  pending,       // Verification submitted, waiting for admin review
  approved,      // Admin approved the verification
  rejected,      // Admin rejected the verification
  needsResubmission, // Admin requested better photo/document
}

class Profile extends Equatable {
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

  const Profile({
    required this.userId,
    required this.displayName,
    this.nickname,
    required this.dateOfBirth,
    required this.gender,
    this.sexualOrientation,
    this.accountStatus = 'active',
    this.isBoosted = false,
    this.boostExpiry,
    this.isIncognito = false,
    this.incognitoExpiry,
    this.isTraveler = false,
    this.travelerExpiry,
    this.travelerLocation,
    required this.photoUrls,
    this.privatePhotoUrls = const [],
    required this.bio,
    required this.interests,
    required this.location,
    required this.languages,
    this.voiceRecordingUrl,
    this.personalityTraits,
    this.education,
    this.occupation,
    this.lookingFor,
    this.height,
    this.weight,
    required this.createdAt,
    required this.updatedAt,
    required this.isComplete,
    this.verificationStatus = VerificationStatus.notSubmitted,
    this.verificationPhotoUrl,
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
  });

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

  /// Check if base membership is currently active
  bool get isBaseMembershipActive {
    if (membershipTier == MembershipTier.test) return true;
    if (!hasBaseMembership) return false;
    if (baseMembershipEndDate == null) return false;
    return baseMembershipEndDate!.isAfter(DateTime.now());
  }

  /// Check if verification was rejected or needs resubmission
  bool get needsVerificationAction =>
      verificationStatus == VerificationStatus.rejected ||
      verificationStatus == VerificationStatus.needsResubmission ||
      verificationStatus == VerificationStatus.notSubmitted;

  int get age {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
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
    );
  }
}

class PersonalityTraits extends Equatable {
  final int openness;
  final int conscientiousness;
  final int extraversion;
  final int agreeableness;
  final int neuroticism;

  const PersonalityTraits({
    required this.openness,
    required this.conscientiousness,
    required this.extraversion,
    required this.agreeableness,
    required this.neuroticism,
  });

  @override
  List<Object?> get props => [
        openness,
        conscientiousness,
        extraversion,
        agreeableness,
        neuroticism,
      ];
}
