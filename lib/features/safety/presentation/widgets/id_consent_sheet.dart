import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/consent_recorder.dart';
import '../../../../generated/app_localizations.dart';

/// Version of the ID-verification notice. Bump when the text changes
/// materially (the server stores it with the consent record).
const int kIdVerificationConsentVersion = 1;

/// Explicit consent before an identity document is uploaded (P2-6).
///
/// Shows what is processed, by whom, how long it is kept and who can see it.
/// On "accept" the decision is recorded server-side (`recordConsent`, type
/// `id_verification`) BEFORE anything is uploaded; if that fails nothing is
/// uploaded. Returns true only when the consent was recorded.
Future<bool> showIdConsentSheet(
  BuildContext context, {
  ConsentRecorder? recorder,
}) async {
  final accepted = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.backgroundCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const IdConsentSheetBody(),
  );
  if (accepted != true) return false;
  final ok = await (recorder ?? ConsentRecorder.instance).record(
    type: ConsentTypes.idVerification,
    accepted: true,
    version: kIdVerificationConsentVersion,
    retries: 1,
  );
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.idConsentRecordError),
        backgroundColor: AppColors.errorRed,
      ),
    );
  }
  return ok;
}

class IdConsentSheetBody extends StatelessWidget {
  const IdConsentSheetBody({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Widget point(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: AppColors.richGold),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 14, height: 1.4),
                ),
              ),
            ],
          ),
        );
    return SafeArea(
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.badge_outlined, color: AppColors.richGold),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.idConsentTitle,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                point(Icons.document_scanner_outlined, l10n.idConsentWhat),
                point(Icons.business_outlined, l10n.idConsentWho),
                point(Icons.timer_outlined, l10n.idConsentRetention),
                point(Icons.inventory_2_outlined, l10n.idConsentKept),
                point(Icons.visibility_off_outlined, l10n.idConsentAccess),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        key: const Key('idConsentCancel'),
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(l10n.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        key: const Key('idConsentAccept'),
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.richGold,
                          foregroundColor: AppColors.deepBlack,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(l10n.idConsentAccept),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
