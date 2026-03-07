import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/entities/community_message.dart';

/// Community Message Bubble Widget
///
/// Displays a message in the community group chat with sender info,
/// special styling for language tips, cultural facts, and city tips
class CommunityMessageBubble extends StatelessWidget {
  final CommunityMessage message;
  final bool isCurrentUser;
  final bool showSenderInfo;

  const CommunityMessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.showSenderInfo = true,
  });

  @override
  Widget build(BuildContext context) {
    // System messages are centered
    if (message.type == CommunityMessageType.system) {
      return _buildSystemMessage();
    }

    // Special message types (language tip, cultural fact, city tip)
    if (message.isSpecialType) {
      return _buildSpecialMessage(context);
    }

    return _buildRegularMessage();
  }

  Widget _buildRegularMessage() {
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(
          vertical: 3,
          horizontal: AppDimensions.marginM,
        ),
        constraints: const BoxConstraints(maxWidth: 300),
        child: Column(
          crossAxisAlignment:
              isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Sender name + avatar (for other users)
            if (!isCurrentUser && showSenderInfo) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.backgroundInput,
                    backgroundImage: message.senderPhotoUrl != null
                        ? NetworkImage(message.senderPhotoUrl!)
                        : null,
                    child: message.senderPhotoUrl == null
                        ? Text(
                            message.senderName.isNotEmpty
                                ? message.senderName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    message.senderName,
                    style: const TextStyle(
                      color: AppColors.richGold,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],

            // Message bubble
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? AppColors.richGold
                    : AppColors.backgroundCard,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppDimensions.radiusM),
                  topRight: const Radius.circular(AppDimensions.radiusM),
                  bottomLeft: Radius.circular(
                    isCurrentUser
                        ? AppDimensions.radiusM
                        : AppDimensions.radiusS,
                  ),
                  bottomRight: Radius.circular(
                    isCurrentUser
                        ? AppDimensions.radiusS
                        : AppDimensions.radiusM,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isCurrentUser
                          ? AppColors.deepBlack
                          : AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.timeText,
                    style: TextStyle(
                      color: isCurrentUser
                          ? AppColors.deepBlack.withValues(alpha: 0.6)
                          : AppColors.textTertiary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialMessage(BuildContext context) {
    final config = _getSpecialMessageConfig(context);

    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: 6,
        horizontal: AppDimensions.marginM,
      ),
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: config.borderColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with icon + type label + sender
          Row(
            children: [
              Icon(
                config.icon,
                color: config.iconColor,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                config.label,
                style: TextStyle(
                  color: config.iconColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                message.senderName,
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Content
          Text(
            message.content,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),

          // Time
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              message.timeText,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemMessage() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.backgroundInput.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        ),
        child: Text(
          message.content,
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  _SpecialMessageConfig _getSpecialMessageConfig(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (message.type) {
      case CommunityMessageType.languageTip:
        return _SpecialMessageConfig(
          icon: Icons.lightbulb_outline,
          iconColor: AppColors.warningAmber,
          backgroundColor: AppColors.warningAmber.withValues(alpha: 0.08),
          borderColor: AppColors.warningAmber.withValues(alpha: 0.3),
          label: l10n.communitiesLanguageTipUpper,
        );
      case CommunityMessageType.culturalFact:
        return _SpecialMessageConfig(
          icon: Icons.auto_awesome,
          iconColor: AppColors.basePurple,
          backgroundColor: AppColors.basePurple.withValues(alpha: 0.08),
          borderColor: AppColors.basePurple.withValues(alpha: 0.3),
          label: l10n.communitiesCulturalFactUpper,
        );
      case CommunityMessageType.cityTip:
        return _SpecialMessageConfig(
          icon: Icons.location_on,
          iconColor: AppColors.successGreen,
          backgroundColor: AppColors.successGreen.withValues(alpha: 0.08),
          borderColor: AppColors.successGreen.withValues(alpha: 0.3),
          label: l10n.communitiesCityTipUpper,
        );
      default:
        return _SpecialMessageConfig(
          icon: Icons.info_outline,
          iconColor: AppColors.infoBlue,
          backgroundColor: AppColors.infoBlue.withValues(alpha: 0.08),
          borderColor: AppColors.infoBlue.withValues(alpha: 0.3),
          label: l10n.communitiesInfoUpper,
        );
    }
  }
}

class _SpecialMessageConfig {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;
  final String label;

  const _SpecialMessageConfig({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.label,
  });
}
