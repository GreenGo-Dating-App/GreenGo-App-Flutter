import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import '../../../../core/constants/app_colors.dart';
import 'support_chat_screen.dart';
import '../../../../core/utils/safe_navigation.dart';

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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.deepBlack,
        title: Text(
          l10n.chatMySupportTickets,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.richGold),
          onPressed: () => SafeNavigation.pop(context, userId: widget.currentUserId),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('support_chats')
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
                    l10n.chatErrorLoadingTickets,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: Text(l10n.retry),
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
                    l10n.chatNoSupportTickets,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.chatNeedHelpCreateTicket,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _createNewTicket(context),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.chatCreateTicket),
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
              final unreadCount = ticket['unreadCount'] ?? 0;

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
        label: Text(l10n.chatNewTicket),
      ),
    );
  }

  void _createNewTicket(BuildContext context) {
    final parentContext = context;
    showDialog(
      context: context,
      builder: (dialogContext) => _CreateTicketDialog(
        currentUserId: widget.currentUserId,
        onCreated: (conversationId) {
          Navigator.pop(dialogContext);
          Navigator.push(
            parentContext,
            MaterialPageRoute(
              builder: (_) => SupportChatScreen(
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
    final l10n = AppLocalizations.of(context)!;
    switch (status.toLowerCase()) {
      case 'open':
        return l10n.chatStatusOpen;
      case 'assigned':
        return l10n.chatStatusAssigned;
      case 'in_progress':
        return l10n.chatStatusInProgress;
      case 'waiting_on_user':
        return l10n.chatStatusAwaitingReply;
      case 'resolved':
        return l10n.chatStatusResolved;
      case 'closed':
        return l10n.chatStatusClosed;
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    final l10n = AppLocalizations.of(context)!;
    if (diff.inMinutes < 1) return l10n.chatJustNow;
    if (diff.inHours < 1) return l10n.chatMinutesAgo(diff.inMinutes);
    if (diff.inDays < 1) return l10n.chatHoursAgo(diff.inHours);
    if (diff.inDays < 7) return l10n.chatDaysAgo(diff.inDays);

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

  List<Map<String, String>> _getCategories(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      {'value': 'general', 'label': l10n.chatCategoryGeneral},
      {'value': 'technical', 'label': l10n.chatCategoryTechnical},
      {'value': 'billing', 'label': l10n.chatCategoryBilling},
      {'value': 'account', 'label': l10n.chatCategoryAccount},
      {'value': 'safety', 'label': l10n.chatCategorySafety},
      {'value': 'feedback', 'label': l10n.chatCategoryFeedback},
    ];
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createTicket() async {
    if (_subjectController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.chatPleaseEnterSubject)),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final now = DateTime.now();

      // Get user profile for sender info
      Map<String, dynamic> userData = {};
      try {
        final userProfile = await firestore
            .collection('profiles')
            .doc(widget.currentUserId)
            .get();
        if (userProfile.exists) {
          userData = userProfile.data() ?? {};
        }
      } catch (e) {
        debugPrint('Could not fetch profile: $e');
      }

      // Find category label
      final categoryLabel = _getCategories(context).firstWhere(
        (cat) => cat['value'] == _selectedCategory,
        orElse: () => {'label': _selectedCategory},
      )['label'] ?? _selectedCategory;

      // Create the support conversation using support_chats collection (matches admin panel)
      final docRef = await firestore.collection('support_chats').add({
        'userId': widget.currentUserId,
        'userName': userData['displayName'] ?? 'User',
        'userAvatar': userData['photoUrls']?.isNotEmpty == true
            ? userData['photoUrls'][0]
            : null,
        'subject': _subjectController.text.trim(),
        'category': _selectedCategory,
        'status': 'open',
        'priority': 'normal',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'lastMessageAt': Timestamp.fromDate(now),
        'lastMessage': '',
        'lastMessageBy': 'user',
        'unreadCount': 0,
        'messageCount': 1,
      });

      // Create the initial ticket message with formatted content
      final String ticketContent = '''📋 **New Support Ticket**

**Category:** $categoryLabel
**Subject:** ${_subjectController.text.trim()}
${_descriptionController.text.trim().isNotEmpty ? '\n**Description:**\n${_descriptionController.text.trim()}' : ''}''';

      await firestore.collection('support_messages').add({
        'conversationId': docRef.id,
        'senderId': widget.currentUserId,
        'senderType': 'user',
        'senderName': userData['displayName'] ?? 'User',
        'senderAvatar': userData['photoUrls']?.isNotEmpty == true
            ? userData['photoUrls'][0]
            : null,
        'content': ticketContent,
        'messageType': 'ticket_creation',
        'isTicketStart': true,
        'readByAdmin': false,
        'readByUser': true,
        'createdAt': Timestamp.fromDate(now),
      });

      // Update last message in conversation
      await docRef.update({
        'lastMessage': 'New ticket: ${_subjectController.text.trim()}',
      });

      widget.onCreated(docRef.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.chatFailedToCreateTicket}: $e')),
        );
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: AppColors.backgroundCard,
      title: Text(
        l10n.chatCreateSupportTicket,
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category dropdown
            Text(
              l10n.chatCategory,
              style: const TextStyle(
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
                  items: _getCategories(context).map((cat) {
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
              l10n.chatSubject,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _subjectController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: l10n.chatSubjectHint,
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
              l10n.chatDescriptionOptional,
              style: const TextStyle(
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
                hintText: l10n.chatDetailsHint,
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
            l10n.cancel,
            style: const TextStyle(color: AppColors.textSecondary),
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
              : Text(l10n.chatCreate),
        ),
      ],
    );
  }
}
