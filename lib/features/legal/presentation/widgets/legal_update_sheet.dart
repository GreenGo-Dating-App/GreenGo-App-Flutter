import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/legal_versions.dart';
import '../../../../core/services/consent_recorder.dart';
import '../../../../generated/app_localizations.dart';
import '../screens/legal_document_screen.dart';

/// Reads `consents/{uid}` (owner-readable, server-written by `recordConsent`).
typedef ConsentDocReader = Future<Map<String, dynamic>?> Function(String uid);

Future<Map<String, dynamic>?> _readConsentDoc(String uid) async {
  final snap =
      await FirebaseFirestore.instance.collection('consents').doc(uid).get();
  return snap.data();
}

/// Decides whether the signed-in user still has to accept the current Terms /
/// Privacy Policy (material change: [kTermsReacceptFrom] /
/// [kPrivacyReacceptFrom]).
///
/// Source of truth is the server record `consents/{uid}.terms|privacy`
/// (`accepted` + `docVersion`, server timestamp). A local per-user mirror
/// (ConsentRecorder.localDocKey) skips the read once acceptance is known, so
/// the check costs one document read per user, once.
class LegalUpdateGate {
  LegalUpdateGate({
    ConsentRecorder? recorder,
    ConsentDocReader? readConsents,
    String? Function()? currentUid,
  })  : _recorder = recorder ?? ConsentRecorder.instance,
        _read = readConsents ?? _readConsentDoc,
        _uid = currentUid ?? (() => FirebaseAuth.instance.currentUser?.uid);

  final ConsentRecorder _recorder;
  final ConsentDocReader _read;
  final String? Function() _uid;

  static bool _accepted(dynamic rec, String min) =>
      rec is Map &&
      rec['accepted'] == true &&
      isLegalVersionAtLeast(rec['docVersion'] as String?, min);

  /// True when the sheet must be shown. Never throws: when the server record
  /// cannot be read (offline), it returns false and the next app start
  /// checks again.
  Future<bool> needsAcceptance() async {
    final uid = _uid();
    if (uid == null) return false;
    final localTerms = await _recorder.localDocVersion(ConsentTypes.terms);
    final localPrivacy = await _recorder.localDocVersion(ConsentTypes.privacy);
    if (isLegalVersionAtLeast(localTerms, kTermsReacceptFrom) &&
        isLegalVersionAtLeast(localPrivacy, kPrivacyReacceptFrom)) {
      return false;
    }
    Map<String, dynamic>? data;
    try {
      data = await _read(uid);
    } catch (e) {
      debugPrint('LegalUpdateGate: consent read failed: $e');
      return false;
    }
    final terms = data?[ConsentTypes.terms];
    final privacy = data?[ConsentTypes.privacy];
    final ok = _accepted(terms, kTermsReacceptFrom) &&
        _accepted(privacy, kPrivacyReacceptFrom);
    if (ok) {
      await _recorder.rememberDocVersion(
          ConsentTypes.terms, (terms as Map)['docVersion'] as String);
      await _recorder.rememberDocVersion(
          ConsentTypes.privacy, (privacy as Map)['docVersion'] as String);
    }
    return !ok;
  }
}

/// True while the sheet is open (no double show from two triggers).
bool _legalSheetShownThisSession = false;

/// How the re-acceptance sheet was closed.
enum LegalUpdateOutcome { agreed, signOut, closeAccount }

/// "What's new" bullets of a material Terms / Privacy [version] (the version
/// that raised [kTermsReacceptFrom] / [kPrivacyReacceptFrom], or the upcoming
/// one announced in advance). Empty for a version without bullets.
List<String> legalUpdateBullets(AppLocalizations l10n, String? version) =>
    switch (version) {
      '5.1.0' => [
          l10n.legalUpdateBulletPrivateContent,
          l10n.legalUpdateBulletWarning,
          l10n.legalUpdateBulletOrientation,
        ],
      '5.3.0' => [
          l10n.legalUpdate530BulletReferral,
          l10n.legalUpdate530BulletCoinGifts,
          l10n.legalUpdate530BulletMenus,
          l10n.legalUpdate530BulletModeration,
          l10n.legalUpdate530BulletTraders,
        ],
      // 5.3.1 = 5.3.0 + higher service fee caps (11.6 b).
      '5.3.1' => [
          l10n.legalUpdate530BulletReferral,
          l10n.legalUpdate530BulletCoinGifts,
          l10n.legalUpdate530BulletMenus,
          l10n.legalUpdate530BulletModeration,
          l10n.legalUpdate530BulletTraders,
          l10n.legalUpdate531BulletFeeCaps,
        ],
      _ => const <String>[],
    };

/// Shows the non-dismissable "we've updated our Terms and Privacy Policy"
/// sheet when [LegalUpdateGate.needsAcceptance]. "I agree" records terms +
/// privacy acceptance server-side (`recordConsent`, server timestamp) and
/// only then closes. [onSignOut] is the way out for a user who does not agree;
/// [onCloseAccount] is "I don't accept - close my account" (Terms 24.2 c: end
/// the contract free of charge, pro-rata refund of a prepaid Membership): it
/// leads to the delete-account flow. Without it, that choice signs out.
Future<void> showLegalUpdateSheetIfNeeded(
  BuildContext context, {
  required VoidCallback onSignOut,
  VoidCallback? onCloseAccount,
  LegalUpdateGate? gate,
  ConsentRecorder? recorder,
}) async {
  if (_legalSheetShownThisSession) return;
  final g = gate ?? LegalUpdateGate(recorder: recorder);
  if (!await g.needsAcceptance()) return;
  if (!context.mounted || _legalSheetShownThisSession) return;
  _legalSheetShownThisSession = true;
  final outcome = await showModalBottomSheet<LegalUpdateOutcome>(
    context: context,
    backgroundColor: AppColors.backgroundCard,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => PopScope(
      canPop: false,
      child: LegalUpdateSheetBody(
        recorder: recorder ?? ConsentRecorder.instance,
      ),
    ),
  );
  // Guard only while the sheet is up: after "I agree" the per-user local
  // mirror stops it, and another account signed in later is checked anew.
  _legalSheetShownThisSession = false;
  switch (outcome) {
    case LegalUpdateOutcome.agreed:
      return;
    case LegalUpdateOutcome.closeAccount:
      (onCloseAccount ?? onSignOut)();
      return;
    case LegalUpdateOutcome.signOut:
    case null:
      onSignOut();
  }
}

/// Resets the once-per-session guard (tests).
@visibleForTesting
void resetLegalUpdateSheetSession() => _legalSheetShownThisSession = false;

class LegalUpdateSheetBody extends StatefulWidget {
  const LegalUpdateSheetBody({required this.recorder, super.key});

  final ConsentRecorder recorder;

  @override
  State<LegalUpdateSheetBody> createState() => _LegalUpdateSheetBodyState();
}

class _LegalUpdateSheetBodyState extends State<LegalUpdateSheetBody> {
  bool _saving = false;
  bool _failed = false;

  Future<void> _agree() async {
    setState(() {
      _saving = true;
      _failed = false;
    });
    final ok = await widget.recorder.recordLegalUpdateAcceptance();
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(LegalUpdateOutcome.agreed);
    } else {
      setState(() {
        _saving = false;
        _failed = true;
      });
    }
  }

  /// Terms 24.2 c: explain the right to end the contract free of charge
  /// (pro-rata refund of a prepaid Membership), then hand over to the
  /// delete-account flow.
  Future<void> _closeAccount() async {
    final l10n = AppLocalizations.of(context)!;
    final go = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(l10n.legalUpdateCloseAccountTitle,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: SingleChildScrollView(
          child: Text(
            l10n.legalUpdateCloseAccountBody(kBillingSupportEmail),
            key: const Key('legalUpdateCloseAccountBody'),
            style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            key: const Key('legalUpdateCloseAccountContinue'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.legalUpdateCloseAccountContinue,
                style: const TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
    if (go == true && mounted) {
      Navigator.of(context).pop(LegalUpdateOutcome.closeAccount);
    }
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    String date;
    try {
      date = DateFormat.yMMMMd(locale).format(kTermsEffectiveDate);
    } catch (_) {
      date = DateFormat.yMMMMd().format(kTermsEffectiveDate);
    }
    final bullets = legalUpdateBullets(l10n, legalUpdateBulletsVersion);
    const bodyStyle =
        TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4);

    return SafeArea(
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 560,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.gavel_outlined, color: AppColors.richGold),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.legalUpdateTitle,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(l10n.legalUpdateIntro(kTermsVersion, date),
                    style: bodyStyle),
                const SizedBox(height: 8),
                for (final b in bullets)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 7, right: 8),
                          child: Icon(Icons.circle,
                              size: 6, color: AppColors.richGold),
                        ),
                        Expanded(child: Text(b, style: bodyStyle)),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton(
                      key: const Key('legalUpdateOpenTerms'),
                      onPressed: () =>
                          _open(const TermsAndConditionsScreen()),
                      child: Text(l10n.termsAndConditions),
                    ),
                    TextButton(
                      key: const Key('legalUpdateOpenPrivacy'),
                      onPressed: () => _open(const PrivacyPolicyScreen()),
                      child: Text(l10n.privacyPolicy),
                    ),
                  ],
                ),
                if (_failed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      l10n.legalUpdateSaveFailed,
                      style: const TextStyle(
                          color: AppColors.errorRed, fontSize: 13),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    key: const Key('legalUpdateAgree'),
                    onPressed: _saving ? null : _agree,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.richGold,
                      foregroundColor: AppColors.deepBlack,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.legalUpdateAgree),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.legalUpdateDisagreeHint,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    TextButton(
                      key: const Key('legalUpdateCloseAccount'),
                      onPressed: _saving ? null : _closeAccount,
                      child: Text(l10n.legalUpdateCloseAccount,
                          style: const TextStyle(color: AppColors.errorRed)),
                    ),
                    TextButton(
                      key: const Key('legalUpdateSignOut'),
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context)
                              .pop(LegalUpdateOutcome.signOut),
                      child: Text(l10n.signOut),
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
