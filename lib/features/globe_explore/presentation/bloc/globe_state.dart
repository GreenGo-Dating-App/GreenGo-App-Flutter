import 'package:equatable/equatable.dart';
import '../../domain/entities/globe_user.dart';

abstract class GlobeState extends Equatable {
  const GlobeState();

  @override
  List<Object?> get props => [];
}

class GlobeInitial extends GlobeState {}

class GlobeLoading extends GlobeState {}

class GlobeLoaded extends GlobeState {

  const GlobeLoaded({
    required this.data,
    this.showMatched = true,
    this.showDiscovery = true,
    this.flyToCountry,
  });
  final GlobeData data;
  final bool showMatched;
  final bool showDiscovery;
  final String? flyToCountry;

  @override
  List<Object?> get props => [data, showMatched, showDiscovery, flyToCountry];
}

class GlobeError extends GlobeState {

  const GlobeError({required this.message});
  final String message;

  @override
  List<Object?> get props => [message];
}

class GlobePinSelected extends GlobeState {

  const GlobePinSelected({
    required this.selectedUser,
    required this.data,
    required this.showMatched,
    required this.showDiscovery,
  });
  final GlobeUser selectedUser;
  final GlobeData data;
  final bool showMatched;
  final bool showDiscovery;

  @override
  List<Object?> get props => [selectedUser, data, showMatched, showDiscovery];
}

class GlobeCountrySelected extends GlobeState {

  const GlobeCountrySelected({
    required this.countryName,
    required this.matchesInCountry,
    required this.data,
    required this.showMatched,
    required this.showDiscovery,
  });
  final String countryName;
  final List<GlobeUser> matchesInCountry;
  final GlobeData data;
  final bool showMatched;
  final bool showDiscovery;

  @override
  List<Object?> get props =>
      [countryName, matchesInCountry, data, showMatched, showDiscovery];
}
