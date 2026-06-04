import '../../../../core/services/usage_limit_service.dart';
import '../../domain/entities/discovery_card.dart';
import '../../domain/entities/match.dart';

/// Discovery States
abstract class DiscoveryState {
  const DiscoveryState();
}

/// Initial state
class DiscoveryInitial extends DiscoveryState {
  const DiscoveryInitial();
}

/// Loading discovery stack
class DiscoveryLoading extends DiscoveryState {
  const DiscoveryLoading();
}

/// Discovery stack loaded successfully
class DiscoveryLoaded extends DiscoveryState {

  const DiscoveryLoaded({
    required this.cards,
    this.currentIndex = 0,
    this.usedWorldwideFallback = false,
  });
  final List<DiscoveryCard> cards;
  final int currentIndex;
  final bool usedWorldwideFallback;

  /// Get current card
  DiscoveryCard? get currentCard =>
      currentIndex < cards.length ? cards[currentIndex] : null;

  /// Get remaining cards count
  int get remainingCount => cards.length - currentIndex;

  /// Check if stack is empty
  bool get isEmpty => remainingCount == 0;

  /// Copy with updated fields
  DiscoveryLoaded copyWith({
    List<DiscoveryCard>? cards,
    int? currentIndex,
    bool? usedWorldwideFallback,
  }) {
    return DiscoveryLoaded(
      cards: cards ?? this.cards,
      currentIndex: currentIndex ?? this.currentIndex,
      usedWorldwideFallback: usedWorldwideFallback ?? this.usedWorldwideFallback,
    );
  }
}

/// Swipe action in progress
class DiscoverySwiping extends DiscoveryState {

  const DiscoverySwiping({
    required this.cards,
    required this.currentIndex,
  });
  final List<DiscoveryCard> cards;
  final int currentIndex;
}

/// Swipe completed
class DiscoverySwipeCompleted extends DiscoveryState {

  const DiscoverySwipeCompleted({
    required this.cards,
    required this.currentIndex,
    this.createdMatch = false,
    this.matchedUserId,
    this.matchId,
  });
  final List<DiscoveryCard> cards;
  final int currentIndex;
  final bool createdMatch;
  final String? matchedUserId;
  final String? matchId;
}

/// Match created
class DiscoveryMatchCreated extends DiscoveryState {

  const DiscoveryMatchCreated({
    required this.match,
    required this.remainingCards,
    required this.currentIndex,
  });
  final Match match;
  final List<DiscoveryCard> remainingCards;
  final int currentIndex;
}

/// Discovery stack empty
class DiscoveryStackEmpty extends DiscoveryState {
  const DiscoveryStackEmpty();
}

/// Error state
class DiscoveryError extends DiscoveryState {

  const DiscoveryError(this.message);
  final String message;
}

/// Swipe limit reached state
class DiscoverySwipeLimitReached extends DiscoveryState {

  const DiscoverySwipeLimitReached({
    required this.cards,
    required this.currentIndex,
    required this.limitResult,
  });
  final List<DiscoveryCard> cards;
  final int currentIndex;
  final UsageLimitResult limitResult;
}

/// Rewind unavailable state
class DiscoveryRewindUnavailable extends DiscoveryState {

  const DiscoveryRewindUnavailable({
    required this.reason,
    required this.cards,
    required this.currentIndex,
  });
  final String reason; // 'no_previous', 'match_created', 'not_allowed'
  final List<DiscoveryCard> cards;
  final int currentIndex;
}

/// Insufficient coins for a feature
class DiscoveryInsufficientCoins extends DiscoveryState {

  const DiscoveryInsufficientCoins({
    required this.cards,
    required this.currentIndex,
    required this.required,
    required this.available,
    this.featureName = 'Super Like',
  });
  final List<DiscoveryCard> cards;
  final int currentIndex;
  final int required;
  final int available;
  final String featureName;
}

/// Base membership required to perform action
class DiscoveryBaseMembershipRequired extends DiscoveryState {

  const DiscoveryBaseMembershipRequired({
    required this.cards,
    required this.currentIndex,
  });
  final List<DiscoveryCard> cards;
  final int currentIndex;
}

/// Super like limit reached state
class DiscoverySuperLikeLimitReached extends DiscoveryState {

  const DiscoverySuperLikeLimitReached({
    required this.cards,
    required this.currentIndex,
    required this.limitResult,
  });
  final List<DiscoveryCard> cards;
  final int currentIndex;
  final UsageLimitResult limitResult;
}
