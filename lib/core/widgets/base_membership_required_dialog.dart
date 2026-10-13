import 'package:flutter/material.dart';

import '../../features/profile/domain/entities/profile.dart';
import '../../features/subscription/presentation/screens/membership_screen.dart';
import '../../generated/app_localizations.dart';
import '../constants/app_colors.dart';
import '../services/own_profile_store.dart';

/// "Base membership required" upsell for joining events and booking
/// experiences (owner rule 2026-10-11). The CTA opens the same membership
/// screen the chat gate uses ([MembershipScreen], Base first).
///
/// Shown by `BaseMembershipGate.ensureCanParticipate` before a join / book,
/// and by `BaseMembershipGate.handleParticipationError` when the server
/// refuses one (`base_membership_required`).
class BaseMembershipRequiredDialog extends StatelessWidget {
  const BaseMembershipRequiredDialog(
      {required this.userId, this.title, this.body, super.key});

  final String userId;

  /// Overrides for other Base upsells (e.g. the daily free chats used up).
  final String? title;
  final String? body;

  static Future<void> show(BuildContext context,
      {required String userId, String? title, String? body}) async {
    final upgrade = await showDialog<bool>(
      context: context,
      builder: (_) => BaseMembershipRequiredDialog(
          userId: userId, title: title, body: body),
    );
    if (upgrade == true && context.mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MembershipScreen(currentUserId: userId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      key: const ValueKey('base-membership-required-dialog'),
      backgroundColor: AppColors.backgroundCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.richGold.withValues(alpha: 0.5)),
      ),
      icon: const Icon(Icons.workspace_premium,
          color: AppColors.richGold, size: 40),
      title: Text(
        title ?? l10n.participationBaseRequiredTitle,
        textAlign: TextAlign.center,
        style: const TextStyle(
            color: AppColors.textPrimary, fontWeight: FontWeight.bold),
      ),
      content: Text(
        body ?? l10n.participationBaseRequiredBody,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.notNow,
              style: const TextStyle(color: AppColors.textTertiary)),
        ),
        ElevatedButton(
          key: const ValueKey('base-membership-required-cta'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.richGold,
            foregroundColor: AppColors.deepBlack,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.participationBaseRequiredCta),
        ),
      ],
    );
  }
}

/// Small "lock + Base membership required" caption shown under a join / book
/// button for users who cannot participate yet. The button stays visible and
/// tappable (it opens [BaseMembershipRequiredDialog]). Hidden while the own
/// profile is unknown and for eligible users.
class BaseMembershipRequiredHint extends StatelessWidget {
  const BaseMembershipRequiredHint({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Profile?>(
      valueListenable: OwnProfileStore.instance.profile,
      builder: (context, _, __) {
        final p = OwnProfileStore.instance.peek(userId);
        // Same rule as BaseMembershipGate.canParticipate.
        if (p == null || p.isBaseMembershipActive) {
          return const SizedBox.shrink();
        }
        final l10n = AppLocalizations.of(context)!;
        return Padding(
          key: const ValueKey('base-membership-required-hint'),
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline,
                  size: 13, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  l10n.participationBaseRequiredHint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.textTertiary, fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
