import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/analytics_consent_service.dart';
import '../../../../core/services/consent_recorder.dart';
import '../../../../core/services/data_export_service.dart';
import '../../../../core/widgets/reauthenticate_dialog.dart';
import '../../../../generated/app_localizations.dart';

/// Privacy & data choices (P2-5): usage analytics / crash reports and
/// marketing emails; "Download my data" (P3-2, GDPR Art. 15/20, LGPD Art. 18).
/// Available to every user (all tiers, mobile + web).
class PrivacyDataSettingsScreen extends StatefulWidget {
  const PrivacyDataSettingsScreen({
    super.key,
    this.analytics,
    this.recorder,
    this.dataExport,
    this.reauthenticate,
    this.openUrl,
  });

  final AnalyticsConsentService? analytics;
  final ConsentRecorder? recorder;
  final DataExportService? dataExport;

  /// Re-authentication prompt (tests override it).
  final Future<bool> Function(BuildContext context)? reauthenticate;

  /// Opens the download link (tests override it).
  final Future<bool> Function(Uri url)? openUrl;

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
  DataExportService get _dataExport =>
      widget.dataExport ?? DataExportService.instance;

  bool _marketingEmail = false;
  bool _savingMarketing = false;
  bool _exporting = false;

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

  Future<void> _downloadMyData() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(l10n.privacyDownloadDataTitle,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(l10n.privacyDownloadDataConfirmBody,
            style:
                const TextStyle(color: AppColors.textSecondary, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            key: const Key('privacyDownloadDataConfirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.privacyDownloadDataConfirmButton,
                style: const TextStyle(
                    color: AppColors.richGold, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _exporting = true);
    var result = await _dataExport.requestExport();
    // Sign-in too old: prove it is you, then try once more.
    if (result.failure == DataExportFailure.requiresRecentLogin && mounted) {
      final reauthed =
          await (widget.reauthenticate ?? reauthenticateCurrentUser)(context);
      if (reauthed && mounted) result = await _dataExport.requestExport();
    }
    if (!mounted) return;
    setState(() => _exporting = false);

    if (result.ok) {
      await _showExportReady(result);
      return;
    }
    final message = switch (result.failure) {
      DataExportFailure.rateLimited => l10n.privacyDownloadDataRateLimited,
      DataExportFailure.inProgress => l10n.privacyDownloadDataInProgress,
      DataExportFailure.requiresRecentLogin => l10n.reauthSignInAgain,
      _ => l10n.privacyDownloadDataFailed,
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: AppColors.errorRed,
    ));
  }

  Future<void> _showExportReady(DataExportResult result) async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(l10n.privacyDownloadDataReadyTitle,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(
          result.emailSent
              ? '${l10n.privacyDownloadDataReadyBody}\n\n${l10n.privacyDownloadDataReadyEmailed}'
              : l10n.privacyDownloadDataReadyBody,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.close,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            key: const Key('privacyDownloadDataOpen'),
            onPressed: () async {
              final open = widget.openUrl ??
                  (Uri u) => launchUrl(u, mode: LaunchMode.externalApplication);
              final ok = await open(Uri.parse(result.url!));
              if (!ok && dialogContext.mounted) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(
                  content: Text(l10n.privacyDownloadDataFailed),
                  backgroundColor: AppColors.errorRed,
                ));
              }
            },
            child: Text(l10n.privacyDownloadDataOpen,
                style: const TextStyle(
                    color: AppColors.richGold, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
              const Divider(height: 1),
              ListTile(
                key: const Key('privacyDownloadDataTile'),
                leading: const Icon(Icons.download_outlined,
                    color: AppColors.richGold),
                title: Text(l10n.privacyDownloadDataTitle,
                    style: const TextStyle(color: AppColors.textPrimary)),
                subtitle: Text(
                    _exporting
                        ? l10n.privacyDownloadDataPreparing
                        : l10n.privacyDownloadDataSubtitle,
                    style: const TextStyle(color: AppColors.textSecondary)),
                trailing: _exporting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.richGold))
                    : null,
                onTap: _exporting ? null : _downloadMyData,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
