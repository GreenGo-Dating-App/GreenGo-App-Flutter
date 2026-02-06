import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Animated success dialog for profile actions
/// Shows a beautiful modal with checkmark animation
class ActionSuccessDialog extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final Duration autoDismiss;
  final VoidCallback? onDismiss;

  const ActionSuccessDialog({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.check_circle,
    this.autoDismiss = const Duration(seconds: 2),
    this.onDismiss,
  });

  /// Show nickname updated success dialog
  static Future<void> showNicknameUpdated(BuildContext context) {
    return _show(
      context,
      title: 'Nickname Updated!',
      message: 'Your new nickname is now active',
      icon: Icons.badge,
    );
  }

  /// Show bio updated success dialog
  static Future<void> showBioUpdated(BuildContext context) {
    return _show(
      context,
      title: 'Bio Updated!',
      message: 'Your profile bio has been saved',
      icon: Icons.edit_note,
    );
  }

  /// Show profile updated success dialog
  static Future<void> showProfileUpdated(BuildContext context) {
    return _show(
      context,
      title: 'Profile Updated!',
      message: 'Your changes have been saved',
      icon: Icons.person,
    );
  }

  /// Show preferences saved success dialog
  static Future<void> showPreferencesSaved(BuildContext context) {
    return _show(
      context,
      title: 'Preferences Saved!',
      message: 'Your discovery preferences have been updated',
      icon: Icons.tune,
    );
  }

  /// Show image uploaded success dialog
  static Future<void> showImageUploaded(BuildContext context) {
    return _show(
      context,
      title: 'Photo Uploaded!',
      message: 'Your photo has been added to your profile',
      icon: Icons.photo_camera,
    );
  }

  /// Show basic info updated success dialog
  static Future<void> showBasicInfoUpdated(BuildContext context) {
    return _show(
      context,
      title: 'Info Updated!',
      message: 'Your basic information has been saved',
      icon: Icons.info,
    );
  }

  /// Show interests updated success dialog
  static Future<void> showInterestsUpdated(BuildContext context) {
    return _show(
      context,
      title: 'Interests Updated!',
      message: 'Your interests have been saved',
      icon: Icons.favorite,
    );
  }

  /// Show location updated success dialog
  static Future<void> showLocationUpdated(BuildContext context) {
    return _show(
      context,
      title: 'Location Updated!',
      message: 'Your location settings have been saved',
      icon: Icons.location_on,
    );
  }

  /// Show voice recording success dialog
  static Future<void> showVoiceUpdated(BuildContext context) {
    return _show(
      context,
      title: 'Voice Saved!',
      message: 'Your voice introduction has been updated',
      icon: Icons.mic,
    );
  }

  /// Show social links updated success dialog
  static Future<void> showSocialLinksUpdated(BuildContext context) {
    return _show(
      context,
      title: 'Social Links Updated!',
      message: 'Your social profiles have been saved',
      icon: Icons.share,
    );
  }

  /// Show photos updated success dialog
  static Future<void> showPhotosUpdated(BuildContext context) {
    return _show(
      context,
      title: 'Photos Updated!',
      message: 'Your photo gallery has been saved',
      icon: Icons.photo_library,
    );
  }

  static Future<void> _show(
    BuildContext context, {
    required String title,
    required String message,
    IconData icon = Icons.check_circle,
    Duration autoDismiss = const Duration(seconds: 2),
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) => ActionSuccessDialog(
        title: title,
        message: message,
        icon: icon,
        autoDismiss: autoDismiss,
      ),
    );
  }

  @override
  State<ActionSuccessDialog> createState() => _ActionSuccessDialogState();
}

class _ActionSuccessDialogState extends State<ActionSuccessDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _checkController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _checkAnimation = CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeInOut,
    );

    _scaleController.forward().then((_) {
      _checkController.forward();
    });

    // Auto dismiss after specified duration
    Future.delayed(widget.autoDismiss, () {
      if (mounted) {
        Navigator.of(context).pop();
        widget.onDismiss?.call();
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.richGold.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.richGold.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated icon container
              AnimatedBuilder(
                animation: _checkAnimation,
                builder: (context, child) {
                  return Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.richGold,
                          AppColors.richGold.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.richGold
                              .withOpacity(0.4 * _checkAnimation.value),
                          blurRadius: 20 * _checkAnimation.value,
                          spreadRadius: 5 * _checkAnimation.value,
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.icon,
                      color: Colors.black,
                      size: 40 * _checkAnimation.value,
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Title
              Text(
                widget.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Message
              Text(
                widget.message,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // Progress indicator
              AnimatedBuilder(
                animation: _checkAnimation,
                builder: (context, child) {
                  return Container(
                    height: 4,
                    width: 100,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _checkAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.richGold, Color(0xFFFFD700)],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
