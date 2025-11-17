import '../../../profile/domain/entities/profile.dart';
import '../../domain/entities/match.dart';

/// Matches States
abstract class MatchesState {
  const MatchesState();
}

/// Initial state
class MatchesInitial extends MatchesState {
  const MatchesInitial();
}

/// Loading matches
class MatchesLoading extends MatchesState {
  const MatchesLoading();
}

/// Matches loaded successfully
class MatchesLoaded extends MatchesState {
  final List<Match> matches;
  final Map<String, Profile> profiles; // Cached profiles for matches

  const MatchesLoaded({
    required this.matches,
    this.profiles = const {},
  });

  /// Get new matches (not seen by user)
  List<Match> getNewMatches(String userId) {
    return matches.where((match) => match.isNewMatch(userId)).toList();
  }

  /// Get match count
  int get matchCount => matches.length;

  /// Get new match count
  int getNewMatchCount(String userId) {
    return getNewMatches(userId).length;
  }

  /// Copy with updated fields
  MatchesLoaded copyWith({
    List<Match>? matches,
    Map<String, Profile>? profiles,
  }) {
    return MatchesLoaded(
      matches: matches ?? this.matches,
      profiles: profiles ?? this.profiles,
    );
  }
}

/// Matches empty
class MatchesEmpty extends MatchesState {
  const MatchesEmpty();
}

/// Match action in progress
class MatchActionInProgress extends MatchesState {
  const MatchActionInProgress();
}

/// Error state
class MatchesError extends MatchesState {
  final String message;

  const MatchesError(this.message);
}
