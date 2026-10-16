import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/utils/user_error.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/services/safety_actions_service.dart';
import 'report_reasons.dart';

/// "Report" for content that is not a person or a chat message - a spot
/// review, a whole community (Terms 18.1). Same reason list as every other
/// report surface ([showReportReasonDialog]); lands in the `reports`
/// collection and from there in the one moderation pipeline.
///
/// Returns true when a report was filed.
Future<bool> showContentReportFlow(
  BuildContext context, {
  required String reporterId,
  required String type,
  required String contentPath,
  required String title,
  String? reportedUserId,
  String? description,
  Map<String, String> extra = const {},
  SafetyActionsService? service,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final errorContext = Navigator.of(context, rootNavigator: true).context;

  final reason = await showReportReasonDialog(
    context,
    title: title,
    prompt: l10n.safetyReportWhyContent,
  );
  if (reason == null) return false;

  try {
    await (service ?? di.sl<SafetyActionsService>()).reportContent(
      reporterId: reporterId,
      type: type,
      contentPath: contentPath,
      reportedUserId: reportedUserId,
      reason: reason.code,
      reasonLabel: reason.label(l10n),
      description: description,
      extra: extra,
    );
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.safetyReportSent),
        backgroundColor: AppColors.successGreen,
      ),
    );
    return true;
  } catch (e, st) {
    if (errorContext.mounted) {
      showUserError(errorContext, e, stackTrace: st);
    }
    return false;
  }
}
