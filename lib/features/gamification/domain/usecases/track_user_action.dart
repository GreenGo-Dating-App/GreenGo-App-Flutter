/// Track User Action Use Case
/// Tracks progress for all active challenges matching an action type.
/// Called from feature blocs (Chat, Discovery, Profile) when users perform actions.
library;

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/gamification_repository.dart';

class TrackUserAction {

  TrackUserAction(this.repository);
  final GamificationRepository repository;

  Future<Either<Failure, void>> call(TrackUserActionParams params) async {
    return repository.trackActionProgress(
      params.userId,
      params.actionType,
      incrementBy: params.incrementBy,
    );
  }
}

class TrackUserActionParams {

  const TrackUserActionParams({
    required this.userId,
    required this.actionType,
    this.incrementBy = 1,
  });

  /// Factory methods for common actions
  factory TrackUserActionParams.messageSent(String userId) =>
      TrackUserActionParams(userId: userId, actionType: 'message_sent');

  factory TrackUserActionParams.match(String userId) =>
      TrackUserActionParams(userId: userId, actionType: 'match');

  factory TrackUserActionParams.superLike(String userId) =>
      TrackUserActionParams(userId: userId, actionType: 'super_like');

  factory TrackUserActionParams.videoCall(String userId) =>
      TrackUserActionParams(userId: userId, actionType: 'video_call');

  factory TrackUserActionParams.photoAdded(String userId) =>
      TrackUserActionParams(userId: userId, actionType: 'photo_added');

  factory TrackUserActionParams.giftSent(String userId) =>
      TrackUserActionParams(userId: userId, actionType: 'gift_sent');
  final String userId;
  final String actionType;
  final int incrementBy;
}
