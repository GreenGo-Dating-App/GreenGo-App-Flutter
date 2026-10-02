import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';

/// A report reason (wire value stored on `reports.reason`).
enum ExperienceReportReason {
  scam('scam'),
  offPlatformPayment('off_platform_payment'),
  misleading('misleading'),
  noShow('no_show'),
  inappropriate('inappropriate'),
  other('other');

  const ExperienceReportReason(this.wire);
  final String wire;
}

class ExperienceReportInput {
  const ExperienceReportInput(this.reason, this.details);
  final ExperienceReportReason reason;
  final String details;
}

/// "Report this experience": reason chips + optional text. Three distinct
/// reporters hide the listing pending admin review (server trigger).
class ReportExperienceSheet extends StatefulWidget {
  const ReportExperienceSheet({super.key});

  static Future<ExperienceReportInput?> show(BuildContext context) =>
      showModalBottomSheet<ExperienceReportInput>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.backgroundCard,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
        builder: (_) => const ReportExperienceSheet(),
      );

  static String label(AppLocalizations l, ExperienceReportReason r) =>
      switch (r) {
        ExperienceReportReason.scam => l.uexpReasonScam,
        ExperienceReportReason.offPlatformPayment => l.uexpReasonOffPlatform,
        ExperienceReportReason.misleading => l.uexpReasonMisleading,
        ExperienceReportReason.noShow => l.uexpReasonNoShow,
        ExperienceReportReason.inappropriate => l.uexpReasonInappropriate,
        ExperienceReportReason.other => l.uexpReasonOther,
      };

  @override
  State<ReportExperienceSheet> createState() => _ReportExperienceSheetState();
}

class _ReportExperienceSheetState extends State<ReportExperienceSheet> {
  ExperienceReportReason? _reason;
  final _details = TextEditingController();

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.uexpReportScamTitle,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(l.uexpReportBody,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 6, children: [
              for (final r in ExperienceReportReason.values)
                ChoiceChip(
                  selected: _reason == r,
                  onSelected: (_) => setState(() => _reason = r),
                  label: Text(ReportExperienceSheet.label(l, r)),
                ),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: _details,
              maxLength: 1000,
              minLines: 2,
              maxLines: 5,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: l.uexpReportDetailsHint,
                hintStyle: const TextStyle(color: AppColors.textTertiary),
                filled: true,
                fillColor: AppColors.backgroundInput,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorRed,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 48),
              ),
              onPressed: _reason == null
                  ? null
                  : () => Navigator.pop(context,
                      ExperienceReportInput(_reason!, _details.text)),
              child: Text(l.uexpReportSend),
            ),
          ],
        ),
      ),
    );
  }
}
