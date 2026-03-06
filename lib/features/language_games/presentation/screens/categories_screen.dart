import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/game_room.dart';
import '../../domain/entities/game_round.dart';
import '../bloc/language_games_bloc.dart';
import '../bloc/language_games_event.dart';
import '../widgets/category_grid_cell.dart';

/// Categories game screen — redesigned with 3x3 grid.
/// Top: current letter + 60-second timer
/// Center: 3x3 grid of 9 category cells
/// Tap cell -> enter word matching category + letter
/// Win: first to complete all 9 categories
class CategoriesScreen extends StatefulWidget {
  final GameRoom room;
  final String currentUserId;
  final GameRound? currentRound;

  const CategoriesScreen({
    super.key,
    required this.room,
    required this.currentUserId,
    this.currentRound,
  });

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _letterAnimController;
  final Map<int, String> _filledWords = {};
  int? _activeCellIndex;
  final _textController = TextEditingController();

  static const List<String> _defaultCategories = [
    'Animals',
    'Food',
    'Countries',
    'Sports',
    'Colors',
    'Clothing',
    'Professions',
    'Nature',
    'Transport',
  ];

  String get _currentLetter =>
      widget.room.currentPrompt ?? widget.currentRound?.prompt ?? 'A';

  List<String> get _categories {
    final roomCategories = widget.room.roundCategories;
    if (roomCategories != null && roomCategories.length >= 9) {
      return roomCategories.take(9).toList();
    }
    return _defaultCategories;
  }

  int get _filledCount => _filledWords.length;

  @override
  void initState() {
    super.initState();
    _letterAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void didUpdateWidget(CategoriesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.room.currentPrompt != widget.room.currentPrompt) {
      _filledWords.clear();
      _activeCellIndex = null;
      _letterAnimController.reset();
      _letterAnimController.forward();
    }
  }

  @override
  void dispose() {
    _letterAnimController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _onCellTapped(int index) {
    if (_filledWords.containsKey(index)) return;
    setState(() => _activeCellIndex = index);
    _textController.clear();
    _showWordInput(index);
  }

  void _showWordInput(int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_categories[index]} — starts with "$_currentLetter"',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _textController,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Enter a word starting with "$_currentLetter"...',
                hintStyle: const TextStyle(color: AppColors.textTertiary),
                filled: true,
                fillColor: AppColors.backgroundDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (word) {
                if (word.isNotEmpty &&
                    word.toUpperCase().startsWith(_currentLetter.toUpperCase())) {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _filledWords[index] = word;
                    _activeCellIndex = null;
                  });
                  Navigator.pop(ctx);
                  // Submit to server
                  context.read<LanguageGamesBloc>().add(SubmitAnswer(
                        roomId: widget.room.id,
                        userId: widget.currentUserId,
                        answer: '$index:$word',
                      ));
                } else {
                  HapticFeedback.heavyImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Word must start with "$_currentLetter"'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAbandonDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text('Abandon Game?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('You will lose this game if you leave now.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<LanguageGamesBloc>().add(
                    LeaveRoom(
                        roomId: widget.room.id,
                        userId: widget.currentUserId),
                  );
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Leave',
                style: TextStyle(color: AppColors.errorRed)),
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
        title: Text(
          '${widget.room.gameType.emoji} Categories',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app,
                color: AppColors.errorRed, size: 20),
            tooltip: 'Abandon Game',
            onPressed: _showAbandonDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Current letter (large, animated) + timer
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: CurvedAnimation(
                    parent: _letterAnimController,
                    curve: Curves.elasticOut,
                  ),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFDAA520)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.richGold.withValues(alpha: 0.3),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _currentLetter,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Progress indicator
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_filledCount / 9',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'categories filled',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Player progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: widget.room.players.map((p) {
                final isMe = p.userId == widget.currentUserId;
                final score = widget.room.scores[p.userId] ?? 0;
                return Column(
                  children: [
                    Text(
                      isMe ? 'You' : p.displayName,
                      style: TextStyle(
                        color: isMe
                            ? AppColors.richGold
                            : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: isMe ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    Text(
                      '$score/9',
                      style: TextStyle(
                        color: isMe
                            ? AppColors.richGold
                            : AppColors.textTertiary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // 3x3 category grid
            Expanded(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 9,
                itemBuilder: (context, index) {
                  return CategoryGridCell(
                    category: _categories[index],
                    filledWord: _filledWords[index],
                    isActive: _activeCellIndex == index,
                    onTap: () => _onCellTapped(index),
                  );
                },
              ),
            ),

            // Hint
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Tap a category to fill it!',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
