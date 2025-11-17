import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/notification_preferences.dart';
import '../repositories/notification_repository.dart';

/// Get Notification Preferences Use Case
class GetNotificationPreferences {
  final NotificationRepository repository;

  GetNotificationPreferences(this.repository);

  Future<Either<Failure, NotificationPreferences>> call(String userId) {
    return repository.getPreferences(userId);
  }
}
