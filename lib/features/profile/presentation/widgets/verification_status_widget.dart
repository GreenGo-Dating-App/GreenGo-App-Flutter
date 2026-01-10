import 'package:flutter/material.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/profile.dart';

/// A widget that displays the current verification status
class VerificationStatusBanner extends StatelessWidget {
  final VerificationStatus status;
  final String? rejectionReason;
  final VoidCallback? onVerifyNow;

  const VerificationStatusBanner({
    super.key,
    required this.status,
    this.rejectionReason,
    this.onVerifyNow,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Don't show banner if approved
    if (status == VerificationStatus.approved) {
      return const SizedBox.shrink();
    }

    Color backgroundColor;
    Color textColor;
    IconData icon;
    String title;
    String message;

    switch (status) {
      case VerificationStatus.notSubmitted:
        backgroundColor = AppColors.richGold.withValues(alpha: 0.15);
        textColor = AppColors.richGold;
        icon = Icons.verified_user_outlined;
        title = l10n.verificationRequired;
        message = l10n.verificationDescription;
        break;
      case VerificationStatus.pending:
        backgroundColor = Colors.blue.withValues(alpha: 0.15);
        textColor = Colors.blue;
        icon = Icons.hourglass_top;
        title = l10n.verificationPending;
        message = l10n.verificationPendingMessage;
        break;
      case VerificationStatus.rejected:
        backgroundColor = AppColors.errorRed.withValues(alpha: 0.15);
        textColor = AppColors.errorRed;
        icon = Icons.error_outline;
        title = l10n.verificationRejected;
        message = rejectionReason != null
            ? l10n.rejectionReason(rejectionReason!)
            : l10n.verificationRejectedMessage;
        break;
      case VerificationStatus.needsResubmission:
        backgroundColor = AppColors.richGold.withValues(alpha: 0.15);
        textColor = AppColors.richGold;
        icon = Icons.camera_alt_outlined;
        title = l10n.verificationNeedsResubmission;
        message = rejectionReason != null
            ? l10n.rejectionReason(rejectionReason!)
            : l10n.verificationNeedsResubmissionMessage;
        break;
      case VerificationStatus.approved:
        return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: textColor, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
          if (status == VerificationStatus.notSubmitted ||
              status == VerificationStatus.rejected ||
              status == VerificationStatus.needsResubmission) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onVerifyNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: textColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(l10n.verifyNow),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// An overlay that blocks access to content for unverified users
class VerificationBlockedOverlay extends StatelessWidget {
  final VerificationStatus status;
  final String? rejectionReason;
  final VoidCallback? onVerifyNow;
  final Widget child;

  const VerificationBlockedOverlay({
    super.key,
    required this.status,
    this.rejectionReason,
    this.onVerifyNow,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // If verified, show the child directly
    if (status == VerificationStatus.approved) {
      return child;
    }

    final l10n = AppLocalizations.of(context)!;

    return Stack(
      children: [
        // Blurred/dimmed child content
        IgnorePointer(
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.7),
              BlendMode.darken,
            ),
            child: child,
          ),
        ),

        // Overlay with verification message
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(AppDimensions.paddingL),
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  border: Border.all(color: AppColors.richGold),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.richGold.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        status == VerificationStatus.pending
                            ? Icons.hourglass_top
                            : Icons.verified_user_outlined,
                        color: AppColors.richGold,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      status == VerificationStatus.pending
                          ? l10n.verificationPending
                          : l10n.accountUnderReview,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      status == VerificationStatus.pending
                          ? l10n.verificationPendingMessage
                          : l10n.cannotAccessFeature,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (rejectionReason != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.errorRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                        ),
                        child: Text(
                          l10n.rejectionReason(rejectionReason!),
                          style: const TextStyle(
                            color: AppColors.errorRed,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    if (status != VerificationStatus.pending &&
                        onVerifyNow != null) ...[
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: onVerifyNow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.richGold,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(l10n.verifyNow),
                        ),
                      ),
                    ],
                    if (status == VerificationStatus.pending) ...[
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: AppColors.richGold,
                              strokeWidth: 2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.waitingForVerification,
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A compact badge that shows verification status
class VerificationStatusBadge extends StatelessWidget {
  final VerificationStatus status;

  const VerificationStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (status) {
      case VerificationStatus.approved:
        icon = Icons.verified;
        color = AppColors.successGreen;
        break;
      case VerificationStatus.pending:
        icon = Icons.hourglass_top;
        color = Colors.blue;
        break;
      case VerificationStatus.rejected:
        icon = Icons.cancel;
        color = AppColors.errorRed;
        break;
      case VerificationStatus.needsResubmission:
        icon = Icons.refresh;
        color = AppColors.richGold;
        break;
      case VerificationStatus.notSubmitted:
        icon = Icons.warning;
        color = AppColors.richGold;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 16),
    );
  }
}
