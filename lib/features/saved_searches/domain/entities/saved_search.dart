import 'package:equatable/equatable.dart';

import '../../../discovery/domain/entities/match_preferences.dart';

/// A single saved discovery "search" — a named snapshot of the Network
/// Discovery filter state the user chose to keep.
///
/// A "search" is the full current filter state of the Network Discovery grid:
/// the discovery [MatchPreferences], the selected private people-[tags] and the
/// nickname [query]. Re-running a saved search re-applies all three.
///
/// Persisted at `saved_searches/{userId}/searches/{id}` — a private per-user
/// subcollection so every read is bounded and index-free.
class SavedSearch extends Equatable {
  const SavedSearch({
    required this.id,
    required this.name,
    required this.preferences,
    this.tags = const [],
    this.query = '',
    this.alertsEnabled = false,
    this.createdAt,
  });

  /// Rebuilds a [SavedSearch] from its Firestore document map. Tolerant of
  /// missing/legacy fields so a partially-written doc never crashes the list.
  factory SavedSearch.fromMap(String id, Map<String, dynamic> map) {
    final rawPrefs = map['preferences'];
    final preferences = rawPrefs is Map
        ? MatchPreferences.fromMap(Map<String, dynamic>.from(rawPrefs))
        : MatchPreferences.defaultFor('');
    final rawCreated = map['createdAt'];
    DateTime? createdAt;
    if (rawCreated != null) {
      // Firestore Timestamp exposes toDate(); guard defensively.
      try {
        createdAt = (rawCreated as dynamic).toDate() as DateTime?;
      } catch (_) {
        createdAt = null;
      }
    }
    return SavedSearch(
      id: id,
      name: map['name'] as String? ?? '',
      preferences: preferences,
      tags: (map['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      query: map['query'] as String? ?? '',
      alertsEnabled: map['alertsEnabled'] as bool? ?? false,
      createdAt: createdAt,
    );
  }

  final String id;
  final String name;
  final MatchPreferences preferences;
  final List<String> tags;
  final String query;
  final bool alertsEnabled;
  final DateTime? createdAt;

  @override
  List<Object?> get props =>
      [id, name, preferences, tags, query, alertsEnabled, createdAt];
}
