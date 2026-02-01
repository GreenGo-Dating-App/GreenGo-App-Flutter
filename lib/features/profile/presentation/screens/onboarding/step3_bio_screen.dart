import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../bloc/onboarding_bloc.dart';
import '../../bloc/onboarding_event.dart';
import '../../bloc/onboarding_state.dart';
import '../../widgets/luxury_onboarding_layout.dart';
import '../../widgets/onboarding_progress_bar.dart';

class Step3BioScreen extends StatefulWidget {
  const Step3BioScreen({super.key});

  @override
  State<Step3BioScreen> createState() => _Step3BioScreenState();
}

class _Step3BioScreenState extends State<Step3BioScreen> {
  final _bioController = TextEditingController();
  final int _maxLength = 500;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final state = context.read<OnboardingBloc>().state;
    if (state is OnboardingInProgress && state.bio != null) {
      _bioController.text = state.bio!;
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleContinue() {
    final bio = _bioController.text.trim();
    if (bio.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please write something about yourself'),
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (bio.length < 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Bio must be at least 50 characters'),
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    context.read<OnboardingBloc>().add(OnboardingBioUpdated(bio: bio));
    context.read<OnboardingBloc>().add(const OnboardingNextStep());
  }

  void _handleBack() {
    final bio = _bioController.text.trim();
    if (bio.isNotEmpty) {
      context.read<OnboardingBloc>().add(OnboardingBioUpdated(bio: bio));
    }
    context.read<OnboardingBloc>().add(const OnboardingPreviousStep());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        if (state is! OnboardingInProgress) {
          return const SizedBox.shrink();
        }

        final charCount = _bioController.text.length;
        final isValidLength = charCount >= 50;

        return LuxuryOnboardingLayout(
          title: 'Express yourself',
          subtitle: 'Write something that captures who you are',
          onBack: _handleBack,
          progressBar: OnboardingProgressBar(
            currentStep: state.stepIndex,
            totalSteps: state.totalSteps,
          ),
          child: Column(
            children: [
              // Bio Text Field
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.1),
                              Colors.white.withOpacity(0.05),
                            ],
                          ),
                          border: Border.all(
                            color: _focusNode.hasFocus
                                ? AppColors.richGold.withOpacity(0.5)
                                : Colors.white.withOpacity(0.1),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _bioController,
                                focusNode: _focusNode,
                                maxLength: _maxLength,
                                maxLines: null,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  height: 1.6,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Tell us about your interests, hobbies, what you\'re looking for...',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.3),
                                    fontSize: 16,
                                  ),
                                  counterText: '',
                                  contentPadding: const EdgeInsets.all(20),
                                ),
                                onChanged: (value) {
                                  setState(() {});
                                },
                              ),
                            ),
                            // Character count bar
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: Colors.white.withOpacity(0.05),
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Progress indicator
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: (charCount / _maxLength).clamp(0, 1),
                                        backgroundColor: Colors.white.withOpacity(0.1),
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          isValidLength
                                              ? AppColors.richGold
                                              : Colors.white.withOpacity(0.3),
                                        ),
                                        minHeight: 4,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    '$charCount / $_maxLength',
                                    style: TextStyle(
                                      color: isValidLength
                                          ? AppColors.richGold
                                          : Colors.white.withOpacity(0.5),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
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
                ),
              ),

              const SizedBox(height: 20),

              // Tips
              LuxuryGlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.richGold.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: AppColors.richGold,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Writing tips',
                          style: TextStyle(
                            color: AppColors.richGold,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTip('Be authentic and genuine'),
                    _buildTip('Share your passions and hobbies'),
                    _buildTip('What makes you unique?'),
                    _buildTip('Keep it positive'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Continue Button
              LuxuryButton(
                text: 'Continue',
                onPressed: _handleContinue,
              ),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.richGold.withOpacity(0.5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
