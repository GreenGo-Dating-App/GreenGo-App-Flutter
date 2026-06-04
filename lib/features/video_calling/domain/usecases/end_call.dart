import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/video_calling_repository.dart';

/// End Call Use Case
class EndCall {

  EndCall(this.repository);
  final VideoCallingRepository repository;

  Future<Either<Failure, void>> call(EndCallParams params) {
    return repository.endCall(
      callId: params.callId,
      userId: params.userId,
    );
  }
}

/// Parameters for EndCall use case
class EndCallParams {

  EndCallParams({
    required this.callId,
    required this.userId,
  });
  final String callId;
  final String userId;
}
