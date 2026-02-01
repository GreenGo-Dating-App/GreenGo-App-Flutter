import 'package:equatable/equatable.dart';

/// Scheduled Date Entity
class ScheduledDate extends Equatable {
  final String id;
  final String matchId;
  final String creatorId;
  final String partnerId;
  final String title;
  final DateTime scheduledAt;
  final String? venueName;
  final String? venueAddress;
  final double? venueLat;
  final double? venueLng;
  final String? venueId;
  final DateStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? cancelledAt;
  final String? cancelledBy;
  final String? cancellationReason;

  const ScheduledDate({
    required this.id,
    required this.matchId,
    required this.creatorId,
    required this.partnerId,
    required this.title,
    required this.scheduledAt,
    this.venueName,
    this.venueAddress,
    this.venueLat,
    this.venueLng,
    this.venueId,
    this.status = DateStatus.pending,
    this.notes,
    required this.createdAt,
    this.confirmedAt,
    this.cancelledAt,
    this.cancelledBy,
    this.cancellationReason,
  });

  @override
  List<Object?> get props => [
        id,
        matchId,
        creatorId,
        partnerId,
        title,
        scheduledAt,
        venueName,
        venueAddress,
        venueLat,
        venueLng,
        venueId,
        status,
        notes,
        createdAt,
        confirmedAt,
        cancelledAt,
        cancelledBy,
        cancellationReason,
      ];

  /// Check if date is upcoming
  bool get isUpcoming =>
      status == DateStatus.confirmed &&
      scheduledAt.isAfter(DateTime.now());

  /// Check if date is today
  bool get isToday {
    final now = DateTime.now();
    return scheduledAt.year == now.year &&
        scheduledAt.month == now.month &&
        scheduledAt.day == now.day;
  }

  /// Check if date is in the past
  bool get isPast => scheduledAt.isBefore(DateTime.now());

  /// Time until date
  Duration get timeUntil => scheduledAt.difference(DateTime.now());

  /// Format date for display
  String get formattedDate {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[scheduledAt.month - 1]} ${scheduledAt.day}';
  }

  /// Format time for display
  String get formattedTime {
    final hour = scheduledAt.hour;
    final minute = scheduledAt.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  /// Has venue
  bool get hasVenue => venueName != null && venueName!.isNotEmpty;

  /// Has location coordinates
  bool get hasLocation => venueLat != null && venueLng != null;
}

/// Date Status
enum DateStatus {
  pending,    // Waiting for partner confirmation
  confirmed,  // Both parties confirmed
  cancelled,  // One party cancelled
  completed,  // Date happened
  missed,     // Date time passed without confirmation
}

/// Venue Suggestion
class VenueSuggestion extends Equatable {
  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final double? rating;
  final int? reviewCount;
  final String? photoUrl;
  final VenueCategory category;
  final double? distance;
  final String? priceLevel;
  final bool isOpen;

  const VenueSuggestion({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    this.rating,
    this.reviewCount,
    this.photoUrl,
    required this.category,
    this.distance,
    this.priceLevel,
    this.isOpen = true,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        address,
        lat,
        lng,
        rating,
        reviewCount,
        photoUrl,
        category,
        distance,
        priceLevel,
        isOpen,
      ];

  /// Format distance for display
  String get formattedDistance {
    if (distance == null) return '';
    if (distance! < 1) {
      return '${(distance! * 1000).round()} m';
    }
    return '${distance!.toStringAsFixed(1)} km';
  }

  /// Format rating for display
  String get formattedRating {
    if (rating == null) return 'No rating';
    return rating!.toStringAsFixed(1);
  }
}

/// Venue Category
enum VenueCategory {
  restaurant,
  cafe,
  bar,
  park,
  museum,
  theater,
  other,
}

extension VenueCategoryExtension on VenueCategory {
  String get displayName {
    switch (this) {
      case VenueCategory.restaurant:
        return 'Restaurant';
      case VenueCategory.cafe:
        return 'Cafe';
      case VenueCategory.bar:
        return 'Bar';
      case VenueCategory.park:
        return 'Park';
      case VenueCategory.museum:
        return 'Museum';
      case VenueCategory.theater:
        return 'Theater';
      case VenueCategory.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case VenueCategory.restaurant:
        return '🍽️';
      case VenueCategory.cafe:
        return '☕';
      case VenueCategory.bar:
        return '🍸';
      case VenueCategory.park:
        return '🌳';
      case VenueCategory.museum:
        return '🏛️';
      case VenueCategory.theater:
        return '🎭';
      case VenueCategory.other:
        return '📍';
    }
  }
}

/// Date Reminder
class DateReminder extends Equatable {
  final String id;
  final String dateId;
  final DateTime remindAt;
  final bool isNotified;

  const DateReminder({
    required this.id,
    required this.dateId,
    required this.remindAt,
    this.isNotified = false,
  });

  @override
  List<Object?> get props => [id, dateId, remindAt, isNotified];
}
