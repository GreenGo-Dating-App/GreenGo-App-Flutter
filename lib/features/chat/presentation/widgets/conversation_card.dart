import 'package:flutter/material.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../domain/entities/conversation.dart';

/// Conversation Card Widget
///
/// Displays a conversation in the list
class ConversationCard extends StatelessWidget {
  final Conversation conversation;
  final Profile? otherUserProfile;
  final String currentUserId;
  final String? chatLanguage; // The language set for this chat (null = user default)
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ConversationCard({
    super.key,
    required this.conversation,
    required this.otherUserProfile,
    required this.currentUserId,
    this.chatLanguage,
    this.onTap,
    this.onLongPress,
  });

  /// Map language codes to flag emojis
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
      'ja': '\u{1F1EF}\u{1F1F5}', // 🇯🇵
      'ko': '\u{1F1F0}\u{1F1F7}', // 🇰🇷
      'zh': '\u{1F1E8}\u{1F1F3}', // 🇨🇳
      'ar': '\u{1F1F8}\u{1F1E6}', // 🇸🇦
      'hi': '\u{1F1EE}\u{1F1F3}', // 🇮🇳
      'tr': '\u{1F1F9}\u{1F1F7}', // 🇹🇷
      'ru': '\u{1F1F7}\u{1F1FA}', // 🇷🇺
    };
    return flags[code] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasUnread = conversation.hasUnreadMessages;
    final isTyping = conversation.isOtherUserTyping(currentUserId);

    // Build language flags for the other user's spoken languages
    final userLanguageFlags = _buildUserLanguageFlags();

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.divider.withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Profile photo
            Stack(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.backgroundCard,
                  backgroundImage: otherUserProfile?.photoUrls.isNotEmpty ??
                          false
                      ? NetworkImage(otherUserProfile!.photoUrls.first)
                      : null,
                  child: otherUserProfile?.photoUrls.isEmpty ?? true
                      ? const Icon(
                          Icons.person,
                          size: 30,
                          color: AppColors.textTertiary,
                        )
                      : null,
                ),

                // Online status indicator
                if (otherUserProfile?.isOnline ?? false)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.successGreen,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.backgroundDark,
                          width: 2,
                        ),
                      ),
                    ),
                  ),

                // Search conversation badge
                if (conversation.isSearchConversation)
                  Positioned(
                    left: -2,
                    bottom: -2,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundDark,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.richGold.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.search,
                        size: 10,
                        color: AppColors.richGold,
                      ),
                    ),
                  ),

                // Unread badge with enhanced visibility
                if (hasUnread && conversation.unreadCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.richGold,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.backgroundDark,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.richGold.withOpacity(0.3),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          conversation.unreadCount > 99
                              ? '99+'
                              : '${conversation.unreadCount}',
                          style: const TextStyle(
                            color: AppColors.deepBlack,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 12),

            // Conversation info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + user's spoken language flags
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          otherUserProfile?.displayName ?? l10n.chatUnknown,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight:
                                hasUnread ? FontWeight.bold : FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (userLanguageFlags.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          userLanguageFlags,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Last message or typing indicator
                  if (isTyping)
                    Row(
                      children: [
                        Text(
                          l10n.chatTyping,
                          style: const TextStyle(
                            color: AppColors.richGold,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            color: AppColors.richGold,
                            strokeWidth: 2,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      conversation.lastMessagePreview,
                      style: TextStyle(
                        color: hasUnread
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight:
                            hasUnread ? FontWeight.w500 : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // Time + chat language flag
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Chat language flag (only if different from default)
                if (chatLanguage != null && chatLanguage!.isNotEmpty) ...[
                  Text(
                    _flagForLanguage(chatLanguage),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  conversation.timeSinceLastMessage,
                  style: TextStyle(
                    color: hasUnread
                        ? AppColors.richGold
                        : AppColors.textTertiary,
                    fontSize: 12,
                    fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build a string of flag emojis for the other user's spoken languages
  String _buildUserLanguageFlags() {
    final profile = otherUserProfile;
    if (profile == null) return '';

    final flags = <String>[];
    // Add native language flag first
    if (profile.nativeLanguage != null && profile.nativeLanguage!.isNotEmpty) {
      final f = _flagForLanguage(profile.nativeLanguage);
      if (f.isNotEmpty) flags.add(f);
    }
    // Add other spoken languages
    for (final lang in profile.languages) {
      final f = _flagForLanguage(lang);
      if (f.isNotEmpty && !flags.contains(f)) {
        flags.add(f);
      }
    }
    return flags.join('');
  }
}
