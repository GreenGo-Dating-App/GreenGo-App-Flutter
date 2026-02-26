import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/action_success_dialog.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/entities/profile.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../../../../core/utils/safe_navigation.dart';

/// Edit Voice Introduction Screen
/// Allows users to record, play, and save a voice introduction
class EditVoiceScreen extends StatefulWidget {
  final Profile profile;

  const EditVoiceScreen({
    super.key,
    required this.profile,
  });

  @override
  State<EditVoiceScreen> createState() => _EditVoiceScreenState();
}

class _EditVoiceScreenState extends State<EditVoiceScreen>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isRecording = false;
  bool _isPlaying = false;
  bool _hasRecording = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  String? _recordedFilePath;
  String? _existingVoiceUrl;
  Duration _recordingDuration = Duration.zero;
  Duration _playbackPosition = Duration.zero;
  Duration _playbackDuration = Duration.zero;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  static const _maxRecordingDuration = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    _existingVoiceUrl = widget.profile.voiceRecordingUrl;
    _hasRecording = _existingVoiceUrl != null;

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _playbackPosition = position;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _playbackDuration = duration;
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _playbackPosition = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _recorder.dispose();
    _audioPlayer.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (!await _recorder.hasPermission()) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.voiceMicrophonePermissionRequired ?? 'Microphone permission is required'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
      return;
    }

    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/voice_intro_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: filePath,
    );

    setState(() {
      _isRecording = true;
      _recordingDuration = Duration.zero;
      _recordedFilePath = filePath;
    });

    _pulseController.repeat(reverse: true);

    // Track recording duration
    _trackRecordingDuration();
  }

  Future<void> _trackRecordingDuration() async {
    while (_isRecording && mounted) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (_isRecording && mounted) {
        setState(() {
          _recordingDuration += const Duration(milliseconds: 100);
        });

        // Auto-stop at max duration
        if (_recordingDuration >= _maxRecordingDuration) {
          await _stopRecording();
        }
      }
    }
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    _pulseController.stop();
    _pulseController.reset();

    if (path != null && mounted) {
      setState(() {
        _isRecording = false;
        _recordedFilePath = path;
        _hasRecording = true;
        _existingVoiceUrl = null; // New recording replaces existing
      });
    }
  }

  Future<void> _playRecording() async {
    if (_recordedFilePath != null) {
      await _audioPlayer.play(DeviceFileSource(_recordedFilePath!));
    } else if (_existingVoiceUrl != null) {
      await _audioPlayer.play(UrlSource(_existingVoiceUrl!));
    }

    setState(() {
      _isPlaying = true;
    });
  }

  Future<void> _pausePlayback() async {
    await _audioPlayer.pause();
    setState(() {
      _isPlaying = false;
    });
  }

  Future<void> _deleteRecording() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(
          l10n?.voiceDeleteRecording ?? 'Delete Recording',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          l10n?.voiceDeleteConfirm ?? 'Are you sure you want to delete your voice introduction?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n?.delete ?? 'Delete',
              style: const TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _audioPlayer.stop();
      setState(() {
        _recordedFilePath = null;
        _existingVoiceUrl = null;
        _hasRecording = false;
        _isPlaying = false;
        _playbackPosition = Duration.zero;
      });
    }
  }

  Future<void> _saveRecording() async {
    if (_recordedFilePath == null && _existingVoiceUrl == null) return;

    // If using existing voice URL and no new recording, just pop
    if (_recordedFilePath == null && _existingVoiceUrl != null) {
      SafeNavigation.pop(context);
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final file = File(_recordedFilePath!);
      final uuid = const Uuid().v4();
      final fileName = 'voice_intros/${widget.profile.userId}/$uuid.m4a';

      final ref = FirebaseStorage.instance.ref().child(fileName);
      final uploadTask = ref.putFile(file);

      uploadTask.snapshotEvents.listen((snapshot) {
        if (mounted) {
          setState(() {
            _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
          });
        }
      });

      await uploadTask;
      final downloadUrl = await ref.getDownloadURL();

      if (mounted) {
        // Update profile with new voice URL
        context.read<ProfileBloc>().add(
              ProfileUpdateRequested(
                profile: widget.profile.copyWith(voiceRecordingUrl: downloadUrl),
              ),
            );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n?.voiceUploadFailed ?? "Failed to upload voice recording"}: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) async {
        if (state is ProfileUpdated) {
          // Show success dialog instead of snackbar
          await ActionSuccessDialog.showVoiceUpdated(context);
          if (context.mounted) {
            Navigator.of(context).pop(state.profile);
          }
        } else if (state is ProfileError) {
          setState(() {
            _isUploading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => SafeNavigation.pop(context),
          ),
          title: Text(
            l10n?.voiceIntro ?? 'Voice Introduction',
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          actions: [
            if (_hasRecording && !_isRecording && !_isUploading)
              TextButton(
                onPressed: _saveRecording,
                child: Text(
                  l10n?.save ?? 'Save',
                  style: const TextStyle(
                    color: AppColors.richGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                decoration: BoxDecoration(
                  color: AppColors.richGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  border: Border.all(
                    color: AppColors.richGold.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.richGold,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n?.voiceStandOutWithYourVoice ?? 'Stand out with your voice!',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n?.voiceRecordIntroDescription(_maxRecordingDuration.inSeconds) ??
                                'Record a short ${_maxRecordingDuration.inSeconds} second introduction to let others hear your personality.',
                            style: const TextStyle(
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

              const SizedBox(height: 48),

              // Recording/Playback UI
              _buildRecordingInterface(l10n),

              const SizedBox(height: 48),

              // Tips
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.voiceRecordingTips ?? 'Recording Tips',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTip(Icons.mic, l10n?.voiceTipFindQuietPlace ?? 'Find a quiet place'),
                    _buildTip(Icons.sentiment_satisfied, l10n?.voiceTipBeYourself ?? 'Be yourself and natural'),
                    _buildTip(Icons.chat_bubble, l10n?.voiceTipShareWhatMakesYouUnique ?? 'Share what makes you unique'),
                    _buildTip(Icons.timer, l10n?.voiceTipKeepItShort ?? 'Keep it short and sweet'),
                  ],
                ),
              ),

              // Upload Progress
              if (_isUploading) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.cloud_upload,
                            color: AppColors.richGold,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n?.voiceUploading ?? 'Uploading...',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${(_uploadProgress * 100).toInt()}%',
                            style: const TextStyle(
                              color: AppColors.richGold,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _uploadProgress,
                        backgroundColor: AppColors.backgroundDark,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.richGold),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingInterface(AppLocalizations? l10n) {
    return Column(
      children: [
        // Main Recording Button
        ScaleTransition(
          scale: _isRecording ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
          child: GestureDetector(
            onTap: _isUploading
                ? null
                : (_isRecording ? _stopRecording : (_hasRecording ? null : _startRecording)),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _isRecording
                    ? const LinearGradient(
                        colors: [AppColors.errorRed, Color(0xFFFF6B6B)],
                      )
                    : LinearGradient(
                        colors: _hasRecording
                            ? [AppColors.successGreen, const Color(0xFF66BB6A)]
                            : [AppColors.richGold, const Color(0xFFFFD700)],
                      ),
                boxShadow: [
                  BoxShadow(
                    color: (_isRecording
                            ? AppColors.errorRed
                            : (_hasRecording ? AppColors.successGreen : AppColors.richGold))
                        .withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                _isRecording
                    ? Icons.stop
                    : (_hasRecording ? Icons.check : Icons.mic),
                size: 50,
                color: Colors.white,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Recording Duration / Status
        Text(
          _isRecording
              ? _formatDuration(_recordingDuration)
              : (_hasRecording
                  ? (l10n?.voiceRecordingSaved ?? 'Recording saved')
                  : (l10n?.voiceTapToRecord ?? 'Tap to record')),
          style: TextStyle(
            color: _isRecording ? AppColors.errorRed : AppColors.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),

        // Playback Controls
        if (_hasRecording && !_isRecording) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Play/Pause Button
                IconButton(
                  onPressed: _isPlaying ? _pausePlayback : _playRecording,
                  icon: Icon(
                    _isPlaying ? Icons.pause_circle : Icons.play_circle,
                    color: AppColors.richGold,
                    size: 48,
                  ),
                ),

                // Progress
                if (_playbackDuration.inMilliseconds > 0)
                  Expanded(
                    child: Column(
                      children: [
                        Slider(
                          value: _playbackPosition.inMilliseconds.toDouble(),
                          max: _playbackDuration.inMilliseconds.toDouble(),
                          activeColor: AppColors.richGold,
                          inactiveColor: AppColors.divider,
                          onChanged: (value) {
                            _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(_playbackPosition),
                                style: const TextStyle(
                                  color: AppColors.textTertiary,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _formatDuration(_playbackDuration),
                                style: const TextStyle(
                                  color: AppColors.textTertiary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Delete Button
                IconButton(
                  onPressed: _deleteRecording,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.errorRed,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Re-record Button
          TextButton.icon(
            onPressed: _startRecording,
            icon: const Icon(Icons.refresh, color: AppColors.richGold),
            label: Text(
              l10n?.voiceRecordAgain ?? 'Record Again',
              style: const TextStyle(color: AppColors.richGold),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTip(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.textTertiary,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
