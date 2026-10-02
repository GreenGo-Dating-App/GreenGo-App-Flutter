import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/globe_user.dart';

abstract class GlobeRepository {
  /// The signed-in user's own pin, or null if it cannot be loaded (never
  /// throws). Lets the map render before the matched pins arrive.
  Future<GlobeUser?> getCurrentUserPin({required String userId});

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
