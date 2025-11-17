import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../authentication/presentation/widgets/auth_text_field.dart';
import '../../bloc/onboarding_bloc.dart';
import '../../bloc/onboarding_event.dart';
import '../../bloc/onboarding_state.dart';
import '../../widgets/onboarding_button.dart';
import '../../widgets/onboarding_progress_bar.dart';

class Step1BasicInfoScreen extends StatefulWidget {
  const Step1BasicInfoScreen({super.key});

  @override
  State<Step1BasicInfoScreen> createState() => _Step1BasicInfoScreenState();
}

class _Step1BasicInfoScreenState extends State<Step1BasicInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedGender;

  final List<String> _genders = ['Male', 'Female', 'Non-binary', 'Other'];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.richGold,
              onPrimary: AppColors.deepBlack,
              surface: AppColors.backgroundCard,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _handleContinue() {
    if (_formKey.currentState!.validate() &&
        _selectedDate != null &&
        _selectedGender != null) {
      context.read<OnboardingBloc>().add(
            OnboardingBasicInfoUpdated(
              displayName: _nameController.text.trim(),
              dateOfBirth: _selectedDate!,
              gender: _selectedGender!,
            ),
          );
      context.read<OnboardingBloc>().add(const OnboardingNextStep());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all fields'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        if (state is! OnboardingInProgress) {
          return const SizedBox.shrink();
        }

        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: OnboardingProgressBar(
              currentStep: state.stepIndex,
              totalSteps: state.totalSteps,
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      'Let\'s start with the basics',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: AppColors.richGold,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tell us a bit about yourself',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 40),

                    // Name Field
                    AuthTextField(
                      controller: _nameController,
                      label: 'Display Name',
                      prefixIcon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        if (value.trim().length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Date of Birth
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: AbsorbPointer(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.backgroundInput,
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusM),
                            border: Border.all(
                              color: _selectedDate == null
                                  ? AppColors.divider
                                  : AppColors.richGold,
                              width: 1.5,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.cake_outlined,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedDate == null
                                      ? 'Date of Birth'
                                      : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                                  style: TextStyle(
                                    color: _selectedDate == null
                                        ? AppColors.textTertiary
                                        : AppColors.textPrimary,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.calendar_today,
                                color: AppColors.richGold,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_selectedDate == null)
                      Padding(
                        padding: const EdgeInsets.only(left: 16, top: 8),
                        child: Text(
                          'You must be 18 or older',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textTertiary,
                              ),
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Gender Selection
                    Text(
                      'Gender',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _genders.map((gender) {
                        final isSelected = _selectedGender == gender;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedGender = gender;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.richGold
                                  : AppColors.backgroundCard,
                              borderRadius:
                                  BorderRadius.circular(AppDimensions.radiusM),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.richGold
                                    : AppColors.divider,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              gender,
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.deepBlack
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 48),

                    // Continue Button
                    OnboardingButton(
                      text: 'Continue',
                      onPressed: _handleContinue,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
