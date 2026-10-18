import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/user_error.dart';
import '../../../generated/app_localizations.dart';
import '../../profile/domain/entities/profile.dart';
import '../data/models/conversation_model.dart';
import '../domain/entities/conversation_listing_context.dart';
import 'connect_and_chat.dart';
import 'screens/chat_screen.dart';

/// The listing a buyer <-> organizer chat is about.
@immutable
class ListingChatRef {
  const ListingChatRef({
    required this.type,
    required this.id,
    this.title = '',
    this.startAt,
    this.organizerId,
  });

  /// [ConversationListingContext.event] or [ConversationListingContext.experience].
  final String type;
  final String id;
  final String title;
  final DateTime? startAt;

  /// Known organizer / host uid (null from a deep link: the server resolves it).
  final String? organizerId;

  ConversationListingContext toContext() => ConversationListingContext(
      type: type, id: id, title: title, startAt: startAt);
}

/// What the server (`openListingChat`) decided.
@immutable
class ListingChatAccess {
  const ListingChatAccess({
    required this.buyer,
    required this.organizerId,
    required this.businessInquiry,
    this.conversationId,
    this.context,
  });

  /// Verified ticket holder / booked guest: the conversation was created or
  /// updated by the server, outside the daily new-connection cap.
  final bool buyer;
  final String organizerId;
  final bool businessInquiry;
  final String? conversationId;
  final ConversationListingContext? context;

  factory ListingChatAccess.fromMap(Map<String, dynamic> d) => ListingChatAccess(
        buyer: d['buyer'] == true,
        organizerId: (d['organizerId'] as String?) ?? '',
        businessInquiry: d['businessInquiry'] == true,
        conversationId: d['conversationId'] as String?,
        context: ConversationListingContext.fromMap(d['context']),
      );
}

/// Refusals the user should hear about (not retried through the open flow).
class ListingChatRefused implements Exception {
  const ListingChatRefused(this.reason);
  final String reason; // own_listing | blocked | listing_not_found
}

typedef ListingChatVerify = Future<ListingChatAccess> Function(ListingChatRef listing);

/// Opens a known (server-created) conversation in the chat screen.
typedef ListingChatOpenKnown = Future<void> Function(
  BuildContext context, {
  required String currentUserId,
  required String organizerId,
  required String conversationId,
  ConversationListingContext? listingContext,
});

/// The normal connect flow (the per-tier daily cap applies), see [openConnectChat].
typedef ListingChatOpenConnect = Future<void> Function(
  BuildContext context, {
  required String currentUserId,
  required String otherUserId,
  bool? businessInquiry,
  ConversationListingContext? listingContext,
});

/// "Message the organizer" / "Message the host" (2026-10-17).
///
///  1. Asks the server (`openListingChat`) whether the user holds a valid
///     ticket / booking for the listing. The server never trusts the app:
///     it reads the attendee row / bookings itself.
///  2. Buyer: the server already created / updated the conversation with a
///     verified `context.buyer` (no daily cap, any plan) -> open it.
///  3. Not a buyer (or the server is unreachable): the normal connect flow,
///     with its tier gate and server-enforced daily cap, plus the topic card.
class ListingChatFlow {
  ListingChatFlow({
    ListingChatVerify? verify,
    ListingChatOpenKnown? openKnown,
    ListingChatOpenConnect? openConnect,
  })  : _verify = verify ?? _verifyOnServer,
        _openKnown = openKnown ?? _openKnownConversation,
        _openConnect = openConnect ?? _openConnectDefault;

  static ListingChatFlow instance = ListingChatFlow();

  final ListingChatVerify _verify;
  final ListingChatOpenKnown _openKnown;
  final ListingChatOpenConnect _openConnect;

  static Future<ListingChatAccess> _verifyOnServer(ListingChatRef l) async {
    try {
      final res = await FirebaseFunctions.instance
          .httpsCallable('openListingChat',
              options: HttpsCallableOptions(timeout: const Duration(seconds: 15)))
          .call<Map<String, dynamic>>({'type': l.type, 'id': l.id});
      return ListingChatAccess.fromMap(Map<String, dynamic>.from(res.data));
    } on FirebaseFunctionsException catch (e) {
      final m = e.message ?? '';
      if (m == 'own_listing' || m == 'blocked' || m == 'listing_not_found') {
        throw ListingChatRefused(m);
      }
      rethrow;
    }
  }

  static Future<void> _openConnectDefault(
    BuildContext context, {
    required String currentUserId,
    required String otherUserId,
    bool? businessInquiry,
    ConversationListingContext? listingContext,
  }) =>
      openConnectChat(
        context,
        currentUserId: currentUserId,
        otherUserId: otherUserId,
        businessInquiry: businessInquiry,
        listingContext: listingContext,
      );

  Future<void> open(
    BuildContext context, {
    required String currentUserId,
    required ListingChatRef listing,
  }) async {
    if (currentUserId.isEmpty) return;
    if (listing.organizerId == currentUserId) return; // never chat with yourself
    final l10n = AppLocalizations.of(context)!;

    ListingChatAccess? access;
    try {
      access = await _withBarrier(
          context, _verify(listing).timeout(const Duration(seconds: 15)));
    } on ListingChatRefused {
      if (context.mounted) showUserErrorMessage(context, l10n.connectError);
      return;
    } catch (_) {
      access = null; // server unreachable: the normal (capped) flow below
    }
    if (!context.mounted) return;

    final organizerId = (access?.organizerId.isNotEmpty ?? false)
        ? access!.organizerId
        : (listing.organizerId ?? '');
    if (organizerId.isEmpty || organizerId == currentUserId) {
      if (organizerId.isEmpty) showUserErrorMessage(context, l10n.connectError);
      return;
    }
    final topic = access?.context ?? listing.toContext();

    if (access != null && access.buyer && (access.conversationId ?? '').isNotEmpty) {
      await _openKnown(
        context,
        currentUserId: currentUserId,
        organizerId: organizerId,
        conversationId: access.conversationId!,
        listingContext: topic,
      );
      return;
    }
    await _openConnect(
      context,
      currentUserId: currentUserId,
      otherUserId: organizerId,
      // Known from the server; otherwise decided from the organizer profile.
      businessInquiry: access?.businessInquiry,
      listingContext: topic.copyWith(buyer: false),
    );
  }
}

/// Spinner while [work] runs. The route is removed by identity, so a
/// dialog shown meanwhile (an error) is never popped instead of it.
Future<T> _withBarrier<T>(BuildContext context, Future<T> work) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final route = DialogRoute<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.richGold)),
  );
  unawaited(navigator.push(route));
  try {
    return await work;
  } finally {
    if (route.isActive) navigator.removeRoute(route);
  }
}

Future<void> _openKnownConversation(
  BuildContext context, {
  required String currentUserId,
  required String organizerId,
  required String conversationId,
  ConversationListingContext? listingContext,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final navigator = Navigator.of(context);
  try {
    final results = await _withBarrier(
      context,
      Future.wait<Object?>([
        FirebaseFirestore.instance
            .collection('conversations')
            .doc(conversationId)
            .get()
            .timeout(const Duration(seconds: 10)),
        resolveChatProfile(organizerId),
      ]),
    );
    final snap = results[0]! as DocumentSnapshot<Map<String, dynamic>>;
    final profile = results[1] as Profile?;
    if (!snap.exists || profile == null) throw StateError('unavailable');
    var conversation = ConversationModel.fromFirestore(snap);
    if (conversation.listingContext == null && listingContext != null) {
      conversation = ConversationModel.fromEntity(
          conversation.copyWith(listingContext: listingContext));
    }
    await navigator.push(MaterialPageRoute<void>(
      builder: (_) => ChatScreen(
        matchId: conversation.matchId,
        currentUserId: currentUserId,
        otherUserId: organizerId,
        otherUserProfile: profile,
        initialConversation: conversation,
      ),
    ));
  } catch (_) {
    if (context.mounted) showUserErrorMessage(context, l10n.connectError);
  }
}

/// Convenience used by the buttons and deep links.
Future<void> openListingChat(
  BuildContext context, {
  required String currentUserId,
  required ListingChatRef listing,
}) =>
    ListingChatFlow.instance
        .open(context, currentUserId: currentUserId, listing: listing);
