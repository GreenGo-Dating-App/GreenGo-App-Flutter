import 'package:equatable/equatable.dart';

class MatchPreferences extends Equatable {
  final String userId;
  final int minAge;
  final int maxAge;
  final int? maxDistanceKm;
  final String interestedInGender; // 'men', 'women', 'everyone'
  final bool onlyVerified;
  final bool onlyRecentlyActive;
  final List<String> dealBreakers;

  const MatchPreferences({
    required this.userId,
    required this.minAge,
    required this.maxAge,
    this.maxDistanceKm,
    required this.interestedInGender,
    this.onlyVerified = false,
    this.onlyRecentlyActive = false,
    this.dealBreakers = const [],
  });

  factory MatchPreferences.defaultFor(String userId) {
    return MatchPreferences(
      userId: userId,
      minAge: 18,
      maxAge: 99,
      maxDistanceKm: 200, // Default 200km
      interestedInGender: 'everyone',
      onlyVerified: false,
      onlyRecentlyActive: false,
      dealBreakers: const [],
    );
  }

  MatchPreferences copyWith({
    String? userId,
    int? minAge,
    int? maxAge,
    int? maxDistanceKm,
    bool clearMaxDistance = false,
    String? interestedInGender,
    bool? onlyVerified,
    bool? onlyRecentlyActive,
    List<String>? dealBreakers,
  }) {
    return MatchPreferences(
      userId: userId ?? this.userId,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      maxDistanceKm: clearMaxDistance ? null : (maxDistanceKm ?? this.maxDistanceKm),
      interestedInGender: interestedInGender ?? this.interestedInGender,
      onlyVerified: onlyVerified ?? this.onlyVerified,
      onlyRecentlyActive: onlyRecentlyActive ?? this.onlyRecentlyActive,
      dealBreakers: dealBreakers ?? this.dealBreakers,
    );
  }

  /// Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'minAge': minAge,
      'maxAge': maxAge,
      'maxDistanceKm': maxDistanceKm,
      'interestedInGender': interestedInGender,
      'onlyVerified': onlyVerified,
      'onlyRecentlyActive': onlyRecentlyActive,
      'dealBreakers': dealBreakers,
    };
  }

  /// Create from Firestore Map
  factory MatchPreferences.fromMap(Map<String, dynamic> map) {
    return MatchPreferences(
      userId: map['userId'] as String? ?? '',
      minAge: map['minAge'] as int? ?? 18,
      maxAge: map['maxAge'] as int? ?? 99,
      maxDistanceKm: map['maxDistanceKm'] as int?,
      interestedInGender: map['interestedInGender'] as String? ?? 'everyone',
      onlyVerified: map['onlyVerified'] as bool? ?? false,
      onlyRecentlyActive: map['onlyRecentlyActive'] as bool? ?? false,
      dealBreakers: (map['dealBreakers'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }

  @override
  List<Object?> get props => [
        userId,
        minAge,
        maxAge,
        maxDistanceKm,
        interestedInGender,
        onlyVerified,
        onlyRecentlyActive,
        dealBreakers,
      ];
}
