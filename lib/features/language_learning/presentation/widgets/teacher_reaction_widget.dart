import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Teacher emotions that drive animation + speech bubble content.
enum TeacherEmotion {
  greeting,
  correct,
  wrong,
  thinking,
  celebrating,
  speaking,
}

/// Animated Lottie teacher character positioned at bottom of screen.
///
/// Shows a large animated teacher. On greeting/thinking/celebrating shows
/// a speech bubble. On correct/wrong just shows the animation (no bubble).
class TeacherReactionWidget extends StatefulWidget {
  final TeacherEmotion emotion;
  final String? customMessage;
  final double size;

  const TeacherReactionWidget({
    super.key,
    required this.emotion,
    this.customMessage,
    this.size = 160,
  });

  @override
  State<TeacherReactionWidget> createState() => _TeacherReactionWidgetState();
}

class _TeacherReactionWidgetState extends State<TeacherReactionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _bubbleCtrl;
  late Animation<double> _bubbleAnim;
  String _message = '';

  // Only show speech bubble for these emotions
  static const _bubbleEmotions = {
    TeacherEmotion.greeting,
    TeacherEmotion.thinking,
    TeacherEmotion.celebrating,
  };

  static const _messages = {
    TeacherEmotion.greeting: [
      "Let's start!",
      'Ready to learn?',
      'Here we go!',
      'Welcome back!',
    ],
    TeacherEmotion.correct: <String>[],
    TeacherEmotion.wrong: <String>[],
    TeacherEmotion.thinking: [
      'Take your time...',
      'Think about it...',
      'You can do this!',
      'No rush!',
    ],
    TeacherEmotion.celebrating: [
      'Lesson complete!',
      "You're a star!",
      'Incredible work!',
      'Well done!',
    ],
    TeacherEmotion.speaking: <String>[],
  };

  static const _lottieFiles = {
    TeacherEmotion.greeting: 'assets/lottie/teacher/teacher_greeting.json',
    TeacherEmotion.correct: 'assets/lottie/teacher/teacher_correct.json',
    TeacherEmotion.wrong: 'assets/lottie/teacher/teacher_wrong.json',
    TeacherEmotion.thinking: 'assets/lottie/teacher/teacher_thinking.json',
    TeacherEmotion.celebrating:
        'assets/lottie/teacher/teacher_celebrating.json',
    TeacherEmotion.speaking: 'assets/lottie/teacher/teacher_speaking.json',
  };

  @override
  void initState() {
    super.initState();
    _bubbleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _bubbleAnim =
        CurvedAnimation(parent: _bubbleCtrl, curve: Curves.elasticOut);
    _pickMessage();
    _bubbleCtrl.forward();
  }

  @override
  void didUpdateWidget(covariant TeacherReactionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.emotion != widget.emotion) {
      _pickMessage();
      _bubbleCtrl.forward(from: 0);
    }
  }

  void _pickMessage() {
    if (widget.customMessage != null) {
      _message = widget.customMessage!;
      return;
    }
    final pool = _messages[widget.emotion] ?? [];
    if (pool.isEmpty) {
      _message = '';
      return;
    }
    _message = pool[Random().nextInt(pool.length)];
  }

  @override
  void dispose() {
    _bubbleCtrl.dispose();
    super.dispose();
  }

  Color get _emotionColor {
    switch (widget.emotion) {
      case TeacherEmotion.correct:
      case TeacherEmotion.celebrating:
        return Colors.green;
      case TeacherEmotion.wrong:
        return Colors.red;
      case TeacherEmotion.greeting:
        return const Color(0xFFD4AF37);
      case TeacherEmotion.thinking:
        return Colors.blue;
      case TeacherEmotion.speaking:
        return Colors.cyan;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lottiePath = _lottieFiles[widget.emotion]!;
    final showBubble =
        _message.isNotEmpty && _bubbleEmotions.contains(widget.emotion);
    final s = widget.size;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Speech bubble (only for greeting/thinking/celebrating)
        if (showBubble)
          Padding(
            padding: EdgeInsets.only(left: s * 0.2, bottom: 4),
            child: ScaleTransition(
              scale: _bubbleAnim,
              alignment: Alignment.bottomLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _emotionColor.withOpacity(0.12),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                    bottomLeft: Radius.circular(4),
                  ),
                  border: Border.all(
                    color: _emotionColor.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  _message,
                  style: TextStyle(
                    color: _emotionColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        // Teacher Lottie animation — large
        SizedBox(
          width: s,
          height: s,
          child: Lottie.asset(
            lottiePath,
            fit: BoxFit.contain,
            repeat: true,
            errorBuilder: (_, __, ___) => Container(
              decoration: BoxDecoration(
                color: _emotionColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _iconForEmotion(widget.emotion),
                color: _emotionColor,
                size: s * 0.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  IconData _iconForEmotion(TeacherEmotion e) {
    switch (e) {
      case TeacherEmotion.greeting:
        return Icons.waving_hand;
      case TeacherEmotion.correct:
        return Icons.celebration;
      case TeacherEmotion.wrong:
        return Icons.sentiment_dissatisfied;
      case TeacherEmotion.thinking:
        return Icons.psychology;
      case TeacherEmotion.celebrating:
        return Icons.emoji_events;
      case TeacherEmotion.speaking:
        return Icons.record_voice_over;
    }
  }
}
