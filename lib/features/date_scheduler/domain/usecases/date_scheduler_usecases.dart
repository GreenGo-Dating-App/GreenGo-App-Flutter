import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/scheduled_date.dart';
import '../repositories/date_scheduler_repository.dart';

/// Create a scheduled date
class CreateScheduledDate {

  CreateScheduledDate(this.repository);
  final DateSchedulerRepository repository;

  Future<Either<Failure, ScheduledDate>> call({
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
  }) {
    return repository.createDate(
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
  }
}

/// Get a scheduled date
class GetScheduledDate {

  GetScheduledDate(this.repository);
  final DateSchedulerRepository repository;

  Future<Either<Failure, ScheduledDate>> call(String dateId) {
    return repository.getDate(dateId);
  }
}

/// Get user dates
class GetUserDates {

  GetUserDates(this.repository);
  final DateSchedulerRepository repository;

  Future<Either<Failure, List<ScheduledDate>>> call(String userId) {
    return repository.getUserDates(userId);
  }
}

/// Get upcoming dates
class GetUpcomingDates {

  GetUpcomingDates(this.repository);
  final DateSchedulerRepository repository;

  Future<Either<Failure, List<ScheduledDate>>> call(String userId) {
    return repository.getUpcomingDates(userId);
  }
}

/// Confirm a date
class ConfirmDate {

  ConfirmDate(this.repository);
  final DateSchedulerRepository repository;

  Future<Either<Failure, ScheduledDate>> call(String dateId) {
    return repository.confirmDate(dateId);
  }
}

/// Cancel a date
class CancelDate {

  CancelDate(this.repository);
  final DateSchedulerRepository repository;

  Future<Either<Failure, ScheduledDate>> call({
    required String dateId,
    required String userId,
    String? reason,
  }) {
    return repository.cancelDate(
      dateId: dateId,
      userId: userId,
      reason: reason,
    );
  }
}

/// Reschedule a date
class RescheduleDate {

  RescheduleDate(this.repository);
  final DateSchedulerRepository repository;

  Future<Either<Failure, ScheduledDate>> call({
    required String dateId,
    required DateTime newScheduledAt,
  }) {
    return repository.rescheduleDate(
      dateId: dateId,
      newScheduledAt: newScheduledAt,
    );
  }
}

/// Get venue suggestions
class GetVenueSuggestions {

  GetVenueSuggestions(this.repository);
  final DateSchedulerRepository repository;

  Future<Either<Failure, List<VenueSuggestion>>> call({
    required double lat,
    required double lng,
    VenueCategory? category,
    double radiusKm = 5,
  }) {
    return repository.getVenueSuggestions(
      lat: lat,
      lng: lng,
      category: category,
      radiusKm: radiusKm,
    );
  }
}

/// Stream user dates
class StreamUserDates {

  StreamUserDates(this.repository);
  final DateSchedulerRepository repository;

  Stream<Either<Failure, List<ScheduledDate>>> call(String userId) {
    return repository.streamDates(userId);
  }
}

/// Set reminder for a date
class SetDateReminder {

  SetDateReminder(this.repository);
  final DateSchedulerRepository repository;

  Future<Either<Failure, DateReminder>> call({
    required String dateId,
    required DateTime remindAt,
  }) {
    return repository.setReminder(dateId: dateId, remindAt: remindAt);
  }
}
