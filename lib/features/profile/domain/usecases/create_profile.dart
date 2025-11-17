import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

class CreateProfile implements UseCase<Profile, CreateProfileParams> {
  final ProfileRepository repository;

  CreateProfile(this.repository);

  @override
  Future<Either<Failure, Profile>> call(CreateProfileParams params) async {
    return await repository.createProfile(params.profile);
  }
}

class CreateProfileParams {
  final Profile profile;

  CreateProfileParams({required this.profile});
}
