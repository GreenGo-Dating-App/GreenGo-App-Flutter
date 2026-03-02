import 'package:equatable/equatable.dart';

/// Community Message Entity
///
/// Represents a message sent within a community group chat
class CommunityMessage extends Equatable {
  final String id;
  final String communityId;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String content;
  final DateTime sentAt;
  final CommunityMessageType type;

  const CommunityMessage({
    required this.id,
    required this.communityId,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.content,
    required this.sentAt,
    this.type = CommunityMessageType.text,
  });

  /// Check if message was sent by a specific user
  bool isSentBy(String userId) => senderId == userId;

  /// Check if this is a special message type (tip or fact)
  bool get isSpecialType =>
      type == CommunityMessageType.languageTip ||
      type == CommunityMessageType.culturalFact ||
      type == CommunityMessageType.cityTip;

  /// Get time display text
  String get timeText {
    final hour = sentAt.hour > 12 ? sentAt.hour - 12 : sentAt.hour;
    final displayHour = hour == 0 ? 12 : hour;
    final minute = sentAt.minute.toString().padLeft(2, '0');
    final period = sentAt.hour >= 12 ? 'PM' : 'AM';
    return '$displayHour:$minute $period';
  }

  /// Get time since message was sent
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

  /// Copy with updated fields
  CommunityMessage copyWith({
    String? id,
    String? communityId,
    String? senderId,
    String? senderName,
    String? senderPhotoUrl,
    String? content,
    DateTime? sentAt,
    CommunityMessageType? type,
  }) {
    return CommunityMessage(
      id: id ?? this.id,
      communityId: communityId ?? this.communityId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderPhotoUrl: senderPhotoUrl ?? this.senderPhotoUrl,
      content: content ?? this.content,
      sentAt: sentAt ?? this.sentAt,
      type: type ?? this.type,
    );
  }

  @override
  List<Object?> get props => [
        id,
        communityId,
        senderId,
        senderName,
        senderPhotoUrl,
        content,
        sentAt,
        type,
      ];
}

/// Community Message Type
enum CommunityMessageType {
  text('Text'),
  image('Image'),
  languageTip('Language Tip'),
  culturalFact('Cultural Fact'),
  cityTip('City Tip'),
  system('System');

  final String displayName;
  const CommunityMessageType(this.displayName);
}

/// Extension for CommunityMessageType serialization
extension CommunityMessageTypeExtension on CommunityMessageType {
  String get value {
    switch (this) {
      case CommunityMessageType.text:
        return 'text';
      case CommunityMessageType.image:
        return 'image';
      case CommunityMessageType.languageTip:
        return 'language_tip';
      case CommunityMessageType.culturalFact:
        return 'cultural_fact';
      case CommunityMessageType.cityTip:
        return 'city_tip';
      case CommunityMessageType.system:
        return 'system';
    }
  }

  static CommunityMessageType fromString(String value) {
    switch (value) {
      case 'text':
        return CommunityMessageType.text;
      case 'image':
        return CommunityMessageType.image;
      case 'language_tip':
        return CommunityMessageType.languageTip;
      case 'cultural_fact':
        return CommunityMessageType.culturalFact;
      case 'city_tip':
        return CommunityMessageType.cityTip;
      case 'system':
        return CommunityMessageType.system;
      default:
        return CommunityMessageType.text;
    }
  }
}
