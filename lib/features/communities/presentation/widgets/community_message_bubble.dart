import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/ai_consent_service.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../generated/app_localizations.dart';
import '../../../chat/presentation/utils/chat_l10n.dart';
import '../../data/services/community_tip_translator.dart';
import '../../domain/entities/community_message.dart';
import '../../../chat/presentation/widgets/deleted_message_bubble.dart';
import '../../../../core/widgets/ai_consent_sheet.dart';

/// Community Message Bubble Widget
///
/// Displays a message in the community group chat with sender info and special
/// styling for language tips, cultural facts, and city tips. Tips written by
/// someone else are shown in the viewer's language AUTOMATICALLY (translated
/// once for everyone on the server, then cached on the device — see
/// [CommunityTipTranslator]) with a "Show original" toggle; chat messages keep
/// on-demand translation (like 1:1/group chat). Long-press to report.
///
/// Consent (Apple 5.1.2(i)): automatic tip translation sends the tip to
/// Google, so it runs only with the account's AI consent; the first tip asks
/// once ([AiConsentGate.allowAutoTranslate]). Without it the original is
/// shown with "Translate", which asks again.
class CommunityMessageBubble extends StatefulWidget {
  const CommunityMessageBubble({
    required this.message,
    required this.isCurrentUser,
    super.key,
    this.showSenderInfo = true,
    this.currentUserLanguage = 'en',
    this.onReport,
    this.onRemove,
    this.tipTranslator,
    this.aiConsent,
  });

  final CommunityMessage message;
  final bool isCurrentUser;
  final bool showSenderInfo;

  /// The viewer's preferred language — target for on-demand translation.
  final String currentUserLanguage;

  /// Long-press action to report this message's author (null = not reportable).
  final VoidCallback? onReport;

  /// Owner/moderator action to remove this post (Terms 17.3); null = the
  /// viewer may not remove it. When set, long-press opens an action sheet
  /// (Remove post + Report) instead of reporting directly.
  final VoidCallback? onRemove;

  /// Tip auto-translation; defaults to [CommunityTipTranslator.instance].
  final CommunityTipTranslator? tipTranslator;

  /// Consent source; defaults to [AiConsentService.instance] (tests inject).
  final AiConsentService? aiConsent;

  @override
  State<CommunityMessageBubble> createState() => _CommunityMessageBubbleState();
}

class _CommunityMessageBubbleState extends State<CommunityMessageBubble> {
  String? _translated;
  bool _translating = false;
  bool _showingTranslation = false;
  bool _failed = false;

  // Tips: automatic translation into the viewer's language.
  TipTranslation? _tipTr;
  bool _tipLoading = false;
  bool _tipShowOriginal = false;

  /// A tip waiting for the account's AI consent: shown in the original.
  bool _tipAwaitingConsent = false;

  AiConsentService get _consent => widget.aiConsent ?? AiConsentService.instance;

  /// Synchronous consent check; false when it cannot be read (no Firebase).
  bool _grantedNow() {
    try {
      return _consent.isGranted;
    } catch (_) {
      return false;
    }
  }

  CommunityMessage get message => widget.message;
  bool get isCurrentUser => widget.isCurrentUser;
  bool get showSenderInfo => widget.showSenderInfo;

  CommunityTipTranslator get _tipTranslator =>
      widget.tipTranslator ?? CommunityTipTranslator.instance;

  /// Tips by someone else are translated automatically.
  bool get _autoTranslates => message.isTip && !isCurrentUser;

  /// A tip translation that differs from the original is available.
  bool get _hasTipTranslation => _tipTr != null && !_tipTr!.sameLanguage;

  String get _displayContent {
    if (_hasTipTranslation) {
      return _tipShowOriginal ? message.content : _tipTr!.text;
    }
    return _showingTranslation && _translated != null
        ? _translated!
        : message.content;
  }

  @override
  void initState() {
    super.initState();
    try {
      _consent.statusListenable.addListener(_onConsentChanged);
    } catch (_) {}
    _startTipTranslation();
  }

  @override
  void dispose() {
    try {
      _consent.statusListenable.removeListener(_onConsentChanged);
    } catch (_) {}
    super.dispose();
  }

  /// Accepted elsewhere (another bubble's sheet, Settings): translate now.
  void _onConsentChanged() {
    if (!mounted || !_tipAwaitingConsent || !_grantedNow()) return;
    setState(() => _tipAwaitingConsent = false);
    _fetchTip();
  }

  @override
  void didUpdateWidget(covariant CommunityMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.id != message.id ||
        oldWidget.message.content != message.content ||
        oldWidget.currentUserLanguage != widget.currentUserLanguage) {
      _tipTr = null;
      _tipLoading = false;
      _tipShowOriginal = false;
      _translated = null;
      _showingTranslation = false;
      _tipAwaitingConsent = false;
      _startTipTranslation();
    }
  }

  void _startTipTranslation() {
    if (!_autoTranslates) return;
    if (!_grantedNow()) {
      // Ask once per account (the sheet needs a laid-out context).
      _tipAwaitingConsent = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        bool ok;
        try {
          ok = await AiConsentGate.allowAutoTranslate(context, service: _consent);
        } catch (_) {
          ok = false;
        }
        if (!mounted || !_tipAwaitingConsent || !ok) return;
        setState(() => _tipAwaitingConsent = false);
        _fetchTip();
      });
      return;
    }
    final known = _tipTranslator.peek(message, widget.currentUserLanguage);
    if (known != null) {
      _tipTr = known;
      return;
    }
    _fetchTip(initial: true);
  }

  void _fetchTip({bool initial = false}) {
    final target = widget.currentUserLanguage;
    if (initial) {
      _tipLoading = true;
    } else {
      final known = _tipTranslator.peek(message, target);
      if (known != null) {
        setState(() => _tipTr = known);
        return;
      }
      setState(() => _tipLoading = true);
    }
    final forId = message.id;
    final forContent = message.content;
    _tipTranslator.translate(message, target).then((r) {
      if (!mounted ||
          message.id != forId ||
          message.content != forContent ||
          widget.currentUserLanguage != target) {
        return;
      }
      setState(() {
        _tipLoading = false;
        _tipTr = r;
      });
    });
  }

  Future<void> _toggleTranslate() async {
    if (_translated != null) {
      setState(() => _showingTranslation = !_showingTranslation);
      return;
    }
    // Translating someone else's message sends it to Google: AI consent.
    // Asked again after a decline (the tap is the user reconsidering).
    final tipWaiting = _tipAwaitingConsent;
    if (!await AiConsentGate.requestTranslation(context, service: _consent)) {
      return;
    }
    if (!mounted) return;
    if (tipWaiting) {
      // A tip: translated through the shared store, like the others (the
      // consent listener may already have started it).
      if (_tipAwaitingConsent) {
        setState(() => _tipAwaitingConsent = false);
        _fetchTip();
      }
      return;
    }
    setState(() {
      _translating = true;
      _failed = false;
    });
    final result = await TranslationService().translateDetailed(
      text: message.content,
      sourceLanguage: 'auto',
      targetLanguage: widget.currentUserLanguage,
    );
    if (!mounted) return;
    setState(() {
      _translating = false;
      _failed = result.failed;
      if (!result.failed) {
        _translated = result.text;
        _showingTranslation = true;
      }
    });
  }

  Widget _translateAction({required Color color}) {
    final l10n = AppLocalizations.of(context)!;
    if (_autoTranslates) {
      // Already in the viewer's language: nothing to toggle.
      if (_tipTr != null && _tipTr!.sameLanguage) return const SizedBox.shrink();
      if (_tipLoading) {
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            l10n.communitiesTranslating,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        );
      }
      if (_hasTipTranslation) {
        return GestureDetector(
          key: const ValueKey('community-tip-translation-toggle'),
          onTap: () => setState(() => _tipShowOriginal = !_tipShowOriginal),
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _tipShowOriginal
                  ? l10n.communitiesTranslate
                  : l10n.communitiesShowOriginal,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        );
      }
      // Not translated right now (offline / rate-limited): fall back to the
      // on-demand device translation below.
    }
    return GestureDetector(
      onTap: _translating ? null : _toggleTranslate,
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          _translating
              ? l10n.communitiesTranslating
              : _failed
                  ? l10n.translationFailedTapRetry
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
    if (isDeletedAuthorMessage(message.senderId)) {
      return const DeletedMessageBubble(compact: true);
    }
    if (message.type == CommunityMessageType.system) {
      return _buildSystemMessage();
    }
    final child = message.isSpecialType
        ? _buildSpecialMessage(context)
        : _buildRegularMessage();
    if (widget.onReport == null && widget.onRemove == null) return child;
    return GestureDetector(
      onLongPress: widget.onRemove == null ? widget.onReport : _showActions,
      child: child,
    );
  }

  /// Moderator long-press menu: Remove post, plus Report when reportable.
  Future<void> _showActions() async {
    final l10n = AppLocalizations.of(context)!;
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              key: const ValueKey('community-post-remove'),
              leading:
                  const Icon(Icons.delete_outline, color: AppColors.errorRed),
              title: Text(
                l10n.communitiesRemovePost,
                style: const TextStyle(color: AppColors.errorRed),
              ),
              onTap: () => Navigator.pop(sheetContext, 'remove'),
            ),
            if (widget.onReport != null)
              ListTile(
                key: const ValueKey('community-post-report'),
                leading: const Icon(Icons.flag_outlined,
                    color: AppColors.textSecondary),
                title: Text(
                  l10n.communitiesReportMember,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                onTap: () => Navigator.pop(sheetContext, 'report'),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'remove') widget.onRemove?.call();
    if (action == 'report') widget.onReport?.call();
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
                        ? CachedNetworkImageProvider(message.senderPhotoUrl!,
                            maxWidth: 48)
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
                        chatClockTime(context, message.sentAt),
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
                          chatClockTime(context, message.sentAt),
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
      case CommunityMessageType.otherTip:
        return _SpecialMessageConfig(
          icon: Icons.push_pin_outlined,
          iconColor: AppColors.infoBlue,
          backgroundColor: AppColors.infoBlue.withValues(alpha: 0.08),
          borderColor: AppColors.infoBlue.withValues(alpha: 0.3),
          label: l10n.communitiesOtherTipUpper,
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
