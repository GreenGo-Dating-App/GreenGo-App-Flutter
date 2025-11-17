import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import 'message_model.dart';

/// Conversation Model
///
/// Data layer model for Conversation entity with Firestore serialization
class ConversationModel extends Conversation {
  const ConversationModel({
    required super.conversationId,
    required super.matchId,
    required super.userId1,
    required super.userId2,
    super.lastMessage,
    super.lastMessageAt,
    super.unreadCount,
    super.isTyping,
    super.typingUserId,
    required super.createdAt,
    super.isPinned,
    super.pinnedAt,
    super.isMuted,
    super.mutedUntil,
    super.isArchived,
    super.archivedAt,
    super.theme,
    super.settings,
  });

  /// Create from Conversation entity
  factory ConversationModel.fromEntity(Conversation conversation) {
    return ConversationModel(
      conversationId: conversation.conversationId,
      matchId: conversation.matchId,
      userId1: conversation.userId1,
      userId2: conversation.userId2,
      lastMessage: conversation.lastMessage,
      lastMessageAt: conversation.lastMessageAt,
      unreadCount: conversation.unreadCount,
      isTyping: conversation.isTyping,
      typingUserId: conversation.typingUserId,
      createdAt: conversation.createdAt,
      isPinned: conversation.isPinned,
      pinnedAt: conversation.pinnedAt,
      isMuted: conversation.isMuted,
      mutedUntil: conversation.mutedUntil,
      isArchived: conversation.isArchived,
      archivedAt: conversation.archivedAt,
      theme: conversation.theme,
      settings: conversation.settings,
    );
  }

  /// Create from Firestore document
  factory ConversationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    Message? lastMessage;
    if (data['lastMessage'] != null) {
      final messageData = data['lastMessage'] as Map<String, dynamic>;
      lastMessage = Message(
        messageId: messageData['messageId'] as String? ?? '',
        matchId: data['matchId'] as String,
        conversationId: doc.id,
        senderId: messageData['senderId'] as String,
        receiverId: messageData['receiverId'] as String,
        content: messageData['content'] as String,
        type: MessageTypeExtension.fromString(
            messageData['type'] as String? ?? 'text'),
        sentAt: messageData['sentAt'] != null
            ? (messageData['sentAt'] as Timestamp).toDate()
            : DateTime.now(),
      );
    }

    return ConversationModel(
      conversationId: doc.id,
      matchId: data['matchId'] as String,
      userId1: data['userId1'] as String,
      userId2: data['userId2'] as String,
      lastMessage: lastMessage,
      lastMessageAt: data['lastMessageAt'] != null
          ? (data['lastMessageAt'] as Timestamp).toDate()
          : null,
      unreadCount: data['unreadCount'] as int? ?? 0,
      isTyping: data['isTyping'] as bool? ?? false,
      typingUserId: data['typingUserId'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isPinned: data['isPinned'] as bool? ?? false,
      pinnedAt: data['pinnedAt'] != null
          ? (data['pinnedAt'] as Timestamp).toDate()
          : null,
      isMuted: data['isMuted'] as bool? ?? false,
      mutedUntil: data['mutedUntil'] != null
          ? (data['mutedUntil'] as Timestamp).toDate()
          : null,
      isArchived: data['isArchived'] as bool? ?? false,
      archivedAt: data['archivedAt'] != null
          ? (data['archivedAt'] as Timestamp).toDate()
          : null,
      theme: ChatTheme.values.firstWhere(
        (t) => t.name == (data['theme'] as String? ?? 'gold'),
        orElse: () => ChatTheme.gold,
      ),
      settings: data['settings'] as Map<String, dynamic>?,
    );
  }

  /// Create from JSON
  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    Message? lastMessage;
    if (json['lastMessage'] != null) {
      lastMessage = MessageModel.fromJson(
          json['lastMessage'] as Map<String, dynamic>);
    }

    return ConversationModel(
      conversationId: json['conversationId'] as String,
      matchId: json['matchId'] as String,
      userId1: json['userId1'] as String,
      userId2: json['userId2'] as String,
      lastMessage: lastMessage,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'] as String)
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
      isTyping: json['isTyping'] as bool? ?? false,
      typingUserId: json['typingUserId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    final lastMessageData = lastMessage != null
        ? {
            'messageId': lastMessage!.messageId,
            'senderId': lastMessage!.senderId,
            'receiverId': lastMessage!.receiverId,
            'content': lastMessage!.content,
            'type': lastMessage!.type.value,
            'sentAt': Timestamp.fromDate(lastMessage!.sentAt),
          }
        : null;

    return {
      'matchId': matchId,
      'userId1': userId1,
      'userId2': userId2,
      'lastMessage': lastMessageData,
      'lastMessageAt':
          lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
      'unreadCount': unreadCount,
      'isTyping': isTyping,
      'typingUserId': typingUserId,
      'createdAt': Timestamp.fromDate(createdAt),
      'isPinned': isPinned,
      'pinnedAt': pinnedAt != null ? Timestamp.fromDate(pinnedAt!) : null,
      'isMuted': isMuted,
      'mutedUntil': mutedUntil != null ? Timestamp.fromDate(mutedUntil!) : null,
      'isArchived': isArchived,
      'archivedAt': archivedAt != null ? Timestamp.fromDate(archivedAt!) : null,
      'theme': theme.name,
      'settings': settings,
    };
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'conversationId': conversationId,
      'matchId': matchId,
      'userId1': userId1,
      'userId2': userId2,
      'lastMessage': lastMessage != null
          ? MessageModel.fromEntity(lastMessage!).toJson()
          : null,
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'unreadCount': unreadCount,
      'isTyping': isTyping,
      'typingUserId': typingUserId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Convert to Conversation entity
  Conversation toEntity() {
    return Conversation(
      conversationId: conversationId,
      matchId: matchId,
      userId1: userId1,
      userId2: userId2,
      lastMessage: lastMessage,
      lastMessageAt: lastMessageAt,
      unreadCount: unreadCount,
      isTyping: isTyping,
      typingUserId: typingUserId,
      createdAt: createdAt,
      isPinned: isPinned,
      pinnedAt: pinnedAt,
      isMuted: isMuted,
      mutedUntil: mutedUntil,
      isArchived: isArchived,
      archivedAt: archivedAt,
      theme: theme,
      settings: settings,
    );
  }
}
