import 'package:greengo_chat/features/chat/data/models/conversation_model.dart';
import 'package:greengo_chat/features/chat/domain/entities/conversation.dart';
import 'package:greengo_chat/features/chat/domain/entities/group_info.dart';
import 'package:greengo_chat/features/chat/domain/entities/message.dart';

/// Chat/messaging fixtures — build VALID [Conversation]/[Message] objects with
/// the real constructors so tests exercise production shapes. Do NOT edit
/// test/support/mock_data.dart; this file owns chat-specific fixtures.
class ChatFixtures {
  static final DateTime _t = DateTime(2026, 7, 15, 12);

  /// A plain text [Message] with sensible defaults; override anything.
  static Message message({
    String messageId = 'msg_1',
    String matchId = 'match_1',
    String conversationId = 'conv_1',
    String senderId = 'user_a',
    String receiverId = 'user_b',
    String content = 'Hello there',
    MessageType type = MessageType.text,
    DateTime? sentAt,
    DateTime? readAt,
    DateTime? deliveredAt,
    MessageStatus status = MessageStatus.sent,
    Map<String, DateTime>? readBy,
  }) {
    return Message(
      messageId: messageId,
      matchId: matchId,
      conversationId: conversationId,
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      type: type,
      sentAt: sentAt ?? _t,
      readAt: readAt,
      deliveredAt: deliveredAt,
      status: status,
      readBy: readBy,
    );
  }

  /// A 1:1 [ConversationModel] between [userId1] and [userId2].
  static ConversationModel conversation({
    String conversationId = 'conv_1',
    String matchId = 'match_1',
    String userId1 = 'user_a',
    String userId2 = 'user_b',
    Message? lastMessage,
    DateTime? lastMessageAt,
    int unreadCount = 0,
    ConversationType conversationType = ConversationType.match,
    bool businessInquiry = false,
    ChatTheme theme = ChatTheme.gold,
    bool isPinned = false,
    bool isMuted = false,
    bool isArchived = false,
    Map<String, bool>? favorites,
    bool isDeleted = false,
    Map<String, dynamic>? deletedFor,
    List<String>? visibleTo,
    String? superLikeSenderId,
  }) {
    return ConversationModel(
      conversationId: conversationId,
      matchId: matchId,
      userId1: userId1,
      userId2: userId2,
      createdAt: _t,
      lastMessage: lastMessage,
      lastMessageAt: lastMessageAt,
      unreadCount: unreadCount,
      conversationType: conversationType,
      businessInquiry: businessInquiry,
      theme: theme,
      isPinned: isPinned,
      isMuted: isMuted,
      isArchived: isArchived,
      favorites: favorites,
      isDeleted: isDeleted,
      deletedFor: deletedFor,
      visibleTo: visibleTo,
      superLikeSenderId: superLikeSenderId,
    );
  }

  /// A group [ConversationModel] (separate `groups` collection semantics).
  static ConversationModel groupConversation({
    String conversationId = 'group_1',
    List<String> participants = const ['user_a', 'user_b', 'user_c'],
    GroupInfo? groupInfo,
    Map<String, String>? roles,
    Map<String, int>? unreadCounts,
    Message? lastMessage,
    DateTime? lastMessageAt,
  }) {
    return ConversationModel(
      conversationId: conversationId,
      matchId: '',
      userId1: participants.isNotEmpty ? participants.first : '',
      userId2: participants.length > 1 ? participants[1] : '',
      createdAt: _t,
      isGroup: true,
      conversationType: ConversationType.group,
      participants: participants,
      groupInfo: groupInfo ??
          const GroupInfo(name: 'Culture Circle', createdBy: 'user_a'),
      roles: roles,
      unreadCounts: unreadCounts,
      lastMessage: lastMessage,
      lastMessageAt: lastMessageAt,
    );
  }
}
