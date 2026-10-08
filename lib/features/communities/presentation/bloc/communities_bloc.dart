import 'dart:async';
import 'dart:math' as math;

import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    on<LoadManagedCommunities>(_onLoadManagedCommunities);
    on<LoadRecommendedCommunities>(_onLoadRecommendedCommunities);
    on<LoadCommunityDetail>(_onLoadCommunityDetail);
    on<LoadCommunityMembers>(_onLoadCommunityMembers);
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

  // Last-result keys (see LastResultCache): per tab, per signed-in user.
  static const String _kDiscoverKey = 'communities_discover_v1';
  static const String _kJoinedKey = 'communities_joined_v1';
  static const String _kMyKey = 'communities_my_v1';

  /// Personalisation remembered from the last LoadCommunities that carried it.
  String? _nearCity;
  String? _nearLanguage;

  /// Per-session memo of the personalised, unfiltered Discover page keyed by
  /// (uid, city, language): re-loads with the same inputs (after join/leave,
  /// the "All" chip, re-opening the screen) re-use it instead of re-running
  /// three queries. Static because the bloc is a factory (one per screen).
  static final Map<String, _DiscoverMemo> _discoverMemo = {};
  static const Duration _discoverMemoTtl = Duration(minutes: 10);

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

    if (event.nearCity != null) _nearCity = event.nearCity;
    if (event.nearLanguage != null) _nearLanguage = event.nearLanguage;

    final unfiltered = event.type == null &&
        (event.language == null || event.language!.isEmpty) &&
        (event.city == null || event.city!.isEmpty) &&
        (event.searchQuery == null || event.searchQuery!.isEmpty);

    if (unfiltered) {
      await _loadPersonalisedDiscover(emit, force: event.forceRefresh);
      return;
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
      (communities) => _emitDiscover(communities, emit),
    );
  }

  /// Unfiltered Discover: local (viewer's city) + language + worldwide fill,
  /// in parallel and de-duplicated. Paints the last-rendered list from the
  /// local cache first, then the server result; memoised for the session.
  Future<void> _loadPersonalisedDiscover(
    Emitter<CommunitiesState> emit, {
    bool force = false,
  }) async {
    final uid = _currentUid();
    final memoKey = '$uid|${_nearCity ?? ''}|${_nearLanguage ?? ''}';
    final memo = _discoverMemo[memoKey];
    if (!force &&
        memo != null &&
        DateTime.now().difference(memo.at) < _discoverMemoTtl) {
      _emitDiscoverDisplay(memo.display, emit,
          hasMore: memo.hasMore, cursor: memo.cursor);
      return;
    }

    // Instant paint: exactly what this tab showed last time (by id, from the
    // local cache). Only a NON-EMPTY result, and only into an empty slice.
    List<Community> painted = const [];
    final cur0 = state;
    if (cur0 is! CommunitiesLoaded || cur0.communities.isEmpty) {
      final cached = await _remoteDataSource.loadLastResult(_kDiscoverKey);
      final cur = state;
      if (cached.isNotEmpty &&
          (cur is! CommunitiesLoaded || cur.communities.isEmpty)) {
        painted = cached;
        _emitDiscoverDisplay(cached, emit, hasMore: true, cursor: null);
      }
    }

    DiscoverCommunities page;
    try {
      page = await _remoteDataSource.getDiscoverCommunities(
        city: _nearCity,
        language: _nearLanguage,
        limit: _communitiesPageSize,
      );
    } catch (e) {
      debugPrint('LoadCommunities failed: $e');
      if (state is! CommunitiesLoaded) {
        emit(CommunitiesError(message: e.toString()));
      }
      return;
    }

    // Local first, then language, then worldwide — each group in random order
    // for variety. Items already painted from the cache keep their position
    // (no visible reshuffle); new ones follow.
    var display = <Community>[
      ..._shuffled(page.local),
      ..._shuffled(page.language),
      ..._shuffled(page.worldwide),
    ];
    if (painted.isNotEmpty) {
      final byId = {for (final c in display) c.id: c};
      final kept = [
        for (final c in painted)
          if (byId.containsKey(c.id)) byId[c.id]!,
      ];
      final keptIds = kept.map((c) => c.id).toSet();
      display = [...kept, ...display.where((c) => !keptIds.contains(c.id))];
    }

    _emitDiscoverDisplay(display, emit,
        hasMore: page.worldwidePageFull, cursor: page.worldwideCursor);
    _discoverMemo[memoKey] = _DiscoverMemo(
      display: display,
      hasMore: page.worldwidePageFull,
      cursor: page.worldwideCursor,
      at: DateTime.now(),
    );
    unawaited(_remoteDataSource.saveLastResult(
        _kDiscoverKey, display.map((c) => c.id)));
  }

  String _currentUid() {
    try {
      return FirebaseAuth.instance.currentUser?.uid ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Emit a Discover page (random order, keyset cursor) merged onto current
  /// state. Used by the filtered (type / search) loads.
  void _emitDiscover(List<Community> communities, Emitter<CommunitiesState> emit) {
    _emitDiscoverDisplay(
      _shuffled(communities),
      emit,
      hasMore: communities.length >= _communitiesPageSize,
      cursor: _oldestActivity(communities),
    );
  }

  void _emitDiscoverDisplay(
    List<Community> display,
    Emitter<CommunitiesState> emit, {
    required bool hasMore,
    required DateTime? cursor,
  }) {
    final languageCircles =
        display.where((c) => c.type == CommunityType.languageCircle).toList();
    final cur = state;
    final base = cur is CommunitiesLoaded ? cur : const CommunitiesLoaded();
    emit(CommunitiesLoaded(
      communities: display,
      userCommunities: base.userCommunities,
      recommended: base.recommended,
      languageCircles: languageCircles,
      hasMoreCommunities: hasMore,
      isLoadingMore: false,
      // Explicit (copyWith can't clear it): a cached paint has no cursor
      // yet, so endless scroll waits for the server pass.
      communitiesCursor: cursor,
      managedCommunities: base.managedCommunities,
      managedLoaded: base.managedLoaded,
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
        final fresh = page.where((c) => !existingIds.contains(c.id)).toList();
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

    // Instant paint of what this tab showed last time (local cache, by id) —
    // only non-empty, only into an empty slice; the server pass follows.
    final c0 = state;
    if (c0 is! CommunitiesLoaded || c0.userCommunities.isEmpty) {
      final cached = await _remoteDataSource.loadLastResult(_kJoinedKey);
      final c = state;
      if (cached.isNotEmpty &&
          (c is! CommunitiesLoaded || c.userCommunities.isEmpty)) {
        final b = c is CommunitiesLoaded ? c : const CommunitiesLoaded();
        emit(b.copyWith(userCommunities: cached));
      }
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
        final rec =
            base.recommended.where((c) => !joinedIds.contains(c.id)).toList();
        emit(base.copyWith(userCommunities: userCommunities, recommended: rec));
        unawaited(_remoteDataSource.saveLastResult(
            _kJoinedKey, userCommunities.map((c) => c.id)));
      },
    );
  }

  Future<void> _onLoadManagedCommunities(
    LoadManagedCommunities event,
    Emitter<CommunitiesState> emit,
  ) async {
    // Instant paint of what this tab showed last time (local cache, by id) —
    // only non-empty, only into an empty slice; the server pass follows.
    final c0 = state;
    if (c0 is! CommunitiesLoaded || c0.managedCommunities.isEmpty) {
      final cached = await _remoteDataSource.loadLastResult(_kMyKey);
      final c = state;
      if (cached.isNotEmpty &&
          (c is! CommunitiesLoaded || c.managedCommunities.isEmpty)) {
        final b = c is CommunitiesLoaded ? c : const CommunitiesLoaded();
        emit(b.copyWith(managedCommunities: cached, managedLoaded: true));
      }
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
        unawaited(_remoteDataSource.saveLastResult(
            _kMyKey, managed.map((c) => c.id)));
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
      city: event.city,
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

  /// Roster page size for the lazily-loaded Members sheet.
  static const int _membersPageSize = 50;

  /// The last community shown in detail — lets a re-load without a community
  /// (e.g. right after joining) repaint instantly instead of re-fetching.
  Community? _lastDetailCommunity;
  String? _detailUserId;

  Future<void> _onLoadCommunityDetail(
    LoadCommunityDetail event,
    Emitter<CommunitiesState> emit,
  ) async {
    // Prefer the community the caller already has (the detail screen always
    // passes it). Only re-fetch when it wasn't provided. This eliminates the
    // "Unable to load community" that appeared right after creating one.
    Community? community = event.community ??
        (_lastDetailCommunity?.id == event.communityId
            ? _lastDetailCommunity
            : null);
    if (community == null) {
      emit(const CommunitiesLoading());
      final communityResult =
          await _repository.getCommunityById(event.communityId);
      community = communityResult.fold((_) => null, (c) => c);
      if (community == null) {
        emit(const CommunitiesError(message: 'Unable to load community')); // i18n-ignore: dev text; UI shows via showUserError
        return;
      }
    }
    _lastDetailCommunity = community;

    // Re-apply any messages that already streamed in for THIS community
    // before the detail finished loading (otherwise they'd be lost).
    final cached = _subscribedCommunityId == event.communityId
        ? _latestMessages
        : const <CommunityMessage>[];

    // Paint the detail IMMEDIATELY with the known community. The roster is
    // NOT loaded here (it is unbounded for big communities) — the Members
    // sheet loads it lazily, page by page. Membership/role comes from the
    // user's single members/{uid} doc below.
    final prev = state;
    final same =
        prev is CommunityDetailLoaded && prev.community.id == event.communityId
            ? prev
            : null;
    emit(CommunityDetailLoaded(
      community: community,
      messages:
          same != null && same.messages.isNotEmpty ? same.messages : cached,
      pendingRequests: same?.pendingRequests ?? const [],
    ));

    final uid = event.userId ?? _detailUserId;
    if (event.userId != null) _detailUserId = event.userId;
    CommunityMember? me;
    if (uid != null && uid.isNotEmpty) {
      final r = await _repository.getMember(
          communityId: event.communityId, userId: uid);
      me = r.fold((_) => null, (m) => m);
    }
    final s = state;
    if (s is CommunityDetailLoaded && s.community.id == event.communityId) {
      emit(s.copyWith(
        myMembership: me,
        clearMyMembership: me == null,
        membershipLoaded: true,
      ));
    }
  }

  /// Lazily load the roster (first page, or the next one when [loadMore]).
  Future<void> _onLoadCommunityMembers(
    LoadCommunityMembers event,
    Emitter<CommunitiesState> emit,
  ) async {
    final cur = state;
    if (cur is! CommunityDetailLoaded ||
        cur.community.id != event.communityId ||
        cur.isLoadingMembers) {
      return;
    }
    if (event.loadMore && (!cur.membersLoaded || !cur.hasMoreMembers)) return;
    if (!event.loadMore && cur.membersLoaded) return;

    emit(cur.copyWith(isLoadingMembers: true));
    final cursor = event.loadMore && cur.members.isNotEmpty
        ? cur.members.last.joinedAt
        : null;
    final result = await _repository.getCommunityMembers(
      event.communityId,
      limit: _membersPageSize,
      startAfterJoinedAt: cursor,
    );
    final s = state;
    if (s is! CommunityDetailLoaded || s.community.id != event.communityId) {
      return;
    }
    result.fold(
      (failure) {
        debugPrint('LoadCommunityMembers failed: ${failure.message}');
        emit(s.copyWith(isLoadingMembers: false, membersLoaded: true));
      },
      (page) {
        final seen = s.members.map((m) => m.userId).toSet();
        final merged = event.loadMore
            ? [...s.members, ...page.where((m) => !seen.contains(m.userId))]
            : page;
        emit(s.copyWith(
          members: merged,
          membersLoaded: true,
          isLoadingMembers: false,
          hasMoreMembers: page.length >= _membersPageSize,
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

        // A new community belongs in Discover right away.
        _discoverMemo.clear();
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
        add(LoadCommunityDetail(
            communityId: event.communityId, userId: event.userId));
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
    final result = await _repository.deleteCommunity(event.communityId);
    result.fold(
      (failure) => emit(CommunitiesError(message: failure.message)),
      (_) {
        _discoverMemo.clear();
        emit(CommunityDeleted(communityId: event.communityId));
      },
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
        // Re-read the CURRENT state — the live message stream may have already
        // emitted a CommunityDetailLoaded that includes the just-sent message
        // while sendMessage was in flight. Using the stale `currentState`
        // captured before the send would clobber that update and make the new
        // message (chat / tip / announcement) disappear until re-entry.
        final s = state;
        if (s is CommunityDetailLoaded) {
          emit(s.copyWith(isSending: false));
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

    _messagesSubscription =
        _repository.getCommunityMessages(event.communityId).listen(
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

    // Re-read only what the sheet has shown (bounded), in parallel with the
    // pending requests.
    final shown = current.members.length;
    final limit = shown <= _membersPageSize
        ? _membersPageSize
        : ((shown + _membersPageSize - 1) ~/ _membersPageSize) *
            _membersPageSize;
    final membersFuture =
        _repository.getCommunityMembers(communityId, limit: limit);
    final requestsFuture = _repository.getJoinRequests(communityId);
    final membersResult = await membersFuture;
    final requestsResult = await requestsFuture;

    final members = membersResult.fold(
      (_) => current.members,
      (m) => m,
    );
    final requests = requestsResult.fold(
      (_) => current.pendingRequests,
      (r) => r,
    );

    if (state is CommunityDetailLoaded) {
      emit((state as CommunityDetailLoaded).copyWith(
        members: members,
        pendingRequests: requests,
        membersLoaded: true,
        hasMoreMembers: membersResult.fold(
          (_) => current.hasMoreMembers,
          (m) => m.length >= limit,
        ),
      ));
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

class _DiscoverMemo {
  const _DiscoverMemo({
    required this.display,
    required this.hasMore,
    required this.cursor,
    required this.at,
  });
  final List<Community> display;
  final bool hasMore;
  final DateTime? cursor;
  final DateTime at;
}
