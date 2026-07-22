import 'dart:async';
import 'dart:math' as math;

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/services/session_cache_gate.dart';
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
    on<LoadManagedCommunities>(_onLoadManagedCommunities);
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

  /// Discover page size — fetch up to 50 public communities per page and show
  /// them in random order for variety (see [_shuffled]).
  static const int _communitiesPageSize = 50;

  final math.Random _rng = math.Random();

  /// A shuffled COPY of [items] (never mutates the source list).
  List<Community> _shuffled(List<Community> items) {
    final copy = [...items]..shuffle(_rng);
    return copy;
  }

  /// The oldest `lastActivityAt` in [items] — the keyset cursor for the next
  /// page (kept separate from the shuffled display order).
  DateTime? _oldestActivity(List<Community> items) {
    DateTime? min;
    for (final c in items) {
      final a = c.lastActivityAt;
      if (a == null) continue;
      if (min == null || a.isBefore(min)) min = a;
    }
    return min;
  }

  StreamSubscription? _messagesSubscription;

  /// Latest community messages from the live stream, cached so they survive the
  /// LoadCommunityDetail ⇄ SubscribeToCommunityMessages race. Bloc v8 runs
  /// different event handlers concurrently, so the first snapshot can arrive
  /// while state is still Loading — dropping it left Tips/Announcements/Chat
  /// permanently empty (a static seeded set never re-emits). We stash the
  /// messages here and re-apply them the moment CommunityDetailLoaded is built.
  String? _subscribedCommunityId;
  List<CommunityMessage> _latestMessages = const [];

  Future<void> _onLoadCommunities(
    LoadCommunities event,
    Emitter<CommunitiesState> emit,
  ) async {
    // Only show the full-screen spinner on the FIRST load. Every emit below
    // MERGES onto the CURRENT state (copyWith) rather than a snapshot captured
    // before the await, so concurrent loads (My/Joined/Recommended) can't be
    // clobbered by a stale captured value.
    if (state is! CommunitiesLoaded) {
      emit(const CommunitiesLoading());
    }

    // CACHE-THEN-NETWORK — but only ONCE the server has been hit this session.
    // On a fresh app open the gate is cold, so we go NETWORK-FIRST (fresh data);
    // subsequent loads paint instantly from the cache, then reconcile.
    if (SessionCacheGate.isWarm(SessionCacheGate.communitiesDiscover)) {
      final cached = await _repository.getCommunities(
        type: event.type,
        language: event.language,
        city: event.city,
        searchQuery: event.searchQuery,
        limit: _communitiesPageSize,
        preferCache: true,
      );
      cached.fold((_) {}, (list) {
        if (list.isNotEmpty) _emitDiscover(list, emit);
      });
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
        if (state is! CommunitiesLoaded) {
          emit(CommunitiesError(message: failure.message));
        }
      },
      (communities) {
        _emitDiscover(communities, emit);
        SessionCacheGate.markWarm(SessionCacheGate.communitiesDiscover);
      },
    );
  }

  /// Emit a Discover page (random order, keyset cursor) merged onto current
  /// state. Shared by the cache and server passes of _onLoadCommunities.
  void _emitDiscover(List<Community> communities, Emitter<CommunitiesState> emit) {
    final display = _shuffled(communities);
    final languageCircles =
        display.where((c) => c.type == CommunityType.languageCircle).toList();
    final cur = state;
    final base = cur is CommunitiesLoaded ? cur : const CommunitiesLoaded();
    emit(base.copyWith(
      communities: display,
      languageCircles: languageCircles,
      hasMoreCommunities: communities.length >= _communitiesPageSize,
      isLoadingMore: false,
      communitiesCursor: _oldestActivity(communities),
    ));
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

    final cursor = currentState.communitiesCursor;
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
        // Dedupe by id in case a boundary item overlaps. Append the (shuffled)
        // fresh chunk so already-seen items don't reorder mid-scroll.
        final existingIds = s.communities.map((c) => c.id).toSet();
        final fresh =
            page.where((c) => !existingIds.contains(c.id)).toList();
        final merged = [...s.communities, ..._shuffled(fresh)];
        // Advance the cursor to the oldest across old + new.
        final pageOldest = _oldestActivity(fresh);
        final newCursor = (pageOldest != null && pageOldest.isBefore(cursor))
            ? pageOldest
            : cursor;
        emit(s.copyWith(
          communities: merged,
          languageCircles: merged
              .where((c) => c.type == CommunityType.languageCircle)
              .toList(),
          hasMoreCommunities: page.length >= _communitiesPageSize,
          isLoadingMore: false,
          communitiesCursor: newCursor,
        ));
      },
    );
  }

  Future<void> _onLoadUserCommunities(
    LoadUserCommunities event,
    Emitter<CommunitiesState> emit,
  ) async {
    // Preserve current state data if available
    // Only blank to a spinner on the FIRST load; a refresh keeps the lists.
    if (state is! CommunitiesLoaded) {
      emit(const CommunitiesLoading());
    }

    // Network-first on a fresh open; cache-then-network once warm this session.
    if (SessionCacheGate.isWarm(SessionCacheGate.communitiesJoined)) {
      final cached =
          await _repository.getUserCommunities(event.userId, preferCache: true);
      cached.fold((_) {}, (list) {
        if (list.isNotEmpty) {
          final c = state;
          final b = c is CommunitiesLoaded ? c : const CommunitiesLoaded();
          emit(b.copyWith(userCommunities: list));
        }
      });
    }

    final result = await _repository.getUserCommunities(event.userId);

    // Merge onto the CURRENT state so a concurrent load can't be clobbered.
    final cur = state;
    final base = cur is CommunitiesLoaded ? cur : const CommunitiesLoaded();
    result.fold(
      // A failing "Joined" query must not blank the other tabs; show it empty.
      (failure) {
        debugPrint('LoadUserCommunities failed: ${failure.message}');
        emit(base.copyWith(userCommunities: const []));
      },
      (userCommunities) {
        // Keep recommendations free of communities the user is already in, even
        // if recommended loaded first (order-independent exclusion).
        final joinedIds = userCommunities.map((c) => c.id).toSet();
        final rec = base.recommended
            .where((c) => !joinedIds.contains(c.id))
            .toList();
        emit(base.copyWith(userCommunities: userCommunities, recommended: rec));
        SessionCacheGate.markWarm(SessionCacheGate.communitiesJoined);
      },
    );
  }

  Future<void> _onLoadManagedCommunities(
    LoadManagedCommunities event,
    Emitter<CommunitiesState> emit,
  ) async {
    // Network-first on a fresh open; cache-then-network once warm this session.
    if (SessionCacheGate.isWarm(SessionCacheGate.communitiesMy)) {
      final cached = await _repository.getCreatedCommunities(event.userId,
          preferCache: true);
      cached.fold((_) {}, (list) {
        if (list.isNotEmpty) {
          final c = state;
          final b = c is CommunitiesLoaded ? c : const CommunitiesLoaded();
          emit(b.copyWith(managedCommunities: list, managedLoaded: true));
        }
      });
    }

    final result = await _repository.getCreatedCommunities(event.userId);

    result.fold(
      (failure) {
        // A failing "My communities" query must not blank the other tabs.
        debugPrint('LoadManagedCommunities failed: ${failure.message}');
        final s = state;
        if (s is CommunitiesLoaded) {
          emit(s.copyWith(managedCommunities: const [], managedLoaded: true));
        }
      },
      (managed) {
        final s = state;
        if (s is CommunitiesLoaded) {
          emit(s.copyWith(managedCommunities: managed, managedLoaded: true));
        } else {
          emit(CommunitiesLoaded(
            managedCommunities: managed,
            managedLoaded: true,
          ));
        }
        SessionCacheGate.markWarm(SessionCacheGate.communitiesMy);
      },
    );
  }

  Future<void> _onLoadRecommendedCommunities(
    LoadRecommendedCommunities event,
    Emitter<CommunitiesState> emit,
  ) async {
    final result = await _repository.getRecommendedCommunities(
      userId: event.userId,
      languages: event.languages,
      interests: event.interests,
    );

    // Merge onto the CURRENT state (copyWith) so we never clobber a concurrent
    // slice with a stale snapshot. A recommended failure just shows none.
    final cur = state;
    final base = cur is CommunitiesLoaded ? cur : const CommunitiesLoaded();
    result.fold(
      (failure) {
        debugPrint('LoadRecommendedCommunities failed: ${failure.message}');
        emit(base.copyWith(recommended: const []));
      },
      (recommended) {
        // Exclude communities the user has ALREADY joined (the datasource no
        // longer runs a separate members scan for this — we filter here against
        // the already-loaded joined set).
        final joinedIds = base.userCommunities.map((c) => c.id).toSet();
        final filtered =
            recommended.where((c) => !joinedIds.contains(c.id)).toList();
        emit(base.copyWith(recommended: filtered));
      },
    );
  }

  Future<void> _onLoadCommunityDetail(
    LoadCommunityDetail event,
    Emitter<CommunitiesState> emit,
  ) async {
    emit(const CommunitiesLoading());

    // Prefer the community the caller already has (the detail screen always
    // passes it). Only re-fetch when it wasn't provided. This eliminates the
    // "Unable to load community" that appeared right after creating one.
    Community? community = event.community;
    if (community == null) {
      final communityResult =
          await _repository.getCommunityById(event.communityId);
      community = communityResult.fold((_) => null, (c) => c);
      if (community == null) {
        emit(const CommunitiesError(message: 'Unable to load community'));
        return;
      }
    }

    final membersResult =
        await _repository.getCommunityMembers(event.communityId);
    final members = membersResult.fold(
      (failure) => <CommunityMember>[],
      (members) => members,
    );

    // Re-apply any messages that already streamed in for THIS community
    // before the detail finished loading (otherwise they'd be lost).
    final cached = _subscribedCommunityId == event.communityId
        ? _latestMessages
        : const <CommunityMessage>[];

    emit(CommunityDetailLoaded(
      community: community,
      members: members,
      messages: cached,
      isMember: false,
    ));
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
    // Reset the cache for the new community so stale messages can't bleed over.
    _subscribedCommunityId = event.communityId;
    _latestMessages = const [];

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
    // Always cache — even if the detail state isn't ready yet — so the messages
    // survive to be applied when CommunityDetailLoaded is emitted.
    _latestMessages = event.messages;
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
