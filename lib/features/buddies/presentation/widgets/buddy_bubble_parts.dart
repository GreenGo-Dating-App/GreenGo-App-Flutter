import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/language_flags.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/entities/buddy_message.dart';
import '../buddy_segments.dart';
import 'buddy_avatar.dart';

/// Inside a Buddy message bubble (the 1:1 chat's [MessageBubble] header):
/// the "AI" badge, plus the check-in / support mark.
class BuddyBubbleHeader extends StatelessWidget {
  const BuddyBubbleHeader({required this.kind, super.key});

  final BuddyMessageKind kind;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final marked = kind != BuddyMessageKind.chat;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BuddyAiBadge(compact: true),
          if (marked) ...[
            const SizedBox(width: 6),
            Icon(
              kind == BuddyMessageKind.safety
                  ? Icons.health_and_safety_outlined
                  : Icons.waving_hand_outlined,
              size: 13,
              color: kind == BuddyMessageKind.safety ? AppColors.infoBlue : AppColors.textTertiary,
            ),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                kind == BuddyMessageKind.safety ? l10n.buddySafetyLabel : l10n.buddyCheckInLabel,
                key: ValueKey('buddy-msg-mark-${kind.name}'),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Inside the user's own bubble, under the original text (which stays the
/// main text and never changes): the server translation into the chat
/// language, appended once it is known (callable result, then the stored
/// doc). Styled like the 1:1 chat's secondary line.
class BuddyUserTranslationLine extends StatelessWidget {
  const BuddyUserTranslationLine({
    required this.messageId,
    required this.text,
    required this.language,
    this.showFlag = true,
    this.matches = const <BuddySegmentMatch>[],
    super.key,
  });

  final String messageId;

  /// Matching chunks to colour in [text] (empty = plain).
  final List<BuddySegmentMatch> matches;
  final String text;

  /// The chat language (what [text] is in).
  final String language;
  final bool showFlag;

  @override
  Widget build(BuildContext context) {
    final flag = showFlag ? languageFlagEmoji(language) : '';
    final style = TextStyle(
      color: AppColors.deepBlack.withValues(alpha: 0.7),
      fontSize: 13,
      height: 1.3,
      fontStyle: FontStyle.italic,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Container(
        key: ValueKey('buddy-user-translation-$messageId'),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.deepBlack.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (flag.isNotEmpty) ...[
              Text(flag, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: matches.isEmpty
                  ? Text(text, style: style)
                  : BuddySegmentText(text: text, matches: matches, original: false, style: style),
            ),
          ],
        ),
      ),
    );
  }
}

/// Under a Buddy chat bubble: "Not sent. Tap to try again." on a failed
/// message of the user, Report on a stored Buddy message. Null when neither.
Widget? buddyBubbleFooter(
  BuildContext context, {
  required String messageId,
  VoidCallback? onRetry,
  VoidCallback? onReport,
}) {
  if (onRetry == null && onReport == null) return null;
  final l10n = AppLocalizations.of(context)!;
  if (onRetry != null) {
    return InkWell(
      key: ValueKey('buddy-retry-$messageId'),
      onTap: onRetry,
      child: Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 14, color: AppColors.errorRed),
            const SizedBox(width: 4),
            Text(l10n.buddyNotSent, style: const TextStyle(color: AppColors.errorRed, fontSize: 12)),
          ],
        ),
      ),
    );
  }
  return InkWell(
    key: ValueKey('buddy-report-$messageId'),
    onTap: onReport,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.flag_outlined, size: 14, color: AppColors.textTertiary),
          const SizedBox(width: 4),
          Text(l10n.buddyReport,
              style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
        ],
      ),
    ),
  );
}

/// "<name> is typing…" with three pulsing dots.
class BuddyTypingIndicator extends StatefulWidget {
  const BuddyTypingIndicator({required this.name, required this.avatarId, super.key});

  final String name;
  final String avatarId;

  @override
  State<BuddyTypingIndicator> createState() => _BuddyTypingIndicatorState();
}

class _BuddyTypingIndicatorState extends State<BuddyTypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      key: const ValueKey('buddy-typing'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          BuddyAvatar(avatarId: widget.avatarId, size: 28),
          const SizedBox(width: 8),
          AnimatedBuilder(
            animation: _c,
            builder: (_, __) => Row(
              children: List.generate(3, (i) {
                final t = ((_c.value * 3) - i).clamp(0.0, 1.0);
                final up = t < 0.5 ? t * 2 : (1 - t) * 2;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: AppColors.richGold.withValues(alpha: 0.35 + 0.65 * up),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              l10n.buddyTyping(widget.name),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
