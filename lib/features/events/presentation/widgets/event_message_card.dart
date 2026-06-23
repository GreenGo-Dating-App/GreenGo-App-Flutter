import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../screens/event_detail_loader_screen.dart';
import 'forward_event_sheet.dart';

/// A compact card rendered inside a chat / group-chat message bubble when an
/// event has been shared (MessageType.event). Reads the shared event metadata
/// and, on tap, opens the full event detail (native events) or deep-links out
/// to the provider's booking page (external experiences/attractions/live events).
///
/// Expected message metadata keys: eventId, eventTitle, eventImageUrl.
/// For external shares: externalUrl (booking link) + externalSource (label).
class EventMessageCard extends StatelessWidget {
  const EventMessageCard({
    super.key,
    required this.metadata,
    required this.currentUserId,
    this.onDark = false,
  });

  final Map<String, dynamic>? metadata;
  final String currentUserId;

  /// True when rendered on a dark/own bubble (adjusts text contrast).
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final eventId = metadata?['eventId'] as String? ?? '';
    final title = metadata?['eventTitle'] as String? ?? l10n.eventsTitle;
    final imageUrl = metadata?['eventImageUrl'] as String?;
    final externalUrl = metadata?['externalUrl'] as String? ?? '';
    final externalSource = metadata?['externalSource'] as String? ?? '';
    final isExternal = eventId.isEmpty && externalUrl.isNotEmpty;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => _showChooser(context, isExternal, eventId, externalUrl),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 240,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cover
            SizedBox(
              height: 110,
              width: double.infinity,
              child: (imageUrl != null && imageUrl.isNotEmpty)
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(theme),
                    )
                  : _placeholder(theme),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(isExternal ? Icons.confirmation_number : Icons.event,
                          size: 16, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        isExternal && externalSource.isNotEmpty
                            ? externalSource
                            : l10n.eventsTitle,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isExternal ? l10n.eventsBook : l10n.eventViewEvent,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      decoration: TextDecoration.underline,
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

  /// Single-tap chooser — same idea as the attractions/experiences menu:
  /// open the event/link, or forward to a chat / group.
  void _showChooser(
      BuildContext context, bool isExternal, String eventId, String externalUrl) {
    final l10n = AppLocalizations.of(context)!;
    final meta = metadata ?? const {};

    Widget tile(IconData icon, String label, VoidCallback onTap) => ListTile(
          leading: Icon(icon, color: AppColors.richGold),
          title:
              Text(label, style: const TextStyle(color: AppColors.textPrimary)),
          onTap: onTap,
        );

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.textTertiary,
                    borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                (meta['eventTitle'] as String?) ?? l10n.eventsTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
            if (isExternal)
              tile(Icons.open_in_new, l10n.attractionOpenLink, () {
                Navigator.pop(sheetCtx);
                launchUrl(Uri.parse(externalUrl),
                    mode: LaunchMode.externalApplication);
              })
            else if (eventId.isNotEmpty)
              tile(Icons.event, l10n.eventViewEvent, () {
                Navigator.pop(sheetCtx);
                Navigator.of(context).push(EventDetailLoaderScreen.route(
                    eventId: eventId, currentUserId: currentUserId));
              }),
            tile(Icons.chat_bubble_outline, l10n.attractionShareChat, () {
              Navigator.pop(sheetCtx);
              showForwardEventSheet(context,
                  metadata: Map<String, dynamic>.from(meta),
                  currentUserId: currentUserId,
                  mode: 'chats');
            }),
            tile(Icons.groups, l10n.attractionShareGroup, () {
              Navigator.pop(sheetCtx);
              showForwardEventSheet(context,
                  metadata: Map<String, dynamic>.from(meta),
                  currentUserId: currentUserId,
                  mode: 'groups');
            }),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(ThemeData theme) => Container(
        color: theme.colorScheme.surfaceContainerHighest,
        child: const Center(
          child: Icon(Icons.event, size: 40, color: Colors.orange),
        ),
      );
}
