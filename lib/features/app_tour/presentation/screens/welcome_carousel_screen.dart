import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../tour_environment.dart';

/// Shows the 4-slide welcome carousel once per device before sign-up/login,
/// then [child] (the login screen).
///
/// Never shown on a web deep link that lands on a specific page (e.g.
/// `/e/{id}`, `/guest`, `?link=/u/{id}`): those visitors came for that page.
class WelcomeGate extends StatefulWidget {
  const WelcomeGate({required this.child, this.launchUri, super.key});

  final Widget child;

  /// The page URL on web (defaults to [Uri.base]); injectable for tests.
  final Uri? launchUri;

  /// Per-device flag.
  static const String prefKey = 'welcome_seen';

  /// True when [uri] is a web deep link to a specific page.
  static bool isWebDeepLink(Uri uri) {
    if (uri.queryParameters.containsKey('link')) return true;
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return false;
    return !(segments.length == 1 && segments.first == 'index.html');
  }

  @override
  State<WelcomeGate> createState() => _WelcomeGateState();
}

class _WelcomeGateState extends State<WelcomeGate> {
  /// null while the flag loads.
  bool? _showCarousel;

  @override
  void initState() {
    super.initState();
    if (!TourEnvironment.enabled ||
        (kIsWeb && WelcomeGate.isWebDeepLink(widget.launchUri ?? Uri.base))) {
      _showCarousel = false;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    var seen = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      seen = prefs.getBool(WelcomeGate.prefKey) ?? false;
    } catch (_) {/* fail open to the login screen */}
    if (mounted) setState(() => _showCarousel = !seen);
  }

  Future<void> _done() async {
    setState(() => _showCarousel = false);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(WelcomeGate.prefKey, true);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final show = _showCarousel;
    if (show == null) {
      return const ColoredBox(color: AppColors.backgroundDark);
    }
    if (!show) return widget.child;
    return WelcomeCarouselScreen(onDone: _done);
  }
}

class _Slide {
  const _Slide(this.icon, this.badge, this.title, this.body);
  final IconData icon;
  final IconData badge;
  final String Function(AppLocalizations) title;
  final String Function(AppLocalizations) body;
}

final List<_Slide> _slides = [
  _Slide(Icons.public, Icons.people_alt_outlined, (l) => l.welcomeSlide1Title,
      (l) => l.welcomeSlide1Body),
  _Slide(Icons.chat_bubble_outline, Icons.translate,
      (l) => l.welcomeSlide2Title, (l) => l.welcomeSlide2Body),
  _Slide(Icons.event, Icons.groups_outlined, (l) => l.welcomeSlide3Title,
      (l) => l.welcomeSlide3Body),
  _Slide(Icons.shield_outlined, Icons.verified, (l) => l.welcomeSlide4Title,
      (l) => l.welcomeSlide4Body),
];

/// The carousel itself: Skip, dots, Next / "Get started" on the last slide.
class WelcomeCarouselScreen extends StatefulWidget {
  const WelcomeCarouselScreen({required this.onDone, super.key});

  final VoidCallback onDone;

  static int get slideCount => _slides.length;

  @override
  State<WelcomeCarouselScreen> createState() => _WelcomeCarouselScreenState();
}

class _WelcomeCarouselScreenState extends State<WelcomeCarouselScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next(bool reduceMotion) {
    final target = _page + 1;
    if (target >= _slides.length) {
      widget.onDone();
      return;
    }
    if (reduceMotion) {
      _controller.jumpToPage(target);
    } else {
      _controller.animateToPage(target,
          duration: const Duration(milliseconds: 320), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final last = _page == _slides.length - 1;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Visibility(
                visible: !last,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: TextButton(
                  key: const ValueKey('welcome-skip'),
                  onPressed: widget.onDone,
                  child: Text(
                    l10n.tourSkip,
                    style: const TextStyle(color: AppColors.textTertiary),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                key: const ValueKey('welcome-pages'),
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => _SlideView(
                  slide: _slides[i],
                  active: i == _page,
                  reduceMotion: reduceMotion,
                ),
              ),
            ),
            Semantics(
              label: l10n.welcomeSlideOf(_page + 1, _slides.length),
              child: ExcludeSemantics(
                child: Row(
                  key: const ValueKey('welcome-dots'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < _slides.length; i++)
                      AnimatedContainer(
                        duration: reduceMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 220),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _page ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _page
                              ? AppColors.richGold
                              : AppColors.textTertiary.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: ValueKey(last ? 'welcome-get-started' : 'welcome-next'),
                  onPressed: () => _next(reduceMotion),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.richGold,
                    foregroundColor: AppColors.deepBlack,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    last ? l10n.welcomeGetStarted : l10n.tourNext,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
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

class _SlideView extends StatelessWidget {
  const _SlideView({
    required this.slide,
    required this.active,
    required this.reduceMotion,
  });

  final _Slide slide;
  final bool active;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final art = SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glass disc with a gold rim.
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.richGold.withValues(alpha: 0.22),
                  AppColors.backgroundCard.withValues(alpha: 0.6),
                ],
              ),
              border: Border.all(
                  color: AppColors.richGold.withValues(alpha: 0.55),
                  width: 1.5),
            ),
          ),
          Icon(slide.icon, size: 84, color: AppColors.richGold),
          Positioned(
            right: 18,
            bottom: 22,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.charcoal,
                border: Border.all(color: AppColors.richGold),
              ),
              child: Icon(slide.badge, size: 26, color: AppColors.accentGold),
            ),
          ),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ExcludeSemantics(
            child: reduceMotion
                ? art
                : AnimatedScale(
                    scale: active ? 1 : 0.85,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutBack,
                    child: art,
                  ),
          ),
          const SizedBox(height: 36),
          Text(
            slide.title(l10n),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            slide.body(l10n),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
