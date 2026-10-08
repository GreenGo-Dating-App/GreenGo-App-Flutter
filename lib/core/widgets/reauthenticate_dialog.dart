import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../generated/app_localizations.dart';
import '../constants/app_colors.dart';
import '../utils/user_error.dart';

/// Asks the signed-in user to prove it is them again, for server actions that
/// need a recent sign-in (`exportMyData`; the same 10-minute rule as
/// `deleteMyAccount`).
///
/// - Email/password accounts: password prompt.
/// - Google / Apple accounts: the provider sign-in again (popup on web).
///
/// Returns true when the user re-authenticated.
Future<bool> reauthenticateCurrentUser(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;
  final providers = user.providerData.map((p) => p.providerId).toList();

  if (providers.contains('password') && user.email != null) {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PasswordReauthDialog(user: user),
    );
    return ok ?? false;
  }

  AuthProvider? provider;
  if (providers.contains('google.com')) provider = GoogleAuthProvider();
  if (provider == null && providers.contains('apple.com'))
    provider = AppleAuthProvider();
  final l10n = AppLocalizations.of(context)!;
  if (provider == null) {
    // e.g. phone-only accounts: ask the user to sign out and in again.
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(l10n.reauthSignInAgain),
      backgroundColor: AppColors.errorRed,
    ));
    return false;
  }
  try {
    if (kIsWeb) {
      await user.reauthenticateWithPopup(provider);
    } else {
      await user.reauthenticateWithProvider(provider);
    }
    return true;
  } on FirebaseAuthException catch (e) {
    if (e.code != 'popup-closed-by-user' &&
        e.code != 'canceled' &&
        e.code != 'web-context-canceled') {
      reportUserError(e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(userErrorMessage(context, e)),
          backgroundColor: AppColors.errorRed,
        ));
      }
    }
    return false;
  }
}

class _PasswordReauthDialog extends StatefulWidget {
  const _PasswordReauthDialog({required this.user});

  final User user;

  @override
  State<_PasswordReauthDialog> createState() => _PasswordReauthDialogState();
}

class _PasswordReauthDialogState extends State<_PasswordReauthDialog> {
  final _controller = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    // Do NOT trim: passwords may legitimately contain spaces.
    final password = _controller.text;
    if (password.isEmpty) {
      setState(() => _error = l10n.passwordRequired);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.user
          .reauthenticateWithCredential(EmailAuthProvider.credential(
        email: widget.user.email!.trim().toLowerCase(),
        password: password,
      ));
      if (mounted) Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _loading = false;
        if (e.code == 'too-many-requests') {
          _error = l10n.profileTooManyAttempts;
        } else if (e.code == 'wrong-password' ||
            e.code == 'invalid-credential') {
          _error = l10n.authErrorWrongPassword;
        } else {
          reportUserError(e);
          _error = userErrorMessage(context, e);
        }
      });
    } catch (e) {
      reportUserError(e);
      setState(() {
        _loading = false;
        _error = userErrorMessage(context, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: AppColors.backgroundCard,
      title: Text(l10n.profileConfirmYourPassword,
          style: const TextStyle(color: AppColors.textPrimary)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.reauthPasswordBody,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14, height: 1.5)),
          const SizedBox(height: 16),
          TextField(
            key: const Key('reauthPasswordField'),
            controller: _controller,
            obscureText: _obscure,
            autofocus: true,
            onSubmitted: (_) => _loading ? null : _submit(),
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: l10n.password,
              labelStyle: const TextStyle(color: AppColors.textSecondary),
              errorText: _error,
              errorMaxLines: 3,
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.textSecondary),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel,
              style: const TextStyle(color: AppColors.textSecondary)),
        ),
        TextButton(
          key: const Key('reauthConfirmButton'),
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.richGold))
              : Text(l10n.reauthContinue,
                  style: const TextStyle(
                      color: AppColors.richGold, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
