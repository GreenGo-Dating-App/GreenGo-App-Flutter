import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/entities/buddy_message.dart';
import 'buddy_avatar.dart';

/// One message in a Buddy chat. Buddy messages carry the "AI" badge, a
/// translate and a report action; check-ins and safety messages are marked.
class BuddyMessageBubble extends StatelessWidget {
  const BuddyMessageBubble({
    required this.message,
    required this.avatarId,
    this.translation,
    this.translating = false,
    this.onTranslate,
    this.onReport,
    this.onRetry,
    super.key,
  });

  final BuddyMessage message;
  final String avatarId;

  /// Shown instead of the text while set ("Show original" toggles back).
  final String? translation;
  final bool translating;
  final VoidCallback? onTranslate;
  final VoidCallback? onReport;
  final VoidCallback? onRetry;

  void _copy(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Clipboard.setData(ClipboardData(text: translation ?? message.text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.buddyCopied)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mine = !message.isBuddy;
    final failed = message.delivery == BuddyDelivery.failed;
    final sending = message.delivery == BuddyDelivery.sending;
    final marked = message.kind != BuddyMessageKind.chat && message.isBuddy;

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: mine
            ? AppColors.richGold.withValues(alpha: failed ? 0.4 : 0.9)
            : AppColors.backgroundCard,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(mine ? 16 : 4),
          bottomRight: Radius.circular(mine ? 4 : 16),
        ),
        border: marked
            ? Border.all(
                color: message.kind == BuddyMessageKind.safety
                    ? AppColors.infoBlue
                    : AppColors.richGold.withValues(alpha: 0.6))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.isBuddy)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BuddyAiBadge(compact: true),
                  if (marked) ...[
                    const SizedBox(width: 6),
                    Icon(
                      message.kind == BuddyMessageKind.safety
                          ? Icons.health_and_safety_outlined
                          : Icons.waving_hand_outlined,
                      size: 13,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      message.kind == BuddyMessageKind.safety
                          ? l10n.buddySafetyLabel
                          : l10n.buddyCheckInLabel,
                      key: ValueKey('buddy-msg-mark-${message.kind.name}'),
                      style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
          SelectableText(
            translation ?? message.text,
            style: TextStyle(
              color: mine ? AppColors.deepBlack : AppColors.textPrimary,
              fontSize: 15,
              height: 1.35,
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!mine) ...[
            BuddyAvatar(avatarId: avatarId, size: 28),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: failed ? onRetry : null,
                  onLongPress: () => _copy(context),
                  child: Opacity(opacity: sending ? 0.7 : 1, child: bubble),
                ),
                if (failed)
                  InkWell(
                    key: ValueKey('buddy-retry-${message.id}'),
                    onTap: onRetry,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 14, color: AppColors.errorRed),
                          const SizedBox(width: 4),
                          Text(l10n.buddyNotSent,
                              style: const TextStyle(color: AppColors.errorRed, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                if (message.isBuddy && (onTranslate != null || onReport != null))
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onTranslate != null)
                        _action(
                          key: ValueKey('buddy-translate-${message.id}'),
                          icon: Icons.translate,
                          label: translation != null ? l10n.buddyShowOriginal : l10n.buddyTranslate,
                          busy: translating,
                          onTap: onTranslate!,
                        ),
                      if (onReport != null)
                        _action(
                          key: ValueKey('buddy-report-${message.id}'),
                          icon: Icons.flag_outlined,
                          label: l10n.buddyReport,
                          onTap: onReport!,
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _action({
    required Key key,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool busy = false,
  }) =>
      InkWell(
        key: key,
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy)
                const SizedBox.square(
                    dimension: 12,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.textTertiary))
              else
                Icon(icon, size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
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
