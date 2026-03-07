import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/entities/lesson.dart';

/// Card shown at the start of each unit in the learning path.
/// Displays unit number, category info, and completion progress.
/// Slides in from left with fade animation.
class UnitHeaderCard extends StatefulWidget {
  final int unitNumber;
  final LessonCategory category;
  final int completedLessons;
  final int totalLessons;

  const UnitHeaderCard({
    super.key,
    required this.unitNumber,
    required this.category,
    required this.completedLessons,
    required this.totalLessons,
  });

  @override
  State<UnitHeaderCard> createState() => _UnitHeaderCardState();
}

class _UnitHeaderCardState extends State<UnitHeaderCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          left: BorderSide(
            color: AppColors.richGold,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Left: Unit number in gold circle
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.richGold.withValues(alpha: 0.15),
              border: Border.all(
                color: AppColors.richGold,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                '${widget.unitNumber}',
                style: const TextStyle(
                  color: AppColors.richGold,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Center: Category emoji + display name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.category.emoji} ${widget.category.displayName}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)!.learningUnitNumber(widget.unitNumber),
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Right: Progress indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: widget.completedLessons == widget.totalLessons
                  ? AppColors.successGreen.withValues(alpha: 0.15)
                  : AppColors.richGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${widget.completedLessons}/${widget.totalLessons}',
              style: TextStyle(
                color: widget.completedLessons == widget.totalLessons
                    ? AppColors.successGreen
                    : AppColors.richGold,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
