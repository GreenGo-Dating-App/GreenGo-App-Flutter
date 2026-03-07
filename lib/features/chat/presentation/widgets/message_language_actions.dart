import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/translation_service.dart';
import '../../domain/entities/message.dart';

/// Message Language Actions Widget
///
/// A row of pill-shaped action buttons for language learning that appears
/// on received messages. Provides Translate, Learn This Phrase, and Listen
/// actions to help users learn languages through chat conversations.
///
/// Usage: Place below a MessageBubble for received (non-current-user) messages.
/// ```dart
/// MessageLanguageActions(
///   message: message,
///   currentUserId: userId,
///   userNativeLanguage: 'en',
///   onTranslated: (translation) { ... },
///   onInsertText: null, // not used here
/// )
/// ```
class MessageLanguageActions extends StatefulWidget {
  /// The message to provide actions for
  final Message message;

  /// Current user's ID (for Firestore writes)
  final String currentUserId;

  /// The user's native language code (e.g., 'en', 'it', 'es')
  final String? userNativeLanguage;

  /// Callback when translation completes, provides translated text
  final ValueChanged<String>? onTranslated;

  /// Optional: existing translation from cache (avoids re-translating)
  final String? existingTranslation;

  const MessageLanguageActions({
    super.key,
    required this.message,
    required this.currentUserId,
    this.userNativeLanguage,
    this.onTranslated,
    this.existingTranslation,
  });

  @override
  State<MessageLanguageActions> createState() => _MessageLanguageActionsState();
}

class _MessageLanguageActionsState extends State<MessageLanguageActions> {
  final TranslationService _translationService = TranslationService();

  bool _isTranslating = false;
  bool _isSavingFlashcard = false;
  String? _translatedText;

  @override
  void initState() {
    super.initState();
    _translatedText = widget.existingTranslation ?? widget.message.translatedContent;
  }

  /// Translate the message to the user's native language
  Future<void> _translateMessage() async {
    if (_isTranslating) return;
    if (widget.message.type != MessageType.text) return;

    final targetLanguage = widget.userNativeLanguage;
    if (targetLanguage == null) {
      _showSnackBar(AppLocalizations.of(context)!.chatSetNativeLanguage, isError: true);
      return;
    }

    setState(() => _isTranslating = true);

    try {
      final translated = await _translationService.translate(
        text: widget.message.content,
        sourceLanguage: 'auto',
        targetLanguage: targetLanguage,
      );

      if (mounted) {
        setState(() {
          _translatedText = translated;
          _isTranslating = false;
        });

        if (translated != widget.message.content) {
          widget.onTranslated?.call(translated);
          HapticFeedback.lightImpact();
        } else {
          _showSnackBar(AppLocalizations.of(context)!.chatAlreadyInYourLanguage);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTranslating = false);
        _showSnackBar(AppLocalizations.of(context)!.chatTranslationFailed, isError: true);
      }
    }
  }

  /// Save the message as a flashcard to the user's deck
  Future<void> _saveAsFlashcard() async {
    if (_isSavingFlashcard) return;
    if (widget.message.type != MessageType.text) return;

    setState(() => _isSavingFlashcard = true);

    try {
      final cardId = const Uuid().v4();
      final front = widget.message.content;
      final back = _translatedText ?? front;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId)
          .collection('flashcard_decks')
          .doc('chat_phrases')
          .collection('cards')
          .doc(cardId)
          .set({
        'cardId': cardId,
        'front': front,
        'back': back,
        'sourceMessageId': widget.message.messageId,
        'sourceConversationId': widget.message.conversationId,
        'createdAt': FieldValue.serverTimestamp(),
        'reviewCount': 0,
        'nextReviewAt': FieldValue.serverTimestamp(),
        'difficulty': 'new',
      });

      // Ensure the parent deck document exists with metadata
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId)
          .collection('flashcard_decks')
          .doc('chat_phrases')
          .set({
        'deckName': 'Chat Phrases',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() => _isSavingFlashcard = false);
        HapticFeedback.mediumImpact();
        _showSnackBar(AppLocalizations.of(context)!.chatPhraseSaved);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSavingFlashcard = false);
        _showSnackBar(AppLocalizations.of(context)!.chatFailedToSaveFlashcard, isError: true);
      }
    }
  }

  /// Text-to-speech placeholder
  void _listenToPronunciation() {
    HapticFeedback.lightImpact();
    _showSnackBar(AppLocalizations.of(context)!.chatTtsComingSoon);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        ),
        backgroundColor: isError ? AppColors.errorRed : AppColors.backgroundCard,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Only show for text messages from other users
    if (widget.message.type != MessageType.text) {
      return const SizedBox.shrink();
    }
    if (widget.message.senderId == widget.currentUserId) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action buttons row
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _buildActionPill(
                icon: _isTranslating ? null : Icons.translate,
                label: _isTranslating
                    ? AppLocalizations.of(context)!.chatTranslating
                    : (_translatedText != null ? AppLocalizations.of(context)!.chatTranslated : AppLocalizations.of(context)!.chatTranslate),
                onTap: _translatedText != null ? null : _translateMessage,
                isLoading: _isTranslating,
                isCompleted: _translatedText != null,
              ),
              _buildActionPill(
                icon: _isSavingFlashcard ? null : Icons.school_outlined,
                label: _isSavingFlashcard ? AppLocalizations.of(context)!.chatSaving : AppLocalizations.of(context)!.chatLearnThis,
                onTap: _saveAsFlashcard,
                isLoading: _isSavingFlashcard,
              ),
              _buildActionPill(
                icon: Icons.volume_up_outlined,
                label: AppLocalizations.of(context)!.chatListen,
                onTap: _listenToPronunciation,
              ),
            ],
          ),

          // Show translation result inline
          if (_translatedText != null &&
              _translatedText != widget.message.content)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  border: Border.all(
                    color: AppColors.richGold.withValues(alpha: 0.2),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.translate,
                      size: 12,
                      color: AppColors.richGold,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _translatedText!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionPill({
    IconData? icon,
    required String label,
    VoidCallback? onTap,
    bool isLoading = false,
    bool isCompleted = false,
  }) {
    final isDisabled = onTap == null && !isLoading;
    final pillColor = isCompleted
        ? AppColors.successGreen.withValues(alpha: 0.15)
        : AppColors.backgroundCard;
    final textColor = isCompleted
        ? AppColors.successGreen
        : isDisabled
            ? AppColors.textTertiary
            : AppColors.textSecondary;
    final iconColor = isCompleted
        ? AppColors.successGreen
        : AppColors.richGold.withValues(alpha: 0.8);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: pillColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(
            color: isCompleted
                ? AppColors.successGreen.withValues(alpha: 0.3)
                : AppColors.divider,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: iconColor,
                ),
              )
            else if (icon != null)
              Icon(icon, size: 14, color: iconColor),
            if (icon != null || isLoading) const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
