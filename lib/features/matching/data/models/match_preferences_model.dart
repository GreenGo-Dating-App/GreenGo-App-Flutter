import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/match_preferences.dart';

/// Match Preferences Model
///
/// Data model for Firestore serialization/deserialization
class MatchPreferencesModel extends MatchPreferences {
  const MatchPreferencesModel({
    required super.userId,
    required super.minAge,
    required super.maxAge,
    required super.maxDistance,
    required super.preferredGenders,
    required super.showOnlyVerified,
    required super.showOnlyWithPhotos,
    required super.dealBreakerInterests,
    required super.preferredLanguages,
    required super.updatedAt,
  });

  /// Create from domain entity
  factory MatchPreferencesModel.fromEntity(MatchPreferences prefs) {
    return MatchPreferencesModel(
      userId: prefs.userId,
      minAge: prefs.minAge,
      maxAge: prefs.maxAge,
      maxDistance: prefs.maxDistance,
      preferredGenders: prefs.preferredGenders,
      showOnlyVerified: prefs.showOnlyVerified,
      showOnlyWithPhotos: prefs.showOnlyWithPhotos,
      dealBreakerInterests: prefs.dealBreakerInterests,
      preferredLanguages: prefs.preferredLanguages,
      updatedAt: prefs.updatedAt,
    );
  }

  /// Create from Firestore document
  factory MatchPreferencesModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return MatchPreferencesModel(
      userId: doc.id,
      minAge: data['minAge'] ?? 18,
      maxAge: data['maxAge'] ?? 99,
      maxDistance: (data['maxDistance'] ?? 100.0).toDouble(),
      preferredGenders: List<String>.from(data['preferredGenders'] ?? []),
      showOnlyVerified: data['showOnlyVerified'] ?? false,
      showOnlyWithPhotos: data['showOnlyWithPhotos'] ?? true,
      dealBreakerInterests: List<String>.from(data['dealBreakerInterests'] ?? []),
      preferredLanguages: List<String>.from(data['preferredLanguages'] ?? []),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'minAge': minAge,
      'maxAge': maxAge,
      'maxDistance': maxDistance,
      'preferredGenders': preferredGenders,
      'showOnlyVerified': showOnlyVerified,
      'showOnlyWithPhotos': showOnlyWithPhotos,
      'dealBreakerInterests': dealBreakerInterests,
      'preferredLanguages': preferredLanguages,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Convert to entity
  MatchPreferences toEntity() => this;
}
