import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../../events/presentation/screens/event_detail_loader_screen.dart';
import '../../../user_experiences/presentation/screens/experience_detail_screen.dart';
import '../../domain/entities/conversation_listing_context.dart';
import '../listing_chat.dart';

/// "Message the organizer" (events) / "Message the host" (experiences).
///
/// Hidden for the organizer / host themselves ([isOrganizer], or the viewer
/// being [ListingChatRef.organizerId]) and when nobody is signed in. Opens
/// the chat through [ListingChatFlow]: a verified ticket holder / booked guest
/// skips the daily new-connection cap (server-side), everyone else goes
/// through the normal connect gate.
class ListingChatButton extends StatelessWidget {
  const ListingChatButton({
    required this.listing,
    required this.currentUserId,
    this.isOrganizer = false,
    this.flow,
    super.key,
  });

  final ListingChatRef listing;
  final String currentUserId;

  /// The viewer runs the listing (organizer, co-owner or host).
  final bool isOrganizer;

  /// Test seam (defaults to [ListingChatFlow.instance]).
  final ListingChatFlow? flow;

  bool get _hidden =>
      currentUserId.isEmpty ||
      isOrganizer ||
      (listing.organizerId != null && listing.organizerId == currentUserId);

  @override
  Widget build(BuildContext context) {
    if (_hidden) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final label = listing.type == ConversationListingContext.event
        ? l10n.listingChatMessageOrganizer
        : l10n.listingChatMessageHost;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        key: const ValueKey('listing-chat-button'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.richGold,
          side: BorderSide(color: AppColors.richGold.withValues(alpha: 0.6)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        icon: const Icon(Icons.chat_bubble_outline, size: 18),
        label: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        onPressed: () => (flow ?? ListingChatFlow.instance)
            .open(context, currentUserId: currentUserId, listing: listing),
      ),
    );
  }
}

String _aboutText(AppLocalizations l10n, BuildContext context,
    ConversationListingContext c) {
  final title = c.title.isNotEmpty ? c.title : '…';
  final start = c.startAt;
  if (start == null) return l10n.listingChatAbout(title);
  final locale = Localizations.localeOf(context).toLanguageTag();
  String date;
  try {
    date = DateFormat.yMMMd(locale).format(start.toLocal());
  } catch (_) {
    date = DateFormat.yMMMd().format(start.toLocal());
  }
  return l10n.listingChatAboutDated(title, date);
}

String _buyerTag(AppLocalizations l10n, ConversationListingContext c) =>
    c.isEvent ? l10n.listingChatTicketHolder : l10n.listingChatBooked;

/// Opens the listing a chat is about.
void openListingOfContext(
    BuildContext context, ConversationListingContext c, String currentUserId) {
  Navigator.of(context).push(c.isEvent
      ? EventDetailLoaderScreen.route(eventId: c.id, currentUserId: currentUserId)
      : ExperienceDetailScreen.route(
          experienceId: c.id, currentUserId: currentUserId));
}

/// Pinned "About: <title> · <date>" chip at the top of a chat; taps through
/// to the listing. The organizer also sees "Ticket holder" / "Booked".
class ListingContextChip extends StatelessWidget {
  const ListingContextChip({
    required this.listingContext,
    required this.currentUserId,
    super.key,
  });

  final ConversationListingContext listingContext;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = listingContext;
    return Material(
      color: AppColors.backgroundCard,
      child: InkWell(
        key: const ValueKey('listing-context-chip'),
        onTap: () => openListingOfContext(context, c, currentUserId),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: Row(children: [
            Icon(c.isEvent ? Icons.event : Icons.explore_outlined,
                size: 16, color: AppColors.richGold),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _aboutText(l10n, context, c),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ),
            if (c.showsBuyerTagFor(currentUserId)) ...[
              const SizedBox(width: 8),
              BuyerTag(text: _buyerTag(l10n, c)),
            ],
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.textTertiary),
          ]),
        ),
      ),
    );
  }
}

/// Small "Ticket holder" / "Booked" pill.
class BuyerTag extends StatelessWidget {
  const BuyerTag({required this.text, super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        key: const ValueKey('listing-buyer-tag'),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.richGold.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.richGold.withValues(alpha: 0.5)),
        ),
        child: Text(text,
            style: const TextStyle(
                color: AppColors.richGold,
                fontSize: 11,
                fontWeight: FontWeight.w700)),
      );
}

/// One-line listing label for the conversation list ("About: <title>" +
/// tag for the organizer). Cheap: reads only the conversation document.
class ListingContextLabel extends StatelessWidget {
  const ListingContextLabel({
    required this.listingContext,
    required this.currentUserId,
    super.key,
  });

  final ConversationListingContext listingContext;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = listingContext;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(children: [
        Icon(c.isEvent ? Icons.event : Icons.explore_outlined,
            size: 12, color: AppColors.richGold),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            l10n.listingChatAbout(c.title.isNotEmpty ? c.title : '…'),
            key: const ValueKey('listing-context-label'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.richGold, fontSize: 12),
          ),
        ),
        if (c.showsBuyerTagFor(currentUserId)) ...[
          const SizedBox(width: 6),
          BuyerTag(text: _buyerTag(l10n, c)),
        ],
      ]),
    );
  }
}
