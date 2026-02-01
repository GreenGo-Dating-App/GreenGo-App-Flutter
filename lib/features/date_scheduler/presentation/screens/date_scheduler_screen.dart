import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/scheduled_date.dart';
import '../bloc/date_scheduler_bloc.dart';

/// Date Scheduler Screen
class DateSchedulerScreen extends StatefulWidget {
  final String userId;
  final String? matchId;
  final String? partnerId;
  final String? partnerName;

  const DateSchedulerScreen({
    super.key,
    required this.userId,
    this.matchId,
    this.partnerId,
    this.partnerName,
  });

  @override
  State<DateSchedulerScreen> createState() => _DateSchedulerScreenState();
}

class _DateSchedulerScreenState extends State<DateSchedulerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<DateSchedulerBloc>().add(LoadUserDates(widget.userId));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Dates'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Pending'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: BlocConsumer<DateSchedulerBloc, DateSchedulerState>(
        listener: (context, state) {
          if (state is DateSchedulerError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is DateCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Date scheduled!'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is DateConfirmed) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Date confirmed!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is DateSchedulerLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is UserDatesLoaded) {
            return TabBarView(
              controller: _tabController,
              children: [
                _buildDatesList(state.upcoming, 'No upcoming dates'),
                _buildDatesList(state.pending, 'No pending dates'),
                _buildDatesList(state.past, 'No past dates'),
              ],
            );
          }

          return _buildEmptyState();
        },
      ),
      floatingActionButton: widget.matchId != null && widget.partnerId != null
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateDateDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Schedule Date'),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No dates scheduled',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Schedule a date with your matches!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.6),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatesList(List<ScheduledDate> dates, String emptyMessage) {
    if (dates.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.6),
              ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: dates.length,
      itemBuilder: (context, index) {
        final date = dates[index];
        return _DateCard(
          date: date,
          userId: widget.userId,
          onConfirm: () {
            context.read<DateSchedulerBloc>().add(ConfirmDateEvent(date.id));
          },
          onCancel: () => _showCancelDialog(context, date),
          onReschedule: () => _showRescheduleDialog(context, date),
        );
      },
    );
  }

  void _showCreateDateDialog(BuildContext context) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 19, minute: 0);
    final titleController = TextEditingController();
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateLocal) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Schedule a Date',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (widget.partnerName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'with ${widget.partnerName}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6),
                              ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'What are you planning?',
                        hintText: 'e.g., Coffee, Dinner, Movie...',
                        prefixIcon: Icon(Icons.event),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (date != null) {
                                setStateLocal(() => selectedDate = date);
                              }
                            },
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              '${selectedDate.month}/${selectedDate.day}/${selectedDate.year}',
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: selectedTime,
                              );
                              if (time != null) {
                                setStateLocal(() => selectedTime = time);
                              }
                            },
                            icon: const Icon(Icons.access_time),
                            label: Text(selectedTime.format(context)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        prefixIcon: Icon(Icons.notes),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              if (titleController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter a title'),
                                  ),
                                );
                                return;
                              }

                              final scheduledAt = DateTime(
                                selectedDate.year,
                                selectedDate.month,
                                selectedDate.day,
                                selectedTime.hour,
                                selectedTime.minute,
                              );

                              context.read<DateSchedulerBloc>().add(
                                    CreateDateEvent(
                                      matchId: widget.matchId!,
                                      creatorId: widget.userId,
                                      partnerId: widget.partnerId!,
                                      title: titleController.text,
                                      scheduledAt: scheduledAt,
                                      notes: notesController.text.isNotEmpty
                                          ? notesController.text
                                          : null,
                                    ),
                                  );
                              Navigator.pop(ctx);
                            },
                            child: const Text('Schedule'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCancelDialog(BuildContext context, ScheduledDate date) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Date'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to cancel this date?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Date'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<DateSchedulerBloc>().add(
                    CancelDateEvent(
                      dateId: date.id,
                      userId: widget.userId,
                      reason: reasonController.text.isNotEmpty
                          ? reasonController.text
                          : null,
                    ),
                  );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Cancel Date'),
          ),
        ],
      ),
    );
  }

  void _showRescheduleDialog(BuildContext context, ScheduledDate date) {
    DateTime selectedDate = date.scheduledAt;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(date.scheduledAt);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateLocal) {
          return AlertDialog(
            title: const Text('Reschedule Date'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final newDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (newDate != null) {
                      setStateLocal(() => selectedDate = newDate);
                    }
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    '${selectedDate.month}/${selectedDate.day}/${selectedDate.year}',
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (time != null) {
                      setStateLocal(() => selectedTime = time);
                    }
                  },
                  icon: const Icon(Icons.access_time),
                  label: Text(selectedTime.format(context)),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final newScheduledAt = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  );
                  Navigator.pop(ctx);
                  context.read<DateSchedulerBloc>().add(
                        RescheduleDateEvent(
                          dateId: date.id,
                          newScheduledAt: newScheduledAt,
                        ),
                      );
                },
                child: const Text('Reschedule'),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Date Card Widget
class _DateCard extends StatelessWidget {
  final ScheduledDate date;
  final String userId;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final VoidCallback? onReschedule;

  const _DateCard({
    required this.date,
    required this.userId,
    this.onConfirm,
    this.onCancel,
    this.onReschedule,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = date.status == DateStatus.pending;
    final isCreator = date.creatorId == userId;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: date.isToday
            ? BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              )
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        date.formattedDate.split(' ')[0],
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      Text(
                        date.scheduledAt.day.toString(),
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        date.title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            date.formattedTime,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.6),
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(context),
              ],
            ),
            if (date.hasVenue) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.place,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      date.venueName!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
            if (date.notes != null && date.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                date.notes!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
              ),
            ],
            if (isPending && !isCreator) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: onConfirm,
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],
            if (date.status == DateStatus.confirmed && !date.isPast) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onReschedule,
                    icon: const Icon(Icons.edit_calendar, size: 18),
                    label: const Text('Reschedule'),
                  ),
                  TextButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Cancel'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    Color color;
    String label;
    IconData icon;

    switch (date.status) {
      case DateStatus.pending:
        color = Colors.orange;
        label = 'Pending';
        icon = Icons.hourglass_empty;
        break;
      case DateStatus.confirmed:
        color = Colors.green;
        label = 'Confirmed';
        icon = Icons.check_circle;
        break;
      case DateStatus.cancelled:
        color = Colors.red;
        label = 'Cancelled';
        icon = Icons.cancel;
        break;
      case DateStatus.completed:
        color = Colors.blue;
        label = 'Completed';
        icon = Icons.done_all;
        break;
      case DateStatus.missed:
        color = Colors.grey;
        label = 'Missed';
        icon = Icons.event_busy;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
