import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../../coins/presentation/bloc/coin_bloc.dart';
import '../../../coins/presentation/bloc/coin_event.dart';
import '../../../coins/presentation/bloc/coin_state.dart';
import '../../domain/entities/entities.dart';
import '../bloc/language_learning_bloc.dart';

class LanguagePacksShopScreen extends StatefulWidget {
  const LanguagePacksShopScreen({super.key});

  @override
  State<LanguagePacksShopScreen> createState() =>
      _LanguagePacksShopScreenState();
}

class _LanguagePacksShopScreenState extends State<LanguagePacksShopScreen> {
  String? _selectedLanguageCode;
  String? _pendingPackId; // Pack awaiting coin deduction confirmation

  late List<LanguagePack> _allPacks;

  @override
  void initState() {
    super.initState();
    _allPacks = LanguagePack.availablePacks;
    context.read<LanguageLearningBloc>().add(const LoadLanguagePacks());
  }

  void _buyPack(LanguagePack pack) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() => _pendingPackId = pack.id);
    context.read<CoinBloc>().add(PurchaseFeatureWithCoins(
          userId: userId,
          featureName: 'language_pack',
          cost: pack.coinPrice,
          relatedId: pack.id,
        ));
  }

  List<String> get _uniqueLanguageCodes {
    final codes = <String>{};
    for (final pack in _allPacks) {
      codes.add(pack.languageCode);
    }
    return codes.toList()..sort();
  }

  String _languageNameForCode(String code) {
    final pack = _allPacks.firstWhere(
      (p) => p.languageCode == code,
      orElse: () => _allPacks.first,
    );
    return pack.languageName;
  }

  List<LanguagePack> get _filteredPacks {
    // Merge static packs with bloc-loaded packs (which may have isPurchased set)
    final blocState = context.read<LanguageLearningBloc>().state;
    final blocPacks = blocState.languagePacks;

    // Use bloc packs if available (they may carry purchase state), fallback to static
    final sourcePacks = blocPacks.isNotEmpty ? blocPacks : _allPacks;

    return sourcePacks.where((pack) {
      if (_selectedLanguageCode != null &&
          pack.languageCode != _selectedLanguageCode) {
        return false;
      }
      return true;
    }).toList();
  }

  Color _parseHexColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        title: Text(
          l10n.languagePacksShopTitle,
          style: const TextStyle(
            color: AppColors.richGold,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.richGold),
      ),
      body: BlocListener<CoinBloc, CoinState>(
        listener: (context, coinState) {
          if (coinState is FeaturePurchased && _pendingPackId != null) {
            // Coin deduction succeeded — now unlock the pack
            context
                .read<LanguageLearningBloc>()
                .add(PurchaseLanguagePack(_pendingPackId!));
            _pendingPackId = null;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.learningPackPurchased),
                backgroundColor: Colors.green,
              ),
            );
          } else if (coinState is CoinError && _pendingPackId != null) {
            _pendingPackId = null;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(coinState.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<LanguageLearningBloc, LanguageLearningState>(
        builder: (context, state) {
          // Update packs from bloc if available
          final sourcePacks =
              state.languagePacks.isNotEmpty ? state.languagePacks : _allPacks;

          final filtered = sourcePacks.where((pack) {
            if (_selectedLanguageCode != null &&
                pack.languageCode != _selectedLanguageCode) {
              return false;
            }
            return true;
          }).toList();

          return Column(
            children: [
              // Language filter chips
              _buildLanguageFilterChips(l10n),
              const SizedBox(height: 4),
              // Loading indicator
              if (state.isPacksLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(
                    color: AppColors.richGold,
                    backgroundColor: Color(0xFF1A1A1A),
                  ),
                ),
              // Pack grid
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyState()
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.62,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: filtered.length,
                          padding: const EdgeInsets.only(bottom: 24, top: 8),
                          itemBuilder: (context, index) {
                            return _PackCard(
                              pack: filtered[index],
                              l10n: l10n,
                              parseHexColor: _parseHexColor,
                              onBuy: () => _buyPack(filtered[index]),
                              onTapPurchased: () {
                                Navigator.pushNamed(
                                  context,
                                  '/language-learning/learning-path',
                                  arguments: {
                                    'languageCode':
                                        filtered[index].languageCode,
                                    'packCategory':
                                        filtered[index].category.name,
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      ),
    );
  }

  Widget _buildLanguageFilterChips(AppLocalizations l10n) {
    final languageCodes = _uniqueLanguageCodes;

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          // "All" chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(l10n.allLanguagesFilter),
              selected: _selectedLanguageCode == null,
              onSelected: (_) {
                setState(() => _selectedLanguageCode = null);
              },
              selectedColor: AppColors.richGold.withValues(alpha: 0.3),
              checkmarkColor: AppColors.richGold,
              labelStyle: TextStyle(
                color: _selectedLanguageCode == null
                    ? AppColors.richGold
                    : Colors.grey[400],
                fontSize: 13,
              ),
              backgroundColor: const Color(0xFF1A1A1A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: _selectedLanguageCode == null
                      ? AppColors.richGold.withValues(alpha: 0.5)
                      : Colors.grey[700]!,
                ),
              ),
            ),
          ),
          // Language chips
          ...languageCodes.map((code) {
            final langName = _languageNameForCode(code);
            final isSelected = _selectedLanguageCode == code;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(langName),
                selected: isSelected,
                onSelected: (_) {
                  setState(() {
                    _selectedLanguageCode = isSelected ? null : code;
                  });
                },
                selectedColor: AppColors.richGold.withValues(alpha: 0.3),
                checkmarkColor: AppColors.richGold,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.richGold : Colors.grey[400],
                  fontSize: 13,
                ),
                backgroundColor: const Color(0xFF1A1A1A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.richGold.withValues(alpha: 0.5)
                        : Colors.grey[700]!,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            color: Colors.grey[600],
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.learningNoPacksFound,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _PackCard extends StatelessWidget {
  final LanguagePack pack;
  final AppLocalizations l10n;
  final Color Function(String) parseHexColor;
  final VoidCallback onBuy;
  final VoidCallback onTapPurchased;

  const _PackCard({
    required this.pack,
    required this.l10n,
    required this.parseHexColor,
    required this.onBuy,
    required this.onTapPurchased,
  });

  @override
  Widget build(BuildContext context) {
    final tierColor = parseHexColor(pack.tier.badgeColor);

    return GestureDetector(
      onTap: pack.isPurchased ? onTapPurchased : null,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: pack.isPurchased
                ? Colors.green.withValues(alpha: 0.4)
                : Colors.grey[800]!,
          ),
        ),
        child: Stack(
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // Icon emoji
                  Text(
                    pack.iconEmoji,
                    style: const TextStyle(fontSize: 40),
                  ),
                  const SizedBox(height: 10),
                  // Pack name
                  Text(
                    pack.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Language name
                  Text(
                    pack.languageName,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  // Phrase count
                  Text(
                    l10n.phrasesCount(pack.phraseCount.toString()),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Description
                  Text(
                    pack.description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  // Bottom: price or purchased label
                  if (pack.isPurchased)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        l10n.purchasedLabel,
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Coin icon and price
                        const Icon(
                          Icons.monetization_on,
                          color: AppColors.richGold,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${pack.coinPrice}',
                          style: const TextStyle(
                            color: AppColors.richGold,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Buy button
                        Flexible(
                          child: SizedBox(
                            height: 30,
                            child: ElevatedButton(
                              onPressed: onBuy,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.richGold,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 14),
                                textStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              child: Text(l10n.buyPackBtn),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            // Tier badge (top-right)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tierColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: tierColor.withValues(alpha: 0.5),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  pack.tier.displayName,
                  style: TextStyle(
                    color: tierColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
