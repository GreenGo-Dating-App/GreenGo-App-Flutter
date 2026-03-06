import 'package:flutter/material.dart';
import '../utils/country_flag_helper.dart';

/// Displays 1-2 country flag emojis (no circle, plain text).
class CountryFlagBadge extends StatelessWidget {
  final String? primary;
  final String? secondary;
  final double fontSize;

  const CountryFlagBadge({
    super.key,
    this.primary,
    this.secondary,
    this.fontSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    if (primary == null || primary!.isEmpty) {
      return const SizedBox.shrink();
    }

    final primaryFlag = CountryFlagHelper.getFlag(primary!);

    if (secondary == null || secondary!.isEmpty) {
      return Text(primaryFlag, style: TextStyle(fontSize: fontSize));
    }

    final secondaryFlag = CountryFlagHelper.getFlag(secondary!);
    return Text(
      '$primaryFlag$secondaryFlag',
      style: TextStyle(fontSize: fontSize),
    );
  }
}
