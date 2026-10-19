import 'package:equatable/equatable.dart';

/// `matched` = a person of the user's network (the name predates the
/// follow / chat network map); `business` = a business account, pinned at
/// its public business address.
enum GlobePinType { currentUser, matched, discovery, business }

/// How a pin is connected to the signed-in user (a pin can be several).
enum GlobeRelation { following, follower, chatted }

/// The filter chips of the network map (multi-select).
enum GlobeNetworkFilter { following, followers, chats, businesses }

/// Every chip on (the default).
const Set<GlobeNetworkFilter> kAllGlobeFilters = {
  GlobeNetworkFilter.following,
  GlobeNetworkFilter.followers,
  GlobeNetworkFilter.chats,
  GlobeNetworkFilter.businesses,
};

enum GlobeDiscoverability { exact, approximate, country, hidden }

class GlobeUser extends Equatable {

  const GlobeUser({
    required this.userId,
    required this.displayName,
    required this.pinLatitude, required this.pinLongitude, required this.country, required this.city, required this.pinType, this.photoUrl,
    this.isOnline = false,
    this.isTravelerActive = false,
    this.travelerCountry,
    this.matchId,
    this.discoverability = GlobeDiscoverability.approximate,
    this.realCountryLatitude,
    this.realCountryLongitude,
    this.relations = const {},
    this.isBusiness = false,
  });
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

  /// Why this pin is on the network map (badges on the pin).
  final Set<GlobeRelation> relations;

  /// A business account: pinned at its business address, opens the
  /// storefront, shown by the "Businesses" chip.
  final bool isBusiness;

  /// Whether the chips in [filters] show this pin: businesses by the
  /// Businesses chip; people when any of their relations' chips is on.
  bool visibleWith(Set<GlobeNetworkFilter> filters) {
    if (isBusiness) return filters.contains(GlobeNetworkFilter.businesses);
    return (relations.contains(GlobeRelation.following) &&
            filters.contains(GlobeNetworkFilter.following)) ||
        (relations.contains(GlobeRelation.follower) &&
            filters.contains(GlobeNetworkFilter.followers)) ||
        (relations.contains(GlobeRelation.chatted) &&
            filters.contains(GlobeNetworkFilter.chats));
  }

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
    Set<GlobeRelation>? relations,
    bool? isBusiness,
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
      relations: relations ?? this.relations,
      isBusiness: isBusiness ?? this.isBusiness,
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
        relations,
        isBusiness,
      ];
}

class GlobeData extends Equatable {

  const GlobeData({
    required this.currentUser,
    required this.matchedUsers,
    required this.discoveryUsers,
  });
  final GlobeUser currentUser;

  /// The user's network pins (people followed / following / chatted with,
  /// businesses followed or chatted with), one pin per account.
  final List<GlobeUser> matchedUsers;
  final List<GlobeUser> discoveryUsers;

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

  /// The same data with only the network pins [filters] show.
  GlobeData filteredBy(Set<GlobeNetworkFilter> filters) => GlobeData(
        currentUser: currentUser,
        matchedUsers: [
          for (final u in matchedUsers)
            if (u.visibleWith(filters)) u,
        ],
        discoveryUsers: discoveryUsers,
      );

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
