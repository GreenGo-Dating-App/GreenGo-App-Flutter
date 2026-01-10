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
          } else if (state is VerificationAdminActionLoading) {
            pending = state.pendingVerifications;
            history = state.verificationHistory;
          } else if (state is VerificationAdminActionSuccess) {
            pending = state.pendingVerifications;
            history = state.verificationHistory;
          } else if (state is VerificationAdminError) {
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
              ),
              _VerificationHistoryTab(profiles: history),
            ],
          );
        },
      ),
    );
  }
}

class _PendingVerificationsTab extends StatelessWidget {
  final List<Profile> profiles;
  final String adminId;
  final bool isLoading;
  final String? loadingUserId;

  const _PendingVerificationsTab({
    required this.profiles,
    required this.adminId,
    this.isLoading = false,
    this.loadingUserId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (profiles.isEmpty) {
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

    return RefreshIndicator(
      onRefresh: () async {
        context.read<VerificationAdminBloc>().add(const RefreshVerifications());
      },
      color: AppColors.richGold,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        itemCount: profiles.length,
        itemBuilder: (context, index) {
          final profile = profiles[index];
          final isCurrentLoading = isLoading && loadingUserId == profile.userId;

          return _VerificationCard(
            profile: profile,
            adminId: adminId,
            isLoading: isCurrentLoading,
            onApprove: () {
              context.read<VerificationAdminBloc>().add(
                    ApproveVerification(
                      userId: profile.userId,
                      adminId: adminId,
                    ),
                  );
            },
            onReject: (reason) {
              context.read<VerificationAdminBloc>().add(
                    RejectVerification(
                      userId: profile.userId,
                      adminId: adminId,
                      reason: reason,
                    ),
                  );
            },
            onRequestBetter: (reason) {
              context.read<VerificationAdminBloc>().add(
                    RequestBetterPhoto(
                      userId: profile.userId,
                      adminId: adminId,
                      reason: reason,
                    ),
                  );
            },
          );
        },
      ),
    );
  }
}

class _VerificationHistoryTab extends StatelessWidget {
  final List<Profile> profiles;

  const _VerificationHistoryTab({required this.profiles});

  @override
  Widget build(BuildContext context) {
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

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      itemCount: profiles.length,
      itemBuilder: (context, index) {
        final profile = profiles[index];
        return _HistoryCard(profile: profile);
      },
    );
  }
}

class _VerificationCard extends StatelessWidget {
  final Profile profile;
  final String adminId;
  final bool isLoading;
  final VoidCallback onApprove;
  final Function(String) onReject;
  final Function(String) onRequestBetter;

  const _VerificationCard({
    required this.profile,
    required this.adminId,
    required this.isLoading,
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

class _HistoryCard extends StatelessWidget {
  final Profile profile;

  const _HistoryCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormatter = DateFormat('MMM dd, yyyy HH:mm');

    final isApproved = profile.verificationStatus == VerificationStatus.approved;

    return Card(
      color: AppColors.backgroundCard,
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        side: BorderSide(
          color: isApproved ? AppColors.successGreen : AppColors.errorRed,
          width: 0.5,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: profile.photoUrls.isNotEmpty
              ? NetworkImage(profile.photoUrls.first)
              : null,
          backgroundColor: AppColors.richGold.withValues(alpha: 0.2),
          child: profile.photoUrls.isEmpty
              ? const Icon(Icons.person, color: AppColors.richGold)
              : null,
        ),
        title: Text(
          profile.displayName,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isApproved ? Icons.check_circle : Icons.cancel,
                  color: isApproved ? AppColors.successGreen : AppColors.errorRed,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  isApproved ? l10n.verificationApproved : l10n.verificationRejected,
                  style: TextStyle(
                    color: isApproved ? AppColors.successGreen : AppColors.errorRed,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (profile.verificationReviewedAt != null)
              Text(
                dateFormatter.format(profile.verificationReviewedAt!),
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                ),
              ),
            if (profile.verificationRejectionReason != null)
              Text(
                l10n.rejectionReason(profile.verificationRejectionReason!),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
