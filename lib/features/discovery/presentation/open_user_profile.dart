import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/di/injection_container.dart' as di;
import '../../../core/services/blocked_users_service.dart';
import '../../profile/domain/entities/profile.dart';
import '../../profile/domain/repositories/profile_repository.dart';
import 'screens/profile_detail_screen.dart';

/// "Profile first": opens [ProfileDetailScreen] for [userId] — the single
/// entry point for any tap on a person that only knows their id (deep links,
/// notifications, …). The chat is then one tap away via the profile's app-bar
/// chat button, which runs the normal connect gates.
///
/// * Never opens anything when [userId] is empty or the viewer is signed out.
/// * Skips users who are blocked in either direction (same rule as the people
///   lists, which filter them out).
/// * Loads the [Profile] (time-bounded) when the caller does not have it.
///
/// Returns `true` when the profile screen was pushed.
Future<bool> openUserProfile(
  BuildContext context, {
  required String currentUserId,
  required String userId,
  Profile? profile,
}) async {
  if (userId.isEmpty || currentUserId.isEmpty) return false;
  final navigator = Navigator.of(context);

  if (userId != currentUserId) {
    try {
      final blocked = await di
          .sl<BlockedUsersService>()
          .getBlockedUserIds(currentUserId)
          .timeout(const Duration(seconds: 8));
      if (blocked.contains(userId)) return false;
    } catch (_) {
      // Unknown block state — the profile screen's own safety menu still
      // applies; never hang here.
    }
  }

  var target = profile;
  if (target == null) {
    try {
      final result = await di
          .sl<ProfileRepository>()
          .getProfile(userId)
          .timeout(const Duration(seconds: 10));
      target = result.fold((_) => null, (p) => p);
    } catch (_) {
      target = null;
    }
  }
  if (target == null || !navigator.mounted) return false;

  final loaded = target;
  unawaited(navigator.push(
    MaterialPageRoute<void>(
      builder: (_) => ProfileDetailScreen(
        profile: loaded,
        currentUserId: currentUserId,
      ),
    ),
  ));
  return true;
}
