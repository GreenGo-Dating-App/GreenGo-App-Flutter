import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/chat_datasets/chat_datasets.dart';
import '../../../../generated/app_localizations.dart';

/// "Ideas to write": offline ice-breakers and suggested sentences by topic,
/// shown in the partner's language with the user's own underneath. Picking
/// one hands the partner-language text to [onPick] (it goes into the input).
class ChatIdeasSheet extends StatefulWidget {
  const ChatIdeasSheet({
    required this.partnerLanguage,
    required this.myLanguage,
    required this.onPick,
    this.sentences = false,
    super.key,
  });

  /// false: ice-breakers; true: suggested sentences (one kind per sheet).
  final bool sentences;

  final String partnerLanguage;
  final String myLanguage;
  final ValueChanged<String> onPick;

  static Future<void> show(
    BuildContext context, {
    required String partnerLanguage,
    required String myLanguage,
    required ValueChanged<String> onPick,
    bool sentences = false,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundCard,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.8,
        child: ChatIdeasSheet(
          partnerLanguage: partnerLanguage,
          myLanguage: myLanguage,
          onPick: onPick,
          sentences: sentences,
        ),
      ),
    );
  }

  /// A few random ice-breakers (empty chat), or empty while not loaded.
  static List<DatasetItem> randomIcebreakers(int n, {int? seed}) {
    final all = ChatDatasets.instance.icebreakers;
    if (all == null || all.isEmpty) return const [];
    final r = Random(seed);
    return [for (var i = 0; i < n; i++) all[r.nextInt(all.length)]];
  }

  @override
  State<ChatIdeasSheet> createState() => _ChatIdeasSheetState();
}

class _ChatIdeasSheetState extends State<ChatIdeasSheet> {
  final _datasets = ChatDatasets.instance;
  // Each tab waits only for its own file (both start loading at once).
  late final Future<void> _ready = _datasets.ensure(_sentences ? 'sentences' : 'icebreakers');
  bool get _sentences => widget.sentences;
  String? _topic;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<void>(
      future: _ready,
      builder: (context, snap) {
        final items = (_sentences ? _datasets.sentences : _datasets.icebreakers) ?? const <DatasetItem>[];
        final counts = <String, int>{};
        for (final i in items) {
          counts[i.topic] = (counts[i.topic] ?? 0) + 1;
        }
        final topics = counts.keys.toList();
        // No category chosen yet: the grid of categories.
        final topic = _topic != null && topics.contains(_topic) ? _topic : null;
        final shown = topic == null ? const <DatasetItem>[] : items.where((i) => i.topic == topic).toList();
        return Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.textTertiary, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                _sentences ? l10n.chatSuggestionsTitle : l10n.chatIcebreakersTitle,
                key: const ValueKey('chat-ideas-title'),
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
            if (snap.connectionState != ConnectionState.done)
              const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.richGold)))
            else if (items.isEmpty)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(l10n.chatDatasetsUnavailable,
                        textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
                  ),
                ),
              )
            else if (topic == null)
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) => GridView.builder(
                    key: const ValueKey('chat-ideas-categories'),
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: c.maxWidth < 500 ? 2 : (c.maxWidth < 900 ? 3 : 4),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.6,
                    ),
                    itemCount: topics.length,
                    itemBuilder: (context, i) {
                      final t = topics[i];
                      return Material(
                        color: AppColors.charcoal,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          key: ValueKey('chat-ideas-category-$t'),
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => setState(() => _topic = t),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(chatTopicIcon(t), color: AppColors.richGold, size: 22),
                                Text(chatTopicLabel(l10n, t),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                                Text('${counts[t]}',
                                    style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              )
            else ...[
              // A category: back to the grid, then its messages.
              ListTile(
                key: const ValueKey('chat-ideas-back'),
                dense: true,
                leading: const Icon(Icons.arrow_back, color: AppColors.richGold),
                title: Text(chatTopicLabel(l10n, topic),
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                onTap: () => setState(() => _topic = null),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                  itemCount: shown.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
                  itemBuilder: (context, i) {
                    final it = shown[i];
                    final theirs = it.text.of(widget.partnerLanguage);
                    final mine = it.text.of(widget.myLanguage);
                    return ListTile(
                      title: Text(theirs, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                      subtitle: mine == theirs
                          ? null
                          : Text(mine,
                              style: const TextStyle(
                                  color: AppColors.textTertiary, fontSize: 12, fontStyle: FontStyle.italic)),
                      trailing: it.level == null
                          ? null
                          : Text(it.level!, style: const TextStyle(color: AppColors.richGold, fontSize: 11)),
                      onTap: () {
                        widget.onPick(theirs);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Icon of a dataset topic key (categories grid).
IconData chatTopicIcon(String topic) => switch (topic) {
      'travel' || 'local_tips' => Icons.flight_takeoff,
      'food' => Icons.restaurant,
      'music' => Icons.music_note,
      'movies_series' => Icons.movie_outlined,
      'books' => Icons.menu_book_outlined,
      'sports_fitness' => Icons.fitness_center,
      'languages' => Icons.translate,
      'traditions' || 'festivals' => Icons.celebration_outlined,
      'hometown' => Icons.home_outlined,
      'work_studies' => Icons.work_outline,
      'hobbies_creativity' || 'art_museums' => Icons.palette_outlined,
      'nature_outdoors' => Icons.park_outlined,
      'technology' => Icons.devices_outlined,
      'daily_life' => Icons.wb_sunny_outlined,
      'dreams_goals' => Icons.flag_outlined,
      'would_you_rather' => Icons.help_outline,
      'animals_pets' => Icons.pets,
      'greetings_intro' => Icons.waving_hand_outlined,
      'getting_to_know' => Icons.people_outline,
      'compliments' => Icons.favorite_border,
      'thanking' => Icons.volunteer_activism_outlined,
      'apologizing' => Icons.sentiment_dissatisfied_outlined,
      'making_plans' => Icons.event_outlined,
      'agree_disagree' => Icons.thumbs_up_down_outlined,
      _ => Icons.chat_bubble_outline,
    };

/// Localised label of a dataset topic key ("travel" -> "Viaggi").
String chatTopicLabel(AppLocalizations l10n, String topic) => switch (topic) {
      'travel' => l10n.chatTopicTravel,
      'food' => l10n.chatTopicFood,
      'music' => l10n.chatTopicMusic,
      'movies_series' => l10n.chatTopicMoviesSeries,
      'books' => l10n.chatTopicBooks,
      'sports_fitness' => l10n.chatTopicSportsFitness,
      'languages' => l10n.chatTopicLanguages,
      'traditions' => l10n.chatTopicTraditions,
      'hometown' => l10n.chatTopicHometown,
      'work_studies' => l10n.chatTopicWorkStudies,
      'hobbies_creativity' => l10n.chatTopicHobbiesCreativity,
      'nature_outdoors' => l10n.chatTopicNatureOutdoors,
      'technology' => l10n.chatTopicTechnology,
      'daily_life' => l10n.chatTopicDailyLife,
      'dreams_goals' => l10n.chatTopicDreamsGoals,
      'would_you_rather' => l10n.chatTopicWouldYouRather,
      'festivals' => l10n.chatTopicFestivals,
      'animals_pets' => l10n.chatTopicAnimalsPets,
      'art_museums' => l10n.chatTopicArtMuseums,
      'local_tips' => l10n.chatTopicLocalTips,
      'greetings_intro' => l10n.chatTopicGreetingsIntro,
      'getting_to_know' => l10n.chatTopicGettingToKnow,
      'agree_disagree' => l10n.chatTopicAgreeDisagree,
      'compliments' => l10n.chatTopicCompliments,
      'apologizing' => l10n.chatTopicApologizing,
      'thanking' => l10n.chatTopicThanking,
      'making_plans' => l10n.chatTopicMakingPlans,
      'inviting' => l10n.chatTopicInviting,
      'accept_decline' => l10n.chatTopicAcceptDecline,
      'recommendations' => l10n.chatTopicRecommendations,
      'directions_meeting' => l10n.chatTopicDirectionsMeeting,
      'weather' => l10n.chatTopicWeather,
      'food_talk' => l10n.chatTopicFoodTalk,
      'restaurant' => l10n.chatTopicRestaurant,
      'shopping' => l10n.chatTopicShopping,
      'transport' => l10n.chatTopicTransport,
      'accommodation' => l10n.chatTopicAccommodation,
      'health_emergency' => l10n.chatTopicHealthEmergency,
      'feelings' => l10n.chatTopicFeelings,
      'encouraging' => l10n.chatTopicEncouraging,
      'small_talk' => l10n.chatTopicSmallTalk,
      'family' => l10n.chatTopicFamily,
      'work' => l10n.chatTopicWork,
      'studies' => l10n.chatTopicStudies,
      'hobbies' => l10n.chatTopicHobbies,
      'travel_stories' => l10n.chatTopicTravelStories,
      'language_help' => l10n.chatTopicLanguageHelp,
      'clarifying' => l10n.chatTopicClarifying,
      'time_dates' => l10n.chatTopicTimeDates,
      'money_prices' => l10n.chatTopicMoneyPrices,
      'celebrating' => l10n.chatTopicCelebrating,
      'support_condolences' => l10n.chatTopicSupportCondolences,
      'goodbyes' => l10n.chatTopicGoodbyes,
      'keeping_in_touch' => l10n.chatTopicKeepingInTouch,
      'video_calls' => l10n.chatTopicVideoCalls,
      'sharing_photos' => l10n.chatTopicSharingPhotos,
      'culture_questions' => l10n.chatTopicCultureQuestions,
      'humor_reactions' => l10n.chatTopicHumorReactions,
      'events_rsvp' => l10n.chatTopicEventsRsvp,
      'language_progress' => l10n.chatTopicLanguageProgress,
      _ => topic,
    };
