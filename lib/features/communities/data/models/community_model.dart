import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/community.dart';

/// Community Model
///
/// Data layer model for Community entity with Firestore serialization
class CommunityModel extends Community {
  const CommunityModel({
    required super.id,
    required super.name,
    required super.description,
    required super.type,
    super.imageUrl,
    required super.createdByUserId,
    required super.createdByName,
    required super.createdAt,
    super.memberCount,
    super.languages,
    super.tags,
    super.isPublic,
    super.city,
    super.country,
    super.lastMessagePreview,
    super.lastActivityAt,
  });

  /// Create from Community entity
  factory CommunityModel.fromEntity(Community community) {
    return CommunityModel(
      id: community.id,
      name: community.name,
      description: community.description,
      type: community.type,
      imageUrl: community.imageUrl,
      createdByUserId: community.createdByUserId,
      createdByName: community.createdByName,
      createdAt: community.createdAt,
      memberCount: community.memberCount,
      languages: community.languages,
      tags: community.tags,
      isPublic: community.isPublic,
      city: community.city,
      country: community.country,
      lastMessagePreview: community.lastMessagePreview,
      lastActivityAt: community.lastActivityAt,
    );
  }

  /// Create from Firestore document
  factory CommunityModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return CommunityModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      type: CommunityTypeExtension.fromString(
        data['type'] as String? ?? 'general',
      ),
      imageUrl: data['imageUrl'] as String?,
      createdByUserId: data['createdByUserId'] as String? ?? '',
      createdByName: data['createdByName'] as String? ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      memberCount: data['memberCount'] as int? ?? 0,
      languages: data['languages'] != null
          ? List<String>.from(data['languages'] as List)
          : const [],
      tags: data['tags'] != null
          ? List<String>.from(data['tags'] as List)
          : const [],
      isPublic: data['isPublic'] as bool? ?? true,
      city: data['city'] as String?,
      country: data['country'] as String?,
      lastMessagePreview: data['lastMessagePreview'] as String?,
      lastActivityAt: data['lastActivityAt'] != null
          ? (data['lastActivityAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Create from JSON map
  factory CommunityModel.fromJson(Map<String, dynamic> json) {
    return CommunityModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      type: CommunityTypeExtension.fromString(
        json['type'] as String? ?? 'general',
      ),
      imageUrl: json['imageUrl'] as String?,
      createdByUserId: json['createdByUserId'] as String? ?? '',
      createdByName: json['createdByName'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      memberCount: json['memberCount'] as int? ?? 0,
      languages: json['languages'] != null
          ? List<String>.from(json['languages'] as List)
          : const [],
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : const [],
      isPublic: json['isPublic'] as bool? ?? true,
      city: json['city'] as String?,
      country: json['country'] as String?,
      lastMessagePreview: json['lastMessagePreview'] as String?,
      lastActivityAt: json['lastActivityAt'] != null
          ? DateTime.parse(json['lastActivityAt'] as String)
          : null,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'type': type.value,
      'imageUrl': imageUrl,
      'createdByUserId': createdByUserId,
      'createdByName': createdByName,
      'createdAt': Timestamp.fromDate(createdAt),
      'memberCount': memberCount,
      'languages': languages,
      'tags': tags,
      'isPublic': isPublic,
      'city': city,
      'country': country,
      'lastMessagePreview': lastMessagePreview,
      'lastActivityAt':
          lastActivityAt != null ? Timestamp.fromDate(lastActivityAt!) : null,
    };
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.value,
      'imageUrl': imageUrl,
      'createdByUserId': createdByUserId,
      'createdByName': createdByName,
      'createdAt': createdAt.toIso8601String(),
      'memberCount': memberCount,
      'languages': languages,
      'tags': tags,
      'isPublic': isPublic,
      'city': city,
      'country': country,
      'lastMessagePreview': lastMessagePreview,
      'lastActivityAt': lastActivityAt?.toIso8601String(),
    };
  }

  /// Convert to Community entity
  Community toEntity() {
    return Community(
      id: id,
      name: name,
      description: description,
      type: type,
      imageUrl: imageUrl,
      createdByUserId: createdByUserId,
      createdByName: createdByName,
      createdAt: createdAt,
      memberCount: memberCount,
      languages: languages,
      tags: tags,
      isPublic: isPublic,
      city: city,
      country: country,
      lastMessagePreview: lastMessagePreview,
      lastActivityAt: lastActivityAt,
    );
  }
}
