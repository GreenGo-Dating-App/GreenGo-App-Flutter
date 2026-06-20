import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../generated/app_localizations.dart';
import '../bloc/events_bloc.dart';
import '../bloc/events_event.dart';
import '../bloc/events_state.dart';
import 'events_screen.dart';

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
                return EventDetailsScreen(
                  event: state.event,
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
