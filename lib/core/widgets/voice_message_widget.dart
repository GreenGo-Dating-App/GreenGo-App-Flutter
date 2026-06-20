import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Enhancement #8: Voice Message Widget
/// Plays a voice note from [audioUrl] using audioplayers, with a live
/// progress waveform and play/pause control.
class VoiceMessageWidget extends StatefulWidget {

  const VoiceMessageWidget({
    required this.isCurrentUser, super.key,
    this.audioUrl,
    this.duration,
    this.onPlay,
    this.onPause,
  });
  final String? audioUrl;
  final Duration? duration;
  final bool isCurrentUser;
  final VoidCallback? onPlay;
  final VoidCallback? onPause;

  @override
  State<VoiceMessageWidget> createState() => _VoiceMessageWidgetState();
}

class _VoiceMessageWidgetState extends State<VoiceMessageWidget> {
  AudioPlayer? _player;
  bool _isPlaying = false;
  bool _isLoading = false;
  double _progress = 0.0;
  Duration _position = Duration.zero;
  Duration? _total;

  @override
  void initState() {
    super.initState();
    _total = widget.duration;
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  AudioPlayer _ensurePlayer() {
    final existing = _player;
    if (existing != null) return existing;
    final p = AudioPlayer();
    p.onDurationChanged.listen((d) {
      if (!mounted) return;
      if (d > Duration.zero) setState(() => _total = d);
    });
    p.onPositionChanged.listen((pos) {
      if (!mounted) return;
      setState(() {
        _position = pos;
        final totalMs = (_total ?? Duration.zero).inMilliseconds;
        _progress = totalMs > 0
            ? (pos.inMilliseconds / totalMs).clamp(0.0, 1.0)
            : 0.0;
      });
    });
    p.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
        _progress = 0.0;
        _position = Duration.zero;
      });
    });
    p.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _isPlaying = state == PlayerState.playing);
    });
    _player = p;
    return p;
  }

  Future<void> _toggle() async {
    final url = widget.audioUrl;
    if (url == null || url.isEmpty) return;
    final player = _ensurePlayer();
    try {
      if (_isPlaying) {
        await player.pause();
        widget.onPause?.call();
      } else {
        setState(() => _isLoading = true);
        if (_position > Duration.zero &&
            player.state == PlayerState.paused) {
          await player.resume();
        } else {
          await player.play(UrlSource(url));
        }
        widget.onPlay?.call();
      }
    } catch (_) {
      // ignore playback errors; UI resets below
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
    // While playing, show the elapsed time counting up; otherwise the total.
    final displayDuration =
        _isPlaying || _position > Duration.zero ? _position : (_total ?? widget.duration);

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
            onTap: _isLoading ? null : _toggle,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor,
                shape: BoxShape.circle,
              ),
              child: _isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(9),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: widget.isCurrentUser
                            ? AppColors.richGold
                            : AppColors.deepBlack,
                      ),
                    )
                  : Icon(
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
                // Duration (elapsed while playing, total otherwise)
                Text(
                  _formatDuration(displayDuration),
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

  const VoiceRecordButton({
    super.key,
    this.onRecordingComplete,
    this.onRecordingStart,
    this.onRecordingCancel,
  });
  final Function(Duration duration)? onRecordingComplete;
  final VoidCallback? onRecordingStart;
  final VoidCallback? onRecordingCancel;

  @override
  State<VoiceRecordButton> createState() => _VoiceRecordButtonState();
}

class _VoiceRecordButtonState extends State<VoiceRecordButton> {
  bool _isRecording = false;
  final Duration _recordingDuration = Duration.zero;

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
