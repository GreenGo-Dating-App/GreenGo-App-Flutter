import '../../../membership/domain/entities/membership.dart';
import '../../domain/entities/message.dart';

/// Chat Events
abstract class ChatEvent {
  const ChatEvent();
}

/// Load conversation and start listening to messages
class ChatConversationLoaded extends ChatEvent {

  const ChatConversationLoaded({
    required this.matchId,
    required this.currentUserId,
    required this.otherUserId,
    this.limit,
  });
  final String matchId;
  final String currentUserId;
  final String otherUserId;
  final int? limit;
}

/// Send a message
class ChatMessageSent extends ChatEvent {

  const ChatMessageSent({
    required this.content,
    this.type = MessageType.text,
    this.membershipRules,
    this.membershipTier,
    this.metadata,
  });
  final String content;
  final MessageType type;
  final MembershipRules? membershipRules;
  final MembershipTier? membershipTier;
  final Map<String, dynamic>? metadata;
}

/// Mark messages as read
class ChatMessagesMarkedAsRead extends ChatEvent {
  const ChatMessagesMarkedAsRead();
}

/// Typing indicator changed
class ChatTypingIndicatorChanged extends ChatEvent {

  const ChatTypingIndicatorChanged(this.isTyping);
  final bool isTyping;
}

/// Delete a message
class ChatMessageDeleted extends ChatEvent {

  const ChatMessageDeleted(this.messageId);
  final String messageId;
}

/// Send an image message
class ChatImageSent extends ChatEvent {

  const ChatImageSent({
    required this.imagePath,
    this.caption,
    this.membershipRules,
    this.membershipTier,
  });
  final String imagePath;
  final String? caption;
  final MembershipRules? membershipRules;
  final MembershipTier? membershipTier;
}

/// Send a video message
class ChatVideoSent extends ChatEvent {

  const ChatVideoSent({
    required this.videoPath,
    this.caption,
    this.membershipRules,
    this.membershipTier,
  });
  final String videoPath;
  final String? caption;
  final MembershipRules? membershipRules;
  final MembershipTier? membershipTier;
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

  const ChatUserBlocked(this.userId, {this.reason});
  final String userId;
  final String? reason;
}

/// Report a user
class ChatUserReported extends ChatEvent {

  const ChatUserReported({
    required this.userId,
    required this.reason,
    this.messageId,
    this.additionalDetails,
  });
  final String userId;
  final String reason;
  final String? messageId;
  final String? additionalDetails;
}

/// Star a message
class ChatMessageStarred extends ChatEvent {

  const ChatMessageStarred({
    required this.messageId,
    required this.isStarred,
  });
  final String messageId;
  final bool isStarred;
}

/// Reply to a message
class ChatMessageReplied extends ChatEvent {

  const ChatMessageReplied({
    required this.content,
    required this.replyToMessageId,
    this.type = MessageType.text,
  });
  final String content;
  final String replyToMessageId;
  final MessageType type;
}

/// Forward a message
class ChatMessageForwarded extends ChatEvent {

  const ChatMessageForwarded({
    required this.messageId,
    required this.toMatchIds,
  });
  final String messageId;
  final List<String> toMatchIds;
}

/// Delete a message for current user only
class ChatMessageDeletedForMe extends ChatEvent {

  const ChatMessageDeletedForMe(this.messageId);
  final String messageId;
}

/// Delete a message for both users
class ChatMessageDeletedForBoth extends ChatEvent {

  const ChatMessageDeletedForBoth(this.messageId);
  final String messageId;
}
