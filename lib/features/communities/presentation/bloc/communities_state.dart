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
    this.managedCommunities = const [],
    this.managedLoaded = false,
  });
  final List<Community> communities;
  final List<Community> userCommunities;
  final List<Community> recommended;
  final List<Community> languageCircles;

  /// Communities the user CREATED (the "My communities" tab). Loaded via a
  /// direct createdByUserId query, so it's independent of member docs.
  final List<Community> managedCommunities;

  /// Whether the "My communities" query has completed at least once — drives a
  /// loader (vs the empty state) on the Managed tab.
  final bool managedLoaded;

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
    List<Community>? managedCommunities,
    bool? managedLoaded,
  }) {
    return CommunitiesLoaded(
      communities: communities ?? this.communities,
      userCommunities: userCommunities ?? this.userCommunities,
      recommended: recommended ?? this.recommended,
      languageCircles: languageCircles ?? this.languageCircles,
      hasMoreCommunities: hasMoreCommunities ?? this.hasMoreCommunities,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      communitiesCursor: communitiesCursor ?? this.communitiesCursor,
      managedCommunities: managedCommunities ?? this.managedCommunities,
      managedLoaded: managedLoaded ?? this.managedLoaded,
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
    this.myMembership,
    this.membershipLoaded = false,
    this.membersLoaded = false,
    this.isLoadingMembers = false,
    this.hasMoreMembers = false,
    this.hasMoreMessages = false,
    this.hasMoreTips = false,
    this.isLoadingOlderMessages = false,
    this.isLoadingOlderTips = false,
  });
  final Community community;

  /// Older chat messages may exist before the loaded ones (endless scroll).
  final bool hasMoreMessages;

  /// Older tips may exist before the loaded ones (endless scroll).
  final bool hasMoreTips;
  final bool isLoadingOlderMessages;
  final bool isLoadingOlderTips;

  /// The roster pages loaded so far (lazy — empty until the Members sheet
  /// asks for them, see [membersLoaded]).
  final List<CommunityMember> members;
  final List<CommunityMessage> messages;
  final bool isMember;
  final bool isSending;

  /// Pending join requests (private communities) — loaded for owner/admins.
  final List<CommunityMember> pendingRequests;

  /// The signed-in user's own member doc (null = not a member) — read as a
  /// single document so the detail never waits for the whole roster.
  final CommunityMember? myMembership;

  /// True once [myMembership] has been resolved (found or confirmed absent).
  final bool membershipLoaded;

  /// True once the first roster page has loaded.
  final bool membersLoaded;
  final bool isLoadingMembers;

  /// Another roster page may exist.
  final bool hasMoreMembers;

  CommunityDetailLoaded copyWith({
    Community? community,
    List<CommunityMember>? members,
    List<CommunityMessage>? messages,
    bool? isMember,
    bool? isSending,
    List<CommunityMember>? pendingRequests,
    CommunityMember? myMembership,
    bool clearMyMembership = false,
    bool? membershipLoaded,
    bool? membersLoaded,
    bool? isLoadingMembers,
    bool? hasMoreMembers,
    bool? hasMoreMessages,
    bool? hasMoreTips,
    bool? isLoadingOlderMessages,
    bool? isLoadingOlderTips,
  }) {
    return CommunityDetailLoaded(
      community: community ?? this.community,
      members: members ?? this.members,
      messages: messages ?? this.messages,
      isMember: isMember ?? this.isMember,
      isSending: isSending ?? this.isSending,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      myMembership:
          clearMyMembership ? null : (myMembership ?? this.myMembership),
      membershipLoaded: membershipLoaded ?? this.membershipLoaded,
      membersLoaded: membersLoaded ?? this.membersLoaded,
      isLoadingMembers: isLoadingMembers ?? this.isLoadingMembers,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      hasMoreTips: hasMoreTips ?? this.hasMoreTips,
      isLoadingOlderMessages:
          isLoadingOlderMessages ?? this.isLoadingOlderMessages,
      isLoadingOlderTips: isLoadingOlderTips ?? this.isLoadingOlderTips,
      hasMoreMembers: hasMoreMembers ?? this.hasMoreMembers,
    );
  }
}

/// Community created successfully
class CommunityCreated extends CommunitiesState {
  const CommunityCreated({required this.community});
  final Community community;
}

/// A community's doc was saved (creator info edit, rules, sponsorship).
/// One-shot: the list screen patches its cached lists with [community] and the
/// edit form closes; the detail screen gets the follow-up
/// [CommunityDetailLoaded] carrying the same community.
class CommunityInfoUpdated extends CommunitiesState {
  const CommunityInfoUpdated({required this.community});
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

/// [loaded] with every list entry whose id is [updated]'s replaced by
/// [updated] (Discover, joined, recommended, language circles, managed).
CommunitiesLoaded replaceCommunityInLoaded(
    CommunitiesLoaded loaded, Community updated) {
  List<Community> swap(List<Community> list) => list.any((c) => c.id == updated.id)
      ? [for (final c in list) c.id == updated.id ? updated : c]
      : list;
  return loaded.copyWith(
    communities: swap(loaded.communities),
    userCommunities: swap(loaded.userCommunities),
    recommended: swap(loaded.recommended),
    languageCircles: swap(loaded.languageCircles),
    managedCommunities: swap(loaded.managedCommunities),
  );
}
