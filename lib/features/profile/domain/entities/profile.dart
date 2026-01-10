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

  // Social media links
  final SocialLinks? socialLinks;

  // Membership fields
  final MembershipTier membershipTier;
  final DateTime? membershipStartDate;
  final DateTime? membershipEndDate;

  const Profile({
    required this.userId,
    required this.displayName,
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
    this.socialLinks,
    this.membershipTier = MembershipTier.free,
    this.membershipStartDate,
    this.membershipEndDate,
  });

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
        socialLinks,
        membershipTier,
        membershipStartDate,
        membershipEndDate,
      ];
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
