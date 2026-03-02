import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/community_message.dart';

/// Community Message Model
///
/// Data layer model for CommunityMessage entity with Firestore serialization
class CommunityMessageModel extends CommunityMessage {
  const CommunityMessageModel({
    required super.id,
    required super.communityId,
    required super.senderId,
    required super.senderName,
    super.senderPhotoUrl,
    required super.content,
    required super.sentAt,
    super.type,
  });

  /// Create from CommunityMessage entity
  factory CommunityMessageModel.fromEntity(CommunityMessage message) {
    return CommunityMessageModel(
      id: message.id,
      communityId: message.communityId,
      senderId: message.senderId,
      senderName: message.senderName,
      senderPhotoUrl: message.senderPhotoUrl,
      content: message.content,
      sentAt: message.sentAt,
      type: message.type,
    );
  }

  /// Create from Firestore document
  factory CommunityMessageModel.fromFirestore(
    DocumentSnapshot doc, {
    required String communityId,
  }) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return CommunityMessageModel(
      id: doc.id,
      communityId: communityId,
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? '',
      senderPhotoUrl: data['senderPhotoUrl'] as String?,
      content: data['content'] as String? ?? '',
      sentAt: data['sentAt'] != null
          ? (data['sentAt'] as Timestamp).toDate()
          : DateTime.now(),
      type: CommunityMessageTypeExtension.fromString(
        data['type'] as String? ?? 'text',
      ),
    );
  }

  /// Create from JSON map
  factory CommunityMessageModel.fromJson(Map<String, dynamic> json) {
    return CommunityMessageModel(
      id: json['id'] as String? ?? '',
      communityId: json['communityId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      senderName: json['senderName'] as String? ?? '',
      senderPhotoUrl: json['senderPhotoUrl'] as String?,
      content: json['content'] as String? ?? '',
      sentAt: json['sentAt'] != null
          ? DateTime.parse(json['sentAt'] as String)
          : DateTime.now(),
      type: CommunityMessageTypeExtension.fromString(
        json['type'] as String? ?? 'text',
      ),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'content': content,
      'sentAt': Timestamp.fromDate(sentAt),
      'type': type.value,
    };
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'communityId': communityId,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'content': content,
      'sentAt': sentAt.toIso8601String(),
      'type': type.value,
    };
  }

  /// Convert to CommunityMessage entity
  CommunityMessage toEntity() {
    return CommunityMessage(
      id: id,
      communityId: communityId,
      senderId: senderId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      content: content,
      sentAt: sentAt,
      type: type,
    );
  }
}
