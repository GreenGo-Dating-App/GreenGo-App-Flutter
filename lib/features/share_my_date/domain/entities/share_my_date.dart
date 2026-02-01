import 'package:equatable/equatable.dart';

/// Trusted Contact Entity
class TrustedContact extends Equatable {
  final String id;
  final String userId;
  final String contactName;
  final String contactPhone;
  final String? contactEmail;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime? lastNotifiedAt;

  const TrustedContact({
    required this.id,
    required this.userId,
    required this.contactName,
    required this.contactPhone,
    this.contactEmail,
    this.isVerified = false,
    required this.createdAt,
    this.lastNotifiedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        contactName,
        contactPhone,
        contactEmail,
        isVerified,
        createdAt,
        lastNotifiedAt,
      ];
}

/// Shared Date Entity
class SharedDate extends Equatable {
  final String id;
  final String userId;
  final String scheduledDateId;
  final String matchName;
  final String? matchPhotoUrl;
  final DateTime dateTime;
  final String? venueName;
  final String? venueAddress;
  final double? venueLat;
  final double? venueLng;
  final List<String> notifiedContactIds;
  final ShareStatus status;
  final DateTime? checkInTime;
  final DateTime? safeArrivalTime;
  final DateTime createdAt;
  final String? emergencyNote;

  const SharedDate({
    required this.id,
    required this.userId,
    required this.scheduledDateId,
    required this.matchName,
    this.matchPhotoUrl,
    required this.dateTime,
    this.venueName,
    this.venueAddress,
    this.venueLat,
    this.venueLng,
    this.notifiedContactIds = const [],
    this.status = ShareStatus.pending,
    this.checkInTime,
    this.safeArrivalTime,
    required this.createdAt,
    this.emergencyNote,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        scheduledDateId,
        matchName,
        matchPhotoUrl,
        dateTime,
        venueName,
        venueAddress,
        venueLat,
        venueLng,
        notifiedContactIds,
        status,
        checkInTime,
        safeArrivalTime,
        createdAt,
        emergencyNote,
      ];

  /// Is date active (currently happening)
  bool get isActive {
    final now = DateTime.now();
    final endTime = dateTime.add(const Duration(hours: 4));
    return now.isAfter(dateTime) && now.isBefore(endTime);
  }

  /// Has checked in
  bool get hasCheckedIn => checkInTime != null;

  /// Has marked safe arrival
  bool get hasSafeArrival => safeArrivalTime != null;

  /// Has venue location
  bool get hasLocation => venueLat != null && venueLng != null;
}

/// Share Status
enum ShareStatus {
  pending,      // Date is scheduled, contacts notified
  active,       // Date is happening
  checkedIn,    // User checked in at venue
  completed,    // User marked safe arrival
  expired,      // Date time passed without safe arrival
  emergency,    // Emergency triggered
}

/// Share Config
class ShareMyDateConfig {
  /// Max trusted contacts allowed
  static const int maxTrustedContacts = 5;

  /// Check-in reminder (minutes before date)
  static const int checkInReminderMinutes = 30;

  /// Safe arrival check time (hours after date start)
  static const int safeArrivalCheckHours = 3;

  /// Emergency escalation time (hours after expected check-in)
  static const int emergencyEscalationHours = 1;
}

/// Safety Check-In Result
class SafetyCheckIn extends Equatable {
  final String sharedDateId;
  final DateTime checkInTime;
  final double? lat;
  final double? lng;
  final bool atExpectedLocation;
  final String? note;

  const SafetyCheckIn({
    required this.sharedDateId,
    required this.checkInTime,
    this.lat,
    this.lng,
    this.atExpectedLocation = false,
    this.note,
  });

  @override
  List<Object?> get props => [
        sharedDateId,
        checkInTime,
        lat,
        lng,
        atExpectedLocation,
        note,
      ];
}

/// Emergency Alert
class EmergencyAlert extends Equatable {
  final String id;
  final String sharedDateId;
  final String userId;
  final DateTime triggeredAt;
  final double? lat;
  final double? lng;
  final List<String> notifiedContacts;
  final String? note;

  const EmergencyAlert({
    required this.id,
    required this.sharedDateId,
    required this.userId,
    required this.triggeredAt,
    this.lat,
    this.lng,
    this.notifiedContacts = const [],
    this.note,
  });

  @override
  List<Object?> get props => [
        id,
        sharedDateId,
        userId,
        triggeredAt,
        lat,
        lng,
        notifiedContacts,
        note,
      ];
}
