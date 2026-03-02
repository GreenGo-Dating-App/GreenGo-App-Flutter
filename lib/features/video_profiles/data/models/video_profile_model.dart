import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/video_profile.dart';

/// Data model for VideoProfile with Firestore serialization support.
class VideoProfileModel extends VideoProfile {
  const VideoProfileModel({
    required super.id,
    required super.userId,
    required super.videoUrl,
    super.thumbnailUrl,
    required super.durationSeconds,
    super.prompt,
    required super.createdAt,
    super.updatedAt,
    super.viewCount,
    super.isActive,
  });

  /// Create a [VideoProfileModel] from a Firestore document snapshot.
  factory VideoProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VideoProfileModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      videoUrl: data['videoUrl'] as String? ?? '',
      thumbnailUrl: data['thumbnailUrl'] as String?,
      durationSeconds: data['durationSeconds'] as int? ?? 0,
      prompt: data['prompt'] as String?,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      viewCount: data['viewCount'] as int? ?? 0,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  /// Create a [VideoProfileModel] from a JSON map.
  factory VideoProfileModel.fromJson(Map<String, dynamic> json) {
    return VideoProfileModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      videoUrl: json['videoUrl'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String?,
      durationSeconds: json['durationSeconds'] as int? ?? 0,
      prompt: json['prompt'] as String?,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : json['createdAt'] is String
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : json['updatedAt'] is String
              ? DateTime.parse(json['updatedAt'] as String)
              : null,
      viewCount: json['viewCount'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// Create a [VideoProfileModel] from a domain [VideoProfile] entity.
  factory VideoProfileModel.fromEntity(VideoProfile entity) {
    return VideoProfileModel(
      id: entity.id,
      userId: entity.userId,
      videoUrl: entity.videoUrl,
      thumbnailUrl: entity.thumbnailUrl,
      durationSeconds: entity.durationSeconds,
      prompt: entity.prompt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      viewCount: entity.viewCount,
      isActive: entity.isActive,
    );
  }

  /// Convert this model to a JSON map suitable for Firestore storage.
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'durationSeconds': durationSeconds,
      'prompt': prompt,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'viewCount': viewCount,
      'isActive': isActive,
    };
  }
}
