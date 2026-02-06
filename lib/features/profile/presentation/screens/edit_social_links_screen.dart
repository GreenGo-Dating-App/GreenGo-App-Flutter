import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/action_success_dialog.dart';
import '../../domain/entities/profile.dart';
import '../../domain/entities/social_links.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

class EditSocialLinksScreen extends StatefulWidget {
  final Profile profile;

  const EditSocialLinksScreen({
    super.key,
    required this.profile,
  });

  @override
  State<EditSocialLinksScreen> createState() => _EditSocialLinksScreenState();
}

class _EditSocialLinksScreenState extends State<EditSocialLinksScreen> {
  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();
  final _tiktokController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _xController = TextEditingController();

  bool _hasChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Load existing social links
    if (widget.profile.socialLinks != null) {
      _facebookController.text = widget.profile.socialLinks!.facebook ?? '';
      _instagramController.text = widget.profile.socialLinks!.instagram ?? '';
      _tiktokController.text = widget.profile.socialLinks!.tiktok ?? '';
      _linkedinController.text = widget.profile.socialLinks!.linkedin ?? '';
      _xController.text = widget.profile.socialLinks!.x ?? '';
    }

    // Listen for changes
    _facebookController.addListener(_onFieldChanged);
    _instagramController.addListener(_onFieldChanged);
    _tiktokController.addListener(_onFieldChanged);
    _linkedinController.addListener(_onFieldChanged);
    _xController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    final currentLinks = _getCurrentLinks();
    final originalLinks = widget.profile.socialLinks;

    final hasChanges = currentLinks.facebook != originalLinks?.facebook ||
        currentLinks.instagram != originalLinks?.instagram ||
        currentLinks.tiktok != originalLinks?.tiktok ||
        currentLinks.linkedin != originalLinks?.linkedin ||
        currentLinks.x != originalLinks?.x;

    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  @override
  void dispose() {
    _facebookController.removeListener(_onFieldChanged);
    _instagramController.removeListener(_onFieldChanged);
    _tiktokController.removeListener(_onFieldChanged);
    _linkedinController.removeListener(_onFieldChanged);
    _xController.removeListener(_onFieldChanged);
    _facebookController.dispose();
    _instagramController.dispose();
    _tiktokController.dispose();
    _linkedinController.dispose();
    _xController.dispose();
    super.dispose();
  }

  SocialLinks _getCurrentLinks() {
    return SocialLinks(
      facebook: _facebookController.text.trim().isEmpty
          ? null
          : _facebookController.text.trim(),
      instagram: _instagramController.text.trim().isEmpty
          ? null
          : _instagramController.text.trim(),
      tiktok: _tiktokController.text.trim().isEmpty
          ? null
          : _tiktokController.text.trim(),
      linkedin: _linkedinController.text.trim().isEmpty
          ? null
          : _linkedinController.text.trim(),
      x: _xController.text.trim().isEmpty ? null : _xController.text.trim(),
    );
  }

  void _saveSocialLinks() {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    final socialLinks = _getCurrentLinks();

    final updatedProfile = widget.profile.copyWith(
      socialLinks: socialLinks,
      updatedAt: DateTime.now(),
    );

    context.read<ProfileBloc>().add(
          ProfileUpdateRequested(profile: updatedProfile),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) async {
          if (state is ProfileUpdated) {
            // Show success dialog instead of snackbar
            await ActionSuccessDialog.showSocialLinksUpdated(context);
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
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColors.backgroundDark,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon:
                    const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: const Text(
                'Social Profiles',
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
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.richGold),
                      ),
                    ),
                  )
                else
                  TextButton(
                    onPressed: _hasChanges ? _saveSocialLinks : null,
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
                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundCard,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusM),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.share,
                            color: Colors.blue,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Connect your social accounts',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Help others find you on social media',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Social Links Inputs
                  _buildSocialInput(
                    controller: _facebookController,
                    label: 'Facebook',
                    hint: 'Username or profile URL',
                    icon: Icons.facebook,
                    color: const Color(0xFF1877F2),
                  ),
                  _buildSocialInput(
                    controller: _instagramController,
                    label: 'Instagram',
                    hint: 'Username (without @)',
                    icon: Icons.camera_alt,
                    color: const Color(0xFFE4405F),
                  ),
                  _buildSocialInput(
                    controller: _tiktokController,
                    label: 'TikTok',
                    hint: 'Username (without @)',
                    icon: Icons.music_note,
                    color: AppColors.textPrimary,
                  ),
                  _buildSocialInput(
                    controller: _linkedinController,
                    label: 'LinkedIn',
                    hint: 'Username or profile URL',
                    icon: Icons.work,
                    color: const Color(0xFF0A66C2),
                  ),
                  _buildSocialInput(
                    controller: _xController,
                    label: 'X (Twitter)',
                    hint: 'Username (without @)',
                    icon: Icons.alternate_email,
                    color: AppColors.textPrimary,
                  ),

                  const SizedBox(height: 24),

                  // Tip Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.richGold.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusM),
                      border:
                          Border.all(color: AppColors.richGold.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.tips_and_updates,
                          color: AppColors.richGold,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your social profiles will be visible on your dating profile and help others verify your identity.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
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
      );
  }

  Widget _buildSocialInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textTertiary),
          filled: true,
          fillColor: AppColors.backgroundCard,
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
            borderSide: BorderSide(color: color, width: 2),
          ),
          prefixIcon: Icon(icon, color: color),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
