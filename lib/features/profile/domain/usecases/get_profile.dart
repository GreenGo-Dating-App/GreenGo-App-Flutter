import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

class GetProfile implements UseCase<Profile, GetProfileParams> {
  final ProfileRepository repository;

  GetProfile(this.repository);

  @override
  Future<Either<Failure, Profile>> call(GetProfileParams params) async {
    return await repository.getProfile(params.userId);
  }
}

class GetProfileParams {
  final String userId;

  GetProfileParams({required this.userId});
}
