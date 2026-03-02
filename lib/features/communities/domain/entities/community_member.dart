import 'package:equatable/equatable.dart';

/// Community Member Entity
///
/// Represents a user's membership in a community
class CommunityMember extends Equatable {
  final String userId;
  final String displayName;
  final String? photoUrl;
  final CommunityRole role;
  final DateTime joinedAt;
  final List<String> languages;
  final bool isLocalGuide;

  const CommunityMember({
    required this.userId,
    required this.displayName,
    this.photoUrl,
    this.role = CommunityRole.member,
    required this.joinedAt,
    this.languages = const [],
    this.isLocalGuide = false,
  });

  /// Check if member is an admin or owner
  bool get isAdminOrOwner =>
      role == CommunityRole.admin || role == CommunityRole.owner;

  /// Check if member is the owner
  bool get isOwner => role == CommunityRole.owner;

  /// Copy with updated fields
  CommunityMember copyWith({
    String? userId,
    String? displayName,
    String? photoUrl,
    CommunityRole? role,
    DateTime? joinedAt,
    List<String>? languages,
    bool? isLocalGuide,
  }) {
    return CommunityMember(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      languages: languages ?? this.languages,
      isLocalGuide: isLocalGuide ?? this.isLocalGuide,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        displayName,
        photoUrl,
        role,
        joinedAt,
        languages,
        isLocalGuide,
      ];
}

/// Community Role
enum CommunityRole {
  owner('Owner'),
  admin('Admin'),
  member('Member');

  final String displayName;
  const CommunityRole(this.displayName);
}

/// Extension for CommunityRole serialization
extension CommunityRoleExtension on CommunityRole {
  String get value {
    switch (this) {
      case CommunityRole.owner:
        return 'owner';
      case CommunityRole.admin:
        return 'admin';
      case CommunityRole.member:
        return 'member';
    }
  }

  static CommunityRole fromString(String value) {
    switch (value) {
      case 'owner':
        return CommunityRole.owner;
      case 'admin':
        return CommunityRole.admin;
      case 'member':
        return CommunityRole.member;
      default:
        return CommunityRole.member;
    }
  }
}
