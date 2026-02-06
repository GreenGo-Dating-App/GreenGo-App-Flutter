import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../constants/app_colors.dart';

/// Voice Introduction Player Widget
///
/// A reusable widget for playing voice introduction recordings on profiles.
/// Features play/pause, progress bar, and duration display.
class VoiceIntroductionPlayer extends StatefulWidget {
  final String voiceUrl;
  final String? label;
  final Color? accentColor;

  const VoiceIntroductionPlayer({
    super.key,
    required this.voiceUrl,
    this.label,
    this.accentColor,
  });

  @override
  State<VoiceIntroductionPlayer> createState() => _VoiceIntroductionPlayerState();
}

class _VoiceIntroductionPlayerState extends State<VoiceIntroductionPlayer> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  Color get _accentColor => widget.accentColor ?? AppColors.richGold;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          _isLoading = state == PlayerState.playing && _duration == Duration.zero;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
          _isLoading = false;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _position = Duration.zero;
          _isPlaying = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        if (_position == Duration.zero) {
          await _audioPlayer.play(UrlSource(widget.voiceUrl));
        } else {
          await _audioPlayer.resume();
        }
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to play voice introduction'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _seekTo(double value) {
    final position = Duration(milliseconds: (value * _duration.inMilliseconds).toInt());
    _audioPlayer.seek(position);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _accentColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with label and icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.mic,
                  color: _accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                widget.label ?? 'Voice Introduction',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Player controls
          Row(
            children: [
              // Play/Pause button
              GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _accentColor,
                        _accentColor.withOpacity(0.8),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _accentColor.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 28,
                          ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Progress slider and time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Progress slider
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: _accentColor,
                        inactiveTrackColor: _accentColor.withOpacity(0.2),
                        thumbColor: _accentColor,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        trackHeight: 4,
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 12,
                        ),
                      ),
                      child: Slider(
                        value: _duration.inMilliseconds > 0
                            ? _position.inMilliseconds / _duration.inMilliseconds
                            : 0,
                        onChanged: _duration.inMilliseconds > 0
                            ? _seekTo
                            : null,
                      ),
                    ),

                    // Time display
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_position),
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _formatDuration(_duration),
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Compact version of the voice introduction player
/// For use in list items or smaller spaces
class VoiceIntroductionPlayerCompact extends StatefulWidget {
  final String voiceUrl;
  final Color? accentColor;

  const VoiceIntroductionPlayerCompact({
    super.key,
    required this.voiceUrl,
    this.accentColor,
  });

  @override
  State<VoiceIntroductionPlayerCompact> createState() =>
      _VoiceIntroductionPlayerCompactState();
}

class _VoiceIntroductionPlayerCompactState
    extends State<VoiceIntroductionPlayerCompact> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = false;

  Color get _accentColor => widget.accentColor ?? AppColors.richGold;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.stop();
        await _audioPlayer.play(UrlSource(widget.voiceUrl));
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _togglePlayPause,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _accentColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _accentColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _accentColor,
                    ),
                  )
                : Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: _accentColor,
                    size: 20,
                  ),
            const SizedBox(width: 6),
            Text(
              _isPlaying ? 'Playing...' : 'Voice Intro',
              style: TextStyle(
                color: _accentColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
