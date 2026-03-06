import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../domain/entities/game_room.dart';
import '../bloc/language_games_bloc.dart';
import '../bloc/language_games_event.dart';
import '../bloc/language_games_state.dart';
import '../screens/game_waiting_screen.dart';
import 'game_invite_popup.dart';

/// Game Invite Listener
///
/// Wraps a child widget and listens for real-time game invites
/// from Firestore. Shows a popup dialog when a new invite arrives.
class GameInviteListener extends StatefulWidget {
  final String userId;
  final String displayName;
  final Widget child;

  const GameInviteListener({
    super.key,
    required this.userId,
    required this.displayName,
    required this.child,
  });

  @override
  State<GameInviteListener> createState() => _GameInviteListenerState();
}

class _GameInviteListenerState extends State<GameInviteListener> {
  StreamSubscription? _inviteSubscription;
  final Set<String> _shownInviteIds = {};
  bool _isShowingPopup = false;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  @override
  void dispose() {
    _inviteSubscription?.cancel();
    super.dispose();
  }

  void _startListening() {
    _inviteSubscription?.cancel();

    _inviteSubscription = FirebaseFirestore.instance
        .collection('game_invites')
        .where('invitedUserId', isEqualTo: widget.userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen(
      (snapshot) {
        for (final change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data();
            if (data == null) continue;

            final inviteId = change.doc.id;

            // Skip if already shown
            if (_shownInviteIds.contains(inviteId)) continue;

            // Check expiry
            final expiresAt = data['expiresAt'] as Timestamp?;
            if (expiresAt != null &&
                expiresAt.toDate().isBefore(DateTime.now())) {
              continue;
            }

            _shownInviteIds.add(inviteId);
            _showInvitePopup(inviteId, data);
          }
        }
      },
      onError: (error) {
        debugPrint('[GameInviteListener] Stream error: $error');
      },
    );
  }

  void _showInvitePopup(String inviteId, Map<String, dynamic> data) {
    if (_isShowingPopup || !mounted) return;

    _isShowingPopup = true;

    final roomId = data['roomId'] as String? ?? '';
    final hostNickname = data['hostNickname'] as String? ?? 'Someone';
    final hostPhotoUrl = data['hostPhotoUrl'] as String?;
    final gameName = data['gameName'] as String? ?? 'a game';
    final gameType = data['gameType'] as String? ?? '';
    final targetLanguage = data['targetLanguage'] as String? ?? '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => GameInvitePopup(
        inviteId: inviteId,
        roomId: roomId,
        hostNickname: hostNickname,
        hostPhotoUrl: hostPhotoUrl,
        gameName: gameName,
        gameType: gameType,
        targetLanguage: targetLanguage,
        onAccept: () {
          Navigator.of(dialogContext).pop();
          _isShowingPopup = false;
          _acceptInvite(inviteId, roomId);
        },
        onDecline: () {
          Navigator.of(dialogContext).pop();
          _isShowingPopup = false;
          _declineInvite(inviteId);
        },
      ),
    ).then((_) {
      _isShowingPopup = false;
    });
  }

  Future<void> _acceptInvite(String inviteId, String roomId) async {
    try {
      // Update invite status
      await FirebaseFirestore.instance
          .collection('game_invites')
          .doc(inviteId)
          .update({'status': 'accepted'});

      if (!mounted) return;

      // Create a new bloc for the game and join the room
      final bloc = di.sl<LanguageGamesBloc>();
      bloc.add(JoinRoom(
        roomId: roomId,
        userId: widget.userId,
        displayName: widget.displayName,
      ));

      // Wait briefly for the join to complete, then navigate
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // Listen for the InRoom state and navigate
      final state = bloc.state;
      if (state is LanguageGamesInRoom) {
        _navigateToGame(bloc, state.room);
      } else {
        // Set up a listener for when join completes
        late StreamSubscription sub;
        sub = bloc.stream.listen((state) {
          if (state is LanguageGamesInRoom) {
            sub.cancel();
            if (mounted) {
              _navigateToGame(bloc, state.room);
            }
          }
        });

        // Timeout after 5 seconds
        Future.delayed(const Duration(seconds: 5), () {
          sub.cancel();
        });
      }
    } catch (e) {
      debugPrint('[GameInviteListener] Accept invite error: $e');
    }
  }

  void _navigateToGame(LanguageGamesBloc bloc, GameRoom room) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: GameWaitingScreen(
            userId: widget.userId,
            displayName: widget.displayName,
            room: room,
          ),
        ),
      ),
    );
  }

  Future<void> _declineInvite(String inviteId) async {
    try {
      await FirebaseFirestore.instance
          .collection('game_invites')
          .doc(inviteId)
          .update({'status': 'declined'});
    } catch (e) {
      debugPrint('[GameInviteListener] Decline invite error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
