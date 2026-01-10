import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/video_call.dart';
import '../repositories/video_calling_repository.dart';

/// Listen For Incoming Calls Use Case
class ListenForIncomingCalls {
  final VideoCallingRepository repository;

  ListenForIncomingCalls(this.repository);

  Stream<Either<Failure, VideoCall?>> call(String userId) {
    return repository.listenForIncomingCalls(userId);
  }
}
