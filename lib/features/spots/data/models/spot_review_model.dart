import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/spot_review.dart';

/// Firestore-backed model for [SpotReview].
class SpotReviewModel extends SpotReview {
  const SpotReviewModel({
    required super.id,
    required super.spotId,
    required super.userId,
    required super.userName,
    super.userPhotoUrl,
    required super.rating,
    required super.text,
    required super.createdAt,
  });

  /// Create a [SpotReviewModel] from a Firestore document snapshot.
  ///
  /// The [spotId] is passed separately since reviews are stored in
  /// a subcollection under the spot document.
  factory SpotReviewModel.fromFirestore(DocumentSnapshot doc, String spotId) {
    final data = doc.data() as Map<String, dynamic>;

    return SpotReviewModel(
      id: doc.id,
      spotId: spotId,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      userPhotoUrl: data['userPhotoUrl'] as String?,
      rating: (data['rating'] as num?)?.toInt() ?? 0,
      text: data['text'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to a Firestore-compatible JSON map.
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'rating': rating,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create a [SpotReviewModel] from a domain [SpotReview] entity.
  factory SpotReviewModel.fromEntity(SpotReview review) {
    return SpotReviewModel(
      id: review.id,
      spotId: review.spotId,
      userId: review.userId,
      userName: review.userName,
      userPhotoUrl: review.userPhotoUrl,
      rating: review.rating,
      text: review.text,
      createdAt: review.createdAt,
    );
  }
}
