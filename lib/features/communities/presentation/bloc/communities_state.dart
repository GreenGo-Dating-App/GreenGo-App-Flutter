import '../../domain/entities/community.dart';
import '../../domain/entities/community_member.dart';
import '../../domain/entities/community_message.dart';

/// Communities States
abstract class CommunitiesState {
  const CommunitiesState();
}

/// Initial state
class CommunitiesInitial extends CommunitiesState {
  const CommunitiesInitial();
}

/// Loading state
class CommunitiesLoading extends CommunitiesState {
  const CommunitiesLoading();
}

/// Communities loaded (list view)
class CommunitiesLoaded extends CommunitiesState {

  const CommunitiesLoaded({
    this.communities = const [],
    this.userCommunities = const [],
    this.recommended = const [],
    this.languageCircles = const [],
    this.hasMoreCommunities = true,
    this.isLoadingMore = false,
    this.communitiesCursor,
  });
  final List<Community> communities;
  final List<Community> userCommunities;
  final List<Community> recommended;
  final List<Community> languageCircles;

  /// Discover pagination: whether another page of public communities may exist
  /// (false once the last fetch returned fewer than the page size).
  final bool hasMoreCommunities;

  /// True while a "load more" page is being fetched (drives the trailing
  /// spinner without blanking the existing list).
  final bool isLoadingMore;

  /// Keyset cursor for endless scroll — the OLDEST `lastActivityAt` fetched so
  /// far. Tracked separately from the (shuffled) display order so pagination
  /// stays correct even though Discover is shown in random order.
  final DateTime? communitiesCursor;

  CommunitiesLoaded copyWith({
    List<Community>? communities,
    List<Community>? userCommunities,
    List<Community>? recommended,
    List<Community>? languageCircles,
    bool? hasMoreCommunities,
    bool? isLoadingMore,
    DateTime? communitiesCursor,
  }) {
    return CommunitiesLoaded(
      communities: communities ?? this.communities,
      userCommunities: userCommunities ?? this.userCommunities,
      recommended: recommended ?? this.recommended,
      languageCircles: languageCircles ?? this.languageCircles,
      hasMoreCommunities: hasMoreCommunities ?? this.hasMoreCommunities,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      communitiesCursor: communitiesCursor ?? this.communitiesCursor,
    );
  }
}

/// Community detail loaded (single community view)
class CommunityDetailLoaded extends CommunitiesState {

  const CommunityDetailLoaded({
    required this.community,
    this.members = const [],
    this.messages = const [],
    this.isMember = false,
    this.isSending = false,
    this.pendingRequests = const [],
  });
  final Community community;
  final List<CommunityMember> members;
  final List<CommunityMessage> messages;
  final bool isMember;
  final bool isSending;

  /// Pending join requests (private communities) — loaded for owner/admins.
  final List<CommunityMember> pendingRequests;

  CommunityDetailLoaded copyWith({
    Community? community,
    List<CommunityMember>? members,
    List<CommunityMessage>? messages,
    bool? isMember,
    bool? isSending,
    List<CommunityMember>? pendingRequests,
  }) {
    return CommunityDetailLoaded(
      community: community ?? this.community,
      members: members ?? this.members,
      messages: messages ?? this.messages,
      isMember: isMember ?? this.isMember,
      isSending: isSending ?? this.isSending,
      pendingRequests: pendingRequests ?? this.pendingRequests,
    );
  }
}

/// Community created successfully
class CommunityCreated extends CommunitiesState {

  const CommunityCreated({required this.community});
  final Community community;
}

/// Community joined successfully
class CommunityJoined extends CommunitiesState {

  const CommunityJoined({required this.communityId});
  final String communityId;
}

/// Join request submitted for a private community (awaiting approval).
class CommunityJoinRequested extends CommunitiesState {

  const CommunityJoinRequested({required this.communityId});
  final String communityId;
}

/// Community left successfully
class CommunityLeft extends CommunitiesState {

  const CommunityLeft({required this.communityId});
  final String communityId;
}

/// Community permanently deleted (owner action).
class CommunityDeleted extends CommunitiesState {

  const CommunityDeleted({required this.communityId});
  final String communityId;
}

/// Error state
class CommunitiesError extends CommunitiesState {

  const CommunitiesError({required this.message});
  final String message;
}
