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
  final List<String> photoUrls;
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

  // Social media links
  final SocialLinks? socialLinks;

  // Membership fields
  final MembershipTier membershipTier;
  final DateTime? membershipStartDate;
  final DateTime? membershipEndDate;

  const Profile({
    required this.userId,
    required this.displayName,
    this.nickname,
    required this.dateOfBirth,
    required this.gender,
    required this.photoUrls,
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
    this.socialLinks,
    this.membershipTier = MembershipTier.free,
    this.membershipStartDate,
    this.membershipEndDate,
  });

  /// Get formatted nickname with @ prefix
  String? get formattedNickname => nickname != null ? '@$nickname' : null;

  /// Check if user can access full app features
  bool get isVerified => verificationStatus == VerificationStatus.approved;

  /// Check if verification is pending review
  bool get isVerificationPending => verificationStatus == VerificationStatus.pending;

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
        photoUrls,
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
        socialLinks,
        membershipTier,
        membershipStartDate,
        membershipEndDate,
      ];

  /// Copy with updated fields
  Profile copyWith({
    String? userId,
    String? displayName,
    String? nickname,
    DateTime? dateOfBirth,
    String? gender,
    List<String>? photoUrls,
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
    SocialLinks? socialLinks,
    MembershipTier? membershipTier,
    DateTime? membershipStartDate,
    DateTime? membershipEndDate,
  }) {
    return Profile(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      nickname: nickname ?? this.nickname,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      photoUrls: photoUrls ?? this.photoUrls,
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
      socialLinks: socialLinks ?? this.socialLinks,
      membershipTier: membershipTier ?? this.membershipTier,
      membershipStartDate: membershipStartDate ?? this.membershipStartDate,
      membershipEndDate: membershipEndDate ?? this.membershipEndDate,
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
