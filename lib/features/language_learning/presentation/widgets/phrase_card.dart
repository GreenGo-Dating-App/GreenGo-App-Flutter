import 'package:flutter/material.dart';
import '../../domain/entities/language_phrase.dart';

class PhraseCard extends StatefulWidget {
  final LanguagePhrase phrase;
  final VoidCallback? onLearn;
  final Function(bool)? onFavorite;
  final bool isFavorite;

  const PhraseCard({
    super.key,
    required this.phrase,
    this.onLearn,
    this.onFavorite,
    this.isFavorite = false,
  });

  @override
  State<PhraseCard> createState() => _PhraseCardState();
}

class _PhraseCardState extends State<PhraseCard> {
  bool _showTranslation = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.phrase.isPremium
              ? const Color(0xFFD4AF37).withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    // Difficulty Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getDifficultyColor(widget.phrase.difficulty)
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.phrase.difficulty.emoji,
                            style: const TextStyle(fontSize: 10),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.phrase.difficulty.displayName,
                            style: TextStyle(
                              color:
                                  _getDifficultyColor(widget.phrase.difficulty),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Category
                    Text(
                      widget.phrase.category.displayName,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    // Premium Badge
                    if (widget.phrase.isPremium)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'PRO',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    // Favorite Button
                    IconButton(
                      icon: Icon(
                        widget.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: widget.isFavorite
                            ? Colors.red
                            : Colors.white.withOpacity(0.5),
                        size: 20,
                      ),
                      onPressed: () =>
                          widget.onFavorite?.call(!widget.isFavorite),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Phrase
                Text(
                  widget.phrase.phrase,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Pronunciation
                if (widget.phrase.pronunciation != null)
                  Text(
                    widget.phrase.pronunciation!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                const SizedBox(height: 12),

                // Translation (tap to reveal)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showTranslation = !_showTranslation;
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _showTranslation
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.white.withOpacity(0.5),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _showTranslation
                                ? widget.phrase.translation
                                : 'Tap to reveal translation',
                            style: TextStyle(
                              color: _showTranslation
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.5),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                // Level Requirement
                Row(
                  children: [
                    const Icon(
                      Icons.lock_open,
                      color: Colors.white38,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Level ${widget.phrase.requiredLevel}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Audio Button (if available)
                if (widget.phrase.audioUrl != null)
                  IconButton(
                    icon: const Icon(
                      Icons.volume_up,
                      color: Color(0xFFD4AF37),
                      size: 20,
                    ),
                    onPressed: () {
                      // TODO: Play audio
                    },
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
                const SizedBox(width: 8),
                // Mark as Learned Button
                TextButton.icon(
                  onPressed: widget.onLearn,
                  icon: const Icon(
                    Icons.check_circle_outline,
                    size: 16,
                  ),
                  label: const Text('Learned'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(PhraseDifficulty difficulty) {
    switch (difficulty) {
      case PhraseDifficulty.beginner:
        return Colors.green;
      case PhraseDifficulty.intermediate:
        return Colors.amber;
      case PhraseDifficulty.advanced:
        return Colors.orange;
      case PhraseDifficulty.fluent:
        return Colors.purple;
    }
  }
}
