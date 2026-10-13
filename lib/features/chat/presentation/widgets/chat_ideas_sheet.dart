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
        final topics = <String>{for (final i in items) i.topic}.toList();
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
                child: GridView.builder(
                  key: const ValueKey('chat-ideas-categories'),
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 28),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.45, // half the former height
                  ),
                  itemCount: topics.length,
                  itemBuilder: (context, i) => _CategoryTile(
                    key: ValueKey('chat-ideas-category-${topics[i]}'),
                    icon: chatTopicIcon(topics[i]),
                    label: chatTopicLabel(l10n, topics[i]),
                    onTap: () => setState(() => _topic = topics[i]),
                  ),
                ),
              )
            else ...[
              // A category: header with back, then its messages as cards.
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
                child: Row(children: [
                  IconButton(
                    key: const ValueKey('chat-ideas-back'),
                    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                    icon: const Icon(Icons.arrow_back, color: AppColors.richGold),
                    onPressed: () => setState(() => _topic = null),
                  ),
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.richGold.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(chatTopicIcon(topic), color: AppColors.richGold, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(chatTopicLabel(l10n, topic),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ]),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 28),
                  itemCount: shown.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final it = shown[i];
                    final theirs = it.text.of(widget.partnerLanguage);
                    final mine = it.text.of(widget.myLanguage);
                    return _IdeaCard(
                      theirs: theirs,
                      mine: mine == theirs ? null : mine,
                      level: it.level,
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

/// A category of the grid: icon over the name (compact, no count).
class _CategoryTile extends StatelessWidget {
  const _CategoryTile({super.key, required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.richGold.withValues(alpha: 0.25)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppColors.richGold, size: 20),
                const SizedBox(height: 3),
                Flexible(
                  child: Text(label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 11.5, fontWeight: FontWeight.w600, height: 1.15)),
                ),
              ],
            ),
          ),
        ),
      );
}

/// One message: the text in the partner's language, the user's own below,
/// the level (sentences) and a send arrow. Tap puts it into the input.
class _IdeaCard extends StatelessWidget {
  const _IdeaCard({required this.theirs, this.mine, this.level, required this.onTap});

  final String theirs;
  final String? mine;
  final String? level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mine = this.mine;
    final level = this.level;
    return Material(
      color: AppColors.charcoal,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border(left: BorderSide(color: AppColors.richGold.withValues(alpha: 0.8), width: 3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(theirs,
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w500, height: 1.35)),
                    if (mine != null) ...[
                      const SizedBox(height: 4),
                      Text(mine,
                          style: const TextStyle(
                              color: AppColors.textTertiary, fontSize: 12.5, fontStyle: FontStyle.italic, height: 1.3)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(children: [
                if (level != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.richGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(level,
                        style: const TextStyle(color: AppColors.richGold, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                const Icon(Icons.send_rounded, size: 18, color: AppColors.richGold),
              ]),
            ],
          ),
        ),
      ),
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
