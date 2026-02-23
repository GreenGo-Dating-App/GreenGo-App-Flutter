import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../profile/domain/entities/profile.dart';
import '../bloc/verification_admin_bloc.dart';
import '../bloc/verification_admin_event.dart';
import '../bloc/verification_admin_state.dart';

class VerificationAdminScreen extends StatefulWidget {
  final String adminId;

  const VerificationAdminScreen({
    super.key,
    required this.adminId,
  });

  @override
  State<VerificationAdminScreen> createState() => _VerificationAdminScreenState();
}

class _VerificationAdminScreenState extends State<VerificationAdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<VerificationAdminBloc>().add(const LoadPendingVerifications());
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
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: Text(
          l10n.adminPanel,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.richGold,
          labelColor: AppColors.richGold,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(text: l10n.pendingVerifications),
            Tab(text: l10n.verificationHistory),
          ],
          onTap: (index) {
            if (index == 1) {
              context
                  .read<VerificationAdminBloc>()
                  .add(const LoadVerificationHistory());
            }
          },
        ),
      ),
      body: BlocConsumer<VerificationAdminBloc, VerificationAdminState>(
        listener: (context, state) {
          if (state is VerificationAdminActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.successGreen,
              ),
            );
          } else if (state is VerificationAdminError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.errorRed,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is VerificationAdminLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.richGold),
            );
          }

          List<Profile> pending = [];
          List<Profile> history = [];

          if (state is VerificationAdminLoaded) {
            pending = state.pendingVerifications;
            history = state.verificationHistory;
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _PendingVerificationsTab(
                profiles: pending,
                adminId: widget.adminId,
                isLoading: state is VerificationAdminActionLoading,
                loadingUserId: state is VerificationAdminActionLoading
                    ? (state).userId
                    : null,
                isBulkLoading: state is VerificationAdminBulkActionLoading,
                bulkLoadingUserIds: state is VerificationAdminBulkActionLoading
                    ? (state).userIds
                    : const [],
              ),
              _VerificationHistoryTab(profiles: history),
            ],
          );
        },
      ),
    );
  }
}

class _PendingVerificationsTab extends StatefulWidget {
  final List<Profile> profiles;
  final String adminId;
  final bool isLoading;
  final String? loadingUserId;
  final bool isBulkLoading;
  final List<String> bulkLoadingUserIds;

  const _PendingVerificationsTab({
    required this.profiles,
    required this.adminId,
    this.isLoading = false,
    this.loadingUserId,
    this.isBulkLoading = false,
    this.bulkLoadingUserIds = const [],
  });

  @override
  State<_PendingVerificationsTab> createState() => _PendingVerificationsTabState();
}

class _PendingVerificationsTabState extends State<_PendingVerificationsTab> {
  final Set<String> _selectedUserIds = {};

  void _toggleSelection(String userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
      } else {
        _selectedUserIds.add(userId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedUserIds.length == widget.profiles.length) {
        _selectedUserIds.clear();
      } else {
        _selectedUserIds.addAll(widget.profiles.map((p) => p.userId));
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedUserIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (widget.profiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.verified_user_outlined,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noPendingVerifications,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    // Remove stale selections
    _selectedUserIds.removeWhere(
      (id) => !widget.profiles.any((p) => p.userId == id),
    );

    return Column(
      children: [
        // Bulk action bar
        if (_selectedUserIds.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingM,
              vertical: AppDimensions.paddingS,
            ),
            color: AppColors.richGold.withValues(alpha: 0.15),
            child: widget.isBulkLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(color: AppColors.richGold),
                    ),
                  )
                : Row(
                    children: [
                      Text(
                        '${_selectedUserIds.length} selected',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _clearSelection,
                        icon: const Icon(Icons.clear, size: 16),
                        label: const Text('Clear'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          context.read<VerificationAdminBloc>().add(
                                BulkApproveVerifications(
                                  userIds: _selectedUserIds.toList(),
                                  adminId: widget.adminId,
                                ),
                              );
                          _clearSelection();
                        },
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Approve Selected'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.successGreen,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () =>
                            _showBulkRequestBetterPhotoDialog(context, l10n),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Request New Photo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.richGold,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),

        // Select all toggle
        if (widget.profiles.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingM,
              vertical: 4,
            ),
            child: Row(
              children: [
                Checkbox(
                  value: _selectedUserIds.length == widget.profiles.length,
                  onChanged: (_) => _selectAll(),
                  activeColor: AppColors.richGold,
                ),
                GestureDetector(
                  onTap: _selectAll,
                  child: Text(
                    _selectedUserIds.length == widget.profiles.length
                        ? 'Deselect all'
                        : 'Select all',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              context
                  .read<VerificationAdminBloc>()
                  .add(const RefreshVerifications());
            },
            color: AppColors.richGold,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              itemCount: widget.profiles.length,
              itemBuilder: (context, index) {
                final profile = widget.profiles[index];
                final isCurrentLoading = widget.isLoading &&
                    widget.loadingUserId == profile.userId;
                final isSelected =
                    _selectedUserIds.contains(profile.userId);

                return _VerificationCard(
                  profile: profile,
                  adminId: widget.adminId,
                  isLoading: isCurrentLoading,
                  isSelected: isSelected,
                  onToggleSelect: () => _toggleSelection(profile.userId),
                  onApprove: () {
                    context.read<VerificationAdminBloc>().add(
                          ApproveVerification(
                            userId: profile.userId,
                            adminId: widget.adminId,
                          ),
                        );
                  },
                  onReject: (reason) {
                    context.read<VerificationAdminBloc>().add(
                          RejectVerification(
                            userId: profile.userId,
                            adminId: widget.adminId,
                            reason: reason,
                          ),
                        );
                  },
                  onRequestBetter: (reason) {
                    context.read<VerificationAdminBloc>().add(
                          RequestBetterPhoto(
                            userId: profile.userId,
                            adminId: widget.adminId,
                            reason: reason,
                          ),
                        );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _showBulkRequestBetterPhotoDialog(
      BuildContext context, AppLocalizations l10n) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(
          '${l10n.requestBetterPhoto} (${_selectedUserIds.length} users)',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: l10n.enterRejectionReason,
            hintStyle: const TextStyle(color: AppColors.textTertiary),
            border: const OutlineInputBorder(),
          ),
          style: const TextStyle(color: AppColors.textPrimary),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.rejectionReasonRequired),
                    backgroundColor: AppColors.errorRed,
                  ),
                );
                return;
              }
              Navigator.pop(dialogContext);
              context.read<VerificationAdminBloc>().add(
                    BulkRequestBetterPhoto(
                      userIds: _selectedUserIds.toList(),
                      adminId: widget.adminId,
                      reason: controller.text.trim(),
                    ),
                  );
              _clearSelection();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.richGold,
            ),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }
}

class _VerificationHistoryTab extends StatelessWidget {
  final List<Profile> profiles;

  const _VerificationHistoryTab({required this.profiles});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormatter = DateFormat('MMM dd, yyyy HH:mm');

    if (profiles.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: AppColors.textTertiary,
            ),
            SizedBox(height: 16),
            Text(
              'No verification history',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingS),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            AppColors.richGold.withValues(alpha: 0.1),
          ),
          dataRowMinHeight: 48,
          dataRowMaxHeight: 64,
          columnSpacing: 16,
          columns: const [
            DataColumn(label: Text('#', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('User', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Status', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Reviewed By', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Date', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Reason', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold))),
          ],
          rows: List.generate(profiles.length, (index) {
            final profile = profiles[index];
            final isApproved = profile.verificationStatus == VerificationStatus.approved;
            final reviewedBy = profile.verificationReviewedBy ?? '-';
            final reviewedAt = profile.verificationReviewedAt != null
                ? dateFormatter.format(profile.verificationReviewedAt!)
                : '-';
            final reason = profile.verificationRejectionReason;
            final truncatedReason = reason != null && reason.length > 30
                ? '${reason.substring(0, 30)}...'
                : reason ?? '-';

            return DataRow(cells: [
              DataCell(Text(
                '${index + 1}',
                style: const TextStyle(color: AppColors.textSecondary),
              )),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundImage: profile.photoUrls.isNotEmpty
                        ? NetworkImage(profile.photoUrls.first)
                        : null,
                    backgroundColor: AppColors.richGold.withValues(alpha: 0.2),
                    child: profile.photoUrls.isEmpty
                        ? const Icon(Icons.person, size: 14, color: AppColors.richGold)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    profile.displayName,
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                ],
              )),
              DataCell(Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isApproved
                      ? AppColors.successGreen.withValues(alpha: 0.15)
                      : AppColors.errorRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isApproved
                      ? l10n.verificationApproved
                      : l10n.verificationRejected,
                  style: TextStyle(
                    color: isApproved ? AppColors.successGreen : AppColors.errorRed,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )),
              DataCell(Text(
                reviewedBy.length > 12
                    ? '${reviewedBy.substring(0, 12)}...'
                    : reviewedBy,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              )),
              DataCell(Text(
                reviewedAt,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              )),
              DataCell(Tooltip(
                message: reason ?? '',
                child: Text(
                  truncatedReason,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              )),
            ]);
          }),
        ),
      ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  final Profile profile;
  final String adminId;
  final bool isLoading;
  final bool isSelected;
  final VoidCallback? onToggleSelect;
  final VoidCallback onApprove;
  final Function(String) onReject;
  final Function(String) onRequestBetter;

  const _VerificationCard({
    required this.profile,
    required this.adminId,
    required this.isLoading,
    this.isSelected = false,
    this.onToggleSelect,
    required this.onApprove,
    required this.onReject,
    required this.onRequestBetter,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormatter = DateFormat('MMM dd, yyyy HH:mm');

    return Card(
      color: AppColors.backgroundCard,
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with user info
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: Row(
              children: [
                if (onToggleSelect != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (_) => onToggleSelect!(),
                      activeColor: AppColors.richGold,
                    ),
                  ),
                CircleAvatar(
                  radius: 24,
                  backgroundImage: profile.photoUrls.isNotEmpty
                      ? NetworkImage(profile.photoUrls.first)
                      : null,
                  backgroundColor: AppColors.richGold.withValues(alpha: 0.2),
                  child: profile.photoUrls.isEmpty
                      ? const Icon(Icons.person, color: AppColors.richGold)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.displayName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${profile.age} years old • ${profile.gender}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      if (profile.verificationSubmittedAt != null)
                        Text(
                          l10n.submittedOn(
                            dateFormatter.format(profile.verificationSubmittedAt!),
                          ),
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Verification photo
          if (profile.verificationPhotoUrl != null)
            Stack(
              children: [
                GestureDetector(
                  onTap: () => _showFullScreenImage(context, profile.verificationPhotoUrl!),
                  child: Container(
                    width: double.infinity,
                    height: 300,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(profile.verificationPhotoUrl!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: ElevatedButton.icon(
                    onPressed: () => _showFullScreenImage(context, profile.verificationPhotoUrl!),
                    icon: const Icon(Icons.fullscreen, size: 18),
                    label: const Text('View Document'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Container(
              width: double.infinity,
              height: 200,
              color: AppColors.divider,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.image_not_supported,
                      color: AppColors.textTertiary,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.noPhotoSubmitted,
                      style: const TextStyle(color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
            ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.richGold),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onApprove,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.successGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.check, size: 18),
                          label: Text(l10n.approveVerification),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _showRejectDialog(context, l10n),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.errorRed,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.close),
                        tooltip: l10n.rejectVerification,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _showRequestBetterDialog(context, l10n),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.richGold,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.refresh),
                        tooltip: l10n.requestBetterPhoto,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(imageUrl),
            ),
          ),
        ),
      ),
    );
  }

  void _showRejectDialog(BuildContext context, AppLocalizations l10n) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(
          l10n.rejectVerification,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: l10n.enterRejectionReason,
            hintStyle: const TextStyle(color: AppColors.textTertiary),
            border: const OutlineInputBorder(),
          ),
          style: const TextStyle(color: AppColors.textPrimary),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.rejectionReasonRequired),
                    backgroundColor: AppColors.errorRed,
                  ),
                );
                return;
              }
              Navigator.pop(context);
              onReject(controller.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
            ),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  void _showRequestBetterDialog(BuildContext context, AppLocalizations l10n) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(
          l10n.requestBetterPhoto,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: l10n.enterRejectionReason,
            hintStyle: const TextStyle(color: AppColors.textTertiary),
            border: const OutlineInputBorder(),
          ),
          style: const TextStyle(color: AppColors.textPrimary),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.rejectionReasonRequired),
                    backgroundColor: AppColors.errorRed,
                  ),
                );
                return;
              }
              Navigator.pop(context);
              onRequestBetter(controller.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.richGold,
            ),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }
}

