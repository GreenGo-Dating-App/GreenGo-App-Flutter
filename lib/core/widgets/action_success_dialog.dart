import 'package:flutter/material.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    return _show(
      context,
      title: l10n.nicknameUpdatedTitle,
      message: l10n.nicknameUpdatedMessage,
      icon: Icons.badge,
    );
  }

  /// Show bio updated success dialog
  static Future<void> showBioUpdated(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _show(
      context,
      title: l10n.bioUpdatedTitle,
      message: l10n.bioUpdatedMessage,
      icon: Icons.edit_note,
    );
  }

  /// Show profile updated success dialog
  static Future<void> showProfileUpdated(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _show(
      context,
      title: l10n.profileUpdatedTitle,
      message: l10n.profileUpdatedMessage,
      icon: Icons.person,
    );
  }

  /// Show preferences saved success dialog
  static Future<void> showPreferencesSaved(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _show(
      context,
      title: l10n.preferencesSavedTitle,
      message: l10n.preferencesSavedMessage,
      icon: Icons.tune,
    );
  }

  /// Show image uploaded success dialog
  static Future<void> showImageUploaded(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _show(
      context,
      title: l10n.photoUploadedTitle,
      message: l10n.photoUploadedMessage,
      icon: Icons.photo_camera,
    );
  }

  /// Show basic info updated success dialog
  static Future<void> showBasicInfoUpdated(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _show(
      context,
      title: l10n.infoUpdatedTitle,
      message: l10n.infoUpdatedMessage,
      icon: Icons.info,
    );
  }

  /// Show interests updated success dialog
  static Future<void> showInterestsUpdated(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _show(
      context,
      title: l10n.interestsUpdatedTitle,
      message: l10n.interestsUpdatedMessage,
      icon: Icons.favorite,
    );
  }

  /// Show location updated success dialog
  static Future<void> showLocationUpdated(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _show(
      context,
      title: l10n.locationUpdatedTitle,
      message: l10n.locationUpdatedMessage,
      icon: Icons.location_on,
    );
  }

  /// Show voice recording success dialog
  static Future<void> showVoiceUpdated(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _show(
      context,
      title: l10n.voiceSavedTitle,
      message: l10n.voiceSavedMessage,
      icon: Icons.mic,
    );
  }

  /// Show social links updated success dialog
  static Future<void> showSocialLinksUpdated(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _show(
      context,
      title: l10n.socialLinksUpdatedTitle,
      message: l10n.socialLinksUpdatedMessage,
      icon: Icons.share,
    );
  }

  /// Show photos updated success dialog
  static Future<void> showPhotosUpdated(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _show(
      context,
      title: l10n.photosUpdatedTitle,
      message: l10n.photosUpdatedMessage,
      icon: Icons.photo_library,
    );
  }

  /// Show chat deleted for me success dialog
  static Future<void> showChatDeletedForMe(BuildContext context, {VoidCallback? onDismiss}) {
    final l10n = AppLocalizations.of(context)!;
    return _show(
      context,
      title: l10n.chatDeletedTitle,
      message: l10n.chatDeletedForMeMessage,
      icon: Icons.delete_outline,
      onDismiss: onDismiss,
    );
  }

  /// Show chat deleted for both success dialog
  static Future<void> showChatDeletedForBoth(BuildContext context, {VoidCallback? onDismiss}) {
    final l10n = AppLocalizations.of(context)!;
    return _show(
      context,
      title: l10n.chatDeletedTitle,
      message: l10n.chatDeletedForBothMessage,
      icon: Icons.delete_forever,
      onDismiss: onDismiss,
    );
  }

  /// Show user blocked success dialog
  static Future<void> showUserBlocked(BuildContext context, String displayName, {VoidCallback? onDismiss}) {
    final l10n = AppLocalizations.of(context)!;
    return _show(
      context,
      title: l10n.userBlockedTitle,
      message: l10n.userBlockedMessage(displayName),
      icon: Icons.block,
      onDismiss: onDismiss,
    );
  }

  /// Show user reported success dialog
  static Future<void> showUserReported(BuildContext context, {VoidCallback? onDismiss}) {
    final l10n = AppLocalizations.of(context)!;
    return _show(
      context,
      title: l10n.reportSubmittedTitle,
      message: l10n.reportSubmittedMessage,
      icon: Icons.flag,
      onDismiss: onDismiss,
    );
  }

  static Future<void> _show(
    BuildContext context, {
    required String title,
    required String message,
    IconData icon = Icons.check_circle,
    Duration autoDismiss = const Duration(seconds: 2),
    VoidCallback? onDismiss,
  }) async {
    // Wait a frame to ensure any previous dialog is fully dismissed
    await Future.delayed(const Duration(milliseconds: 150));
    if (!context.mounted) return;
    return showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (dialogContext) => ActionSuccessDialog(
        title: title,
        message: message,
        icon: icon,
        autoDismiss: autoDismiss,
        onDismiss: onDismiss,
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
        Navigator.of(context, rootNavigator: true).pop();
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
