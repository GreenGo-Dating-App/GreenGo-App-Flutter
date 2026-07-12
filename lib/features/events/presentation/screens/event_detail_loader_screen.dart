import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/interaction_log_service.dart';
import '../../../../generated/app_localizations.dart';
import '../bloc/events_bloc.dart';
import '../bloc/events_event.dart';
import '../bloc/events_state.dart';
import 'events_screen.dart';

/// Per-session in-memory guard so the repeated `BlocBuilder` rebuilds on one
/// screen open cannot each kick off an async view-count write before the
/// SharedPreferences day-marker is persisted. Holds `{userId}_{eventId}_{day}`.
final Set<String> _viewCountedThisSession = <String>{};

/// Increment `events/{eventId}.viewCount` exactly once per user, per event, per
/// day. Deduped by a SharedPreferences marker (`evview_{uid}_{eventId}_{day}`)
/// so reopening the same event later the same day does NOT re-increment, and a
/// per-session in-memory guard so a single open's rebuilds don't race.
///
/// Fire-and-forget: every failure is swallowed — a view counter must never
/// surface an error into the UI, and a dropped increment is harmless.
Future<void> _recordEventView(String eventId, String userId) async {
  if (eventId.isEmpty) return;
  final now = DateTime.now();
  final day = '${now.year.toString().padLeft(4, '0')}'
      '${now.month.toString().padLeft(2, '0')}'
      '${now.day.toString().padLeft(2, '0')}';
  final marker = 'evview_${userId}_${eventId}_$day';
  if (!_viewCountedThisSession.add(marker)) return; // already handled this session
  try {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(marker) ?? false) return; // already counted today
    await prefs.setBool(marker, true);
    await FirebaseFirestore.instance
        .collection('events')
        .doc(eventId)
        .update({'viewCount': FieldValue.increment(1)});
  } catch (_) {
    // Non-fatal: allow a retry later this session if the write failed.
    _viewCountedThisSession.remove(marker);
  }
}

/// Loads an event by id (e.g. when opening a shared event card from a chat)
/// and shows the full [EventDetailsScreen]. Provides its own [EventsBloc] so it
/// works from anywhere — chat, group chat, deep links.
class EventDetailLoaderScreen extends StatelessWidget {
  const EventDetailLoaderScreen({
    super.key,
    required this.eventId,
    required this.currentUserId,
  });

  final String eventId;
  final String currentUserId;

  static Route<void> route({
    required String eventId,
    required String currentUserId,
  }) {
    return MaterialPageRoute(
      builder: (_) => EventDetailLoaderScreen(
        eventId: eventId,
        currentUserId: currentUserId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<EventsBloc>(
      create: (_) => di.sl<EventsBloc>()..add(LoadEventById(eventId: eventId)),
      child: Builder(
        builder: (context) {
          return BlocBuilder<EventsBloc, EventsState>(
            builder: (context, state) {
              if (state is EventDetailLoaded) {
                // Attendees load separately (subcollection); merge them onto the
                // event so the roster + "My ticket" gate work from deep links.
                final event = state.event.attendees.isEmpty &&
                        state.attendees.isNotEmpty
                    ? state.event.copyWith(attendees: state.attendees)
                    : state.event;
                // Log the event view for recommendations (fire-and-forget,
                // never throws; the service dedupes identical rebuilds).
                di.sl<InteractionLogService>().logEventView(
                      currentUserId,
                      eventId,
                      category: event.category.name,
                    );
                // Bump the EXACT per-event view counter, deduped to at most one
                // increment per user, per event, per day (fire-and-forget).
                _recordEventView(eventId, currentUserId);
                return EventDetailsScreen(
                  event: event,
                  currentUserId: currentUserId,
                );
              }
              if (state is EventsError) {
                return Scaffold(
                  backgroundColor: AppColors.backgroundDark,
                  appBar: AppBar(backgroundColor: AppColors.backgroundDark),
                  body: Center(
                    child: Text(
                      AppLocalizations.of(context)!.eventLoadError,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                );
              }
              return const Scaffold(
                backgroundColor: AppColors.backgroundDark,
                body: Center(
                  child: CircularProgressIndicator(color: AppColors.richGold),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
