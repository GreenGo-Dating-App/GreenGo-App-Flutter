import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// A single flip card for the Language Snaps memory game.
/// Shows a face-down card (🃏) or face-up card with word text.
/// Supports 3D flip animation, matched state, and mismatch shake.
class SnapCardWidget extends StatefulWidget {
  final String word;
  final bool isFaceUp;
  final bool isMatched;
  final bool isMismatch;
  final VoidCallback? onTap;
  final Color accentColor;

  const SnapCardWidget({
    super.key,
    required this.word,
    this.isFaceUp = false,
    this.isMatched = false,
    this.isMismatch = false,
    this.onTap,
    this.accentColor = AppColors.richGold,
  });

  @override
  State<SnapCardWidget> createState() => _SnapCardWidgetState();
}

class _SnapCardWidgetState extends State<SnapCardWidget>
    with TickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _matchController;
  late Animation<double> _matchScale;

  bool _showFront = false;

  @override
  void initState() {
    super.initState();

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
    _flipAnimation.addListener(() {
      // Switch content at halfway point
      if (_flipAnimation.value >= 0.5 && !_showFront && widget.isFaceUp) {
        setState(() => _showFront = true);
      } else if (_flipAnimation.value < 0.5 && _showFront && !widget.isFaceUp) {
        setState(() => _showFront = false);
      }
    });

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _matchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _matchScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 50),
    ]).animate(
      CurvedAnimation(parent: _matchController, curve: Curves.easeInOut),
    );

    if (widget.isFaceUp || widget.isMatched) {
      _showFront = true;
      _flipController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant SnapCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Flip up
    if (widget.isFaceUp && !oldWidget.isFaceUp) {
      _flipController.forward(from: 0);
    }
    // Flip down
    if (!widget.isFaceUp && oldWidget.isFaceUp && !widget.isMatched) {
      _flipController.reverse();
    }
    // Match celebration
    if (widget.isMatched && !oldWidget.isMatched) {
      _showFront = true;
      _flipController.value = 1.0;
      _matchController.forward(from: 0);
    }
    // Mismatch shake
    if (widget.isMismatch && !oldWidget.isMismatch) {
      _shakeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    _shakeController.dispose();
    _matchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_flipAnimation, _shakeAnimation, _matchScale]),
      builder: (context, child) {
        // Shake offset
        final shakeOffset = widget.isMismatch
            ? math.sin(_shakeAnimation.value * math.pi * 4) * 5
            : 0.0;

        // Flip rotation (0 to π)
        final angle = _flipAnimation.value * math.pi;

        // Match scale
        final scale = widget.isMatched ? _matchScale.value : 1.0;

        return Transform.translate(
          offset: Offset(shakeOffset, 0),
          child: Transform.scale(
            scale: scale,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
              child: GestureDetector(
                onTap: widget.onTap,
                child: _showFront ? _buildFront() : _buildBack(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBack() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2A2A3E),
            const Color(0xFF1A1A2E),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.divider.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          '🃏',
          style: TextStyle(fontSize: 28),
        ),
      ),
    );
  }

  Widget _buildFront() {
    final borderColor = widget.isMatched
        ? AppColors.successGreen
        : widget.accentColor;
    final bgColor = widget.isMatched
        ? AppColors.successGreen.withValues(alpha: 0.15)
        : widget.accentColor.withValues(alpha: 0.08);

    // Mirror the text so it reads correctly when the card is flipped
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(math.pi),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor.withValues(alpha: 0.7),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: borderColor.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Word text
            Center(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Text(
                  widget.word,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: widget.isMatched
                        ? AppColors.successGreen
                        : AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            // Matched checkmark
            if (widget.isMatched)
              Positioned(
                top: 4,
                right: 4,
                child: Icon(
                  Icons.check_circle,
                  color: AppColors.successGreen,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
