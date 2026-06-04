import 'package:equatable/equatable.dart';
import '../../domain/entities/globe_user.dart';

abstract class GlobeEvent extends Equatable {
  const GlobeEvent();

  @override
  List<Object?> get props => [];
}

class GlobeLoadRequested extends GlobeEvent {

  const GlobeLoadRequested({required this.userId});
  final String userId;

  @override
  List<Object?> get props => [userId];
}

class GlobeRefreshRequested extends GlobeEvent {

  const GlobeRefreshRequested({required this.userId});
  final String userId;

  @override
  List<Object?> get props => [userId];
}

class GlobePinTapped extends GlobeEvent {

  const GlobePinTapped({
    required this.tappedUserId,
    required this.pinType,
  });
  final String tappedUserId;
  final GlobePinType pinType;

  @override
  List<Object?> get props => [tappedUserId, pinType];
}

class GlobeFilterToggled extends GlobeEvent {

  const GlobeFilterToggled({this.showMatched, this.showDiscovery});
  final bool? showMatched;
  final bool? showDiscovery;

  @override
  List<Object?> get props => [showMatched, showDiscovery];
}

class GlobeFlyToCountry extends GlobeEvent {

  const GlobeFlyToCountry({required this.country});
  final String country;

  @override
  List<Object?> get props => [country];
}

class GlobeCountryTapped extends GlobeEvent {

  const GlobeCountryTapped({
    required this.countryName,
    required this.latitude,
    required this.longitude,
  });
  final String countryName;
  final double latitude;
  final double longitude;

  @override
  List<Object?> get props => [countryName, latitude, longitude];
}

class GlobeMatchesUpdated extends GlobeEvent {

  const GlobeMatchesUpdated({required this.updatedMatches});
  final List<GlobeUser> updatedMatches;

  @override
  List<Object?> get props => [updatedMatches];
}

class GlobeOnlineStatusUpdated extends GlobeEvent {

  const GlobeOnlineStatusUpdated({required this.onlineStatusMap});
  final Map<String, bool> onlineStatusMap;

  @override
  List<Object?> get props => [onlineStatusMap];
}
