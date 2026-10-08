import 'package:flutter/material.dart';

import '../../generated/app_localizations.dart';
import '../constants/app_colors.dart';
import '../services/ai_consent_service.dart';

/// One-time notice + choice before the first use of a feature that sends
/// text to Google AI services (smart replies, AI coach, translating messages
/// from other people, read-aloud). Returns true (allow), false (decline) or
/// null (dismissed without choosing: asked again later). The decision is
/// stored through [AiConsentService].
Future<bool?> showAiConsentSheet(BuildContext context, {AiConsentService? service}) async {
  final svc = service ?? AiConsentService.instance;
  final decision = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.backgroundCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => const _AiConsentSheetBody(),
  );
  if (decision != null) await svc.setDecision(accepted: decision);
  return decision;
}

class _AiConsentSheetBody extends StatelessWidget {
  const _AiConsentSheetBody();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Widget point(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: AppColors.richGold),
              const SizedBox(width: 10),
              Expanded(
                child: Text(text,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 14, height: 1.4)),
              ),
            ],
          ),
        );
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.richGold),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(l10n.aiConsentTitle,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(l10n.aiConsentIntro,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 14, height: 1.4)),
            const SizedBox(height: 14),
            point(Icons.business, l10n.aiConsentProviders),
            point(Icons.chat_bubble_outline, l10n.aiConsentWhatSent),
            point(Icons.help_outline, l10n.aiConsentWhy),
            point(Icons.toggle_off_outlined, l10n.aiConsentDeclineInfo),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('aiConsentDecline'),
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.divider),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(l10n.aiConsentDecline),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    key: const Key('aiConsentAccept'),
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.richGold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(l10n.aiConsentAccept),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Gate for AI features. Interactive entry points call [ensure]; screens that
/// would auto-translate other people's messages call [maybePromptOnce].
class AiConsentGate {
  AiConsentGate._();

  /// True when the feature may run. Unknown -> shows the sheet. Declined ->
  /// explains why the feature is off, with a "Review" action.
  static Future<bool> ensure(BuildContext context, {AiConsentService? service}) async {
    final svc = service ?? AiConsentService.instance;
    await svc.ensureLoaded();
    switch (svc.status) {
      case AiConsentStatus.granted:
        return true;
      case AiConsentStatus.declined:
        if (context.mounted) showDisabledNotice(context, service: svc);
        return false;
      case AiConsentStatus.unknown:
        if (!context.mounted) return false;
        svc.promptedThisSession = true;
        return await showAiConsentSheet(context, service: svc) == true;
    }
  }

  /// Shows the sheet once per session while the user has not decided yet.
  static Future<void> maybePromptOnce(BuildContext context, {AiConsentService? service}) async {
    final svc = service ?? AiConsentService.instance;
    await svc.ensureLoaded();
    if (svc.status != AiConsentStatus.unknown || svc.promptedThisSession) return;
    if (!context.mounted) return;
    svc.promptedThisSession = true;
    await showAiConsentSheet(context, service: svc);
  }

  /// "AI features are off" + Review (re-opens the sheet).
  static void showDisabledNotice(BuildContext context, {AiConsentService? service}) {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Text(l10n.aiConsentDisabledNotice),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: l10n.aiConsentReview,
          onPressed: () {
            if (context.mounted) showAiConsentSheet(context, service: service);
          },
        ),
      ),
    );
  }
}
