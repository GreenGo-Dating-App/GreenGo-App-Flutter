import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/notification_repository.dart';

/// Request Notification Permission Use Case
class RequestNotificationPermission {
  final NotificationRepository repository;

  RequestNotificationPermission(this.repository);

  Future<Either<Failure, bool>> call() {
    return repository.requestPermission();
  }
}

/// Get FCM Token Use Case
class GetFCMToken {
  final NotificationRepository repository;

  GetFCMToken(this.repository);

  Future<Either<Failure, String?>> call() {
    return repository.getFCMToken();
  }
}

/// Save FCM Token Use Case
class SaveFCMToken {
  final NotificationRepository repository;

  SaveFCMToken(this.repository);

  Future<Either<Failure, void>> call(String userId, String token) {
    return repository.saveFCMToken(userId, token);
  }
}
