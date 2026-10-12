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
    super.key,
  });

  final String partnerLanguage;
  final String myLanguage;
  final ValueChanged<String> onPick;

  static Future<void> show(
    BuildContext context, {
    required String partnerLanguage,
    required String myLanguage,
    required ValueChanged<String> onPick,
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
  late final Future<void> _ready =
      Future.wait([_datasets.ensure('icebreakers'), _datasets.ensure('sentences')]);
  bool _sentences = false;
  String? _topic;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<void>(
      future: _ready,
      builder: (context, snap) {
        final items = (_sentences ? _datasets.sentences : _datasets.icebreakers) ?? const <DatasetItem>[];
        final topics = <String>{for (final i in items) i.topic}.toList();
        final topic = _topic != null && topics.contains(_topic) ? _topic : (topics.isEmpty ? null : topics.first);
        final shown = items.where((i) => i.topic == topic).toList();
        return Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.textTertiary, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: false, label: Text(l10n.chatIcebreakersTitle)),
                  ButtonSegment(value: true, label: Text(l10n.chatSuggestionsTitle)),
                ],
                selected: {_sentences},
                onSelectionChanged: (v) => setState(() {
                  _sentences = v.first;
                  _topic = null;
                }),
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
            else ...[
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  children: [
                    for (final t in topics)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(chatTopicLabel(l10n, t)),
                          selected: t == topic,
                          onSelected: (_) => setState(() => _topic = t),
                        ),
                      ),
                  ],
                ),
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
