import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/analytics_consent_service.dart';
import '../../../../core/services/consent_recorder.dart';
import '../../../../generated/app_localizations.dart';

/// Privacy & data choices (P2-5): usage analytics / crash reports and
/// marketing emails. Available to every user (all tiers, mobile + web).
class PrivacyDataSettingsScreen extends StatefulWidget {
  const PrivacyDataSettingsScreen({
    super.key,
    this.analytics,
    this.recorder,
  });

  final AnalyticsConsentService? analytics;
  final ConsentRecorder? recorder;

  static Route<void> route() => MaterialPageRoute(
        builder: (_) => const PrivacyDataSettingsScreen(),
      );

  @override
  State<PrivacyDataSettingsScreen> createState() =>
      _PrivacyDataSettingsScreenState();
}

class _PrivacyDataSettingsScreenState extends State<PrivacyDataSettingsScreen> {
  AnalyticsConsentService get _analytics =>
      widget.analytics ?? AnalyticsConsentService.instance;
  ConsentRecorder get _recorder => widget.recorder ?? ConsentRecorder.instance;

  bool _marketingEmail = false;
  bool _savingMarketing = false;

  @override
  void initState() {
    super.initState();
    _loadMarketing();
  }

  Future<void> _loadMarketing() async {
    final v = await _recorder.localDecision(ConsentTypes.marketingEmail);
    if (!mounted) return;
    setState(() => _marketingEmail = v ?? false);
  }

  Future<void> _setMarketing(bool value) async {
    final previous = _marketingEmail;
    setState(() {
      _marketingEmail = value;
      _savingMarketing = true;
    });
    final ok = await _recorder.record(
      type: ConsentTypes.marketingEmail,
      accepted: value,
      retries: 1,
    );
    if (!mounted) return;
    setState(() {
      _savingMarketing = false;
      if (!ok) _marketingEmail = previous;
    });
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.privacySettingsSaveError),
        backgroundColor: AppColors.errorRed,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: Text(l10n.privacySettingsTitle),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              ValueListenableBuilder<AnalyticsConsentChoice>(
                valueListenable: _analytics.choice,
                builder: (context, _, __) => SwitchListTile(
                  key: const Key('privacyAnalyticsSwitch'),
                  activeColor: AppColors.richGold,
                  title: Text(l10n.privacyAnalyticsToggle,
                      style: const TextStyle(color: AppColors.textPrimary)),
                  subtitle: Text(l10n.privacyAnalyticsToggleSubtitle,
                      style: const TextStyle(color: AppColors.textSecondary)),
                  value: _analytics.collectionAllowed,
                  onChanged: (v) => _analytics.setChoice(granted: v),
                ),
              ),
              const Divider(height: 1),
              SwitchListTile(
                key: const Key('privacyMarketingEmailSwitch'),
                activeColor: AppColors.richGold,
                title: Text(l10n.privacyMarketingEmailToggle,
                    style: const TextStyle(color: AppColors.textPrimary)),
                subtitle: Text(l10n.privacyMarketingEmailSubtitle,
                    style: const TextStyle(color: AppColors.textSecondary)),
                value: _marketingEmail,
                onChanged: _savingMarketing ? null : _setMarketing,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
