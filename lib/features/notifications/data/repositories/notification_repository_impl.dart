import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/notification.dart';
import '../../domain/entities/notification_preferences.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';
import '../models/notification_preferences_model.dart';

/// Notification Repository Implementation
class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;

  NotificationRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<Either<Failure, List<NotificationEntity>>> getNotificationsStream(
    String userId, {
    bool unreadOnly = false,
    int? limit,
  }) {
    try {
      return remoteDataSource
          .getNotificationsStream(
            userId,
            unreadOnly: unreadOnly,
            limit: limit,
          )
          .map((notifications) => Right<Failure, List<NotificationEntity>>(
              notifications.map((n) => n.toEntity()).toList()))
          .handleError((error) {
        return Left<Failure, List<NotificationEntity>>(
            ServerFailure(error.toString()));
      });
    } catch (e) {
      return Stream.value(Left(ServerFailure(e.toString())));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(String notificationId) async {
    try {
      await remoteDataSource.markAsRead(notificationId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAllAsRead(String userId) async {
    try {
      await remoteDataSource.markAllAsRead(userId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteNotification(String notificationId) async {
    try {
      await remoteDataSource.deleteNotification(notificationId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadCount(String userId) async {
    try {
      final count = await remoteDataSource.getUnreadCount(userId);
      return Right(count);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, NotificationEntity>> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
    String? actionUrl,
    String? imageUrl,
  }) async {
    try {
      final notification = await remoteDataSource.createNotification(
        userId: userId,
        type: type,
        title: title,
        message: message,
        data: data,
        actionUrl: actionUrl,
        imageUrl: imageUrl,
      );
      return Right(notification.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, NotificationPreferences>> getPreferences(
      String userId) async {
    try {
      final preferences = await remoteDataSource.getPreferences(userId);
      return Right(preferences.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updatePreferences(
      NotificationPreferences preferences) async {
    try {
      await remoteDataSource.updatePreferences(
        NotificationPreferencesModel.fromEntity(preferences),
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> requestPermission() async {
    try {
      final granted = await remoteDataSource.requestPermission();
      return Right(granted);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String?>> getFCMToken() async {
    try {
      final token = await remoteDataSource.getFCMToken();
      return Right(token);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveFCMToken(String userId, String token) async {
    try {
      await remoteDataSource.saveFCMToken(userId, token);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
