import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
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
          SnackBar(content: Text(AppLocalizations.of(context)!.adminErrorLoadingData(e.toString()))),
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCard,
        title: Text(l10n.adminReportsManagement),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.richGold,
          labelColor: AppColors.richGold,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(text: l10n.adminPendingCount(_pendingReports.length)),
            Tab(text: l10n.adminAllReports),
            Tab(text: l10n.adminLockedCount(_lockedAccounts.length)),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 64, color: AppColors.successGreen),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.adminNoPendingReports,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
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
      return Center(
        child: Text(
          AppLocalizations.of(context)!.adminNoReportsYet,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
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
    final l10n = AppLocalizations.of(context)!;
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
            Text(
              l10n.adminReportedMessage,
              style: const TextStyle(
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
              l10n.adminReasonLabel(report.reason),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.adminReporterIdShort(report.reporterId.substring(0, 8)),
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
            ),
            Text(
              l10n.adminReportedUserIdShort(report.reportedUserId.substring(0, 8)),
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
                    label: Text(l10n.adminViewContext),
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
                  tooltip: l10n.adminChatWithReporter,
                ),
                if (report.status == ReportStatus.pending) ...[
                  IconButton(
                    onPressed: () => _dismissReport(report),
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    tooltip: l10n.adminDismiss,
                  ),
                  IconButton(
                    onPressed: () => _lockUserAccount(report),
                    icon: const Icon(Icons.lock, color: AppColors.errorRed),
                    tooltip: l10n.adminLockAccount,
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
    final l10n = AppLocalizations.of(context)!;
    if (_lockedAccounts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_open, size: 64, color: AppColors.successGreen),
            const SizedBox(height: 16),
            Text(
              l10n.adminNoLockedAccounts,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
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
              account['displayName'] ?? l10n.adminUnknown,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.adminLockReasonLabel(account['lockReason'] ?? 'N/A'),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                if (account['lockedAt'] != null)
                  Text(
                    l10n.adminLockedDate(_formatDate(account['lockedAt'])),
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
              child: Text(l10n.adminUnlock),
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
        SnackBar(content: Text(AppLocalizations.of(context)!.adminErrorOpeningChat(e.toString()))),
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
        SnackBar(content: Text(AppLocalizations.of(context)!.adminErrorLoadingContext(e.toString()))),
      );
    }
  }

  void _showMessageContextDialog(List<Message> messages, String reportedMessageId) {
    final l10n = AppLocalizations.of(context)!;
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
                  Text(
                    l10n.adminMessageContext,
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
                                l10n.adminUserSenderIdShort(message.senderId.substring(0, 8)),
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
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                l10n.adminReportedMessageMarker,
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
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(
          l10n.adminDismissReport,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          l10n.adminDismissReportConfirm,
          style: const TextStyle(color: AppColors.textSecondary),
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
            child: Text(l10n.adminDismiss),
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
            SnackBar(content: Text(l10n.adminReportDismissed)),
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
    final l10n = AppLocalizations.of(context)!;
    final reasonController = TextEditingController();
    final lockDays = ValueNotifier<int?>(null);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(
          l10n.adminLockAccount,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.adminLockAccountConfirm(report.reportedUserId.substring(0, 8)),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: l10n.adminReason,
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                border: const OutlineInputBorder(),
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
                  decoration: InputDecoration(
                    labelText: l10n.adminLockDuration,
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.adminPermanent)),
                    DropdownMenuItem(value: 1, child: Text(l10n.adminOneDay)),
                    DropdownMenuItem(value: 7, child: Text(l10n.adminSevenDays)),
                    DropdownMenuItem(value: 30, child: Text(l10n.adminThirtyDays)),
                    DropdownMenuItem(value: 90, child: Text(l10n.adminNinetyDays)),
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
            child: Text(l10n.adminLockAccount),
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
              : l10n.adminViolationOfCommunityGuidelines,
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
            SnackBar(
              content: Text(l10n.adminAccountLockedSuccessfully),
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
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(
          l10n.adminUnlockAccount,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          l10n.adminUnlockAccountConfirm,
          style: const TextStyle(color: AppColors.textSecondary),
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
            child: Text(l10n.adminUnlock),
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
            SnackBar(
              content: Text(l10n.adminAccountUnlockedSuccessfully),
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
