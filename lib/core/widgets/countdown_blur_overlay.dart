import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/access_control_service.dart';
import '../widgets/animated_luxury_logo.dart';

/// A blur overlay widget that shows a countdown timer
/// Displayed on top of app content when user is approved but waiting for access date
class CountdownBlurOverlay extends StatefulWidget {
  final Widget child;
  final UserAccessData accessData;
  final VoidCallback? onSettingsTapped;

  const CountdownBlurOverlay({
    super.key,
    required this.child,
    required this.accessData,
    this.onSettingsTapped,
  });

  @override
  State<CountdownBlurOverlay> createState() => _CountdownBlurOverlayState();
}

class _CountdownBlurOverlayState extends State<CountdownBlurOverlay>
    with SingleTickerProviderStateMixin {
  Timer? _countdownTimer;
  Duration _timeRemaining = Duration.zero;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startCountdown();
  }

  void _startCountdown() {
    _updateTimeRemaining();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTimeRemaining();
    });
  }

  void _updateTimeRemaining() {
    setState(() {
      _timeRemaining = widget.accessData.timeUntilAccess;
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasEarlyAccess = widget.accessData.hasEarlyAccess;

    return Stack(
      children: [
        // The actual content (blurred)
        widget.child,

        // Blur overlay
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              color: Colors.black.withOpacity(0.7),
            ),
          ),
        ),

        // Countdown content
        Positioned.fill(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),

                  // Animated Logo
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: const AnimatedLuxuryLogo(
                      assetPath: 'assets/images/greengo_main_logo_gold.png',
                      size: 100,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Title
                  const Text(
                    'Almost There!',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.richGold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  // Access date info
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: hasEarlyAccess
                          ? AppColors.richGold.withOpacity(0.15)
                          : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasEarlyAccess
                            ? AppColors.richGold.withOpacity(0.5)
                            : Colors.white.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasEarlyAccess ? Icons.star : Icons.access_time,
                          color: hasEarlyAccess ? AppColors.richGold : Colors.white70,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hasEarlyAccess
                              ? 'VIP Early Access'
                              : 'Launch Date: April 14th',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: hasEarlyAccess ? AppColors.richGold : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Countdown timer
                  _buildCountdownTimer(),

                  const SizedBox(height: 40),

                  // Info message
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.white54,
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your account is approved! You can access Settings while waiting for the launch date.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Settings button
                  if (widget.onSettingsTapped != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: widget.onSettingsTapped,
                        icon: const Icon(Icons.settings),
                        label: const Text('Go to Settings'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.richGold,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 40),

                  // Upgrade banner (for basic users)
                  if (!hasEarlyAccess) _buildUpgradeBanner(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCountdownTimer() {
    final days = _timeRemaining.inDays;
    final hours = _timeRemaining.inHours % 24;
    final minutes = _timeRemaining.inMinutes % 60;
    final seconds = _timeRemaining.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.richGold.withOpacity(0.2),
            AppColors.richGold.withOpacity(0.05),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.richGold.withOpacity(0.4),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Time Until Launch',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTimeUnit(days.toString(), 'DAYS'),
              _buildSeparator(),
              _buildTimeUnit(hours.toString().padLeft(2, '0'), 'HRS'),
              _buildSeparator(),
              _buildTimeUnit(minutes.toString().padLeft(2, '0'), 'MIN'),
              _buildSeparator(),
              _buildTimeUnit(seconds.toString().padLeft(2, '0'), 'SEC'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeUnit(String value, String label) {
    return Column(
      children: [
        Container(
          width: 60,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.richGold.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.richGold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.6),
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSeparator() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: Text(
        ':',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.richGold,
        ),
      ),
    );
  }

  Widget _buildUpgradeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.richGold.withOpacity(0.3),
            AppColors.richGold.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.richGold.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.rocket_launch, color: AppColors.richGold, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Want Earlier Access?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.richGold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Upgrade your tier to get earlier access before April 14th!',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
