import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../generated/app_localizations.dart';

/// Owner/admin composer for a community announcement. Returns the announcement
/// text (or null if cancelled).
class AnnouncementComposerSheet extends StatefulWidget {
  const AnnouncementComposerSheet({super.key});

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.backgroundDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusL)),
      ),
      builder: (_) => const AnnouncementComposerSheet(),
    );
  }

  @override
  State<AnnouncementComposerSheet> createState() =>
      _AnnouncementComposerSheetState();
}

class _AnnouncementComposerSheetState extends State<AnnouncementComposerSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        left: AppDimensions.paddingL,
        right: AppDimensions.paddingL,
        top: AppDimensions.paddingL,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppDimensions.paddingL,
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
              const Icon(Icons.campaign, color: AppColors.richGold),
              const SizedBox(width: 10),
              Text(
                l10n.communitiesPostAnnouncement,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: 5,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: l10n.communitiesAnnouncementHint,
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
                Navigator.of(context).pop(text.isEmpty ? null : text);
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
