import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/entities/community.dart';

/// Collapsible pinned header showing a community's Rules & Resources. Owner/
/// admins get an inline edit affordance. Renders nothing meaningful when the
/// community has no rules/resources unless [canEdit] (then it offers "Add").
class CommunityRulesHeader extends StatefulWidget {
  const CommunityRulesHeader({
    required this.community,
    required this.canEdit,
    required this.onEdit,
    super.key,
  });

  final Community community;
  final bool canEdit;
  final VoidCallback onEdit;

  @override
  State<CommunityRulesHeader> createState() => _CommunityRulesHeaderState();
}

class _CommunityRulesHeaderState extends State<CommunityRulesHeader> {
  bool _expanded = false;

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = widget.community;
    final hasContent = c.hasRulesOrResources;

    // Empty + can edit → a slim "Add rules & resources" prompt.
    if (!hasContent && widget.canEdit) {
      return Material(
        color: AppColors.backgroundCard,
        child: InkWell(
          onTap: widget.onEdit,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingM, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.menu_book_outlined,
                    color: AppColors.richGold, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.communitiesAddRulesPrompt,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                ),
                const Icon(Icons.add, color: AppColors.richGold, size: 18),
              ],
            ),
          ),
        ),
      );
    }
    if (!hasContent) return const SizedBox.shrink();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundCard,
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingM, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.menu_book_outlined,
                      color: AppColors.richGold, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.communitiesRulesResourcesTitle,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (widget.canEdit)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.edit_outlined,
                          color: AppColors.textTertiary, size: 18),
                      onPressed: widget.onEdit,
                    ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textTertiary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppDimensions.paddingM, 0, AppDimensions.paddingM, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (c.rules != null && c.rules!.trim().isNotEmpty)
                    Text(
                      c.rules!.trim(),
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.4),
                    ),
                  if (c.resourceLinks.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ...c.resourceLinks.map(
                      (link) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: InkWell(
                          onTap: () => _open(link.url),
                          child: Row(
                            children: [
                              const Icon(Icons.link,
                                  color: AppColors.richGold, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  link.title,
                                  style: const TextStyle(
                                    color: AppColors.richGold,
                                    fontSize: 13,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
