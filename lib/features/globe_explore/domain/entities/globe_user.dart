import 'package:equatable/equatable.dart';

enum GlobePinType { currentUser, matched, discovery }

enum GlobeDiscoverability { exact, approximate, country, hidden }

class GlobeUser extends Equatable {
  final String userId;
  final String displayName;
  final String? photoUrl;
  final double pinLatitude;
  final double pinLongitude;
  final String country;
  final String city;
  final GlobePinType pinType;
  final bool isOnline;
  final bool isTravelerActive;
  final String? travelerCountry;
  final String? matchId;
  final GlobeDiscoverability discoverability;
  final double? realCountryLatitude;
  final double? realCountryLongitude;

  const GlobeUser({
    required this.userId,
    required this.displayName,
    this.photoUrl,
    required this.pinLatitude,
    required this.pinLongitude,
    required this.country,
    required this.city,
    required this.pinType,
    this.isOnline = false,
    this.isTravelerActive = false,
    this.travelerCountry,
    this.matchId,
    this.discoverability = GlobeDiscoverability.approximate,
    this.realCountryLatitude,
    this.realCountryLongitude,
  });

  GlobeUser copyWith({
    String? userId,
    String? displayName,
    String? photoUrl,
    double? pinLatitude,
    double? pinLongitude,
    String? country,
    String? city,
    GlobePinType? pinType,
    bool? isOnline,
    bool? isTravelerActive,
    String? travelerCountry,
    String? matchId,
    GlobeDiscoverability? discoverability,
    double? realCountryLatitude,
    double? realCountryLongitude,
  }) {
    return GlobeUser(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      pinLatitude: pinLatitude ?? this.pinLatitude,
      pinLongitude: pinLongitude ?? this.pinLongitude,
      country: country ?? this.country,
      city: city ?? this.city,
      pinType: pinType ?? this.pinType,
      isOnline: isOnline ?? this.isOnline,
      isTravelerActive: isTravelerActive ?? this.isTravelerActive,
      travelerCountry: travelerCountry ?? this.travelerCountry,
      matchId: matchId ?? this.matchId,
      discoverability: discoverability ?? this.discoverability,
      realCountryLatitude: realCountryLatitude ?? this.realCountryLatitude,
      realCountryLongitude: realCountryLongitude ?? this.realCountryLongitude,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        displayName,
        photoUrl,
        pinLatitude,
        pinLongitude,
        country,
        city,
        pinType,
        isOnline,
        isTravelerActive,
        travelerCountry,
        matchId,
        discoverability,
        realCountryLatitude,
        realCountryLongitude,
      ];
}

class GlobeData extends Equatable {
  final GlobeUser currentUser;
  final List<GlobeUser> matchedUsers;
  final List<GlobeUser> discoveryUsers;

  const GlobeData({
    required this.currentUser,
    required this.matchedUsers,
    required this.discoveryUsers,
  });

  List<GlobeUser> getFilteredUsers({
    required bool showMatched,
    required bool showDiscovery,
  }) {
    return [
      currentUser,
      if (showMatched) ...matchedUsers,
      if (showDiscovery) ...discoveryUsers,
    ];
  }

  List<String> get allCountries {
    final countries = <String>{};
    countries.add(currentUser.country);
    for (final u in matchedUsers) {
      countries.add(u.country);
    }
    for (final u in discoveryUsers) {
      countries.add(u.country);
    }
    return countries.toList()..sort();
  }

  GlobeData copyWithOnlineStatus(Map<String, bool> statusMap) {
    return GlobeData(
      currentUser: currentUser,
      matchedUsers: matchedUsers
          .map((u) => statusMap.containsKey(u.userId)
              ? u.copyWith(isOnline: statusMap[u.userId]!)
              : u)
          .toList(),
      discoveryUsers: discoveryUsers
          .map((u) => statusMap.containsKey(u.userId)
              ? u.copyWith(isOnline: statusMap[u.userId]!)
              : u)
          .toList(),
    );
  }

  @override
  List<Object?> get props => [currentUser, matchedUsers, discoveryUsers];
}
