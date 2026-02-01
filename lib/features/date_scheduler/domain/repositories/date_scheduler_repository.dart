import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/scheduled_date.dart';

/// Repository interface for Date Scheduler
abstract class DateSchedulerRepository {
  /// Create a new scheduled date
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
  });

  /// Get a scheduled date by ID
  Future<Either<Failure, ScheduledDate>> getDate(String dateId);

  /// Get all dates for a user
  Future<Either<Failure, List<ScheduledDate>>> getUserDates(String userId);

  /// Get upcoming dates for a user
  Future<Either<Failure, List<ScheduledDate>>> getUpcomingDates(String userId);

  /// Confirm a date
  Future<Either<Failure, ScheduledDate>> confirmDate(String dateId);

  /// Cancel a date
  Future<Either<Failure, ScheduledDate>> cancelDate({
    required String dateId,
    required String userId,
    String? reason,
  });

  /// Reschedule a date
  Future<Either<Failure, ScheduledDate>> rescheduleDate({
    required String dateId,
    required DateTime newScheduledAt,
  });

  /// Get venue suggestions near a location
  Future<Either<Failure, List<VenueSuggestion>>> getVenueSuggestions({
    required double lat,
    required double lng,
    VenueCategory? category,
    double radiusKm = 5,
  });

  /// Stream dates for a user
  Stream<Either<Failure, List<ScheduledDate>>> streamDates(String userId);

  /// Set reminder for a date
  Future<Either<Failure, DateReminder>> setReminder({
    required String dateId,
    required DateTime remindAt,
  });

  /// Mark date as completed
  Future<Either<Failure, ScheduledDate>> markCompleted(String dateId);
}
