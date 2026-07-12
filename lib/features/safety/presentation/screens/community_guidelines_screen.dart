import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';

/// Community Guidelines — a brief, welcoming glass sheet about respectful
/// cross-cultural exchange (this is NOT a dating app). Shown ONCE on first app
/// open (persisted in SharedPreferences) and also reachable from Help/Settings.
class CommunityGuidelinesScreen extends StatelessWidget {

  const CommunityGuidelinesScreen({
    super.key,
    this.showAccept = false,
    this.onAccepted,
  });

  /// When true, renders the "Accept & Continue" gate button (first-run mode).
  /// When false, it's a plain read-only screen (Help/Settings entry).
  final bool showAccept;
  final VoidCallback? onAccepted;

  static const String _prefKey = 'has_accepted_community_guidelines';

  /// Whether the user has already accepted the guidelines.
  static Future<bool> hasAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? false;
  }

  static Future<void> _markAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, true);
  }

  /// Show the guidelines as a mandatory first-run gate if not yet accepted.
  static Future<void> showIfNeeded(BuildContext context) async {
    if (await hasAccepted()) return;
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => CommunityGuidelinesScreen(
          showAccept: true,
          onAccepted: () async {
            await _markAccepted();
          },
        ),
      ),
    );
  }

  /// Open the guidelines as a read-only screen (e.g. from Help/Settings).
  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const CommunityGuidelinesScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.darkGradient),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Center(
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            gradient: AppColors.goldGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.richGold.withOpacity(0.35),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.diversity_3,
                              color: AppColors.deepBlack, size: 38),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          l10n.guidelinesTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _GlassCard(
                        child: Text(
                          l10n.guidelinesBody,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (showAccept)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        onAccepted?.call();
                        Navigator.of(context).maybePop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.richGold,
                        foregroundColor: AppColors.deepBlack,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        l10n.guidelinesAccept,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.richGold,
                        side: BorderSide(
                            color: AppColors.richGold.withOpacity(0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(l10n.guidelinesAccept),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard.withOpacity(0.55),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.richGold.withOpacity(0.25)),
          ),
          child: child,
        ),
      ),
    );
  }
}
