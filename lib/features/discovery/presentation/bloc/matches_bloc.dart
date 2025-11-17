import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_matches.dart';
import '../../domain/repositories/discovery_repository.dart';
import 'matches_event.dart';
import 'matches_state.dart';

/// Matches BLoC
///
/// Manages user's matches
class MatchesBloc extends Bloc<MatchesEvent, MatchesState> {
  final GetMatches getMatches;
  final DiscoveryRepository repository;

  MatchesBloc({
    required this.getMatches,
    required this.repository,
  }) : super(const MatchesInitial()) {
    on<MatchesLoadRequested>(_onLoadMatches);
    on<MatchesRefreshRequested>(_onRefreshMatches);
    on<MatchMarkedAsSeen>(_onMarkAsSeen);
    on<MatchUnmatchRequested>(_onUnmatch);
  }

  Future<void> _onLoadMatches(
    MatchesLoadRequested event,
    Emitter<MatchesState> emit,
  ) async {
    emit(const MatchesLoading());

    final result = await getMatches(
      GetMatchesParams(
        userId: event.userId,
        activeOnly: event.activeOnly,
      ),
    );

    result.fold(
      (failure) => emit(const MatchesError('Failed to load matches')),
      (matches) {
        if (matches.isEmpty) {
          emit(const MatchesEmpty());
        } else {
          emit(MatchesLoaded(matches: matches));
        }
      },
    );
  }

  Future<void> _onRefreshMatches(
    MatchesRefreshRequested event,
    Emitter<MatchesState> emit,
  ) async {
    add(MatchesLoadRequested(userId: event.userId));
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
}
