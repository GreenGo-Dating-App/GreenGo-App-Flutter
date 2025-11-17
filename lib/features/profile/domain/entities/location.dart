import 'package:equatable/equatable.dart';

class Location extends Equatable {
  final double latitude;
  final double longitude;
  final String city;
  final String country;
  final String displayAddress;

  const Location({
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.country,
    required this.displayAddress,
  });

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        city,
        country,
        displayAddress,
      ];

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'country': country,
      'displayAddress': displayAddress,
    };
  }

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      city: json['city'] as String,
      country: json['country'] as String,
      displayAddress: json['displayAddress'] as String,
    );
  }
}
