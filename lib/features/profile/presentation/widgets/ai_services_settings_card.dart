import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/ai_consent_service.dart';
import '../../../../core/widgets/ai_consent_sheet.dart';
import '../../../../generated/app_localizations.dart';

/// Profile > Account settings > "AI services": the master on/off switch for
/// every feature that sends text to third-party AI services (smart replies,
/// AI language coach, translating received messages, read-aloud, support
/// assistant replies).
///
/// The switch IS the AI-processing consent (`consents/{uid}.ai_processing`,
/// written by the `recordConsent` callable with a timestamped event history):
///  - OFF records a withdrawal immediately (no confirmation step: withdrawing
///    must be as easy as giving consent, GDPR art. 7(3) / LGPD art. 8 §5).
///    The AI callables then refuse this user server-side.
///  - ON shows the same notice used at first use; only "Allow" records it.
///
/// Safety / moderation screening is not part of this switch.
class AiServicesSettingsCard extends StatefulWidget {
  const AiServicesSettingsCard({super.key, this.service});

  /// Injected in tests; defaults to [AiConsentService.instance].
  final AiConsentService? service;

  @override
  State<AiServicesSettingsCard> createState() => _AiServicesSettingsCardState();
}

class _AiServicesSettingsCardState extends State<AiServicesSettingsCard> {
  AiConsentService get _svc => widget.service ?? AiConsentService.instance;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Show this device's copy at once, then align with the server record
    // (the choice may have been changed on another device).
    _svc.ensureLoaded().then((_) => _svc.refreshFromServer());
  }

  Future<void> _onChanged(bool on) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _busy = true);
    try {
      if (on) {
        // Same notice as at first use; backing out records nothing.
        final accepted = await showAiConsentSheet(context,
            service: _svc, recordDecline: false);
        if (accepted != true) return;
      } else {
        await _svc.setDecision(accepted: false);
      }
      final synced = !_svc.hasUnsyncedDecision;
      messenger?.hideCurrentSnackBar();
      messenger?.showSnackBar(SnackBar(
        content: Text(!synced
            ? l10n.aiServicesSyncPending
            : (on ? l10n.aiServicesTurnedOn : l10n.aiServicesTurnedOff)),
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ValueListenableBuilder<AiConsentStatus>(
      valueListenable: _svc.statusListenable,
      builder: (context, _, __) {
        final on = _svc.status == AiConsentStatus.granted;
        // A Material (not a decorated Container) so the tiles' ink splashes
        // stay visible.
        return Material(
          color: AppColors.backgroundCard,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            side: BorderSide(
              color: on
                  ? AppColors.richGold.withValues(alpha: 0.5)
                  : AppColors.divider,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                key: const Key('aiServicesSwitch'),
                value: on,
                onChanged: _busy ? null : _onChanged,
                activeThumbColor: AppColors.richGold,
                contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
                secondary: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.richGold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                  child: const Icon(Icons.auto_awesome,
                      color: AppColors.richGold, size: 24),
                ),
                title: Text(
                  l10n.aiServicesTitle,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    on ? l10n.aiServicesSubtitleOn : l10n.aiServicesSubtitleOff,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 14),
                  ),
                ),
              ),
              Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  key: const Key('aiServicesDetails'),
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  iconColor: AppColors.textSecondary,
                  collapsedIconColor: AppColors.textTertiary,
                  title: Text(
                    l10n.aiServicesWhatsIncluded,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                  children: [
                    _point(
                        Icons.lightbulb_outline, l10n.aiServicesFeatureCoach),
                    _point(Icons.translate, l10n.aiServicesFeatureTranslate),
                    _point(Icons.volume_up_outlined,
                        l10n.aiServicesFeatureReadAloud),
                    _point(Icons.support_agent, l10n.aiServicesFeatureSupport),
                    _point(Icons.shield_outlined, l10n.aiServicesSafetyNote,
                        color: AppColors.textTertiary),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _point(IconData icon, String text,
          {Color color = AppColors.textSecondary}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.richGold),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: TextStyle(color: color, fontSize: 13, height: 1.4)),
            ),
          ],
        ),
      );
}
