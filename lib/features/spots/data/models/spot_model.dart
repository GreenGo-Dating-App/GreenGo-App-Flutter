import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/spot.dart';

/// Firestore-backed model for [Spot].
class SpotModel extends Spot {
  const SpotModel({
    required super.id,
    required super.name,
    required super.description,
    required super.category,
    required super.latitude,
    required super.longitude,
    required super.city,
    required super.country,
    super.rating,
    super.reviewCount,
    super.photos,
    required super.createdByUserId,
    required super.createdByName,
    super.createdAt,
  });

  /// Create a [SpotModel] from a Firestore document snapshot.
  factory SpotModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return SpotModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: SpotCategory.fromString(data['category'] as String? ?? 'culturalSite'),
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      city: data['city'] as String? ?? '',
      country: data['country'] as String? ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: data['reviewCount'] as int? ?? 0,
      photos: data['photos'] != null
          ? List<String>.from(data['photos'] as List)
          : <String>[],
      createdByUserId: data['createdByUserId'] as String? ?? '',
      createdByName: data['createdByName'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to a Firestore-compatible JSON map.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'category': category.firestoreValue,
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'country': country,
      'rating': rating,
      'reviewCount': reviewCount,
      'photos': photos,
      'createdByUserId': createdByUserId,
      'createdByName': createdByName,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  /// Create a [SpotModel] from a domain [Spot] entity.
  factory SpotModel.fromEntity(Spot spot) {
    return SpotModel(
      id: spot.id,
      name: spot.name,
      description: spot.description,
      category: spot.category,
      latitude: spot.latitude,
      longitude: spot.longitude,
      city: spot.city,
      country: spot.country,
      rating: spot.rating,
      reviewCount: spot.reviewCount,
      photos: spot.photos,
      createdByUserId: spot.createdByUserId,
      createdByName: spot.createdByName,
      createdAt: spot.createdAt,
    );
  }
}
