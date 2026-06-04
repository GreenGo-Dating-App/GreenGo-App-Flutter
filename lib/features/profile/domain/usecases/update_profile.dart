import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

class UpdateProfile implements UseCase<Profile, UpdateProfileParams> {

  UpdateProfile(this.repository);
  final ProfileRepository repository;

  @override
  Future<Either<Failure, Profile>> call(UpdateProfileParams params) async {
    return repository.updateProfile(params.profile);
  }
}

class UpdateProfileParams {

  UpdateProfileParams({required this.profile});
  final Profile profile;
}
