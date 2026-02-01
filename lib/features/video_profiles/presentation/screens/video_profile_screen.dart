import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/video_profile.dart';

/// Screen for recording/uploading video profile introduction
class VideoProfileScreen extends StatefulWidget {
  final String userId;
  final VideoProfile? existingProfile;
  final Function(String videoUrl, String? thumbnailUrl)? onVideoUploaded;

  const VideoProfileScreen({
    super.key,
    required this.userId,
    this.existingProfile,
    this.onVideoUploaded,
  });

  @override
  State<VideoProfileScreen> createState() => _VideoProfileScreenState();
}

class _VideoProfileScreenState extends State<VideoProfileScreen> {
  VideoPlayerController? _videoController;
  File? _videoFile;
  bool _isRecording = false;
  bool _isUploading = false;
  final int _maxDurationSeconds = 30;

  @override
  void initState() {
    super.initState();
    if (widget.existingProfile != null) {
      _initializeExistingVideo();
    }
  }

  Future<void> _initializeExistingVideo() async {
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(widget.existingProfile!.videoUrl),
    );
    await _videoController!.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _recordVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: Duration(seconds: _maxDurationSeconds),
    );

    if (video != null) {
      _setVideo(File(video.path));
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: Duration(seconds: _maxDurationSeconds),
    );

    if (video != null) {
      _setVideo(File(video.path));
    }
  }

  Future<void> _setVideo(File file) async {
    _videoController?.dispose();
    _videoFile = file;
    _videoController = VideoPlayerController.file(file);
    await _videoController!.initialize();

    // Check duration
    if (_videoController!.value.duration.inSeconds > _maxDurationSeconds) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video must be $_maxDurationSeconds seconds or less'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
      _videoController?.dispose();
      _videoController = null;
      _videoFile = null;
    }

    setState(() {});
  }

  Future<void> _uploadVideo() async {
    if (_videoFile == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      // TODO: Implement actual upload to Firebase Storage
      await Future.delayed(const Duration(seconds: 2)); // Simulated upload

      // Simulated URL - replace with actual upload logic
      final videoUrl = 'https://example.com/videos/${widget.userId}_intro.mp4';

      widget.onVideoUploaded?.call(videoUrl, null);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video uploaded successfully!'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _deleteVideo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text(
          'Delete Video?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to delete your video introduction?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _videoController?.dispose();
              _videoController = null;
              _videoFile = null;
              setState(() {});
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Video Introduction',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          if (_videoFile != null || widget.existingProfile != null)
            IconButton(
              icon: const Icon(Icons.delete, color: AppColors.errorRed),
              onPressed: _deleteVideo,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              decoration: BoxDecoration(
                color: AppColors.richGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                border: Border.all(
                  color: AppColors.richGold.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.videocam,
                    color: AppColors.richGold,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Make a great first impression!',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Record a $_maxDurationSeconds second video to introduce yourself. Profiles with videos get 40% more matches!',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Video preview
            AspectRatio(
              aspectRatio: 9 / 16,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  border: Border.all(color: AppColors.divider),
                ),
                child: _videoController != null && _videoController!.value.isInitialized
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            VideoPlayer(_videoController!),
                            _VideoPlayPauseOverlay(controller: _videoController!),
                            Positioned(
                              bottom: 8,
                              left: 8,
                              right: 8,
                              child: _VideoProgressIndicator(controller: _videoController!),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.videocam_outlined,
                            color: AppColors.textTertiary,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No video yet',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Max $_maxDurationSeconds seconds',
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            if (_videoFile == null && widget.existingProfile == null) ...[
              // Record button
              ElevatedButton.icon(
                onPressed: _recordVideo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.richGold,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                ),
                icon: const Icon(Icons.videocam),
                label: const Text(
                  'Record Video',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              // Upload button
              OutlinedButton.icon(
                onPressed: _pickVideo,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.divider),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                ),
                icon: const Icon(Icons.upload),
                label: const Text(
                  'Upload from Gallery',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ] else if (_videoFile != null) ...[
              // Upload button
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadVideo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.successGreen,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                ),
                icon: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.cloud_upload),
                label: Text(
                  _isUploading ? 'Uploading...' : 'Save Video',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              // Re-record button
              OutlinedButton.icon(
                onPressed: _isUploading ? null : _recordVideo,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.divider),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text(
                  'Record Again',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Tips
            const Text(
              'Tips for a great video:',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildTip(Icons.wb_sunny, 'Good lighting - face a window or light source'),
            _buildTip(Icons.stay_current_portrait, 'Hold your phone vertically'),
            _buildTip(Icons.sentiment_satisfied, 'Smile and be yourself!'),
            _buildTip(Icons.volume_up, 'Speak clearly - introduce yourself'),
            _buildTip(Icons.interests, 'Mention your hobbies or interests'),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: AppColors.richGold, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoPlayPauseOverlay extends StatefulWidget {
  final VideoPlayerController controller;

  const _VideoPlayPauseOverlay({required this.controller});

  @override
  State<_VideoPlayPauseOverlay> createState() => _VideoPlayPauseOverlayState();
}

class _VideoPlayPauseOverlayState extends State<_VideoPlayPauseOverlay> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_listener);
  }

  void _listener() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.controller.value.isPlaying) {
          widget.controller.pause();
        } else {
          widget.controller.play();
        }
      },
      child: Container(
        color: Colors.transparent,
        child: Center(
          child: AnimatedOpacity(
            opacity: widget.controller.value.isPlaying ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoProgressIndicator extends StatefulWidget {
  final VideoPlayerController controller;

  const _VideoProgressIndicator({required this.controller});

  @override
  State<_VideoProgressIndicator> createState() => _VideoProgressIndicatorState();
}

class _VideoProgressIndicatorState extends State<_VideoProgressIndicator> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_listener);
  }

  void _listener() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duration = widget.controller.value.duration;
    final position = widget.controller.value.position;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        VideoProgressIndicator(
          widget.controller,
          allowScrubbing: true,
          colors: const VideoProgressColors(
            playedColor: AppColors.richGold,
            bufferedColor: Colors.white30,
            backgroundColor: Colors.white12,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(position),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            Text(
              _formatDuration(duration),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
