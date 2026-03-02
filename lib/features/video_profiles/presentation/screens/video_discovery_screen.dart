import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/video_profile.dart';
import '../bloc/video_profile_bloc.dart';
import '../bloc/video_profile_event.dart';
import '../bloc/video_profile_state.dart';

/// TikTok-style full-screen video discovery screen.
///
/// Vertical PageView with auto-playing videos, user overlays,
/// and gesture-based like/pass interactions.
class VideoDiscoveryScreen extends StatefulWidget {
  const VideoDiscoveryScreen({super.key});

  @override
  State<VideoDiscoveryScreen> createState() => _VideoDiscoveryScreenState();
}

class _VideoDiscoveryScreenState extends State<VideoDiscoveryScreen> {
  late PageController _pageController;
  final Map<int, VideoPlayerController> _controllers = {};
  int _currentPage = 0;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Load discovery videos
    context.read<VideoProfileBloc>().add(const LoadDiscoveryVideos());
  }

  @override
  void dispose() {
    _isDisposed = true;
    _pageController.dispose();
    // Dispose all video controllers
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    super.dispose();
  }

  /// Initialize a video controller for the given index.
  Future<void> _initializeController(
      int index, List<VideoProfile> videos) async {
    if (_isDisposed || index < 0 || index >= videos.length) return;
    if (_controllers.containsKey(index)) return;

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(videos[index].videoUrl),
      );
      _controllers[index] = controller;
      await controller.initialize();
      controller.setLooping(true);

      // Auto-play if this is the current page
      if (index == _currentPage && !_isDisposed) {
        controller.play();
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('[VideoDiscovery] Failed to init video $index: $e');
    }
  }

  /// Pre-load adjacent videos for smooth scrolling.
  void _preloadVideos(int currentIndex, List<VideoProfile> videos) {
    // Initialize current, next, and previous
    _initializeController(currentIndex, videos);
    if (currentIndex + 1 < videos.length) {
      _initializeController(currentIndex + 1, videos);
    }
    if (currentIndex - 1 >= 0) {
      _initializeController(currentIndex - 1, videos);
    }

    // Dispose controllers that are far away (more than 2 pages)
    final keysToRemove = <int>[];
    for (final key in _controllers.keys) {
      if ((key - currentIndex).abs() > 2) {
        keysToRemove.add(key);
      }
    }
    for (final key in keysToRemove) {
      _controllers[key]?.dispose();
      _controllers.remove(key);
    }
  }

  void _onPageChanged(int page, List<VideoProfile> videos) {
    // Pause old video
    _controllers[_currentPage]?.pause();

    _currentPage = page;

    // Play new video
    final controller = _controllers[page];
    if (controller != null && controller.value.isInitialized) {
      controller.play();
    }

    _preloadVideos(page, videos);

    // Load more videos when near the end
    if (page >= videos.length - 3) {
      final lastId = videos.isNotEmpty ? videos.last.id : null;
      context
          .read<VideoProfileBloc>()
          .add(LoadDiscoveryVideos(lastId: lastId));
    }
  }

  void _onLike() {
    HapticFeedback.mediumImpact();
    // Show a brief like animation
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Liked!'),
            ],
          ),
          backgroundColor: AppColors.successGreen.withValues(alpha: 0.9),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 100, left: 80, right: 80),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
          ),
        ),
      );
    }
  }

  void _onPass() {
    HapticFeedback.lightImpact();
    // Show a brief pass animation
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.close, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Passed'),
            ],
          ),
          backgroundColor: AppColors.errorRed.withValues(alpha: 0.9),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 100, left: 80, right: 80),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureBlack,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Video Intros',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: BlocBuilder<VideoProfileBloc, VideoProfileState>(
        builder: (context, state) {
          if (state is VideoProfileLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.richGold),
            );
          }

          if (state is VideoProfileError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.errorRed,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context
                        .read<VideoProfileBloc>()
                        .add(const LoadDiscoveryVideos()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.richGold,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is VideoProfileLoaded) {
            final videos = state.discoveryVideos;

            if (videos.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.videocam_off_outlined,
                      color: AppColors.textTertiary,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No video introductions yet',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Be the first to create one!',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Initialize first videos
            _preloadVideos(_currentPage, videos);

            return PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: videos.length,
              onPageChanged: (page) => _onPageChanged(page, videos),
              itemBuilder: (context, index) {
                return _VideoPage(
                  videoProfile: videos[index],
                  controller: _controllers[index],
                  onLike: _onLike,
                  onPass: _onPass,
                );
              },
            );
          }

          // Initial state
          return const Center(
            child: CircularProgressIndicator(color: AppColors.richGold),
          );
        },
      ),
    );
  }
}

/// A single full-screen video page in the discovery feed.
class _VideoPage extends StatelessWidget {
  final VideoProfile videoProfile;
  final VideoPlayerController? controller;
  final VoidCallback onLike;
  final VoidCallback onPass;

  const _VideoPage({
    required this.videoProfile,
    this.controller,
    required this.onLike,
    required this.onPass,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTapUp: (details) {
        // Tap right side = like, tap left side = pass
        if (details.globalPosition.dx > screenWidth / 2) {
          onLike();
        } else {
          onPass();
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video player or loading placeholder
          if (controller != null && controller!.value.isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: controller!.value.aspectRatio,
                child: VideoPlayer(controller!),
              ),
            )
          else
            Container(
              color: AppColors.pureBlack,
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.richGold,
                  strokeWidth: 2,
                ),
              ),
            ),

          // Gradient overlay at bottom for text readability
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 250,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
          ),

          // User info overlay
          Positioned(
            bottom: 80,
            left: AppDimensions.paddingL,
            right: 80, // Leave space for action buttons
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // User ID (in real app, this would be name/age)
                Text(
                  'User ${videoProfile.userId.substring(0, videoProfile.userId.length.clamp(0, 8))}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 4,
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Prompt used (if any)
                if (videoProfile.prompt != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.richGold.withValues(alpha: 0.2),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusS),
                      border: Border.all(
                        color: AppColors.richGold.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      videoProfile.prompt!,
                      style: const TextStyle(
                        color: AppColors.richGold,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 8),
                // View count and duration
                Row(
                  children: [
                    const Icon(Icons.visibility,
                        color: AppColors.textTertiary, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${videoProfile.viewCount} views',
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.timer,
                        color: AppColors.textTertiary, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${videoProfile.durationSeconds}s',
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Right-side action buttons
          Positioned(
            right: AppDimensions.paddingM,
            bottom: 100,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Like button
                _ActionButton(
                  icon: Icons.favorite,
                  label: 'Like',
                  color: AppColors.errorRed,
                  onTap: onLike,
                ),
                const SizedBox(height: 20),
                // Pass button
                _ActionButton(
                  icon: Icons.close,
                  label: 'Pass',
                  color: AppColors.textTertiary,
                  onTap: onPass,
                ),
                const SizedBox(height: 20),
                // Mute/unmute button
                if (controller != null && controller!.value.isInitialized)
                  _MuteButton(controller: controller!),
              ],
            ),
          ),

          // Video progress at the very bottom
          if (controller != null && controller!.value.isInitialized)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: VideoProgressIndicator(
                controller!,
                allowScrubbing: false,
                colors: const VideoProgressColors(
                  playedColor: AppColors.richGold,
                  bufferedColor: Colors.white30,
                  backgroundColor: Colors.white12,
                ),
                padding: EdgeInsets.zero,
              ),
            ),

          // Tap hint areas (semi-transparent, only shown briefly on first use)
          // Left side = Pass, Right side = Like
        ],
      ),
    );
  }
}

/// Circular action button for the right-side column.
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mute/unmute toggle button for video audio.
class _MuteButton extends StatefulWidget {
  final VideoPlayerController controller;

  const _MuteButton({required this.controller});

  @override
  State<_MuteButton> createState() => _MuteButtonState();
}

class _MuteButtonState extends State<_MuteButton> {
  bool _isMuted = false;

  void _toggle() {
    setState(() {
      _isMuted = !_isMuted;
      widget.controller.setVolume(_isMuted ? 0.0 : 1.0);
    });
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.textTertiary.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: Icon(
              _isMuted ? Icons.volume_off : Icons.volume_up,
              color: AppColors.textPrimary,
              size: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isMuted ? 'Unmute' : 'Mute',
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
