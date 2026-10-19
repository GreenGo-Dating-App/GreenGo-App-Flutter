import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../generated/app_localizations.dart';
import '../../../chat/presentation/connect_and_chat.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../data/services/leads_service.dart';

/// The storefront header's primary "Chat" action, right next to Share.
///
/// Opens the BUSINESS chat ([openConnectChat] with `businessInquiry: true`,
/// routed to the owner's Business inbox) and logs a `contact` lead
/// (fire-and-forget). Hidden for the owner viewing their own storefront and
/// for signed-out viewers ([visibleFor]).
class StorefrontChatButton extends StatelessWidget {
  const StorefrontChatButton({
    required this.business,
    required this.currentUserId,
    this.onChat,
    super.key,
  });

  final Profile business;
  final String currentUserId;

  /// Test hook; defaults to logging the lead and opening the business chat.
  final VoidCallback? onChat;

  static bool visibleFor({required String currentUserId, required String businessId}) =>
      currentUserId.isNotEmpty && businessId.isNotEmpty && currentUserId != businessId;

  void _chat(BuildContext context) {
    HapticFeedback.mediumImpact();
    if (onChat != null) return onChat!();
    unawaited(di.sl<LeadsService>()
        .logContactLead(businessId: business.userId, uid: currentUserId)
        .catchError((Object _) {}));
    openConnectChat(
      context,
      currentUserId: currentUserId,
      otherUserId: business.userId,
      otherUserProfile: business,
      businessInquiry: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!visibleFor(currentUserId: currentUserId, businessId: business.userId)) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    return ElevatedButton.icon(
      key: const ValueKey('storefront-chat-button'),
      onPressed: () => _chat(context),
      icon: const Icon(Icons.chat_bubble_outline, size: 18),
      label: Text(l10n.storefrontChatButton),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.richGold,
        foregroundColor: AppColors.deepBlack,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }
}
