import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';

/// Asks before a location is sent in a chat (owner notes 2026-10-20):
/// "Are you sure you want to share your exact location?" Cancel / Share.
///
/// True only when the user tapped Share; Cancel, the back button or a tap
/// outside the dialog all mean no.
Future<bool> confirmShareLocation(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      key: const ValueKey('share-location-confirm'),
      backgroundColor: AppColors.backgroundCard,
      icon: const Icon(Icons.location_on, color: AppColors.richGold),
      content: Text(
        l10n.chatShareLocationConfirmMessage,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
      ),
      actions: [
        TextButton(
          key: const ValueKey('share-location-cancel'),
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(
            l10n.cancel,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        TextButton(
          key: const ValueKey('share-location-confirm-share'),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(
            l10n.chatShareLocationConfirmShare,
            style: const TextStyle(
              color: AppColors.richGold,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
  return ok ?? false;
}
