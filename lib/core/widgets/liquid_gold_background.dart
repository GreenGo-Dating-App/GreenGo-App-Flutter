import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../constants/app_colors.dart';

/// Loads the liquid-gold fragment program. Swappable in tests.
typedef LiquidGoldProgramLoader = Future<ui.FragmentProgram> Function();

/// One molten glow: where it sits, how big it is, and its slow drift.
///
/// Mirrors the approved CSS mock: a `size`-px disc with a radial gradient to
/// transparent, `blur` px of blur, animated `translate + scale` between two
/// keyframes with `ease-in-out infinite alternate`.
@immutable
class LiquidGlowSpec {
  const LiquidGlowSpec({
    required this.anchor,
    required this.size,
    required this.blur,
    required this.color,
    required this.from,
    required this.to,
    required this.fromScale,
    required this.toScale,
    required this.period,
  });

  /// Centre as a fraction of the screen (resolved on a 390x844 phone).
  final Offset anchor;

  /// Diameter / blur in logical px on a 390x844 phone (scaled on bigger
  /// screens so the glows keep filling the window).
  final double size;
  final double blur;
  final Color color;
  final Offset from;
  final Offset to;
  final double fromScale;
  final double toScale;

  /// One leg (from → to); the drift then eases back (alternate).
  final double period;
}

/// A glow resolved for one frame, in px.
@immutable
class ResolvedGlow {
  const ResolvedGlow(this.center, this.radius, this.blur, this.color);
  final Offset center;
  final double radius;
  final double blur;
  final Color color;
}

/// Warm near-black background with three large, soft, molten-gold glows that
/// drift slowly and independently (26 s / 32 s / 38 s, ease-in-out,
/// alternate) — the "Liquid Gold" auth background (login, waiting).
///
/// * Renders with `shaders/liquid_gold.frag` when the GPU/back-end supports
///   it, otherwise with [LiquidGoldFallbackPainter] (pre-softened radial
///   gradients, no MaskFilter) — shader loading is wrapped in try/catch, so a
///   failing web/old GPU just gets the Dart fallback. Both paths use the same
///   Dart-side motion ([LiquidGoldBackground.resolve]).
/// * Cheap: the animated layer sits in its own [RepaintBoundary] and is driven
///   by a [ValueNotifier] (repaint only — the [child] is never rebuilt per
///   frame). Ticks are throttled to ~30 fps, plenty for a 26–38 s drift.
/// * Pauses when the app is backgrounded (lifecycle) and when the route is not
///   visible (the ticker honours [TickerMode], which Navigator/Overlay turn off
///   for covered routes).
/// * Honours reduced motion ([MediaQuery.disableAnimations]) → static frame.
class LiquidGoldBackground extends StatefulWidget {
  const LiquidGoldBackground({
    required this.child,
    super.key,
    this.programLoader,
    this.useShader = true,
  });

  final Widget child;

  /// Override the shader loader (tests). Defaults to loading the bundled
  /// `shaders/liquid_gold.frag`.
  final LiquidGoldProgramLoader? programLoader;

  /// Set false to force the pure-Dart fallback.
  final bool useShader;

  static const String shaderAsset = 'shaders/liquid_gold.frag';

  static const Color base = AppColors.liquidBase;

  /// The three glows of the approved mock (phone frame 390x844).
  static const List<LiquidGlowSpec> glows = [
    LiquidGlowSpec(
      anchor: Offset(100 / 390, 200 / 844),
      size: 320,
      blur: 30,
      color: Color(0x8CE9C46A), // rgba(233,196,106,.55)
      from: Offset(-30, -20),
      to: Offset(60, 90),
      fromScale: 1.0,
      toScale: 1.25,
      period: 26,
    ),
    LiquidGlowSpec(
      anchor: Offset(300 / 390, 480 / 844),
      size: 360,
      blur: 36,
      color: Color(0x73C98C28), // rgba(201,140,40,.45)
      from: Offset(40, 30),
      to: Offset(-70, -60),
      fromScale: 1.1,
      toScale: 0.9,
      period: 32,
    ),
    LiquidGlowSpec(
      anchor: Offset(190 / 390, 814 / 844),
      size: 300,
      blur: 40,
      color: Color(0x66A06E1E), // rgba(160,110,30,.40)
      from: Offset.zero,
      to: Offset(-40, 80),
      fromScale: 0.9,
      toScale: 1.2,
      period: 38,
    ),
  ];

  /// Glow geometry at [seconds] for a [size] canvas. Pure, so the shader
  /// and the fallback painter (and tests) agree exactly.
  static List<ResolvedGlow> resolve(Size size, double seconds) {
    // The mock is a 390x844 phone; on bigger windows grow everything with the
    // area so a desktop browser is not a black field with three dots.
    final scale = math
        .sqrt((size.width * size.height) / (390 * 844))
        .clamp(0.85, 2.2)
        .toDouble();
    return [
      for (final g in glows)
        () {
          // ease-in-out + alternate == half a cosine wave per leg.
          final e = 0.5 - 0.5 * math.cos(math.pi * seconds / g.period);
          final t = Offset.lerp(g.from, g.to, e)! * scale;
          final s = ui.lerpDouble(g.fromScale, g.toScale, e)! * scale;
          return ResolvedGlow(
            Offset(g.anchor.dx * size.width, g.anchor.dy * size.height) + t,
            g.size / 2 * s,
            g.blur * s,
            g.color,
          );
        }(),
    ];
  }

  /// Process-wide cache: the default program is compiled once per app run.
  static Future<ui.FragmentProgram?>? _defaultProgram;

  static Future<ui.FragmentProgram?> _loadDefault() {
    return _defaultProgram ??= () async {
      try {
        return await ui.FragmentProgram.fromAsset(shaderAsset);
      } catch (e) {
        debugPrint('LiquidGoldBackground: shader unavailable, fallback ($e)');
        return null;
      }
    }();
  }

  @visibleForTesting
  static void debugResetProgramCache() => _defaultProgram = null;

  @override
  State<LiquidGoldBackground> createState() => LiquidGoldBackgroundState();
}

@visibleForTesting
class LiquidGoldBackgroundState extends State<LiquidGoldBackground>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  /// Seconds of drift. Drives repaint without rebuilding anything.
  final ValueNotifier<double> _time = ValueNotifier<double>(0);
  late final Ticker _ticker = createTicker(_onTick);

  ui.FragmentShader? _shader;
  bool _reducedMotion = false;
  bool _appActive = true;

  Duration _accumulated = Duration.zero; // time banked before last pause
  Duration _lastPainted = Duration.zero;
  Duration _lastElapsed = Duration.zero; // ticker time of the latest tick

  /// LCM of the three alternate cycles (52, 64, 76 s): the whole picture
  /// repeats after this, so wrapping here keeps doubles small and seamless.
  static const int _loopMicros = 15808 * Duration.microsecondsPerSecond;

  /// True once a usable fragment shader is active (exposed for tests).
  bool get usingShader => _shader != null;

  /// True while the drift animation is ticking (exposed for tests).
  bool get isAnimating => _ticker.isActive;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final state = WidgetsBinding.instance.lifecycleState;
    _appActive = state == null || state == AppLifecycleState.resumed;
    if (widget.useShader) _loadShader();
  }

  Future<void> _loadShader() async {
    ui.FragmentProgram? program;
    try {
      program = widget.programLoader != null
          ? await widget.programLoader!()
          : await LiquidGoldBackground._loadDefault();
    } catch (e) {
      debugPrint('LiquidGoldBackground: shader load failed, fallback ($e)');
      program = null;
    }
    if (!mounted || program == null) return;
    try {
      final shader = program.fragmentShader();
      setState(() => _shader = shader);
    } catch (e) {
      debugPrint('LiquidGoldBackground: shader init failed, fallback ($e)');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _syncTicker();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appActive = state == AppLifecycleState.resumed;
    _syncTicker();
  }

  void _syncTicker() {
    final shouldRun = _appActive && !_reducedMotion;
    if (shouldRun && !_ticker.isActive) {
      _lastPainted = Duration.zero;
      _lastElapsed = Duration.zero;
      _ticker.start();
    } else if (!shouldRun && _ticker.isActive) {
      // Bank the elapsed time so resuming continues the drift seamlessly.
      _accumulated += _lastElapsed;
      _ticker.stop();
    }
    if (_reducedMotion) _time.value = 0;
  }

  void _onTick(Duration elapsed) {
    _lastElapsed = elapsed;
    // ~30 fps is indistinguishable for a 26–38 s drift and halves GPU work.
    if (elapsed - _lastPainted < const Duration(milliseconds: 33)) return;
    _lastPainted = elapsed;
    final total = (_accumulated + elapsed).inMicroseconds % _loopMicros;
    _time.value = total / 1e6;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _shader?.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CustomPainter painter = _shader != null
        ? _LiquidGoldShaderPainter(_shader!, _time)
        : LiquidGoldFallbackPainter(time: _time);

    return ColoredBox(
      color: LiquidGoldBackground.base,
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: CustomPaint(
              key: const ValueKey('liquid_gold_background_layer'),
              painter: painter,
              isComplex: true,
              willChange: !_reducedMotion,
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _LiquidGoldShaderPainter extends CustomPainter {
  _LiquidGoldShaderPainter(this.shader, this.time) : super(repaint: time);

  final ui.FragmentShader shader;
  final ValueListenable<double> time;

  @override
  void paint(Canvas canvas, Size size) {
    final glows = LiquidGoldBackground.resolve(size, time.value);
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height);
    var i = 2;
    for (final g in glows) {
      shader
        ..setFloat(i++, g.center.dx)
        ..setFloat(i++, g.center.dy)
        ..setFloat(i++, g.radius)
        ..setFloat(i++, g.blur);
    }
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_LiquidGoldShaderPainter old) =>
      old.shader != shader || old.time != time;
}

/// Pure-Dart liquid gold: the base colour plus three radial gradients whose
/// stops follow the same "ramp softened by blur" profile as the shader.
/// A gradient fading to transparent is already blurred, so no MaskFilter
/// (expensive on web) is needed.
class LiquidGoldFallbackPainter extends CustomPainter {
  LiquidGoldFallbackPainter({required this.time}) : super(repaint: time);

  final ValueListenable<double> time;

  static const List<double> _stops = [0.0, 0.2, 0.4, 0.6, 0.8, 1.0];

  /// Same falloff as `glow()` in liquid_gold.frag, sampled at [_stops].
  static double _profile(double d) {
    final x = (1 - d).clamp(0.0, 1.0);
    return 0.92 * x * x * (3 - 2 * x);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = LiquidGoldBackground.base);
    for (final g in LiquidGoldBackground.resolve(size, time.value)) {
      final reach = g.radius + 0.9 * g.blur;
      final a = g.color.a;
      canvas.drawCircle(
        g.center,
        reach,
        Paint()
          ..shader = RadialGradient(
            colors: [
              for (final s in _stops) g.color.withValues(alpha: a * _profile(s)),
            ],
            stops: _stops,
          ).createShader(Rect.fromCircle(center: g.center, radius: reach)),
      );
    }
  }

  @override
  bool shouldRepaint(LiquidGoldFallbackPainter old) => old.time != time;
}
