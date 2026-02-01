import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/share_my_date.dart';

/// Repository interface for Share My Date feature
abstract class ShareMyDateRepository {
  /// Add a trusted contact
  Future<Either<Failure, TrustedContact>> addTrustedContact({
    required String userId,
    required String contactName,
    required String contactPhone,
    String? contactEmail,
  });

  /// Remove a trusted contact
  Future<Either<Failure, void>> removeTrustedContact(String contactId);

  /// Get all trusted contacts for a user
  Future<Either<Failure, List<TrustedContact>>> getTrustedContacts(
    String userId,
  );

  /// Share a date with trusted contacts
  Future<Either<Failure, SharedDate>> shareDate({
    required String userId,
    required String scheduledDateId,
    required String matchName,
    String? matchPhotoUrl,
    required DateTime dateTime,
    String? venueName,
    String? venueAddress,
    double? venueLat,
    double? venueLng,
    List<String> contactIds = const [],
  });

  /// Get shared dates for a user
  Future<Either<Failure, List<SharedDate>>> getSharedDates(String userId);

  /// Get active shared date
  Future<Either<Failure, SharedDate?>> getActiveSharedDate(String userId);

  /// Check in at date location
  Future<Either<Failure, SafetyCheckIn>> checkIn({
    required String sharedDateId,
    double? lat,
    double? lng,
    String? note,
  });

  /// Mark safe arrival home
  Future<Either<Failure, SharedDate>> markSafeArrival(String sharedDateId);

  /// Trigger emergency alert
  Future<Either<Failure, EmergencyAlert>> triggerEmergency({
    required String sharedDateId,
    required String userId,
    double? lat,
    double? lng,
    String? note,
  });

  /// Cancel emergency alert
  Future<Either<Failure, void>> cancelEmergency(String alertId);

  /// Stream active shared date
  Stream<Either<Failure, SharedDate?>> streamActiveDate(String userId);
}
