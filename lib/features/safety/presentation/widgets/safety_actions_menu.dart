import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/user_error.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/services/safety_actions_service.dart';
import '../../data/services/safety_takedown_service.dart';
import '../screens/ncii_request_screen.dart';
import 'report_reasons.dart';

/// Overflow (⋮) menu with Report and Block actions for a viewed user.
///
/// Reuses the existing report/block Firestore schema through
/// [SafetyActionsService] and the existing chat report-reason l10n strings, so
/// no new moderation pipeline is created. Drop this into an AppBar `actions`
/// list for any screen that shows another user's profile.
class SafetyActionsMenu extends StatelessWidget {

  const SafetyActionsMenu({
    required this.currentUserId,
    required this.reportedUserId,
    required this.reportedUserName,
    super.key,
    this.isReportedUserAdmin = false,
  });

  final String currentUserId;
  final String reportedUserId;
  final String reportedUserName;
  final bool isReportedUserAdmin;

  SafetyActionsService get _service => sl<SafetyActionsService>();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopupMenuButton<String>(
      tooltip: '',
      color: AppColors.backgroundCard,
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.backgroundDark.withOpacity(0.7),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.more_vert, color: AppColors.textPrimary),
      ),
      onSelected: (value) {
        if (value == 'report') {
          _onReport(context);
        } else if (value == 'block') {
          _onBlock(context);
        } else if (value == 'ncii') {
          openNciiRequestForm(context, prefilledLocations: [nciiProfileLocation(reportedUserId)]);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'report',
          child: Row(
            children: [
              const Icon(Icons.flag_outlined,
                  color: AppColors.warningAmber, size: 20),
              const SizedBox(width: 12),
              Text(
                l10n.safetyReportUser,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'block',
          child: Row(
            children: [
              const Icon(Icons.block, color: AppColors.errorRed, size: 20),
              const SizedBox(width: 12),
              Text(
                l10n.safetyBlockUser,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          key: const ValueKey('safety-menu-ncii'),
          value: 'ncii',
          child: Row(
            children: [
              const Icon(Icons.no_photography_outlined,
                  color: AppColors.textSecondary, size: 20),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  l10n.nciiEntryTitle,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _onReport(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final errorContext = Navigator.of(context, rootNavigator: true).context;

    // Admins cannot be reported — mirror chat behaviour.
    if (isReportedUserAdmin) {
      showUserErrorMessage(context, l10n.chatCannotReportAdmin);
      return;
    }

    // One shared list on every surface (report_reasons.dart).
    final selectedReason = await showReportReasonDialog(
      context,
      title: l10n.chatReportUserTitle,
      prompt: l10n.chatWhyReportUser(reportedUserName),
    );

    if (selectedReason == null) return;

    try {
      await _service.reportUser(
        reporterId: currentUserId,
        reportedUserId: reportedUserId,
        reason: selectedReason.code,
        reasonLabel: selectedReason.label(l10n),
      );
      // Auto-block after a report so the reported user is removed from every
      // list immediately (the block broadcast drives the live removal) and can
      // no longer interact — mirrors the in-chat report behaviour.
      await _service.blockUser(
        blockerId: currentUserId,
        blockedUserId: reportedUserId,
        reason: 'Auto-blocked after report: ${selectedReason.code}',
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.chatUserReported),
          backgroundColor: AppColors.errorRed,
        ),
      );
      // Leave the profile once reported+blocked.
      if (navigator.canPop()) navigator.pop();
    } catch (e, st) {
      if (errorContext.mounted) {
        showUserError(errorContext, e, stackTrace: st);
      }
    }
  }

  Future<void> _onBlock(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final errorContext = Navigator.of(context, rootNavigator: true).context;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(
          l10n.chatBlockUserTitle,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          l10n.chatBlockUserMessage(reportedUserName),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              l10n.chatBlock,
              style: const TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.blockUser(
        blockerId: currentUserId,
        blockedUserId: reportedUserId,
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.chatBlockUser(reportedUserName)),
          backgroundColor: AppColors.errorRed,
        ),
      );
      // Leave the profile once blocked.
      if (navigator.canPop()) navigator.pop();
    } catch (e, st) {
      if (errorContext.mounted) {
        showUserError(errorContext, e, stackTrace: st);
      }
    }
  }
}
