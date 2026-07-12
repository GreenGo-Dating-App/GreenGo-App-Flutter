import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Cultural Passport — a gamified, Apple-safe collection of "stamps" the user
/// earns as they engage with the app's cross-cultural surfaces.
///
/// Three stamp families:
///  * [countryStamps]   — ISO 3166-1 alpha-2 codes for the countries of the
///                        people the user has conversations with.
///  * [languageStamps]  — language names the user speaks / is learning, plus
///                        the languages of their chat partners.
///  * [eventStamps]      — [EventCategory] names for events the user RSVP'd to.
///
/// Persisted at `user_passports/{userId}`; every list is deduped and the doc
/// carries a server [updatedAt]. Stamps can be *derived* from existing data on
/// read (see `PassportService.load`) and *awarded* explicitly for future
/// triggers, then merged — so the passport is always at least as complete as
/// the user's real activity, and never loses an explicitly-granted stamp.
class CulturalPassport extends Equatable {
  const CulturalPassport({
    this.countryStamps = const <String>[],
    this.languageStamps = const <String>[],
    this.eventStamps = const <String>[],
    this.updatedAt,
  });

  /// Builds an empty passport (no stamps yet).
  const CulturalPassport.empty() : this();

  /// Reads a stored `user_passports/{userId}` document body.
  factory CulturalPassport.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const CulturalPassport.empty();
    return CulturalPassport(
      countryStamps: _stringList(data['countryStamps']),
      languageStamps: _stringList(data['languageStamps']),
      eventStamps: _stringList(data['eventStamps']),
      updatedAt: _dateTime(data['updatedAt']),
    );
  }

  /// ISO 3166-1 alpha-2 country codes (upper-case), deduped.
  final List<String> countryStamps;

  /// Language names, deduped.
  final List<String> languageStamps;

  /// [EventCategory] names, deduped.
  final List<String> eventStamps;

  /// Last time the stored document was written (server time).
  final DateTime? updatedAt;

  /// Total number of stamps across all three families.
  int get totalStamps =>
      countryStamps.length + languageStamps.length + eventStamps.length;

  /// Whether the user has earned no stamps at all.
  bool get isEmpty => totalStamps == 0;

  /// Firestore write body (without [updatedAt]; the service stamps that).
  Map<String, dynamic> toMap() => <String, dynamic>{
        'countryStamps': countryStamps,
        'languageStamps': languageStamps,
        'eventStamps': eventStamps,
      };

  CulturalPassport copyWith({
    List<String>? countryStamps,
    List<String>? languageStamps,
    List<String>? eventStamps,
    DateTime? updatedAt,
  }) {
    return CulturalPassport(
      countryStamps: countryStamps ?? this.countryStamps,
      languageStamps: languageStamps ?? this.languageStamps,
      eventStamps: eventStamps ?? this.eventStamps,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const <String>[];
    final seen = <String>{};
    final out = <String>[];
    for (final item in value) {
      if (item == null) continue;
      final s = item.toString().trim();
      if (s.isEmpty) continue;
      if (seen.add(s)) out.add(s);
    }
    return out;
  }

  static DateTime? _dateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  List<Object?> get props =>
      [countryStamps, languageStamps, eventStamps, updatedAt];
}
