import 'package:greengo_chat/features/membership/domain/entities/membership.dart';
import 'package:greengo_chat/features/profile/data/models/profile_model.dart';
import 'package:greengo_chat/features/profile/domain/entities/location.dart';
import 'package:greengo_chat/features/profile/domain/entities/profile.dart';

/// Shared PROFILE fixtures for unit + widget tests.
///
/// These build valid [Profile] / [ProfileModel] entities with EVERY required
/// constructor field populated, so tests can override just the field under
/// test without repeating the (large) constructor. Do NOT edit
/// test/support/mock_data.dart — this is the profile-specific companion.
const kFixtureLocation = LocationModel(
  latitude: 38.7223,
  longitude: -9.1393,
  city: 'Lisbon',
  country: 'Portugal',
  displayAddress: 'Lisbon, Portugal',
);

/// A fixed reference "now" is intentionally NOT used for [dateOfBirth]; callers
/// that assert on [Profile.age] pass their own dateOfBirth.
Profile buildProfile({
  String userId = 'user_fixture_1',
  String displayName = 'Ava Reyes',
  String? nickname,
  DateTime? dateOfBirth,
  String gender = 'female',
  List<String> photoUrls = const ['https://example.com/ava_1.jpg'],
  String bio = 'Love languages and travel.',
  List<String> interests = const ['travel', 'coffee'],
  Location location = kFixtureLocation,
  List<String> languages = const ['English', 'Portuguese'],
  DateTime? createdAt,
  DateTime? updatedAt,
  bool isComplete = true,
  MembershipTier membershipTier = MembershipTier.free,
  DateTime? membershipEndDate,
  bool hasBaseMembership = false,
  DateTime? baseMembershipEndDate,
  bool isTraveler = false,
  DateTime? travelerExpiry,
  Location? travelerLocation,
  VerificationStatus verificationStatus = VerificationStatus.notSubmitted,
  bool isBusiness = false,
  String? businessName,
  String? coverImageUrl,
  DateTime? businessPromotedUntil,
  bool businessVerified = false,
  String? nativeLanguage,
  bool isOnline = false,
}) {
  return ProfileModel(
    userId: userId,
    displayName: displayName,
    nickname: nickname,
    dateOfBirth: dateOfBirth ?? DateTime(1995, 6, 15),
    gender: gender,
    photoUrls: photoUrls,
    bio: bio,
    interests: interests,
    location: location,
    languages: languages,
    createdAt: createdAt ?? DateTime(2024, 1, 1),
    updatedAt: updatedAt ?? DateTime(2024, 6, 1),
    isComplete: isComplete,
    membershipTier: membershipTier,
    membershipEndDate: membershipEndDate,
    hasBaseMembership: hasBaseMembership,
    baseMembershipEndDate: baseMembershipEndDate,
    isTraveler: isTraveler,
    travelerExpiry: travelerExpiry,
    travelerLocation: travelerLocation,
    verificationStatus: verificationStatus,
    isBusiness: isBusiness,
    businessName: businessName,
    coverImageUrl: coverImageUrl,
    businessPromotedUntil: businessPromotedUntil,
    businessVerified: businessVerified,
    nativeLanguage: nativeLanguage,
    isOnline: isOnline,
  );
}

/// A promoted business/venue storefront profile (Elena's Cafe).
Profile buildBusinessProfile({
  bool promoted = true,
  String businessName = "Elena's Cafe",
  String coverImageUrl = 'https://example.com/elena_cover.jpg',
}) {
  return buildProfile(
    userId: 'business_fixture_1',
    displayName: 'Elena Marco',
    isBusiness: true,
    businessName: businessName,
    coverImageUrl: coverImageUrl,
    businessVerified: true,
    businessPromotedUntil: promoted
        ? DateTime.now().add(const Duration(days: 30))
        : DateTime.now().subtract(const Duration(days: 1)),
  );
}
