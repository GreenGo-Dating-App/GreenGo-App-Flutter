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

/// One filter chip tapped: turns [filter] on or off (remembered per device).
class GlobeFilterToggled extends GlobeEvent {

  const GlobeFilterToggled(this.filter);
  final GlobeNetworkFilter filter;

  @override
  List<Object?> get props => [filter];
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
