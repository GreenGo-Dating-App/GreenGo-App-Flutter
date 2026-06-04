import 'package:equatable/equatable.dart';

/// Blind Date Events
abstract class BlindDateEvent extends Equatable {
  const BlindDateEvent();

  @override
  List<Object?> get props => [];
}

/// Activate blind date mode
class ActivateBlindDateMode extends BlindDateEvent {

  const ActivateBlindDateMode(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Deactivate blind date mode
class DeactivateBlindDateMode extends BlindDateEvent {

  const DeactivateBlindDateMode(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Check blind date status
class CheckBlindDateStatus extends BlindDateEvent {

  const CheckBlindDateStatus(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Load blind date candidates
class LoadBlindCandidates extends BlindDateEvent {

  const LoadBlindCandidates({
    required this.userId,
    this.limit = 10,
  });
  final String userId;
  final int limit;

  @override
  List<Object?> get props => [userId, limit];
}

/// Like a blind profile
class LikeBlindProfileEvent extends BlindDateEvent {

  const LikeBlindProfileEvent({
    required this.userId,
    required this.targetUserId,
  });
  final String userId;
  final String targetUserId;

  @override
  List<Object?> get props => [userId, targetUserId];
}

/// Pass on a blind profile
class PassBlindProfileEvent extends BlindDateEvent {

  const PassBlindProfileEvent({
    required this.userId,
    required this.targetUserId,
  });
  final String userId;
  final String targetUserId;

  @override
  List<Object?> get props => [userId, targetUserId];
}

/// Load blind matches
class LoadBlindMatches extends BlindDateEvent {

  const LoadBlindMatches(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Subscribe to blind matches stream
class SubscribeToBlindMatches extends BlindDateEvent {

  const SubscribeToBlindMatches(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Request instant photo reveal
class RequestInstantReveal extends BlindDateEvent {

  const RequestInstantReveal({
    required this.userId,
    required this.matchId,
  });
  final String userId;
  final String matchId;

  @override
  List<Object?> get props => [userId, matchId];
}

/// Load revealed profile
class LoadRevealedProfile extends BlindDateEvent {

  const LoadRevealedProfile({
    required this.matchId,
    required this.userId,
  });
  final String matchId;
  final String userId;

  @override
  List<Object?> get props => [matchId, userId];
}

/// Select a candidate for viewing
class SelectBlindCandidate extends BlindDateEvent {

  const SelectBlindCandidate(this.index);
  final int index;

  @override
  List<Object?> get props => [index];
}
