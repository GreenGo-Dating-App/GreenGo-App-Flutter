import '../../domain/entities/event.dart';

/// Events BLoC Events
abstract class EventsEvent {
  const EventsEvent();
}

/// Load events with optional filters
class LoadEvents extends EventsEvent {
  final String? category;
  final String? city;
  final bool? upcoming;

  const LoadEvents({this.category, this.city, this.upcoming});
}

/// Load a single event by ID
class LoadEventById extends EventsEvent {
  final String eventId;

  const LoadEventById({required this.eventId});
}

/// Create a new event
class CreateEvent extends EventsEvent {
  final Event event;

  const CreateEvent({required this.event});
}

/// Update an existing event
class UpdateEvent extends EventsEvent {
  final Event event;

  const UpdateEvent({required this.event});
}

/// Delete an event
class DeleteEvent extends EventsEvent {
  final String eventId;

  const DeleteEvent({required this.eventId});
}

/// RSVP to an event
class RsvpEvent extends EventsEvent {
  final String eventId;
  final String userId;
  final String status; // going, interested, notGoing

  const RsvpEvent({
    required this.eventId,
    required this.userId,
    required this.status,
  });
}

/// Cancel RSVP for an event
class CancelRsvp extends EventsEvent {
  final String eventId;
  final String userId;

  const CancelRsvp({required this.eventId, required this.userId});
}

/// Load attendees for an event
class LoadEventAttendees extends EventsEvent {
  final String eventId;

  const LoadEventAttendees({required this.eventId});
}

/// Load events the user created or is attending
class LoadUserEvents extends EventsEvent {
  final String userId;

  const LoadUserEvents({required this.userId});
}

/// Filter events by category (client-side filter on loaded data)
class FilterByCategory extends EventsEvent {
  final EventCategory? category;

  const FilterByCategory({this.category});
}

/// Load events near a location
class LoadNearbyEvents extends EventsEvent {
  final double latitude;
  final double longitude;
  final double radiusKm;

  const LoadNearbyEvents({
    required this.latitude,
    required this.longitude,
    this.radiusKm = 25.0,
  });
}
