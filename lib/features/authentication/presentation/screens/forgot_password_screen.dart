import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/validators.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';

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

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

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
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.successGreen, size: 28),
              SizedBox(width: 12),
              Text(
                'Email Sent!',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
              ),
            ],
          ),
          content: Text(
            'A password reset link has been sent to ${_emailController.text.trim()}.\n\nPlease check your inbox and spam folder.',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'OK',
                style: TextStyle(
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
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email address.';
          break;
        case 'invalid-email':
          message = 'Invalid email address.';
          break;
        case 'too-many-requests':
          message = 'Too many requests. Please try again later.';
          break;
        default:
          message = e.message ?? 'Failed to send reset email. Please try again.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white)),
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e', style: const TextStyle(color: Colors.white)),
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(AppStrings.resetPassword),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Icon
                Container(
                  width: 120,
                  height: 120,
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

                const SizedBox(height: 32),

                // Title
                Text(
                  'Reset Your Password',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppColors.richGold,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Description
                Text(
                  'Enter your email address and we\'ll send you instructions to reset your password.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Email Field
                AuthTextField(
                  controller: _emailController,
                  label: AppStrings.email,
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
                  text: 'Send Reset Link',
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
                  child: const Text(
                    'Back to Login',
                    style: TextStyle(
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
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
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
                          'The reset link will expire in 1 hour for security reasons.',
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
  }
}
