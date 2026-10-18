import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/user_error.dart';
import '../../../core/utils/conversation_queries.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection_container.dart' as di;
import '../../../core/services/tier_gate.dart';
import '../../membership/domain/entities/membership.dart';
import '../../../core/services/user_directory_service.dart';
import '../../../generated/app_localizations.dart';
import '../../profile/domain/entities/profile.dart';
import '../../profile/domain/repositories/profile_repository.dart';
import '../data/datasources/chat_remote_datasource.dart';
import '../data/models/conversation_model.dart';
import '../domain/entities/conversation_listing_context.dart';
import 'screens/chat_screen.dart';
import '../../safety/data/services/age_assurance_service.dart';
import '../../safety/presentation/screens/age_assurance_required_screen.dart';

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
  bool? businessInquiry,
  ConversationListingContext? listingContext,
  bool businessOwnerSide = false,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final tierGate = TierGate();

  // From a listing ("Message the organizer"): the organizer's storefront is
  // chosen automatically (no person/business sheet), like the server does.
  if (listingContext != null && businessInquiry == null) {
    final p = otherUserProfile ?? await resolveChatProfile(otherUserId)
        .catchError((Object _) => null);
    businessInquiry = p != null && p.isBusiness &&
        (p.businessName?.isNotEmpty ?? false);
    otherUserProfile ??= p;
  }
  if (!context.mounted) return;
  // Business Center > Customers: the owner writes to a customer from the
  // business inbox (bizsearch_{owner}_{customer}).
  if (businessOwnerSide) businessInquiry = true;

  // Resolve WHICH identity to chat with. When the caller didn't force it
  // (businessInquiry == null) and the target is a business storefront, ask the
  // user: chat with the PERSON (user-to-user) or the BUSINESS (user-to-business)?
  // Explore / Discovery cards pass no flag, so tapping a business profile opens
  // this choice; the "Contact business" button forces businessInquiry: true.
  var isBusinessChat = businessInquiry ?? false;
  final choiceProfile = otherUserProfile;
  final targetIsBusiness = choiceProfile != null &&
      choiceProfile.isBusiness &&
      (choiceProfile.businessName?.isNotEmpty ?? false);
  if (businessInquiry == null && targetIsBusiness) {
    final choice =
        await _askBusinessOrPersonChat(context, choiceProfile!, l10n);
    if (choice == null) return; // user dismissed the sheet — open nothing
    isBusinessChat = choice;
  }

  // Brief modal loading barrier while we resolve/create the conversation.
  //
  // CRITICAL: showDialog defaults to useRootNavigator:true, so the barrier is
  // pushed onto the ROOT navigator. In the Apple-safe build the Explore /
  // Discovery tabs run inside their OWN nested tab-Navigator, so popping the
  // *nearest* navigator (as the old code did) targeted the WRONG navigator and
  // the barrier was never dismissed — THE persistent endless-spinner cause. We
  // capture the dialog's own context and pop THAT, which always resolves to the
  // navigator the barrier actually lives on, regardless of nested tab stacks.
  BuildContext? barrierContext;
  var barrierUp = true;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    builder: (dialogCtx) {
      barrierContext = dialogCtx;
      return const Center(
        child: CircularProgressIndicator(color: AppColors.richGold),
      );
    },
  );

  // GUARANTEED barrier dismissal (called in success, deny, catch AND finally),
  // combined with the time-bounded reads below, makes it impossible for the
  // spinner to outlive this call.
  void dismissBarrier() {
    if (!barrierUp) return;
    barrierUp = false;
    final bc = barrierContext;
    if (bc != null && bc.mounted) {
      Navigator.of(bc).pop();
    }
  }

  try {
    // Resolve the other user's profile (needed by ChatScreen) CONCURRENTLY
    // with the conversation lookup below: shared user directory first (memory
    // / disk cached, batched), then the repository. Awaited before anything
    // is created, so a missing profile still opens nothing.
    final Future<Profile?> profileFuture = otherUserProfile != null
        ? Future.value(otherUserProfile)
        : _resolveProfile(otherUserId);
    // Never leave an unobserved error if the lookup below throws first.
    unawaited(profileFuture.then((_) {}, onError: (Object _) {}));

    // Is this a NEW connection? Only NEW connects count against — and are gated
    // by — the per-tier daily cap; re-opening an existing chat is always free.
    // Mirrors ChatRemoteDataSource.getOrCreateSearchConversation's synthetic id.
    final sortedIds = [currentUserId, otherUserId]..sort();
    // Must mirror getOrCreateSearchConversation: business inquiries live in
    // their own directional conversation, separate from the personal chat.
    final syntheticMatchId = businessOwnerSide
        ? 'bizsearch_${currentUserId}_$otherUserId'
        : isBusinessChat
            ? 'bizsearch_${otherUserId}_$currentUserId'
            : 'search_${sortedIds[0]}_${sortedIds[1]}';
    // Existence check is CACHE-FIRST: for a returning user (the conversation is
    // already in the local Firestore cache) this resolves INSTANTLY with no
    // network round-trip, so re-opening a chat is immediate. Only a cache miss
    // falls through to a (time-bounded) server read.
    final scoped = conversationsByMatchId(
      FirebaseFirestore.instance,
      syntheticMatchId,
      uid: currentUserId,
    );
    QuerySnapshot<Map<String, dynamic>> existing;
    try {
      existing = await scoped
          .limit(1)
          .get(const GetOptions(source: Source.cache));
      if (existing.docs.isEmpty) {
        throw StateError('cache-miss'); // fall through to server below
      }
    } catch (_) {
      existing = await scoped
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 10));
    }
    final isNewConnect = existing.docs.isEmpty;

    final profile = await profileFuture;
    if (profile == null) {
      throw Exception('profile-unavailable');
    }

    final dataSource = di.sl<ChatRemoteDataSource>();

    ConversationModel conversation;
    if (isNewConnect &&
        await AgeAssuranceService.instance.isBlocked()) {
      // P3-1: a NEW private conversation needs age assurance where the law
      // requires it. Existing conversations still open below.
      dismissBarrier();
      if (context.mounted) {
        final ok = await AgeAssuranceGuard.ensureCanStartConversation(context);
        if (ok && context.mounted) {
          await openConnectChat(
            context,
            currentUserId: currentUserId,
            otherUserId: otherUserId,
            otherUserProfile: otherUserProfile,
            businessInquiry: isBusinessChat,
            listingContext: listingContext,
            businessOwnerSide: businessOwnerSide,
          );
        }
      }
      return;
    }
    if (isNewConnect) {
      // NEW connect: the daily cap is enforced by the SERVER (the rules refuse
      // the create over the cap; the counter is entitlement_usage/{uid}). The
      // gate runs FIRST and the create only when it allows: the old
      // concurrent create left a conversation behind on a denied tap, and
      // the next tap opened it with no gate (audit P-H1).
      TierGateResult? gate;
      try {
        gate = await tierGate
            .canConnectToday(currentUserId)
            .timeout(const Duration(seconds: 8));
      } catch (_) {
        gate = null; // the server still enforces the cap on the create
      }
      if (gate != null && !gate.allowed) {
        dismissBarrier();
        if (context.mounted) {
          await tierGate.showConnectLimitDialog(context, currentUserId, gate);
        }
        return;
      }

      try {
        conversation = await dataSource
            .getOrCreateSearchConversation(
              currentUserId: currentUserId,
              otherUserId: otherUserId,
              businessInquiry: isBusinessChat,
              businessOwnerSide: businessOwnerSide,
            )
            .timeout(const Duration(seconds: 12));
      } catch (e) {
        // Refused by the server: the cap was reached since the gate read
        // (e.g. another device). Show the limit, not a generic error.
        if (e.toString().contains('permission-denied')) {
          final fresh = await tierGate
              .canConnectToday(currentUserId)
              .timeout(const Duration(seconds: 8))
              .catchError((Object _) => gate ??
                  const TierGateResult(
                      allowed: true,
                      tier: MembershipTier.free,
                      current: 0,
                      limit: null));
          if (!fresh.allowed) {
            dismissBarrier();
            if (context.mounted) {
              await tierGate.showConnectLimitDialog(
                  context, currentUserId, fresh);
            }
            return;
          }
        }
        rethrow;
      }
    } else {
      // Existing conversation: just fetch/ensure it (cache-first internally).
      conversation = await dataSource
          .getOrCreateSearchConversation(
            currentUserId: currentUserId,
            otherUserId: otherUserId,
            businessInquiry: isBusinessChat,
            businessOwnerSide: businessOwnerSide,
          )
          .timeout(const Duration(seconds: 12));
    }

    // Topic card ("About: <listing>"): stamp the latest listing on the
    // conversation (the history is kept). Best-effort, never blocks opening.
    if (listingContext != null &&
        !listingContext.sameListing(conversation.listingContext)) {
      final topic = listingContext.copyWith(buyer: false);
      try {
        await FirebaseFirestore.instance
            .collection('conversations')
            .doc(conversation.conversationId)
            .update({'context': topic.toClientMap()})
            .timeout(const Duration(seconds: 8));
      } catch (_) {
        // Offline / refused: the chat still opens; the chip shows locally.
      }
      conversation = ConversationModel.fromEntity(
          conversation.copyWith(listingContext: topic));
    }

    // Dismiss the loading barrier before navigating.
    dismissBarrier();

    await navigator.push(
      MaterialPageRoute<void>(
        builder: (context) => ChatScreen(
          matchId: conversation.matchId,
          currentUserId: currentUserId,
          otherUserId: otherUserId,
          otherUserProfile: profile,
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
    if (context.mounted) {
      showUserErrorMessage(context, l10n.connectError);
    } else {
      messenger.showSnackBar(SnackBar(content: Text(l10n.connectError)));
    }
  } finally {
    // Last-resort guarantee: the spinner can never outlive this function.
    dismissBarrier();
  }
}

/// Bottom sheet shown when the tapped profile is a BUSINESS: lets the user pick
/// whether to chat with the PERSON behind it (user-to-user) or the BUSINESS
/// storefront (user-to-business). Returns `true` for business, `false` for
/// person, `null` if dismissed.
Future<bool?> _askBusinessOrPersonChat(
  BuildContext context,
  Profile profile,
  AppLocalizations l10n,
) {
  final personName = profile.displayName;
  final businessName = profile.businessName ?? profile.displayName;
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.backgroundCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetCtx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          // Chat with the PERSON (user-to-user).
          ListTile(
            leading: const Icon(Icons.person, color: AppColors.richGold),
            title: Text(
              l10n.chatWithName(personName),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () => Navigator.of(sheetCtx).pop(false),
          ),
          // Chat with the BUSINESS storefront (user-to-business).
          ListTile(
            leading: const Icon(Icons.storefront, color: AppColors.richGold),
            title: Text(
              l10n.chatWithName(businessName),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () => Navigator.of(sheetCtx).pop(true),
          ),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
}

/// The other user's profile for opening a chat (see [_resolveProfile]).
Future<Profile?> resolveChatProfile(String uid) => _resolveProfile(uid);

/// The other user's profile for opening a chat: the shared directory's
/// cached copy when present, else its batched/cached resolve, else the
/// repository. Time-bounded; null when unavailable.
Future<Profile?> _resolveProfile(String uid) async {
  final directory = UserDirectoryService.instance;
  final cached = directory.cachedProfile(uid);
  if (cached != null) return cached;
  try {
    final map = await directory
        .resolveProfiles([uid]).timeout(const Duration(seconds: 10));
    final p = map[uid];
    if (p != null) return p;
  } catch (_) {
    // Fall through to the repository.
  }
  final result = await di
      .sl<ProfileRepository>()
      .getProfile(uid)
      .timeout(const Duration(seconds: 10));
  return result.fold((_) => null, (p) => p);
}
