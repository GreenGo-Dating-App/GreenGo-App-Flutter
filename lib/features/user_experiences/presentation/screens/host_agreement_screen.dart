import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../generated/app_localizations.dart';
import '../../domain/repositories/user_experiences_repository.dart';

/// Host agreement, shown before a host publishes their first experience.
///
/// LEGAL TEXT IS A DRAFT FOR LAWYER REVIEW (v1): the clauses live in the ARBs
/// (hostAgreementClause1..7 + idDocumentRetentionNotice, 7 languages). When
/// the text changes materially, bump [currentVersion] here AND
/// HOST_AGREEMENT_VERSION in functions/src/user_experiences/safety.ts: hosts
/// are then asked to accept again before their next publish.
///
/// Acceptance is recorded server-side by the `acceptHostAgreement` callable
/// (profiles.hostAgreementAcceptedAt / hostAgreementVersion, which clients
/// cannot write). Pops true once accepted.
class HostAgreementScreen extends StatefulWidget {
  const HostAgreementScreen({super.key});

  static const int currentVersion = 1;

  static Future<bool?> push(BuildContext context) =>
      Navigator.of(context).push<bool>(MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const HostAgreementScreen(),
      ));

  /// The clauses in display order (unit-tested: all 7 languages non-empty).
  static List<String> clauses(AppLocalizations l) => [
        l.hostAgreementClause1,
        l.hostAgreementClause2,
        l.hostAgreementClause3,
        l.hostAgreementClause4,
        l.hostAgreementClause5,
        l.hostAgreementClause6,
        l.hostAgreementClause7,
        l.idDocumentRetentionNotice,
      ];

  @override
  State<HostAgreementScreen> createState() => _HostAgreementScreenState();
}

class _HostAgreementScreenState extends State<HostAgreementScreen> {
  bool _checked = false;
  bool _saving = false;

  Future<void> _accept() async {
    final l = AppLocalizations.of(context)!;
    setState(() => _saving = true);
    final r = await di
        .sl<UserExperiencesRepository>()
        .acceptHostAgreement(HostAgreementScreen.currentVersion);
    if (!mounted) return;
    setState(() => _saving = false);
    r.fold(
      (_) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l.somethingWentWrong),
          backgroundColor: AppColors.errorRed)),
      (_) => Navigator.of(context).pop(true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final clauses = HostAgreementScreen.clauses(l);
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: Text(l.hostAgreementTitle,
            style: const TextStyle(color: AppColors.textPrimary)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(l.hostAgreementIntro,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14, height: 1.4)),
          const SizedBox(height: 16),
          for (var i = 0; i < clauses.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.richGold.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Text('${i + 1}',
                        style: const TextStyle(
                            color: AppColors.richGold,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(clauses[i],
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            height: 1.4)),
                  ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CheckboxListTile(
                value: _checked,
                onChanged: _saving
                    ? null
                    : (v) => setState(() => _checked = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: AppColors.richGold,
                contentPadding: EdgeInsets.zero,
                title: Text(l.hostAgreementCheckbox,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 14)),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ElevatedButton(
                  key: const ValueKey('host-agreement-accept'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.richGold,
                    foregroundColor: AppColors.deepBlack,
                    minimumSize: const Size(0, 48),
                  ),
                  onPressed: _checked && !_saving ? _accept : null,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.deepBlack))
                      : Text(l.hostAgreementAccept),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
