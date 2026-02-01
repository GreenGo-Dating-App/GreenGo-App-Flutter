import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/scheduled_date.dart';
import '../models/scheduled_date_model.dart';

/// Remote data source for Date Scheduler
abstract class DateSchedulerRemoteDataSource {
  /// Create a scheduled date
  Future<ScheduledDateModel> createDate({
    required String matchId,
    required String creatorId,
    required String partnerId,
    required String title,
    required DateTime scheduledAt,
    String? venueName,
    String? venueAddress,
    double? venueLat,
    double? venueLng,
    String? venueId,
    String? notes,
  });

  /// Get a date by ID
  Future<ScheduledDateModel> getDate(String dateId);

  /// Get all user dates
  Future<List<ScheduledDateModel>> getUserDates(String userId);

  /// Get upcoming dates
  Future<List<ScheduledDateModel>> getUpcomingDates(String userId);

  /// Confirm a date
  Future<ScheduledDateModel> confirmDate(String dateId);

  /// Cancel a date
  Future<ScheduledDateModel> cancelDate({
    required String dateId,
    required String userId,
    String? reason,
  });

  /// Reschedule a date
  Future<ScheduledDateModel> rescheduleDate({
    required String dateId,
    required DateTime newScheduledAt,
  });

  /// Get venue suggestions
  Future<List<VenueSuggestionModel>> getVenueSuggestions({
    required double lat,
    required double lng,
    VenueCategory? category,
    double radiusKm = 5,
  });

  /// Stream dates
  Stream<List<ScheduledDateModel>> streamDates(String userId);

  /// Set reminder
  Future<DateReminderModel> setReminder({
    required String dateId,
    required DateTime remindAt,
  });

  /// Mark date as completed
  Future<ScheduledDateModel> markCompleted(String dateId);
}

/// Implementation of Date Scheduler remote data source
class DateSchedulerRemoteDataSourceImpl implements DateSchedulerRemoteDataSource {
  final FirebaseFunctions functions;
  final FirebaseFirestore firestore;

  DateSchedulerRemoteDataSourceImpl({
    required this.functions,
    required this.firestore,
  });

  @override
  Future<ScheduledDateModel> createDate({
    required String matchId,
    required String creatorId,
    required String partnerId,
    required String title,
    required DateTime scheduledAt,
    String? venueName,
    String? venueAddress,
    double? venueLat,
    double? venueLng,
    String? venueId,
    String? notes,
  }) async {
    final callable = functions.httpsCallable('createScheduledDate');
    final result = await callable.call<Map<String, dynamic>>({
      'matchId': matchId,
      'creatorId': creatorId,
      'partnerId': partnerId,
      'title': title,
      'scheduledAt': scheduledAt.toIso8601String(),
      'venueName': venueName,
      'venueAddress': venueAddress,
      'venueLat': venueLat,
      'venueLng': venueLng,
      'venueId': venueId,
      'notes': notes,
    });

    return ScheduledDateModel.fromMap(
      result.data['date'] as Map<String, dynamic>,
    );
  }

  @override
  Future<ScheduledDateModel> getDate(String dateId) async {
    final doc = await firestore.collection('scheduledDates').doc(dateId).get();
    if (!doc.exists) {
      throw Exception('Date not found');
    }
    return ScheduledDateModel.fromFirestore(doc);
  }

  @override
  Future<List<ScheduledDateModel>> getUserDates(String userId) async {
    final callable = functions.httpsCallable('getUserScheduledDates');
    final result = await callable.call<Map<String, dynamic>>({
      'userId': userId,
    });

    final dates = result.data['dates'] as List<dynamic>;
    return dates
        .map((d) => ScheduledDateModel.fromMap(d as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ScheduledDateModel>> getUpcomingDates(String userId) async {
    final callable = functions.httpsCallable('getUpcomingDates');
    final result = await callable.call<Map<String, dynamic>>({
      'userId': userId,
    });

    final dates = result.data['dates'] as List<dynamic>;
    return dates
        .map((d) => ScheduledDateModel.fromMap(d as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ScheduledDateModel> confirmDate(String dateId) async {
    final callable = functions.httpsCallable('confirmScheduledDate');
    final result = await callable.call<Map<String, dynamic>>({
      'dateId': dateId,
    });

    return ScheduledDateModel.fromMap(
      result.data['date'] as Map<String, dynamic>,
    );
  }

  @override
  Future<ScheduledDateModel> cancelDate({
    required String dateId,
    required String userId,
    String? reason,
  }) async {
    final callable = functions.httpsCallable('cancelScheduledDate');
    final result = await callable.call<Map<String, dynamic>>({
      'dateId': dateId,
      'userId': userId,
      'reason': reason,
    });

    return ScheduledDateModel.fromMap(
      result.data['date'] as Map<String, dynamic>,
    );
  }

  @override
  Future<ScheduledDateModel> rescheduleDate({
    required String dateId,
    required DateTime newScheduledAt,
  }) async {
    final callable = functions.httpsCallable('rescheduleDate');
    final result = await callable.call<Map<String, dynamic>>({
      'dateId': dateId,
      'newScheduledAt': newScheduledAt.toIso8601String(),
    });

    return ScheduledDateModel.fromMap(
      result.data['date'] as Map<String, dynamic>,
    );
  }

  @override
  Future<List<VenueSuggestionModel>> getVenueSuggestions({
    required double lat,
    required double lng,
    VenueCategory? category,
    double radiusKm = 5,
  }) async {
    final callable = functions.httpsCallable('getVenueSuggestions');
    final result = await callable.call<Map<String, dynamic>>({
      'lat': lat,
      'lng': lng,
      'category': category?.name,
      'radiusKm': radiusKm,
    });

    final venues = result.data['venues'] as List<dynamic>;
    return venues
        .map((v) => VenueSuggestionModel.fromMap(v as Map<String, dynamic>))
        .toList();
  }

  @override
  Stream<List<ScheduledDateModel>> streamDates(String userId) {
    return firestore
        .collection('scheduledDates')
        .where('participants', arrayContains: userId)
        .orderBy('scheduledAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ScheduledDateModel.fromFirestore(doc))
            .toList());
  }

  @override
  Future<DateReminderModel> setReminder({
    required String dateId,
    required DateTime remindAt,
  }) async {
    final callable = functions.httpsCallable('setDateReminder');
    final result = await callable.call<Map<String, dynamic>>({
      'dateId': dateId,
      'remindAt': remindAt.toIso8601String(),
    });

    return DateReminderModel.fromMap(
      result.data['reminder'] as Map<String, dynamic>,
    );
  }

  @override
  Future<ScheduledDateModel> markCompleted(String dateId) async {
    final callable = functions.httpsCallable('markDateCompleted');
    final result = await callable.call<Map<String, dynamic>>({
      'dateId': dateId,
    });

    return ScheduledDateModel.fromMap(
      result.data['date'] as Map<String, dynamic>,
    );
  }
}
