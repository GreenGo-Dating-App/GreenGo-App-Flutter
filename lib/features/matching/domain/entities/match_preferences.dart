/// Match Preferences Entity
///
/// User's preferences for finding matches.
class MatchPreferences {
  final String userId;
  final int minAge;
  final int maxAge;
  final double maxDistance; // in kilometers
  final List<String> preferredGenders;
  final bool showOnlyVerified;
  final bool showOnlyWithPhotos;
  final List<String> dealBreakerInterests; // Must have these interests
  final List<String> preferredLanguages; // Preferred common languages
  final List<String> preferredCountries; // Empty = user's own country
  final DateTime updatedAt;

  const MatchPreferences({
    required this.userId,
    this.minAge = 18,
    this.maxAge = 99,
    this.maxDistance = 100.0, // Default 100km
    this.preferredGenders = const ['Female', 'Male', 'Non-binary'],
    this.showOnlyVerified = false,
    this.showOnlyWithPhotos = true,
    this.dealBreakerInterests = const [],
    this.preferredLanguages = const [],
    this.preferredCountries = const [],
    required this.updatedAt,
  });

  /// Create default preferences for a user
  factory MatchPreferences.defaultFor(String userId) {
    return MatchPreferences(
      userId: userId,
      minAge: 18,
      maxAge: 99,
      maxDistance: 99999.0, // No distance limit by default (worldwide)
      preferredGenders: const ['Female', 'Male', 'Non-binary'],
      showOnlyVerified: false,
      showOnlyWithPhotos: false, // Show all profiles including those without photos
      dealBreakerInterests: const [],
      preferredLanguages: const [],
      preferredCountries: const [],
      updatedAt: DateTime.now(),
    );
  }

  /// Get age range as string
  String get ageRangeText => '$minAge-$maxAge years';

  /// Get distance as string
  String get distanceText {
    if (maxDistance < 1) {
      return '${(maxDistance * 1000).toStringAsFixed(0)}m';
    } else if (maxDistance >= 1000) {
      return 'Any distance';
    } else {
      return '${maxDistance.toStringAsFixed(0)}km';
    }
  }

  /// Copy with updated values
  MatchPreferences copyWith({
    int? minAge,
    int? maxAge,
    double? maxDistance,
    List<String>? preferredGenders,
    bool? showOnlyVerified,
    bool? showOnlyWithPhotos,
    List<String>? dealBreakerInterests,
    List<String>? preferredLanguages,
    List<String>? preferredCountries,
  }) {
    return MatchPreferences(
      userId: userId,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      maxDistance: maxDistance ?? this.maxDistance,
      preferredGenders: preferredGenders ?? this.preferredGenders,
      showOnlyVerified: showOnlyVerified ?? this.showOnlyVerified,
      showOnlyWithPhotos: showOnlyWithPhotos ?? this.showOnlyWithPhotos,
      dealBreakerInterests: dealBreakerInterests ?? this.dealBreakerInterests,
      preferredLanguages: preferredLanguages ?? this.preferredLanguages,
      preferredCountries: preferredCountries ?? this.preferredCountries,
      updatedAt: DateTime.now(),
    );
  }
}
