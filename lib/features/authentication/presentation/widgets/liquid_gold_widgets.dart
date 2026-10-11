import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../core/constants/app_colors.dart';

/// The mock's entrance easing: cubic-bezier(.22,.61,.36,1).
const Curve kLiquidEase = Cubic(0.22, 0.61, 0.36, 1);

/// Staggered entrance timing (seconds), as in the approved mock:
/// logo .15 s, tagline .45 s, form .75 s, footer 1.05 s; each 1.1 s long.
const double kEntranceStep = 1.1;
const List<double> kEntranceDelays = [0.15, 0.45, 0.75, 1.05];
const Duration kEntranceTotal = Duration(milliseconds: 2150);

/// Interval of [kEntranceTotal] for entrance item [index].
Animation<double> entranceFor(AnimationController controller, int index) {
  final total = kEntranceTotal.inMicroseconds / 1e6;
  final start = kEntranceDelays[index] / total;
  final end = math.min(1.0, (kEntranceDelays[index] + kEntranceStep) / total);
  return CurvedAnimation(
    parent: controller,
    curve: Interval(start, end, curve: kLiquidEase),
  );
}

/// Fades [child] in while it rises ~18 px and (optionally) its blur clears.
/// Only this wrapper rebuilds per frame; [child] is passed through. The
/// widget structure never changes (so [child] keeps its state — focus, typed
/// text, the shimmer timer); once complete it adds no layers at all
/// (opacity 1, zero translation and a disabled filter paint straight through).
class RiseIn extends StatelessWidget {
  const RiseIn({
    required this.animation,
    required this.child,
    super.key,
    this.blur = true,
  });

  final Animation<double> animation;
  final Widget child;

  /// Clear a 6 px blur as it rises. Off for the glass card: a BackdropFilter
  /// under an ImageFiltered layer would sample an empty backdrop.
  final bool blur;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final v = animation.value.clamp(0.0, 1.0);
        final sigma = 6 * (1 - v);
        return ImageFiltered(
          enabled: blur && sigma > 0.05,
          imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - v)),
            child: Opacity(opacity: v, child: child),
          ),
        );
      },
    );
  }
}

/// Frosted glass panel: rounded 22, warm translucent fill, gold hairline,
/// backdrop blur 18. On web the blur is skipped (CanvasKit would re-blur the
/// window behind the card every animated frame, and the background is
/// already soft) and the fill is a touch denser instead.
class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.fromLTRB(20, 24, 20, 24),
    this.useBackdropBlur = !kIsWeb,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool useBackdropBlur;

  static const BorderRadius radius = BorderRadius.all(Radius.circular(22));

  @override
  Widget build(BuildContext context) {
    final panel = DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF120F0A)
            .withValues(alpha: useBackdropBlur ? 0.55 : 0.66),
        borderRadius: radius,
        border: Border.all(
          color: AppColors.liquidGoldLight.withValues(alpha: 0.22),
        ),
      ),
      child: Padding(padding: padding, child: child),
    );
    if (!useBackdropBlur) return panel;
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: panel,
      ),
    );
  }
}

/// The primary gold button's wrapper: a subtle "breathing" gold glow (box
/// shadow pulsing over 6 s) and a tiny press scale (0.98).
///
/// The glow is painted by a [CustomPainter] driven by a throttled (~30 fps)
/// ticker → repaint only, inside its own [RepaintBoundary]; the button is
/// never rebuilt by it. Static glow with reduced motion; the ticker honours
/// [TickerMode] so it stops when the route is covered.
class BreathingGoldButton extends StatefulWidget {
  const BreathingGoldButton({
    required this.child,
    super.key,
    this.borderRadius = 14,
    this.period = const Duration(seconds: 6),
  });

  final Widget child;
  final double borderRadius;
  final Duration period;

  @override
  State<BreathingGoldButton> createState() => BreathingGoldButtonState();
}

@visibleForTesting
class BreathingGoldButtonState extends State<BreathingGoldButton>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final ValueNotifier<double> _phase = ValueNotifier<double>(0);
  late final Ticker _ticker = createTicker(_onTick);
  Duration _lastPainted = Duration.zero;
  bool _reducedMotion = false;
  bool _appActive = true;
  bool _pressed = false;

  /// True while the glow is breathing (exposed for tests).
  bool get isAnimating => _ticker.isActive;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final state = WidgetsBinding.instance.lifecycleState;
    _appActive = state == null || state == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appActive = state == AppLifecycleState.resumed;
    _sync();
  }

  void _sync() {
    final run = _appActive && !_reducedMotion;
    if (run && !_ticker.isActive) {
      _lastPainted = Duration.zero;
      _ticker.start();
    } else if (!run && _ticker.isActive) {
      _ticker.stop();
    }
    if (_reducedMotion) _phase.value = 0.35;
  }

  void _onTick(Duration elapsed) {
    if (elapsed - _lastPainted < const Duration(milliseconds: 33)) return;
    _lastPainted = elapsed;
    final p = widget.period.inMicroseconds;
    final t = (elapsed.inMicroseconds % p) / p;
    // ease-in-out 0 → 1 → 0 over one period.
    _phase.value = 0.5 - 0.5 * math.cos(2 * math.pi * t);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _phase.dispose();
    super.dispose();
  }

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 250),
        curve: kLiquidEase,
        // Outer boundary: a glow repaint never repaints the card around it.
        // Inner boundary: nor the button itself.
        child: RepaintBoundary(
          child: CustomPaint(
            key: const ValueKey('liquid_gold_button_glow'),
            painter: _GlowPainter(_phase, widget.borderRadius),
            child: RepaintBoundary(child: widget.child),
          ),
        ),
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  _GlowPainter(this.phase, this.radius) : super(repaint: phase);

  final ValueListenable<double> phase;
  final double radius;

  // 0 6px 18px rgba(233,196,106,.18)  <->  0 10px 34px rgba(233,196,106,.42)
  static final BoxShadow _calm = BoxShadow(
    color: AppColors.liquidGoldLight.withValues(alpha: 0.18),
    offset: const Offset(0, 6),
    blurRadius: 18,
  );
  static final BoxShadow _bright = BoxShadow(
    color: AppColors.liquidGoldLight.withValues(alpha: 0.42),
    offset: const Offset(0, 10),
    blurRadius: 34,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final s = BoxShadow.lerp(_calm, _bright, phase.value)!;
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).shift(s.offset),
      Radius.circular(radius),
    );
    canvas.drawRRect(rrect, s.toPaint());
  }

  @override
  bool shouldRepaint(_GlowPainter old) =>
      old.phase != phase || old.radius != radius;
}
