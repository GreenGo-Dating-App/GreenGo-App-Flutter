import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../profile/domain/entities/profile.dart';

/// Match Notification Dialog
///
/// Displays when a mutual match is created
class MatchNotification extends StatefulWidget {
  final Profile matchedProfile;
  final VoidCallback? onKeepSwiping;
  final VoidCallback? onSendMessage;

  const MatchNotification({
    super.key,
    required this.matchedProfile,
    this.onKeepSwiping,
    this.onSendMessage,
  });

  @override
  State<MatchNotification> createState() => _MatchNotificationState();
}

class _MatchNotificationState extends State<MatchNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.backgroundDark,
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              border: Border.all(color: AppColors.richGold, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Match icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.richGold.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: AppColors.richGold,
                    size: 60,
                  ),
                ),

                const SizedBox(height: 24),

                // Match text
                const Text(
                  "It's a Match!",
                  style: TextStyle(
                    color: AppColors.richGold,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                // Profile info
                Text(
                  'You and ${widget.matchedProfile.displayName} have liked each other!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 32),

                // Profile photo
                if (widget.matchedProfile.photoUrls.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    child: Image.network(
                      widget.matchedProfile.photoUrls.first,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholder(),
                    ),
                  )
                else
                  _buildPlaceholder(),

                const SizedBox(height: 24),

                // Action buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onSendMessage?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.richGold,
                      foregroundColor: AppColors.deepBlack,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusM),
                      ),
                    ),
                    child: const Text(
                      'Send Message',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onKeepSwiping?.call();
                  },
                  child: const Text(
                    'Keep Swiping',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: const Icon(
        Icons.person,
        size: 60,
        color: AppColors.textTertiary,
      ),
    );
  }
}

/// Helper function to show match notification
Future<void> showMatchNotification(
  BuildContext context, {
  required Profile matchedProfile,
  VoidCallback? onKeepSwiping,
  VoidCallback? onSendMessage,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => MatchNotification(
      matchedProfile: matchedProfile,
      onKeepSwiping: onKeepSwiping,
      onSendMessage: onSendMessage,
    ),
  );
}
