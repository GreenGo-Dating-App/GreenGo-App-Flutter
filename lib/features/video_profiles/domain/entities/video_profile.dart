import 'package:equatable/equatable.dart';

/// Video Profile Entity
/// Short video introduction for user profiles
class VideoProfile extends Equatable {
  final String id;
  final String userId;
  final String videoUrl;
  final String? thumbnailUrl;
  final int durationSeconds;
  final String? prompt;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int viewCount;
  final bool isActive;

  const VideoProfile({
    required this.id,
    required this.userId,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.durationSeconds,
    this.prompt,
    required this.createdAt,
    this.updatedAt,
    this.viewCount = 0,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        videoUrl,
        thumbnailUrl,
        durationSeconds,
        prompt,
        createdAt,
        updatedAt,
        viewCount,
        isActive,
      ];

  VideoProfile copyWith({
    String? id,
    String? userId,
    String? videoUrl,
    String? thumbnailUrl,
    int? durationSeconds,
    String? prompt,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? viewCount,
    bool? isActive,
  }) {
    return VideoProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      prompt: prompt ?? this.prompt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      viewCount: viewCount ?? this.viewCount,
      isActive: isActive ?? this.isActive,
    );
  }
}
