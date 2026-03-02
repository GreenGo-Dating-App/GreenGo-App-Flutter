import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/pronunciation_service.dart';
import '../../../../core/services/visual_vocabulary_service.dart';
import 'package:audioplayers/audioplayers.dart';

/// A visually rich flashcard that shows:
/// 1. Contextual images of the word (from Unsplash/Pexels, cached)
/// 2. The word in the target language
/// 3. Translation in user's native language
/// 4. Pronunciation audio button (from Google TTS, cached)
/// 5. Example sentence
///
/// Designed for effortless visual recognition — users see "red" with
/// images of red flowers, red cars, and red sunsets.
class VisualFlashcardWidget extends StatefulWidget {
  final String word;
  final String translation;
  final String targetLanguage;
  final String nativeLanguage;
  final String? exampleSentence;
  final String? exampleTranslation;
  final bool showAnswer;
  final VoidCallback? onTap;

  const VisualFlashcardWidget({
    super.key,
    required this.word,
    required this.translation,
    required this.targetLanguage,
    required this.nativeLanguage,
    this.exampleSentence,
    this.exampleTranslation,
    this.showAnswer = false,
    this.onTap,
  });

  @override
  State<VisualFlashcardWidget> createState() => _VisualFlashcardWidgetState();
}

class _VisualFlashcardWidgetState extends State<VisualFlashcardWidget> {
  final VisualVocabularyService _imageService = VisualVocabularyService();
  final PronunciationService _pronunciationService = PronunciationService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<VocabularyImage> _images = [];
  bool _isLoadingImages = true;
  bool _isPlayingAudio = false;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadImages() async {
    try {
      final images = await _imageService.getImagesForWord(
        widget.word,
        language: widget.targetLanguage,
        count: 4,
      );
      if (mounted) {
        setState(() {
          _images = images;
          _isLoadingImages = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingImages = false;
        });
      }
    }
  }

  Future<void> _playPronunciation() async {
    if (_isPlayingAudio) return;

    setState(() => _isPlayingAudio = true);

    try {
      final audioUrl = await _pronunciationService.getPronunciationUrl(
        widget.word,
        widget.targetLanguage,
      );

      if (audioUrl != null && mounted) {
        await _audioPlayer.play(UrlSource(audioUrl));
        _audioPlayer.onPlayerComplete.listen((_) {
          if (mounted) setState(() => _isPlayingAudio = false);
        });
      } else {
        if (mounted) setState(() => _isPlayingAudio = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isPlayingAudio = false);
    }
  }

  Future<void> _playExampleSentence() async {
    if (widget.exampleSentence == null || _isPlayingAudio) return;

    setState(() => _isPlayingAudio = true);

    try {
      final audioUrl = await _pronunciationService.getPronunciationUrl(
        widget.exampleSentence!,
        widget.targetLanguage,
      );

      if (audioUrl != null && mounted) {
        await _audioPlayer.play(UrlSource(audioUrl));
        _audioPlayer.onPlayerComplete.listen((_) {
          if (mounted) setState(() => _isPlayingAudio = false);
        });
      } else {
        if (mounted) setState(() => _isPlayingAudio = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isPlayingAudio = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Image carousel
            _buildImageCarousel(),

            // Word + pronunciation
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      widget.word,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  // Pronunciation button
                  IconButton(
                    onPressed: _playPronunciation,
                    icon: Icon(
                      _isPlayingAudio
                          ? Icons.volume_up
                          : Icons.volume_up_outlined,
                      color: _isPlayingAudio
                          ? AppColors.richGold
                          : AppColors.textSecondary,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),

            // Translation (shown when answer revealed)
            if (widget.showAnswer) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  widget.translation,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.richGold.withValues(alpha: 0.9),
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Example sentence
            if (widget.exampleSentence != null && widget.showAnswer) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundDark.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.exampleSentence!,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _playExampleSentence,
                          icon: const Icon(
                            Icons.play_circle_outline,
                            color: AppColors.textSecondary,
                            size: 24,
                          ),
                          constraints: const BoxConstraints(
                              minWidth: 32, minHeight: 32),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                    if (widget.exampleTranslation != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.exampleTranslation!,
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Image attribution
            if (_images.isNotEmpty) ...[
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  _images[_currentImageIndex].attribution,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 10,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel() {
    if (_isLoadingImages) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.backgroundDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.richGold),
        ),
      );
    }

    if (_images.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.backgroundDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.image_outlined,
                  color: AppColors.textTertiary, size: 48),
              const SizedBox(height: 8),
              Text(
                widget.word,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Image
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: SizedBox(
            height: 220,
            width: double.infinity,
            child: PageView.builder(
              itemCount: _images.length,
              onPageChanged: (index) {
                setState(() => _currentImageIndex = index);
              },
              itemBuilder: (context, index) {
                final image = _images[index];
                return CachedNetworkImage(
                  imageUrl: image.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppColors.backgroundDark,
                    child: const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.richGold),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.backgroundDark,
                    child: const Icon(Icons.broken_image,
                        color: AppColors.textTertiary, size: 48),
                  ),
                );
              },
            ),
          ),
        ),

        // Gradient overlay at bottom for text readability
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppColors.backgroundCard.withValues(alpha: 0.9),
                ],
              ),
            ),
          ),
        ),

        // Image indicator dots
        if (_images.length > 1)
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _images.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == _currentImageIndex
                        ? AppColors.richGold
                        : AppColors.textTertiary.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),

        // Image description
        Positioned(
          bottom: 20,
          left: 12,
          right: 12,
          child: Text(
            _images[_currentImageIndex].description,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textPrimary.withValues(alpha: 0.8),
              fontSize: 12,
              shadows: const [
                Shadow(
                  blurRadius: 4,
                  color: Colors.black,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
