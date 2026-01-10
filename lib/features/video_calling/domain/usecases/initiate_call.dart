import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/video_call.dart';
import '../repositories/video_calling_repository.dart';

/// Initiate Call Use Case
class InitiateCall {
  final VideoCallingRepository repository;

  InitiateCall(this.repository);

  Future<Either<Failure, VideoCall>> call(InitiateCallParams params) {
    return repository.initiateCall(
      callerId: params.callerId,
      receiverId: params.receiverId,
      type: params.type,
    );
  }
}

/// Parameters for InitiateCall use case
class InitiateCallParams {
  final String callerId;
  final String receiverId;
  final VideoCallType type;

  InitiateCallParams({
    required this.callerId,
    required this.receiverId,
    this.type = VideoCallType.oneOnOne,
  });
}
