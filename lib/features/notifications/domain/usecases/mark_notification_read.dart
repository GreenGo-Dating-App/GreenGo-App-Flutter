import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/notification_repository.dart';

/// Mark Notification As Read Use Case
class MarkNotificationRead {

  MarkNotificationRead(this.repository);
  final NotificationRepository repository;

  Future<Either<Failure, void>> call(String notificationId) {
    return repository.markAsRead(notificationId);
  }
}
