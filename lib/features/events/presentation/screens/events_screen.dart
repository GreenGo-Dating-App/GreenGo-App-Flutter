import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/tier_limits_service.dart';
import '../../../coins/domain/usecases/purchase_feature.dart';
import '../../../profile/data/datasources/profile_remote_data_source.dart';
import '../../../profile/domain/entities/location.dart' as profile_entity;
import '../../../profile/presentation/screens/traveler_location_picker_screen.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/datasources/events_remote_datasource.dart';
import '../../data/repositories/events_repository_impl.dart';
import '../../domain/entities/event.dart';
import '../bloc/events_bloc.dart';
import '../bloc/events_event.dart';
import '../bloc/events_state.dart';
import '../widgets/share_event_sheet.dart';
import 'event_chat_screen.dart';

/// Events Screen - Discover local events and activities
///
/// 3 tabs: Upcoming, Nearby, My Events
/// Category chips for filtering.
/// Wired to EventsBloc for all data operations.
class EventsScreen extends StatefulWidget {

  const EventsScreen({
    required this.currentUserId, super.key,
  });
  final String currentUserId;

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late EventsBloc _eventsBloc;
  EventCategory? _selectedCategory;
  String _searchQuery = '';
  bool _sortByPopularity = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Create the BLoC with repository and datasource
    final dataSource = EventsRemoteDataSourceImpl();
    final repository = EventsRepositoryImpl(remoteDataSource: dataSource);
    _eventsBloc = EventsBloc(repository: repository);

    // Load initial events
    _eventsBloc.add(const LoadEvents(upcoming: true));
    _eventsBloc.add(LoadUserEvents(userId: widget.currentUserId));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _eventsBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _eventsBloc,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundDark,
          title: Text(
            AppLocalizations.of(context)!.eventsTitle,
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: AppColors.richGold),
              onPressed: () => _showCreateEventDialog(context),
            ),
            IconButton(
              icon:
                  const Icon(Icons.filter_list, color: AppColors.textPrimary),
              onPressed: () => _showFilterDialog(context),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.richGold,
            labelColor: AppColors.richGold,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(text: AppLocalizations.of(context)!.eventsTabUpcoming),
              Tab(text: AppLocalizations.of(context)!.eventsTabNearby),
              Tab(text: AppLocalizations.of(context)!.eventsTabMyEvents),
            ],
          ),
        ),
        body: BlocConsumer<EventsBloc, EventsState>(
          listener: (context, state) {
            if (state is EventCreated) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.eventsCreatedSuccessfully),
                  backgroundColor: AppColors.successGreen,
                ),
              );
              // Reload events
              _eventsBloc.add(const LoadEvents(upcoming: true));
              _eventsBloc.add(LoadUserEvents(userId: widget.currentUserId));
            } else if (state is EventRsvpSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.status == 'cancelled'
                        ? AppLocalizations.of(context)!.eventsRsvpCancelled
                        : AppLocalizations.of(context)!.eventsRsvpUpdated,
                  ),
                  backgroundColor: AppColors.successGreen,
                ),
              );
              // Reload events to reflect changes
              _eventsBloc.add(const LoadEvents(upcoming: true));
              _eventsBloc.add(LoadUserEvents(userId: widget.currentUserId));
            } else if (state is EventDeleted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.eventsDeleted),
                  backgroundColor: AppColors.successGreen,
                ),
              );
            } else if (state is EventsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.errorRed,
                ),
              );
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                // Search by country/city/name + popularity sort
                _buildSearchAndSortBar(),
                // Category Filter
                _buildCategoryFilter(),
                // Events List
                Expanded(
                  child: _buildBody(state),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(EventsState state) {
    if (state is EventsLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.richGold),
      );
    }

    if (state is EventsLoaded) {
      return TabBarView(
        controller: _tabController,
        children: [
          _buildEventsList(_applySearchAndSort(_getUpcomingEvents(state))),
          _buildEventsList(_applySearchAndSort(_getNearbyEvents(state))),
          _buildEventsList(_applySearchAndSort(_getMyEvents(state))),
        ],
      );
    }

    // Default: show empty state for initial/error/other states
    return TabBarView(
      controller: _tabController,
      children: [
        _buildEventsList([]),
        _buildEventsList([]),
        _buildEventsList([]),
      ],
    );
  }

  /// Search bar (country / city / name) + popularity sort toggle.
  Widget _buildSearchAndSortBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              style: const TextStyle(color: AppColors.textPrimary),
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
              decoration: InputDecoration(
                isDense: true,
                hintText: AppLocalizations.of(context)!.eventsSearchHint,
                hintStyle: const TextStyle(color: AppColors.textTertiary),
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.backgroundCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Popularity sort toggle
          ChoiceChip(
            label: Text(AppLocalizations.of(context)!.eventsSortPopular),
            avatar: Icon(
              Icons.local_fire_department,
              size: 18,
              color: _sortByPopularity
                  ? AppColors.deepBlack
                  : AppColors.richGold,
            ),
            selected: _sortByPopularity,
            selectedColor: AppColors.richGold,
            backgroundColor: AppColors.backgroundCard,
            labelStyle: TextStyle(
              color: _sortByPopularity
                  ? AppColors.deepBlack
                  : AppColors.textPrimary,
            ),
            onSelected: (v) => setState(() => _sortByPopularity = v),
          ),
        ],
      ),
    );
  }

  /// Apply the free-text search (country/city/name) and optional popularity sort.
  List<Event> _applySearchAndSort(List<Event> events) {
    var result = events;
    final q = _searchQuery.toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((e) {
        return e.title.toLowerCase().contains(q) ||
            (e.city ?? '').toLowerCase().contains(q) ||
            e.locationName.toLowerCase().contains(q) ||
            (e.address ?? '').toLowerCase().contains(q) ||
            e.tags.any((t) => t.toLowerCase().contains(q));
      }).toList();
    }
    // Featured/boosted events always surface first; then popularity if toggled.
    result = [...result]..sort((a, b) {
        if (a.isCurrentlyFeatured != b.isCurrentlyFeatured) {
          return a.isCurrentlyFeatured ? -1 : 1;
        }
        if (_sortByPopularity) {
          return b.attendeeCount.compareTo(a.attendeeCount);
        }
        return 0;
      });
    return result;
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          _buildCategoryChip(null, 'All'),
          ...EventCategory.values.map((category) {
            return _buildCategoryChip(category, _getCategoryName(category));
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(EventCategory? category, String label) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = selected ? category : null;
          });
          _eventsBloc.add(FilterByCategory(category: _selectedCategory));
        },
        backgroundColor: AppColors.backgroundCard,
        selectedColor: AppColors.richGold.withOpacity(0.3),
        labelStyle: TextStyle(
          color: isSelected ? AppColors.richGold : AppColors.textPrimary,
        ),
        checkmarkColor: AppColors.richGold,
      ),
    );
  }

  String _getCategoryName(EventCategory category) {
    switch (category) {
      case EventCategory.dating:
        return 'Dating';
      case EventCategory.social:
        return 'Social';
      case EventCategory.sports:
        return 'Sports';
      case EventCategory.food:
        return 'Food & Drink';
      case EventCategory.nightlife:
        return 'Nightlife';
      case EventCategory.outdoor:
        return 'Outdoor';
      case EventCategory.arts:
        return 'Arts';
      case EventCategory.gaming:
        return 'Gaming';
      case EventCategory.travel:
        return 'Travel';
      case EventCategory.wellness:
        return 'Wellness';
      case EventCategory.languageExchange:
        return 'Language';
      case EventCategory.other:
        return 'Other';
    }
  }

  List<Event> _getUpcomingEvents(EventsLoaded state) {
    return state.upcomingEvents;
  }

  List<Event> _getNearbyEvents(EventsLoaded state) {
    if (state.nearbyEvents.isNotEmpty) {
      // Apply category filter to nearby events too
      if (_selectedCategory != null) {
        return state.nearbyEvents
            .where((e) => e.category == _selectedCategory)
            .toList();
      }
      return state.nearbyEvents;
    }
    // Fallback: show upcoming events if no nearby data
    return state.upcomingEvents;
  }

  List<Event> _getMyEvents(EventsLoaded state) {
    if (state.userEvents.isNotEmpty) {
      if (_selectedCategory != null) {
        return state.userEvents
            .where((e) => e.category == _selectedCategory)
            .toList();
      }
      return state.userEvents;
    }
    // Fallback: filter from all events
    return state.filteredEvents.where((e) {
      return e.organizerId == widget.currentUserId ||
          e.attendees.any((a) => a.userId == widget.currentUserId);
    }).toList();
  }

  Widget _buildEventsList(List<Event> events) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.event_busy,
              size: 80,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.eventsNoEventsFound,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.eventsCheckBackLater,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showCreateEventDialog(context),
              icon: const Icon(Icons.add),
              label: Text(AppLocalizations.of(context)!.eventsCreateEvent),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.richGold,
                foregroundColor: AppColors.deepBlack,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.richGold,
      onRefresh: () async {
        _eventsBloc.add(const LoadEvents(upcoming: true));
        _eventsBloc.add(LoadUserEvents(userId: widget.currentUserId));
        // Wait briefly for the BLoC to process
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: events.length,
        itemBuilder: (context, index) {
          return EventCard(
            event: events[index],
            currentUserId: widget.currentUserId,
            onTap: () => _showEventDetails(events[index]),
            onRSVP: (status) => _handleRSVP(events[index], status),
          );
        },
      ),
    );
  }

  void _showCreateEventDialog(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateEventScreen(
          currentUserId: widget.currentUserId,
          onEventCreated: (event) {
            _eventsBloc.add(CreateEvent(event: event));
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildFilterSheet(),
    );
  }

  Widget _buildFilterSheet() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.eventsFilterEvents,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context)!.eventsDistance,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          Slider(
            value: 25,
            min: 1,
            max: 100,
            divisions: 20,
            label: '25 km',
            activeColor: AppColors.richGold,
            onChanged: (value) {},
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.eventsDateRange,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.textTertiary),
                  ),
                  child: Text(AppLocalizations.of(context)!.eventsToday),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.textTertiary),
                  ),
                  child: Text(AppLocalizations.of(context)!.eventsThisWeekFilter),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.textTertiary),
                  ),
                  child: Text(AppLocalizations.of(context)!.eventsThisMonth),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.richGold,
                foregroundColor: AppColors.deepBlack,
              ),
              child: Text(AppLocalizations.of(context)!.eventsApplyFilters),
            ),
          ),
        ],
      ),
    );
  }

  void _showEventDetails(Event event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: _eventsBloc,
          child: EventDetailsScreen(
            event: event,
            currentUserId: widget.currentUserId,
          ),
        ),
      ),
    );
  }

  void _handleRSVP(Event event, RSVPStatus status) {
    _eventsBloc.add(RsvpEvent(
      eventId: event.id,
      userId: widget.currentUserId,
      status: status.name,
    ));
  }
}

/// Event Card Widget
class EventCard extends StatelessWidget {

  const EventCard({
    required this.event, required this.currentUserId, required this.onTap, required this.onRSVP, super.key,
  });
  final Event event;
  final String currentUserId;
  final VoidCallback onTap;
  final Function(RSVPStatus) onRSVP;

  @override
  Widget build(BuildContext context) {
    final userRSVP = event.attendees
        .where((a) => a.userId == currentUserId)
        .firstOrNull;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  Container(
                    height: 150,
                    width: double.infinity,
                    color: AppColors.backgroundDark,
                    child: event.imageUrl != null
                        ? Image.network(event.imageUrl!, fit: BoxFit.cover)
                        : const Icon(
                            Icons.event,
                            size: 60,
                            color: AppColors.textTertiary,
                          ),
                  ),
                  // Category Badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.richGold,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        event.category.name.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.deepBlack,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Featured/boosted badge
                  if (event.isCurrentlyFeatured)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star,
                                size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              AppLocalizations.of(context)!.eventsFeatured,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Language badge for language exchange events
                  if (event.category == EventCategory.languageExchange &&
                      event.languagePairs != null)
                    Positioned(
                      top: 12,
                      left: 120,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.infoBlue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.translate,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              event.languagePairs!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Spots Left
                  if (!event.isFull)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.eventsSpotsLeft(event.spotsLeft),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Event Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('EEE, MMM d \u2022 h:mm a')
                            .format(event.startDate),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event.locationName,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Attendees
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.people,
                              size: 16,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              AppLocalizations.of(context)!.eventsGoing(event.goingCount),
                              style: const TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Price
                      if (!event.isFree)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.richGold.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${event.currency ?? '\$'}${event.price?.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: AppColors.richGold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.eventsFreeLabel,
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      // RSVP Button
                      ElevatedButton(
                        onPressed: event.isFull
                            ? null
                            : () => onRSVP(RSVPStatus.going),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              userRSVP?.status == RSVPStatus.going
                                  ? Colors.green
                                  : AppColors.richGold,
                          foregroundColor: AppColors.deepBlack,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: Text(
                          userRSVP?.status == RSVPStatus.going
                              ? AppLocalizations.of(context)!.eventsGoingLabel
                              : event.isFull
                                  ? AppLocalizations.of(context)!.eventsFullLabel
                                  : AppLocalizations.of(context)!.eventsJoinLabel,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Event Details Screen
class EventDetailsScreen extends StatelessWidget {

  const EventDetailsScreen({
    required this.event, required this.currentUserId, super.key,
  });
  final Event event;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: AppColors.backgroundDark,
            flexibleSpace: FlexibleSpaceBar(
              background: event.imageUrl != null
                  ? Image.network(event.imageUrl!, fit: BoxFit.cover)
                  : Container(
                      color: AppColors.backgroundCard,
                      child: const Icon(
                        Icons.event,
                        size: 80,
                        color: AppColors.textTertiary,
                      ),
                    ),
            ),
            actions: [
              // Boost (feature) — organizer only, if not already featured
              if (event.organizerId == currentUserId &&
                  !event.isCurrentlyFeatured)
                IconButton(
                  icon: const Icon(Icons.rocket_launch,
                      color: AppColors.richGold),
                  tooltip: AppLocalizations.of(context)!.eventsBoost,
                  onPressed: () => _handleBoost(context, event),
                ),
              // Share event to chats / groups
              IconButton(
                icon: const Icon(Icons.share, color: AppColors.richGold),
                onPressed: () => showShareEventSheet(
                  context,
                  event: event,
                  currentUserId: currentUserId,
                ),
                tooltip: AppLocalizations.of(context)!.eventShare,
              ),
              // Group Chat button
              IconButton(
                icon: const Icon(Icons.chat, color: AppColors.richGold),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EventChatScreen(
                        event: event,
                        currentUserId: currentUserId,
                        currentUserName: 'User', // TODO: get from profile
                      ),
                    ),
                  );
                },
                tooltip: AppLocalizations.of(context)!.eventsGroupChatTooltip,
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    Icons.calendar_today,
                    DateFormat('EEEE, MMMM d, yyyy').format(event.startDate),
                    '${DateFormat('h:mm a').format(event.startDate)} - ${DateFormat('h:mm a').format(event.endDate)}',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.location_on,
                    event.locationName,
                    event.address,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.people,
                    event.isUnlimited
                        ? AppLocalizations.of(context)!
                            .eventsGoing(event.goingCount)
                        : AppLocalizations.of(context)!.eventsAttending(
                            event.goingCount, event.maxAttendees),
                    event.isUnlimited
                        ? null
                        : AppLocalizations.of(context)!
                            .eventsSpotsLeft(event.spotsLeft),
                  ),
                  if (event.isPrivate) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.lock_outline,
                      AppLocalizations.of(context)!.eventsPrivateEvent,
                      null,
                    ),
                  ],
                  if (event.externalLinks.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ...event.externalLinks.map((lnk) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () => launchUrl(
                              Uri.parse(lnk.url),
                              mode: LaunchMode.externalApplication,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.link,
                                    color: AppColors.richGold, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    lnk.label ?? lnk.url,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.richGold,
                                      fontSize: 14,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
                  ],
                  // Language exchange info
                  if (event.category == EventCategory.languageExchange) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.translate,
                      event.languagePairs ?? AppLocalizations.of(context)!.eventsLanguageExchange,
                      event.languages.isNotEmpty
                          ? AppLocalizations.of(context)!.eventsLanguages(event.languages.join(', '))
                          : null,
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context)!.eventsAboutThisEvent,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  // Tags
                  if (event.tags.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: event.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundInput,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '#$tag',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Group Chat link
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EventChatScreen(
                            event: event,
                            currentUserId: currentUserId,
                            currentUserName: 'User',
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.richGold.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline,
                            color: AppColors.richGold,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.eventsGroupChatTooltip,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  AppLocalizations.of(context)!.eventsChatWithAttendees,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.textTertiary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context)!.eventsAttendees,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Builder(builder: (context) {
                    // Respect attendee privacy: hide invisible / organizer-only
                    // attendees from everyone except themselves and the organizer.
                    final visibleGoing = event.attendees
                        .where((a) =>
                            a.status == RSVPStatus.going &&
                            a.isVisibleTo(currentUserId, event.organizerId))
                        .toList();
                    return SizedBox(
                      height: 80,
                      child: visibleGoing.isEmpty
                          ? Center(
                              child: Text(
                                AppLocalizations.of(context)!
                                    .eventsNoAttendeesYet,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            )
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: visibleGoing.length,
                              itemBuilder: (context, index) {
                                final attendee = visibleGoing[index];
                                final name = attendee.displayNameFor(
                                    currentUserId, event.organizerId);
                                final anon = attendee.isAnonymous &&
                                    currentUserId != attendee.userId &&
                                    currentUserId != event.organizerId;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: Column(
                                    children: [
                                      CircleAvatar(
                                        radius: 28,
                                        backgroundImage: (!anon &&
                                                attendee.userPhotoUrl != null)
                                            ? NetworkImage(
                                                attendee.userPhotoUrl!)
                                            : null,
                                        backgroundColor:
                                            AppColors.backgroundCard,
                                        child: (anon ||
                                                attendee.userPhotoUrl == null)
                                            ? Text(name.isNotEmpty
                                                ? name[0].toUpperCase()
                                                : '?')
                                            : null,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        name.split(' ').first,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    );
                  }),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            border: Border(
              top: BorderSide(
                  color: AppColors.textTertiary.withOpacity(0.2)),
            ),
          ),
          child: Row(
            children: [
              if (!event.isFree)
                Text(
                  '${event.currency ?? '\$'}${event.price?.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                Text(
                  AppLocalizations.of(context)!.eventsFreeLabel,
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      event.isFull ? null : () => _handleJoin(context, event),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.richGold,
                    foregroundColor: AppColors.deepBlack,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    event.isFull ? AppLocalizations.of(context)!.eventsEventFull : AppLocalizations.of(context)!.eventsJoinEvent,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Join a (possibly paid) event — charges coins for paid events first.
  Future<void> _handleJoin(BuildContext context, Event event) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final bloc = context.read<EventsBloc>();

    if (!event.isFree && (event.price ?? 0) > 0) {
      final cost = event.price!.round();
      final afford =
          await sl<CanAffordFeature>()(userId: currentUserId, cost: cost);
      if (!context.mounted) return;
      if (!afford.fold((_) => false, (v) => v)) {
        messenger.showSnackBar(
            SnackBar(content: Text(l10n.eventsInsufficientCoins)));
        return;
      }
      final confirmed = await _confirmCoinSpend(
          context, l10n.eventsJoinEvent, l10n.eventsJoinForCoins(cost));
      if (confirmed != true || !context.mounted) return;
      final charge = await sl<PurchaseFeature>()(
        userId: currentUserId,
        featureName: 'event_rsvp',
        cost: cost,
        relatedId: event.id,
      );
      if (!context.mounted) return;
      if (!charge.fold((_) => false, (_) => true)) {
        messenger.showSnackBar(
            SnackBar(content: Text(l10n.eventsInsufficientCoins)));
        return;
      }
    }

    bloc.add(RsvpEvent(
      eventId: event.id,
      userId: currentUserId,
      status: RSVPStatus.going.name,
    ));
    if (context.mounted) Navigator.pop(context);
  }

  /// Boost (feature) an event for a fixed coin cost (organizer only).
  Future<void> _handleBoost(BuildContext context, Event event) async {
    const cost = 100;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final bloc = context.read<EventsBloc>();

    final afford =
        await sl<CanAffordFeature>()(userId: currentUserId, cost: cost);
    if (!context.mounted) return;
    if (!afford.fold((_) => false, (v) => v)) {
      messenger.showSnackBar(
          SnackBar(content: Text(l10n.eventsInsufficientCoins)));
      return;
    }
    final confirmed = await _confirmCoinSpend(
        context, l10n.eventsBoost, l10n.eventsBoostConfirm(cost));
    if (confirmed != true || !context.mounted) return;
    final charge = await sl<PurchaseFeature>()(
      userId: currentUserId,
      featureName: 'event_boost',
      cost: cost,
      relatedId: event.id,
    );
    if (!context.mounted) return;
    if (!charge.fold((_) => false, (_) => true)) {
      messenger.showSnackBar(
          SnackBar(content: Text(l10n.eventsInsufficientCoins)));
      return;
    }
    bloc.add(UpdateEvent(
      event: event.copyWith(
        isFeatured: true,
        featuredUntil: DateTime.now().add(const Duration(days: 7)),
      ),
    ));
    messenger.showSnackBar(SnackBar(content: Text(l10n.eventsBoosted)));
  }

  Future<bool?> _confirmCoinSpend(
      BuildContext context, String title, String body) {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(body, style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.groupCancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.eventsConfirmAction)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String? subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.richGold, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Create Event Screen
class CreateEventScreen extends StatefulWidget {

  const CreateEventScreen({
    required this.currentUserId, required this.onEventCreated, super.key,
  });
  final String currentUserId;
  final Function(Event) onEventCreated;

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxAttendeesController = TextEditingController(text: '20');
  final _languagePairsController = TextEditingController();
  EventCategory _category = EventCategory.social;
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 1, hours: 2));
  bool _isFree = true;
  double _price = 0;
  EventVisibility _visibility = EventVisibility.public;
  bool _isUnlimited = false;
  double? _lat;
  double? _lng;
  String? _pickedCity;
  String? _pickedCountry;
  File? _mainPhoto;
  final List<File> _extraPhotos = [];
  final ImagePicker _picker = ImagePicker();
  bool _uploading = false;
  final _linkUrlController = TextEditingController();
  final _linkLabelController = TextEditingController();
  final List<ExternalLink> _externalLinks = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _maxAttendeesController.dispose();
    _languagePairsController.dispose();
    _linkUrlController.dispose();
    _linkLabelController.dispose();
    super.dispose();
  }

  Future<void> _pickMainPhoto() async {
    final x =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (x != null) setState(() => _mainPhoto = File(x.path));
  }

  Future<void> _pickExtraPhoto() async {
    if (_extraPhotos.length >= 4) return;
    final x =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (x != null) setState(() => _extraPhotos.add(File(x.path)));
  }

  /// Main photo + up to 4 extra photos, uploaded on create.
  Widget _buildPhotoSection() {
    Widget slot({File? file, required VoidCallback onTap, bool main = false}) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: main ? 110 : 70,
          height: main ? 110 : 70,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(12),
            image: file != null
                ? DecorationImage(image: FileImage(file), fit: BoxFit.cover)
                : null,
            border: Border.all(color: AppColors.textTertiary.withOpacity(0.3)),
          ),
          child: file == null
              ? Icon(main ? Icons.add_a_photo : Icons.add,
                  color: AppColors.textSecondary)
              : null,
        ),
      );
    }

    return SizedBox(
      height: 116,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          slot(file: _mainPhoto, onTap: _pickMainPhoto, main: true),
          ..._extraPhotos.map((f) => slot(file: f, onTap: () {})),
          if (_extraPhotos.length < 4)
            slot(file: null, onTap: _pickExtraPhoto),
        ],
      ),
    );
  }

  /// Pick the event location from the map (reuses the app's location picker).
  Future<void> _pickLocation() async {
    final result = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(
        builder: (_) => const TravelerLocationPickerScreen(),
      ),
    );
    if (result == null || !mounted) return;
    final loc = result as profile_entity.Location;
    setState(() {
      _lat = loc.latitude;
      _lng = loc.longitude;
      _pickedCity = loc.city;
      _pickedCountry = loc.country;
      _locationController.text = loc.displayAddress;
    });
  }

  void _addLink() {
    final url = _linkUrlController.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _externalLinks.add(ExternalLink(
        url: url,
        label: _linkLabelController.text.trim().isEmpty
            ? null
            : _linkLabelController.text.trim(),
      ));
      _linkUrlController.clear();
      _linkLabelController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: Text(
          AppLocalizations.of(context)!.eventsCreateEvent,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildPhotoSection(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _inputDecoration(AppLocalizations.of(context)!.eventsEventTitle),
              validator: (v) => v?.isEmpty ?? true ? AppLocalizations.of(context)!.eventsRequired : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _inputDecoration(AppLocalizations.of(context)!.eventsDescription),
              maxLines: 4,
              validator: (v) => v?.isEmpty ?? true ? AppLocalizations.of(context)!.eventsRequired : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<EventCategory>(
              initialValue: _category,
              dropdownColor: AppColors.backgroundCard,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _inputDecoration(AppLocalizations.of(context)!.eventsCategory),
              items: EventCategory.values.map((c) {
                return DropdownMenuItem(
                  value: c,
                  child: Text(c.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            // Language Pairs field (shown only for language exchange category)
            if (_category == EventCategory.languageExchange) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _languagePairsController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _inputDecoration(
                  AppLocalizations.of(context)!.eventsLanguagePairs,
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              style: const TextStyle(color: AppColors.textPrimary),
              readOnly: true,
              onTap: _pickLocation,
              decoration: _inputDecoration(
                      AppLocalizations.of(context)!.eventsLocation)
                  .copyWith(
                suffixIcon:
                    const Icon(Icons.map_outlined, color: AppColors.richGold),
              ),
              validator: (v) => v?.isEmpty ?? true
                  ? AppLocalizations.of(context)!.eventsRequired
                  : null,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                AppLocalizations.of(context)!.eventsStartDateTime,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              subtitle: Text(
                DateFormat('EEE, MMM d yyyy \u2022 h:mm a')
                    .format(_startDate),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              trailing: const Icon(Icons.calendar_today,
                  color: AppColors.richGold),
              onTap: () => _selectDateTime(true),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                AppLocalizations.of(context)!.eventsEndDateTime,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              subtitle: Text(
                DateFormat('EEE, MMM d yyyy \u2022 h:mm a').format(_endDate),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              trailing: const Icon(Icons.calendar_today,
                  color: AppColors.richGold),
              onTap: () => _selectDateTime(false),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                AppLocalizations.of(context)!.eventsUnlimitedAttendees,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              value: _isUnlimited,
              activeThumbColor: AppColors.richGold,
              onChanged: (v) => setState(() => _isUnlimited = v),
            ),
            if (!_isUnlimited)
              TextFormField(
                controller: _maxAttendeesController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _inputDecoration(
                    AppLocalizations.of(context)!.eventsMaxAttendees),
                keyboardType: TextInputType.number,
              ),
            const SizedBox(height: 16),
            // Visibility: public (discoverable) vs private (invitees/link only)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                AppLocalizations.of(context)!.eventsPrivateEvent,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              value: _visibility == EventVisibility.private,
              activeThumbColor: AppColors.richGold,
              onChanged: (v) => setState(() => _visibility =
                  v ? EventVisibility.private : EventVisibility.public),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                AppLocalizations.of(context)!.eventsFreeEvent,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              value: _isFree,
              activeThumbColor: AppColors.richGold,
              onChanged: (v) => setState(() => _isFree = v),
            ),
            if (!_isFree) ...[
              Slider(
                value: _price,
                min: 0,
                max: 100,
                divisions: 20,
                label: '\$${_price.toStringAsFixed(0)}',
                activeColor: AppColors.richGold,
                onChanged: (v) => setState(() => _price = v),
              ),
            ],
            const SizedBox(height: 16),
            // External links (tickets, website, map…)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                AppLocalizations.of(context)!.eventsExternalLinks,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ..._externalLinks.map((lnk) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.link, color: AppColors.richGold),
                  title: Text(
                    lnk.label ?? lnk.url,
                    style: const TextStyle(color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close,
                        color: AppColors.textSecondary),
                    onPressed: () =>
                        setState(() => _externalLinks.remove(lnk)),
                  ),
                )),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _linkUrlController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    keyboardType: TextInputType.url,
                    decoration: _inputDecoration(
                        AppLocalizations.of(context)!.eventsLinkUrlHint),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: AppColors.richGold),
                  tooltip: AppLocalizations.of(context)!.eventsAddLink,
                  onPressed: _addLink,
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _uploading ? null : _createEvent,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.richGold,
                foregroundColor: AppColors.deepBlack,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _uploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.deepBlack),
                    )
                  : Text(
                      AppLocalizations.of(context)!.eventsCreateEvent,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.backgroundCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  Future<void> _selectDateTime(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay.fromDateTime(isStart ? _startDate : _endDate),
    );
    if (time == null) return;

    setState(() {
      final dateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      if (isStart) {
        _startDate = dateTime;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(hours: 2));
        }
      } else {
        _endDate = dateTime;
      }
    });
  }

  Future<void> _createEvent() async {
    if (_uploading) return;
    if (!_formKey.currentState!.validate()) return;

    // Enforce tier cap on number of events created.
    final check =
        await TierLimitsService().canCreateEvent(widget.currentUserId);
    if (!mounted) return;
    if (!check.allowed) {
      final l10n = AppLocalizations.of(context)!;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.backgroundCard,
          title: Text(l10n.tierLimitTitle,
              style: const TextStyle(color: AppColors.textPrimary)),
          content: Text(
            l10n.tierLimitEventsBody(check.max ?? 0),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.tourGotIt),
            ),
          ],
        ),
      );
      return;
    }

    // Upload the photos (main + up to 4) to Storage.
    setState(() => _uploading = true);
    String? imageUrl;
    final photoUrls = <String>[];
    try {
      final ds = sl<ProfileRemoteDataSource>();
      if (_mainPhoto != null) {
        imageUrl = await ds.uploadPhoto(widget.currentUserId, _mainPhoto!,
            folder: 'events');
      }
      for (final f in _extraPhotos) {
        photoUrls.add(await ds.uploadPhoto(widget.currentUserId, f,
            folder: 'events'));
      }
    } catch (_) {
      // Non-fatal: proceed without (or with partial) images.
    }
    if (!mounted) return;
    setState(() => _uploading = false);

    final event = Event(
      id: '', // Firestore will generate the ID
      organizerId: widget.currentUserId,
      organizerName: 'Current User', // TODO: Get from profile
      title: _titleController.text,
      description: _descriptionController.text,
      category: _category,
      imageUrl: imageUrl,
      photoUrls: photoUrls,
      startDate: _startDate,
      endDate: _endDate,
      locationName: _locationController.text,
      latitude: _lat,
      longitude: _lng,
      city: _pickedCity,
      country: _pickedCountry,
      maxAttendees:
          _isUnlimited ? 0 : (int.tryParse(_maxAttendeesController.text) ?? 20),
      price: _isFree ? null : _price,
      visibility: _visibility,
      externalLinks: _externalLinks,
      status: EventStatus.published,
      languagePairs: _category == EventCategory.languageExchange
          ? _languagePairsController.text.isNotEmpty
              ? _languagePairsController.text
              : null
          : null,
      createdAt: DateTime.now(),
    );

    widget.onEventCreated(event);
  }
}
