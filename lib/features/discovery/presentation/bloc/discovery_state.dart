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
  final List<DiscoveryCard> cards;
  final int currentIndex;

  const DiscoveryLoaded({
    required this.cards,
    this.currentIndex = 0,
  });

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
  }) {
    return DiscoveryLoaded(
      cards: cards ?? this.cards,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}

/// Swipe action in progress
class DiscoverySwiping extends DiscoveryState {
  final List<DiscoveryCard> cards;
  final int currentIndex;

  const DiscoverySwiping({
    required this.cards,
    required this.currentIndex,
  });
}

/// Swipe completed
class DiscoverySwipeCompleted extends DiscoveryState {
  final List<DiscoveryCard> cards;
  final int currentIndex;
  final bool createdMatch;

  const DiscoverySwipeCompleted({
    required this.cards,
    required this.currentIndex,
    this.createdMatch = false,
  });
}

/// Match created
class DiscoveryMatchCreated extends DiscoveryState {
  final Match match;
  final List<DiscoveryCard> remainingCards;
  final int currentIndex;

  const DiscoveryMatchCreated({
    required this.match,
    required this.remainingCards,
    required this.currentIndex,
  });
}

/// Discovery stack empty
class DiscoveryStackEmpty extends DiscoveryState {
  const DiscoveryStackEmpty();
}

/// Error state
class DiscoveryError extends DiscoveryState {
  final String message;

  const DiscoveryError(this.message);
}
