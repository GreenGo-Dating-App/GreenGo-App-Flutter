import 'package:flutter/material.dart';
import '../utils/country_flag_helper.dart';

/// Displays 1-2 circular country flag badges.
/// Shows primary flag, and optionally a secondary flag overlapping.
class CountryFlagBadge extends StatelessWidget {
  final String? primary;
  final String? secondary;
  final bool compact;
  final double size;

  const CountryFlagBadge({
    super.key,
    this.primary,
    this.secondary,
    this.compact = false,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    if (primary == null || primary!.isEmpty) {
      return const SizedBox.shrink();
    }

    final flagSize = compact ? size * 0.8 : size;
    final primaryFlag = CountryFlagHelper.getFlag(primary!);

    if (secondary == null || secondary!.isEmpty) {
      return _FlagCircle(flag: primaryFlag, size: flagSize);
    }

    final secondaryFlag = CountryFlagHelper.getFlag(secondary!);
    return SizedBox(
      width: flagSize * 1.5,
      height: flagSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            child: _FlagCircle(flag: primaryFlag, size: flagSize),
          ),
          Positioned(
            left: flagSize * 0.55,
            child: _FlagCircle(flag: secondaryFlag, size: flagSize),
          ),
        ],
      ),
    );
  }
}

class _FlagCircle extends StatelessWidget {
  final String flag;
  final double size;

  const _FlagCircle({required this.flag, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black26,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        flag,
        style: TextStyle(fontSize: size * 0.55),
      ),
    );
  }
}
