import '../../domain/entities/community.dart';
import '../../domain/entities/community_message.dart';

/// Communities Events
abstract class CommunitiesEvent {
  const CommunitiesEvent();
}

/// Load all communities (with optional filters)
class LoadCommunities extends CommunitiesEvent {
  final CommunityType? type;
  final String? language;
  final String? city;
  final String? searchQuery;

  const LoadCommunities({
    this.type,
    this.language,
    this.city,
    this.searchQuery,
  });
}

/// Load user's joined communities
class LoadUserCommunities extends CommunitiesEvent {
  final String userId;

  const LoadUserCommunities({required this.userId});
}

/// Load recommended communities
class LoadRecommendedCommunities extends CommunitiesEvent {
  final String userId;
  final List<String> languages;
  final List<String> interests;

  const LoadRecommendedCommunities({
    required this.userId,
    required this.languages,
    this.interests = const [],
  });
}

/// Load community detail (community info + members + messages)
class LoadCommunityDetail extends CommunitiesEvent {
  final String communityId;

  const LoadCommunityDetail({required this.communityId});
}

/// Create a new community
class CreateCommunity extends CommunitiesEvent {
  final Community community;
  final String userId;
  final String userName;

  const CreateCommunity({
    required this.community,
    required this.userId,
    required this.userName,
  });
}

/// Join a community
class JoinCommunity extends CommunitiesEvent {
  final String communityId;
  final String userId;
  final String displayName;
  final String? photoUrl;
  final List<String> languages;
  final bool isLocalGuide;

  const JoinCommunity({
    required this.communityId,
    required this.userId,
    required this.displayName,
    this.photoUrl,
    this.languages = const [],
    this.isLocalGuide = false,
  });
}

/// Leave a community
class LeaveCommunity extends CommunitiesEvent {
  final String communityId;
  final String userId;

  const LeaveCommunity({
    required this.communityId,
    required this.userId,
  });
}

/// Send a message to a community
class SendCommunityMessage extends CommunitiesEvent {
  final String communityId;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String content;
  final CommunityMessageType type;

  const SendCommunityMessage({
    required this.communityId,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.content,
    this.type = CommunityMessageType.text,
  });
}

/// Start listening to community messages
class SubscribeToCommunityMessages extends CommunitiesEvent {
  final String communityId;

  const SubscribeToCommunityMessages({required this.communityId});
}

/// Messages received from stream
class CommunityMessagesUpdated extends CommunitiesEvent {
  final List<CommunityMessage> messages;

  const CommunityMessagesUpdated({required this.messages});
}

/// Seed sample communities (development only)
class SeedSampleCommunities extends CommunitiesEvent {
  const SeedSampleCommunities();
}
