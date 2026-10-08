import 'package:flutter/material.dart';

import '../../generated/app_localizations.dart';
import '../constants/app_colors.dart';
import '../services/analytics_consent_service.dart';

/// First-run analytics / crash-reporting consent prompt (P2-5a). Shown only
/// in consent-required regions (EEA, UK, CH, unknown) until the user decides.
/// Dismissing it without a choice leaves collection OFF; it is offered again
/// on the next app start. The same choice is available in Privacy & data.
Future<void> showAnalyticsConsentPromptIfNeeded(
  BuildContext context, {
  AnalyticsConsentService? service,
}) async {
  final svc = service ?? AnalyticsConsentService.instance;
  if (!svc.shouldPrompt || _shownThisSession) return;
  _shownThisSession = true;
  final granted = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.backgroundCard,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const AnalyticsConsentPromptBody(),
  );
  if (granted != null) await svc.setChoice(granted: granted);
}

bool _shownThisSession = false;

class AnalyticsConsentPromptBody extends StatelessWidget {
  const AnalyticsConsentPromptBody({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.insights_outlined, color: AppColors.richGold),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.analyticsConsentTitle,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.analyticsConsentBody,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    // Equal weight: refusing is as easy as accepting.
                    Expanded(
                      child: OutlinedButton(
                        key: const Key('analyticsConsentDecline'),
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(l10n.analyticsConsentDecline),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        key: const Key('analyticsConsentAllow'),
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.richGold,
                          foregroundColor: AppColors.deepBlack,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(l10n.analyticsConsentAllow),
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
