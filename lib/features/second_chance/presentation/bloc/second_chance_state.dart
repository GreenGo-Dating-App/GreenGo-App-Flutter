import 'package:equatable/equatable.dart';
import '../../domain/entities/second_chance.dart';

/// Second Chance States
abstract class SecondChanceState extends Equatable {
  const SecondChanceState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class SecondChanceInitial extends SecondChanceState {
  const SecondChanceInitial();
}

/// Loading state
class SecondChanceLoading extends SecondChanceState {
  const SecondChanceLoading();
}

/// Error state
class SecondChanceError extends SecondChanceState {
  final String message;

  const SecondChanceError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Profiles loaded
class SecondChanceProfilesLoaded extends SecondChanceState {
  final List<SecondChanceProfile> profiles;
  final SecondChanceUsage usage;
  final int currentIndex;

  const SecondChanceProfilesLoaded({
    required this.profiles,
    required this.usage,
    this.currentIndex = 0,
  });

  /// Current profile
  SecondChanceProfile? get currentProfile {
    if (currentIndex < 0 || currentIndex >= profiles.length) return null;
    return profiles[currentIndex];
  }

  /// Has more profiles
  bool get hasMore => currentIndex < profiles.length - 1;

  /// Copy with new index
  SecondChanceProfilesLoaded withIndex(int newIndex) {
    return SecondChanceProfilesLoaded(
      profiles: profiles,
      usage: usage,
      currentIndex: newIndex,
    );
  }

  @override
  List<Object?> get props => [profiles, usage, currentIndex];
}

/// Like action result
class SecondChanceLikeResult extends SecondChanceState {
  final bool isMatch;
  final String? matchId;

  const SecondChanceLikeResult({
    required this.isMatch,
    this.matchId,
  });

  @override
  List<Object?> get props => [isMatch, matchId];
}

/// Pass action completed
class SecondChancePassCompleted extends SecondChanceState {
  const SecondChancePassCompleted();
}

/// No more second chances
class NoMoreSecondChances extends SecondChanceState {
  const NoMoreSecondChances();
}

/// Unlimited purchased
class UnlimitedPurchased extends SecondChanceState {
  final SecondChanceUsage usage;

  const UnlimitedPurchased(this.usage);

  @override
  List<Object?> get props => [usage];
}

/// Need more uses (show purchase option)
class NeedMoreSecondChances extends SecondChanceState {
  final SecondChanceUsage usage;

  const NeedMoreSecondChances(this.usage);

  @override
  List<Object?> get props => [usage];
}
