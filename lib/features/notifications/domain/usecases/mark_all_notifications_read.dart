import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/notification_repository.dart';

/// Mark All Notifications Read Use Case
///
/// Marks all unread notifications as read for a user
class MarkAllNotificationsRead {

  MarkAllNotificationsRead(this.repository);
  final NotificationRepository repository;

  Future<Either<Failure, void>> call(String userId) async {
    return repository.markAllAsRead(userId);
  }
}
