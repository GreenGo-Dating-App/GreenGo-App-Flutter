import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/services/translation_service.dart';

/// Subtitle Overlay Widget - Displays real-time translated subtitles during video calls
class SubtitleOverlay extends StatefulWidget {
  final TranslationService translationService;
  final bool showOriginal;

  const SubtitleOverlay({
    super.key,
    required this.translationService,
    this.showOriginal = false,
  });

  @override
  State<SubtitleOverlay> createState() => _SubtitleOverlayState();
}

class _SubtitleOverlayState extends State<SubtitleOverlay>
    with SingleTickerProviderStateMixin {
  SubtitleData? _currentSubtitle;
  StreamSubscription<SubtitleData>? _subtitleSubscription;
  Timer? _fadeTimer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _subscribeToSubtitles();
  }

  void _subscribeToSubtitles() {
    _subtitleSubscription =
        widget.translationService.subtitleStream.listen((subtitle) {
      setState(() {
        _currentSubtitle = subtitle;
      });
      _animationController.forward(from: 0);

      // Reset fade timer
      _fadeTimer?.cancel();
      _fadeTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) {
          _animationController.reverse().then((_) {
            if (mounted) {
              setState(() {
                _currentSubtitle = null;
              });
            }
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _subtitleSubscription?.cancel();
    _fadeTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentSubtitle == null ||
        !widget.translationService.isEnabled) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 120,
      left: 16,
      right: 16,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.75),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white24,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Translated text (main)
              Text(
                _currentSubtitle!.translatedText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
              // Original text (optional)
              if (widget.showOriginal &&
                  _currentSubtitle!.sourceLanguage !=
                      _currentSubtitle!.targetLanguage) ...[
                const SizedBox(height: 4),
                Text(
                  _currentSubtitle!.originalText,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              // Language indicator
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLanguageChip(
                    SupportedLanguages.getLanguageName(
                        _currentSubtitle!.sourceLanguage),
                    Colors.blue,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.arrow_forward,
                      color: Colors.white54,
                      size: 14,
                    ),
                  ),
                  _buildLanguageChip(
                    SupportedLanguages.getLanguageName(
                        _currentSubtitle!.targetLanguage),
                    Colors.green,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageChip(String language, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        language,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Translation Toggle Button Widget
class TranslationToggleButton extends StatelessWidget {
  final TranslationService translationService;
  final VoidCallback? onTap;

  const TranslationToggleButton({
    super.key,
    required this.translationService,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<TranslationStatus>(
      stream: translationService.statusStream,
      builder: (context, snapshot) {
        final isEnabled = translationService.isEnabled;
        final status = snapshot.data ?? TranslationStatus.ready;

        return GestureDetector(
          onTap: () {
            translationService.toggleEnabled();
            onTap?.call();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isEnabled
                  ? Colors.green.withOpacity(0.8)
                  : Colors.grey.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (isEnabled ? Colors.green : Colors.grey)
                      .withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isEnabled ? Icons.subtitles : Icons.subtitles_off,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  isEnabled ? 'CC On' : 'CC Off',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (status == TranslationStatus.listening) ...[
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Language Selector Widget
class LanguageSelectorWidget extends StatelessWidget {
  final String currentLanguage;
  final Function(String) onLanguageSelected;
  final String label;

  const LanguageSelectorWidget({
    super.key,
    required this.currentLanguage,
    required this.onLanguageSelected,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => _showLanguagePicker(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  SupportedLanguages.getLanguageName(currentLanguage),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Select $label',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(color: Colors.white24),
            Expanded(
              child: ListView.builder(
                itemCount: SupportedLanguages.getAllLanguages().length,
                itemBuilder: (context, index) {
                  final entry =
                      SupportedLanguages.getAllLanguages()[index];
                  final isSelected = entry.key == currentLanguage;
                  return ListTile(
                    leading: isSelected
                        ? const Icon(Icons.check, color: Colors.green)
                        : const SizedBox(width: 24),
                    title: Text(
                      entry.value,
                      style: TextStyle(
                        color: isSelected ? Colors.green : Colors.white,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: Text(
                      entry.key.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                    onTap: () {
                      onLanguageSelected(entry.key);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
