import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/vibe_tag.dart';

/// Vibe Tag Model for Firestore serialization
class VibeTagModel extends VibeTag {
  const VibeTagModel({
    required super.id,
    required super.name,
    required super.emoji,
    required super.category,
    super.isActive = true,
    super.isPremium = false,
    super.sortOrder = 0,
  });

  /// Create from Firestore document
  factory VibeTagModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return VibeTagModel(
      id: doc.id,
      name: data['name'] as String,
      emoji: data['emoji'] as String,
      category: data['category'] as String,
      isActive: data['isActive'] as bool? ?? true,
      isPremium: data['isPremium'] as bool? ?? false,
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  /// Create from map
  factory VibeTagModel.fromMap(Map<String, dynamic> map, String id) {
    return VibeTagModel(
      id: id,
      name: map['name'] as String,
      emoji: map['emoji'] as String,
      category: map['category'] as String,
      isActive: map['isActive'] as bool? ?? true,
      isPremium: map['isPremium'] as bool? ?? false,
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'emoji': emoji,
      'category': category,
      'isActive': isActive,
      'isPremium': isPremium,
      'sortOrder': sortOrder,
    };
  }

  /// Create from entity
  factory VibeTagModel.fromEntity(VibeTag entity) {
    return VibeTagModel(
      id: entity.id,
      name: entity.name,
      emoji: entity.emoji,
      category: entity.category,
      isActive: entity.isActive,
      isPremium: entity.isPremium,
      sortOrder: entity.sortOrder,
    );
  }
}

/// User Vibe Tags Model for Firestore serialization
class UserVibeTagsModel extends UserVibeTags {
  const UserVibeTagsModel({
    required super.userId,
    required super.selectedTagIds,
    super.temporaryTagId,
    super.temporaryTagExpiresAt,
    required super.updatedAt,
  });

  /// Create from Firestore document
  factory UserVibeTagsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserVibeTagsModel(
      userId: doc.id,
      selectedTagIds: List<String>.from(data['selectedTagIds'] ?? []),
      temporaryTagId: data['temporaryTagId'] as String?,
      temporaryTagExpiresAt: data['temporaryTagExpiresAt'] != null
          ? (data['temporaryTagExpiresAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'selectedTagIds': selectedTagIds,
      'temporaryTagId': temporaryTagId,
      'temporaryTagExpiresAt': temporaryTagExpiresAt != null
          ? Timestamp.fromDate(temporaryTagExpiresAt!)
          : null,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create from entity
  factory UserVibeTagsModel.fromEntity(UserVibeTags entity) {
    return UserVibeTagsModel(
      userId: entity.userId,
      selectedTagIds: entity.selectedTagIds,
      temporaryTagId: entity.temporaryTagId,
      temporaryTagExpiresAt: entity.temporaryTagExpiresAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Create empty for user
  factory UserVibeTagsModel.empty(String userId) {
    return UserVibeTagsModel(
      userId: userId,
      selectedTagIds: [],
      updatedAt: DateTime.now(),
    );
  }
}
