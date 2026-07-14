import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/entities/community.dart';

/// Result of the rules/resources editor.
class RulesEditorResult {
  const RulesEditorResult({this.rules, this.links = const []});
  final String? rules;
  final List<CommunityLink> links;
}

/// Owner/admin editor for a community's pinned Rules & Resources.
class RulesEditorSheet extends StatefulWidget {
  const RulesEditorSheet({
    super.key,
    this.initialRules,
    this.initialLinks = const [],
  });

  final String? initialRules;
  final List<CommunityLink> initialLinks;

  static Future<RulesEditorResult?> show(
    BuildContext context, {
    String? initialRules,
    List<CommunityLink> initialLinks = const [],
  }) {
    return showModalBottomSheet<RulesEditorResult>(
      context: context,
      backgroundColor: AppColors.backgroundDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusL)),
      ),
      builder: (_) => RulesEditorSheet(
        initialRules: initialRules,
        initialLinks: initialLinks,
      ),
    );
  }

  @override
  State<RulesEditorSheet> createState() => _RulesEditorSheetState();
}

class _RulesEditorSheetState extends State<RulesEditorSheet> {
  late final TextEditingController _rulesController;
  // Parallel controllers for each resource link row.
  final List<TextEditingController> _titleControllers = [];
  final List<TextEditingController> _urlControllers = [];

  @override
  void initState() {
    super.initState();
    _rulesController = TextEditingController(text: widget.initialRules ?? '');
    for (final link in widget.initialLinks) {
      _titleControllers.add(TextEditingController(text: link.title));
      _urlControllers.add(TextEditingController(text: link.url));
    }
  }

  @override
  void dispose() {
    _rulesController.dispose();
    for (final c in _titleControllers) {
      c.dispose();
    }
    for (final c in _urlControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addLinkRow() {
    setState(() {
      _titleControllers.add(TextEditingController());
      _urlControllers.add(TextEditingController());
    });
  }

  void _removeLinkRow(int index) {
    setState(() {
      _titleControllers.removeAt(index).dispose();
      _urlControllers.removeAt(index).dispose();
    });
  }

  void _save() {
    final rules = _rulesController.text.trim();
    final links = <CommunityLink>[];
    for (var i = 0; i < _titleControllers.length; i++) {
      final title = _titleControllers[i].text.trim();
      final url = _urlControllers[i].text.trim();
      if (title.isNotEmpty && url.isNotEmpty) {
        links.add(CommunityLink(title: title, url: url));
      }
    }
    Navigator.of(context).pop(
      RulesEditorResult(rules: rules.isEmpty ? null : rules, links: links),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DraggableScrollableSheet(
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
                  const Icon(Icons.menu_book_outlined,
                      color: AppColors.richGold),
                  const SizedBox(width: 10),
                  Text(
                    l10n.communitiesRulesResourcesTitle,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _label(l10n.communitiesRulesLabel),
              const SizedBox(height: 8),
              TextField(
                controller: _rulesController,
                maxLines: 6,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _fieldDecoration(l10n.communitiesRulesHint),
              ),
              const SizedBox(height: 24),
              _label(l10n.communitiesResourcesLabel),
              const SizedBox(height: 8),
              for (var i = 0; i < _titleControllers.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _titleControllers[i],
                          style:
                              const TextStyle(color: AppColors.textPrimary),
                          decoration: _fieldDecoration(
                              l10n.communitiesResourceTitleHint),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _urlControllers[i],
                          keyboardType: TextInputType.url,
                          style:
                              const TextStyle(color: AppColors.textPrimary),
                          decoration:
                              _fieldDecoration(l10n.communitiesResourceUrlHint),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: AppColors.errorRed),
                        onPressed: () => _removeLinkRow(i),
                      ),
                    ],
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addLinkRow,
                  icon: const Icon(Icons.add, color: AppColors.richGold),
                  label: Text(
                    l10n.communitiesAddResource,
                    style: const TextStyle(color: AppColors.richGold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
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
                    l10n.communitiesSaveLabel,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      );

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
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
      );
}
