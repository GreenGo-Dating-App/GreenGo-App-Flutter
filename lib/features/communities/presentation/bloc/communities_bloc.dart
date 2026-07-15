import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../data/datasources/communities_remote_datasource.dart';
import '../../domain/entities/community.dart';
import '../../domain/entities/community_member.dart';
import '../../domain/entities/community_message.dart';
import '../../domain/repositories/communities_repository.dart';
import 'communities_event.dart';
import 'communities_state.dart';

/// Communities BLoC
///
/// Manages state for the communities feature including
/// interest groups, language circles, and local guide program
class CommunitiesBloc extends Bloc<CommunitiesEvent, CommunitiesState> {

  CommunitiesBloc({
    required CommunitiesRepository repository,
    required CommunitiesRemoteDataSource remoteDataSource,
  })  : _repository = repository,
        _remoteDataSource = remoteDataSource,
        super(const CommunitiesInitial()) {
    on<LoadCommunities>(_onLoadCommunities);
    on<LoadMoreCommunities>(_onLoadMoreCommunities);
    on<LoadUserCommunities>(_onLoadUserCommunities);
    on<LoadRecommendedCommunities>(_onLoadRecommendedCommunities);
    on<LoadCommunityDetail>(_onLoadCommunityDetail);
    on<CreateCommunity>(_onCreateCommunity);
    on<UpdateCommunity>(_onUpdateCommunity);
    on<JoinCommunity>(_onJoinCommunity);
    on<LeaveCommunity>(_onLeaveCommunity);
    on<DeleteCommunity>(_onDeleteCommunity);
    on<SendCommunityMessage>(_onSendMessage);
    on<SubscribeToCommunityMessages>(_onSubscribeToMessages);
    on<CommunityMessagesUpdated>(_onMessagesUpdated);
    on<RequestToJoinCommunity>(_onRequestToJoin);
    on<LoadJoinRequests>(_onLoadJoinRequests);
    on<ApproveJoinRequest>(_onApproveJoinRequest);
    on<RejectJoinRequest>(_onRejectJoinRequest);
    on<ModerateMember>(_onModerateMember);
    on<SeedSampleCommunities>(_onSeedSampleCommunities);
  }
  final CommunitiesRepository _repository;
  final CommunitiesRemoteDataSource _remoteDataSource;

  /// Discover page size (must match the value the datasource pages by).
  static const int _communitiesPageSize = 50;

  StreamSubscription? _messagesSubscription;

  Future<void> _onLoadCommunities(
    LoadCommunities event,
    Emitter<CommunitiesState> emit,
  ) async {
    // Preserve any already-loaded lists so a reload/refresh never blanks the
    // tabs. Only show the full-screen spinner on the FIRST load.
    final currentState = state;
    var userCommunities = <Community>[];
    var recommended = <Community>[];
    if (currentState is CommunitiesLoaded) {
      userCommunities = currentState.userCommunities;
      recommended = currentState.recommended;
    } else {
      emit(const CommunitiesLoading());
    }

    final result = await _repository.getCommunities(
      type: event.type,
      language: event.language,
      city: event.city,
      searchQuery: event.searchQuery,
      limit: _communitiesPageSize,
    );

    result.fold(
      (failure) {
        // A failing Discover query must NOT blank the already-loaded My/Managed
        // tabs. Keep whatever we have; only surface a hard error on first load
        // when there is nothing to show at all.
        debugPrint('LoadCommunities failed: ${failure.message}');
        if (currentState is CommunitiesLoaded) {
          emit(currentState);
        } else {
          emit(CommunitiesError(message: failure.message));
        }
      },
      (communities) {
        // Separate language circles from other communities
        final languageCircles = communities
            .where((c) => c.type == CommunityType.languageCircle)
            .toList();

        emit(CommunitiesLoaded(
          communities: communities,
          userCommunities: userCommunities,
          recommended: recommended,
          languageCircles: languageCircles,
          hasMoreCommunities: communities.length >= _communitiesPageSize,
          isLoadingMore: false,
        ));
      },
    );
  }

  /// Endless scroll: fetch the NEXT page of public communities and APPEND it to
  /// the Discover list without disturbing the other tabs. No-op if there is no
  /// more data, a page is already in flight, or there is no cursor yet.
  Future<void> _onLoadMoreCommunities(
    LoadMoreCommunities event,
    Emitter<CommunitiesState> emit,
  ) async {
    final currentState = state;
    if (currentState is! CommunitiesLoaded) return;
    if (!currentState.hasMoreCommunities || currentState.isLoadingMore) return;
    if (currentState.communities.isEmpty) return;

    final cursor = currentState.communities.last.lastActivityAt;
    if (cursor == null) {
      // Can't paginate without a cursor value; treat as end of list.
      emit(currentState.copyWith(hasMoreCommunities: false));
      return;
    }

    emit(currentState.copyWith(isLoadingMore: true));

    final result = await _repository.getCommunities(
      type: event.type,
      language: event.language,
      city: event.city,
      searchQuery: event.searchQuery,
      startAfterActivity: cursor,
      limit: _communitiesPageSize,
    );

    result.fold(
      (failure) {
        debugPrint('LoadMoreCommunities failed: ${failure.message}');
        // Keep the list intact; just stop the spinner and allow a retry.
        final s = state;
        if (s is CommunitiesLoaded) {
          emit(s.copyWith(isLoadingMore: false));
        }
      },
      (page) {
        final s = state;
        if (s is! CommunitiesLoaded) return;
        // Dedupe by id in case a boundary item overlaps.
        final existingIds = s.communities.map((c) => c.id).toSet();
        final fresh =
            page.where((c) => !existingIds.contains(c.id)).toList();
        final merged = [...s.communities, ...fresh];
        emit(s.copyWith(
          communities: merged,
          languageCircles: merged
              .where((c) => c.type == CommunityType.languageCircle)
              .toList(),
          hasMoreCommunities: page.length >= _communitiesPageSize,
          isLoadingMore: false,
        ));
      },
    );
  }

  Future<void> _onLoadUserCommunities(
    LoadUserCommunities event,
    Emitter<CommunitiesState> emit,
  ) async {
    // Preserve current state data if available
    final currentState = state;
    var allCommunities = <Community>[];
    var recommended = <Community>[];
    var languageCircles = <Community>[];

    if (currentState is CommunitiesLoaded) {
      allCommunities = currentState.communities;
      recommended = currentState.recommended;
      languageCircles = currentState.languageCircles;
    } else {
      // Only blank to a spinner on the FIRST load; a refresh keeps the lists.
      emit(const CommunitiesLoading());
    }

    final result = await _repository.getUserCommunities(event.userId);

    result.fold(
      // A failing "My Communities" query must not blank Discover/Managed.
      // Preserve every other slice and just show My as empty.
      (failure) {
        debugPrint('LoadUserCommunities failed: ${failure.message}');
        emit(CommunitiesLoaded(
          communities: allCommunities,
          userCommunities: const [],
          recommended: recommended,
          languageCircles: languageCircles,
        ));
      },
      (userCommunities) {
        emit(CommunitiesLoaded(
          communities: allCommunities,
          userCommunities: userCommunities,
          recommended: recommended,
          languageCircles: languageCircles,
        ));
      },
    );
  }

  Future<void> _onLoadRecommendedCommunities(
    LoadRecommendedCommunities event,
    Emitter<CommunitiesState> emit,
  ) async {
    final currentState = state;
    var allCommunities = <Community>[];
    var userCommunities = <Community>[];
    var languageCircles = <Community>[];

    if (currentState is CommunitiesLoaded) {
      allCommunities = currentState.communities;
      userCommunities = currentState.userCommunities;
      languageCircles = currentState.languageCircles;
    }

    final result = await _repository.getRecommendedCommunities(
      userId: event.userId,
      languages: event.languages,
      interests: event.interests,
    );

    result.fold(
      // Recommended is the most index-hungry query; a failure here previously
      // emitted CommunitiesError and blanked ALL tabs (the real "communities
      // not appearing" bug). Preserve every loaded slice; just show no
      // recommendations.
      (failure) {
        debugPrint('LoadRecommendedCommunities failed: ${failure.message}');
        final currentState = state;
        if (currentState is CommunitiesLoaded) {
          emit(currentState.copyWith(recommended: const []));
        } else {
          emit(CommunitiesLoaded(
            communities: allCommunities,
            userCommunities: userCommunities,
            recommended: const [],
            languageCircles: languageCircles,
          ));
        }
      },
      (recommended) {
        emit(CommunitiesLoaded(
          communities: allCommunities,
          userCommunities: userCommunities,
          recommended: recommended,
          languageCircles: languageCircles,
        ));
      },
    );
  }

  Future<void> _onLoadCommunityDetail(
    LoadCommunityDetail event,
    Emitter<CommunitiesState> emit,
  ) async {
    emit(const CommunitiesLoading());

    final communityResult =
        await _repository.getCommunityById(event.communityId);

    await communityResult.fold(
      (failure) async =>
          emit(CommunitiesError(message: failure.message)),
      (community) async {
        final membersResult =
            await _repository.getCommunityMembers(event.communityId);

        final members = membersResult.fold(
          (failure) => <CommunityMember>[],
          (members) => members,
        );

        emit(CommunityDetailLoaded(
          community: community,
          members: members,
          messages: const [],
          isMember: false,
        ));
      },
    );
  }

  Future<void> _onCreateCommunity(
    CreateCommunity event,
    Emitter<CommunitiesState> emit,
  ) async {
    emit(const CommunitiesLoading());

    final result = await _repository.createCommunity(event.community);

    // NOTE: the success branch is async (it awaits joinCommunity before
    // emitting). The whole fold MUST be awaited — otherwise `_onCreateCommunity`
    // completes before `emit(CommunityCreated)` runs, Bloc rejects the late
    // emit, the UI's BlocListener never fires and "Create" appears to do nothing
    // (even though the community was actually written).
    await result.fold(
      (failure) async => emit(CommunitiesError(message: failure.message)),
      (community) async {
        // Auto-join the creator as owner
        final member = CommunityMember(
          userId: event.userId,
          displayName: event.userName,
          role: CommunityRole.owner,
          joinedAt: DateTime.now(),
        );

        await _repository.joinCommunity(
          communityId: community.id,
          member: member,
        );

        emit(CommunityCreated(community: community));
      },
    );
  }

  Future<void> _onUpdateCommunity(
    UpdateCommunity event,
    Emitter<CommunitiesState> emit,
  ) async {
    final result = await _repository.updateCommunity(event.community);

    result.fold(
      (failure) => emit(CommunitiesError(message: failure.message)),
      (_) {
        // Reflect the updated community in-place so the detail view (promo,
        // header badge) refreshes without dropping the live message stream.
        final currentState = state;
        if (currentState is CommunityDetailLoaded) {
          emit(currentState.copyWith(community: event.community));
        }
      },
    );
  }

  Future<void> _onJoinCommunity(
    JoinCommunity event,
    Emitter<CommunitiesState> emit,
  ) async {
    final member = CommunityMember(
      userId: event.userId,
      displayName: event.displayName,
      photoUrl: event.photoUrl,
      role: CommunityRole.member,
      joinedAt: DateTime.now(),
      languages: event.languages,
      isLocalGuide: event.isLocalGuide,
    );

    final result = await _repository.joinCommunity(
      communityId: event.communityId,
      member: member,
    );

    result.fold(
      (failure) => emit(CommunitiesError(message: failure.message)),
      (_) {
        emit(CommunityJoined(communityId: event.communityId));

        // Refresh detail if currently viewing this community
        add(LoadCommunityDetail(communityId: event.communityId));
      },
    );
  }

  Future<void> _onLeaveCommunity(
    LeaveCommunity event,
    Emitter<CommunitiesState> emit,
  ) async {
    final result = await _repository.leaveCommunity(
      communityId: event.communityId,
      userId: event.userId,
    );

    result.fold(
      (failure) => emit(CommunitiesError(message: failure.message)),
      (_) => emit(CommunityLeft(communityId: event.communityId)),
    );
  }

  Future<void> _onDeleteCommunity(
    DeleteCommunity event,
    Emitter<CommunitiesState> emit,
  ) async {
    final result =
        await _repository.deleteCommunity(event.communityId);
    result.fold(
      (failure) => emit(CommunitiesError(message: failure.message)),
      (_) => emit(CommunityDeleted(communityId: event.communityId)),
    );
  }

  Future<void> _onSendMessage(
    SendCommunityMessage event,
    Emitter<CommunitiesState> emit,
  ) async {
    final currentState = state;
    if (currentState is CommunityDetailLoaded) {
      emit(currentState.copyWith(isSending: true));
    }

    final message = CommunityMessage(
      id: '',
      communityId: event.communityId,
      senderId: event.senderId,
      senderName: event.senderName,
      senderPhotoUrl: event.senderPhotoUrl,
      content: event.content,
      sentAt: DateTime.now(),
      type: event.type,
    );

    final result = await _repository.sendMessage(
      communityId: event.communityId,
      message: message,
    );

    result.fold(
      (failure) => emit(CommunitiesError(message: failure.message)),
      (sentMessage) {
        if (currentState is CommunityDetailLoaded) {
          emit(currentState.copyWith(isSending: false));
        }
      },
    );
  }

  void _onSubscribeToMessages(
    SubscribeToCommunityMessages event,
    Emitter<CommunitiesState> emit,
  ) {
    _messagesSubscription?.cancel();

    _messagesSubscription = _repository
        .getCommunityMessages(event.communityId)
        .listen(
      (result) {
        result.fold(
          (failure) {
            debugPrint('Message stream error: ${failure.message}');
          },
          (messages) {
            add(CommunityMessagesUpdated(messages: messages));
          },
        );
      },
      onError: (error) {
        debugPrint('Message stream error: $error');
      },
    );
  }

  void _onMessagesUpdated(
    CommunityMessagesUpdated event,
    Emitter<CommunitiesState> emit,
  ) {
    final currentState = state;
    if (currentState is CommunityDetailLoaded) {
      emit(currentState.copyWith(messages: event.messages));
    }
  }

  Future<void> _onRequestToJoin(
    RequestToJoinCommunity event,
    Emitter<CommunitiesState> emit,
  ) async {
    final request = CommunityMember(
      userId: event.userId,
      displayName: event.displayName,
      photoUrl: event.photoUrl,
      role: CommunityRole.member,
      joinedAt: DateTime.now(),
      languages: event.languages,
      isLocalGuide: event.isLocalGuide,
    );

    final result = await _repository.requestToJoin(
      communityId: event.communityId,
      request: request,
    );

    result.fold(
      (failure) => emit(CommunitiesError(message: failure.message)),
      (_) => emit(CommunityJoinRequested(communityId: event.communityId)),
    );
  }

  Future<void> _onLoadJoinRequests(
    LoadJoinRequests event,
    Emitter<CommunitiesState> emit,
  ) async {
    final result = await _repository.getJoinRequests(event.communityId);
    final current = state;
    if (current is! CommunityDetailLoaded) return;
    result.fold(
      (failure) => debugPrint('Join requests error: ${failure.message}'),
      (requests) => emit(current.copyWith(pendingRequests: requests)),
    );
  }

  Future<void> _onApproveJoinRequest(
    ApproveJoinRequest event,
    Emitter<CommunitiesState> emit,
  ) async {
    final result = await _repository.approveJoinRequest(
      communityId: event.communityId,
      userId: event.userId,
    );
    await result.fold(
      (failure) async => emit(CommunitiesError(message: failure.message)),
      (_) async => _refreshMembersAndRequests(event.communityId, emit),
    );
  }

  Future<void> _onRejectJoinRequest(
    RejectJoinRequest event,
    Emitter<CommunitiesState> emit,
  ) async {
    final result = await _repository.rejectJoinRequest(
      communityId: event.communityId,
      userId: event.userId,
    );
    await result.fold(
      (failure) async => emit(CommunitiesError(message: failure.message)),
      (_) async => _refreshMembersAndRequests(event.communityId, emit),
    );
  }

  Future<void> _onModerateMember(
    ModerateMember event,
    Emitter<CommunitiesState> emit,
  ) async {
    late final Either<Failure, void> result;
    switch (event.action) {
      case MemberModerationAction.promoteToAdmin:
        result = await _repository.updateMemberRole(
          communityId: event.communityId,
          userId: event.userId,
          newRole: CommunityRole.admin,
        );
        break;
      case MemberModerationAction.demoteToMember:
        result = await _repository.updateMemberRole(
          communityId: event.communityId,
          userId: event.userId,
          newRole: CommunityRole.member,
        );
        break;
      case MemberModerationAction.mute:
        result = await _repository.updateMemberModeration(
          communityId: event.communityId,
          userId: event.userId,
          isMuted: true,
        );
        break;
      case MemberModerationAction.unmute:
        result = await _repository.updateMemberModeration(
          communityId: event.communityId,
          userId: event.userId,
          isMuted: false,
        );
        break;
      case MemberModerationAction.ban:
        result = await _repository.updateMemberModeration(
          communityId: event.communityId,
          userId: event.userId,
          isBanned: true,
        );
        break;
      case MemberModerationAction.remove:
        result = await _repository.removeMember(
          communityId: event.communityId,
          userId: event.userId,
        );
        break;
      case MemberModerationAction.grantTips:
        result = await _repository.updateMemberModeration(
          communityId: event.communityId,
          userId: event.userId,
          canWriteTips: true,
        );
        break;
      case MemberModerationAction.revokeTips:
        result = await _repository.updateMemberModeration(
          communityId: event.communityId,
          userId: event.userId,
          canWriteTips: false,
        );
        break;
      case MemberModerationAction.grantAnnouncements:
        result = await _repository.updateMemberModeration(
          communityId: event.communityId,
          userId: event.userId,
          canWriteAnnouncements: true,
        );
        break;
      case MemberModerationAction.revokeAnnouncements:
        result = await _repository.updateMemberModeration(
          communityId: event.communityId,
          userId: event.userId,
          canWriteAnnouncements: false,
        );
        break;
    }

    await result.fold(
      (failure) async => emit(CommunitiesError(message: failure.message)),
      (_) async => _refreshMembersAndRequests(event.communityId, emit),
    );
  }

  /// Reload the members list (and pending requests) into the current detail
  /// state after a moderation / approval action.
  Future<void> _refreshMembersAndRequests(
    String communityId,
    Emitter<CommunitiesState> emit,
  ) async {
    final current = state;
    if (current is! CommunityDetailLoaded) return;

    final membersResult = await _repository.getCommunityMembers(communityId);
    final members = membersResult.fold(
      (_) => current.members,
      (m) => m,
    );

    final requestsResult = await _repository.getJoinRequests(communityId);
    final requests = requestsResult.fold(
      (_) => current.pendingRequests,
      (r) => r,
    );

    if (state is CommunityDetailLoaded) {
      emit((state as CommunityDetailLoaded)
          .copyWith(members: members, pendingRequests: requests));
    }
  }

  Future<void> _onSeedSampleCommunities(
    SeedSampleCommunities event,
    Emitter<CommunitiesState> emit,
  ) async {
    try {
      await _remoteDataSource.seedSampleCommunities();
    } catch (e) {
      debugPrint('Error seeding communities: $e');
    }
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    return super.close();
  }
}
