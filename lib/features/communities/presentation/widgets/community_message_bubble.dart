import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/entities/community_message.dart';

/// Community Message Bubble Widget
///
/// Displays a message in the community group chat with sender info and special
/// styling for language tips, cultural facts, and city tips. Supports on-demand
/// translation into the viewer's language (like 1:1/group chat) and long-press
/// to report.
class CommunityMessageBubble extends StatefulWidget {
  const CommunityMessageBubble({
    required this.message,
    required this.isCurrentUser,
    super.key,
    this.showSenderInfo = true,
    this.currentUserLanguage = 'en',
    this.onReport,
  });

  final CommunityMessage message;
  final bool isCurrentUser;
  final bool showSenderInfo;

  /// The viewer's preferred language — target for on-demand translation.
  final String currentUserLanguage;

  /// Long-press action to report this message's author (null = not reportable).
  final VoidCallback? onReport;

  @override
  State<CommunityMessageBubble> createState() => _CommunityMessageBubbleState();
}

class _CommunityMessageBubbleState extends State<CommunityMessageBubble> {
  String? _translated;
  bool _translating = false;
  bool _showingTranslation = false;

  CommunityMessage get message => widget.message;
  bool get isCurrentUser => widget.isCurrentUser;
  bool get showSenderInfo => widget.showSenderInfo;

  String get _displayContent => _showingTranslation && _translated != null
      ? _translated!
      : message.content;

  Future<void> _toggleTranslate() async {
    if (_translated != null) {
      setState(() => _showingTranslation = !_showingTranslation);
      return;
    }
    setState(() => _translating = true);
    try {
      final result = await TranslationService().translate(
        text: message.content,
        sourceLanguage: 'auto',
        targetLanguage: widget.currentUserLanguage,
      );
      if (!mounted) return;
      setState(() {
        _translated = result;
        _showingTranslation = true;
        _translating = false;
      });
    } catch (_) {
      if (mounted) setState(() => _translating = false);
    }
  }

  Widget _translateAction({required Color color}) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: _translating ? null : _toggleTranslate,
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          _translating
              ? l10n.communitiesTranslating
              : (_showingTranslation
                  ? l10n.communitiesShowOriginal
                  : l10n.communitiesTranslate),
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (message.type == CommunityMessageType.system) {
      return _buildSystemMessage();
    }
    final child = message.isSpecialType
        ? _buildSpecialMessage(context)
        : _buildRegularMessage();
    if (widget.onReport == null) return child;
    return GestureDetector(onLongPress: widget.onReport, child: child);
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
            if (!isCurrentUser && showSenderInfo) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                    _displayContent,
                    style: TextStyle(
                      color: isCurrentUser
                          ? AppColors.deepBlack
                          : AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.timeText,
                        style: TextStyle(
                          color: isCurrentUser
                              ? AppColors.deepBlack.withValues(alpha: 0.6)
                              : AppColors.textTertiary,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _translateAction(
                        color: isCurrentUser
                            ? AppColors.deepBlack.withValues(alpha: 0.8)
                            : AppColors.richGold,
                      ),
                    ],
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
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: config.borderColor,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Colored accent stripe gives each tip type a stronger identity.
            Container(width: 4, color: config.iconColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(config.icon, color: config.iconColor, size: 18),
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
          Text(
            _displayContent,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _translateAction(color: config.iconColor),
                        const Spacer(),
                        Text(
                          message.timeText,
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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

  const _SpecialMessageConfig({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.label,
  });
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;
  final String label;
}
