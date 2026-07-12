import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/event.dart';
import '../models/event_model.dart';

/// EventsCacheService — a lightweight, per-feed **daily** cache for the events
/// feed list.
///
/// Rationale (scale/perf): the community events feed is read on every open of
/// the Events screen. Re-querying Firestore each time — for a feed that changes
/// slowly over a day — burns reads at millions-of-users scale. This service
/// persists the first page of a feed (JSON) plus a `cachedAtDay` stamp
/// (yyyy-MM-dd) to SharedPreferences. Within the same calendar day the tab
/// serves the cache and skips the network; a pull-to-refresh always bypasses
/// the cache, re-fetches, and re-stamps.
///
/// Storage shape (one SharedPreferences string per feed key):
/// ```json
/// { "cachedAtDay": "2026-07-11", "events": [ { ...eventJson... }, ... ] }
/// ```
/// Event maps are produced from [EventModel.toJson] and made JSON-safe by
/// converting Firestore [Timestamp]s to ISO-8601 strings; they round-trip back
/// through [EventModel.fromJson] (which already parses ISO date strings).
class EventsCacheService {
  const EventsCacheService();

  static const String _prefix = 'events_feed_cache_';

  /// Today's date stamped as `yyyy-MM-dd` in local time. Used to decide whether
  /// a cached feed is still "fresh" (same calendar day).
  static String _todayStamp() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _keyFor(String feedKey) => '$_prefix$feedKey';

  /// Returns the cached feed for [feedKey] **only if** it was stamped today;
  /// otherwise (stale, absent, or unreadable) returns null so the caller does a
  /// network fetch. Never throws — a corrupt entry is treated as a cache miss.
  Future<List<Event>?> getCachedIfFresh(String feedKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyFor(feedKey));
      if (raw == null || raw.isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      if (decoded['cachedAtDay'] != _todayStamp()) return null; // stale → miss

      final list = decoded['events'];
      if (list is! List) return null;
      return list
          .whereType<Map>()
          .map((m) => EventModel.fromJson(Map<String, dynamic>.from(m)))
          .cast<Event>()
          .toList();
    } catch (_) {
      return null; // any parse/IO error → treat as a miss, fall back to network
    }
  }

  /// Persists [events] for [feedKey] and stamps it with today's date. Called
  /// after every network fetch (initial cold load and pull-to-refresh).
  Future<void> save(String feedKey, List<Event> events) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = <String, dynamic>{
        'cachedAtDay': _todayStamp(),
        'events': events.map(_eventToJsonSafe).toList(),
      };
      await prefs.setString(_keyFor(feedKey), jsonEncode(payload));
    } catch (_) {
      // Best-effort cache write; a failure just means the next open re-fetches.
    }
  }

  /// Clears a single feed's cache (e.g. on sign-out, if a caller wants to).
  Future<void> clear(String feedKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyFor(feedKey));
    } catch (_) {}
  }

  /// Serialize an [Event] to a JSON-safe map. [EventModel.toJson] emits
  /// Firestore [Timestamp]s (and nested maps that may contain them), which
  /// `jsonEncode` cannot handle; [_sanitize] rewrites every Timestamp to an
  /// ISO-8601 string that [EventModel.fromJson] reads back correctly.
  static Map<String, dynamic> _eventToJsonSafe(Event event) {
    final model =
        event is EventModel ? event : EventModel.fromEntity(event);
    final json = model.toJson();
    // Keep the id — toJson() omits it (Firestore stores it as the doc id), but
    // the cache round-trips through fromJson which needs it.
    json['id'] = event.id;
    return _sanitize(json) as Map<String, dynamic>;
  }

  /// Recursively convert Firestore [Timestamp] values into ISO-8601 strings so
  /// the structure is safe for [jsonEncode]. Maps and lists are walked.
  static dynamic _sanitize(dynamic value) {
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is DateTime) return value.toIso8601String();
    if (value is Map) {
      return value.map<String, dynamic>(
          (k, v) => MapEntry(k.toString(), _sanitize(v)));
    }
    if (value is List) return value.map(_sanitize).toList();
    return value;
  }
}
