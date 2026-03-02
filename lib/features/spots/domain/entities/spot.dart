import 'package:equatable/equatable.dart';

/// Category types for cultural spots.
enum SpotCategory {
  restaurant,
  cafe,
  culturalSite,
  market,
  viewpoint;

  String get displayName {
    switch (this) {
      case SpotCategory.restaurant:
        return 'Restaurant';
      case SpotCategory.cafe:
        return 'Cafe';
      case SpotCategory.culturalSite:
        return 'Cultural Site';
      case SpotCategory.market:
        return 'Market';
      case SpotCategory.viewpoint:
        return 'Viewpoint';
    }
  }

  String get firestoreValue {
    switch (this) {
      case SpotCategory.restaurant:
        return 'restaurant';
      case SpotCategory.cafe:
        return 'cafe';
      case SpotCategory.culturalSite:
        return 'culturalSite';
      case SpotCategory.market:
        return 'market';
      case SpotCategory.viewpoint:
        return 'viewpoint';
    }
  }

  static SpotCategory fromString(String value) {
    switch (value) {
      case 'restaurant':
        return SpotCategory.restaurant;
      case 'cafe':
        return SpotCategory.cafe;
      case 'culturalSite':
        return SpotCategory.culturalSite;
      case 'market':
        return SpotCategory.market;
      case 'viewpoint':
        return SpotCategory.viewpoint;
      default:
        return SpotCategory.culturalSite;
    }
  }
}

/// A cultural spot (restaurant, cafe, cultural site, market, or viewpoint)
/// that users can discover and review.
class Spot extends Equatable {
  final String id;
  final String name;
  final String description;
  final SpotCategory category;
  final double latitude;
  final double longitude;
  final String city;
  final String country;
  final double rating;
  final int reviewCount;
  final List<String> photos;
  final String createdByUserId;
  final String createdByName;
  final DateTime? createdAt;

  const Spot({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.country,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.photos = const [],
    required this.createdByUserId,
    required this.createdByName,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        category,
        latitude,
        longitude,
        city,
        country,
        rating,
        reviewCount,
        photos,
        createdByUserId,
        createdByName,
        createdAt,
      ];
}
