import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/event.dart';
import '../../domain/repositories/events_repository.dart';
import '../datasources/events_remote_datasource.dart';

/// Events Repository Implementation
///
/// Delegates all operations to the remote data source.
/// Wraps exceptions into Failure types for clean error handling.
class EventsRepositoryImpl implements EventsRepository {
  final EventsRemoteDataSource remoteDataSource;

  EventsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Event>>> getEvents({
    String? category,
    String? city,
    bool? upcoming,
  }) async {
    try {
      final events = await remoteDataSource.getEvents(
        category: category,
        city: city,
        upcoming: upcoming,
      );
      return Right(events);
    } on ServerException catch (e) {
      debugPrint('ServerException in getEvents: ${e.message}');
      return Left(ServerFailure(e.message));
    } catch (e) {
      debugPrint('Error in getEvents: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Event?>> getEventById(String id) async {
    try {
      final event = await remoteDataSource.getEventById(id);
      return Right(event);
    } on ServerException catch (e) {
      debugPrint('ServerException in getEventById: ${e.message}');
      return Left(ServerFailure(e.message));
    } catch (e) {
      debugPrint('Error in getEventById: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> createEvent(Event event) async {
    try {
      final eventId = await remoteDataSource.createEvent(event);
      return Right(eventId);
    } on ServerException catch (e) {
      debugPrint('ServerException in createEvent: ${e.message}');
      return Left(ServerFailure(e.message));
    } catch (e) {
      debugPrint('Error in createEvent: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateEvent(Event event) async {
    try {
      await remoteDataSource.updateEvent(event);
      return const Right(null);
    } on ServerException catch (e) {
      debugPrint('ServerException in updateEvent: ${e.message}');
      return Left(ServerFailure(e.message));
    } catch (e) {
      debugPrint('Error in updateEvent: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteEvent(String eventId) async {
    try {
      await remoteDataSource.deleteEvent(eventId);
      return const Right(null);
    } on ServerException catch (e) {
      debugPrint('ServerException in deleteEvent: ${e.message}');
      return Left(ServerFailure(e.message));
    } catch (e) {
      debugPrint('Error in deleteEvent: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> rsvpEvent(
    String eventId,
    String userId,
    String status,
  ) async {
    try {
      await remoteDataSource.rsvpEvent(eventId, userId, status);
      return const Right(null);
    } on ServerException catch (e) {
      debugPrint('ServerException in rsvpEvent: ${e.message}');
      return Left(ServerFailure(e.message));
    } catch (e) {
      debugPrint('Error in rsvpEvent: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> cancelRsvp(
    String eventId,
    String userId,
  ) async {
    try {
      await remoteDataSource.cancelRsvp(eventId, userId);
      return const Right(null);
    } on ServerException catch (e) {
      debugPrint('ServerException in cancelRsvp: ${e.message}');
      return Left(ServerFailure(e.message));
    } catch (e) {
      debugPrint('Error in cancelRsvp: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<EventAttendee>>> getEventAttendees(
    String eventId,
  ) async {
    try {
      final attendees = await remoteDataSource.getEventAttendees(eventId);
      return Right(attendees);
    } on ServerException catch (e) {
      debugPrint('ServerException in getEventAttendees: ${e.message}');
      return Left(ServerFailure(e.message));
    } catch (e) {
      debugPrint('Error in getEventAttendees: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Event>>> getEventsNearLocation(
    double lat,
    double lng,
    double radiusKm,
  ) async {
    try {
      final events = await remoteDataSource.getEventsNearLocation(
        lat,
        lng,
        radiusKm,
      );
      return Right(events);
    } on ServerException catch (e) {
      debugPrint('ServerException in getEventsNearLocation: ${e.message}');
      return Left(ServerFailure(e.message));
    } catch (e) {
      debugPrint('Error in getEventsNearLocation: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Event>>> getUserEvents(String userId) async {
    try {
      final events = await remoteDataSource.getUserEvents(userId);
      return Right(events);
    } on ServerException catch (e) {
      debugPrint('ServerException in getUserEvents: ${e.message}');
      return Left(ServerFailure(e.message));
    } catch (e) {
      debugPrint('Error in getUserEvents: $e');
      return Left(ServerFailure(e.toString()));
    }
  }
}
