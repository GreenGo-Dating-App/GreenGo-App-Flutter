import 'package:equatable/equatable.dart';

/// See Who Liked You Entity
class SecretAdmirer extends Equatable {
  final String id;
  final String admirerId;
  final String admirerName;
  final String? admirerPhotoUrl;
  final int admirerAge;
  final String? admirerBio;
  final DateTime likedAt;
  final bool isRevealed;
  final bool isSuperLike;
  final double? compatibilityScore;

  const SecretAdmirer({
    required this.id,
    required this.admirerId,
    required this.admirerName,
    this.admirerPhotoUrl,
    required this.admirerAge,
    this.admirerBio,
    required this.likedAt,
    this.isRevealed = false,
    this.isSuperLike = false,
    this.compatibilityScore,
  });

  @override
  List<Object?> get props => [
        id,
        admirerId,
        admirerName,
        admirerPhotoUrl,
        admirerAge,
        admirerBio,
        likedAt,
        isRevealed,
        isSuperLike,
        compatibilityScore,
      ];
}

/// Travel Mode Entity
class TravelMode extends Equatable {
  final String id;
  final String userId;
  final String destinationCity;
  final String destinationCountry;
  final double latitude;
  final double longitude;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final bool showInDestination;
  final DateTime createdAt;

  const TravelMode({
    required this.id,
    required this.userId,
    required this.destinationCity,
    required this.destinationCountry,
    required this.latitude,
    required this.longitude,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.showInDestination = true,
    required this.createdAt,
  });

  bool get isTraveling =>
      isActive &&
      DateTime.now().isAfter(startDate) &&
      DateTime.now().isBefore(endDate);

  int get daysRemaining => endDate.difference(DateTime.now()).inDays;

  @override
  List<Object?> get props => [
        id,
        userId,
        destinationCity,
        destinationCountry,
        latitude,
        longitude,
        startDate,
        endDate,
        isActive,
        showInDestination,
        createdAt,
      ];
}

/// Advanced Filters Entity
class AdvancedFilters extends Equatable {
  final String userId;
  final int? minHeight;
  final int? maxHeight;
  final List<String>? educationLevels;
  final List<String>? occupations;
  final List<String>? religions;
  final List<String>? ethnicities;
  final List<String>? languages;
  final bool? hasChildren;
  final bool? wantsChildren;
  final List<String>? smokingPreference;
  final List<String>? drinkingPreference;
  final List<String>? exerciseFrequency;
  final List<String>? dietaryPreferences;
  final List<String>? zodiacSigns;
  final bool? hasVerifiedPhotos;
  final bool? hasVideoProfile;
  final int? minIncome;
  final int? maxIncome;
  final List<String>? politicalViews;
  final List<String>? relationshipGoals;
  final DateTime? lastUpdated;

  const AdvancedFilters({
    required this.userId,
    this.minHeight,
    this.maxHeight,
    this.educationLevels,
    this.occupations,
    this.religions,
    this.ethnicities,
    this.languages,
    this.hasChildren,
    this.wantsChildren,
    this.smokingPreference,
    this.drinkingPreference,
    this.exerciseFrequency,
    this.dietaryPreferences,
    this.zodiacSigns,
    this.hasVerifiedPhotos,
    this.hasVideoProfile,
    this.minIncome,
    this.maxIncome,
    this.politicalViews,
    this.relationshipGoals,
    this.lastUpdated,
  });

  bool get hasActiveFilters =>
      minHeight != null ||
      maxHeight != null ||
      (educationLevels?.isNotEmpty ?? false) ||
      (occupations?.isNotEmpty ?? false) ||
      (religions?.isNotEmpty ?? false) ||
      (ethnicities?.isNotEmpty ?? false) ||
      (languages?.isNotEmpty ?? false) ||
      hasChildren != null ||
      wantsChildren != null ||
      (smokingPreference?.isNotEmpty ?? false) ||
      (drinkingPreference?.isNotEmpty ?? false) ||
      (exerciseFrequency?.isNotEmpty ?? false) ||
      (dietaryPreferences?.isNotEmpty ?? false) ||
      (zodiacSigns?.isNotEmpty ?? false) ||
      hasVerifiedPhotos != null ||
      hasVideoProfile != null;

  @override
  List<Object?> get props => [
        userId,
        minHeight,
        maxHeight,
        educationLevels,
        occupations,
        religions,
        ethnicities,
        languages,
        hasChildren,
        wantsChildren,
        smokingPreference,
        drinkingPreference,
        exerciseFrequency,
        dietaryPreferences,
        zodiacSigns,
        hasVerifiedPhotos,
        hasVideoProfile,
        minIncome,
        maxIncome,
        politicalViews,
        relationshipGoals,
        lastUpdated,
      ];

  AdvancedFilters copyWith({
    String? userId,
    int? minHeight,
    int? maxHeight,
    List<String>? educationLevels,
    List<String>? occupations,
    List<String>? religions,
    List<String>? ethnicities,
    List<String>? languages,
    bool? hasChildren,
    bool? wantsChildren,
    List<String>? smokingPreference,
    List<String>? drinkingPreference,
    List<String>? exerciseFrequency,
    List<String>? dietaryPreferences,
    List<String>? zodiacSigns,
    bool? hasVerifiedPhotos,
    bool? hasVideoProfile,
    int? minIncome,
    int? maxIncome,
    List<String>? politicalViews,
    List<String>? relationshipGoals,
    DateTime? lastUpdated,
  }) {
    return AdvancedFilters(
      userId: userId ?? this.userId,
      minHeight: minHeight ?? this.minHeight,
      maxHeight: maxHeight ?? this.maxHeight,
      educationLevels: educationLevels ?? this.educationLevels,
      occupations: occupations ?? this.occupations,
      religions: religions ?? this.religions,
      ethnicities: ethnicities ?? this.ethnicities,
      languages: languages ?? this.languages,
      hasChildren: hasChildren ?? this.hasChildren,
      wantsChildren: wantsChildren ?? this.wantsChildren,
      smokingPreference: smokingPreference ?? this.smokingPreference,
      drinkingPreference: drinkingPreference ?? this.drinkingPreference,
      exerciseFrequency: exerciseFrequency ?? this.exerciseFrequency,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      zodiacSigns: zodiacSigns ?? this.zodiacSigns,
      hasVerifiedPhotos: hasVerifiedPhotos ?? this.hasVerifiedPhotos,
      hasVideoProfile: hasVideoProfile ?? this.hasVideoProfile,
      minIncome: minIncome ?? this.minIncome,
      maxIncome: maxIncome ?? this.maxIncome,
      politicalViews: politicalViews ?? this.politicalViews,
      relationshipGoals: relationshipGoals ?? this.relationshipGoals,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Priority Visibility / Boost Entity
class ProfileBoost extends Equatable {
  final String id;
  final String userId;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final int impressions;
  final int profileViews;
  final int newLikes;
  final int newMatches;
  final bool isActive;
  final String? boostType; // 'free', 'purchased', 'reward'

  const ProfileBoost({
    required this.id,
    required this.userId,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    this.impressions = 0,
    this.profileViews = 0,
    this.newLikes = 0,
    this.newMatches = 0,
    this.isActive = true,
    this.boostType,
  });

  Duration get remainingTime =>
      isActive ? endTime.difference(DateTime.now()) : Duration.zero;

  double get effectivenessScore {
    if (impressions == 0) return 0;
    return (newMatches * 10 + newLikes * 2 + profileViews) / impressions * 100;
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        startTime,
        endTime,
        durationMinutes,
        impressions,
        profileViews,
        newLikes,
        newMatches,
        isActive,
        boostType,
      ];
}
