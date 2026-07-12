import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/event.dart';

/// Event Attendee Model
///
/// Data layer model for EventAttendee entity with Firestore serialization.
class EventAttendeeModel extends EventAttendee {
  const EventAttendeeModel({
    required super.id,
    required super.eventId,
    required super.userId,
    required super.userName,
    required super.status, required super.rsvpDate, super.userPhotoUrl,
    super.isApproved = false,
    super.isInvisible = false,
    super.isAnonymous = false,
    super.muteNotifications = false,
    super.visibleToOrganizerOnly = false,
    super.checkedIn = false,
    super.checkedInAt,
    super.guestCount = 0,
    super.tierId,
  });

  /// Create from EventAttendee entity
  factory EventAttendeeModel.fromEntity(EventAttendee attendee) {
    return EventAttendeeModel(
      id: attendee.id,
      eventId: attendee.eventId,
      userId: attendee.userId,
      userName: attendee.userName,
      userPhotoUrl: attendee.userPhotoUrl,
      status: attendee.status,
      rsvpDate: attendee.rsvpDate,
      isApproved: attendee.isApproved,
      isInvisible: attendee.isInvisible,
      isAnonymous: attendee.isAnonymous,
      muteNotifications: attendee.muteNotifications,
      visibleToOrganizerOnly: attendee.visibleToOrganizerOnly,
      checkedIn: attendee.checkedIn,
      checkedInAt: attendee.checkedInAt,
      guestCount: attendee.guestCount,
      tierId: attendee.tierId,
    );
  }

  /// Create from Firestore document
  factory EventAttendeeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return EventAttendeeModel.fromJson({...data, 'id': doc.id});
  }

  /// Create from JSON map
  factory EventAttendeeModel.fromJson(Map<String, dynamic> json) {
    return EventAttendeeModel(
      id: json['id'] as String? ?? '',
      eventId: json['eventId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      userPhotoUrl: json['userPhotoUrl'] as String?,
      status: _parseRsvpStatus(json['status'] as String?),
      rsvpDate: _parseDateTime(json['rsvpDate']),
      isApproved: json['isApproved'] as bool? ?? false,
      isInvisible: json['isInvisible'] as bool? ?? false,
      isAnonymous: json['isAnonymous'] as bool? ?? false,
      muteNotifications: json['muteNotifications'] as bool? ?? false,
      visibleToOrganizerOnly: json['visibleToOrganizerOnly'] as bool? ?? false,
      checkedIn: json['checkedIn'] as bool? ?? false,
      checkedInAt: json['checkedInAt'] != null
          ? _parseDateTime(json['checkedInAt'])
          : null,
      guestCount: (json['guestCount'] as num?)?.toInt() ?? 0,
      tierId: json['tierId'] as String?,
    );
  }

  /// Convert to JSON map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'status': status.name,
      'rsvpDate': Timestamp.fromDate(rsvpDate),
      'isApproved': isApproved,
      'isInvisible': isInvisible,
      'isAnonymous': isAnonymous,
      'muteNotifications': muteNotifications,
      'visibleToOrganizerOnly': visibleToOrganizerOnly,
      'checkedIn': checkedIn,
      'checkedInAt': checkedInAt != null ? Timestamp.fromDate(checkedInAt!) : null,
      'guestCount': guestCount,
      'tierId': tierId,
    };
  }

  /// Parse RSVPStatus from string
  static RSVPStatus _parseRsvpStatus(String? value) {
    if (value == null) return RSVPStatus.interested;
    try {
      return RSVPStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => RSVPStatus.interested,
      );
    } catch (_) {
      return RSVPStatus.interested;
    }
  }

  /// Parse DateTime from Firestore Timestamp or other formats
  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is DateTime) {
      return value;
    } else if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
