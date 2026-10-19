import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/globe_user.dart';

abstract class GlobeRepository {
  /// The signed-in user's own pin, or null if it cannot be loaded (never
  /// throws). Lets the map render before the network pins arrive.
  Future<GlobeUser?> getCurrentUserPin({required String userId});

  /// The user's own pin plus their network (follows, followers, chats,
  /// businesses), one bounded read per open.
  Future<Either<Failure, GlobeData>> getGlobeData({
    required String userId,
  });
}
