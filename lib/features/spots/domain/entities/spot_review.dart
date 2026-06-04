import 'package:equatable/equatable.dart';

/// A review left by a user on a cultural spot.
class SpotReview extends Equatable {

  const SpotReview({
    required this.id,
    required this.spotId,
    required this.userId,
    required this.userName,
    required this.rating, required this.text, required this.createdAt, this.userPhotoUrl,
  });
  final String id;
  final String spotId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final int rating; // 1-5
  final String text;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        spotId,
        userId,
        userName,
        userPhotoUrl,
        rating,
        text,
        createdAt,
      ];
}
