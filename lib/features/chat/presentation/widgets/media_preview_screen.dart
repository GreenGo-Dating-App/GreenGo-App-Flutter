import 'dart:io';
import 'package:flutter/material.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/constants/app_colors.dart';

/// Media Preview Screen
///
/// Shows a preview of the selected image/video before sending
/// Allows adding a caption to the media
class MediaPreviewScreen extends StatefulWidget {
  final File mediaFile;
  final bool isVideo;
  final Function(String? caption) onSend;
  final VoidCallback onCancel;

  const MediaPreviewScreen({
    super.key,
    required this.mediaFile,
    required this.isVideo,
    required this.onSend,
    required this.onCancel,
  });

  @override
  State<MediaPreviewScreen> createState() => _MediaPreviewScreenState();
}

class _MediaPreviewScreenState extends State<MediaPreviewScreen> {
  final TextEditingController _captionController = TextEditingController();
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.file(widget.mediaFile);
    try {
      await _videoController!.initialize();
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: widget.onCancel,
        ),
        title: Text(
          widget.isVideo ? AppLocalizations.of(context)!.chatPreviewVideo : AppLocalizations.of(context)!.chatPreviewImage,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // Media Preview
          Expanded(
            child: Center(
              child: widget.isVideo
                  ? _buildVideoPreview()
                  : _buildImagePreview(),
            ),
          ),

          // Caption Input and Send Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Caption input
                  TextField(
                    controller: _captionController,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.chatAddCaption,
                      hintStyle: const TextStyle(
                        color: AppColors.textTertiary,
                      ),
                      filled: true,
                      fillColor: AppColors.backgroundDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    maxLines: 3,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),

                  // Send button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final caption = _captionController.text.trim();
                        widget.onSend(caption.isEmpty ? null : caption);
                      },
                      icon: const Icon(Icons.send),
                      label: Text(AppLocalizations.of(context)!.chatSend),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.richGold,
                        foregroundColor: AppColors.deepBlack,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 3.0,
      child: Image.file(
        widget.mediaFile,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Container(
          color: AppColors.backgroundCard,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.broken_image,
                color: AppColors.textTertiary,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.chatFailedToLoadImage,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPreview() {
    if (!_isVideoInitialized || _videoController == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppColors.richGold,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.chatLoadingVideo,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_videoController!.value.isPlaying) {
            _videoController!.pause();
          } else {
            _videoController!.play();
          }
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
          if (!_videoController!.value.isPlaying)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 48,
              ),
            ),
        ],
      ),
    );
  }
}
