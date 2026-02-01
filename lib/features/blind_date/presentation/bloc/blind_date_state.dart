import 'package:equatable/equatable.dart';
import '../../domain/entities/blind_date.dart';

/// Blind Date States
abstract class BlindDateState extends Equatable {
  const BlindDateState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class BlindDateInitial extends BlindDateState {
  const BlindDateInitial();
}

/// Loading state
class BlindDateLoading extends BlindDateState {
  const BlindDateLoading();
}

/// Error state
class BlindDateError extends BlindDateState {
  final String message;

  const BlindDateError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Blind date status loaded
class BlindDateStatusLoaded extends BlindDateState {
  final BlindDateProfile? profile;
  final bool isActive;

  const BlindDateStatusLoaded({
    this.profile,
    required this.isActive,
  });

  @override
  List<Object?> get props => [profile, isActive];
}

/// Blind date mode activated
class BlindDateModeActivated extends BlindDateState {
  final BlindDateProfile profile;

  const BlindDateModeActivated(this.profile);

  @override
  List<Object?> get props => [profile];
}

/// Blind date mode deactivated
class BlindDateModeDeactivated extends BlindDateState {
  const BlindDateModeDeactivated();
}

/// Blind candidates loaded for swiping
class BlindCandidatesLoaded extends BlindDateState {
  final List<BlindProfileView> candidates;
  final int currentIndex;
  final bool hasMore;

  const BlindCandidatesLoaded({
    required this.candidates,
    this.currentIndex = 0,
    this.hasMore = false,
  });

  /// Get current candidate
  BlindProfileView? get currentCandidate {
    if (currentIndex < 0 || currentIndex >= candidates.length) return null;
    return candidates[currentIndex];
  }

  /// Check if there are more candidates
  bool get hasMoreCandidates => currentIndex < candidates.length - 1;

  /// Get remaining candidates count
  int get remainingCount => candidates.length - currentIndex - 1;

  /// Copy with new index
  BlindCandidatesLoaded withIndex(int newIndex) {
    return BlindCandidatesLoaded(
      candidates: candidates,
      currentIndex: newIndex,
      hasMore: hasMore,
    );
  }

  @override
  List<Object?> get props => [candidates, currentIndex, hasMore];
}

/// Like action result
class BlindLikeActionResult extends BlindDateState {
  final BlindLikeResult result;
  final BlindMatch? match;

  const BlindLikeActionResult({
    required this.result,
    this.match,
  });

  bool get isMatch => result == BlindLikeResult.matched;

  @override
  List<Object?> get props => [result, match];
}

/// Pass action completed
class BlindPassActionCompleted extends BlindDateState {
  const BlindPassActionCompleted();
}

/// Blind matches loaded
class BlindMatchesLoaded extends BlindDateState {
  final List<BlindMatch> matches;
  final List<BlindMatch> revealedMatches;
  final List<BlindMatch> pendingMatches;

  BlindMatchesLoaded({required this.matches})
      : revealedMatches = matches.where((m) => m.isRevealed).toList(),
        pendingMatches = matches.where((m) => !m.isRevealed).toList();

  @override
  List<Object?> get props => [matches, revealedMatches, pendingMatches];
}

/// Instant reveal completed
class InstantRevealCompleted extends BlindDateState {
  final BlindMatch match;
  final int coinsSpent;

  const InstantRevealCompleted({
    required this.match,
    required this.coinsSpent,
  });

  @override
  List<Object?> get props => [match, coinsSpent];
}

/// Revealed profile loaded
class RevealedProfileLoaded extends BlindDateState {
  final BlindProfileView profile;
  final BlindMatch match;

  const RevealedProfileLoaded({
    required this.profile,
    required this.match,
  });

  @override
  List<Object?> get props => [profile, match];
}

/// Natural reveal triggered (after message threshold)
class NaturalRevealTriggered extends BlindDateState {
  final BlindMatch match;
  final BlindProfileView profile;

  const NaturalRevealTriggered({
    required this.match,
    required this.profile,
  });

  @override
  List<Object?> get props => [match, profile];
}

/// Insufficient coins for instant reveal
class InsufficientCoinsForReveal extends BlindDateState {
  final int required;
  final int available;

  const InsufficientCoinsForReveal({
    required this.required,
    required this.available,
  });

  int get shortfall => required - available;

  @override
  List<Object?> get props => [required, available];
}

/// No more candidates available
class NoMoreCandidates extends BlindDateState {
  final String message;

  const NoMoreCandidates({
    this.message = 'No more profiles available. Check back later!',
  });

  @override
  List<Object?> get props => [message];
}
