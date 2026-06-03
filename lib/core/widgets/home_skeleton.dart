import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_colors.dart';

/// Shimmer skeleton of the home/discovery shell, shown while the main screen
/// resolves the user's profile + access data. Gives a fast, "content is
/// coming" feel instead of a blank spinner (especially right after signup).
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  static Widget _box(double w, double h, {double radius = 8}) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Shimmer.fromColors(
          baseColor: AppColors.backgroundCard,
          highlightColor: const Color(0xFF2E2E2E),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar: avatar + title + action icon
                Row(
                  children: [
                    _box(44, 44, radius: 22),
                    const SizedBox(width: 12),
                    _box(140, 18),
                    const Spacer(),
                    _box(40, 40, radius: 12),
                  ],
                ),
                const SizedBox(height: 20),
                // Big discovery card
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Name + subtitle lines
                _box(180, 22),
                const SizedBox(height: 10),
                _box(120, 14),
                const SizedBox(height: 20),
                // Action buttons row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _box(56, 56, radius: 28),
                    _box(64, 64, radius: 32),
                    _box(56, 56, radius: 28),
                  ],
                ),
                const SizedBox(height: 20),
                // Bottom nav placeholder
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(5, (_) => _box(28, 28, radius: 8)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
