import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/globe_user.dart';
import '../../domain/repositories/globe_repository.dart';
import '../datasources/globe_remote_datasource.dart';

class GlobeRepositoryImpl implements GlobeRepository {
  final GlobeRemoteDataSource remoteDataSource;

  GlobeRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, GlobeData>> getGlobeData({
    required String userId,
  }) async {
    try {
      final data = await remoteDataSource.getGlobeData(userId: userId);
      return Right(data);
    } catch (e) {
      return Left(ServerFailure('Failed to load globe data: $e'));
    }
  }

  @override
  Stream<List<GlobeUser>> watchMatchUpdates({required String userId}) {
    return remoteDataSource.watchMatchUpdates(userId: userId);
  }

  @override
  Stream<Map<String, bool>> watchOnlineStatus({
    required List<String> userIds,
  }) {
    return remoteDataSource.watchOnlineStatus(userIds: userIds);
  }
}
