import '../../domain/entities/event.dart';

/// Events BLoC Events
abstract class EventsEvent {
  const EventsEvent();
}

/// Load events with optional filters
class LoadEvents extends EventsEvent {

  const LoadEvents({this.category, this.city, this.upcoming});
  final String? category;
  final String? city;
  final bool? upcoming;
}

/// Load a single event by ID
class LoadEventById extends EventsEvent {

  const LoadEventById({required this.eventId});
  final String eventId;
}

/// Create a new event
class CreateEvent extends EventsEvent {

  const CreateEvent({required this.event});
  final Event event;
}

/// Update an existing event
class UpdateEvent extends EventsEvent {

  const UpdateEvent({required this.event});
  final Event event;
}

/// Delete an event
class DeleteEvent extends EventsEvent {

  const DeleteEvent({required this.eventId});
  final String eventId;
}

/// RSVP to an event
class RsvpEvent extends EventsEvent { // going, interested, notGoing

  const RsvpEvent({
    required this.eventId,
    required this.userId,
    required this.status,
  });
  final String eventId;
  final String userId;
  final String status;
}

/// Cancel RSVP for an event
class CancelRsvp extends EventsEvent {

  const CancelRsvp({required this.eventId, required this.userId});
  final String eventId;
  final String userId;
}

/// Load attendees for an event
class LoadEventAttendees extends EventsEvent {

  const LoadEventAttendees({required this.eventId});
  final String eventId;
}

/// Load events the user created or is attending
class LoadUserEvents extends EventsEvent {

  const LoadUserEvents({required this.userId});
  final String userId;
}

/// Filter events by category (client-side filter on loaded data)
class FilterByCategory extends EventsEvent {

  const FilterByCategory({this.category});
  final EventCategory? category;
}

/// Load events near a location
class LoadNearbyEvents extends EventsEvent {

  const LoadNearbyEvents({
    required this.latitude,
    required this.longitude,
    this.radiusKm = 25.0,
  });
  final double latitude;
  final double longitude;
  final double radiusKm;
}
