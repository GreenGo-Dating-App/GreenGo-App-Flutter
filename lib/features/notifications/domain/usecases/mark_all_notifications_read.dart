import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/notification_repository.dart';

/// Mark All Notifications Read Use Case
///
/// Marks all unread notifications as read for a user
class MarkAllNotificationsRead {
  final NotificationRepository repository;

  MarkAllNotificationsRead(this.repository);

  Future<Either<Failure, void>> call(String userId) async {
    return await repository.markAllAsRead(userId);
  }
}
