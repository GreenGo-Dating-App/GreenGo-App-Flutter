import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/action_success_dialog.dart';
import '../../domain/entities/profile.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../../../../core/utils/safe_navigation.dart';

class EditDetailsScreen extends StatefulWidget {
  final Profile profile;

  const EditDetailsScreen({
    super.key,
    required this.profile,
  });

  @override
  State<EditDetailsScreen> createState() => _EditDetailsScreenState();
}

class _EditDetailsScreenState extends State<EditDetailsScreen> {
  final TextEditingController _educationController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _lookingForController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _educationController.text = widget.profile.education ?? '';
    _occupationController.text = widget.profile.occupation ?? '';
    _heightController.text = widget.profile.height?.toString() ?? '';
    _lookingForController.text = widget.profile.lookingFor ?? '';
  }

  @override
  void dispose() {
    _educationController.dispose();
    _occupationController.dispose();
    _heightController.dispose();
    _lookingForController.dispose();
    super.dispose();
  }

  bool get _hasChanges {
    return _educationController.text.trim() != (widget.profile.education ?? '') ||
        _occupationController.text.trim() != (widget.profile.occupation ?? '') ||
        _heightController.text.trim() != (widget.profile.height?.toString() ?? '') ||
        _lookingForController.text.trim() != (widget.profile.lookingFor ?? '');
  }

  void _save() {
    if (!_hasChanges || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    final heightText = _heightController.text.trim();
    final height = heightText.isNotEmpty ? int.tryParse(heightText) : null;

    final updatedProfile = widget.profile.copyWith(
      education: _educationController.text.trim().isEmpty
          ? null
          : _educationController.text.trim(),
      occupation: _occupationController.text.trim().isEmpty
          ? null
          : _occupationController.text.trim(),
      height: height,
      lookingFor: _lookingForController.text.trim().isEmpty
          ? null
          : _lookingForController.text.trim(),
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
          await ActionSuccessDialog.showProfileUpdated(context);
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
            'Education & Occupation',
            style: TextStyle(color: AppColors.textPrimary),
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
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.richGold),
                  ),
                ),
              )
            else
              TextButton(
                onPressed: _hasChanges ? _save : null,
                child: Text(
                  'Save',
                  style: TextStyle(
                    color:
                        _hasChanges ? AppColors.richGold : AppColors.textTertiary,
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
              // Education
              _buildLabel('Education'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _educationController,
                hint: 'e.g., Bachelor in Computer Science',
                icon: Icons.school,
              ),

              const SizedBox(height: 24),

              // Occupation
              _buildLabel('Occupation'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _occupationController,
                hint: 'e.g., Software Engineer',
                icon: Icons.work,
              ),

              const SizedBox(height: 24),

              // Height
              _buildLabel('Height (cm)'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _heightController,
                hint: 'e.g., 175',
                icon: Icons.height,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 24),

              // Looking For
              _buildLabel('Looking For'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _lookingForController,
                hint: 'e.g., Serious relationship',
                icon: Icons.favorite_border,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textTertiary),
        prefixIcon: Icon(icon, color: AppColors.richGold),
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
      onChanged: (_) => setState(() {}),
    );
  }
}
