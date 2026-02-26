import 'package:equatable/equatable.dart';
import '../../domain/entities/discovery_card.dart';
import '../../domain/entities/match.dart';
import '../../../../core/services/usage_limit_service.dart';

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
  final String? matchedUserId;
  final String? matchId;

  const DiscoverySwipeCompleted({
    required this.cards,
    required this.currentIndex,
    this.createdMatch = false,
    this.matchedUserId,
    this.matchId,
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

/// Swipe limit reached state
class DiscoverySwipeLimitReached extends DiscoveryState {
  final List<DiscoveryCard> cards;
  final int currentIndex;
  final UsageLimitResult limitResult;

  const DiscoverySwipeLimitReached({
    required this.cards,
    required this.currentIndex,
    required this.limitResult,
  });
}

/// Rewind unavailable state
class DiscoveryRewindUnavailable extends DiscoveryState {
  final String reason; // 'no_previous', 'match_created', 'not_allowed'
  final List<DiscoveryCard> cards;
  final int currentIndex;

  const DiscoveryRewindUnavailable({
    required this.reason,
    required this.cards,
    required this.currentIndex,
  });
}

/// Insufficient coins for a feature
class DiscoveryInsufficientCoins extends DiscoveryState {
  final List<DiscoveryCard> cards;
  final int currentIndex;
  final int required;
  final int available;
  final String featureName;

  const DiscoveryInsufficientCoins({
    required this.cards,
    required this.currentIndex,
    required this.required,
    required this.available,
    this.featureName = 'Super Like',
  });
}

/// Base membership required to perform action
class DiscoveryBaseMembershipRequired extends DiscoveryState {
  final List<DiscoveryCard> cards;
  final int currentIndex;

  const DiscoveryBaseMembershipRequired({
    required this.cards,
    required this.currentIndex,
  });
}

/// Super like limit reached state
class DiscoverySuperLikeLimitReached extends DiscoveryState {
  final List<DiscoveryCard> cards;
  final int currentIndex;
  final UsageLimitResult limitResult;

  const DiscoverySuperLikeLimitReached({
    required this.cards,
    required this.currentIndex,
    required this.limitResult,
  });
}
