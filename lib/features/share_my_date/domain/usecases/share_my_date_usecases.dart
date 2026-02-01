import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/share_my_date.dart';
import '../repositories/share_my_date_repository.dart';

/// Add a trusted contact
class AddTrustedContact {
  final ShareMyDateRepository repository;

  AddTrustedContact(this.repository);

  Future<Either<Failure, TrustedContact>> call({
    required String userId,
    required String contactName,
    required String contactPhone,
    String? contactEmail,
  }) {
    return repository.addTrustedContact(
      userId: userId,
      contactName: contactName,
      contactPhone: contactPhone,
      contactEmail: contactEmail,
    );
  }
}

/// Remove a trusted contact
class RemoveTrustedContact {
  final ShareMyDateRepository repository;

  RemoveTrustedContact(this.repository);

  Future<Either<Failure, void>> call(String contactId) {
    return repository.removeTrustedContact(contactId);
  }
}

/// Get trusted contacts
class GetTrustedContacts {
  final ShareMyDateRepository repository;

  GetTrustedContacts(this.repository);

  Future<Either<Failure, List<TrustedContact>>> call(String userId) {
    return repository.getTrustedContacts(userId);
  }
}

/// Share a date
class ShareDate {
  final ShareMyDateRepository repository;

  ShareDate(this.repository);

  Future<Either<Failure, SharedDate>> call({
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
  }) {
    return repository.shareDate(
      userId: userId,
      scheduledDateId: scheduledDateId,
      matchName: matchName,
      matchPhotoUrl: matchPhotoUrl,
      dateTime: dateTime,
      venueName: venueName,
      venueAddress: venueAddress,
      venueLat: venueLat,
      venueLng: venueLng,
      contactIds: contactIds,
    );
  }
}

/// Get shared dates
class GetSharedDates {
  final ShareMyDateRepository repository;

  GetSharedDates(this.repository);

  Future<Either<Failure, List<SharedDate>>> call(String userId) {
    return repository.getSharedDates(userId);
  }
}

/// Get active shared date
class GetActiveSharedDate {
  final ShareMyDateRepository repository;

  GetActiveSharedDate(this.repository);

  Future<Either<Failure, SharedDate?>> call(String userId) {
    return repository.getActiveSharedDate(userId);
  }
}

/// Check in at date
class CheckInAtDate {
  final ShareMyDateRepository repository;

  CheckInAtDate(this.repository);

  Future<Either<Failure, SafetyCheckIn>> call({
    required String sharedDateId,
    double? lat,
    double? lng,
    String? note,
  }) {
    return repository.checkIn(
      sharedDateId: sharedDateId,
      lat: lat,
      lng: lng,
      note: note,
    );
  }
}

/// Mark safe arrival
class MarkSafeArrival {
  final ShareMyDateRepository repository;

  MarkSafeArrival(this.repository);

  Future<Either<Failure, SharedDate>> call(String sharedDateId) {
    return repository.markSafeArrival(sharedDateId);
  }
}

/// Trigger emergency
class TriggerEmergency {
  final ShareMyDateRepository repository;

  TriggerEmergency(this.repository);

  Future<Either<Failure, EmergencyAlert>> call({
    required String sharedDateId,
    required String userId,
    double? lat,
    double? lng,
    String? note,
  }) {
    return repository.triggerEmergency(
      sharedDateId: sharedDateId,
      userId: userId,
      lat: lat,
      lng: lng,
      note: note,
    );
  }
}

/// Stream active date
class StreamActiveSharedDate {
  final ShareMyDateRepository repository;

  StreamActiveSharedDate(this.repository);

  Stream<Either<Failure, SharedDate?>> call(String userId) {
    return repository.streamActiveDate(userId);
  }
}
