import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/message_report.dart';
import '../../data/datasources/reports_admin_remote_datasource.dart';
import '../../../chat/domain/entities/message.dart';
import '../../../chat/presentation/screens/support_chat_screen.dart';

/// Reports Admin Screen
///
/// Allows admins to view and manage reported messages
/// Shows 50 messages before and after the reported message for context
class ReportsAdminScreen extends StatefulWidget {
  final String adminId;

  const ReportsAdminScreen({
    super.key,
    required this.adminId,
  });

  @override
  State<ReportsAdminScreen> createState() => _ReportsAdminScreenState();
}

class _ReportsAdminScreenState extends State<ReportsAdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ReportsAdminRemoteDataSource _dataSource;
  List<MessageReport> _pendingReports = [];
  List<MessageReport> _allReports = [];
  List<Map<String, dynamic>> _lockedAccounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _dataSource = ReportsAdminRemoteDataSourceImpl(
      firestore: FirebaseFirestore.instance,
    );
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final pending = await _dataSource.getPendingReports();
      final all = await _dataSource.getAllReports();
      final locked = await _dataSource.getLockedAccounts();

      if (mounted) {
        setState(() {
          _pendingReports = pending;
          _allReports = all;
          _lockedAccounts = locked;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
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
        backgroundColor: AppColors.backgroundCard,
        title: const Text('Reports Management'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.richGold,
          labelColor: AppColors.richGold,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(text: 'Pending (${_pendingReports.length})'),
            const Tab(text: 'All Reports'),
            Tab(text: 'Locked (${_lockedAccounts.length})'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.richGold),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPendingReportsList(),
                _buildAllReportsList(),
                _buildLockedAccountsList(),
              ],
            ),
    );
  }

  Widget _buildPendingReportsList() {
    if (_pendingReports.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: AppColors.successGreen),
            SizedBox(height: 16),
            Text(
              'No pending reports',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingReports.length,
      itemBuilder: (context, index) {
        return _buildReportCard(_pendingReports[index]);
      },
    );
  }

  Widget _buildAllReportsList() {
    if (_allReports.isEmpty) {
      return const Center(
        child: Text(
          'No reports yet',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _allReports.length,
      itemBuilder: (context, index) {
        return _buildReportCard(_allReports[index]);
      },
    );
  }

  Widget _buildReportCard(MessageReport report) {
    Color statusColor;
    switch (report.status) {
      case ReportStatus.pending:
        statusColor = Colors.orange;
        break;
      case ReportStatus.reviewed:
        statusColor = Colors.blue;
        break;
      case ReportStatus.actionTaken:
        statusColor = AppColors.successGreen;
        break;
      case ReportStatus.dismissed:
        statusColor = AppColors.textSecondary;
        break;
    }

    return Card(
      color: AppColors.backgroundCard,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    report.status.value.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  _formatDate(report.reportedAt),
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Reported Message:',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.errorRed.withOpacity(0.3)),
              ),
              child: Text(
                report.messageContent,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Reason: ${report.reason}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Reporter ID: ${report.reporterId.substring(0, 8)}...',
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
            ),
            Text(
              'Reported User ID: ${report.reportedUserId.substring(0, 8)}...',
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _viewMessageContext(report),
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('View Context'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.richGold,
                      foregroundColor: AppColors.deepBlack,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _chatWithReporter(report),
                  icon: const Icon(Icons.chat, color: AppColors.richGold),
                  tooltip: 'Chat with Reporter',
                ),
                if (report.status == ReportStatus.pending) ...[
                  IconButton(
                    onPressed: () => _dismissReport(report),
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    tooltip: 'Dismiss',
                  ),
                  IconButton(
                    onPressed: () => _lockUserAccount(report),
                    icon: const Icon(Icons.lock, color: AppColors.errorRed),
                    tooltip: 'Lock Account',
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedAccountsList() {
    if (_lockedAccounts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_open, size: 64, color: AppColors.successGreen),
            SizedBox(height: 16),
            Text(
              'No locked accounts',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _lockedAccounts.length,
      itemBuilder: (context, index) {
        final account = _lockedAccounts[index];
        return Card(
          color: AppColors.backgroundCard,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.errorRed.withOpacity(0.2),
              child: const Icon(Icons.lock, color: AppColors.errorRed),
            ),
            title: Text(
              account['displayName'] ?? 'Unknown',
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reason: ${account['lockReason'] ?? 'N/A'}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                if (account['lockedAt'] != null)
                  Text(
                    'Locked: ${_formatDate(account['lockedAt'])}',
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: () => _unlockAccount(account['userId']),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.successGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Unlock'),
            ),
          ),
        );
      },
    );
  }

  Future<void> _chatWithReporter(MessageReport report) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.richGold),
      ),
    );

    try {
      final firestore = FirebaseFirestore.instance;

      // Check for existing support chat with this reportId
      final existingChats = await firestore
          .collection('support_chats')
          .where('reportId', isEqualTo: report.reportId)
          .limit(1)
          .get();

      String conversationId;

      if (existingChats.docs.isNotEmpty) {
        conversationId = existingChats.docs.first.id;
      } else {
        // Create new support chat for this report
        conversationId = const Uuid().v4();
        final now = FieldValue.serverTimestamp();

        await firestore.collection('support_chats').doc(conversationId).set({
          'reportId': report.reportId,
          'userId': report.reporterId,
          'supportAgentId': widget.adminId,
          'assignedTo': widget.adminId,
          'subject': 'Report Follow-up: ${report.reason}',
          'category': 'report_followup',
          'status': 'open',
          'createdAt': now,
          'updatedAt': now,
          'lastMessage': 'Report follow-up conversation started',
          'lastMessageAt': now,
          'lastMessageBy': 'system',
          'messageCount': 1,
          'unreadCount': 0,
          'adminUnreadCount': 0,
        });

        // Create initial system message with report context
        await firestore.collection('support_messages').doc().set({
          'conversationId': conversationId,
          'senderId': 'system',
          'senderType': 'system',
          'senderName': 'System',
          'content': 'Report Follow-up\n\n'
              'Reason: ${report.reason}\n'
              'Reported message: "${report.messageContent}"\n'
              'Reported user: ${report.reportedUserId.substring(0, 8)}...\n'
              'Reported at: ${_formatDate(report.reportedAt)}',
          'messageType': 'system',
          'isTicketStart': true,
          'readByAdmin': true,
          'readByUser': false,
          'createdAt': now,
        });
      }

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SupportChatScreen(
            conversationId: conversationId,
            currentUserId: widget.adminId,
            isAdmin: true,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening chat: $e')),
      );
    }
  }

  Future<void> _viewMessageContext(MessageReport report) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.richGold),
      ),
    );

    try {
      final messages = await _dataSource.getMessagesAroundReport(
        conversationId: report.conversationId,
        messageId: report.messageId,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      _showMessageContextDialog(messages, report.messageId);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading context: $e')),
      );
    }
  }

  void _showMessageContextDialog(List<Message> messages, String reportedMessageId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.backgroundDark,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Message Context (50 before/after)',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const Divider(color: AppColors.divider),
              Expanded(
                child: ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isReported = message.messageId == reportedMessageId;

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isReported
                            ? AppColors.errorRed.withOpacity(0.2)
                            : AppColors.backgroundCard,
                        borderRadius: BorderRadius.circular(8),
                        border: isReported
                            ? Border.all(color: AppColors.errorRed, width: 2)
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'User: ${message.senderId.substring(0, 8)}...',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                message.timeText,
                                style: const TextStyle(
                                  color: AppColors.textTertiary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            message.content,
                            style: TextStyle(
                              color: isReported
                                  ? AppColors.errorRed
                                  : AppColors.textPrimary,
                              fontWeight:
                                  isReported ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          if (isReported)
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                '^ REPORTED MESSAGE',
                                style: TextStyle(
                                  color: AppColors.errorRed,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _dismissReport(MessageReport report) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text(
          'Dismiss Report',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to dismiss this report?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.richGold,
            ),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _dataSource.updateReportStatus(
          reportId: report.reportId,
          status: ReportStatus.dismissed,
          adminId: widget.adminId,
        );
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report dismissed')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _lockUserAccount(MessageReport report) async {
    final reasonController = TextEditingController();
    final lockDays = ValueNotifier<int?>(null);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text(
          'Lock Account',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Lock account for user ${report.reportedUserId.substring(0, 8)}...?',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Reason',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<int?>(
              valueListenable: lockDays,
              builder: (context, value, child) {
                return DropdownButtonFormField<int?>(
                  value: value,
                  dropdownColor: AppColors.backgroundCard,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Lock Duration',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Permanent')),
                    DropdownMenuItem(value: 1, child: Text('1 day')),
                    DropdownMenuItem(value: 7, child: Text('7 days')),
                    DropdownMenuItem(value: 30, child: Text('30 days')),
                    DropdownMenuItem(value: 90, child: Text('90 days')),
                  ],
                  onChanged: (v) => lockDays.value = v,
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
            ),
            child: const Text('Lock Account'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final lockUntil = lockDays.value != null
            ? DateTime.now().add(Duration(days: lockDays.value!))
            : null;

        await _dataSource.lockAccount(
          userId: report.reportedUserId,
          adminId: widget.adminId,
          reason: reasonController.text.isNotEmpty
              ? reasonController.text
              : 'Violation of community guidelines',
          lockUntil: lockUntil,
        );

        await _dataSource.updateReportStatus(
          reportId: report.reportId,
          status: ReportStatus.actionTaken,
          adminId: widget.adminId,
          actionTaken: 'Account locked',
        );

        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account locked successfully'),
              backgroundColor: AppColors.successGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _unlockAccount(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text(
          'Unlock Account',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to unlock this account?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.successGreen,
            ),
            child: const Text('Unlock'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _dataSource.unlockAccount(
          userId: userId,
          adminId: widget.adminId,
        );
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account unlocked successfully'),
              backgroundColor: AppColors.successGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
