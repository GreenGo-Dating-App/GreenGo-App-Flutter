import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Enhancement #8: Voice Message Widget
/// For recording and playing voice messages
class VoiceMessageWidget extends StatefulWidget {
  final String? audioUrl;
  final Duration? duration;
  final bool isCurrentUser;
  final VoidCallback? onPlay;
  final VoidCallback? onPause;

  const VoiceMessageWidget({
    super.key,
    this.audioUrl,
    this.duration,
    required this.isCurrentUser,
    this.onPlay,
    this.onPause,
  });

  @override
  State<VoiceMessageWidget> createState() => _VoiceMessageWidgetState();
}

class _VoiceMessageWidgetState extends State<VoiceMessageWidget> {
  bool _isPlaying = false;
  double _progress = 0.0;

  String _formatDuration(Duration? duration) {
    if (duration == null) return '0:00';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isCurrentUser
        ? AppColors.deepBlack.withOpacity(0.2)
        : AppColors.backgroundInput;
    final iconColor = widget.isCurrentUser
        ? AppColors.deepBlack
        : AppColors.richGold;
    final textColor = widget.isCurrentUser
        ? AppColors.deepBlack
        : AppColors.textPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause button
          GestureDetector(
            onTap: () {
              setState(() {
                _isPlaying = !_isPlaying;
              });
              if (_isPlaying) {
                widget.onPlay?.call();
              } else {
                widget.onPause?.call();
              }
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: widget.isCurrentUser
                    ? AppColors.richGold
                    : AppColors.deepBlack,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Waveform visualization
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Waveform bars
                SizedBox(
                  height: 24,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(20, (index) {
                      final isActive = index / 20 <= _progress;
                      final height = 8.0 + (index % 5) * 3.0;
                      return Container(
                        width: 3,
                        height: height,
                        decoration: BoxDecoration(
                          color: isActive
                              ? iconColor
                              : iconColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 4),
                // Duration
                Text(
                  _formatDuration(widget.duration),
                  style: TextStyle(
                    color: textColor.withOpacity(0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Mic icon
          Icon(
            Icons.mic,
            color: iconColor.withOpacity(0.5),
            size: 16,
          ),
        ],
      ),
    );
  }
}

/// Voice recording button
class VoiceRecordButton extends StatefulWidget {
  final Function(Duration duration)? onRecordingComplete;
  final VoidCallback? onRecordingStart;
  final VoidCallback? onRecordingCancel;

  const VoiceRecordButton({
    super.key,
    this.onRecordingComplete,
    this.onRecordingStart,
    this.onRecordingCancel,
  });

  @override
  State<VoiceRecordButton> createState() => _VoiceRecordButtonState();
}

class _VoiceRecordButtonState extends State<VoiceRecordButton> {
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) {
        setState(() => _isRecording = true);
        widget.onRecordingStart?.call();
      },
      onLongPressEnd: (_) {
        setState(() => _isRecording = false);
        widget.onRecordingComplete?.call(_recordingDuration);
      },
      onLongPressCancel: () {
        setState(() => _isRecording = false);
        widget.onRecordingCancel?.call();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: _isRecording ? 64 : 44,
        height: _isRecording ? 64 : 44,
        decoration: BoxDecoration(
          color: _isRecording ? AppColors.errorRed : AppColors.backgroundInput,
          shape: BoxShape.circle,
          boxShadow: _isRecording
              ? [
                  BoxShadow(
                    color: AppColors.errorRed.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Icon(
          Icons.mic,
          color: _isRecording ? Colors.white : AppColors.textSecondary,
          size: _isRecording ? 28 : 22,
        ),
      ),
    );
  }
}
