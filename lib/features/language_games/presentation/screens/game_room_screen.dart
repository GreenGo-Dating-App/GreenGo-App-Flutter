import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/game_room.dart';
import '../bloc/language_games_bloc.dart';
import '../bloc/language_games_event.dart';
import '../bloc/language_games_state.dart';
import 'game_waiting_screen.dart';
import 'categories_screen.dart';
import 'game_play_screen.dart';
import 'game_results_screen.dart';
import 'grammar_duel_screen.dart';
import 'picture_guess_screen.dart';
import 'translation_race_screen.dart';
import 'language_snaps_screen.dart';
import 'language_tapples_screen.dart';
import 'vocabulary_chain_screen.dart';

/// Game room screen - routes to appropriate sub-screen based on game status
class GameRoomScreen extends StatefulWidget {
  final String roomId;
  final String currentUserId;
  final String currentDisplayName;
  final String? currentPhotoUrl;

  const GameRoomScreen({
    super.key,
    required this.roomId,
    required this.currentUserId,
    required this.currentDisplayName,
    this.currentPhotoUrl,
  });

  @override
  State<GameRoomScreen> createState() => _GameRoomScreenState();
}

class _GameRoomScreenState extends State<GameRoomScreen> {
  @override
  void initState() {
    super.initState();
    // Subscribe to room updates
    context
        .read<LanguageGamesBloc>()
        .add(ListenToRoom(roomId: widget.roomId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LanguageGamesBloc, LanguageGamesState>(
      listener: (context, state) {
        if (state is LanguageGamesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        if (state is LanguageGamesInRoom) {
          final room = state.room;
          switch (room.status) {
            case GameStatus.waiting:
            case GameStatus.starting:
              return GameWaitingScreen(
                userId: widget.currentUserId,
                room: room,
              );
            case GameStatus.inProgress:
              if (room.gameType == GameType.translationRace) {
                return TranslationRaceScreen(
                  room: room,
                  currentUserId: widget.currentUserId,
                  currentRound: state.currentRound,
                );
              }
              if (room.gameType == GameType.pictureGuess) {
                return PictureGuessScreen(
                  room: room,
                  currentUserId: widget.currentUserId,
                  currentRound: state.currentRound,
                );
              }
              if (room.gameType == GameType.grammarDuel) {
                return GrammarDuelScreen(
                  room: room,
                  currentUserId: widget.currentUserId,
                  currentRound: state.currentRound,
                );
              }
              if (room.gameType == GameType.vocabularyChain) {
                return VocabularyChainScreen(
                  room: room,
                  currentUserId: widget.currentUserId,
                  currentRound: state.currentRound,
                );
              }
              if (room.gameType == GameType.languageSnaps) {
                return LanguageSnapsScreen(
                  room: room,
                  currentUserId: widget.currentUserId,
                  currentRound: state.currentRound,
                );
              }
              if (room.gameType == GameType.languageTapples) {
                return LanguageTapplesScreen(
                  room: room,
                  currentUserId: widget.currentUserId,
                  currentRound: state.currentRound,
                );
              }
              if (room.gameType == GameType.categories) {
                return CategoriesScreen(
                  room: room,
                  currentUserId: widget.currentUserId,
                  currentRound: state.currentRound,
                );
              }
              return GamePlayScreen(
                userId: widget.currentUserId,
                room: room,
              );
            case GameStatus.finished:
              return GameResultsScreen(
                room: room,
                finalScores: room.scores,
                currentUserId: widget.currentUserId,
                xpEarned: room.xpReward,
              );
          }
        }

        if (state is LanguageGamesFinished) {
          return GameResultsScreen(
            room: state.room,
            finalScores: state.finalScores,
            currentUserId: widget.currentUserId,
            xpEarned: state.xpEarned,
          );
        }

        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          body: const Center(
            child: CircularProgressIndicator(color: AppColors.richGold),
          ),
        );
      },
    );
  }
}
