import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../generated/app_localizations.dart';
import '../../data/services/safety_actions_service.dart';

/// App-wide "report or block this person" sheet.
///
/// App Store Guideline 1.2 requires that an app with user-generated content
/// provides a way to report offensive content AND to block abusive users —
/// from every surface where that content appears, not just the ones that got
/// built first. GreenGo had this in 1:1 chat, communities and profiles, but
/// not in group chat, event chat or video profiles.
///
/// Complements [SafetyActionsMenu], which is the same actions as a persistent
/// AppBar overflow widget for screens that show ONE user (a profile, a
/// storefront). This is the imperative form, for places that have nowhere to
/// put a menu — a long-pressed message bubble, a button in a video overlay.
/// Both call the same [SafetyActionsService], so reports land in one pipeline
/// however they were raised.
///
/// [surface] is a short machine-readable tag recorded on the report
/// (`group:<id>`, `videoProfile:<uid>`, `eventChat:<id>`) so moderators can
/// see where something was reported from — the reporting pipeline stores it in
/// `additionalDetails`.
Future<void> showReportBlockSheet(
  BuildContext context, {
  required String reporterId,
  required String reportedUserId,
  required String reportedUserName,
  required String surface,
  String? contentId,
  bool allowBlock = true,
}) async {
  final l10n = AppLocalizations.of(context)!;

  final action = await showModalBottomSheet<_SafetyAction>(
    context: context,
    backgroundColor: AppColors.backgroundCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.flag_outlined, color: AppColors.errorRed),
            title: Text(
              l10n.chatReportUser(reportedUserName),
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            onTap: () => Navigator.pop(sheetContext, _SafetyAction.report),
          ),
          if (allowBlock)
            ListTile(
              leading:
                  const Icon(Icons.block, color: AppColors.textSecondary),
              title: Text(
                l10n.chatBlockUser(reportedUserName),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () => Navigator.pop(sheetContext, _SafetyAction.block),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );

  if (action == null || !context.mounted) return;

  switch (action) {
    case _SafetyAction.report:
      await _report(
        context,
        reporterId: reporterId,
        reportedUserId: reportedUserId,
        reportedUserName: reportedUserName,
        surface: surface,
        contentId: contentId,
      );
    case _SafetyAction.block:
      await _block(
        context,
        blockerId: reporterId,
        blockedUserId: reportedUserId,
        blockedUserName: reportedUserName,
      );
  }
}

enum _SafetyAction { report, block }

/// The reasons offered. Deliberately the same list everywhere so moderation
/// can aggregate across surfaces, and `underage` is included because
/// Guideline 1.2.1 makes under-age content a first-class concern.
List<String> _reasons(AppLocalizations l10n) => [
      l10n.chatReportReasonHarassment,
      l10n.chatReportReasonFakeProfile,
      l10n.chatReportReasonSpam,
      l10n.chatReportReasonInappropriate,
      l10n.chatReportReasonThreatening,
      l10n.chatReportReasonUnderage,
      l10n.chatReportReasonOther,
    ];

Future<void> _report(
  BuildContext context, {
  required String reporterId,
  required String reportedUserId,
  required String reportedUserName,
  required String surface,
  String? contentId,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);

  final reason = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.backgroundCard,
      title: Text(
        l10n.chatReportUserTitle,
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.chatWhyReportUser(reportedUserName),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ..._reasons(l10n).map(
              (r) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  r,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 14),
                ),
                onTap: () => Navigator.pop(dialogContext, r),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(l10n.cancel),
        ),
      ],
    ),
  );

  if (reason == null) return;

  try {
    await di.sl<SafetyActionsService>().reportUser(
          reporterId: reporterId,
          reportedUserId: reportedUserId,
          reason: reason,
          additionalDetails:
              contentId != null ? '$surface; content:$contentId' : surface,
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
        content: Text(l10n.somethingWentWrong),
        backgroundColor: AppColors.errorRed,
      ),
    );
  }
}

Future<void> _block(
  BuildContext context, {
  required String blockerId,
  required String blockedUserId,
  required String blockedUserName,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.backgroundCard,
      title: Text(
        l10n.chatBlockUserTitle,
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      content: Text(
        l10n.chatBlockUserMessage(blockedUserName),
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
            l10n.chatBlockUserTitle,
            style: const TextStyle(color: AppColors.errorRed),
          ),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  try {
    await di.sl<SafetyActionsService>().blockUser(
          blockerId: blockerId,
          blockedUserId: blockedUserId,
        );
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.chatUserBlocked(blockedUserName)),
        backgroundColor: AppColors.successGreen,
      ),
    );
  } catch (_) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.somethingWentWrong),
        backgroundColor: AppColors.errorRed,
      ),
    );
  }
}
