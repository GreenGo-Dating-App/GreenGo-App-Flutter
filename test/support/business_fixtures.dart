import 'package:greengo_chat/features/profile/domain/entities/location.dart';
import 'package:greengo_chat/features/profile/domain/entities/profile.dart';

/// Business/profile fixtures for storefront + chat widget tests.
/// Builds VALID [Profile] objects with the real constructor. Do NOT edit
/// test/support/mock_data.dart.
class BusinessFixtures {
  static final DateTime _t = DateTime(2026, 7, 15, 12);

  static const Location _lisbon = Location(
    latitude: 38.7223,
    longitude: -9.1393,
    city: 'Lisbon',
    country: 'Portugal',
    displayAddress: 'Lisbon, Portugal',
  );

  /// A regular (non-business) member profile.
  static Profile person({
    String userId = 'user_a',
    String displayName = 'Ava Reyes',
    List<String> photoUrls = const ['https://example.com/ava.jpg'],
    String? nativeLanguage,
    List<String> languages = const ['en'],
    bool isOnline = false,
  }) {
    return Profile(
      userId: userId,
      displayName: displayName,
      dateOfBirth: DateTime(1995, 1, 1),
      gender: 'female',
      photoUrls: photoUrls,
      bio: 'Hello world',
      interests: const ['travel'],
      location: _lisbon,
      languages: languages,
      createdAt: _t,
      updatedAt: _t,
      isComplete: true,
      nativeLanguage: nativeLanguage,
      isOnline: isOnline,
    );
  }

  /// A business/storefront profile (isBusiness == true).
  static Profile business({
    String userId = 'user_biz',
    String displayName = 'Elena Marco',
    String? businessName = "Elena's Cafe",
    String? coverImageUrl = 'https://example.com/cover.jpg',
    List<String> photoUrls = const ['https://example.com/elena.jpg'],
    String? businessCategory = 'Cafe',
    bool isBusiness = true,
  }) {
    return Profile(
      userId: userId,
      displayName: displayName,
      dateOfBirth: DateTime(1990, 5, 5),
      gender: 'female',
      photoUrls: photoUrls,
      bio: 'Best coffee in town',
      interests: const ['coffee'],
      location: _lisbon,
      languages: const ['en', 'pt'],
      createdAt: _t,
      updatedAt: _t,
      isComplete: true,
      isBusiness: isBusiness,
      businessName: businessName,
      businessCategory: businessCategory,
      coverImageUrl: coverImageUrl,
    );
  }
}
