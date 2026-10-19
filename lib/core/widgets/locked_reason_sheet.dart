import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/coins/presentation/bloc/coin_bloc.dart';
import '../../features/coins/presentation/bloc/coin_event.dart';
import '../../features/coins/presentation/screens/coin_shop_screen.dart';
import '../../features/membership/domain/entities/membership.dart';
import '../../features/subscription/presentation/tier_l10n.dart';
import '../../generated/app_localizations.dart';
import '../constants/app_colors.dart';
import '../di/injection_container.dart' as di;
import 'explain_sheet.dart';

/// "Why can't I...?" sheet: explains why a feature is locked and offers the
/// one action that unlocks it (upgrade, verify phone, add a photo...).
///
/// Returns `true` from [show] when the user tapped the action button (the
/// [onAction] callback has then already run).
class LockedReasonSheet {
  LockedReasonSheet._();

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String reason,
    String? actionLabel,
    VoidCallback? onAction,
    List<String> bullets = const <String>[],
    IconData icon = Icons.lock_outline,
  }) async {
    var acted = false;
    await showExplainSheet<void>(
      context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return ExplainSheetFrame(
          title: title,
          message: reason,
          bullets: bullets,
          icon: icon,
          actions: [
            if (actionLabel != null && onAction != null) ...[
              ExplainPrimaryButton(
                label: actionLabel,
                onPressed: () {
                  acted = true;
                  Navigator.of(ctx).pop();
                },
              ),
              const SizedBox(height: 6),
              ExplainSecondaryButton(
                label: l10n.notNow,
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ] else
              ExplainPrimaryButton(
                label: explainGotIt(ctx),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
          ],
        );
      },
    );
    if (acted) onAction?.call();
    return acted;
  }

  /// Plan limit / plan-only feature: says which plan unlocks it and offers
  /// "See plans" which opens the Shop on its Membership tab.
  static Future<bool> showPlanRequired(
    BuildContext context, {
    required String userId,
    required String reason,
    MembershipTier? requiredTier,
    String? title,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final bullets = <String>[
      if (requiredTier != null)
        l10n.xplLockedUnlockedBy(
          localizedMembershipTierName(l10n, requiredTier),
        ),
    ];
    return show(
      context,
      title: title ?? l10n.xplLockedPlanTitle,
      reason: reason,
      bullets: bullets,
      icon: Icons.workspace_premium_outlined,
      actionLabel: l10n.xplSeePlans,
      onAction: () => openMembershipShop(context, userId),
    );
  }

  /// Phone verification required (new accounts): why + "Verify now".
  static Future<bool> showPhoneRequired(
    BuildContext context, {
    required VoidCallback onVerify,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return show(
      context,
      title: l10n.xplLockedPhoneTitle,
      reason: l10n.xplLockedPhoneBody,
      icon: Icons.phone_iphone,
      actionLabel: l10n.verifyNow,
      onAction: onVerify,
    );
  }

  /// Opens the Shop on its Membership tab (index 1), like the other tier
  /// gates of the app.
  static void openMembershipShop(BuildContext context, String userId) {
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider<CoinBloc>(
          create: (_) => di.sl<CoinBloc>()
            ..add(LoadCoinBalance(userId))
            ..add(const LoadAvailablePackages()),
          child: CoinShopScreen(userId: userId, initialTab: 1),
        ),
      ),
    );
  }
}

/// "What happens if I do this?" confirmation: lists the consequences and
/// asks for confirmation. Resolves to `true` only when confirmed.
class ConsequenceConfirmSheet {
  ConsequenceConfirmSheet._();

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required List<String> consequences,
    required String confirmLabel,
    String? message,
    bool destructive = false,
    IconData icon = Icons.help_outline,
    Key? confirmKey,
  }) async {
    final result = await showExplainSheet<bool>(
      context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return ExplainSheetFrame(
          title: title,
          message: message,
          bullets: consequences,
          icon: icon,
          iconColor: destructive ? AppColors.errorRed : AppColors.richGold,
          actions: [
            ExplainPrimaryButton(
              key: confirmKey,
              label: confirmLabel,
              destructive: destructive,
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
            const SizedBox(height: 6),
            ExplainSecondaryButton(
              label: l10n.cancel,
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}
