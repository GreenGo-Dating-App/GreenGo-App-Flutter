import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../generated/app_localizations.dart';
import '../../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../../authentication/presentation/bloc/auth_event.dart';

/// Shown when the user tries to leave the registration wizard at the first step
/// (or via the system/browser back). The account already exists but the profile
/// is incomplete, so "exit" means sign out and return to the login screen —
/// never pop the route, which would leave a black (empty-navigator) screen.
Future<void> showOnboardingExitDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.backgroundCard,
      title: Text(
        l10n?.onboardingExitTitle ?? 'Exit registration?',
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      content: Text(
        l10n?.onboardingExitMessage ??
            "You'll be signed out. You can finish setting up your profile next time you log in.",
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n?.onboardingExitCancel ?? 'Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(
            l10n?.onboardingExitConfirm ?? 'Sign Out',
            style: const TextStyle(color: AppColors.errorRed),
          ),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    context.read<AuthBloc>().add(const AuthSignOutRequested());
  }
}
