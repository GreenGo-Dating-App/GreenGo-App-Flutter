import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/profile_repository.dart';

class UploadPhoto implements UseCase<String, UploadPhotoParams> {
  final ProfileRepository repository;

  UploadPhoto(this.repository);

  @override
  Future<Either<Failure, String>> call(UploadPhotoParams params) async {
    return await repository.uploadPhoto(params.userId, params.photo);
  }
}

class UploadPhotoParams {
  final String userId;
  final File photo;

  UploadPhotoParams({
    required this.userId,
    required this.photo,
  });
}
