import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/profile_repository.dart';

class VerifyPhoto implements UseCase<bool, VerifyPhotoParams> {
  final ProfileRepository repository;

  VerifyPhoto(this.repository);

  @override
  Future<Either<Failure, bool>> call(VerifyPhotoParams params) async {
    return await repository.verifyPhotoWithAI(params.photo);
  }
}

class VerifyPhotoParams {
  final File photo;

  VerifyPhotoParams({required this.photo});
}
