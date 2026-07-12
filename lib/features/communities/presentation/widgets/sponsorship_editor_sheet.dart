import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/entities/community.dart';

/// Result returned by [SponsorshipEditorSheet].
class SponsorshipResult {
  const SponsorshipResult({required this.isSponsored, this.pinnedPromo});

  final bool isSponsored;
  final PinnedPromo? pinnedPromo;
}

/// Bottom-sheet editor a Platinum business uses to mark a community as
/// sponsored and set/edit the pinned promo.
///
/// Reused by both the create-community flow and the community-detail
/// "Edit sponsorship & promo" action. Returns a [SponsorshipResult] (or null
/// if dismissed without saving).
class SponsorshipEditorSheet extends StatefulWidget {
  const SponsorshipEditorSheet({
    super.key,
    this.initialSponsored = false,
    this.initialPromo,
  });

  final bool initialSponsored;
  final PinnedPromo? initialPromo;

  static Future<SponsorshipResult?> show(
    BuildContext context, {
    bool initialSponsored = false,
    PinnedPromo? initialPromo,
  }) {
    return showModalBottomSheet<SponsorshipResult>(
      context: context,
      backgroundColor: AppColors.backgroundDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusL),
        ),
      ),
      builder: (_) => SponsorshipEditorSheet(
        initialSponsored: initialSponsored,
        initialPromo: initialPromo,
      ),
    );
  }

  @override
  State<SponsorshipEditorSheet> createState() => _SponsorshipEditorSheetState();
}

class _SponsorshipEditorSheetState extends State<SponsorshipEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late final TextEditingController _imageController;
  late final TextEditingController _eventIdController;
  late final TextEditingController _linkUrlController;

  bool _isSponsored = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _isSponsored = widget.initialSponsored;
    final p = widget.initialPromo;
    _titleController = TextEditingController(text: p?.title ?? '');
    _bodyController = TextEditingController(text: p?.body ?? '');
    _imageController = TextEditingController(text: p?.imageUrl ?? '');
    _eventIdController = TextEditingController(text: p?.linkEventId ?? '');
    _linkUrlController = TextEditingController(text: p?.linkUrl ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _imageController.dispose();
    _eventIdController.dispose();
    _linkUrlController.dispose();
    super.dispose();
  }

  void _save() {
    final l10n = AppLocalizations.of(context)!;

    PinnedPromo? promo;
    if (_isSponsored) {
      final title = _titleController.text.trim();
      final body = _bodyController.text.trim();
      if (title.isEmpty) {
        setState(() => _error = l10n.communitiesPromoTitleRequired);
        return;
      }
      String? nullIfEmpty(String v) => v.trim().isEmpty ? null : v.trim();
      promo = PinnedPromo(
        title: title,
        body: body,
        imageUrl: nullIfEmpty(_imageController.text),
        linkEventId: nullIfEmpty(_eventIdController.text),
        linkUrl: nullIfEmpty(_linkUrlController.text),
      );
    }

    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(
      SponsorshipResult(isSponsored: _isSponsored, pinnedPromo: promo),
    );
  }

  void _removePromo() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(
      const SponsorshipResult(isSponsored: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
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
                    const Icon(Icons.workspace_premium,
                        color: AppColors.richGold, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.communitiesEditSponsorship,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Sponsored toggle
                Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.communitiesMarkAsSponsored,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.communitiesSponsorSubtitle,
                              style: const TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isSponsored,
                        onChanged: (v) => setState(() => _isSponsored = v),
                        activeThumbColor: AppColors.richGold,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingL),

                if (_isSponsored) ...[
                  _label(l10n.communitiesPromoTitleLabel),
                  _field(
                    controller: _titleController,
                    hint: l10n.communitiesPromoTitleHint,
                  ),
                  const SizedBox(height: AppDimensions.paddingM),

                  _label(l10n.communitiesPromoBodyLabel),
                  _field(
                    controller: _bodyController,
                    hint: l10n.communitiesPromoBodyHint,
                    maxLines: 3,
                  ),
                  const SizedBox(height: AppDimensions.paddingM),

                  _label(l10n.communitiesPromoImageLabel),
                  _field(
                    controller: _imageController,
                    hint: l10n.communitiesPromoImageLabel,
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: AppDimensions.paddingM),

                  _label(l10n.communitiesPromoLinkEventLabel),
                  _field(
                    controller: _eventIdController,
                    hint: l10n.communitiesPromoLinkEventLabel,
                  ),
                  const SizedBox(height: AppDimensions.paddingM),

                  _label(l10n.communitiesPromoLinkUrlLabel),
                  _field(
                    controller: _linkUrlController,
                    hint: l10n.communitiesPromoLinkUrlLabel,
                    keyboardType: TextInputType.url,
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: AppColors.errorRed,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: AppDimensions.paddingL),

                // Save
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.richGold,
                      foregroundColor: AppColors.deepBlack,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusFull),
                      ),
                    ),
                    child: Text(
                      l10n.communitiesSaveSponsorship,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (widget.initialPromo != null) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _removePromo,
                      child: Text(
                        l10n.communitiesRemovePromo,
                        style: const TextStyle(color: AppColors.errorRed),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppDimensions.paddingL),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textTertiary),
        filled: true,
        fillColor: AppColors.backgroundInput,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingM,
          vertical: AppDimensions.paddingM,
        ),
      ),
    );
  }
}
