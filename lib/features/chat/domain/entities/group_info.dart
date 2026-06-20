import 'package:equatable/equatable.dart';

/// Role of a member within a group conversation.
enum GroupRole {
  admin, // can rename group, add/remove members, change roles, delete messages
  member, // can read and send messages
}

/// Extension for [GroupRole] serialization.
extension GroupRoleExtension on GroupRole {
  String get value => name;

  static GroupRole fromString(String? value) {
    return GroupRole.values.firstWhere(
      (r) => r.name == value,
      orElse: () => GroupRole.member,
    );
  }
}

/// Metadata describing a group conversation (only set when the parent
/// [Conversation] is a group). Kept separate from the 1:1 conversation fields
/// so the existing match/support/super-like flows are unaffected.
class GroupInfo extends Equatable {
  const GroupInfo({
    required this.name,
    required this.createdBy,
    this.photoUrl,
    this.description,
    this.language,
  });

  /// Display name of the group.
  final String name;

  /// User id of the creator (defaults to first admin).
  final String createdBy;

  /// Optional group avatar (Firebase Storage URL).
  final String? photoUrl;

  /// Optional group description / topic.
  final String? description;

  /// Optional primary language tag for the group (e.g. "it", "pt_BR").
  /// Used by the cross-cultural translation features.
  final String? language;

  GroupInfo copyWith({
    String? name,
    String? createdBy,
    String? photoUrl,
    String? description,
    String? language,
  }) {
    return GroupInfo(
      name: name ?? this.name,
      createdBy: createdBy ?? this.createdBy,
      photoUrl: photoUrl ?? this.photoUrl,
      description: description ?? this.description,
      language: language ?? this.language,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'createdBy': createdBy,
      'photoUrl': photoUrl,
      'description': description,
      'language': language,
    };
  }

  factory GroupInfo.fromMap(Map<String, dynamic> map) {
    return GroupInfo(
      name: map['name'] as String? ?? '',
      createdBy: map['createdBy'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      description: map['description'] as String?,
      language: map['language'] as String?,
    );
  }

  @override
  List<Object?> get props => [name, createdBy, photoUrl, description, language];
}

/// A single member of a group conversation. Stored in the
/// `conversations/{id}/members/{uid}` subcollection for scalability.
class GroupMember extends Equatable {
  const GroupMember({
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.lastReadAt,
    this.notificationsEnabled = true,
    this.leftAt,
  });

  final String userId;
  final GroupRole role;
  final DateTime joinedAt;

  /// Last time this member opened the conversation — used to compute unread
  /// counts without writing a per-message readBy entry for every member.
  final DateTime? lastReadAt;

  final bool notificationsEnabled;

  /// Set when the member leaves; null while active.
  final DateTime? leftAt;

  bool get isActive => leftAt == null;
  bool get isAdmin => role == GroupRole.admin;

  GroupMember copyWith({
    String? userId,
    GroupRole? role,
    DateTime? joinedAt,
    DateTime? lastReadAt,
    bool? notificationsEnabled,
    DateTime? leftAt,
    bool clearLeftAt = false,
  }) {
    return GroupMember(
      userId: userId ?? this.userId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      leftAt: clearLeftAt ? null : (leftAt ?? this.leftAt),
    );
  }

  @override
  List<Object?> get props =>
      [userId, role, joinedAt, lastReadAt, notificationsEnabled, leftAt];
}
