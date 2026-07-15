import 'package:equatable/equatable.dart';

/// Community Member Entity
///
/// Represents a user's membership in a community
class CommunityMember extends Equatable {

  const CommunityMember({
    required this.userId,
    required this.displayName,
    required this.joinedAt, this.photoUrl,
    this.role = CommunityRole.member,
    this.languages = const [],
    this.isLocalGuide = false,
    this.isMuted = false,
    this.isBanned = false,
    this.canWriteTips = false,
    this.canWriteAnnouncements = false,
  });
  final String userId;
  final String displayName;
  final String? photoUrl;
  final CommunityRole role;
  final DateTime joinedAt;
  final List<String> languages;
  final bool isLocalGuide;

  /// Moderation: a muted member stays in the community but cannot post.
  final bool isMuted;

  /// Moderation: a banned member is hidden from the roster, blocked from
  /// posting, and blocked from rejoining.
  final bool isBanned;

  /// Permission: an admin-designated member (not an owner/admin) who may post
  /// Tips (language/cultural/city). Owners/admins can always post tips.
  final bool canWriteTips;

  /// Permission: an admin-designated member who may post Announcements.
  /// Owners/admins can always post announcements.
  final bool canWriteAnnouncements;

  /// Check if member is an admin or owner
  bool get isAdminOrOwner =>
      role == CommunityRole.admin || role == CommunityRole.owner;

  /// Check if member is the owner
  bool get isOwner => role == CommunityRole.owner;

  /// May this member post Tips? Owners/admins always may; others need the grant.
  bool get mayWriteTips => isAdminOrOwner || canWriteTips;

  /// May this member post Announcements?
  bool get mayWriteAnnouncements => isAdminOrOwner || canWriteAnnouncements;

  /// Copy with updated fields
  CommunityMember copyWith({
    String? userId,
    String? displayName,
    String? photoUrl,
    CommunityRole? role,
    DateTime? joinedAt,
    List<String>? languages,
    bool? isLocalGuide,
    bool? isMuted,
    bool? isBanned,
    bool? canWriteTips,
    bool? canWriteAnnouncements,
  }) {
    return CommunityMember(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      languages: languages ?? this.languages,
      isLocalGuide: isLocalGuide ?? this.isLocalGuide,
      isMuted: isMuted ?? this.isMuted,
      isBanned: isBanned ?? this.isBanned,
      canWriteTips: canWriteTips ?? this.canWriteTips,
      canWriteAnnouncements:
          canWriteAnnouncements ?? this.canWriteAnnouncements,
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
        isMuted,
        isBanned,
        canWriteTips,
        canWriteAnnouncements,
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
