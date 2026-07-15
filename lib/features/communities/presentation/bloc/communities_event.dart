import '../../domain/entities/community.dart';
import '../../domain/entities/community_message.dart';

/// Communities Events
abstract class CommunitiesEvent {
  const CommunitiesEvent();
}

/// Load all communities (with optional filters)
class LoadCommunities extends CommunitiesEvent {

  const LoadCommunities({
    this.type,
    this.language,
    this.city,
    this.searchQuery,
  });
  final CommunityType? type;
  final String? language;
  final String? city;
  final String? searchQuery;
}

/// Load the NEXT page of public communities for the Discover tab (endless
/// scroll). Carries the active filter so pagination stays consistent with the
/// current view; the bloc appends the page to the existing list.
class LoadMoreCommunities extends CommunitiesEvent {

  const LoadMoreCommunities({
    this.type,
    this.language,
    this.city,
    this.searchQuery,
  });
  final CommunityType? type;
  final String? language;
  final String? city;
  final String? searchQuery;
}

/// Load user's joined communities
class LoadUserCommunities extends CommunitiesEvent {

  const LoadUserCommunities({required this.userId});
  final String userId;
}

/// Load recommended communities
class LoadRecommendedCommunities extends CommunitiesEvent {

  const LoadRecommendedCommunities({
    required this.userId,
    required this.languages,
    this.interests = const [],
  });
  final String userId;
  final List<String> languages;
  final List<String> interests;
}

/// Load community detail (community info + members + messages)
class LoadCommunityDetail extends CommunitiesEvent {

  const LoadCommunityDetail({required this.communityId});
  final String communityId;
}

/// Create a new community
class CreateCommunity extends CommunitiesEvent {

  const CreateCommunity({
    required this.community,
    required this.userId,
    required this.userName,
  });
  final Community community;
  final String userId;
  final String userName;
}

/// Update an existing community (e.g. sponsor/promo edits by the owner-business)
class UpdateCommunity extends CommunitiesEvent {

  const UpdateCommunity({required this.community});
  final Community community;
}

/// Join a community
class JoinCommunity extends CommunitiesEvent {

  const JoinCommunity({
    required this.communityId,
    required this.userId,
    required this.displayName,
    this.photoUrl,
    this.languages = const [],
    this.isLocalGuide = false,
  });
  final String communityId;
  final String userId;
  final String displayName;
  final String? photoUrl;
  final List<String> languages;
  final bool isLocalGuide;
}

/// Leave a community
class LeaveCommunity extends CommunitiesEvent {

  const LeaveCommunity({
    required this.communityId,
    required this.userId,
  });
  final String communityId;
  final String userId;
}

/// Send a message to a community
class SendCommunityMessage extends CommunitiesEvent {

  const SendCommunityMessage({
    required this.communityId,
    required this.senderId,
    required this.senderName,
    required this.content, this.senderPhotoUrl,
    this.type = CommunityMessageType.text,
  });
  final String communityId;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String content;
  final CommunityMessageType type;
}

/// Start listening to community messages
class SubscribeToCommunityMessages extends CommunitiesEvent {

  const SubscribeToCommunityMessages({required this.communityId});
  final String communityId;
}

/// Messages received from stream
class CommunityMessagesUpdated extends CommunitiesEvent {

  const CommunityMessagesUpdated({required this.messages});
  final List<CommunityMessage> messages;
}

/// Request to join a PRIVATE community (creates a pending request).
class RequestToJoinCommunity extends CommunitiesEvent {

  const RequestToJoinCommunity({
    required this.communityId,
    required this.userId,
    required this.displayName,
    this.photoUrl,
    this.languages = const [],
    this.isLocalGuide = false,
  });
  final String communityId;
  final String userId;
  final String displayName;
  final String? photoUrl;
  final List<String> languages;
  final bool isLocalGuide;
}

/// Load pending join requests (owner/admin) into the detail state.
class LoadJoinRequests extends CommunitiesEvent {
  const LoadJoinRequests({required this.communityId});
  final String communityId;
}

/// Approve a pending join request.
class ApproveJoinRequest extends CommunitiesEvent {
  const ApproveJoinRequest({required this.communityId, required this.userId});
  final String communityId;
  final String userId;
}

/// Reject a pending join request.
class RejectJoinRequest extends CommunitiesEvent {
  const RejectJoinRequest({required this.communityId, required this.userId});
  final String communityId;
  final String userId;
}

/// Moderation action on a member (promote/demote/remove/mute/unmute/ban +
/// granular tip/announcement writer grants).
enum MemberModerationAction {
  promoteToAdmin,
  demoteToMember,
  remove,
  mute,
  unmute,
  ban,
  grantTips,
  revokeTips,
  grantAnnouncements,
  revokeAnnouncements,
}

/// Apply a moderation action to a member, then refresh the members list.
class ModerateMember extends CommunitiesEvent {
  const ModerateMember({
    required this.communityId,
    required this.userId,
    required this.action,
  });
  final String communityId;
  final String userId;
  final MemberModerationAction action;
}

/// Permanently delete a community (owner-only; the UI gates this behind an
/// owner password re-authentication before dispatching).
class DeleteCommunity extends CommunitiesEvent {
  const DeleteCommunity({required this.communityId});
  final String communityId;
}

/// Seed sample communities (development only)
class SeedSampleCommunities extends CommunitiesEvent {
  const SeedSampleCommunities();
}
