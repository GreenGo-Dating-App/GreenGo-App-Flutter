import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/message.dart';

/// Message Model
///
/// Data layer model for Message entity with Firestore serialization
class MessageModel extends Message {
  const MessageModel({
    required super.messageId,
    required super.matchId,
    required super.conversationId,
    required super.senderId,
    required super.receiverId,
    required super.content,
    required super.type,
    required super.sentAt,
    super.deliveredAt,
    super.readAt,
    super.status,
    super.reactions,
    super.metadata,
    super.translatedContent,
    super.detectedLanguage,
    super.isScheduled,
    super.scheduledFor,
  });

  /// Create from Message entity
  factory MessageModel.fromEntity(Message message) {
    return MessageModel(
      messageId: message.messageId,
      matchId: message.matchId,
      conversationId: message.conversationId,
      senderId: message.senderId,
      receiverId: message.receiverId,
      content: message.content,
      type: message.type,
      sentAt: message.sentAt,
      deliveredAt: message.deliveredAt,
      readAt: message.readAt,
      status: message.status,
      reactions: message.reactions,
      metadata: message.metadata,
      translatedContent: message.translatedContent,
      detectedLanguage: message.detectedLanguage,
      isScheduled: message.isScheduled,
      scheduledFor: message.scheduledFor,
    );
  }

  /// Create from Firestore document
  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return MessageModel(
      messageId: doc.id,
      matchId: data['matchId'] as String? ?? '',
      conversationId: data['conversationId'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      receiverId: data['receiverId'] as String? ?? '',
      content: data['content'] as String? ?? '',
      type: MessageTypeExtension.fromString(data['type'] as String),
      sentAt: (data['sentAt'] as Timestamp).toDate(),
      deliveredAt: data['deliveredAt'] != null
          ? (data['deliveredAt'] as Timestamp).toDate()
          : null,
      readAt: data['readAt'] != null
          ? (data['readAt'] as Timestamp).toDate()
          : null,
      status: data['status'] != null
          ? MessageStatusExtension.fromString(data['status'] as String)
          : MessageStatus.sent,
      reactions: data['reactions'] != null
          ? Map<String, String>.from(data['reactions'] as Map)
          : null,
      metadata: data['metadata'] as Map<String, dynamic>?,
      translatedContent: data['translatedContent'] as String?,
      detectedLanguage: data['detectedLanguage'] as String?,
      isScheduled: data['isScheduled'] as bool? ?? false,
      scheduledFor: data['scheduledFor'] != null
          ? (data['scheduledFor'] as Timestamp).toDate()
          : null,
    );
  }

  /// Create from JSON
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      messageId: json['messageId'] as String,
      matchId: json['matchId'] as String,
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      receiverId: json['receiverId'] as String,
      content: json['content'] as String,
      type: MessageTypeExtension.fromString(json['type'] as String),
      sentAt: DateTime.parse(json['sentAt'] as String),
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'] as String)
          : null,
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'] as String)
          : null,
      status: json['status'] != null
          ? MessageStatusExtension.fromString(json['status'] as String)
          : MessageStatus.sent,
      reactions: json['reactions'] != null
          ? Map<String, String>.from(json['reactions'] as Map)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
      translatedContent: json['translatedContent'] as String?,
      detectedLanguage: json['detectedLanguage'] as String?,
      isScheduled: json['isScheduled'] as bool? ?? false,
      scheduledFor: json['scheduledFor'] != null
          ? DateTime.parse(json['scheduledFor'] as String)
          : null,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'matchId': matchId,
      'conversationId': conversationId,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'type': type.value,
      'sentAt': Timestamp.fromDate(sentAt),
      'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'status': status.value,
      'reactions': reactions,
      'metadata': metadata,
      'translatedContent': translatedContent,
      'detectedLanguage': detectedLanguage,
      'isScheduled': isScheduled,
      'scheduledFor': scheduledFor != null ? Timestamp.fromDate(scheduledFor!) : null,
    };
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'matchId': matchId,
      'conversationId': conversationId,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'type': type.value,
      'sentAt': sentAt.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'status': status.value,
      'reactions': reactions,
      'metadata': metadata,
      'translatedContent': translatedContent,
      'detectedLanguage': detectedLanguage,
      'isScheduled': isScheduled,
      'scheduledFor': scheduledFor?.toIso8601String(),
    };
  }

  /// Convert to Message entity
  Message toEntity() {
    return Message(
      messageId: messageId,
      matchId: matchId,
      conversationId: conversationId,
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      type: type,
      sentAt: sentAt,
      deliveredAt: deliveredAt,
      readAt: readAt,
      status: status,
      reactions: reactions,
      metadata: metadata,
      translatedContent: translatedContent,
      detectedLanguage: detectedLanguage,
      isScheduled: isScheduled,
      scheduledFor: scheduledFor,
    );
  }
}
