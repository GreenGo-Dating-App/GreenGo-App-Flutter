import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../constants/app_colors.dart';

/// Loads the aurora fragment program. Swappable in tests.
typedef AuroraProgramLoader = Future<ui.FragmentProgram> Function();

/// Calm, slowly drifting dark-green → near-black "aurora" background used by
/// the auth screens (login, waiting).
///
/// * Renders with `shaders/aurora.frag` when the GPU/back-end supports it,
///   otherwise with [AuroraFallbackPainter] (a few large, low-opacity radial
///   blobs) — shader loading is wrapped in try/catch, so a failing web/old
///   GPU just gets the Dart fallback.
/// * Cheap: the animated layer sits in its own [RepaintBoundary] and is driven
///   by a [ValueNotifier] (repaint only — the [child] is never rebuilt per
///   frame). Ticks are throttled to ~30 fps, which is plenty for a 24 s loop.
/// * Pauses when the app is backgrounded (lifecycle) and when the route is not
///   visible (the ticker honours [TickerMode], which Navigator/Overlay turn off
///   for covered routes).
/// * Honours reduced motion ([MediaQuery.disableAnimations]) → static frame.
class AuroraBackground extends StatefulWidget {
  const AuroraBackground({
    required this.child,
    super.key,
    this.period = const Duration(seconds: 24),
    this.programLoader,
    this.useShader = true,
  });

  final Widget child;

  /// Length of one seamless loop.
  final Duration period;

  /// Override the shader loader (tests). Defaults to loading the bundled
  /// `shaders/aurora.frag`.
  final AuroraProgramLoader? programLoader;

  /// Set false to force the pure-Dart fallback.
  final bool useShader;

  static const String shaderAsset = 'shaders/aurora.frag';

  /// Base colours, shared by the fallback painter and the static gradient.
  static const Color base = Color(0xFF040706);
  static const Color green = Color(0xFF0B3D2E);
  static const Color emerald = Color(0xFF092E26);
  static const Color teal = Color(0xFF0A3337);

  /// Process-wide cache: the default program is compiled once per app run.
  static Future<ui.FragmentProgram?>? _defaultProgram;

  static Future<ui.FragmentProgram?> _loadDefault() {
    return _defaultProgram ??= () async {
      try {
        return await ui.FragmentProgram.fromAsset(shaderAsset);
      } catch (e) {
        debugPrint('AuroraBackground: shader unavailable, using fallback ($e)');
        return null;
      }
    }();
  }

  @visibleForTesting
  static void debugResetProgramCache() => _defaultProgram = null;

  @override
  State<AuroraBackground> createState() => AuroraBackgroundState();
}

@visibleForTesting
class AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  /// Seconds into the loop. Drives repaint without rebuilding anything.
  final ValueNotifier<double> _time = ValueNotifier<double>(0);
  late final Ticker _ticker = createTicker(_onTick);

  ui.FragmentShader? _shader;
  bool _reducedMotion = false;
  bool _appActive = true;

  Duration _accumulated = Duration.zero; // time banked before last pause
  Duration _lastPainted = Duration.zero;
  Duration _lastElapsed = Duration.zero; // ticker time of the latest tick

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
          : await AuroraBackground._loadDefault();
    } catch (e) {
      debugPrint('AuroraBackground: shader load failed, using fallback ($e)');
      program = null;
    }
    if (!mounted || program == null) return;
    try {
      final shader = program.fragmentShader();
      setState(() => _shader = shader);
    } catch (e) {
      debugPrint('AuroraBackground: shader init failed, using fallback ($e)');
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
    // ~30 fps is indistinguishable for a 24 s drift and halves GPU work.
    if (elapsed - _lastPainted < const Duration(milliseconds: 33)) return;
    _lastPainted = elapsed;
    final total = _accumulated + elapsed;
    final periodUs = widget.period.inMicroseconds;
    _time.value = (total.inMicroseconds % periodUs) / 1e6;
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
    final periodSeconds = widget.period.inMicroseconds / 1e6;
    final CustomPainter painter = _shader != null
        ? _AuroraShaderPainter(_shader!, _time, periodSeconds)
        : AuroraFallbackPainter(time: _time, periodSeconds: periodSeconds);

    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: CustomPaint(
            key: const ValueKey('aurora_background_layer'),
            painter: painter,
            isComplex: true,
            willChange: !_reducedMotion,
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _AuroraShaderPainter extends CustomPainter {
  _AuroraShaderPainter(this.shader, this.time, this.period)
      : super(repaint: time);

  final ui.FragmentShader shader;
  final ValueListenable<double> time;
  final double period;

  @override
  void paint(Canvas canvas, Size size) {
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, time.value)
      ..setFloat(3, period);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_AuroraShaderPainter old) =>
      old.shader != shader || old.period != period || old.time != time;
}

/// Pure-Dart aurora: a vertical base gradient plus a few large, very soft,
/// low-opacity radial blobs drifting on closed paths (seamless loop). Radial
/// gradients fading to transparent are already "blurred", so no MaskFilter
/// (expensive on web) is needed.
class AuroraFallbackPainter extends CustomPainter {
  AuroraFallbackPainter({required this.time, required this.periodSeconds})
      : super(repaint: time);

  final ValueListenable<double> time;
  final double periodSeconds;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF06150F), AuroraBackground.base],
          stops: [0.0, 0.85],
        ).createShader(rect),
    );

    final a = 2 * math.pi * time.value / periodSeconds;
    final w = size.width;
    final h = size.height;
    final r = math.max(w, h) * 0.55;

    void blob(double cx, double cy, double radius, Color c, double alpha) {
      final center = Offset(cx * w, cy * h);
      final circle = Rect.fromCircle(center: center, radius: radius);
      canvas.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            colors: [c.withValues(alpha: alpha), c.withValues(alpha: 0)],
          ).createShader(circle),
      );
    }

    blob(0.20 + 0.10 * math.sin(a), 0.18 + 0.08 * math.cos(a), r,
        AuroraBackground.green, 0.42);
    blob(0.85 + 0.08 * math.cos(a + 1.7), 0.40 + 0.10 * math.sin(2 * a + 0.6),
        r * 0.9, AuroraBackground.teal, 0.34);
    blob(0.35 + 0.12 * math.sin(2 * a + 2.4), 0.92 + 0.06 * math.cos(a + 0.3),
        r * 1.1, AuroraBackground.emerald, 0.40);
    blob(0.70 + 0.10 * math.cos(a + 4.1), 0.08 + 0.05 * math.sin(a + 2.0),
        r * 0.7, AppColors.richGold, 0.035);

    // Vignette: deepen the edges so the centre (where the form sits) is calm.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.1),
          radius: 1.0,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.50),
          ],
          stops: const [0.55, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(AuroraFallbackPainter old) =>
      old.time != time || old.periodSeconds != periodSeconds;
}
