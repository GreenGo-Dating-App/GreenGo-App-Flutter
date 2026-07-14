import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../generated/app_localizations.dart';
import '../../../safety/data/services/safety_actions_service.dart';

/// Report a community member or a community post's author. Reuses the app-wide
/// [SafetyActionsService] and the existing chat report-reason strings, tagging
/// the report with the community (and optional content) it came from.
Future<void> showCommunityReportSheet(
  BuildContext context, {
  required String reporterId,
  required String reportedUserId,
  required String reportedUserName,
  required String communityId,
  String? contentId,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);

  final reasons = <String>[
    l10n.chatReportReasonHarassment,
    l10n.chatReportReasonFakeProfile,
    l10n.chatReportReasonSpam,
    l10n.chatReportReasonInappropriate,
    l10n.chatReportReasonThreatening,
    l10n.chatReportReasonUnderage,
    l10n.chatReportReasonOther,
  ];

  final selectedReason = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.backgroundCard,
      title: Text(
        l10n.chatReportUserTitle,
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.chatWhyReportUser(reportedUserName),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ...reasons.map((reason) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  reason,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 14),
                ),
                onTap: () => Navigator.pop(dialogContext, reason),
              )),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(l10n.cancel),
        ),
      ],
    ),
  );

  if (selectedReason == null) return;

  try {
    // Tag the report with the community + content it came from (the report
    // pipeline stores this in `additionalDetails`).
    final details = contentId != null
        ? 'community:$communityId; post:$contentId'
        : 'community:$communityId';
    await di.sl<SafetyActionsService>().reportUser(
          reporterId: reporterId,
          reportedUserId: reportedUserId,
          reason: selectedReason,
          additionalDetails: details,
        );
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.chatUserReported),
        backgroundColor: AppColors.successGreen,
      ),
    );
  } catch (_) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.communitiesUnableToLoad),
        backgroundColor: AppColors.errorRed,
      ),
    );
  }
}
