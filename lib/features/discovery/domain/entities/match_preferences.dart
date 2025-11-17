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
      maxDistanceKm: 50,
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
    String? interestedInGender,
    bool? onlyVerified,
    bool? onlyRecentlyActive,
    List<String>? dealBreakers,
  }) {
    return MatchPreferences(
      userId: userId ?? this.userId,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
      interestedInGender: interestedInGender ?? this.interestedInGender,
      onlyVerified: onlyVerified ?? this.onlyVerified,
      onlyRecentlyActive: onlyRecentlyActive ?? this.onlyRecentlyActive,
      dealBreakers: dealBreakers ?? this.dealBreakers,
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
