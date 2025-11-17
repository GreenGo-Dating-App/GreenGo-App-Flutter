import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/notification.dart';
import '../repositories/notification_repository.dart';

/// Get Notifications Stream Use Case
class GetNotifications {
  final NotificationRepository repository;

  GetNotifications(this.repository);

  Stream<Either<Failure, List<NotificationEntity>>> call(
      GetNotificationsParams params) {
    return repository.getNotificationsStream(
      params.userId,
      unreadOnly: params.unreadOnly,
      limit: params.limit,
    );
  }
}

/// Parameters for GetNotifications use case
class GetNotificationsParams {
  final String userId;
  final bool unreadOnly;
  final int? limit;

  GetNotificationsParams({
    required this.userId,
    this.unreadOnly = false,
    this.limit,
  });
}
