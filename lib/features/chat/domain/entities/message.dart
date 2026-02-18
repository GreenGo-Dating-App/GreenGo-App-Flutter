import 'package:equatable/equatable.dart';

/// Message Entity
///
/// Represents a chat message between two users with reactions and status
class Message extends Equatable {
  final String messageId;
  final String matchId;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String content;
  final MessageType type;
  final DateTime sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final MessageStatus status;
  final Map<String, String>? reactions; // userId -> emoji
  final Map<String, dynamic>? metadata;
  final String? translatedContent;
  final String? detectedLanguage;
  final bool isScheduled;
  final DateTime? scheduledFor;

  const Message({
    required this.messageId,
    required this.matchId,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.type,
    required this.sentAt,
    this.deliveredAt,
    this.readAt,
    this.status = MessageStatus.sent,
    this.reactions,
    this.metadata,
    this.translatedContent,
    this.detectedLanguage,
    this.isScheduled = false,
    this.scheduledFor,
  });

  /// Check if message has been read
  bool get isRead => readAt != null;

  /// Check if message has been delivered
  bool get isDelivered => deliveredAt != null;

  /// Check if current user is sender
  bool isSentBy(String userId) => senderId == userId;

  /// Get reaction for specific user
  String? getReaction(String userId) => reactions?[userId];

  /// Check if message has reactions
  bool get hasReactions => reactions != null && reactions!.isNotEmpty;

  /// Get reaction count
  int get reactionCount => reactions?.length ?? 0;

  /// Check if message is translated
  bool get isTranslated => translatedContent != null;

  /// Get time since message sent
  String get timeSinceText {
    final now = DateTime.now();
    final difference = now.difference(sentAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${sentAt.month}/${sentAt.day}/${sentAt.year}';
    }
  }

  /// Format time for display (e.g., "10:30 AM")
  String get timeText {
    final hour = sentAt.hour > 12 ? sentAt.hour - 12 : sentAt.hour;
    final minute = sentAt.minute.toString().padLeft(2, '0');
    final period = sentAt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  /// Copy with updated fields
  Message copyWith({
    String? messageId,
    String? matchId,
    String? conversationId,
    String? senderId,
    String? receiverId,
    String? content,
    MessageType? type,
    DateTime? sentAt,
    DateTime? deliveredAt,
    DateTime? readAt,
    MessageStatus? status,
    Map<String, String>? reactions,
    Map<String, dynamic>? metadata,
    String? translatedContent,
    String? detectedLanguage,
    bool? isScheduled,
    DateTime? scheduledFor,
  }) {
    return Message(
      messageId: messageId ?? this.messageId,
      matchId: matchId ?? this.matchId,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      type: type ?? this.type,
      sentAt: sentAt ?? this.sentAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      status: status ?? this.status,
      reactions: reactions ?? this.reactions,
      metadata: metadata ?? this.metadata,
      translatedContent: translatedContent ?? this.translatedContent,
      detectedLanguage: detectedLanguage ?? this.detectedLanguage,
      isScheduled: isScheduled ?? this.isScheduled,
      scheduledFor: scheduledFor ?? this.scheduledFor,
    );
  }

  @override
  List<Object?> get props => [
        messageId,
        matchId,
        conversationId,
        senderId,
        receiverId,
        content,
        type,
        sentAt,
        deliveredAt,
        readAt,
        status,
        reactions,
        metadata,
        translatedContent,
        detectedLanguage,
        isScheduled,
        scheduledFor,
      ];
}

/// Message Status
enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

/// Message Types
enum MessageType {
  text,
  image,
  video,
  gif,
  voiceNote,
  sticker,
  system,
  albumShare,
  albumRevoke,
}

/// Extension for MessageStatus
extension MessageStatusExtension on MessageStatus {
  String get value {
    switch (this) {
      case MessageStatus.sending:
        return 'sending';
      case MessageStatus.sent:
        return 'sent';
      case MessageStatus.delivered:
        return 'delivered';
      case MessageStatus.read:
        return 'read';
      case MessageStatus.failed:
        return 'failed';
    }
  }

  static MessageStatus fromString(String value) {
    switch (value) {
      case 'sending':
        return MessageStatus.sending;
      case 'sent':
        return MessageStatus.sent;
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      case 'failed':
        return MessageStatus.failed;
      default:
        return MessageStatus.sent;
    }
  }
}

/// Extension for MessageType
extension MessageTypeExtension on MessageType {
  String get value {
    switch (this) {
      case MessageType.text:
        return 'text';
      case MessageType.image:
        return 'image';
      case MessageType.video:
        return 'video';
      case MessageType.gif:
        return 'gif';
      case MessageType.voiceNote:
        return 'voice_note';
      case MessageType.sticker:
        return 'sticker';
      case MessageType.system:
        return 'system';
      case MessageType.albumShare:
        return 'album_share';
      case MessageType.albumRevoke:
        return 'album_revoke';
    }
  }

  static MessageType fromString(String value) {
    switch (value) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'video':
        return MessageType.video;
      case 'gif':
        return MessageType.gif;
      case 'voice_note':
        return MessageType.voiceNote;
      case 'sticker':
        return MessageType.sticker;
      case 'system':
        return MessageType.system;
      case 'album_share':
        return MessageType.albumShare;
      case 'album_revoke':
        return MessageType.albumRevoke;
      default:
        return MessageType.text;
    }
  }
}
