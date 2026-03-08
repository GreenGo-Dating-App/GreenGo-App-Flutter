import 'dart:ui' as ui;
import 'package:audioplayers/audioplayers.dart' hide Source;
import 'package:audioplayers/audioplayers.dart' as ap show Source, DeviceFileSource;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/chat_learning_service.dart';
import '../../../../core/services/pronunciation_service.dart';
import '../../../../features/coins/data/datasources/coin_remote_datasource.dart';
import '../../../../features/coins/domain/entities/coin_transaction.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../features/membership/domain/entities/membership.dart';
import '../../domain/entities/message.dart';

/// Message Bubble Widget
///
/// Displays a single chat message with translation support
/// Double-tap to toggle between translated and original text
/// Long-press for message options (reply, forward, star, report)
class MessageBubble extends StatefulWidget {
  final Message message;
  final bool isCurrentUser;
  final String? currentUserId;
  final String? otherUserLanguage;
  final bool showOriginalText;
  final bool showDifficultyBadge;
  final bool showCulturalTips;
  final bool showWordBreakdown;
  final bool showPronunciation;
  final bool showLanguageFlags;
  final bool ttsReadTranslated;
  final String? userSelectedLanguage;
  final bool otherUserIsMale;
  final bool currentUserIsMale;
  final Function(Message)? onReport;
  final Function(Message, bool)? onStar;
  final Function(Message)? onReply;
  final Function(Message)? onForward;
  final Function(Message)? onAlbumTap;
  final MembershipTier? userMembershipTier;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.currentUserId,
    this.otherUserLanguage,
    this.showOriginalText = true,
    this.showDifficultyBadge = true,
    this.showCulturalTips = true,
    this.showWordBreakdown = true,
    this.showPronunciation = true,
    this.showLanguageFlags = true,
    this.ttsReadTranslated = false,
    this.userSelectedLanguage,
    this.otherUserIsMale = true,
    this.currentUserIsMale = true,
    this.onReport,
    this.onStar,
    this.onReply,
    this.onForward,
    this.onAlbumTap,
    this.userMembershipTier,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _isStarred = false;
  bool _isTtsLoading = false;
  bool _isTtsPlaying = false;
  static final AudioPlayer _audioPlayer = AudioPlayer();

  // Learning enhancement state
  String? _difficultyLevel;
  String? _romanizedText;
  String? _culturalTooltip;
  bool _loadingDifficulty = false;
  bool _loadingRomanization = false;

  /// Get flag emoji for a language code
  static String _flagForLanguage(String? langCode) {
    if (langCode == null || langCode.isEmpty) return '';
    final code = langCode.toLowerCase().replaceAll('-', '_');
    const flags = {
      'en': '\u{1F1EC}\u{1F1E7}', // 🇬🇧
      'de': '\u{1F1E9}\u{1F1EA}', // 🇩🇪
      'es': '\u{1F1EA}\u{1F1F8}', // 🇪🇸
      'fr': '\u{1F1EB}\u{1F1F7}', // 🇫🇷
      'it': '\u{1F1EE}\u{1F1F9}', // 🇮🇹
      'pt': '\u{1F1F5}\u{1F1F9}', // 🇵🇹
      'pt_br': '\u{1F1E7}\u{1F1F7}', // 🇧🇷
    };
    return flags[code] ?? '\u{1F310}'; // 🌐 globe fallback
  }

  @override
  void initState() {
    super.initState();
    _isStarred = widget.message.metadata?['isStarred'] == true;
    if (!widget.isCurrentUser && widget.message.type == MessageType.text && (widget.showDifficultyBadge || widget.showCulturalTips)) {
      _loadEnhancements();
    }
  }

  Future<void> _loadEnhancements() async {
    final message = widget.message;
    final language = message.detectedLanguage ?? message.metadata?['language'] as String? ?? widget.otherUserLanguage ?? 'en';
    final service = ChatLearningService();

    // Load difficulty
    setState(() => _loadingDifficulty = true);
    try {
      final level = await service.getMessageDifficulty(message.content, language);
      if (mounted) setState(() { _difficultyLevel = level; _loadingDifficulty = false; });
    } catch (e) {
      if (mounted) setState(() => _loadingDifficulty = false);
    }

    // Load romanization
    setState(() => _loadingRomanization = true);
    try {
      final romanized = await service.getRomanization(message.content, language);
      if (mounted) setState(() { _romanizedText = romanized; _loadingRomanization = false; });
    } catch (e) {
      if (mounted) setState(() => _loadingRomanization = false);
    }

    // Load cultural tooltip
    try {
      final tooltip = await service.getCulturalTooltip(message.content, language);
      if (mounted) setState(() => _culturalTooltip = tooltip);
    } catch (e) {
      debugPrint('Cultural tooltip error: $e');
    }
  }

  Color _getDifficultyColor(String level) {
    switch (level) {
      case 'A1': return Colors.green;
      case 'A2': return Colors.lightGreen;
      case 'B1': return Colors.orange;
      case 'B2': return Colors.deepOrange;
      case 'C1': return Colors.red;
      case 'C2': return Colors.purple;
      default: return Colors.grey;
    }
  }

  void _showCulturalTooltip() {
    if (_culturalTooltip == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Row(
          children: [
            Icon(Icons.lightbulb, color: AppColors.richGold),
            SizedBox(width: 8),
            Text('Cultural Context', style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        content: Text(_culturalTooltip!, style: const TextStyle(color: AppColors.textSecondary)),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
  }

  void _showWordBreakdown() async {
    final tier = widget.userMembershipTier ?? MembershipTier.free;
    if (tier == MembershipTier.free) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Word breakdown is available for Silver, Gold, and Platinum members')),
        );
      }
      return;
    }
    final language = widget.message.detectedLanguage ?? widget.message.metadata?['language'] as String? ?? widget.otherUserLanguage ?? 'en';
    final words = await ChatLearningService().getWordBreakdown(
      widget.message.content,
      language,
      'en', // Target language for translations
    );
    if (words.isEmpty || !mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Word Breakdown', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: words.map((w) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.backgroundDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(w['word'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                    Text(w['translation'] ?? '', style: const TextStyle(color: AppColors.richGold, fontSize: 12)),
                    Text(w['pos'] ?? '', style: const TextStyle(color: AppColors.textTertiary, fontSize: 10, fontStyle: FontStyle.italic)),
                  ],
                ),
              )).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Map language codes to TTS locale codes
  static String _ttsLocale(String lang) {
    final code = lang.toLowerCase().replaceAll('-', '_');
    const localeMap = {
      'en': 'en-US',
      'it': 'it-IT',
      'es': 'es-ES',
      'fr': 'fr-FR',
      'de': 'de-DE',
      'pt': 'pt-PT',
      'pt_br': 'pt-BR',
    };
    return localeMap[code] ?? 'en-US';
  }

  /// Play TTS for the message text on double-tap.
  /// Uses Google Cloud TTS (Chirp 3 HD) for human-like speech.
  /// The sender's gender determines the voice (male sender = male voice).
  /// Each listen costs 5 coins.
  Future<void> _playTts() async {
    final message = widget.message;
    if (message.type != MessageType.text) return;

    // If already playing, stop
    if (_isTtsPlaying) {
      await _audioPlayer.stop();
      if (mounted) setState(() => _isTtsPlaying = false);
      return;
    }

    // Choose text and language based on TTS setting
    final String text;
    final String lang;
    if (widget.ttsReadTranslated && message.translatedContent != null && message.translatedContent!.isNotEmpty) {
      text = message.translatedContent!;
      lang = widget.userSelectedLanguage ?? widget.otherUserLanguage ?? 'en';
    } else {
      text = message.content;
      lang = message.detectedLanguage
          ?? message.metadata?['language'] as String?
          ?? widget.otherUserLanguage
          ?? 'en';
    }
    if (text.isEmpty) return;

    // Deduct 5 coins before playing
    final userId = widget.currentUserId;
    if (userId == null) return;

    try {
      final coinDs = di.sl<CoinRemoteDataSource>();
      final balance = await coinDs.getBalance(userId);
      if (balance.totalCoins < 5) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Not enough coins for TTS (5 coins required)')),
          );
        }
        return;
      }
      await coinDs.updateBalance(
        userId: userId,
        amount: 5,
        type: CoinTransactionType.debit,
        reason: CoinTransactionReason.featurePurchase,
        metadata: {'feature': 'tts_listen', 'messageId': message.messageId},
      );
      debugPrint('TTS: Deducted 5 coins from $userId');
    } catch (e) {
      debugPrint('TTS: Coin deduction failed: $e');
      // Allow playback even if coin deduction fails (e.g. emulator issues)
    }

    // Sender's gender determines the voice
    final bool senderIsMale = widget.isCurrentUser
        ? widget.currentUserIsMale
        : widget.otherUserIsMale;

    setState(() => _isTtsLoading = true);

    try {
      final filePath = await PronunciationService().getPronunciationFilePath(
        text, lang, isMale: senderIsMale,
      );
      if (filePath != null && mounted) {
        debugPrint('TTS: Playing Cloud TTS audio (${senderIsMale ? "male" : "female"} voice) from $filePath');
        setState(() { _isTtsLoading = false; _isTtsPlaying = true; });

        _audioPlayer.onPlayerComplete.first.then((_) {
          if (mounted) setState(() => _isTtsPlaying = false);
        });

        await _audioPlayer.setVolume(1.0);
        await _audioPlayer.play(ap.DeviceFileSource(filePath));
      } else {
        debugPrint('TTS: Cloud TTS failed after 3 retries');
        if (mounted) setState(() => _isTtsLoading = false);
      }
    } catch (e) {
      debugPrint('TTS: Playback error: $e');
      if (mounted) setState(() { _isTtsLoading = false; _isTtsPlaying = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final isCurrentUser = widget.isCurrentUser;
    final hasTranslation = message.translatedContent != null &&
        message.translatedContent!.isNotEmpty &&
        message.translatedContent != message.content;

    // Album share/revoke messages are center-aligned like system messages
    if (message.type == MessageType.albumShare || message.type == MessageType.albumRevoke) {
      return _buildAlbumMessage(context, message, isCurrentUser);
    }

    return GestureDetector(
      onTap: (!isCurrentUser && message.type == MessageType.text && widget.showWordBreakdown) ? _showWordBreakdown : null,
      onDoubleTap: (message.type == MessageType.text && widget.showPronunciation) ? _playTts : null,
      onLongPress: () => _showMessageOptions(context),
      child: Align(
        alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: isCurrentUser
                ? AppColors.richGold
                : AppColors.backgroundCard,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(AppDimensions.radiusM),
              topRight: const Radius.circular(AppDimensions.radiusM),
              bottomLeft: Radius.circular(
                  isCurrentUser ? AppDimensions.radiusM : AppDimensions.radiusS),
              bottomRight: Radius.circular(
                  isCurrentUser ? AppDimensions.radiusS : AppDimensions.radiusM),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reply indicator if this is a reply
              if (message.metadata?['replyToMessageId'] != null)
                _buildReplyIndicator(),

              // Message content
              _buildMessageContent(),

              const SizedBox(height: 4),

              // TTS, translation indicator, star, and time
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // TTS indicator
                  if (_isTtsLoading) ...[
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: isCurrentUser
                            ? AppColors.deepBlack.withOpacity(0.6)
                            : AppColors.richGold,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ] else if (_isTtsPlaying) ...[
                    Icon(
                      Icons.volume_up,
                      size: 14,
                      color: isCurrentUser
                          ? AppColors.deepBlack.withOpacity(0.6)
                          : AppColors.richGold,
                    ),
                    const SizedBox(width: 4),
                  ],
                  // Star indicator
                  if (_isStarred) ...[
                    Icon(
                      Icons.star,
                      size: 12,
                      color: isCurrentUser
                          ? AppColors.deepBlack.withOpacity(0.6)
                          : AppColors.richGold,
                    ),
                    const SizedBox(width: 4),
                  ],
                  // Difficulty badge (CEFR level)
                  if (_difficultyLevel != null && widget.showDifficultyBadge) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: _getDifficultyColor(_difficultyLevel!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _difficultyLevel!,
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  // Show translation indicator if message is translated
                  if (hasTranslation) ...[
                    Icon(
                      Icons.translate,
                      size: 12,
                      color: isCurrentUser
                          ? AppColors.deepBlack.withOpacity(0.6)
                          : AppColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    message.timeText,
                    style: TextStyle(
                      color: isCurrentUser
                          ? AppColors.deepBlack.withOpacity(0.6)
                          : AppColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                  if (isCurrentUser) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message.status == MessageStatus.sending
                          ? Icons.access_time
                          : message.isRead
                              ? Icons.done_all
                              : Icons.done,
                      size: 14,
                      color: message.status == MessageStatus.sending
                          ? AppColors.deepBlack.withOpacity(0.4)
                          : message.isRead
                              ? AppColors.successGreen
                              : AppColors.deepBlack.withOpacity(0.6),
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

  Widget _buildAlbumMessage(BuildContext context, Message message, bool isCurrentUser) {
    final l10n = AppLocalizations.of(context)!;
    final isShare = message.type == MessageType.albumShare;
    final albumOwnerName = message.metadata?['albumOwnerName'] as String? ?? l10n.chatSomeone;

    // Determine display text
    String displayText;
    if (isShare) {
      displayText = isCurrentUser
          ? l10n.chatYouSharedAlbum
          : l10n.chatOtherSharedAlbum(albumOwnerName);
    } else {
      displayText = isCurrentUser
          ? l10n.chatYouRevokedAlbum
          : l10n.chatOtherRevokedAlbum(albumOwnerName);
    }

    // albumShare is tappable for the receiver; albumRevoke is never tappable
    final bool isTappable = isShare && !isCurrentUser;

    return GestureDetector(
      onTap: isTappable ? () => widget.onAlbumTap?.call(message) : null,
      child: Align(
        alignment: Alignment.center,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 32),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard.withOpacity(0.7),
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: isShare && isTappable
                ? Border.all(color: AppColors.richGold.withOpacity(0.3), width: 1)
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.photo_album,
                size: 28,
                color: isShare
                    ? AppColors.richGold
                    : AppColors.textTertiary,
              ),
              const SizedBox(height: 6),
              Text(
                displayText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isShare ? AppColors.textPrimary : AppColors.textSecondary,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
              if (isTappable) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.chatTapToViewAlbum,
                  style: TextStyle(
                    color: AppColors.richGold.withOpacity(0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                message.timeText,
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReplyIndicator() {
    final l10n = AppLocalizations.of(context)!;
    final isCurrentUser = widget.isCurrentUser;
    final replyContent = widget.message.metadata?['replyContent'] as String? ?? l10n.chatMessage;
    final isMediaUrl = replyContent.contains('firebasestorage.googleapis.com') ||
        replyContent.startsWith('https://') && (replyContent.contains('/chat_images/') || replyContent.contains('/chat_videos/'));

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppColors.deepBlack.withOpacity(0.1)
            : AppColors.backgroundDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border(
          left: BorderSide(
            color: isCurrentUser ? AppColors.deepBlack.withOpacity(0.3) : AppColors.richGold,
            width: 3,
          ),
        ),
      ),
      child: isMediaUrl
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Image.network(
                        replyContent,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.image, color: Colors.white54, size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  replyContent.contains('/chat_videos/') ? Icons.videocam : Icons.photo,
                  color: isCurrentUser
                      ? AppColors.deepBlack.withOpacity(0.5)
                      : AppColors.textSecondary,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  replyContent.contains('/chat_videos/') ? l10n.chatVideo : l10n.chatPhoto,
                  style: TextStyle(
                    color: isCurrentUser
                        ? AppColors.deepBlack.withOpacity(0.7)
                        : AppColors.textSecondary,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            )
          : Text(
              replyContent.length > 50 ? '${replyContent.substring(0, 50)}...' : replyContent,
              style: TextStyle(
                color: isCurrentUser
                    ? AppColors.deepBlack.withOpacity(0.7)
                    : AppColors.textSecondary,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
    );
  }

  void _toggleStar() {
    setState(() {
      _isStarred = !_isStarred;
    });
    widget.onStar?.call(widget.message, _isStarred);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isStarred ? AppLocalizations.of(context)!.chatMessageStarred : AppLocalizations.of(context)!.chatMessageUnstarred),
        duration: const Duration(seconds: 1),
        backgroundColor: AppColors.backgroundCard,
      ),
    );
  }

  Widget _buildMessageContent() {
    final l10n = AppLocalizations.of(context)!;
    final message = widget.message;
    final isCurrentUser = widget.isCurrentUser;
    final hasTranslation = message.translatedContent != null &&
        message.translatedContent!.isNotEmpty &&
        message.translatedContent != message.content;

    switch (message.type) {
      case MessageType.text:
        // Determine flags for translated and original languages
        final translatedFlag = widget.showLanguageFlags && hasTranslation
            ? _flagForLanguage(widget.userSelectedLanguage ?? widget.otherUserLanguage)
            : '';
        final originalLang = message.detectedLanguage ??
            message.metadata?['language'] as String? ??
            widget.otherUserLanguage;
        final originalFlag = widget.showLanguageFlags && hasTranslation
            ? _flagForLanguage(originalLang)
            : '';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Translated text as the main readable message
            if (hasTranslation && widget.showLanguageFlags) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(translatedFlag, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      message.translatedContent!,
                      style: TextStyle(
                        color: isCurrentUser ? AppColors.deepBlack : AppColors.textPrimary,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                hasTranslation ? message.translatedContent! : message.content,
                style: TextStyle(
                  color: isCurrentUser ? AppColors.deepBlack : AppColors.textPrimary,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ],
            // Original text shown underneath for learning
            if (hasTranslation && widget.showOriginalText) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: isCurrentUser
                      ? AppColors.deepBlack.withValues(alpha: 0.08)
                      : AppColors.backgroundDark.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.showLanguageFlags) ...[
                      Text(originalFlag, style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 5),
                    ],
                    Expanded(
                      child: Text(
                        message.content,
                        style: TextStyle(
                          color: isCurrentUser
                              ? AppColors.deepBlack.withValues(alpha: 0.7)
                              : AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.3,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Romanized text for non-Latin scripts
            if (_romanizedText != null && !isCurrentUser) ...[
              const SizedBox(height: 4),
              Text(
                _romanizedText!,
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  height: 1.3,
                ),
              ),
            ],
            // Cultural tooltip icon
            if (_culturalTooltip != null && !isCurrentUser && widget.showCulturalTips) ...[
              const SizedBox(height: 4),
              GestureDetector(
                onTap: _showCulturalTooltip,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('\u{1F4A1}', style: TextStyle(fontSize: 14)),
                    SizedBox(width: 4),
                    Text(
                      'Cultural context',
                      style: TextStyle(
                        color: AppColors.richGold,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );

      case MessageType.image:
        return Column(
          children: [
            GestureDetector(
              onTap: () => _openFullScreenImage(context, message.content),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Blurred thumbnail
                      ImageFiltered(
                        imageFilter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Image.network(
                          message.content,
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                          cacheWidth: 200,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: AppColors.backgroundDark,
                            child: const Icon(
                              Icons.broken_image,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                      ),
                      // Semi-transparent overlay + tap icon
                      Container(
                        color: Colors.black.withOpacity(0.2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.visibility, color: Colors.white70, size: 32),
                            const SizedBox(height: 6),
                            Text(
                              l10n.chatTapToView,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (message.metadata?['caption'] != null) ...[
              const SizedBox(height: 8),
              Text(
                message.metadata!['caption'] as String,
                style: TextStyle(
                  color: isCurrentUser
                      ? AppColors.deepBlack
                      : AppColors.textPrimary,
                  fontSize: 15,
                ),
              ),
            ],
          ],
        );

      case MessageType.video:
        return Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              child: GestureDetector(
                onTap: () => _openVideoPlayer(context, message.content),
                child: Container(
                  width: 200,
                  height: 200,
                  color: AppColors.backgroundDark,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.videocam,
                        color: AppColors.textTertiary,
                        size: 48,
                      ),
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (message.metadata?['caption'] != null) ...[
              const SizedBox(height: 8),
              Text(
                message.metadata!['caption'] as String,
                style: TextStyle(
                  color: isCurrentUser
                      ? AppColors.deepBlack
                      : AppColors.textPrimary,
                  fontSize: 15,
                ),
              ),
            ],
          ],
        );

      case MessageType.system:
        return Text(
          message.content,
          style: TextStyle(
            color: AppColors.textTertiary,
            fontSize: 13,
            fontStyle: FontStyle.italic,
          ),
        );

      default:
        return Text(
          message.content,
          style: TextStyle(
            color: isCurrentUser ? AppColors.deepBlack : AppColors.textPrimary,
            fontSize: 15,
          ),
        );
    }
  }

  void _openVideoPlayer(BuildContext context, String videoUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullScreenVideoPlayer(videoUrl: videoUrl),
      ),
    );
  }

  void _showMessageOptions(BuildContext context) {
    final message = widget.message;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.chatMessageOptions,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.reply, color: Colors.blue),
              title: Text(
                AppLocalizations.of(context)!.chatReply,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              subtitle: Text(
                AppLocalizations.of(context)!.chatReplyToMessage,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                widget.onReply?.call(message);
              },
            ),
            // Hide forward for private album images (non-chat uploaded images)
            if (!(message.type == MessageType.image &&
                !message.content.contains('/chat_images/')))
              ListTile(
                leading: const Icon(Icons.forward, color: Colors.purple),
                title: Text(
                  AppLocalizations.of(context)!.chatForward,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                subtitle: Text(
                  AppLocalizations.of(context)!.chatForwardToChat,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  widget.onForward?.call(message);
                },
              ),
            ListTile(
              leading: Icon(
                _isStarred ? Icons.star : Icons.star_border,
                color: AppColors.richGold,
              ),
              title: Text(
                _isStarred ? AppLocalizations.of(context)!.chatUnstarMessage : AppLocalizations.of(context)!.chatStarMessage,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              subtitle: Text(
                _isStarred ? AppLocalizations.of(context)!.chatRemoveFromStarred : AppLocalizations.of(context)!.chatAddToStarred,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _toggleStar();
              },
            ),
            if (!widget.isCurrentUser) ...[
              const Divider(color: AppColors.divider, height: 1),
              ListTile(
                leading: const Icon(Icons.flag, color: AppColors.errorRed),
                title: Text(
                  AppLocalizations.of(context)!.chatReportMessage,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                subtitle: Text(
                  AppLocalizations.of(context)!.chatReportInappropriate,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _showReportDialog(context);
                },
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reasons = [
      l10n.chatReportReasonHarassment,
      l10n.chatReportReasonSpam,
      l10n.chatReportReasonInappropriate,
      l10n.chatReportReasonPersonalInfo,
      l10n.chatReportReasonThreatening,
      l10n.chatReportReasonOther,
    ];

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(
          l10n.chatReportMessage,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.chatWhyReportMessage,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ...reasons.map((reason) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                reason,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              ),
              onTap: () {
                Navigator.pop(dialogContext);
                _submitReport(context, reason);
              },
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReport(BuildContext context, String reason) async {
    // Call the onReport callback if provided
    if (widget.onReport != null) {
      widget.onReport!(widget.message);
    }

    // Show a confirmation
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.chatMessageReported),
          backgroundColor: AppColors.richGold,
        ),
      );
    }
  }

  void _openFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.richGold),
                  );
                },
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(Icons.broken_image, color: Colors.white54, size: 64),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-screen video player widget
class _FullScreenVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const _FullScreenVideoPlayer({required this.videoUrl});

  @override
  State<_FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<_FullScreenVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _isInitialized = true);
          _controller.play();
        }
      }).catchError((e) {
        if (mounted) setState(() => _hasError = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: _hasError
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.white54, size: 48),
                  const SizedBox(height: 12),
                  Text(AppLocalizations.of(context)!.chatFailedToLoadVideo,
                      style: const TextStyle(color: Colors.white70)),
                ],
              )
            : !_isInitialized
                ? const CircularProgressIndicator(color: AppColors.richGold)
                : GestureDetector(
                    onTap: () {
                      setState(() {
                        _controller.value.isPlaying
                            ? _controller.pause()
                            : _controller.play();
                      });
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        ),
                        if (!_controller.value.isPlaying)
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.play_arrow,
                                color: Colors.white, size: 40),
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
