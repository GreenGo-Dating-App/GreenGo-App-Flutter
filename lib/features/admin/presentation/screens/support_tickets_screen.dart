import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../chat/domain/entities/conversation.dart';
import '../../../chat/presentation/screens/support_chat_screen.dart';

/// Support Tickets Admin Screen
///
/// Allows admins/support agents to manage support tickets
class SupportTicketsScreen extends StatefulWidget {
  final String adminId;

  const SupportTicketsScreen({
    super.key,
    required this.adminId,
  });

  @override
  State<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends State<SupportTicketsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, int> _stats = {};
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      final functions = FirebaseFunctions.instance;
      final result = await functions.httpsCallable('getSupportStats').call({});
      final data = result.data as Map<String, dynamic>;

      if (mounted) {
        setState(() {
          _stats = {
            'open': data['byStatus']?['open'] ?? 0,
            'assigned': data['byStatus']?['assigned'] ?? 0,
            'inProgress': data['byStatus']?['inProgress'] ?? 0,
            'waitingOnUser': data['byStatus']?['waitingOnUser'] ?? 0,
            'resolved': data['byStatus']?['resolved'] ?? 0,
            'closed': data['byStatus']?['closed'] ?? 0,
            'activeTotal': data['activeTotal'] ?? 0,
            'resolvedTotal': data['resolvedTotal'] ?? 0,
          };
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading support stats: $e');
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.deepBlack,
        title: const Text(
          'Support Tickets',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.richGold),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.richGold,
          labelColor: AppColors.richGold,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(text: 'Open (${_stats['open'] ?? 0})'),
            Tab(text: 'Active (${(_stats['assigned'] ?? 0) + (_stats['inProgress'] ?? 0)})'),
            Tab(text: 'Waiting (${_stats['waitingOnUser'] ?? 0})'),
            Tab(text: 'Resolved (${_stats['resolvedTotal'] ?? 0})'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.richGold),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats header
          if (!_isLoadingStats) _buildStatsHeader(),

          // Tickets list
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTicketsList(['open']),
                _buildTicketsList(['assigned', 'inProgress']),
                _buildTicketsList(['waitingOnUser']),
                _buildTicketsList(['resolved', 'closed']),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.backgroundCard,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Active', _stats['activeTotal'] ?? 0, Colors.orange),
          _buildStatItem('Resolved', _stats['resolvedTotal'] ?? 0, Colors.green),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTicketsList(List<String> statuses) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('conversations')
          .where('conversationType', isEqualTo: 'support')
          .where('supportTicketStatus', whereIn: statuses)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.richGold),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: AppColors.errorRed),
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
                  Icons.inbox_outlined,
                  size: 64,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No ${statuses.first} tickets',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadStats,
          color: AppColors.richGold,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticketData = tickets[index].data() as Map<String, dynamic>;
              return _buildTicketCard(tickets[index].id, ticketData);
            },
          ),
        );
      },
    );
  }

  Widget _buildTicketCard(String ticketId, Map<String, dynamic> data) {
    final userId = data['userId1'] as String?;
    final subject = data['supportSubject'] as String? ?? 'Support Request';
    final status = data['supportTicketStatus'] as String? ?? 'open';
    final priority = data['supportPriority'] as String? ?? 'medium';
    final createdAt = data['createdAt'] as Timestamp?;
    final agentId = data['supportAgentId'] as String?;

    return FutureBuilder<DocumentSnapshot>(
      future: userId != null
          ? _firestore.collection('profiles').doc(userId).get()
          : null,
      builder: (context, profileSnapshot) {
        final userName = profileSnapshot.data?.data() != null
            ? (profileSnapshot.data!.data() as Map<String, dynamic>)['displayName'] as String? ?? 'Unknown'
            : 'Loading...';

        return Card(
          color: AppColors.backgroundCard,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: _getPriorityColor(priority).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: () => _openTicket(ticketId, userId ?? ''),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subject,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              userName,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildStatusBadge(status),
                          const SizedBox(height: 4),
                          _buildPriorityBadge(priority),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (createdAt != null)
                        Text(
                          _formatDate(createdAt.toDate()),
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                      Row(
                        children: [
                          if (status == 'open')
                            _buildActionButton(
                              'Assign to me',
                              Icons.person_add,
                              () => _assignToMe(ticketId),
                            ),
                          if (status == 'assigned' || status == 'inProgress')
                            _buildActionButton(
                              'Resolve',
                              Icons.check_circle,
                              () => _resolveTicket(ticketId),
                            ),
                          if (status == 'waitingOnUser')
                            _buildActionButton(
                              'Close',
                              Icons.close,
                              () => _closeTicket(ticketId),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;

    switch (status) {
      case 'open':
        color = Colors.orange;
        text = 'Open';
        break;
      case 'assigned':
        color = Colors.blue;
        text = 'Assigned';
        break;
      case 'inProgress':
        color = Colors.green;
        text = 'In Progress';
        break;
      case 'waitingOnUser':
        color = Colors.purple;
        text = 'Waiting';
        break;
      case 'resolved':
        color = Colors.teal;
        text = 'Resolved';
        break;
      case 'closed':
        color = Colors.grey;
        text = 'Closed';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    final color = _getPriorityColor(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: AppColors.richGold),
      label: Text(
        label,
        style: const TextStyle(
          color: AppColors.richGold,
          fontSize: 12,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _openTicket(String ticketId, String userId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SupportChatScreen(
          conversationId: ticketId,
          currentUserId: widget.adminId,
        ),
      ),
    );
    _loadStats();
  }

  Future<void> _assignToMe(String ticketId) async {
    try {
      final functions = FirebaseFunctions.instance;
      await functions.httpsCallable('assignSupportAgent').call({
        'conversationId': ticketId,
        'agentId': widget.adminId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ticket assigned to you'),
            backgroundColor: Colors.green,
          ),
        );
        _loadStats();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _resolveTicket(String ticketId) async {
    final resolution = await _showResolutionDialog();
    if (resolution == null) return;

    try {
      final functions = FirebaseFunctions.instance;
      await functions.httpsCallable('updateSupportTicketStatus').call({
        'conversationId': ticketId,
        'status': 'resolved',
        'resolution': resolution,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ticket resolved'),
            backgroundColor: Colors.green,
          ),
        );
        _loadStats();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _closeTicket(String ticketId) async {
    try {
      final functions = FirebaseFunctions.instance;
      await functions.httpsCallable('updateSupportTicketStatus').call({
        'conversationId': ticketId,
        'status': 'closed',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ticket closed'),
            backgroundColor: Colors.green,
          ),
        );
        _loadStats();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<String?> _showResolutionDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text(
          'Resolution Note',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Add a resolution note...',
            hintStyle: TextStyle(color: AppColors.textTertiary),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.richGold),
            ),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.richGold,
              foregroundColor: AppColors.deepBlack,
            ),
            child: const Text('Resolve'),
          ),
        ],
      ),
    );
  }
}
