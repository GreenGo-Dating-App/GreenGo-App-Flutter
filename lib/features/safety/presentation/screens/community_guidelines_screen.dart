import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_glass.dart';
import '../../../../generated/app_localizations.dart';
import '../widgets/guideline_principle_card.dart';

/// Community Guidelines — a warm, welcoming glass experience about respectful
/// cross-cultural exchange (this is NOT a dating app). Shown ONCE on first app
/// open (persisted in SharedPreferences) and also reachable from Help/Settings.
///
/// The guidelines are presented as a hero header plus a set of icon-led
/// principle cards that cascade into view (respecting reduced-motion), with a
/// premium gold CTA pinned to the bottom in first-run mode.
class CommunityGuidelinesScreen extends StatefulWidget {

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
  State<CommunityGuidelinesScreen> createState() =>
      _CommunityGuidelinesScreenState();
}

class _CommunityGuidelinesScreenState extends State<CommunityGuidelinesScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Kick off the staggered entrance once (skip when reduced-motion is on).
    if (_controller.status == AnimationStatus.dismissed) {
      if (MediaQuery.of(context).disableAnimations) {
        _controller.value = 1.0;
      } else {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_Principle> _principles(AppLocalizations l10n) => <_Principle>[
        _Principle(
          icon: Icons.public,
          title: l10n.guidelinesWelcomeTitle,
          description: l10n.guidelinesWelcomeDesc,
        ),
        _Principle(
          icon: Icons.favorite_rounded,
          title: l10n.guidelinesRespectTitle,
          description: l10n.guidelinesRespectDesc,
        ),
        _Principle(
          icon: Icons.verified_user_rounded,
          title: l10n.guidelinesAuthenticTitle,
          description: l10n.guidelinesAuthenticDesc,
        ),
        _Principle(
          icon: Icons.shield_rounded,
          title: l10n.guidelinesSafetyTitle,
          description: l10n.guidelinesSafetyDesc,
        ),
        _Principle(
          icon: Icons.block_rounded,
          title: l10n.guidelinesNoSpamTitle,
          description: l10n.guidelinesNoSpamDesc,
        ),
        _Principle(
          icon: Icons.flag_rounded,
          title: l10n.guidelinesReportTitle,
          description: l10n.guidelinesReportDesc,
        ),
      ];

  void _onAccept() {
    HapticFeedback.mediumImpact();
    widget.onAccepted?.call();
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final principles = _principles(l10n);

    // Total staggered items = hero + intro + N cards, used to spread timing.
    final itemCount = principles.length + 2;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.darkGradient),
        child: Stack(
          children: [
            // Soft gold ambient glow behind the hero for depth.
            const Positioned(
              top: -80,
              left: 0,
              right: 0,
              child: _AmbientGoldGlow(),
            ),
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StaggeredEntrance(
                            animation: _controller,
                            index: 0,
                            itemCount: itemCount,
                            reduceMotion: reduceMotion,
                            child: _Hero(l10n: l10n),
                          ),
                          const SizedBox(height: 20),
                          StaggeredEntrance(
                            animation: _controller,
                            index: 1,
                            itemCount: itemCount,
                            reduceMotion: reduceMotion,
                            child: _IntroCard(text: l10n.guidelinesBody),
                          ),
                          const SizedBox(height: 16),
                          for (int i = 0; i < principles.length; i++) ...[
                            StaggeredEntrance(
                              animation: _controller,
                              index: i + 2,
                              itemCount: itemCount,
                              reduceMotion: reduceMotion,
                              child: GuidelinePrincipleCard(
                                icon: principles[i].icon,
                                title: principles[i].title,
                                description: principles[i].description,
                              ),
                            ),
                            if (i != principles.length - 1)
                              const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ),
                  ),
                  _BottomAction(
                    label: l10n.guidelinesAccept,
                    showAccept: widget.showAccept,
                    onAccept: _onAccept,
                    onClose: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Principle {
  const _Principle({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

/// Hero header: glowing gold badge + welcoming title & subtitle.
class _Hero extends StatelessWidget {
  const _Hero({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 8),
        Center(
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.richGold.withOpacity(0.45),
                  blurRadius: 28,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: const Icon(
              Icons.diversity_3,
              color: AppColors.deepBlack,
              size: 42,
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          l10n.guidelinesTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 27,
            fontWeight: FontWeight.bold,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.guidelinesSubtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.richGold.withOpacity(0.9),
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

/// Intro paragraph rendered inside a frosted glass card.
class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppGlass.radiusCard);
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppGlass.blurSigma,
            sigmaY: AppGlass.blurSigma,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppGlass.surface,
              borderRadius: radius,
              border: Border.all(color: AppGlass.borderGold),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.0),
                ],
                stops: const [0.0, 0.4],
              ),
            ),
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14.5,
                height: 1.6,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Soft, blurred gold radial glow used as an ambient backdrop behind the hero.
class _AmbientGoldGlow extends StatelessWidget {
  const _AmbientGoldGlow();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        height: 260,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 0.9,
            colors: [
              AppColors.richGold.withOpacity(0.16),
              AppColors.richGold.withOpacity(0.0),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom pinned action area. In first-run mode this is the premium gold
/// "I agree" CTA (with a gold glow); otherwise a subtle "close" outline button.
class _BottomAction extends StatelessWidget {
  const _BottomAction({
    required this.label,
    required this.showAccept,
    required this.onAccept,
    required this.onClose,
  });

  final String label;
  final bool showAccept;
  final VoidCallback onAccept;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    if (!showAccept) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onClose,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.richGold,
              side: BorderSide(color: AppColors.richGold.withOpacity(0.5)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(label),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppGlass.goldGlow,
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onAccept,
            icon: const Icon(Icons.check_circle_rounded, size: 20),
            label: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.richGold,
              foregroundColor: AppColors.deepBlack,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
