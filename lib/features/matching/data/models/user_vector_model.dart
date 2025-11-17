import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_vector.dart';

/// User Vector Model
///
/// Data model for storing feature vectors in Firestore
class UserVectorModel extends UserVector {
  const UserVectorModel({
    required super.userId,
    required super.locationVector,
    required super.ageNormalized,
    required super.interestVector,
    required super.personalityVector,
    required super.activityPatternVector,
    required super.additionalFeatures,
  });

  /// Create from domain entity
  factory UserVectorModel.fromEntity(UserVector vector) {
    return UserVectorModel(
      userId: vector.userId,
      locationVector: vector.locationVector,
      ageNormalized: vector.ageNormalized,
      interestVector: vector.interestVector,
      personalityVector: vector.personalityVector,
      activityPatternVector: vector.activityPatternVector,
      additionalFeatures: vector.additionalFeatures,
    );
  }

  /// Create from Firestore document
  factory UserVectorModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserVectorModel(
      userId: doc.id,
      locationVector: List<double>.from(data['locationVector'] ?? []),
      ageNormalized: (data['ageNormalized'] ?? 0.0).toDouble(),
      interestVector: List<double>.from(data['interestVector'] ?? []),
      personalityVector: List<double>.from(data['personalityVector'] ?? []),
      activityPatternVector:
          List<double>.from(data['activityPatternVector'] ?? []),
      additionalFeatures: Map<String, double>.from(
        (data['additionalFeatures'] as Map<String, dynamic>?)?.map(
              (key, value) => MapEntry(key, (value as num).toDouble()),
            ) ??
            {},
      ),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'locationVector': locationVector,
      'ageNormalized': ageNormalized,
      'interestVector': interestVector,
      'personalityVector': personalityVector,
      'activityPatternVector': activityPatternVector,
      'additionalFeatures': additionalFeatures,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Convert to entity
  UserVector toEntity() => this;
}
