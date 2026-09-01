import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../generated/app_localizations.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    // Captured before the first await so none of the copy below reads the
    // BuildContext across an async gap.
    final l10n = AppLocalizations.of(context)!;

    setState(() => _isLoading = true);

    try {
      await FirebaseFunctions.instance
          .httpsCallable('sendPasswordResetViaResend')
          .call({'email': _emailController.text.trim()});

      if (!mounted) return;

      // Show success dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.backgroundCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.check_circle,
                  color: AppColors.successGreen, size: 28),
              const SizedBox(width: 12),
              Text(
                l10n.resetEmailSentTitle,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 18),
              ),
            ],
          ),
          content: Text(
            l10n.resetEmailSentBody(_emailController.text.trim()),
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                AppLocalizations.of(ctx)!.ok,
                style: const TextStyle(
                  color: AppColors.richGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Return to login
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      String message;
      switch (e.code) {
        case 'invalid-argument':
          message = l10n.resetErrorInvalidEmail;
          break;
        case 'unavailable':
          message = l10n.resetErrorUnavailable;
          break;
        default:
          message = l10n.resetErrorFailed;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white)),
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.somethingWentWrong,
              style: const TextStyle(color: Colors.white)),
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Read above the Scaffold — it zeroes viewInsets for its body once it has
    // resized to avoid the keyboard.
    final keyboardUp = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(l10n.resetPassword),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Same contract as the login screen: while the keyboard is up on a
            // short viewport, collapse the decorative header so the Send
            // button stays on screen instead of sliding behind the keyboard.
            final compact = keyboardUp && constraints.maxHeight < 640;
            final iconSize = compact ? 72.0 : 120.0;
            final topGap = compact ? 8.0 : 40.0;
            final gap = compact ? 16.0 : 32.0;
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: topGap),

                        // Icon
                        Container(
                          width: iconSize,
                          height: iconSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.backgroundCard,
                            border: Border.all(
                              color: AppColors.richGold,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.lock_reset,
                            size: 60,
                            color: AppColors.richGold,
                          ),
                        ),

                        SizedBox(height: gap),

                        // Title
                        Text(
                          l10n.resetPasswordTitle,
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(
                                color: AppColors.richGold,
                              ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 16),

                        // Description
                        Text(
                          l10n.resetPasswordSubtitle,
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: gap),

                        // Email Field
                        AuthTextField(
                          controller: _emailController,
                          label: l10n.email,
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.validateEmail,
                          prefixIcon: Icons.email_outlined,
                          enabled: !_isLoading,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _handleResetPassword(),
                        ),

                        const SizedBox(height: 32),

                        // Send Button
                        AuthButton(
                          text: l10n.sendResetLink,
                          onPressed: _isLoading ? null : _handleResetPassword,
                          isLoading: _isLoading,
                          icon: Icons.send,
                        ),

                        const SizedBox(height: 16),

                        // Back to Login
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  Navigator.of(context).pop();
                                },
                          child: Text(
                            l10n.backToLogin,
                            style: const TextStyle(
                              color: AppColors.richGold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Help Text
                        Container(
                          padding: const EdgeInsets.all(AppDimensions.paddingM),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundCard,
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusM),
                            border: Border.all(
                              color: AppColors.divider,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: AppColors.richGold,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  l10n.resetLinkExpiryNote,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
