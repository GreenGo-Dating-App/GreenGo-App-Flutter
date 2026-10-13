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
    this.flyRequestId = 0,
  });
  final GlobeData data;
  final bool showMatched;
  final bool showDiscovery;
  final String? flyToCountry;

  /// Bumped per fly request, so jumping to the same country twice is still
  /// a new state (Equatable would otherwise swallow it).
  final int flyRequestId;

  @override
  List<Object?> get props =>
      [data, showMatched, showDiscovery, flyToCountry, flyRequestId];
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
    this.requestId = 0,
  });
  final GlobeUser selectedUser;
  final GlobeData data;
  final bool showMatched;
  final bool showDiscovery;

  /// Bumped per tap, so tapping the same pin again re-opens its sheet.
  final int requestId;

  @override
  List<Object?> get props =>
      [selectedUser, data, showMatched, showDiscovery, requestId];
}

class GlobeCountrySelected extends GlobeState {

  const GlobeCountrySelected({
    required this.countryName,
    required this.matchesInCountry,
    required this.data,
    required this.showMatched,
    required this.showDiscovery,
    this.requestId = 0,
  });
  final String countryName;
  final List<GlobeUser> matchesInCountry;
  final GlobeData data;
  final bool showMatched;
  final bool showDiscovery;

  /// Bumped per tap, so tapping the same country again re-opens its sheet.
  final int requestId;

  @override
  List<Object?> get props => [
        countryName,
        matchesInCountry,
        data,
        showMatched,
        showDiscovery,
        requestId,
      ];
}
