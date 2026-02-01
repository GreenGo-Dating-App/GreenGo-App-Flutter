import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/event.dart';

/// Events Screen - Discover local events and activities
class EventsScreen extends StatefulWidget {
  final String currentUserId;

  const EventsScreen({
    super.key,
    required this.currentUserId,
  });

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  EventCategory? _selectedCategory;
  final List<Event> _events = []; // TODO: Load from repository

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: const Text(
          'Events',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.richGold),
            onPressed: () => _showCreateEventDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppColors.textPrimary),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.richGold,
          labelColor: AppColors.richGold,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Nearby'),
            Tab(text: 'My Events'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Category Filter
          _buildCategoryFilter(),
          // Events List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEventsList(_getUpcomingEvents()),
                _buildEventsList(_getNearbyEvents()),
                _buildEventsList(_getMyEvents()),
              ],
            ),
          ),
        ],
      ),
    );
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
      case EventCategory.other:
        return 'Other';
    }
  }

  List<Event> _getUpcomingEvents() {
    return _events.where((e) => e.isUpcoming).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  List<Event> _getNearbyEvents() {
    // TODO: Sort by distance
    return _events.where((e) => e.isUpcoming).toList();
  }

  List<Event> _getMyEvents() {
    return _events.where((e) {
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
            const Text(
              'No events found',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check back later or create your own event!',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showCreateEventDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Create Event'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.richGold,
                foregroundColor: AppColors.deepBlack,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
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
    );
  }

  void _showCreateEventDialog(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateEventScreen(
          currentUserId: widget.currentUserId,
          onEventCreated: (event) {
            // TODO: Save event
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
          const Text(
            'Filter Events',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Distance',
            style: TextStyle(color: AppColors.textSecondary),
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
          const Text(
            'Date Range',
            style: TextStyle(color: AppColors.textSecondary),
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
                  child: const Text('Today'),
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
                  child: const Text('This Week'),
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
                  child: const Text('This Month'),
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
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }

  void _showEventDetails(Event event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EventDetailsScreen(
          event: event,
          currentUserId: widget.currentUserId,
        ),
      ),
    );
  }

  void _handleRSVP(Event event, RSVPStatus status) {
    // TODO: Update RSVP status
  }
}

/// Event Card Widget
class EventCard extends StatelessWidget {
  final Event event;
  final String currentUserId;
  final VoidCallback onTap;
  final Function(RSVPStatus) onRSVP;

  const EventCard({
    super.key,
    required this.event,
    required this.currentUserId,
    required this.onTap,
    required this.onRSVP,
  });

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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                          '${event.spotsLeft} spots left',
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
                        DateFormat('EEE, MMM d • h:mm a').format(event.startDate),
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
                              '${event.goingCount} going',
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
                          child: const Text(
                            'FREE',
                            style: TextStyle(
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
                          backgroundColor: userRSVP?.status == RSVPStatus.going
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
                              ? 'Going'
                              : event.isFull
                                  ? 'Full'
                                  : 'Join',
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
  final Event event;
  final String currentUserId;

  const EventDetailsScreen({
    super.key,
    required this.event,
    required this.currentUserId,
  });

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
                    DateFormat('h:mm a').format(event.startDate) +
                        ' - ' +
                        DateFormat('h:mm a').format(event.endDate),
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
                    '${event.goingCount} / ${event.maxAttendees} attending',
                    '${event.spotsLeft} spots left',
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'About this event',
                    style: TextStyle(
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
                  const SizedBox(height: 24),
                  const Text(
                    'Attendees',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: event.attendees
                          .where((a) => a.status == RSVPStatus.going)
                          .length,
                      itemBuilder: (context, index) {
                        final attendee = event.attendees
                            .where((a) => a.status == RSVPStatus.going)
                            .elementAt(index);
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundImage: attendee.userPhotoUrl != null
                                    ? NetworkImage(attendee.userPhotoUrl!)
                                    : null,
                                backgroundColor: AppColors.backgroundCard,
                                child: attendee.userPhotoUrl == null
                                    ? Text(attendee.userName[0].toUpperCase())
                                    : null,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                attendee.userName.split(' ').first,
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
                  ),
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
              top: BorderSide(color: AppColors.textTertiary.withOpacity(0.2)),
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
                const Text(
                  'FREE',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: event.isFull ? null : () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.richGold,
                    foregroundColor: AppColors.deepBlack,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    event.isFull ? 'Event Full' : 'Join Event',
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
  final String currentUserId;
  final Function(Event) onEventCreated;

  const CreateEventScreen({
    super.key,
    required this.currentUserId,
    required this.onEventCreated,
  });

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxAttendeesController = TextEditingController(text: '20');
  EventCategory _category = EventCategory.social;
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 1, hours: 2));
  bool _isFree = true;
  double _price = 0;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _maxAttendeesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: const Text(
          'Create Event',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _inputDecoration('Event Title'),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _inputDecoration('Description'),
              maxLines: 4,
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<EventCategory>(
              value: _category,
              dropdownColor: AppColors.backgroundCard,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _inputDecoration('Category'),
              items: EventCategory.values.map((c) {
                return DropdownMenuItem(
                  value: c,
                  child: Text(c.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _inputDecoration('Location'),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Start Date & Time',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              subtitle: Text(
                DateFormat('EEE, MMM d yyyy • h:mm a').format(_startDate),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              trailing: const Icon(Icons.calendar_today, color: AppColors.richGold),
              onTap: () => _selectDateTime(true),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'End Date & Time',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              subtitle: Text(
                DateFormat('EEE, MMM d yyyy • h:mm a').format(_endDate),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              trailing: const Icon(Icons.calendar_today, color: AppColors.richGold),
              onTap: () => _selectDateTime(false),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _maxAttendeesController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _inputDecoration('Max Attendees'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Free Event',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              value: _isFree,
              activeColor: AppColors.richGold,
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
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _createEvent,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.richGold,
                foregroundColor: AppColors.deepBlack,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Create Event',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(isStart ? _startDate : _endDate),
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

  void _createEvent() {
    if (!_formKey.currentState!.validate()) return;

    final event = Event(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      organizerId: widget.currentUserId,
      organizerName: 'Current User', // TODO: Get from profile
      title: _titleController.text,
      description: _descriptionController.text,
      category: _category,
      startDate: _startDate,
      endDate: _endDate,
      locationName: _locationController.text,
      maxAttendees: int.tryParse(_maxAttendeesController.text) ?? 20,
      price: _isFree ? null : _price,
      status: EventStatus.published,
      createdAt: DateTime.now(),
    );

    widget.onEventCreated(event);
  }
}
