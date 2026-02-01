import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/scheduled_date.dart';
import '../../domain/repositories/date_scheduler_repository.dart';
import '../datasources/date_scheduler_remote_datasource.dart';

/// Implementation of Date Scheduler repository
class DateSchedulerRepositoryImpl implements DateSchedulerRepository {
  final DateSchedulerRemoteDataSource remoteDataSource;

  DateSchedulerRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, ScheduledDate>> createDate({
    required String matchId,
    required String creatorId,
    required String partnerId,
    required String title,
    required DateTime scheduledAt,
    String? venueName,
    String? venueAddress,
    double? venueLat,
    double? venueLng,
    String? venueId,
    String? notes,
  }) async {
    try {
      final date = await remoteDataSource.createDate(
        matchId: matchId,
        creatorId: creatorId,
        partnerId: partnerId,
        title: title,
        scheduledAt: scheduledAt,
        venueName: venueName,
        venueAddress: venueAddress,
        venueLat: venueLat,
        venueLng: venueLng,
        venueId: venueId,
        notes: notes,
      );
      return Right(date);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ScheduledDate>> getDate(String dateId) async {
    try {
      final date = await remoteDataSource.getDate(dateId);
      return Right(date);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ScheduledDate>>> getUserDates(
    String userId,
  ) async {
    try {
      final dates = await remoteDataSource.getUserDates(userId);
      return Right(dates);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ScheduledDate>>> getUpcomingDates(
    String userId,
  ) async {
    try {
      final dates = await remoteDataSource.getUpcomingDates(userId);
      return Right(dates);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ScheduledDate>> confirmDate(String dateId) async {
    try {
      final date = await remoteDataSource.confirmDate(dateId);
      return Right(date);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ScheduledDate>> cancelDate({
    required String dateId,
    required String userId,
    String? reason,
  }) async {
    try {
      final date = await remoteDataSource.cancelDate(
        dateId: dateId,
        userId: userId,
        reason: reason,
      );
      return Right(date);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ScheduledDate>> rescheduleDate({
    required String dateId,
    required DateTime newScheduledAt,
  }) async {
    try {
      final date = await remoteDataSource.rescheduleDate(
        dateId: dateId,
        newScheduledAt: newScheduledAt,
      );
      return Right(date);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<VenueSuggestion>>> getVenueSuggestions({
    required double lat,
    required double lng,
    VenueCategory? category,
    double radiusKm = 5,
  }) async {
    try {
      final venues = await remoteDataSource.getVenueSuggestions(
        lat: lat,
        lng: lng,
        category: category,
        radiusKm: radiusKm,
      );
      return Right(venues);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<ScheduledDate>>> streamDates(String userId) {
    return remoteDataSource
        .streamDates(userId)
        .map((dates) => Right<Failure, List<ScheduledDate>>(dates));
  }

  @override
  Future<Either<Failure, DateReminder>> setReminder({
    required String dateId,
    required DateTime remindAt,
  }) async {
    try {
      final reminder = await remoteDataSource.setReminder(
        dateId: dateId,
        remindAt: remindAt,
      );
      return Right(reminder);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ScheduledDate>> markCompleted(String dateId) async {
    try {
      final date = await remoteDataSource.markCompleted(dateId);
      return Right(date);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
