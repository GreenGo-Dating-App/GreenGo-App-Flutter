import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/animated_svg_icon.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/entities/game_room.dart';

/// A card widget for the lobby grid displaying a game type
/// with live player counts and visual feedback
class GameCard extends StatefulWidget {
  final GameType gameType;
  final int waitingCount;
  final int playingCount;
  final VoidCallback onTap;

  const GameCard({
    super.key,
    required this.gameType,
    this.waitingCount = 0,
    this.playingCount = 0,
    required this.onTap,
  });

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _isPressed
                ? AppColors.richGold.withValues(alpha: 0.12)
                : AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isPressed
                  ? AppColors.richGold
                  : AppColors.richGold.withValues(alpha: 0.15),
              width: _isPressed ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.richGold.withValues(alpha: _isPressed ? 0.2 : 0.06),
                blurRadius: _isPressed ? 16 : 8,
                spreadRadius: _isPressed ? 2 : 0,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated SVG game icon
                Center(
                  child: AnimatedSvgIcon(
                    assetPath: widget.gameType.iconAsset,
                    width: 64,
                    height: 64,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.gameType.displayName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 6),

                Text(
                  widget.gameType.tagline,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const Spacer(),

                Text(
                  AppLocalizations.of(context)!.playersRange(
                      widget.gameType.minPlayers.toString(),
                      widget.gameType.maxPlayers.toString()),
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: 4),

                // Live counts with animated dot
                Row(
                  children: [
                    if (widget.playingCount > 0) ...[
                      _AnimatedDot(color: AppColors.successGreen),
                      const SizedBox(width: 4),
                      Text(
                        AppLocalizations.of(context)!.playingCountLabel(widget.playingCount.toString()),
                        style: const TextStyle(
                          color: AppColors.successGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (widget.playingCount > 0 && widget.waitingCount > 0)
                      const SizedBox(width: 8),
                    if (widget.waitingCount > 0) ...[
                      _AnimatedDot(color: AppColors.warningAmber),
                      const SizedBox(width: 4),
                      Text(
                        AppLocalizations.of(context)!.waitingCountLabel(widget.waitingCount.toString()),
                        style: const TextStyle(
                          color: AppColors.warningAmber,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (widget.playingCount == 0 && widget.waitingCount == 0)
                      Text(
                        AppLocalizations.of(context)!.noActiveGamesLabel,
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pulsing dot indicator for live counts
class _AnimatedDot extends StatefulWidget {
  final Color color;
  const _AnimatedDot({required this.color});

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.6 * _controller.value),
                blurRadius: 4 + 4 * _controller.value,
                spreadRadius: 1 * _controller.value,
              ),
            ],
          ),
        );
      },
    );
  }
}

