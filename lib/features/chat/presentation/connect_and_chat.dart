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
import '../data/models/conversation_model.dart';
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

  // GUARANTEED barrier dismissal. Every Firestore read below is time-bounded,
  // and this closure (called in success, deny, catch AND finally) makes it
  // impossible for the spinner to stay up forever — the persistent P0 was an
  // unbounded .get() leaving an await pending, so the barrier's pop() was never
  // reached and `catch` never fired.
  var barrierUp = true;
  void dismissBarrier() {
    if (barrierUp && navigator.canPop()) {
      navigator.pop();
      barrierUp = false;
    }
  }

  try {
    // Resolve the other user's profile (needed by ChatScreen).
    var profile = otherUserProfile;
    if (profile == null) {
      final result = await di
          .sl<ProfileRepository>()
          .getProfile(otherUserId)
          .timeout(const Duration(seconds: 10));
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
    // Existence check is CACHE-FIRST: for a returning user (the conversation is
    // already in the local Firestore cache) this resolves INSTANTLY with no
    // network round-trip, so re-opening a chat is immediate. Only a cache miss
    // falls through to a (time-bounded) server read.
    final convs = FirebaseFirestore.instance.collection('conversations');
    QuerySnapshot<Map<String, dynamic>> existing;
    try {
      existing = await convs
          .where('matchId', isEqualTo: syntheticMatchId)
          .limit(1)
          .get(const GetOptions(source: Source.cache));
      if (existing.docs.isEmpty) {
        throw StateError('cache-miss'); // fall through to server below
      }
    } catch (_) {
      existing = await convs
          .where('matchId', isEqualTo: syntheticMatchId)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 10));
    }
    final isNewConnect = existing.docs.isEmpty;

    final dataSource = di.sl<ChatRemoteDataSource>();

    ConversationModel conversation;
    if (isNewConnect) {
      // NEW connect: run the daily-limit gate and the conversation create
      // CONCURRENTLY (they touch different docs) so the open is as fast as a
      // single round-trip instead of two sequential ones. Both are bounded.
      final createFuture = dataSource
          .getOrCreateSearchConversation(
            currentUserId: currentUserId,
            otherUserId: otherUserId,
            businessInquiry: businessInquiry,
          )
          .timeout(const Duration(seconds: 12));

      TierGateResult? gate;
      try {
        gate = await tierGate
            .canConnectToday(currentUserId)
            .timeout(const Duration(seconds: 8));
      } catch (_) {
        gate = null; // treat as allowed on timeout/error — never hang or block
      }
      if (gate != null && !gate.allowed) {
        dismissBarrier();
        // Let the (already in-flight) create settle so it doesn't leak, but we
        // do not open the chat.
        unawaited(createFuture.catchError((_) => throw Exception('ignored')));
        if (context.mounted) {
          await tierGate.showConnectLimitDialog(context, currentUserId, gate);
        }
        return;
      }

      conversation = await createFuture;
      // Count a successful NEW connection toward today's cap (fire-and-forget).
      unawaited(tierGate.recordConnect(currentUserId));
    } else {
      // Existing conversation: just fetch/ensure it (cache-first internally).
      conversation = await dataSource
          .getOrCreateSearchConversation(
            currentUserId: currentUserId,
            otherUserId: otherUserId,
            businessInquiry: businessInquiry,
          )
          .timeout(const Duration(seconds: 12));
    }

    // Dismiss the loading barrier before navigating.
    dismissBarrier();

    await navigator.push(
      MaterialPageRoute<void>(
        builder: (context) => ChatScreen(
          matchId: conversation.matchId,
          currentUserId: currentUserId,
          otherUserId: otherUserId,
          otherUserProfile: profile!,
          // Hand the just-created conversation straight to the chat so it opens
          // instantly — no re-fetch, no chance of hanging on the loading spinner.
          initialConversation: conversation,
        ),
      ),
    );
  } catch (_) {
    // Dismiss the loading barrier if it is still up (covers TimeoutException,
    // permission-denied, profile-unavailable, and any other failure).
    dismissBarrier();
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.connectError)),
    );
  } finally {
    // Last-resort guarantee: the spinner can never outlive this function.
    dismissBarrier();
  }
}
