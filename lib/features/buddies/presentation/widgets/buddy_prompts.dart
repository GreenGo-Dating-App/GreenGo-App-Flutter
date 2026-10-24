import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/ai_consent_service.dart';
import '../../../../core/services/app_sound_service.dart';
import '../../../../core/services/tier_gate.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/utils/user_error.dart';
import '../../../../core/widgets/ai_consent_sheet.dart';
import '../../../../core/widgets/limit_reached_dialog.dart';
import '../../../../generated/app_localizations.dart';
import '../../../coins/presentation/bloc/coin_bloc.dart';
import '../../../coins/presentation/bloc/coin_event.dart';
import '../../../coins/presentation/screens/coin_shop_screen.dart';
import '../../../membership/domain/entities/membership.dart';
import '../../../safety/presentation/widgets/content_report_flow.dart';
import '../../domain/buddy_exception.dart';

/// Everything the Buddy screens show or call outside the feature: upgrade
/// and coin-shop prompts, the AI notice, translation, reporting and sounds.
/// One object so widget tests can swap it for a fake.
class BuddyPrompts {
  const BuddyPrompts();

  /// "Buddy limit reached" / "this Buddy is locked": the plan upsell used by
  /// the other tier gates ([FeatureNotAvailableDialog] -> membership plans).
  Future<void> showUpgrade(BuildContext context,
      {required String uid, required int limit, String? tier}) async {
    final l10n = AppLocalizations.of(context)!;
    final current = MembershipTier.fromString(tier);
    final next = switch (current) {
      MembershipTier.free => MembershipTier.silver,
      MembershipTier.silver => MembershipTier.gold,
      _ => MembershipTier.platinum,
    };
    final r = await FeatureNotAvailableDialog.show(
      context: context,
      featureName: l10n.buddiesFeatureName,
      description: l10n.buddyLimitBody(limit),
      currentTier: current,
      requiredTier: next,
      userId: uid,
      icon: Icons.smart_toy_outlined,
    );
    if (r?.action == LimitDialogAction.upgrade && context.mounted) {
      TierGate().openMembershipUpgrade(context, currentUserId: uid);
    }
  }

  /// Free replies used up and no coins: the coin shop prompt (same pattern
  /// as the other coin features). [repliesPerCoin] > 1 = one coin buys
  /// several replies (from `getBuddyStatus`, never hard-coded).
  Future<void> showInsufficientCoins(BuildContext context,
      {required String uid, required int coins, int repliesPerCoin = 1}) {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title:
            Text(l10n.insufficientCoinsTitle, style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(
            repliesPerCoin > 1
                ? l10n.buddyInsufficientCoinsBundleBody(repliesPerCoin)
                : l10n.buddyInsufficientCoinsBody(coins),
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => BlocProvider(
                    create: (_) => di.sl<CoinBloc>()
                      ..add(LoadCoinBalance(uid))
                      ..add(const LoadAvailablePackages()),
                    child: CoinShopScreen(userId: uid),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.richGold),
            child: Text(l10n.buddyBuyCoins, style: const TextStyle(color: AppColors.deepBlack)),
          ),
        ],
      ),
    );
  }

  /// The server wants an (updated) AI notice. Returns true when the caller
  /// may retry: the device already had a decision that just was not stored
  /// on the server, or the user accepted the notice now.
  Future<bool> ensureAiConsent(BuildContext context, {required bool update}) async {
    final svc = AiConsentService.instance;
    await svc.ensureLoaded();
    if (!update && svc.isGranted && await svc.resyncAfterServerRejection()) {
      return true;
    }
    if (!context.mounted) return false;
    return await showAiConsentSheet(context) == true;
  }

  /// Translates a Buddy message into the app language through the private
  /// (contracted) translation path. Null = could not translate.
  Future<String?> translate(BuildContext context, String text, String target) async {
    final svc = TranslationService();
    var r = await svc.translateDetailed(text: text, targetLanguage: target);
    if (r.consentRequired && context.mounted) {
      if (await showAiConsentSheet(context) != true) return null;
      r = await svc.translateDetailed(text: text, targetLanguage: target);
    }
    return r.failed ? null : r.text;
  }

  /// The shared content report flow (reason picker -> `reports`).
  Future<void> report(BuildContext context,
      {required String uid,
      required String buddyId,
      required String messageId,
      required String text}) async {
    final l10n = AppLocalizations.of(context)!;
    await showContentReportFlow(
      context,
      reporterId: uid,
      type: 'ai_buddy_message',
      contentPath: 'ai_buddies/$uid/buddies/$buddyId/messages/$messageId',
      title: l10n.buddyReportTitle,
      description: text,
      extra: {'buddyId': buddyId},
    );
  }

  void playSound(AppSound sound) => AppSoundService().play(sound);

  /// Localized text for refusals that are not handled by a dedicated prompt.
  String messageFor(AppLocalizations l10n, BuddyException e) {
    switch (e.kind) {
      case BuddyErrorKind.rateLimited:
      case BuddyErrorKind.duplicate:
        return l10n.buddyErrorRateLimited;
      case BuddyErrorKind.unavailable:
        return l10n.buddyErrorUnavailable;
      case BuddyErrorKind.textTooLong:
        return l10n.buddyErrorTooLong(e.max ?? 500);
      case BuddyErrorKind.consentRequired:
      case BuddyErrorKind.consentUpdateRequired:
        return l10n.buddyErrorConsentNeeded;
      default:
        return l10n.userErrorGeneric;
    }
  }

  /// A refused call that has no dedicated prompt.
  Future<void> showError(BuildContext context, BuddyException e) {
    final l10n = AppLocalizations.of(context)!;
    if (e.kind == BuddyErrorKind.other && e.cause != null) {
      return showUserError(context, e.cause);
    }
    return showUserErrorMessage(context, messageFor(l10n, e));
  }
}
