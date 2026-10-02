import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';

/// Splash screen shown briefly after login before entering the main app.
/// Displays the GreenGo logo centered on a dark background. Business accounts
/// additionally get a small gold "BUSINESS" label beneath the logo.
class PostLoginSplashScreen extends StatefulWidget {

  const PostLoginSplashScreen({
    required this.onComplete, super.key,
    this.ready,
  });
  final VoidCallback onComplete;

  /// Completes when the post-login preload is done. The splash then ends
  /// early (never sooner than [minDuration]); without it, or if it takes
  /// longer, the splash runs its full length (the old fixed 2.2s).
  final Future<void>? ready;

  /// Shortest the splash may run when [ready] completes quickly.
  static const Duration minDuration = Duration(milliseconds: 1200);

  @override
  State<PostLoginSplashScreen> createState() => _PostLoginSplashScreenState();
}

class _PostLoginSplashScreenState extends State<PostLoginSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  /// Cached in SharedPreferences by the auth wrapper when the profile loads.
  bool _isBusiness = false;

  @override
  void initState() {
    super.initState();
    _loadBusinessFlag();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_controller);

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.8, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.05)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
    ]).animate(_controller);

    _controller.addListener(() {
      setState(() {});
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });

    _controller.forward();

    widget.ready?.then((_) {
      _ready = true;
      _maybeFinishEarly();
    }, onError: (Object _) {/* preload is best-effort: run the full length */});
    _controller.addListener(_maybeFinishEarly);
  }

  // Timeline (fraction of the 2.2s controller): fade-in 0-0.3, hold
  // 0.3-0.7, fade-out 0.7-1.0. During the hold opacity and scale are
  // constant, so skipping part of it is invisible.
  static const double _fadeInEnd = 0.3;
  static const double _fadeOutStart = 0.7;

  bool _ready = false;
  bool _finishingEarly = false;

  /// Once the preload is done and the logo has faded in, skips the rest of
  /// the hold and fades out, keeping the total at least
  /// [PostLoginSplashScreen.minDuration].
  void _maybeFinishEarly() {
    if (!_ready || _finishingEarly || !mounted) return;
    final v = _controller.value;
    if (v < _fadeInEnd || v >= _fadeOutStart) return;
    _finishingEarly = true;
    final total = _controller.duration!;
    final elapsed = total * v;
    final fadeOut = total * (1 - _fadeOutStart);
    final minRest = PostLoginSplashScreen.minDuration - elapsed;
    // Fade out over the usual time, or longer if needed to reach the minimum.
    final rest = minRest > fadeOut ? minRest : fadeOut;
    _controller
      ..value = _fadeOutStart
      ..animateTo(1, duration: rest);
  }

  Future<void> _loadBusinessFlag() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isBusiness = prefs.getBool('is_business_account') ?? false;
      if (mounted && isBusiness) {
        setState(() => _isBusiness = true);
      }
    } catch (_) {
      // Non-fatal: simply omit the label if the flag can't be read.
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/greengo_logo.png',
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                ),
                if (_isBusiness) ...[
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context)!.splashBusinessLabel,
                    style: const TextStyle(
                      color: AppColors.richGold,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
