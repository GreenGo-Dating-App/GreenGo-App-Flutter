import 'package:flutter/material.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/icebreaker.dart';

/// Screen for selecting and sending icebreaker questions
class IcebreakerScreen extends StatefulWidget {
  final String matchId;
  final String receiverName;
  final Function(Icebreaker, String?)? onIcebreakerSelected;

  const IcebreakerScreen({
    super.key,
    required this.matchId,
    required this.receiverName,
    this.onIcebreakerSelected,
  });

  @override
  State<IcebreakerScreen> createState() => _IcebreakerScreenState();
}

class _IcebreakerScreenState extends State<IcebreakerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  IcebreakerCategory? _selectedCategory;
  final List<Icebreaker> _icebreakers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _loadIcebreakers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<IcebreakerCategory> get _categories => [
        IcebreakerCategory.funnyQuestions,
        IcebreakerCategory.wouldYouRather,
        IcebreakerCategory.deepQuestions,
        IcebreakerCategory.travel,
        IcebreakerCategory.food,
        IcebreakerCategory.personality,
      ];

  void _loadIcebreakers() {
    // Load from default database
    int id = 0;
    for (final data in IcebreakerDatabase.defaultIcebreakers) {
      _icebreakers.add(Icebreaker(
        id: 'icebreaker_${id++}',
        question: data['question'] as String,
        category: data['category'] as IcebreakerCategory,
        suggestedAnswers: data['suggestedAnswers'] as List<String>?,
        createdAt: DateTime.now(),
      ));
    }
    setState(() {});
  }

  String _getCategoryName(IcebreakerCategory category) {
    final l10n = AppLocalizations.of(context)!;
    switch (category) {
      case IcebreakerCategory.funnyQuestions:
        return l10n.icebreakersCategoryFunny;
      case IcebreakerCategory.deepQuestions:
        return l10n.icebreakersCategoryDeep;
      case IcebreakerCategory.wouldYouRather:
        return l10n.icebreakersCategoryWouldYouRather;
      case IcebreakerCategory.twoTruths:
        return l10n.icebreakersCategoryTwoTruths;
      case IcebreakerCategory.dateIdeas:
        return l10n.icebreakersCategoryDateIdeas;
      case IcebreakerCategory.compliments:
        return l10n.icebreakersCategoryCompliments;
      case IcebreakerCategory.hobbies:
        return l10n.icebreakersCategoryHobbies;
      case IcebreakerCategory.travel:
        return l10n.icebreakersCategoryTravel;
      case IcebreakerCategory.food:
        return l10n.icebreakersCategoryFood;
      case IcebreakerCategory.music:
        return l10n.icebreakersCategoryMusic;
      case IcebreakerCategory.movies:
        return l10n.icebreakersCategoryMovies;
      case IcebreakerCategory.dreams:
        return l10n.icebreakersCategoryDreams;
      case IcebreakerCategory.hypothetical:
        return l10n.icebreakersCategoryHypothetical;
      case IcebreakerCategory.personality:
        return l10n.icebreakersCategoryPersonality;
    }
  }

  IconData _getCategoryIcon(IcebreakerCategory category) {
    switch (category) {
      case IcebreakerCategory.funnyQuestions:
        return Icons.sentiment_very_satisfied;
      case IcebreakerCategory.deepQuestions:
        return Icons.psychology;
      case IcebreakerCategory.wouldYouRather:
        return Icons.swap_horiz;
      case IcebreakerCategory.twoTruths:
        return Icons.fact_check;
      case IcebreakerCategory.dateIdeas:
        return Icons.favorite;
      case IcebreakerCategory.compliments:
        return Icons.stars;
      case IcebreakerCategory.hobbies:
        return Icons.sports_esports;
      case IcebreakerCategory.travel:
        return Icons.flight;
      case IcebreakerCategory.food:
        return Icons.restaurant;
      case IcebreakerCategory.music:
        return Icons.music_note;
      case IcebreakerCategory.movies:
        return Icons.movie;
      case IcebreakerCategory.dreams:
        return Icons.nights_stay;
      case IcebreakerCategory.hypothetical:
        return Icons.lightbulb;
      case IcebreakerCategory.personality:
        return Icons.person;
    }
  }

  void _selectIcebreaker(Icebreaker icebreaker) {
    if (icebreaker.suggestedAnswers != null &&
        icebreaker.suggestedAnswers!.isNotEmpty) {
      _showAnswerOptions(icebreaker);
    } else {
      _sendIcebreaker(icebreaker, null);
    }
  }

  void _showAnswerOptions(Icebreaker icebreaker) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              icebreaker.question,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.icebreakersQuickAnswers,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: icebreaker.suggestedAnswers!.map((answer) {
                return ActionChip(
                  label: Text(answer),
                  labelStyle: const TextStyle(color: AppColors.textPrimary),
                  backgroundColor: AppColors.backgroundDark,
                  side: const BorderSide(color: AppColors.richGold),
                  onPressed: () {
                    Navigator.pop(context);
                    _sendIcebreaker(icebreaker, answer);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _sendIcebreaker(icebreaker, null);
              },
              child: Text(AppLocalizations.of(context)!.icebreakersSendWithoutAnswer),
            ),
          ],
        ),
      ),
    );
  }

  void _sendIcebreaker(Icebreaker icebreaker, String? answer) {
    widget.onIcebreakerSelected?.call(icebreaker, answer);
    Navigator.pop(context, {
      'icebreaker': icebreaker,
      'answer': answer,
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.icebreakersTitle,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
              ),
            ),
            Text(
              l10n.icebreakersSendTo(widget.receiverName),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.richGold,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.richGold,
          tabs: _categories.map((category) {
            return Tab(
              text: _getCategoryName(category),
              icon: Icon(_getCategoryIcon(category), size: 20),
            );
          }).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _categories.map((category) {
          final categoryIcebreakers = _icebreakers
              .where((i) => i.category == category)
              .toList();

          return categoryIcebreakers.isEmpty
              ? Center(
                  child: Text(
                    l10n.icebreakersNoneInCategory,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  itemCount: categoryIcebreakers.length,
                  itemBuilder: (context, index) {
                    final icebreaker = categoryIcebreakers[index];
                    return _IcebreakerCard(
                      icebreaker: icebreaker,
                      onTap: () => _selectIcebreaker(icebreaker),
                    );
                  },
                );
        }).toList(),
      ),
    );
  }
}

class _IcebreakerCard extends StatelessWidget {
  final Icebreaker icebreaker;
  final VoidCallback onTap;

  const _IcebreakerCard({
    required this.icebreaker,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.divider),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        icebreaker.question,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (icebreaker.suggestedAnswers != null &&
                          icebreaker.suggestedAnswers!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: icebreaker.suggestedAnswers!.take(3).map((answer) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.richGold.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                answer,
                                style: const TextStyle(
                                  color: AppColors.richGold,
                                  fontSize: 11,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.richGold.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.send,
                    color: AppColors.richGold,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Icebreaker suggestion widget for chat input
class IcebreakerSuggestionButton extends StatelessWidget {
  final VoidCallback onTap;

  const IcebreakerSuggestionButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: AppLocalizations.of(context)!.icebreakersSendAnIcebreaker,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.richGold.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.richGold.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lightbulb_outline,
                color: AppColors.richGold,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                AppLocalizations.of(context)!.icebreakersLabel,
                style: const TextStyle(
                  color: AppColors.richGold,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
