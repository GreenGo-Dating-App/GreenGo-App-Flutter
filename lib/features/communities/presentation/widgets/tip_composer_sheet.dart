import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/entities/community_message.dart';

/// Result of the tip composer: the chosen tip type + the text.
class TipComposerResult {
  const TipComposerResult({required this.type, required this.text});
  final CommunityMessageType type;
  final String text;
}

/// Composer for adding a community Tip (language tip / cultural fact / city tip).
/// Any member can add as many as they want.
class TipComposerSheet extends StatefulWidget {
  const TipComposerSheet({super.key, this.allowCityTip = false});

  final bool allowCityTip;

  static Future<TipComposerResult?> show(
    BuildContext context, {
    bool allowCityTip = false,
  }) {
    return showModalBottomSheet<TipComposerResult>(
      context: context,
      backgroundColor: AppColors.backgroundDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusL)),
      ),
      builder: (_) => TipComposerSheet(allowCityTip: allowCityTip),
    );
  }

  @override
  State<TipComposerSheet> createState() => _TipComposerSheetState();
}

class _TipComposerSheetState extends State<TipComposerSheet> {
  final _controller = TextEditingController();
  CommunityMessageType _type = CommunityMessageType.languageTip;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final types = <(CommunityMessageType, String)>[
      (CommunityMessageType.languageTip, l10n.communitiesLanguageTipLabel),
      (CommunityMessageType.culturalFact, l10n.communitiesCulturalFactLabel),
      if (widget.allowCityTip)
        (CommunityMessageType.cityTip, l10n.communitiesCityTipLabel),
    ];

    return Padding(
      padding: EdgeInsets.only(
        left: AppDimensions.paddingL,
        right: AppDimensions.paddingL,
        top: AppDimensions.paddingL,
        bottom:
            MediaQuery.of(context).viewInsets.bottom + AppDimensions.paddingL,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: AppColors.richGold),
              const SizedBox(width: 10),
              Text(
                l10n.communitiesAddTip,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              for (final (t, label) in types)
                GestureDetector(
                  onTap: () => setState(() => _type = t),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _type == t
                          ? AppColors.richGold
                          : AppColors.backgroundCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            _type == t ? AppColors.richGold : AppColors.divider,
                      ),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: _type == t
                            ? AppColors.deepBlack
                            : AppColors.textSecondary,
                        fontWeight:
                            _type == t ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: 4,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: l10n.communitiesTipHint,
              hintStyle: const TextStyle(color: AppColors.textTertiary),
              filled: true,
              fillColor: AppColors.backgroundInput,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(AppDimensions.paddingM),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final text = _controller.text.trim();
                if (text.isEmpty) return;
                Navigator.of(context)
                    .pop(TipComposerResult(type: _type, text: text));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.richGold,
                foregroundColor: AppColors.deepBlack,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
              ),
              child: Text(
                l10n.communitiesPostLabel,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
