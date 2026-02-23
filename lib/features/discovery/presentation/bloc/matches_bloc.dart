import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../profile/data/models/profile_model.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../domain/entities/match.dart' as domain;
import '../../domain/usecases/get_matches.dart';
import '../../domain/repositories/discovery_repository.dart';
import 'matches_event.dart';
import 'matches_state.dart';

/// Matches BLoC
///
/// Manages user's matches with real-time Firestore stream updates
class MatchesBloc extends Bloc<MatchesEvent, MatchesState> {
  final GetMatches getMatches;
  final DiscoveryRepository repository;
  final ProfileRepository profileRepository;

  StreamSubscription<QuerySnapshot>? _matchesStream1;
  StreamSubscription<QuerySnapshot>? _matchesStream2;
  String? _currentUserId;
  Timer? _streamDebounce;

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

  Future<void> _onLoadMatches(
    MatchesLoadRequested event,
    Emitter<MatchesState> emit,
  ) async {
    emit(const MatchesLoading());
    _currentUserId = event.userId;

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
    } catch (e) {
      debugPrint('[Matches] Error loading matches: $e');
      emit(MatchesError('Failed to load matches: $e'));
    }
  }

  /// Load profiles for all users involved in matches using batched whereIn queries
  Future<Map<String, Profile>> _loadProfiles(
    List<domain.Match> matches,
    String currentUserId,
  ) async {
    final Map<String, Profile> profiles = {};
    final userIds = <String>{currentUserId};

    for (final match in matches) {
      userIds.add(match.userId1);
      userIds.add(match.userId2);
    }

    final idList = userIds.toList();

    // Batch-fetch profiles using whereIn (max 10 per query) + parallel execution
    // This replaces N individual document reads with ceil(N/10) queries
    final futures = <Future<QuerySnapshot<Map<String, dynamic>>>>[];
    for (var i = 0; i < idList.length; i += 10) {
      final batch = idList.sublist(
        i,
        i + 10 > idList.length ? idList.length : i + 10,
      );
      futures.add(
        FirebaseFirestore.instance
            .collection('profiles')
            .where(FieldPath.documentId, whereIn: batch)
            .get(),
      );
    }

    try {
      final results = await Future.wait(futures);
      for (final snapshot in results) {
        for (final doc in snapshot.docs) {
          try {
            final profile = ProfileModel.fromFirestore(doc);
            profiles[doc.id] = profile;
          } catch (e) {
            debugPrint('Failed to parse profile for ${doc.id}: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Batch profile fetch failed, falling back to individual: $e');
      await Future.wait(
        userIds.map((uid) async {
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
    _matchesStream1 = FirebaseFirestore.instance
        .collection('matches')
        .where('userId1', isEqualTo: userId)
        .snapshots()
        .listen(
      (snapshot) {
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
    _matchesStream2 = FirebaseFirestore.instance
        .collection('matches')
        .where('userId2', isEqualTo: userId)
        .snapshots()
        .listen(
      (snapshot) {
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
              user1Seen: event.userId == match.userId1 ? true : match.user1Seen,
              user2Seen: event.userId == match.userId2 ? true : match.user2Seen,
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
