import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/notification_preferences.dart';
import '../repositories/notification_repository.dart';

/// Update Notification Preferences Use Case
class UpdateNotificationPreferences {
  final NotificationRepository repository;

  UpdateNotificationPreferences(this.repository);

  Future<Either<Failure, void>> call(NotificationPreferences preferences) {
    return repository.updatePreferences(preferences);
  }
}
