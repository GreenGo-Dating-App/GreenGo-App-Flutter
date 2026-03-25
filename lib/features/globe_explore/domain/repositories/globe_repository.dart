import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/globe_user.dart';

abstract class GlobeRepository {
  Future<Either<Failure, GlobeData>> getGlobeData({
    required String userId,
  });

  Stream<List<GlobeUser>> watchMatchUpdates({
    required String userId,
  });

  Stream<Map<String, bool>> watchOnlineStatus({
    required List<String> userIds,
  });
}
