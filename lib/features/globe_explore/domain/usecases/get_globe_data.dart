import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/globe_user.dart';
import '../repositories/globe_repository.dart';

class GetGlobeData {

  GetGlobeData(this.repository);
  final GlobeRepository repository;

  Future<Either<Failure, GlobeData>> call(String userId) {
    return repository.getGlobeData(userId: userId);
  }
}
