import '../entities/globe_user.dart';
import '../repositories/globe_repository.dart';

class WatchGlobeUpdates {
  final GlobeRepository repository;

  WatchGlobeUpdates(this.repository);

  Stream<List<GlobeUser>> watchMatches(String userId) {
    return repository.watchMatchUpdates(userId: userId);
  }

  Stream<Map<String, bool>> watchOnlineStatus(List<String> userIds) {
    return repository.watchOnlineStatus(userIds: userIds);
  }
}
