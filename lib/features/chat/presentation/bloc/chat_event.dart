import '../../domain/entities/message.dart';
import '../../../membership/domain/entities/membership.dart';

/// Chat Events
abstract class ChatEvent {
  const ChatEvent();
}

/// Load conversation and start listening to messages
class ChatConversationLoaded extends ChatEvent {
  final String matchId;
  final String currentUserId;
  final String otherUserId;

  const ChatConversationLoaded({
    required this.matchId,
    required this.currentUserId,
    required this.otherUserId,
  });
}

/// Send a message
class ChatMessageSent extends ChatEvent {
  final String content;
  final MessageType type;
  final MembershipRules? membershipRules;
  final MembershipTier? membershipTier;
  final Map<String, dynamic>? metadata;

  const ChatMessageSent({
    required this.content,
    this.type = MessageType.text,
    this.membershipRules,
    this.membershipTier,
    this.metadata,
  });
}

/// Mark messages as read
class ChatMessagesMarkedAsRead extends ChatEvent {
  const ChatMessagesMarkedAsRead();
}

/// Typing indicator changed
class ChatTypingIndicatorChanged extends ChatEvent {
  final bool isTyping;

  const ChatTypingIndicatorChanged(this.isTyping);
}

/// Delete a message
class ChatMessageDeleted extends ChatEvent {
  final String messageId;

  const ChatMessageDeleted(this.messageId);
}

/// Send an image message
class ChatImageSent extends ChatEvent {
  final String imagePath;
  final String? caption;
  final MembershipRules? membershipRules;
  final MembershipTier? membershipTier;

  const ChatImageSent({
    required this.imagePath,
    this.caption,
    this.membershipRules,
    this.membershipTier,
  });
}

/// Send a video message
class ChatVideoSent extends ChatEvent {
  final String videoPath;
  final String? caption;
  final MembershipRules? membershipRules;
  final MembershipTier? membershipTier;

  const ChatVideoSent({
    required this.videoPath,
    this.caption,
    this.membershipRules,
    this.membershipTier,
  });
}

/// Delete chat for current user only
class ChatDeletedForMe extends ChatEvent {
  const ChatDeletedForMe();
}

/// Delete chat for both users
class ChatDeletedForBoth extends ChatEvent {
  const ChatDeletedForBoth();
}

/// Block a user
class ChatUserBlocked extends ChatEvent {
  final String userId;
  final String? reason;

  const ChatUserBlocked(this.userId, {this.reason});
}

/// Report a user
class ChatUserReported extends ChatEvent {
  final String userId;
  final String reason;
  final String? messageId;
  final String? additionalDetails;

  const ChatUserReported({
    required this.userId,
    required this.reason,
    this.messageId,
    this.additionalDetails,
  });
}

/// Star a message
class ChatMessageStarred extends ChatEvent {
  final String messageId;
  final bool isStarred;

  const ChatMessageStarred({
    required this.messageId,
    required this.isStarred,
  });
}

/// Reply to a message
class ChatMessageReplied extends ChatEvent {
  final String content;
  final String replyToMessageId;
  final MessageType type;

  const ChatMessageReplied({
    required this.content,
    required this.replyToMessageId,
    this.type = MessageType.text,
  });
}

/// Forward a message
class ChatMessageForwarded extends ChatEvent {
  final String messageId;
  final List<String> toMatchIds;

  const ChatMessageForwarded({
    required this.messageId,
    required this.toMatchIds,
  });
}

/// Delete a message for current user only
class ChatMessageDeletedForMe extends ChatEvent {
  final String messageId;

  const ChatMessageDeletedForMe(this.messageId);
}

/// Delete a message for both users
class ChatMessageDeletedForBoth extends ChatEvent {
  final String messageId;

  const ChatMessageDeletedForBoth(this.messageId);
}
