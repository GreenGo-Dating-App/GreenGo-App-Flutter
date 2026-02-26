import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/action_success_dialog.dart';
import '../../domain/entities/profile.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../../../../core/utils/safe_navigation.dart';

class EditBioScreen extends StatefulWidget {
  final Profile profile;

  const EditBioScreen({
    super.key,
    required this.profile,
  });

  @override
  State<EditBioScreen> createState() => _EditBioScreenState();
}

class _EditBioScreenState extends State<EditBioScreen> {
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _educationController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _lookingForController = TextEditingController();
  final int _minLength = 50;
  final int _maxLength = 500;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _bioController.text = widget.profile.bio;
    _weightController.text = widget.profile.weight?.toString() ?? '';
    _heightController.text = widget.profile.height?.toString() ?? '';
    _educationController.text = widget.profile.education ?? '';
    _occupationController.text = widget.profile.occupation ?? '';
    _lookingForController.text = widget.profile.lookingFor ?? '';
  }

  @override
  void dispose() {
    _bioController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _educationController.dispose();
    _occupationController.dispose();
    _lookingForController.dispose();
    super.dispose();
  }

  bool get _isValid {
    final length = _bioController.text.trim().length;
    return length >= _minLength && length <= _maxLength;
  }

  void _save() {
    if (!_isValid || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    final weightText = _weightController.text.trim();
    final heightText = _heightController.text.trim();

    final updatedProfile = widget.profile.copyWith(
      bio: _bioController.text.trim(),
      weight: weightText.isNotEmpty ? int.tryParse(weightText) : null,
      height: heightText.isNotEmpty ? int.tryParse(heightText) : null,
      education: _educationController.text.trim().isNotEmpty
          ? _educationController.text.trim()
          : null,
      occupation: _occupationController.text.trim().isNotEmpty
          ? _occupationController.text.trim()
          : null,
      lookingFor: _lookingForController.text.trim().isNotEmpty
          ? _lookingForController.text.trim()
          : null,
      updatedAt: DateTime.now(),
    );

    context.read<ProfileBloc>().add(
          ProfileUpdateRequested(profile: updatedProfile),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) async {
        if (state is ProfileUpdated) {
          await ActionSuccessDialog.showBioUpdated(context);
          if (context.mounted) {
            Navigator.of(context).pop(state.profile);
          }
        } else if (state is ProfileError) {
          setState(() {
            _isSaving = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
      },
      child: Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => SafeNavigation.pop(context),
        ),
        title: const Text(
          'About Me',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.richGold),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _isValid ? _save : null,
              child: Text(
                'Save',
                style: TextStyle(
                  color: _isValid ? AppColors.richGold : AppColors.textTertiary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bio Tips
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: AppColors.richGold,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Tips for a great bio',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTip('Be authentic and genuine'),
                  _buildTip('Mention your hobbies and passions'),
                  _buildTip('Add a touch of humor'),
                  _buildTip('Keep it positive'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Bio Input
            TextField(
              controller: _bioController,
              maxLines: 8,
              maxLength: _maxLength,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: 'Tell people about yourself...',
                hintStyle: const TextStyle(color: AppColors.textTertiary),
                filled: true,
                fillColor: AppColors.backgroundInput,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  borderSide: const BorderSide(color: AppColors.richGold, width: 2),
                ),
                counterStyle: TextStyle(
                  color: _bioController.text.length < _minLength
                      ? AppColors.errorRed
                      : AppColors.textSecondary,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 8),

            // Character Count Info
            if (_bioController.text.trim().isNotEmpty &&
                _bioController.text.trim().length < _minLength)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  border: Border.all(color: AppColors.errorRed.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.errorRed,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bio must be at least $_minLength characters',
                        style: const TextStyle(
                          color: AppColors.errorRed,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Additional Details Section
            const Text(
              'Additional Details',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Optional — helps others get to know you',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),

            // Weight & Height Row
            Row(
              children: [
                Expanded(
                  child: _buildNumberField(
                    controller: _weightController,
                    label: 'Weight (kg)',
                    icon: Icons.fitness_center,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildNumberField(
                    controller: _heightController,
                    label: 'Height (cm)',
                    icon: Icons.height,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Education
            _buildTextField(
              controller: _educationController,
              label: 'Education',
              icon: Icons.school,
              hint: 'e.g. Bachelor in Computer Science',
            ),
            const SizedBox(height: 16),

            // Occupation
            _buildTextField(
              controller: _occupationController,
              label: 'Occupation',
              icon: Icons.work,
              hint: 'e.g. Software Engineer',
            ),
            const SizedBox(height: 16),

            // Looking For
            _buildTextField(
              controller: _lookingForController,
              label: 'Looking For',
              icon: Icons.favorite,
              hint: 'e.g. Long-term relationship',
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.richGold, size: 20),
        filled: true,
        fillColor: AppColors.backgroundInput,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: const BorderSide(color: AppColors.richGold, width: 2),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.richGold, size: 20),
        filled: true,
        fillColor: AppColors.backgroundInput,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: const BorderSide(color: AppColors.richGold, width: 2),
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: AppColors.successGreen,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
