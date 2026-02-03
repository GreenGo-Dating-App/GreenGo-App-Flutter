import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import 'support_chat_screen.dart';

/// Support Tickets List Screen
///
/// Shows the user's support tickets and allows creating new ones
class SupportTicketsListScreen extends StatefulWidget {
  final String currentUserId;

  const SupportTicketsListScreen({
    super.key,
    required this.currentUserId,
  });

  @override
  State<SupportTicketsListScreen> createState() => _SupportTicketsListScreenState();
}

class _SupportTicketsListScreenState extends State<SupportTicketsListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.deepBlack,
        title: const Text(
          'My Support Tickets',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.richGold),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('support_conversations')
            .where('userId', isEqualTo: widget.currentUserId)
            .orderBy('lastMessageAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.richGold),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.errorRed, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading tickets',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final tickets = snapshot.data?.docs ?? [];

          if (tickets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.support_agent,
                    size: 80,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Support Tickets',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Need help? Create a new ticket.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _createNewTicket(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Ticket'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.richGold,
                      foregroundColor: AppColors.deepBlack,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index].data() as Map<String, dynamic>;
              final ticketId = tickets[index].id;
              final subject = ticket['subject'] ?? 'Support Request';
              final status = ticket['status'] ?? 'open';
              final lastMessageAt = ticket['lastMessageAt'] as Timestamp?;
              final unreadCount = ticket['userUnreadCount'] ?? 0;

              return Card(
                color: AppColors.backgroundCard,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(status).withValues(alpha: 0.2),
                    child: Icon(
                      _getStatusIcon(status),
                      color: _getStatusColor(status),
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          subject,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.richGold,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                              color: AppColors.deepBlack,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getStatusLabel(status),
                              style: TextStyle(
                                color: _getStatusColor(status),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (lastMessageAt != null)
                            Text(
                              _formatDate(lastMessageAt.toDate()),
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SupportChatScreen(
                          conversationId: ticketId,
                          currentUserId: widget.currentUserId,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createNewTicket(context),
        backgroundColor: AppColors.richGold,
        foregroundColor: AppColors.deepBlack,
        icon: const Icon(Icons.add),
        label: const Text('New Ticket'),
      ),
    );
  }

  void _createNewTicket(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _CreateTicketDialog(
        currentUserId: widget.currentUserId,
        onCreated: (conversationId) {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SupportChatScreen(
                conversationId: conversationId,
                currentUserId: widget.currentUserId,
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.blue;
      case 'assigned':
      case 'in_progress':
        return Colors.orange;
      case 'waiting_on_user':
        return Colors.purple;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Icons.fiber_new;
      case 'assigned':
      case 'in_progress':
        return Icons.pending;
      case 'waiting_on_user':
        return Icons.reply;
      case 'resolved':
        return Icons.check_circle;
      case 'closed':
        return Icons.lock;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return 'Open';
      case 'assigned':
        return 'Assigned';
      case 'in_progress':
        return 'In Progress';
      case 'waiting_on_user':
        return 'Awaiting Reply';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${date.day}/${date.month}/${date.year}';
  }
}

class _CreateTicketDialog extends StatefulWidget {
  final String currentUserId;
  final Function(String conversationId) onCreated;

  const _CreateTicketDialog({
    required this.currentUserId,
    required this.onCreated,
  });

  @override
  State<_CreateTicketDialog> createState() => _CreateTicketDialogState();
}

class _CreateTicketDialogState extends State<_CreateTicketDialog> {
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'general';
  bool _isCreating = false;

  final List<Map<String, String>> _categories = [
    {'value': 'general', 'label': 'General Question'},
    {'value': 'technical', 'label': 'Technical Issue'},
    {'value': 'billing', 'label': 'Billing & Payments'},
    {'value': 'account', 'label': 'Account Help'},
    {'value': 'safety', 'label': 'Safety Concern'},
    {'value': 'feedback', 'label': 'Feedback'},
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createTicket() async {
    if (_subjectController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a subject')),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final now = DateTime.now();

      // Create the support conversation
      final docRef = await firestore.collection('support_conversations').add({
        'userId': widget.currentUserId,
        'subject': _subjectController.text.trim(),
        'category': _selectedCategory,
        'status': 'open',
        'priority': 'normal',
        'createdAt': Timestamp.fromDate(now),
        'lastMessageAt': Timestamp.fromDate(now),
        'userUnreadCount': 0,
        'supportUnreadCount': 1,
      });

      // Add the initial message if description provided
      if (_descriptionController.text.trim().isNotEmpty) {
        await docRef.collection('messages').add({
          'senderId': widget.currentUserId,
          'senderType': 'user',
          'content': _descriptionController.text.trim(),
          'timestamp': Timestamp.fromDate(now),
          'type': 'text',
        });
      }

      widget.onCreated(docRef.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create ticket: $e')),
        );
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.backgroundCard,
      title: const Text(
        'Create Support Ticket',
        style: TextStyle(color: AppColors.textPrimary),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category dropdown
            Text(
              'Category',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.backgroundDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.divider),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  dropdownColor: AppColors.backgroundCard,
                  style: const TextStyle(color: AppColors.textPrimary),
                  items: _categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat['value'],
                      child: Text(cat['label']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCategory = value);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Subject field
            Text(
              'Subject',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _subjectController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Brief description of your issue',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.backgroundDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.richGold),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description field
            Text(
              'Description (Optional)',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              style: const TextStyle(color: AppColors.textPrimary),
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Provide more details about your issue...',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.backgroundDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.richGold),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: _isCreating ? null : _createTicket,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.richGold,
            foregroundColor: AppColors.deepBlack,
          ),
          child: _isCreating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}
