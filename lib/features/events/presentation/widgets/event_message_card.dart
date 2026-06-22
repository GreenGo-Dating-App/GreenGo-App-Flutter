import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../generated/app_localizations.dart';
import '../screens/event_detail_loader_screen.dart';

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
      onTap: isExternal
          ? () => launchUrl(Uri.parse(externalUrl),
              mode: LaunchMode.externalApplication)
          : eventId.isEmpty
              ? null
              : () => Navigator.of(context).push(
                    EventDetailLoaderScreen.route(
                      eventId: eventId,
                      currentUserId: currentUserId,
                    ),
                  ),
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

  Widget _placeholder(ThemeData theme) => Container(
        color: theme.colorScheme.surfaceContainerHighest,
        child: const Center(
          child: Icon(Icons.event, size: 40, color: Colors.orange),
        ),
      );
}
