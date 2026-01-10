import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/video_call.dart';
import '../repositories/video_calling_repository.dart';

/// Get SDK Config Use Case
class GetSDKConfig {
  final VideoCallingRepository repository;

  GetSDKConfig(this.repository);

  Future<Either<Failure, VideoSDKConfig>> call(GetSDKConfigParams params) {
    return repository.getSDKConfig(
      callId: params.callId,
      userId: params.userId,
    );
  }
}

/// Parameters for GetSDKConfig use case
class GetSDKConfigParams {
  final String callId;
  final String userId;

  GetSDKConfigParams({
    required this.callId,
    required this.userId,
  });
}
