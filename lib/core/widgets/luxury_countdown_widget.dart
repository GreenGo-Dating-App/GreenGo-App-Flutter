import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import '../constants/app_colors.dart';

/// A luxury animated countdown widget following GreenGo's gold/black theme
/// Shows countdown with elegant animations, shimmer effects, and pulsing numbers
class LuxuryCountdownWidget extends StatefulWidget {
  final DateTime targetDate;
  final String? title;
  final String? subtitle;
  final VoidCallback? onComplete;
  final bool showDays;
  final bool showHours;
  final bool showMinutes;
  final bool showSeconds;
  final bool compact;

  const LuxuryCountdownWidget({
    super.key,
    required this.targetDate,
    this.title,
    this.subtitle,
    this.onComplete,
    this.showDays = true,
    this.showHours = true,
    this.showMinutes = true,
    this.showSeconds = true,
    this.compact = false,
  });

  @override
  State<LuxuryCountdownWidget> createState() => _LuxuryCountdownWidgetState();
}

class _LuxuryCountdownWidgetState extends State<LuxuryCountdownWidget>
    with TickerProviderStateMixin {
  Timer? _countdownTimer;
  Duration _timeRemaining = Duration.zero;
  bool _isComplete = false;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late AnimationController _glowController;
  late AnimationController _numberFlipController;

  // Animations
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _glowAnimation;

  // Track previous values for flip animation
  int _previousSeconds = -1;
  int _previousMinutes = -1;
  int _previousHours = -1;
  int _previousDays = -1;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startCountdown();
  }

  void _initializeAnimations() {
    // Pulse animation for the entire countdown
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Shimmer animation
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Glow animation
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Number flip animation
    _numberFlipController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  void _startCountdown() {
    _updateTimeRemaining();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTimeRemaining();
    });
  }

  void _updateTimeRemaining() {
    final now = DateTime.now();
    if (now.isAfter(widget.targetDate) || now.isAtSameMomentAs(widget.targetDate)) {
      setState(() {
        _timeRemaining = Duration.zero;
        _isComplete = true;
      });
      _countdownTimer?.cancel();
      widget.onComplete?.call();
    } else {
      final newDuration = widget.targetDate.difference(now);
      setState(() {
        _timeRemaining = newDuration;
      });

      // Trigger flip animation when values change
      final newSeconds = newDuration.inSeconds % 60;
      if (_previousSeconds != newSeconds && _previousSeconds != -1) {
        _numberFlipController.forward(from: 0);
      }
      _previousSeconds = newSeconds;
      _previousMinutes = newDuration.inMinutes % 60;
      _previousHours = newDuration.inHours % 24;
      _previousDays = newDuration.inDays;
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    _shimmerController.dispose();
    _glowController.dispose();
    _numberFlipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isComplete) {
      return _buildCompletedState();
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _glowAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            padding: EdgeInsets.all(widget.compact ? 12 : 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.8),
                  AppColors.charcoal.withValues(alpha: 0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(widget.compact ? 16 : 24),
              border: Border.all(
                color: AppColors.richGold.withValues(alpha: _glowAnimation.value),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.richGold.withValues(alpha: _glowAnimation.value * 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.title != null) ...[
                  _buildShimmerText(
                    widget.title!,
                    style: TextStyle(
                      fontSize: widget.compact ? 18 : 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.richGold,
                    ),
                  ),
                  SizedBox(height: widget.compact ? 4 : 8),
                ],
                if (widget.subtitle != null) ...[
                  Text(
                    widget.subtitle!,
                    style: TextStyle(
                      fontSize: widget.compact ? 12 : 14,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: widget.compact ? 12 : 20),
                ],
                _buildCountdownRow(),
                SizedBox(height: widget.compact ? 8 : 16),
                _buildAccessDateText(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCountdownRow() {
    final l10n = AppLocalizations.of(context);
    final days = _timeRemaining.inDays;
    final hours = _timeRemaining.inHours % 24;
    final minutes = _timeRemaining.inMinutes % 60;
    final seconds = _timeRemaining.inSeconds % 60;

    // Use localized labels or fallback to English
    final daysLabel = l10n?.days ?? 'Days';
    final hoursLabel = l10n?.hours ?? 'Hours';
    final minutesLabel = l10n?.minutes ?? 'Min';
    final secondsLabel = l10n?.seconds ?? 'Sec';

    final List<Widget> units = [];

    if (widget.showDays && days > 0) {
      units.add(_buildCountdownUnit(days, daysLabel.substring(0, math.min(3, daysLabel.length)).toUpperCase()));
    }
    if (widget.showHours) {
      if (units.isNotEmpty) units.add(_buildSeparator());
      units.add(_buildCountdownUnit(hours, hoursLabel.substring(0, math.min(3, hoursLabel.length)).toUpperCase()));
    }
    if (widget.showMinutes) {
      if (units.isNotEmpty) units.add(_buildSeparator());
      units.add(_buildCountdownUnit(minutes, minutesLabel.substring(0, math.min(3, minutesLabel.length)).toUpperCase()));
    }
    if (widget.showSeconds) {
      if (units.isNotEmpty) units.add(_buildSeparator());
      units.add(_buildCountdownUnit(seconds, secondsLabel.substring(0, math.min(3, secondsLabel.length)).toUpperCase(), isSeconds: true));
    }

    // Use FittedBox to prevent overflow
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: units,
      ),
    );
  }

  Widget _buildCountdownUnit(int value, String label, {bool isSeconds = false}) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: widget.compact ? 1 : 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: widget.compact ? 42 : 52,
                height: widget.compact ? 42 : 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.richGold.withValues(alpha: 0.2),
                      AppColors.accentGold.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(widget.compact ? 10 : 12),
                  border: Border.all(
                    color: AppColors.richGold.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  boxShadow: isSeconds
                      ? [
                          BoxShadow(
                            color: AppColors.richGold.withValues(alpha: _glowAnimation.value * 0.4),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.5),
                          end: Offset.zero,
                        ).animate(animation),
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      value.toString().padLeft(2, '0'),
                      key: ValueKey<int>(value),
                      style: TextStyle(
                        fontSize: widget.compact ? 20 : 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.richGold,
                        fontFamily: 'Poppins',
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: widget.compact ? 3 : 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: widget.compact ? 8 : 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.6),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSeparator() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Padding(
          padding: EdgeInsets.only(bottom: widget.compact ? 18 : 22),
          child: Text(
            ':',
            style: TextStyle(
              fontSize: widget.compact ? 22 : 28,
              fontWeight: FontWeight.bold,
              color: AppColors.richGold.withValues(alpha: _glowAnimation.value + 0.2),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccessDateText() {
    final formattedDate = _formatDate(widget.targetDate);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.compact ? 12 : 16,
        vertical: widget.compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.richGold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.richGold.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today,
            size: widget.compact ? 14 : 16,
            color: AppColors.richGold,
          ),
          SizedBox(width: widget.compact ? 6 : 8),
          Text(
            formattedDate,
            style: TextStyle(
              fontSize: widget.compact ? 12 : 14,
              fontWeight: FontWeight.w600,
              color: AppColors.richGold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerText(String text, {required TextStyle style}) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: const [
                AppColors.richGold,
                AppColors.accentGold,
                AppColors.richGold,
              ],
              stops: const [0.0, 0.5, 1.0],
              transform: _SlidingGradientTransform(_shimmerAnimation.value),
            ).createShader(bounds);
          },
          child: Text(
            text,
            style: style.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  Widget _buildCompletedState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.successGreen.withValues(alpha: 0.2),
            AppColors.charcoal.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.successGreen.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.celebration,
            size: 48,
            color: AppColors.successGreen,
          ),
          const SizedBox(height: 16),
          const Text(
            'Launch Day!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.successGreen,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'GreenGo Chat is now available',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform(this.slidePercent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
  }
}

/// A compact version of the countdown for inline use
class CompactLuxuryCountdown extends StatelessWidget {
  final DateTime targetDate;
  final VoidCallback? onComplete;

  const CompactLuxuryCountdown({
    super.key,
    required this.targetDate,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return LuxuryCountdownWidget(
      targetDate: targetDate,
      onComplete: onComplete,
      compact: true,
      showDays: true,
      showHours: true,
      showMinutes: true,
      showSeconds: true,
    );
  }
}
