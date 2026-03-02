import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/community_member.dart';

/// Community Member Model
///
/// Data layer model for CommunityMember entity with Firestore serialization
class CommunityMemberModel extends CommunityMember {
  const CommunityMemberModel({
    required super.userId,
    required super.displayName,
    super.photoUrl,
    super.role,
    required super.joinedAt,
    super.languages,
    super.isLocalGuide,
  });

  /// Create from CommunityMember entity
  factory CommunityMemberModel.fromEntity(CommunityMember member) {
    return CommunityMemberModel(
      userId: member.userId,
      displayName: member.displayName,
      photoUrl: member.photoUrl,
      role: member.role,
      joinedAt: member.joinedAt,
      languages: member.languages,
      isLocalGuide: member.isLocalGuide,
    );
  }

  /// Create from Firestore document
  factory CommunityMemberModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return CommunityMemberModel(
      userId: doc.id,
      displayName: data['displayName'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      role: CommunityRoleExtension.fromString(
        data['role'] as String? ?? 'member',
      ),
      joinedAt: data['joinedAt'] != null
          ? (data['joinedAt'] as Timestamp).toDate()
          : DateTime.now(),
      languages: data['languages'] != null
          ? List<String>.from(data['languages'] as List)
          : const [],
      isLocalGuide: data['isLocalGuide'] as bool? ?? false,
    );
  }

  /// Create from JSON map
  factory CommunityMemberModel.fromJson(Map<String, dynamic> json) {
    return CommunityMemberModel(
      userId: json['userId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      role: CommunityRoleExtension.fromString(
        json['role'] as String? ?? 'member',
      ),
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'] as String)
          : DateTime.now(),
      languages: json['languages'] != null
          ? List<String>.from(json['languages'] as List)
          : const [],
      isLocalGuide: json['isLocalGuide'] as bool? ?? false,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role.value,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'languages': languages,
      'isLocalGuide': isLocalGuide,
    };
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role.value,
      'joinedAt': joinedAt.toIso8601String(),
      'languages': languages,
      'isLocalGuide': isLocalGuide,
    };
  }

  /// Convert to CommunityMember entity
  CommunityMember toEntity() {
    return CommunityMember(
      userId: userId,
      displayName: displayName,
      photoUrl: photoUrl,
      role: role,
      joinedAt: joinedAt,
      languages: languages,
      isLocalGuide: isLocalGuide,
    );
  }
}
