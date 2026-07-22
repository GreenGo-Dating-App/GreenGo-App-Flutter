import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection_container.dart' as di;
import '../../../core/services/tier_gate.dart';
import '../../../generated/app_localizations.dart';
import '../../profile/domain/entities/profile.dart';
import '../../profile/domain/repositories/profile_repository.dart';
import '../data/datasources/chat_remote_datasource.dart';
import 'screens/chat_screen.dart';

/// Shared "Connect" action for the Apple-safe cultural-exchange build.
///
/// Opens a one-to-one chat with [otherUserId] IMMEDIATELY, with NO approval /
/// acceptance step. It routes through
/// [ChatRemoteDataSource.getOrCreateSearchConversation] which creates a search
/// conversation with `visibleTo: null` — instantly visible to BOTH users — so
/// the first message arrives without any like / super-like / match / accept
/// gate. This is deliberately NOT the full-flavor super-like/priority-connect
/// approval path.
///
/// Callers that already hold the other user's [Profile] (people grids, profile
/// detail) should pass it via [otherUserProfile] to skip an extra network read;
/// otherwise it is fetched on demand.
Future<void> openConnectChat(
  BuildContext context, {
  required String currentUserId,
  required String otherUserId,
  Profile? otherUserProfile,
  bool businessInquiry = false,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final tierGate = TierGate();

  // Brief modal loading barrier while we resolve/create the conversation.
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    builder: (_) => const Center(
      child: CircularProgressIndicator(color: AppColors.richGold),
    ),
  );

  try {
    // Resolve the other user's profile (needed by ChatScreen).
    var profile = otherUserProfile;
    if (profile == null) {
      final result =
          await di.sl<ProfileRepository>().getProfile(otherUserId);
      profile = result.fold((_) => null, (p) => p);
    }
    if (profile == null) {
      throw Exception('profile-unavailable');
    }

    // Is this a NEW connection? Only NEW connects count against — and are gated
    // by — the per-tier daily cap; re-opening an existing chat is always free.
    // Mirrors ChatRemoteDataSource.getOrCreateSearchConversation's synthetic id.
    final sortedIds = [currentUserId, otherUserId]..sort();
    // Must mirror getOrCreateSearchConversation: business inquiries live in
    // their own directional conversation, separate from the personal chat.
    final syntheticMatchId = businessInquiry
        ? 'bizsearch_${otherUserId}_$currentUserId'
        : 'search_${sortedIds[0]}_${sortedIds[1]}';
    final existing = await FirebaseFirestore.instance
        .collection('conversations')
        .where('matchId', isEqualTo: syntheticMatchId)
        .limit(1)
        .get();
    final isNewConnect = existing.docs.isEmpty;

    // Gate NEW connects against MembershipTier.maxDailyConnects. ∞ tiers never
    // block. On deny: dismiss the barrier, show the upgrade dialog, and return
    // WITHOUT opening the chat.
    if (isNewConnect) {
      final gate = await tierGate.canConnectToday(currentUserId);
      if (!gate.allowed) {
        if (navigator.canPop()) navigator.pop();
        if (context.mounted) {
          await tierGate.showConnectLimitDialog(context, currentUserId, gate);
        }
        return;
      }
    }

    // Create / fetch the immediately-visible search conversation (no approval).
    final conversation =
        await di.sl<ChatRemoteDataSource>().getOrCreateSearchConversation(
              currentUserId: currentUserId,
              otherUserId: otherUserId,
              businessInquiry: businessInquiry,
            );

    // Count a successful NEW connection toward today's cap (fire-and-forget).
    if (isNewConnect) {
      unawaited(tierGate.recordConnect(currentUserId));
    }

    // Dismiss the loading barrier before navigating.
    if (navigator.canPop()) navigator.pop();

    await navigator.push(
      MaterialPageRoute<void>(
        builder: (context) => ChatScreen(
          matchId: conversation.matchId,
          currentUserId: currentUserId,
          otherUserId: otherUserId,
          otherUserProfile: profile!,
        ),
      ),
    );
  } catch (_) {
    // Dismiss the loading barrier if it is still up.
    if (navigator.canPop()) navigator.pop();
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.connectError)),
    );
  }
}
