import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../bloc/onboarding_bloc.dart';
import '../../bloc/onboarding_event.dart';
import '../../bloc/onboarding_state.dart';
import '../../widgets/luxury_onboarding_layout.dart';
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

  final List<Map<String, dynamic>> _genders = [
    {'label': 'Male', 'icon': Icons.male},
    {'label': 'Female', 'icon': Icons.female},
    {'label': 'Non-binary', 'icon': Icons.transgender},
    {'label': 'Other', 'icon': Icons.more_horiz},
  ];

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
              onPrimary: Colors.black,
              surface: Color(0xFF1A1A1A),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF0D0D0D),
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
        SnackBar(
          content: const Text('Please complete all fields'),
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

        return LuxuryOnboardingLayout(
          title: "Let's get started",
          subtitle: 'Tell us a bit about yourself',
          showBackButton: true,
          onBack: () => Navigator.of(context).pop(),
          progressBar: OnboardingProgressBar(
            currentStep: state.stepIndex,
            totalSteps: state.totalSteps,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name Field
                  LuxuryTextField(
                    controller: _nameController,
                    label: 'Display Name',
                    hint: 'How should we call you?',
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

                  const SizedBox(height: 24),

                  // Date of Birth
                  _buildDatePicker(context),

                  const SizedBox(height: 32),

                  // Gender Selection
                  Text(
                    'I identify as',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _genders.map((gender) {
                      final isSelected = _selectedGender == gender['label'];
                      return LuxuryChip(
                        label: gender['label'],
                        icon: gender['icon'],
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            _selectedGender = gender['label'];
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 48),

                  // Continue Button
                  LuxuryButton(
                    text: 'Continue',
                    onPressed: _handleContinue,
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.08),
              Colors.white.withOpacity(0.03),
            ],
          ),
          border: Border.all(
            color: _selectedDate != null
                ? AppColors.richGold.withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
            width: _selectedDate != null ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Icon(
              Icons.cake_outlined,
              color: _selectedDate != null
                  ? AppColors.richGold
                  : Colors.white.withOpacity(0.5),
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date of Birth',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedDate == null
                        ? ''
                        : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: _selectedDate != null ? FontWeight.w500 : null,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.richGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.calendar_today,
                color: AppColors.richGold,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
