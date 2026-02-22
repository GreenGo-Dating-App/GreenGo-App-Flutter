import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../bloc/onboarding_bloc.dart';
import '../../bloc/onboarding_event.dart';
import '../../bloc/onboarding_state.dart';
import '../../widgets/luxury_onboarding_layout.dart';
import '../../widgets/onboarding_progress_bar.dart';

class Step6VoiceRecordingScreen extends StatefulWidget {
  const Step6VoiceRecordingScreen({super.key});

  @override
  State<Step6VoiceRecordingScreen> createState() =>
      _Step6VoiceRecordingScreenState();
}

class _Step6VoiceRecordingScreenState extends State<Step6VoiceRecordingScreen> {
  bool _isRecording = false;
  bool _hasRecording = false;
  int _recordingDuration = 0;
  Timer? _timer;
  final int _maxDuration = 15; // 15 seconds
  String? _recordingPath;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<OnboardingBloc>().state;
    if (state is OnboardingInProgress && state.voiceUrl != null) {
      _hasRecording = true;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      // Get temporary directory for recording
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      setState(() {
        _recordingPath = path;
        _isRecording = true;
        _recordingDuration = 0;
      });

      // Start timer
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingDuration++;
        });

        // Auto-stop at max duration
        if (_recordingDuration >= _maxDuration) {
          _stopRecording();
        }
      });

      // TODO: Implement actual audio recording
      // For now, this is a placeholder
      // You would use a package like 'record' or 'audio_session' here
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start recording: ${e.toString()}'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();

    setState(() {
      _isRecording = false;
      _hasRecording = _recordingDuration > 0;
    });

    // TODO: Implement actual audio recording stop
  }

  Future<void> _uploadRecording() async {
    if (_recordingPath == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final file = File(_recordingPath!);

      // TODO: Upload to Firebase Storage
      // For now, simulate upload
      await Future.delayed(const Duration(seconds: 2));

      final voiceUrl = 'https://storage.example.com/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      if (!mounted) return;

      context.read<OnboardingBloc>().add(
        OnboardingVoiceUpdated(voiceUrl: voiceUrl),
      );

      setState(() {
        _isUploading = false;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload recording: ${e.toString()}'),
          backgroundColor: AppColors.errorRed,
        ),
      );

      setState(() {
        _isUploading = false;
      });
    }
  }

  void _deleteRecording() {
    setState(() {
      _hasRecording = false;
      _recordingDuration = 0;
      _recordingPath = null;
    });
  }

  void _handleContinue() {
    // Voice recording is optional, can skip
    context.read<OnboardingBloc>().add(const OnboardingNextStep());
  }

  void _handleBack() {
    context.read<OnboardingBloc>().add(const OnboardingPreviousStep());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        if (state is! OnboardingInProgress) {
          return const SizedBox.shrink();
        }

        return LuxuryOnboardingLayout(
          title: 'Voice introduction',
          subtitle: 'Record a short voice message (optional)',
          onBack: _handleBack,
          progressBar: OnboardingProgressBar(
            currentStep: state.stepIndex,
            totalSteps: state.totalSteps,
          ),
          child: Column(
            children: [
              // Recording UI
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Recording Circle
                      GestureDetector(
                        onTap: _isRecording ? _stopRecording : _startRecording,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: _isRecording
                                ? LinearGradient(
                                    colors: [
                                      AppColors.errorRed,
                                      AppColors.errorRed.withOpacity(0.6),
                                    ],
                                  )
                                : const LinearGradient(
                                    colors: [
                                      AppColors.richGold,
                                      AppColors.accentGold,
                                    ],
                                  ),
                            boxShadow: [
                              BoxShadow(
                                color: (_isRecording
                                        ? AppColors.errorRed
                                        : AppColors.richGold)
                                    .withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isRecording ? Icons.stop : Icons.mic,
                            size: 80,
                            color: AppColors.deepBlack,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Timer Display
                      Text(
                        _formatDuration(_recordingDuration),
                        style: Theme.of(context)
                            .textTheme
                            .displayMedium
                            ?.copyWith(
                              color: _isRecording
                                  ? AppColors.errorRed
                                  : AppColors.richGold,
                              fontWeight: FontWeight.bold,
                            ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        _isRecording
                            ? 'Recording... (max $_maxDuration seconds)'
                            : _hasRecording
                                ? 'Recording ready'
                                : '',
                        style:
                            Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.white.withOpacity(0.6),
                                ),
                      ),

                      const SizedBox(height: 32),

                      // Delete Button (if has recording)
                      if (_hasRecording && !_isRecording)
                        TextButton.icon(
                          onPressed: _deleteRecording,
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.errorRed,
                          ),
                          label: const Text(
                            'Delete Recording',
                            style: TextStyle(color: AppColors.errorRed),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Info Box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.richGold,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Voice introductions help others get to know you better. This step is optional.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withOpacity(0.6),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Continue/Skip Button
              LuxuryButton(
                text: _hasRecording ? 'Continue' : 'Skip',
                onPressed: _handleContinue,
                isLoading: _isUploading,
              ),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
