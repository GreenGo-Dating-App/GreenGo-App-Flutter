import 'package:flutter/material.dart';
import '../../domain/entities/daily_hint.dart';

class DailyHintCard extends StatelessWidget {
  final DailyHint hint;
  final VoidCallback onViewed;
  final VoidCallback onLearned;

  const DailyHintCard({
    super.key,
    required this.hint,
    required this.onViewed,
    required this.onLearned,
  });

  @override
  Widget build(BuildContext context) {
    // Mark as viewed when displayed
    if (!hint.isViewed) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onViewed());
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF2D2D44),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD4AF37).withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lightbulb,
                  color: Color(0xFFD4AF37),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Word of the Day',
                      style: TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Learn a new phrase daily!',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (hint.isLearned)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Learned',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Language Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              hint.phrase.languageName,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Phrase
          Text(
            hint.phrase.phrase,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Pronunciation
          if (hint.phrase.pronunciation != null)
            Text(
              hint.phrase.pronunciation!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          const SizedBox(height: 12),

          // Translation
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.translate,
                  color: Colors.white54,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hint.phrase.translation,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // XP Rewards & Action Button
          Row(
            children: [
              // XP Info
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Color(0xFFD4AF37),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+${hint.viewXpReward} XP viewed',
                        style: TextStyle(
                          color: hint.isViewed
                              ? Colors.green
                              : Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                      if (hint.isViewed)
                        const Icon(
                          Icons.check,
                          color: Colors.green,
                          size: 14,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Color(0xFFD4AF37),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+${hint.learnXpReward} XP learned',
                        style: TextStyle(
                          color: hint.isLearned
                              ? Colors.green
                              : Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                      if (hint.isLearned)
                        const Icon(
                          Icons.check,
                          color: Colors.green,
                          size: 14,
                        ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              // Mark as Learned Button
              if (!hint.isLearned)
                ElevatedButton(
                  onPressed: onLearned,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check, size: 18),
                      SizedBox(width: 4),
                      Text(
                        'I learned it!',
                        style: TextStyle(fontWeight: FontWeight.bold),
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
