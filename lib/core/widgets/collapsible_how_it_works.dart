import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../generated/app_localizations.dart';
import '../constants/app_colors.dart';
import '../theme/app_glass.dart';

/// Collapsible "How it works" intro card shown at the top of a screen.
///
/// Expanded the first time; once the user collapses it, the collapsed state is
/// remembered on this device (SharedPreferences key
/// `how_it_works_collapsed_<id>`), so returning users only see a one-line
/// header they can reopen.
class CollapsibleHowItWorks extends StatefulWidget {
  const CollapsibleHowItWorks({
    required this.id,
    required this.steps,
    super.key,
    this.title,
    this.icon = Icons.lightbulb_outline,
    this.margin = const EdgeInsets.fromLTRB(16, 12, 16, 4),
  });

  /// Stable id of the screen (used in the preference key).
  final String id;

  /// Card title; defaults to the localized "How it works".
  final String? title;

  /// Short numbered steps (1-4 sentences).
  final List<String> steps;
  final IconData icon;
  final EdgeInsetsGeometry margin;

  static String prefsKey(String id) => 'how_it_works_collapsed_$id';

  @override
  State<CollapsibleHowItWorks> createState() => _CollapsibleHowItWorksState();
}

class _CollapsibleHowItWorksState extends State<CollapsibleHowItWorks> {
  bool _collapsed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getBool(CollapsibleHowItWorks.prefsKey(widget.id));
      if (v != null && mounted) setState(() => _collapsed = v);
    } catch (_) {
      // Preferences unavailable: keep the default (expanded).
    }
  }

  Future<void> _toggle() async {
    setState(() => _collapsed = !_collapsed);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(
        CollapsibleHowItWorks.prefsKey(widget.id),
        _collapsed,
      );
    } catch (_) {
      // Not persisted; the toggle still works for this session.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = widget.title ?? l10n.xplHowItWorks;
    return Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        color: AppGlass.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppGlass.borderGold),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: true,
            expanded: !_collapsed,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _toggle,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                child: Row(
                  children: [
                    Icon(widget.icon, color: AppColors.richGold, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      _collapsed ? Icons.expand_more : Icons.expand_less,
                      color: AppColors.textTertiary,
                      semanticLabel: _collapsed
                          ? l10n.xplShowDetails
                          : l10n.xplHideDetails,
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _collapsed
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < widget.steps.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            alignment: Alignment.center,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.richGold.withValues(alpha: 0.18),
                            ),
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                color: AppColors.richGold,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              widget.steps[i],
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
