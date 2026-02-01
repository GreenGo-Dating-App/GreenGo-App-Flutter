import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/share_my_date.dart';

/// Trusted Contact Model
class TrustedContactModel extends TrustedContact {
  const TrustedContactModel({
    required super.id,
    required super.userId,
    required super.contactName,
    required super.contactPhone,
    super.contactEmail,
    super.isVerified = false,
    required super.createdAt,
    super.lastNotifiedAt,
  });

  factory TrustedContactModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TrustedContactModel(
      id: doc.id,
      userId: data['userId'] as String,
      contactName: data['contactName'] as String,
      contactPhone: data['contactPhone'] as String,
      contactEmail: data['contactEmail'] as String?,
      isVerified: data['isVerified'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastNotifiedAt: data['lastNotifiedAt'] != null
          ? (data['lastNotifiedAt'] as Timestamp).toDate()
          : null,
    );
  }

  factory TrustedContactModel.fromMap(Map<String, dynamic> map) {
    return TrustedContactModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      contactName: map['contactName'] as String,
      contactPhone: map['contactPhone'] as String,
      contactEmail: map['contactEmail'] as String?,
      isVerified: map['isVerified'] as bool? ?? false,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt'] as String),
      lastNotifiedAt: map['lastNotifiedAt'] != null
          ? (map['lastNotifiedAt'] is Timestamp
              ? (map['lastNotifiedAt'] as Timestamp).toDate()
              : DateTime.parse(map['lastNotifiedAt'] as String))
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'contactName': contactName,
      'contactPhone': contactPhone,
      'contactEmail': contactEmail,
      'isVerified': isVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastNotifiedAt':
          lastNotifiedAt != null ? Timestamp.fromDate(lastNotifiedAt!) : null,
    };
  }
}

/// Shared Date Model
class SharedDateModel extends SharedDate {
  const SharedDateModel({
    required super.id,
    required super.userId,
    required super.scheduledDateId,
    required super.matchName,
    super.matchPhotoUrl,
    required super.dateTime,
    super.venueName,
    super.venueAddress,
    super.venueLat,
    super.venueLng,
    super.notifiedContactIds = const [],
    super.status = ShareStatus.pending,
    super.checkInTime,
    super.safeArrivalTime,
    required super.createdAt,
    super.emergencyNote,
  });

  factory SharedDateModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SharedDateModel(
      id: doc.id,
      userId: data['userId'] as String,
      scheduledDateId: data['scheduledDateId'] as String,
      matchName: data['matchName'] as String,
      matchPhotoUrl: data['matchPhotoUrl'] as String?,
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      venueName: data['venueName'] as String?,
      venueAddress: data['venueAddress'] as String?,
      venueLat: (data['venueLat'] as num?)?.toDouble(),
      venueLng: (data['venueLng'] as num?)?.toDouble(),
      notifiedContactIds: List<String>.from(data['notifiedContactIds'] ?? []),
      status: ShareStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => ShareStatus.pending,
      ),
      checkInTime: data['checkInTime'] != null
          ? (data['checkInTime'] as Timestamp).toDate()
          : null,
      safeArrivalTime: data['safeArrivalTime'] != null
          ? (data['safeArrivalTime'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      emergencyNote: data['emergencyNote'] as String?,
    );
  }

  factory SharedDateModel.fromMap(Map<String, dynamic> map) {
    return SharedDateModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      scheduledDateId: map['scheduledDateId'] as String,
      matchName: map['matchName'] as String,
      matchPhotoUrl: map['matchPhotoUrl'] as String?,
      dateTime: map['dateTime'] is Timestamp
          ? (map['dateTime'] as Timestamp).toDate()
          : DateTime.parse(map['dateTime'] as String),
      venueName: map['venueName'] as String?,
      venueAddress: map['venueAddress'] as String?,
      venueLat: (map['venueLat'] as num?)?.toDouble(),
      venueLng: (map['venueLng'] as num?)?.toDouble(),
      notifiedContactIds: List<String>.from(map['notifiedContactIds'] ?? []),
      status: ShareStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => ShareStatus.pending,
      ),
      checkInTime: map['checkInTime'] != null
          ? (map['checkInTime'] is Timestamp
              ? (map['checkInTime'] as Timestamp).toDate()
              : DateTime.parse(map['checkInTime'] as String))
          : null,
      safeArrivalTime: map['safeArrivalTime'] != null
          ? (map['safeArrivalTime'] is Timestamp
              ? (map['safeArrivalTime'] as Timestamp).toDate()
              : DateTime.parse(map['safeArrivalTime'] as String))
          : null,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt'] as String),
      emergencyNote: map['emergencyNote'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'scheduledDateId': scheduledDateId,
      'matchName': matchName,
      'matchPhotoUrl': matchPhotoUrl,
      'dateTime': Timestamp.fromDate(dateTime),
      'venueName': venueName,
      'venueAddress': venueAddress,
      'venueLat': venueLat,
      'venueLng': venueLng,
      'notifiedContactIds': notifiedContactIds,
      'status': status.name,
      'checkInTime':
          checkInTime != null ? Timestamp.fromDate(checkInTime!) : null,
      'safeArrivalTime': safeArrivalTime != null
          ? Timestamp.fromDate(safeArrivalTime!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'emergencyNote': emergencyNote,
    };
  }
}

/// Safety Check-In Model
class SafetyCheckInModel extends SafetyCheckIn {
  const SafetyCheckInModel({
    required super.sharedDateId,
    required super.checkInTime,
    super.lat,
    super.lng,
    super.atExpectedLocation = false,
    super.note,
  });

  factory SafetyCheckInModel.fromMap(Map<String, dynamic> map) {
    return SafetyCheckInModel(
      sharedDateId: map['sharedDateId'] as String,
      checkInTime: map['checkInTime'] is Timestamp
          ? (map['checkInTime'] as Timestamp).toDate()
          : DateTime.parse(map['checkInTime'] as String),
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      atExpectedLocation: map['atExpectedLocation'] as bool? ?? false,
      note: map['note'] as String?,
    );
  }
}

/// Emergency Alert Model
class EmergencyAlertModel extends EmergencyAlert {
  const EmergencyAlertModel({
    required super.id,
    required super.sharedDateId,
    required super.userId,
    required super.triggeredAt,
    super.lat,
    super.lng,
    super.notifiedContacts = const [],
    super.note,
  });

  factory EmergencyAlertModel.fromMap(Map<String, dynamic> map) {
    return EmergencyAlertModel(
      id: map['id'] as String,
      sharedDateId: map['sharedDateId'] as String,
      userId: map['userId'] as String,
      triggeredAt: map['triggeredAt'] is Timestamp
          ? (map['triggeredAt'] as Timestamp).toDate()
          : DateTime.parse(map['triggeredAt'] as String),
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      notifiedContacts: List<String>.from(map['notifiedContacts'] ?? []),
      note: map['note'] as String?,
    );
  }
}
