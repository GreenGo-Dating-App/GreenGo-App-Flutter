import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/cache/last_result_cache.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/blocked_users_service.dart';
import '../../../../core/services/user_directory_service.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../data/models/match_model.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../domain/entities/match.dart' as domain;
import '../../domain/repositories/discovery_repository.dart';
import '../../domain/usecases/get_matches.dart';
import 'matches_event.dart';
import 'matches_state.dart';

/// Matches BLoC
///
/// Manages user's matches with real-time Firestore stream updates
class MatchesBloc extends Bloc<MatchesEvent, MatchesState> {

  MatchesBloc({
    required this.getMatches,
    required this.repository,
    required this.profileRepository,
  }) : super(const MatchesInitial()) {
    on<MatchesLoadRequested>(_onLoadMatches);
    on<MatchesRefreshRequested>(_onRefreshMatches);
    on<MatchMarkedAsSeen>(_onMarkAsSeen);
    on<MatchUnmatchRequested>(_onUnmatch);
    on<MatchesStreamUpdated>(_onStreamUpdated);
  }
  final GetMatches getMatches;
  final DiscoveryRepository repository;
  final ProfileRepository profileRepository;

  StreamSubscription<QuerySnapshot>? _matchesStream1;
  StreamSubscription<QuerySnapshot>? _matchesStream2;
  String? _currentUserId;
  Timer? _streamDebounce;

  Future<void> _onLoadMatches(
    MatchesLoadRequested event,
    Emitter<MatchesState> emit,
  ) async {
    emit(const MatchesLoading());
    _currentUserId = event.userId;

    // Paint what the user saw last time (local cache only, no network), then
    // replace it with the server result below. Never paints an empty list.
    await _paintCached(event.userId, event.activeOnly, emit);

    await _loadAndEmitMatches(event.userId, event.activeOnly, emit);

    // Start listening for real-time match updates
    _startMatchesStream(event.userId);
  }

  /// Core method to load matches + profiles and emit state
  Future<void> _loadAndEmitMatches(
    String userId,
    bool activeOnly,
    Emitter<MatchesState> emit,
  ) async {
    try {
      final result = await getMatches(
        GetMatchesParams(userId: userId, activeOnly: activeOnly),
      );

      if (result.isLeft()) {
        debugPrint('[Matches] Failed to load matches');
        emit(const MatchesError('Failed to load matches'));
        return;
      }

      final matches = result.getOrElse(() => []);
      debugPrint('[Matches] Loaded ${matches.length} matches for $userId');

      if (matches.isEmpty) {
        emit(const MatchesEmpty());
      } else {
        final profiles = await _loadProfiles(matches, userId);
        debugPrint('[Matches] Loaded ${profiles.length} profiles');
        emit(MatchesLoaded(matches: matches, profiles: profiles));
      }
      unawaited(LastResultCache.saveIds(
          _cacheKey, matches.map((m) => m.matchId)));
    } catch (e) {
      debugPrint('[Matches] Error loading matches: $e');
      emit(MatchesError('Failed to load matches: $e'));
    }
  }

  static const String _cacheKey = 'matches_v1';

  /// Live listeners only watch the newest matches: a new or changed match is
  /// always among them, and an unbounded listener streamed every match doc.
  static const int _listenLimit = 50;

  /// The last server-rendered matches, read from the LOCAL Firestore cache by
  /// id, with the same active / deactivated / blocked rules as the server
  /// load. Emits only when there is something to show and the state is still
  /// the loading skeleton.
  Future<void> _paintCached(
    String userId,
    bool activeOnly,
    Emitter<MatchesState> emit,
  ) async {
    try {
      final docs = await LastResultCache.loadDocs(
        _cacheKey,
        FirebaseFirestore.instance.collection('matches'),
      );
      if (docs.isEmpty) return;
      Set<String> blocked = const {};
      if (di.sl.isRegistered<BlockedUsersService>()) {
        blocked = await di.sl<BlockedUsersService>().getBlockedUserIds(userId);
      }
      final matches = <domain.Match>[];
      for (final doc in docs) {
        final data = doc.data();
        if (data == null) continue;
        if (data['userId1'] != userId && data['userId2'] != userId) continue;
        if (activeOnly) {
          if (data['isActive'] == false) continue;
          final deactivatedFor = data['deactivatedFor'];
          if (deactivatedFor is Map && deactivatedFor[userId] == true) continue;
        }
        try {
          final m = MatchModel.fromFirestore(doc);
          if (blocked.contains(m.getOtherUserId(userId))) continue;
          matches.add(m);
        } catch (_) {}
      }
      if (matches.isEmpty || state is! MatchesLoading) return;
      matches.sort((a, b) => b.matchedAt.compareTo(a.matchedAt));
      final dir = UserDirectoryService.instance;
      final profiles = <String, Profile>{};
      for (final m in matches) {
        for (final uid in [m.userId1, m.userId2]) {
          final p = dir.cachedProfile(uid);
          if (p != null) profiles[uid] = p;
        }
      }
      // Without at least the other users' cached profiles the cards would
      // render blank; let the server load paint instead.
      if (profiles.isEmpty) return;
      emit(MatchesLoaded(matches: matches, profiles: profiles));
    } catch (e) {
      debugPrint('[Matches] Cached paint skipped: $e');
    }
  }

  /// Profiles for all users involved in matches, through the shared,
  /// cache-first, batched user directory (memory → disk → Firestore cache →
  /// server `whereIn` of 30, coalesced with other callers).
  Future<Map<String, Profile>> _loadProfiles(
    List<domain.Match> matches,
    String currentUserId,
  ) async {
    final profiles = <String, Profile>{};
    final userIds = <String>{currentUserId};

    for (final match in matches) {
      userIds.add(match.userId1);
      userIds.add(match.userId2);
    }

    var missing = userIds.toSet();
    try {
      final resolved =
          await UserDirectoryService.instance.resolveProfiles(userIds);
      resolved.forEach((uid, profile) {
        if (profile != null) profiles[uid] = profile;
      });
      // Omitted = failed to load (null = confirmed deleted, don't retry).
      missing = userIds.where((u) => !resolved.containsKey(u)).toSet();
    } catch (e) {
      debugPrint('[Matches] Directory profile fetch failed: $e');
    }

    if (missing.isNotEmpty) {
      await Future.wait(
        missing.map((uid) async {
          try {
            final result = await profileRepository.getProfile(uid);
            result.fold(
              (_) {},
              (profile) => profiles[uid] = profile,
            );
          } catch (e) {
            debugPrint('Failed to load profile for $uid: $e');
          }
        }),
      );
    }

    return profiles;
  }

  /// Start listening for new matches in real-time using two user-scoped queries
  void _startMatchesStream(String userId) {
    _matchesStream1?.cancel();
    _matchesStream2?.cancel();

    // Stream 1: matches where user is userId1
    var first1 = true;
    _matchesStream1 = FirebaseFirestore.instance
        .collection('matches')
        .where('userId1', isEqualTo: userId)
        .orderBy('matchedAt', descending: true)
        .limit(_listenLimit)
        .snapshots()
        .listen(
      (snapshot) {
        // The first snapshot is the current state the load above just
        // rendered — reloading on it doubled every open.
        if (first1) {
          first1 = false;
          return;
        }
        final hasNewOrModified = snapshot.docChanges.any((change) =>
            change.type == DocumentChangeType.added ||
            change.type == DocumentChangeType.modified);
        if (hasNewOrModified) {
          debugPrint('Match stream1 update detected - debounced refresh');
          _debouncedStreamUpdate(userId);
        }
      },
      onError: (error) => debugPrint('Matches stream1 error: $error'),
    );

    // Stream 2: matches where user is userId2
    var first2 = true;
    _matchesStream2 = FirebaseFirestore.instance
        .collection('matches')
        .where('userId2', isEqualTo: userId)
        .orderBy('matchedAt', descending: true)
        .limit(_listenLimit)
        .snapshots()
        .listen(
      (snapshot) {
        // The first snapshot is the current state the load above just
        // rendered — reloading on it doubled every open.
        if (first2) {
          first2 = false;
          return;
        }
        final hasNewOrModified = snapshot.docChanges.any((change) =>
            change.type == DocumentChangeType.added ||
            change.type == DocumentChangeType.modified);
        if (hasNewOrModified) {
          debugPrint('Match stream2 update detected - debounced refresh');
          _debouncedStreamUpdate(userId);
        }
      },
      onError: (error) => debugPrint('Matches stream2 error: $error'),
    );
  }

  /// Debounce stream updates to avoid rapid-fire reloads (e.g. when multiple
  /// match documents change at once)
  void _debouncedStreamUpdate(String userId) {
    _streamDebounce?.cancel();
    _streamDebounce = Timer(const Duration(milliseconds: 500), () {
      add(MatchesStreamUpdated(userId));
    });
  }

  Future<void> _onStreamUpdated(
    MatchesStreamUpdated event,
    Emitter<MatchesState> emit,
  ) async {
    await _loadAndEmitMatches(event.userId, true, emit);
  }

  Future<void> _onRefreshMatches(
    MatchesRefreshRequested event,
    Emitter<MatchesState> emit,
  ) async {
    // Directly load and emit instead of dispatching another event,
    // so RefreshIndicator properly waits for completion
    await _loadAndEmitMatches(event.userId, true, emit);
  }

  Future<void> _onMarkAsSeen(
    MatchMarkedAsSeen event,
    Emitter<MatchesState> emit,
  ) async {
    if (state is! MatchesLoaded) return;

    final currentState = state as MatchesLoaded;

    final result = await repository.markMatchAsSeen(
      matchId: event.matchId,
      userId: event.userId,
    );

    result.fold(
      (failure) {
        // Keep current state on error
      },
      (_) {
        // Update the match in the list
        final updatedMatches = currentState.matches.map((match) {
          if (match.matchId == event.matchId) {
            return match.copyWith(
              user1Seen: event.userId == match.userId1 || match.user1Seen,
              user2Seen: event.userId == match.userId2 || match.user2Seen,
            );
          }
          return match;
        }).toList();

        emit(currentState.copyWith(matches: updatedMatches));
      },
    );
  }

  Future<void> _onUnmatch(
    MatchUnmatchRequested event,
    Emitter<MatchesState> emit,
  ) async {
    if (state is! MatchesLoaded) return;

    final currentState = state as MatchesLoaded;

    emit(const MatchActionInProgress());

    final result = await repository.unmatch(
      matchId: event.matchId,
      userId: event.userId,
    );

    result.fold(
      (failure) {
        emit(const MatchesError('Failed to unmatch'));
        emit(currentState); // Revert to previous state
      },
      (_) {
        // Remove match from list
        final updatedMatches = currentState.matches
            .where((match) => match.matchId != event.matchId)
            .toList();

        if (updatedMatches.isEmpty) {
          emit(const MatchesEmpty());
        } else {
          emit(currentState.copyWith(matches: updatedMatches));
        }
      },
    );
  }

  @override
  Future<void> close() {
    _streamDebounce?.cancel();
    _matchesStream1?.cancel();
    _matchesStream2?.cancel();
    return super.close();
  }
}
