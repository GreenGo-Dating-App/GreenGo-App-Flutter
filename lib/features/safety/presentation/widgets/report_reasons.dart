import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';

/// GreenGo's public safety contact (Terms 18.1, 18.7 and 19.3).
const String kSafetyEmail = 'safety@greengochat.com';

/// The ONE list of report reasons, used by every report surface (1:1 chat
/// user + message reports, the app-wide report sheet, the profile menu,
/// community / spot-review reports).
///
/// [code] is what is written to the report's `reason` field: a
/// language-neutral wire value that the server's report pipeline maps
/// exactly (functions/src/safety/reportPipeline.ts REASON_STRINGS), so the
/// triage never depends on how a label is translated. The label the reporter
/// saw goes to `reasonLabel` for the moderators.
///
/// [csae] is the reason Terms 19.3 promises ("Child sexual exploitation"):
/// it maps to the server's `csae` P0 path (immediate hide, legal hold, P0
/// alert). [csae] and [ncii] are P0 on the server.
enum ReportReason {
  harassment('harassment'),
  fakeProfile('fakeProfile'),
  spam('spam'),
  inappropriate('inappropriate'),
  personalInfo('personal_info'),
  threatening('threatening'),
  underage('underage'),
  csae('csae'),
  ncii('ncii'),
  other('other');

  const ReportReason(this.code);

  /// Wire value stored in `reason`.
  final String code;

  String label(AppLocalizations l10n) => switch (this) {
        ReportReason.harassment => l10n.chatReportReasonHarassment,
        ReportReason.fakeProfile => l10n.chatReportReasonFakeProfile,
        ReportReason.spam => l10n.chatReportReasonSpam,
        ReportReason.inappropriate => l10n.chatReportReasonInappropriate,
        ReportReason.personalInfo => l10n.chatReportReasonPersonalInfo,
        ReportReason.threatening => l10n.chatReportReasonThreatening,
        ReportReason.underage => l10n.chatReportReasonUnderage,
        ReportReason.csae => l10n.safetyReportReasonCsae,
        ReportReason.ncii => l10n.safetyReportReasonNcii,
        ReportReason.other => l10n.chatReportReasonOther,
      };
}

/// Reasons in display order: every surface shows all of them.
const List<ReportReason> kReportReasons = ReportReason.values;

/// Shows the reason picker and returns the chosen reason (null = cancelled).
///
/// Ends with the safety email (Terms 18.1: reports can also be emailed to
/// safety@greengochat.com).
Future<ReportReason?> showReportReasonDialog(
  BuildContext context, {
  required String title,
  required String prompt,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showDialog<ReportReason>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.backgroundCard,
      title: Text(
        title,
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              prompt,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            for (final r in kReportReasons)
              ListTile(
                key: ValueKey('report-reason-${r.code}'),
                contentPadding: EdgeInsets.zero,
                title: Text(
                  r.label(l10n),
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 14),
                ),
                onTap: () => Navigator.pop(dialogContext, r),
              ),
            const SizedBox(height: 8),
            Text(
              l10n.safetyReportEmailNote(kSafetyEmail),
              key: const ValueKey('report-safety-email'),
              style: const TextStyle(
                  color: AppColors.textTertiary, fontSize: 12),
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
}
