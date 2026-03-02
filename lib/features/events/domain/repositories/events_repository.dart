import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/event.dart';

/// Events Repository Interface
abstract class EventsRepository {
  /// Get events with optional filters
  Future<Either<Failure, List<Event>>> getEvents({
    String? category,
    String? city,
    bool? upcoming,
  });

  /// Get a single event by ID
  Future<Either<Failure, Event?>> getEventById(String id);

  /// Create a new event, returns the event ID
  Future<Either<Failure, String>> createEvent(Event event);

  /// Update an existing event
  Future<Either<Failure, void>> updateEvent(Event event);

  /// Delete an event
  Future<Either<Failure, void>> deleteEvent(String eventId);

  /// RSVP to an event
  Future<Either<Failure, void>> rsvpEvent(
    String eventId,
    String userId,
    String status,
  );

  /// Cancel RSVP for an event
  Future<Either<Failure, void>> cancelRsvp(String eventId, String userId);

  /// Get attendees for an event
  Future<Either<Failure, List<EventAttendee>>> getEventAttendees(
    String eventId,
  );

  /// Get events near a location within a radius
  Future<Either<Failure, List<Event>>> getEventsNearLocation(
    double lat,
    double lng,
    double radiusKm,
  );

  /// Get events the user created or is attending
  Future<Either<Failure, List<Event>>> getUserEvents(String userId);
}
