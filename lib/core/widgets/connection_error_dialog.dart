import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../../generated/app_localizations.dart';

/// A graceful error dialog for connection and authentication errors
/// Shows a beautiful modal with icon, message, and retry option
class ConnectionErrorDialog extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final bool showRetryButton;

  const ConnectionErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.wifi_off,
    this.iconColor = AppColors.errorRed,
    this.onRetry,
    this.onDismiss,
    this.showRetryButton = true,
  });

  /// Show a network/connection error dialog
  static Future<void> showConnectionError(
    BuildContext context, {
    VoidCallback? onRetry,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) => ConnectionErrorDialog(
        title: l10n.connectionErrorTitle,
        message: l10n.connectionErrorMessage,
        icon: Icons.wifi_off,
        iconColor: AppColors.errorRed,
        onRetry: onRetry,
        showRetryButton: onRetry != null,
      ),
    );
  }

  /// Show an authentication error dialog
  static Future<void> showAuthError(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onRetry,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) => ConnectionErrorDialog(
        title: title,
        message: message,
        icon: Icons.error_outline,
        iconColor: AppColors.warningAmber,
        onRetry: onRetry,
        showRetryButton: onRetry != null,
      ),
    );
  }

  /// Show a server error dialog
  static Future<void> showServerError(
    BuildContext context, {
    VoidCallback? onRetry,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) => ConnectionErrorDialog(
        title: l10n.serverUnavailableTitle,
        message: l10n.serverUnavailableMessage,
        icon: Icons.cloud_off,
        iconColor: AppColors.warningAmber,
        onRetry: onRetry,
        showRetryButton: onRetry != null,
      ),
    );
  }

  /// Show a generic error dialog with custom message
  static Future<void> showError(
    BuildContext context, {
    required String title,
    required String message,
    IconData icon = Icons.warning_amber_rounded,
    VoidCallback? onRetry,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) => ConnectionErrorDialog(
        title: title,
        message: message,
        icon: icon,
        iconColor: AppColors.warningAmber,
        onRetry: onRetry,
        showRetryButton: onRetry != null,
      ),
    );
  }

  @override
  State<ConnectionErrorDialog> createState() => _ConnectionErrorDialogState();
}

class _ConnectionErrorDialogState extends State<ConnectionErrorDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _iconAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _iconAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1.0, curve: Curves.bounceOut),
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
              color: widget.iconColor.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.iconColor.withOpacity(0.15),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated icon
              ScaleTransition(
                scale: _iconAnimation,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.iconColor.withOpacity(0.15),
                    border: Border.all(
                      color: widget.iconColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.iconColor,
                    size: 44,
                  ),
                ),
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

              const SizedBox(height: 12),

              // Message
              Text(
                widget.message,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  // Dismiss button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onDismiss?.call();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.divider),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)?.dismiss ?? 'Dismiss',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  // Retry button (if enabled)
                  if (widget.showRetryButton) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onRetry?.call();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.richGold,
                          foregroundColor: AppColors.deepBlack,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          AppLocalizations.of(context)?.tryAgain ?? 'Try Again',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
