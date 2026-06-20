import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/group_info.dart';
import '../../domain/entities/message.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

/// Group Chat Remote Data Source
///
/// Production, scale-oriented Firestore access for group conversations
/// ("Culture Circles"). Fully isolated from the legacy 1:1 `conversations`
/// collection — it never reads or writes that collection, its rules, or its
/// Cloud Functions.
///
/// Scale design:
///  * A message body is written **exactly once** to `groups/{id}/messages`
///    (pull model — no per-recipient copies).
///  * Each user's inbox is a private, indexed subtree
///    `user_group_inbox/{uid}/threads/{groupId}` maintained by a Cloud Function
///    fan-out, so listing groups is a single paginated query per user that
///    scales to millions of users regardless of group size.
///  * Per-member state (role, lastReadAt, mute) lives in
///    `groups/{id}/members/{uid}` to avoid contention on the group document.
///  * Server timestamps order messages authoritatively (no client clock skew).
abstract class GroupChatRemoteDataSource {
  Future<ConversationModel> createGroup({
    required String creatorId,
    required String name,
    required List<String> memberIds,
    String? photoUrl,
    String? description,
    String? language,
  });

  /// Per-user inbox list (scales to millions — reads only the caller's subtree).
  Stream<List<ConversationModel>> getUserGroupsStream(
    String userId, {
    int limit,
  });

  /// Latest messages for a group (newest first), paginated by [limit].
  Stream<List<MessageModel>> getGroupMessagesStream({
    required String groupId,
    int limit,
  });

  /// Fetch one older page for infinite scroll (keyset pagination).
  Future<List<MessageModel>> getGroupMessagesPage({
    required String groupId,
    required DateTime before,
    int limit,
  });

  /// Single-write message send. Group doc + every member inbox are updated by
  /// the fan-out Cloud Function, not the client.
  Future<MessageModel> sendGroupMessage({
    required String groupId,
    required String senderId,
    required String content,
    required MessageType type,
    Map<String, dynamic>? metadata,
    String? detectedLanguage,
  });

  Future<void> markGroupRead({
    required String groupId,
    required String userId,
  });

  Stream<List<GroupMember>> getGroupMembersStream(String groupId);

  Future<void> addMembers({
    required String groupId,
    required String actorId,
    required List<String> memberIds,
  });

  Future<void> removeMember({
    required String groupId,
    required String actorId,
    required String memberId,
  });

  Future<void> leaveGroup({
    required String groupId,
    required String userId,
  });

  Future<void> updateGroupInfo({
    required String groupId,
    String? name,
    String? photoUrl,
    String? description,
    String? language,
  });

  Future<void> changeMemberRole({
    required String groupId,
    required String actorId,
    required String memberId,
    required GroupRole role,
  });

  Future<void> addReaction({
    required String groupId,
    required String messageId,
    required String userId,
    required String emoji,
  });

  Future<void> removeReaction({
    required String groupId,
    required String messageId,
    required String userId,
  });

  Future<void> deleteGroupMessageForEveryone({
    required String groupId,
    required String messageId,
    required String actorId,
  });
}

/// Implementation
class GroupChatRemoteDataSourceImpl implements GroupChatRemoteDataSource {
  GroupChatRemoteDataSourceImpl({required this.firestore});

  final FirebaseFirestore firestore;

  // ---- Collection names (all NEW, isolated from legacy chat) ----
  static const String groupsCol = 'groups';
  static const String messagesSub = 'messages';
  static const String membersSub = 'members';
  static const String inboxCol = 'user_group_inbox';
  static const String threadsSub = 'threads';

  /// Hard cap on members per group (creator + up to 9 others).
  static const int maxGroupMembers = 10;

  /// Default page size for messages.
  static const int defaultMessageLimit = 30;

  /// Default page size for the inbox list.
  static const int defaultInboxLimit = 50;

  CollectionReference<Map<String, dynamic>> get _groups =>
      firestore.collection(groupsCol);

  DocumentReference<Map<String, dynamic>> _inboxThread(
          String uid, String groupId) =>
      firestore
          .collection(inboxCol)
          .doc(uid)
          .collection(threadsSub)
          .doc(groupId);

  @override
  Future<ConversationModel> createGroup({
    required String creatorId,
    required String name,
    required List<String> memberIds,
    String? photoUrl,
    String? description,
    String? language,
  }) async {
    final members = <String>{creatorId, ...memberIds}.toList();
    if (members.length < 2) {
      throw Exception('A group needs at least 2 members.');
    }
    if (members.length > maxGroupMembers) {
      throw Exception('Groups are limited to $maxGroupMembers members.');
    }

    final groupRef = _groups.doc();
    final now = FieldValue.serverTimestamp();
    final groupInfo = GroupInfo(
      name: name.trim(),
      createdBy: creatorId,
      photoUrl: photoUrl,
      description: description,
      language: language,
    );
    final roles = <String, String>{
      for (final m in members)
        m: (m == creatorId ? GroupRole.admin.name : GroupRole.member.name),
    };

    // SINGLE client write: only the group document. The `onGroupCreated` Cloud
    // Function (Admin SDK) seeds every member's `members/{uid}` doc and private
    // `user_group_inbox` thread, and posts the "created" system message. This
    // keeps the client free of cross-user writes (which security rules forbid)
    // and keeps creation O(1) on the client regardless of group size.
    await groupRef.set({
      'conversationType': ConversationType.group.name,
      'isGroup': true,
      'participants': members,
      'groupInfo': groupInfo.toMap(),
      'roles': roles,
      'memberCount': members.length,
      'createdBy': creatorId,
      'createdAt': now,
      'lastMessageAt': now,
      'theme': ChatTheme.gold.name,
      'isDeleted': false,
    });

    return ConversationModel(
      conversationId: groupRef.id,
      matchId: '',
      userId1: creatorId,
      userId2: '',
      createdAt: DateTime.now(),
      conversationType: ConversationType.group,
      isGroup: true,
      participants: members,
      groupInfo: groupInfo,
      roles: roles,
      unreadCounts: {for (final m in members) m: 0},
    );
  }

  @override
  Stream<List<ConversationModel>> getUserGroupsStream(
    String userId, {
    int limit = defaultInboxLimit,
  }) {
    return firestore
        .collection(inboxCol)
        .doc(userId)
        .collection(threadsSub)
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => _inboxToConversation(userId, d)).toList());
  }

  /// Map a per-user inbox thread summary to a lightweight [ConversationModel]
  /// for the conversation list (no message-collection reads required).
  ConversationModel _inboxToConversation(
    String userId,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final groupId = data['groupId'] as String? ?? doc.id;
    final lastAt = (data['lastMessageAt'] as Timestamp?)?.toDate();
    final unread = (data['unreadCount'] as num?)?.toInt() ?? 0;

    final preview = Message(
      messageId: '',
      matchId: groupId,
      conversationId: groupId,
      senderId: data['lastSenderId'] as String? ?? '',
      receiverId: '',
      content: data['lastMessagePreview'] as String? ?? '',
      type: MessageType.text,
      sentAt: lastAt ?? DateTime.now(),
    );

    return ConversationModel(
      conversationId: groupId,
      matchId: '',
      userId1: userId,
      userId2: '',
      createdAt: lastAt ?? DateTime.now(),
      conversationType: ConversationType.group,
      isGroup: true,
      groupInfo: GroupInfo(
        name: data['name'] as String? ?? 'Group',
        createdBy: '',
        photoUrl: data['photoUrl'] as String?,
      ),
      lastMessage: preview,
      lastMessageAt: lastAt,
      unreadCounts: {userId: unread},
      isPinned: data['pinned'] as bool? ?? false,
      isMuted: data['muted'] as bool? ?? false,
    );
  }

  @override
  Stream<List<MessageModel>> getGroupMessagesStream({
    required String groupId,
    int limit = defaultMessageLimit,
  }) {
    return _groups
        .doc(groupId)
        .collection(messagesSub)
        .orderBy('sentAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(MessageModel.fromFirestore).toList());
  }

  @override
  Future<List<MessageModel>> getGroupMessagesPage({
    required String groupId,
    required DateTime before,
    int limit = defaultMessageLimit,
  }) async {
    final snap = await _groups
        .doc(groupId)
        .collection(messagesSub)
        .orderBy('sentAt', descending: true)
        .startAfter([Timestamp.fromDate(before)])
        .limit(limit)
        .get();
    return snap.docs.map(MessageModel.fromFirestore).toList();
  }

  @override
  Future<MessageModel> sendGroupMessage({
    required String groupId,
    required String senderId,
    required String content,
    required MessageType type,
    Map<String, dynamic>? metadata,
    String? detectedLanguage,
  }) async {
    final msgRef = _groups.doc(groupId).collection(messagesSub).doc();

    // SINGLE write. The fan-out Cloud Function updates the group doc's
    // lastMessage/lastMessageAt and every member's inbox summary + unread,
    // and dispatches FCM — keeping the client write path O(1).
    await msgRef.set({
      'senderId': senderId,
      'receiverId': '',
      'matchId': groupId,
      'content': content,
      'type': type.value,
      'status': MessageStatus.sent.value,
      'sentAt': FieldValue.serverTimestamp(),
      if (metadata != null) 'metadata': metadata,
      if (detectedLanguage != null) 'detectedLanguage': detectedLanguage,
    });

    return MessageModel(
      messageId: msgRef.id,
      matchId: groupId,
      conversationId: groupId,
      senderId: senderId,
      receiverId: '',
      content: content,
      type: type,
      sentAt: DateTime.now(),
      metadata: metadata,
      detectedLanguage: detectedLanguage,
    );
  }

  @override
  Future<void> markGroupRead({
    required String groupId,
    required String userId,
  }) async {
    final batch = firestore.batch();
    batch.set(
      _groups.doc(groupId).collection(membersSub).doc(userId),
      {'lastReadAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
    // Reset unread only — do NOT bump updatedAt (would reorder the inbox).
    batch.set(
      _inboxThread(userId, groupId),
      {'unreadCount': 0},
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  @override
  Stream<List<GroupMember>> getGroupMembersStream(String groupId) {
    return _groups
        .doc(groupId)
        .collection(membersSub)
        .snapshots()
        .map((snap) => snap.docs.map(_memberFromDoc).toList());
  }

  GroupMember _memberFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return GroupMember(
      userId: data['userId'] as String? ?? doc.id,
      role: GroupRoleExtension.fromString(data['role'] as String?),
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastReadAt: (data['lastReadAt'] as Timestamp?)?.toDate(),
      notificationsEnabled: data['notificationsEnabled'] as bool? ?? true,
      leftAt: (data['leftAt'] as Timestamp?)?.toDate(),
    );
  }

  @override
  Future<void> addMembers({
    required String groupId,
    required String actorId,
    required List<String> memberIds,
  }) async {
    final groupRef = _groups.doc(groupId);
    final snap = await groupRef.get();
    if (!snap.exists) throw Exception('Group not found');
    final data = snap.data()!;
    _requireAdmin(data, actorId);

    final current = List<String>.from(data['participants'] as List? ?? []);
    final toAdd = memberIds.where((m) => !current.contains(m)).toList();
    if (toAdd.isEmpty) return;
    if (current.length + toAdd.length > maxGroupMembers) {
      throw Exception('Groups are limited to $maxGroupMembers members.');
    }

    // Update only the group doc. The `onGroupParticipantsChanged` Cloud Function
    // detects the added ids and seeds their member docs + inbox threads and
    // posts the system message (cross-user writes are server-side only).
    await groupRef.update({
      'participants': FieldValue.arrayUnion(toAdd),
      'memberCount': FieldValue.increment(toAdd.length),
      for (final m in toAdd) 'roles.$m': GroupRole.member.name,
    });
  }

  @override
  Future<void> removeMember({
    required String groupId,
    required String actorId,
    required String memberId,
  }) async {
    final groupRef = _groups.doc(groupId);
    final snap = await groupRef.get();
    if (!snap.exists) throw Exception('Group not found');
    _requireAdmin(snap.data()!, actorId);
    await _detachMember(groupRef, memberId, actorId, 'removed a member');
  }

  @override
  Future<void> leaveGroup({
    required String groupId,
    required String userId,
  }) async {
    final groupRef = _groups.doc(groupId);
    await _detachMember(groupRef, userId, userId, 'left the group');
  }

  Future<void> _detachMember(
    DocumentReference<Map<String, dynamic>> groupRef,
    String memberId,
    String actorId,
    String systemText,
  ) async {
    // Update only the group doc. The `onGroupParticipantsChanged` Cloud Function
    // marks the member's doc leftAt, deletes their inbox thread, and posts the
    // system message (cross-user writes are server-side only).
    await groupRef.update({
      'participants': FieldValue.arrayRemove([memberId]),
      'memberCount': FieldValue.increment(-1),
      'roles.$memberId': FieldValue.delete(),
    });
  }

  @override
  Future<void> updateGroupInfo({
    required String groupId,
    String? name,
    String? photoUrl,
    String? description,
    String? language,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['groupInfo.name'] = name.trim();
    if (photoUrl != null) updates['groupInfo.photoUrl'] = photoUrl;
    if (description != null) updates['groupInfo.description'] = description;
    if (language != null) updates['groupInfo.language'] = language;
    if (updates.isEmpty) return;
    await _groups.doc(groupId).update(updates);
  }

  @override
  Future<void> changeMemberRole({
    required String groupId,
    required String actorId,
    required String memberId,
    required GroupRole role,
  }) async {
    final groupRef = _groups.doc(groupId);
    final snap = await groupRef.get();
    if (!snap.exists) throw Exception('Group not found');
    _requireAdmin(snap.data()!, actorId);
    // `group.roles` is the authoritative role map; the per-member doc role is a
    // denormalized copy synced by the Cloud Function. Update only the group doc
    // here to avoid a cross-user write to another member's doc.
    await groupRef.update({'roles.$memberId': role.name});
  }

  @override
  Future<void> addReaction({
    required String groupId,
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    await _groups
        .doc(groupId)
        .collection(messagesSub)
        .doc(messageId)
        .update({'reactions.$userId': emoji});
  }

  @override
  Future<void> removeReaction({
    required String groupId,
    required String messageId,
    required String userId,
  }) async {
    await _groups
        .doc(groupId)
        .collection(messagesSub)
        .doc(messageId)
        .update({'reactions.$userId': FieldValue.delete()});
  }

  @override
  Future<void> deleteGroupMessageForEveryone({
    required String groupId,
    required String messageId,
    required String actorId,
  }) async {
    // Soft-delete so history stays consistent for everyone.
    await _groups.doc(groupId).collection(messagesSub).doc(messageId).update({
      'metadata.isDeletedForEveryone': true,
      'metadata.deletedBy': actorId,
      'content': '',
    });
  }

  // ---- helpers ----

  void _requireAdmin(Map<String, dynamic> groupData, String actorId) {
    final roles = Map<String, dynamic>.from(groupData['roles'] as Map? ?? {});
    if (roles[actorId] != GroupRole.admin.name) {
      throw Exception('Only group admins can perform this action.');
    }
  }
}
