import 'package:equatable/equatable.dart';

/// Check-in Status
enum CheckInStatus {
  scheduled,
  pending,
  safe,
  emergency,
  missed,
  cancelled,
}

/// Date Check-In Entity
/// Safety feature for real-world dates
class DateCheckIn extends Equatable {

  const DateCheckIn({
    required this.id,
    required this.userId,
    required this.locationName, required this.scheduledDate, required this.status, required this.createdAt, this.matchId,
    this.matchName,
    this.latitude,
    this.longitude,
    this.checkInTime,
    this.checkInInterval = const Duration(minutes: 30),
    this.emergencyContacts = const [],
    this.notes,
    this.logs = const [],
    this.shareLocationEnabled = false,
  });
  final String id;
  final String userId;
  final String? matchId;
  final String? matchName;
  final String locationName;
  final double? latitude;
  final double? longitude;
  final DateTime scheduledDate;
  final DateTime? checkInTime;
  final Duration checkInInterval;
  final List<EmergencyContact> emergencyContacts;
  final CheckInStatus status;
  final String? notes;
  final List<CheckInLog> logs;
  final DateTime createdAt;
  final bool shareLocationEnabled;

  bool get isActive =>
      status == CheckInStatus.scheduled || status == CheckInStatus.pending;

  DateTime get nextCheckInDue {
    final lastLog = logs.isNotEmpty ? logs.last.timestamp : scheduledDate;
    return lastLog.add(checkInInterval);
  }

  bool get isCheckInOverdue =>
      status == CheckInStatus.pending &&
      DateTime.now().isAfter(nextCheckInDue);

  @override
  List<Object?> get props => [
        id,
        userId,
        matchId,
        matchName,
        locationName,
        latitude,
        longitude,
        scheduledDate,
        checkInTime,
        checkInInterval,
        emergencyContacts,
        status,
        notes,
        logs,
        createdAt,
        shareLocationEnabled,
      ];

  DateCheckIn copyWith({
    String? id,
    String? userId,
    String? matchId,
    String? matchName,
    String? locationName,
    double? latitude,
    double? longitude,
    DateTime? scheduledDate,
    DateTime? checkInTime,
    Duration? checkInInterval,
    List<EmergencyContact>? emergencyContacts,
    CheckInStatus? status,
    String? notes,
    List<CheckInLog>? logs,
    DateTime? createdAt,
    bool? shareLocationEnabled,
  }) {
    return DateCheckIn(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      matchId: matchId ?? this.matchId,
      matchName: matchName ?? this.matchName,
      locationName: locationName ?? this.locationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      checkInTime: checkInTime ?? this.checkInTime,
      checkInInterval: checkInInterval ?? this.checkInInterval,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      logs: logs ?? this.logs,
      createdAt: createdAt ?? this.createdAt,
      shareLocationEnabled: shareLocationEnabled ?? this.shareLocationEnabled,
    );
  }
}

/// Emergency Contact
class EmergencyContact extends Equatable {

  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.relationship, this.email,
    this.notifyOnCheckIn = false,
    this.notifyOnEmergency = true,
  });
  final String id;
  final String name;
  final String phoneNumber;
  final String? email;
  final String relationship;
  final bool notifyOnCheckIn;
  final bool notifyOnEmergency;

  @override
  List<Object?> get props => [
        id,
        name,
        phoneNumber,
        email,
        relationship,
        notifyOnCheckIn,
        notifyOnEmergency,
      ];
}

/// Check-In Log Entry
class CheckInLog extends Equatable {

  const CheckInLog({
    required this.id,
    required this.checkInId,
    required this.timestamp,
    required this.status,
    this.latitude,
    this.longitude,
    this.message,
    this.automaticCheckIn = false,
  });
  final String id;
  final String checkInId;
  final DateTime timestamp;
  final CheckInStatus status;
  final double? latitude;
  final double? longitude;
  final String? message;
  final bool automaticCheckIn;

  @override
  List<Object?> get props => [
        id,
        checkInId,
        timestamp,
        status,
        latitude,
        longitude,
        message,
        automaticCheckIn,
      ];
}
