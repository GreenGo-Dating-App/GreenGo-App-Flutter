import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/entities.dart';
import '../bloc/cultural_exchange_bloc.dart';
import '../widgets/widgets.dart';
import 'country_spotlight_screen.dart';
import 'dating_etiquette_screen.dart';

/// Main hub screen for the Cultural Exchange feature
class CulturalExchangeScreen extends StatefulWidget {
  const CulturalExchangeScreen({super.key});

  @override
  State<CulturalExchangeScreen> createState() =>
      _CulturalExchangeScreenState();
}

class _CulturalExchangeScreenState extends State<CulturalExchangeScreen> {
  @override
  void initState() {
    super.initState();
    context
        .read<CulturalExchangeBloc>()
        .add(const LoadCulturalExchangeData());
  }

  Future<void> _onRefresh() async {
    context
        .read<CulturalExchangeBloc>()
        .add(const LoadCulturalExchangeData());
    // Give time for data to load
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: BlocBuilder<CulturalExchangeBloc, CulturalExchangeState>(
          builder: (context, state) {
            if (state.status == CulturalExchangeStatus.loading &&
                !state.hasSpotlight &&
                !state.hasTips) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.richGold,
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _onRefresh,
              color: AppColors.richGold,
              backgroundColor: AppColors.backgroundCard,
              child: CustomScrollView(
                slivers: [
                  // App Bar
                  SliverAppBar(
                    expandedHeight: 100,
                    floating: false,
                    pinned: true,
                    backgroundColor: AppColors.backgroundDark,
                    flexibleSpace: FlexibleSpaceBar(
                      title: const Text(
                        'Cultural Exchange',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.richGold.withValues(alpha: 0.15),
                              AppColors.backgroundDark,
                            ],
                          ),
                        ),
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(
                          Icons.favorite_border,
                          color: AppColors.richGold,
                        ),
                        onPressed: () => _navigateToDatingEtiquette(context),
                        tooltip: 'Dating Etiquette',
                      ),
                    ],
                  ),

                  // Content
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Daily Cultural Hint banner
                        _buildDailyCulturalHint(),
                        const SizedBox(height: 20),

                        // Country Spotlight
                        if (state.hasSpotlight) ...[
                          _buildSectionHeader(
                            'Country Spotlight',
                            icon: Icons.public,
                          ),
                          const SizedBox(height: 10),
                          CountrySpotlightCard(
                            spotlight: state.activeSpotlight!,
                            onTap: () => _navigateToSpotlightDetail(
                              context,
                              state.activeSpotlight!,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Quick Access: Dating Etiquette
                        _buildSectionHeader(
                          'Dating Etiquette Guide',
                          icon: Icons.favorite,
                          onViewAll: () =>
                              _navigateToDatingEtiquette(context),
                        ),
                        const SizedBox(height: 10),
                        _buildDatingEtiquettePreview(state),
                        const SizedBox(height: 24),

                        // User Cultural Tips
                        _buildSectionHeader(
                          'Community Tips',
                          icon: Icons.lightbulb_outline,
                        ),
                        const SizedBox(height: 10),
                        if (state.isTipsLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(
                                color: AppColors.richGold,
                              ),
                            ),
                          )
                        else if (state.culturalTips.isEmpty)
                          _buildEmptyTips()
                        else
                          ...state.culturalTips.take(10).map(
                                (tip) => CulturalTipCard(
                                  tip: tip,
                                  onLike: () {
                                    context.read<CulturalExchangeBloc>().add(
                                          LikeCulturalTip(
                                            tipId: tip.id,
                                            userId: '', // TODO: Get from auth
                                          ),
                                        );
                                  },
                                ),
                              ),

                        const SizedBox(height: 80), // Space for FAB
                      ]),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSubmitTipDialog(context),
        backgroundColor: AppColors.richGold,
        icon: const Icon(
          Icons.add,
          color: AppColors.deepBlack,
        ),
        label: const Text(
          'Share a Tip',
          style: TextStyle(
            color: AppColors.deepBlack,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDailyCulturalHint() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.richGold.withValues(alpha: 0.2),
            AppColors.backgroundCard,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.richGold.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.richGold.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.tips_and_updates,
              color: AppColors.richGold,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Cultural Insight',
                  style: TextStyle(
                    color: AppColors.richGold,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'In Japan, it is customary to bow when greeting someone. '
                  'The deeper the bow, the more respect you show.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title, {
    IconData? icon,
    VoidCallback? onViewAll,
  }) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: AppColors.richGold, size: 20),
          const SizedBox(width: 8),
        ],
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        if (onViewAll != null)
          GestureDetector(
            onTap: onViewAll,
            child: const Text(
              'View All',
              style: TextStyle(
                color: AppColors.richGold,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDatingEtiquettePreview(CulturalExchangeState state) {
    final countries = state.availableCountries.take(6).toList();

    if (countries.isEmpty) {
      return Container(
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.divider,
            width: 0.5,
          ),
        ),
        child: const Center(
          child: Text(
            'Loading countries...',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: countries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _navigateToDatingEtiquette(
              context,
              initialCountry: countries[index],
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.richGold.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: Center(
                child: Text(
                  countries[index],
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyTips() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.divider,
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: AppColors.richGold.withValues(alpha: 0.5),
            size: 48,
          ),
          const SizedBox(height: 12),
          const Text(
            'No tips yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Be the first to share a cultural tip!',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToSpotlightDetail(
    BuildContext context,
    CountrySpotlight spotlight,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CountrySpotlightScreen(spotlight: spotlight),
      ),
    );
  }

  void _navigateToDatingEtiquette(
    BuildContext context, {
    String? initialCountry,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<CulturalExchangeBloc>(),
          child: DatingEtiquetteScreen(
            initialCountry: initialCountry,
          ),
        ),
      ),
    );
  }

  void _showSubmitTipDialog(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final countryController = TextEditingController();
    TipCategory selectedCategory = TipCategory.customs;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        const Icon(
                          Icons.lightbulb,
                          color: AppColors.richGold,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Share a Cultural Tip',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Country field
                    _buildInputField(
                      controller: countryController,
                      label: 'Country',
                      hint: 'e.g., Japan, Brazil, France',
                    ),
                    const SizedBox(height: 12),

                    // Category selector
                    const Text(
                      'Category',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: TipCategory.values.map((cat) {
                        final isSelected = cat == selectedCategory;
                        return GestureDetector(
                          onTap: () {
                            setModalState(() => selectedCategory = cat);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.richGold.withValues(alpha: 0.2)
                                  : AppColors.backgroundInput,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.richGold
                                    : AppColors.divider,
                                width: isSelected ? 1 : 0.5,
                              ),
                            ),
                            child: Text(
                              '${cat.emoji} ${cat.displayName}',
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.richGold
                                    : AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    // Title field
                    _buildInputField(
                      controller: titleController,
                      label: 'Title',
                      hint: 'Give your tip a catchy title',
                    ),
                    const SizedBox(height: 12),

                    // Content field
                    _buildInputField(
                      controller: contentController,
                      label: 'Your Tip',
                      hint: 'Share your cultural knowledge...',
                      maxLines: 4,
                    ),
                    const SizedBox(height: 20),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (titleController.text.isNotEmpty &&
                              contentController.text.isNotEmpty &&
                              countryController.text.isNotEmpty) {
                            final tip = CulturalTip(
                              id: '',
                              userId: '', // TODO: Get from auth
                              userDisplayName: 'You', // TODO: Get from profile
                              country: countryController.text.trim(),
                              title: titleController.text.trim(),
                              content: contentController.text.trim(),
                              category: selectedCategory,
                              createdAt: DateTime.now(),
                            );
                            context
                                .read<CulturalExchangeBloc>()
                                .add(SubmitCulturalTip(tip));
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.richGold,
                          foregroundColor: AppColors.deepBlack,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Submit Tip',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 14,
            ),
            filled: true,
            fillColor: AppColors.backgroundInput,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: AppColors.divider,
                width: 0.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: AppColors.divider,
                width: 0.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.richGold,
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
