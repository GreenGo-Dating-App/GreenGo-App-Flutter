import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/story.dart';

/// Stories Screen - Instagram-like 24-hour stories
class StoriesScreen extends StatefulWidget {
  final String currentUserId;
  final List<UserStories> userStories;
  final int initialUserIndex;
  final int initialStoryIndex;

  const StoriesScreen({
    super.key,
    required this.currentUserId,
    required this.userStories,
    this.initialUserIndex = 0,
    this.initialStoryIndex = 0,
  });

  @override
  State<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  int _currentUserIndex = 0;
  int _currentStoryIndex = 0;
  VideoPlayerController? _videoController;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _currentUserIndex = widget.initialUserIndex;
    _currentStoryIndex = widget.initialStoryIndex;
    _pageController = PageController(initialPage: _currentUserIndex);
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _progressController.addStatusListener(_onProgressComplete);
    _startStory();
  }

  void _onProgressComplete(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _nextStory();
    }
  }

  void _startStory() {
    if (widget.userStories.isEmpty) return;

    final currentUser = widget.userStories[_currentUserIndex];
    if (currentUser.activeStories.isEmpty) return;

    final story = currentUser.activeStories[_currentStoryIndex];

    _progressController.reset();

    if (story.type == StoryType.video) {
      _initializeVideo(story.mediaUrl);
    } else {
      _progressController.duration = const Duration(seconds: 5);
      _progressController.forward();
    }
  }

  Future<void> _initializeVideo(String url) async {
    _videoController?.dispose();
    _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
    await _videoController!.initialize();
    _progressController.duration = _videoController!.value.duration;
    _videoController!.play();
    _progressController.forward();
    if (mounted) setState(() {});
  }

  void _nextStory() {
    final currentUser = widget.userStories[_currentUserIndex];
    if (_currentStoryIndex < currentUser.activeStories.length - 1) {
      setState(() {
        _currentStoryIndex++;
      });
      _startStory();
    } else {
      _nextUser();
    }
  }

  void _previousStory() {
    if (_currentStoryIndex > 0) {
      setState(() {
        _currentStoryIndex--;
      });
      _startStory();
    } else {
      _previousUser();
    }
  }

  void _nextUser() {
    if (_currentUserIndex < widget.userStories.length - 1) {
      setState(() {
        _currentUserIndex++;
        _currentStoryIndex = 0;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startStory();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _previousUser() {
    if (_currentUserIndex > 0) {
      setState(() {
        _currentUserIndex--;
        final storyCount = widget.userStories[_currentUserIndex].activeStories.length;
        _currentStoryIndex = storyCount > 0 ? storyCount - 1 : 0;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startStory();
    }
  }

  void _pauseStory() {
    setState(() {
      _isPaused = true;
    });
    _progressController.stop();
    _videoController?.pause();
  }

  void _resumeStory() {
    setState(() {
      _isPaused = false;
    });
    _progressController.forward();
    _videoController?.play();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userStories.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'No stories available',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final currentUser = widget.userStories[_currentUserIndex];
    final stories = currentUser.activeStories;

    if (stories.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'No active stories',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final currentStory = stories[_currentStoryIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          final width = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < width / 3) {
            _previousStory();
          } else if (details.globalPosition.dx > width * 2 / 3) {
            _nextStory();
          }
        },
        onLongPressStart: (_) => _pauseStory(),
        onLongPressEnd: (_) => _resumeStory(),
        child: Stack(
          children: [
            // Story Content
            PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.userStories.length,
              itemBuilder: (context, index) {
                return _buildStoryContent(currentStory);
              },
            ),

            // Progress Indicators
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              right: 8,
              child: Row(
                children: List.generate(
                  stories.length,
                  (index) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: 2,
                      child: AnimatedBuilder(
                        animation: _progressController,
                        builder: (context, child) {
                          double progress = 0;
                          if (index < _currentStoryIndex) {
                            progress = 1;
                          } else if (index == _currentStoryIndex) {
                            progress = _progressController.value;
                          }
                          return LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // User Info Header
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: currentUser.userPhotoUrl != null
                        ? NetworkImage(currentUser.userPhotoUrl!)
                        : null,
                    child: currentUser.userPhotoUrl == null
                        ? Text(currentUser.userDisplayName.isNotEmpty
                            ? currentUser.userDisplayName[0].toUpperCase()
                            : '?')
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentUser.userDisplayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _getTimeAgo(currentStory.createdAt),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Caption
            if (currentStory.caption != null)
              Positioned(
                bottom: 100,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    currentStory.caption!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            // Reply Input
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white.withOpacity(0.5)),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Send a message...',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                              border: InputBorder.none,
                            ),
                            onTap: _pauseStory,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.favorite_border, color: Colors.white),
                        onPressed: () {
                          // React to story
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: () {
                          // Send reply
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryContent(Story story) {
    if (story.type == StoryType.video && _videoController != null) {
      return Center(
        child: _videoController!.value.isInitialized
            ? AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              )
            : const CircularProgressIndicator(color: Colors.white),
      );
    }

    return Image.network(
      story.mediaUrl,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return const Center(
          child: Icon(Icons.broken_image, color: Colors.white, size: 64),
        );
      },
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }
    return '${difference.inDays}d ago';
  }
}

/// Stories Row Widget for home/discover screen
class StoriesRow extends StatelessWidget {
  final String currentUserId;
  final List<UserStories> userStories;
  final VoidCallback onAddStory;
  final Function(int userIndex)? onStoryTap;

  const StoriesRow({
    super.key,
    required this.currentUserId,
    required this.userStories,
    required this.onAddStory,
    this.onStoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: userStories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildAddStoryButton(context);
          }
          return _buildStoryAvatar(context, userStories[index - 1], index - 1);
        },
      ),
    );
  }

  Widget _buildAddStoryButton(BuildContext context) {
    return GestureDetector(
      onTap: onAddStory,
      child: Container(
        width: 70,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.richGold, width: 2),
              ),
              child: const Icon(
                Icons.add,
                color: AppColors.richGold,
                size: 28,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Your Story',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryAvatar(BuildContext context, UserStories user, int index) {
    final hasUnviewed = user.hasUnviewedStories;

    return GestureDetector(
      onTap: () {
        if (onStoryTap != null) {
          onStoryTap!(index);
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => StoriesScreen(
                currentUserId: currentUserId,
                userStories: userStories,
                initialUserIndex: index,
              ),
            ),
          );
        }
      },
      child: Container(
        width: 70,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasUnviewed
                    ? const LinearGradient(
                        colors: [AppColors.richGold, Colors.orange],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                border: hasUnviewed
                    ? null
                    : Border.all(color: AppColors.textTertiary, width: 2),
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundImage: user.userPhotoUrl != null
                    ? NetworkImage(user.userPhotoUrl!)
                    : null,
                backgroundColor: AppColors.backgroundCard,
                child: user.userPhotoUrl == null
                    ? Text(
                        user.userDisplayName.isNotEmpty
                            ? user.userDisplayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user.userDisplayName,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Create Story Screen
class CreateStoryScreen extends StatefulWidget {
  final String userId;
  final Function(File file, StoryType type, String? caption) onPost;

  const CreateStoryScreen({
    super.key,
    required this.userId,
    required this.onPost,
  });

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedFile;
  StoryType? _selectedType;
  final TextEditingController _captionController = TextEditingController();
  VideoPlayerController? _videoController;
  bool _isPosting = false;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() {
        _selectedFile = File(image.path);
        _selectedType = StoryType.image;
      });
    }
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 30),
    );
    if (video != null) {
      final file = File(video.path);
      _videoController = VideoPlayerController.file(file);
      await _videoController!.initialize();
      setState(() {
        _selectedFile = file;
        _selectedType = StoryType.video;
      });
    }
  }

  Future<void> _takePhoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1080,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() {
        _selectedFile = File(image.path);
        _selectedType = StoryType.image;
      });
    }
  }

  Future<void> _recordVideo() async {
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(seconds: 30),
    );
    if (video != null) {
      final file = File(video.path);
      _videoController = VideoPlayerController.file(file);
      await _videoController!.initialize();
      setState(() {
        _selectedFile = file;
        _selectedType = StoryType.video;
      });
    }
  }

  void _postStory() {
    if (_selectedFile == null || _selectedType == null) return;

    setState(() {
      _isPosting = true;
    });

    widget.onPost(
      _selectedFile!,
      _selectedType!,
      _captionController.text.isNotEmpty ? _captionController.text : null,
    );
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
        title: const Text('Create Story'),
        actions: [
          if (_selectedFile != null)
            TextButton(
              onPressed: _isPosting ? null : _postStory,
              child: _isPosting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.richGold,
                      ),
                    )
                  : const Text(
                      'Post',
                      style: TextStyle(
                        color: AppColors.richGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
        ],
      ),
      body: _selectedFile == null
          ? _buildMediaPicker()
          : _buildPreview(),
    );
  }

  Widget _buildMediaPicker() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.add_photo_alternate,
            size: 80,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 24),
          const Text(
            'Share a moment',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your story will disappear after 24 hours',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildOptionButton(
                icon: Icons.photo_library,
                label: 'Gallery',
                onTap: _pickImage,
              ),
              const SizedBox(width: 24),
              _buildOptionButton(
                icon: Icons.camera_alt,
                label: 'Photo',
                onTap: _takePhoto,
              ),
              const SizedBox(width: 24),
              _buildOptionButton(
                icon: Icons.videocam,
                label: 'Video',
                onTap: _recordVideo,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.richGold.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.richGold, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_selectedType == StoryType.image)
                Image.file(_selectedFile!, fit: BoxFit.contain)
              else if (_videoController != null && _videoController!.value.isInitialized)
                Center(
                  child: AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: VideoPlayer(_videoController!),
                  ),
                ),
              Positioned(
                top: 16,
                left: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () {
                    setState(() {
                      _selectedFile = null;
                      _selectedType = null;
                      _videoController?.dispose();
                      _videoController = null;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.backgroundCard,
          child: TextField(
            controller: _captionController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Add a caption...',
              hintStyle: const TextStyle(color: AppColors.textTertiary),
              filled: true,
              fillColor: AppColors.backgroundDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}
