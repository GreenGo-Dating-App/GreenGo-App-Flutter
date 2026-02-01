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

  const DateCheckIn({
    required this.id,
    required this.userId,
    this.matchId,
    this.matchName,
    required this.locationName,
    this.latitude,
    this.longitude,
    required this.scheduledDate,
    this.checkInTime,
    this.checkInInterval = const Duration(minutes: 30),
    this.emergencyContacts = const [],
    required this.status,
    this.notes,
    this.logs = const [],
    required this.createdAt,
    this.shareLocationEnabled = false,
  });

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
  final String id;
  final String name;
  final String phoneNumber;
  final String? email;
  final String relationship;
  final bool notifyOnCheckIn;
  final bool notifyOnEmergency;

  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.email,
    required this.relationship,
    this.notifyOnCheckIn = false,
    this.notifyOnEmergency = true,
  });

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
  final String id;
  final String checkInId;
  final DateTime timestamp;
  final CheckInStatus status;
  final double? latitude;
  final double? longitude;
  final String? message;
  final bool automaticCheckIn;

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
