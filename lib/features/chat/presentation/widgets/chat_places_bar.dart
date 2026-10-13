import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/chat_datasets/keyword_matcher.dart';
import '../../../../core/utils/country_names_l10n.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/chat_places.dart';
import '../screens/chat_trip_screen.dart';
import 'keyword_actions.dart';

/// Above the chat input, offline (message metadata + datasets, no AI): when
/// the other person's latest message names a place, ready-to-send questions
/// about it ("Have you been to Lisbon?") and its country's cultural tips.
/// Every place of the chat is behind [ChatPlacesButton] (list + map).
class ChatPlacesBar extends StatefulWidget {
  const ChatPlacesBar({
    super.key,
    required this.places,
    required this.partnerPlaces,
    required this.onInsert,
  });

  /// Every place in the chat, newest first ([ChatPlaces.collect]).
  final List<ChatPlace> places;

  /// Places of the other person's latest message ([ChatPlaces.latestFromPartner]).
  final List<ChatPlace> partnerPlaces;

  /// Puts a suggested question into the input field.
  final ValueChanged<String> onInsert;

  /// Question templates per kind of place (all take the place name).
  static List<String Function(AppLocalizations, String)> questionsFor(KeywordKind kind) => switch (kind) {
        KeywordKind.attraction => [
            (l, p) => l.chatAskBeenTo(p),
            (l, p) => l.chatAskWorthIt(p),
            (l, p) => l.chatAskBestTime(p),
          ],
        KeywordKind.city => [
            (l, p) => l.chatAskBeenTo(p),
            (l, p) => l.chatAskMustSee(p),
            (l, p) => l.chatAskFood(p),
            (l, p) => l.chatAskFavorite(p),
          ],
        KeywordKind.country => [
            (l, p) => l.chatAskBeenTo(p),
            (l, p) => l.chatAskMustSee(p),
            (l, p) => l.chatAskFood(p),
            (l, p) => l.chatAskBestTime(p),
          ],
      };

  static IconData iconFor(KeywordKind kind) => switch (kind) {
        KeywordKind.attraction => Icons.place_outlined,
        KeywordKind.city => Icons.location_city_outlined,
        KeywordKind.country => Icons.public,
      };

  @override
  State<ChatPlacesBar> createState() => _ChatPlacesBarState();
}

class _ChatPlacesBarState extends State<ChatPlacesBar> {
  /// Message whose suggestions the user closed.
  String? _dismissedFor;

  @override
  Widget build(BuildContext context) {
    final topic = widget.partnerPlaces.isEmpty ? null : widget.partnerPlaces.first;
    if (topic == null || topic.messageId == _dismissedFor) return const SizedBox.shrink();
    return Container(
      color: AppColors.backgroundCard,
      child: _suggestions(AppLocalizations.of(context)!, topic),
    );
  }

  Widget _suggestions(AppLocalizations l10n, ChatPlace topic) {
    final iso = topic.iso2;
    final questions = ChatPlacesBar.questionsFor(topic.kind).map((q) => q(l10n, topic.label)).toList();
    return Container(
      key: const ValueKey('chat-place-suggestions'),
      padding: const EdgeInsets.fromLTRB(12, 6, 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tips_and_updates_outlined, size: 16, color: AppColors.richGold),
              const SizedBox(width: 6),
              Expanded(
                child: Text(l10n.chatPlaceCameUp(topic.label),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                icon: const Icon(Icons.close, size: 18, color: AppColors.textTertiary),
                onPressed: () => setState(() => _dismissedFor = topic.messageId),
              ),
            ],
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final q in questions)
                  Padding(
                    padding: const EdgeInsets.only(right: 6, bottom: 4),
                    child: ActionChip(
                      label: Text(q),
                      labelStyle: const TextStyle(color: AppColors.richGold, fontSize: 12.5),
                      backgroundColor: AppColors.richGold.withValues(alpha: 0.08),
                      side: BorderSide(color: AppColors.richGold.withValues(alpha: 0.5)),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => widget.onInsert(q),
                    ),
                  ),
                if (iso != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 6, bottom: 4),
                    child: ActionChip(
                      avatar: const Icon(Icons.lightbulb_outline, size: 16, color: AppColors.richGold),
                      label: Text(l10n.chatTipsFor(localizedCountryName(l10n, iso))),
                      labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 12.5),
                      backgroundColor: AppColors.charcoal,
                      side: BorderSide(color: AppColors.textTertiary.withValues(alpha: 0.35)),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => CountryTipsSheet.show(context, iso),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The chat's places (attractions, cities, countries) as a list and on a map.
class ChatPlacesButton extends StatelessWidget {
  const ChatPlacesButton({super.key, required this.places, this.onRemove});

  final List<ChatPlace> places;

  /// See [ChatTripScreen.onRemove].
  final Future<void> Function(ChatPlace place)? onRemove;

  @override
  Widget build(BuildContext context) => IconButton(
        key: const ValueKey('chat-places-trip'),
        tooltip: AppLocalizations.of(context)!.chatTripTitle,
        icon: const Icon(Icons.map_outlined),
        color: AppColors.richGold,
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ChatTripScreen(places: places, onRemove: onRemove),
        )),
      );
}
