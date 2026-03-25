import 'package:equatable/equatable.dart';
import '../../domain/entities/globe_user.dart';

abstract class GlobeEvent extends Equatable {
  const GlobeEvent();

  @override
  List<Object?> get props => [];
}

class GlobeLoadRequested extends GlobeEvent {
  final String userId;

  const GlobeLoadRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class GlobeRefreshRequested extends GlobeEvent {
  final String userId;

  const GlobeRefreshRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class GlobePinTapped extends GlobeEvent {
  final String tappedUserId;
  final GlobePinType pinType;

  const GlobePinTapped({
    required this.tappedUserId,
    required this.pinType,
  });

  @override
  List<Object?> get props => [tappedUserId, pinType];
}

class GlobeFilterToggled extends GlobeEvent {
  final bool? showMatched;
  final bool? showDiscovery;

  const GlobeFilterToggled({this.showMatched, this.showDiscovery});

  @override
  List<Object?> get props => [showMatched, showDiscovery];
}

class GlobeFlyToCountry extends GlobeEvent {
  final String country;

  const GlobeFlyToCountry({required this.country});

  @override
  List<Object?> get props => [country];
}

class GlobeCountryTapped extends GlobeEvent {
  final String countryName;
  final double latitude;
  final double longitude;

  const GlobeCountryTapped({
    required this.countryName,
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [countryName, latitude, longitude];
}

class GlobeMatchesUpdated extends GlobeEvent {
  final List<GlobeUser> updatedMatches;

  const GlobeMatchesUpdated({required this.updatedMatches});

  @override
  List<Object?> get props => [updatedMatches];
}

class GlobeOnlineStatusUpdated extends GlobeEvent {
  final Map<String, bool> onlineStatusMap;

  const GlobeOnlineStatusUpdated({required this.onlineStatusMap});

  @override
  List<Object?> get props => [onlineStatusMap];
}
