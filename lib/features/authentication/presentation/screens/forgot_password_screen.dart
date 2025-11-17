import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/validators.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
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

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleResetPassword() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            AuthPasswordResetRequested(_emailController.text.trim()),
          );
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
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.errorRed,
                ),
              );
            } else if (state is AuthPasswordResetSent) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password reset email sent! Check your inbox.'),
                  backgroundColor: AppColors.successGreen,
                  duration: Duration(seconds: 5),
                ),
              );
              // Return to login screen
              Navigator.of(context).pop();
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return SingleChildScrollView(
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
                      enabled: !isLoading,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _handleResetPassword(),
                    ),

                    const SizedBox(height: 32),

                    // Send Button
                    AuthButton(
                      text: 'Send Reset Link',
                      onPressed: isLoading ? null : _handleResetPassword,
                      isLoading: isLoading,
                      icon: Icons.send,
                    ),

                    const SizedBox(height: 16),

                    // Back to Login
                    TextButton(
                      onPressed: isLoading
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
            );
          },
        ),
      ),
    );
  }
}
