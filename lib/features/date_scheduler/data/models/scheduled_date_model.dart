import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/scheduled_date.dart';

/// Scheduled Date Model
class ScheduledDateModel extends ScheduledDate {
  const ScheduledDateModel({
    required super.id,
    required super.matchId,
    required super.creatorId,
    required super.partnerId,
    required super.title,
    required super.scheduledAt,
    super.venueName,
    super.venueAddress,
    super.venueLat,
    super.venueLng,
    super.venueId,
    super.status = DateStatus.pending,
    super.notes,
    required super.createdAt,
    super.confirmedAt,
    super.cancelledAt,
    super.cancelledBy,
    super.cancellationReason,
  });

  factory ScheduledDateModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ScheduledDateModel(
      id: doc.id,
      matchId: data['matchId'] as String,
      creatorId: data['creatorId'] as String,
      partnerId: data['partnerId'] as String,
      title: data['title'] as String,
      scheduledAt: (data['scheduledAt'] as Timestamp).toDate(),
      venueName: data['venueName'] as String?,
      venueAddress: data['venueAddress'] as String?,
      venueLat: (data['venueLat'] as num?)?.toDouble(),
      venueLng: (data['venueLng'] as num?)?.toDouble(),
      venueId: data['venueId'] as String?,
      status: DateStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => DateStatus.pending,
      ),
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      confirmedAt: data['confirmedAt'] != null
          ? (data['confirmedAt'] as Timestamp).toDate()
          : null,
      cancelledAt: data['cancelledAt'] != null
          ? (data['cancelledAt'] as Timestamp).toDate()
          : null,
      cancelledBy: data['cancelledBy'] as String?,
      cancellationReason: data['cancellationReason'] as String?,
    );
  }

  factory ScheduledDateModel.fromMap(Map<String, dynamic> map) {
    return ScheduledDateModel(
      id: map['id'] as String,
      matchId: map['matchId'] as String,
      creatorId: map['creatorId'] as String,
      partnerId: map['partnerId'] as String,
      title: map['title'] as String,
      scheduledAt: map['scheduledAt'] is Timestamp
          ? (map['scheduledAt'] as Timestamp).toDate()
          : DateTime.parse(map['scheduledAt'] as String),
      venueName: map['venueName'] as String?,
      venueAddress: map['venueAddress'] as String?,
      venueLat: (map['venueLat'] as num?)?.toDouble(),
      venueLng: (map['venueLng'] as num?)?.toDouble(),
      venueId: map['venueId'] as String?,
      status: DateStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => DateStatus.pending,
      ),
      notes: map['notes'] as String?,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt'] as String),
      confirmedAt: map['confirmedAt'] != null
          ? (map['confirmedAt'] is Timestamp
              ? (map['confirmedAt'] as Timestamp).toDate()
              : DateTime.parse(map['confirmedAt'] as String))
          : null,
      cancelledAt: map['cancelledAt'] != null
          ? (map['cancelledAt'] is Timestamp
              ? (map['cancelledAt'] as Timestamp).toDate()
              : DateTime.parse(map['cancelledAt'] as String))
          : null,
      cancelledBy: map['cancelledBy'] as String?,
      cancellationReason: map['cancellationReason'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'matchId': matchId,
      'creatorId': creatorId,
      'partnerId': partnerId,
      'title': title,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'venueName': venueName,
      'venueAddress': venueAddress,
      'venueLat': venueLat,
      'venueLng': venueLng,
      'venueId': venueId,
      'status': status.name,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'confirmedAt':
          confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
      'cancelledAt':
          cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'cancelledBy': cancelledBy,
      'cancellationReason': cancellationReason,
    };
  }
}

/// Venue Suggestion Model
class VenueSuggestionModel extends VenueSuggestion {
  const VenueSuggestionModel({
    required super.id,
    required super.name,
    required super.address,
    required super.lat,
    required super.lng,
    super.rating,
    super.reviewCount,
    super.photoUrl,
    required super.category,
    super.distance,
    super.priceLevel,
    super.isOpen = true,
  });

  factory VenueSuggestionModel.fromMap(Map<String, dynamic> map) {
    return VenueSuggestionModel(
      id: map['id'] as String,
      name: map['name'] as String,
      address: map['address'] as String,
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
      rating: (map['rating'] as num?)?.toDouble(),
      reviewCount: (map['reviewCount'] as num?)?.toInt(),
      photoUrl: map['photoUrl'] as String?,
      category: VenueCategory.values.firstWhere(
        (c) => c.name == map['category'],
        orElse: () => VenueCategory.other,
      ),
      distance: (map['distance'] as num?)?.toDouble(),
      priceLevel: map['priceLevel'] as String?,
      isOpen: map['isOpen'] as bool? ?? true,
    );
  }
}

/// Date Reminder Model
class DateReminderModel extends DateReminder {
  const DateReminderModel({
    required super.id,
    required super.dateId,
    required super.remindAt,
    super.isNotified = false,
  });

  factory DateReminderModel.fromMap(Map<String, dynamic> map) {
    return DateReminderModel(
      id: map['id'] as String,
      dateId: map['dateId'] as String,
      remindAt: map['remindAt'] is Timestamp
          ? (map['remindAt'] as Timestamp).toDate()
          : DateTime.parse(map['remindAt'] as String),
      isNotified: map['isNotified'] as bool? ?? false,
    );
  }
}
