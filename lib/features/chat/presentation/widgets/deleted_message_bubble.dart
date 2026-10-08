import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';

/// Sender id the server writes on messages whose author deleted their account
/// (functions/src/auth/accountDeletion.ts, TOMBSTONE).
const String kDeletedUserSenderId = 'deleted_user';

/// True for a message whose author deleted their account: new format
/// (`deletedAuthor: true`, empty body) and old format (only the tombstone
/// sender id, body possibly still present). Either way the bubble shows the
/// localized "Message deleted" placeholder instead of the content.
bool isDeletedAuthorMessage(String? senderId, {Object? deletedAuthor}) =>
    senderId == kDeletedUserSenderId || deletedAuthor == true;

/// Placeholder bubble for a message whose author deleted their account.
/// Always rendered on the "other person" side.
class DeletedMessageBubble extends StatelessWidget {
  const DeletedMessageBubble({super.key, this.compact = false});

  /// Smaller margins for dense lists (group / community / event chats).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)?.chatMessageDeleted ?? '';
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: compact
            ? const EdgeInsets.symmetric(vertical: 3)
            : const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.block, size: 14, color: AppColors.textTertiary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
