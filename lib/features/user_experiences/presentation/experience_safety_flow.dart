import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection_container.dart' as di;
import '../../../core/error/failures.dart';
import '../../../core/utils/user_error.dart';
import '../../../generated/app_localizations.dart';
import '../../safety/presentation/screens/age_verification_screen.dart';
import '../domain/entities/user_experience.dart';
import '../domain/repositories/user_experiences_repository.dart';
import 'screens/host_agreement_screen.dart';

/// Where a user stands on the identity document (age-assurance flow):
/// mirrors `idDocumentState` in functions/src/user_experiences/safety.ts.
enum IdDocState { none, uploaded, approved }

/// The ID photo sent at registration ("a photo of yourself holding your ID"),
/// reviewed by an admin. Phone sign-ups have none. Mirrors
/// functions/src/shared/registrationIdReview.ts.
enum RegistrationDoc { none, pending, approved }

/// Pure (unit-tested): the registration ID photo from a raw profile document.
RegistrationDoc registrationDocFromProfile(Map<String, dynamic>? p) {
  if (p == null || p['verificationMethod'] == 'phone') {
    return RegistrationDoc.none;
  }
  final s = p['verificationStatus'];
  if (s == 'approved' || s == 'verified') return RegistrationDoc.approved;
  if (s == 'pending') return RegistrationDoc.pending;
  return RegistrationDoc.none;
}

/// Pure (unit-tested): the document state from a raw profile document. A
/// registration ID photo counts as uploaded (the server trusts its approval
/// only through the admin's record).
IdDocState idDocStateFromProfile(Map<String, dynamic>? p) {
  if (p == null) return IdDocState.none;
  if (p['isAgeVerified'] == true) return IdDocState.approved;
  final av = p['ageVerification'];
  final status = av is Map ? av['status'] : null;
  if (status == 'verified') return IdDocState.approved;
  if (status == 'pending') return IdDocState.uploaded;
  if (registrationDocFromProfile(p) != RegistrationDoc.none) {
    return IdDocState.uploaded;
  }
  return IdDocState.none;
}

/// The bits of the profile the experience safety prompts need.
class HostSafetySnapshot {
  const HostSafetySnapshot({
    this.idState = IdDocState.none,
    this.idRejected = false,
    this.agreementVersion = 0,
    this.ageDocPending = false,
    this.registrationDoc = RegistrationDoc.none,
  });

  factory HostSafetySnapshot.fromProfile(Map<String, dynamic>? p) {
    final av = p?['ageVerification'];
    return HostSafetySnapshot(
      idState: idDocStateFromProfile(p),
      idRejected: av is Map && av['status'] == 'rejected',
      agreementVersion: (p?['hostAgreementVersion'] as num?)?.toInt() ?? 0,
      ageDocPending: av is Map && av['status'] == 'pending',
      registrationDoc: registrationDocFromProfile(p),
    );
  }

  final IdDocState idState;
  final bool idRejected;
  final int agreementVersion;

  /// The age-verification document is under review.
  final bool ageDocPending;
  final RegistrationDoc registrationDoc;

  /// A document is approved: age verification, or the registration ID photo
  /// an admin approved (the server double-checks the admin's record).
  bool get docApproved =>
      idState == IdDocState.approved ||
      registrationDoc == RegistrationDoc.approved;

  /// A document was sent and is still being validated.
  bool get docPending =>
      !docApproved &&
      (ageDocPending || registrationDoc == RegistrationDoc.pending);

  bool get agreementAccepted =>
      agreementVersion >= HostAgreementScreen.currentVersion;
}

/// Why the user is asked for an ID document (changes the explanation).
enum IdDocPurpose { payAsGuest, createAsHost }

/// What the host chose when a publish was refused.
enum SafetyResolution { retry, saveDraft, publishFree, cancel }

/// Phase 1 safety prompts for experiences: ASK for what is missing in place
/// (ID document, host agreement) and continue automatically once it is there;
/// for a paid listing the host can't publish yet, offer "Save as draft" /
/// "Publish as free". The server enforces every rule regardless.
class ExperienceSafetyFlow {
  const ExperienceSafetyFlow._();

  static Future<HostSafetySnapshot> load(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 8));
      return HostSafetySnapshot.fromProfile(doc.data());
    } catch (_) {
      return const HostSafetySnapshot();
    }
  }

  /// Paying a host: true once [uid] has an ID document uploaded (pending or
  /// approved). Creating as a host: true once a document is APPROVED (the
  /// registration ID photo counts); one still being validated says so and
  /// stops. With no document, explains why, opens the upload flow (web too)
  /// and re-checks on return, so the caller simply continues on true.
  static Future<bool> ensureIdDocument(
    BuildContext context,
    String uid,
    IdDocPurpose purpose,
  ) async {
    final before = await load(uid);
    if (purpose == IdDocPurpose.createAsHost) {
      if (before.docApproved) return true;
      if (before.docPending) {
        if (context.mounted) await _showPending(context);
        return false;
      }
    } else if (before.idState != IdDocState.none) {
      return true;
    }
    if (!context.mounted) return false;
    final l = AppLocalizations.of(context)!;
    final go = await _ask(
      context,
      title: l.uexpIdDocTitle,
      body: purpose == IdDocPurpose.payAsGuest
          ? l.uexpIdDocGuestBody
          : l.uexpIdDocHostBody,
      icon: Icons.badge_outlined,
      actions: [
        _Choice(l.cancel, false),
        _Choice(l.uexpIdDocUpload, true, primary: true),
      ],
    );
    if (go != true || !context.mounted) return false;
    await AgeVerificationScreen.push(context);
    final after = await load(uid);
    if (purpose == IdDocPurpose.createAsHost) {
      if (after.docApproved) return true;
      if (after.docPending && context.mounted) await _showPending(context);
      return false;
    }
    return after.idState != IdDocState.none;
  }

  /// "Your document is being validated": creating waits for the approval.
  static Future<void> _showPending(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    await _ask<bool>(
      context,
      title: l.uexpPaidPendingTitle,
      body: l.uexpIdDocPendingCreateBody,
      icon: Icons.hourglass_top_rounded,
      actions: [_Choice(l.ok, true, primary: true)],
    );
  }

  /// True once [uid] accepted the current host agreement (shows it if not).
  static Future<bool> ensureHostAgreement(BuildContext context, String uid,
      {HostSafetySnapshot? snapshot}) async {
    final s = snapshot ?? await load(uid);
    if (s.agreementAccepted) return true;
    if (!context.mounted) return false;
    final ok = await HostAgreementScreen.push(context);
    return ok == true;
  }

  /// Guided answer to a server refusal [code] (see safety.ts).
  static Future<SafetyResolution> resolve(
    BuildContext context,
    String uid,
    String code,
  ) async {
    final l = AppLocalizations.of(context)!;
    switch (code) {
      case 'id_document_required':
        return await ensureIdDocument(context, uid, IdDocPurpose.createAsHost)
            ? SafetyResolution.retry
            : SafetyResolution.cancel;
      case 'host_agreement_required':
      case 'agreement_outdated':
        return await ensureHostAgreement(context, uid,
                snapshot: const HostSafetySnapshot())
            ? SafetyResolution.retry
            : SafetyResolution.cancel;
      case 'id_document_not_approved':
        return paidBlocked(context, uid);
      case 'new_host_paid_limit':
        final r = await _ask(
          context,
          title: l.uexpNewHostLimitTitle,
          body: l.uexpNewHostLimitBody,
          icon: Icons.verified_user_outlined,
          actions: [
            _Choice(l.cancel, SafetyResolution.cancel),
            _Choice(l.uexpSaveDraft, SafetyResolution.saveDraft),
            _Choice(l.uexpPublishAsFree, SafetyResolution.publishFree,
                primary: true),
          ],
        );
        return r ?? SafetyResolution.cancel;
      case 'business_required':
        final b = await _ask(
          context,
          title: l.uexpBusinessRequiredTitle,
          body: l.paidBusinessOnlyBody,
          icon: Icons.storefront_outlined,
          actions: [
            _Choice(l.cancel, SafetyResolution.cancel),
            _Choice(l.uexpSaveDraft, SafetyResolution.saveDraft),
            _Choice(l.uexpPublishAsFree, SafetyResolution.publishFree,
                primary: true),
          ],
        );
        return b ?? SafetyResolution.cancel;
      case 'host_banned':
        _snack(context, l.uexpHostBanned);
        return SafetyResolution.cancel;
      case 'dates_required':
        _snack(context, l.uexpDatesRequiredToPublish);
        return SafetyResolution.cancel;
      default:
        _snack(context, l.userErrorGeneric);
        return SafetyResolution.cancel;
    }
  }

  /// A paid listing whose host has no APPROVED document: review pending →
  /// explain; missing / rejected → offer the upload too. Always offers
  /// "Save as draft" / "Publish as free".
  static Future<SafetyResolution> paidBlocked(
      BuildContext context, String uid) async {
    final l = AppLocalizations.of(context)!;
    final s = await load(uid);
    if (!context.mounted) return SafetyResolution.cancel;
    // An admin-approved registration photo: the server checks the admin's
    // record, so try again.
    if (s.docApproved) return SafetyResolution.retry;
    final pending = s.docPending;
    final r = await _ask(
      context,
      title: pending ? l.uexpPaidPendingTitle : l.uexpIdDocTitle,
      body: pending ? l.uexpPaidPendingBody : l.uexpPaidMissingBody,
      icon: pending ? Icons.hourglass_top_rounded : Icons.badge_outlined,
      actions: [
        if (!pending) _Choice(l.uexpIdDocUpload, SafetyResolution.retry),
        _Choice(l.uexpSaveDraft, SafetyResolution.saveDraft),
        _Choice(l.uexpPublishAsFree, SafetyResolution.publishFree,
            primary: true),
      ],
    );
    if (r == SafetyResolution.retry && context.mounted) {
      // Upload, then ask again (an approved document publishes; a pending
      // one comes back here with the pending explanation).
      await AgeVerificationScreen.push(context);
      if (!context.mounted) return SafetyResolution.cancel;
      return paidBlocked(context, uid);
    }
    return r ?? SafetyResolution.cancel;
  }

  /// Publishes [e] through the server with the guided prompts. Returns the
  /// published experience (free if the host chose "Publish as free"), or null
  /// when it stays unpublished.
  static Future<UserExperience?> publish(
    BuildContext context,
    String uid,
    UserExperience e,
  ) async {
    final l = AppLocalizations.of(context)!;
    final repo = di.sl<UserExperiencesRepository>();
    if (!await ensureHostAgreement(context, uid)) return null;
    var asFree = false;
    for (var attempt = 0; attempt < 4; attempt++) {
      final r = await repo.publishExperience(e.id, asFree: asFree);
      Failure? failure;
      r.fold((f) => failure = f, (_) {});
      if (failure == null) {
        final published = (asFree ? e.asFree() : e)
            .copyWith(status: ExperienceStatus.published);
        return published;
      }
      if (!context.mounted) return null;
      final f = failure;
      if (f is! ExperienceSafetyFailure) {
        if (f is ExperienceContactInfoFailure) {
          _snack(context, l.uexpErrContactInfo);
        } else {
          showUserError(context, f);
        }
        return null;
      }
      final res = await resolve(context, uid, f.code);
      if (!context.mounted) return null;
      switch (res) {
        case SafetyResolution.retry:
          continue;
        case SafetyResolution.publishFree:
          asFree = true;
          continue;
        case SafetyResolution.saveDraft:
          _snack(context, l.uexpSaved, error: false);
          return null;
        case SafetyResolution.cancel:
          return null;
      }
    }
    return null;
  }

  static void _snack(BuildContext context, String msg, {bool error = true}) {
    if (error) {
      showUserErrorMessage(context, msg);
      return;
    }
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.errorRed : AppColors.successGreen,
    ));
  }

  static Future<T?> _ask<T>(
    BuildContext context, {
    required String title,
    required String body,
    required IconData icon,
    required List<_Choice<T>> actions,
  }) =>
      showDialog<T>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.backgroundCard,
          icon: Icon(icon, color: AppColors.richGold, size: 32),
          title: Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textPrimary)),
          content: Text(body,
              style: const TextStyle(
                  color: AppColors.textSecondary, height: 1.4)),
          actionsOverflowButtonSpacing: 4,
          actions: [
            for (final a in actions)
              a.primary
                  ? ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.richGold,
                        foregroundColor: AppColors.deepBlack,
                        minimumSize: const Size(0, 40),
                      ),
                      onPressed: () => Navigator.pop(ctx, a.value),
                      child: Text(a.label),
                    )
                  : TextButton(
                      onPressed: () => Navigator.pop(ctx, a.value),
                      child: Text(a.label),
                    ),
          ],
        ),
      );
}

class _Choice<T> {
  const _Choice(this.label, this.value, {this.primary = false});
  final String label;
  final T value;
  final bool primary;
}
