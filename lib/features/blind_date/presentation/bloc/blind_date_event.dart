import 'package:equatable/equatable.dart';

/// Blind Date Events
abstract class BlindDateEvent extends Equatable {
  const BlindDateEvent();

  @override
  List<Object?> get props => [];
}

/// Activate blind date mode
class ActivateBlindDateMode extends BlindDateEvent {
  final String userId;

  const ActivateBlindDateMode(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Deactivate blind date mode
class DeactivateBlindDateMode extends BlindDateEvent {
  final String userId;

  const DeactivateBlindDateMode(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Check blind date status
class CheckBlindDateStatus extends BlindDateEvent {
  final String userId;

  const CheckBlindDateStatus(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Load blind date candidates
class LoadBlindCandidates extends BlindDateEvent {
  final String userId;
  final int limit;

  const LoadBlindCandidates({
    required this.userId,
    this.limit = 10,
  });

  @override
  List<Object?> get props => [userId, limit];
}

/// Like a blind profile
class LikeBlindProfileEvent extends BlindDateEvent {
  final String userId;
  final String targetUserId;

  const LikeBlindProfileEvent({
    required this.userId,
    required this.targetUserId,
  });

  @override
  List<Object?> get props => [userId, targetUserId];
}

/// Pass on a blind profile
class PassBlindProfileEvent extends BlindDateEvent {
  final String userId;
  final String targetUserId;

  const PassBlindProfileEvent({
    required this.userId,
    required this.targetUserId,
  });

  @override
  List<Object?> get props => [userId, targetUserId];
}

/// Load blind matches
class LoadBlindMatches extends BlindDateEvent {
  final String userId;

  const LoadBlindMatches(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Subscribe to blind matches stream
class SubscribeToBlindMatches extends BlindDateEvent {
  final String userId;

  const SubscribeToBlindMatches(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Request instant photo reveal
class RequestInstantReveal extends BlindDateEvent {
  final String userId;
  final String matchId;

  const RequestInstantReveal({
    required this.userId,
    required this.matchId,
  });

  @override
  List<Object?> get props => [userId, matchId];
}

/// Load revealed profile
class LoadRevealedProfile extends BlindDateEvent {
  final String matchId;
  final String userId;

  const LoadRevealedProfile({
    required this.matchId,
    required this.userId,
  });

  @override
  List<Object?> get props => [matchId, userId];
}

/// Select a candidate for viewing
class SelectBlindCandidate extends BlindDateEvent {
  final int index;

  const SelectBlindCandidate(this.index);

  @override
  List<Object?> get props => [index];
}
