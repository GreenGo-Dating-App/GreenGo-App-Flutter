import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../generated/app_localizations.dart';
import '../constants/app_colors.dart';
import '../services/location_change.dart';
import '../services/location_refresh_service.dart';
import '../services/app_sound_service.dart';

/// Gets a fresh position and saves it (see
/// [LocationRefreshService.refreshOnPull]).
typedef PullLocationRefresher = Future<PullLocationResult> Function(
    String userId,
    {bool? isTravelerActive});

/// Resolves a missing permission / off location services when the user taps
/// the snackbar action. Returns true when location is now usable (the pull is
/// then run again).
typedef LocationAccessResolver = Future<bool> Function(
    LocationSkipReason reason);

/// Swipe down = "update my location, then reload" (owner 2026-10-21: "when
/// the user is in Explore and swipes down, the location will be updated").
///
/// A [RefreshIndicator] that, on pull:
///  1. reads a fresh device / browser position and saves it through the
///     existing location write (throttled - [shouldWritePulledLocation]);
///     Traveler mode keeps the travel location (no GPS read);
///  2. ALWAYS reloads the content ([onReload]), whatever step 1 did;
///  3. tells the user what happened in a short snackbar - the city it was
///     updated to, or why it was not (permission / location off, with an
///     action to fix it; Traveler mode).
///
/// The child must be scrollable with [AlwaysScrollableScrollPhysics] so the
/// pull also works when the content is short or empty.
class LocationPullToRefresh extends StatelessWidget {
  const LocationPullToRefresh({
    super.key,
    required this.userId,
    required this.onReload,
    required this.child,
    this.isTravelerActive,
    this.onPullStateChanged,
    this.refresher,
    this.accessResolver,
    this.locationTimeout = const Duration(seconds: 8),
    this.color = AppColors.richGold,
    this.backgroundColor = AppColors.backgroundCard,
  });

  final String userId;

  /// Reloads the screen's content (nearest-first from the saved position).
  final Future<void> Function(PullLocationResult result) onReload;
  final Widget child;

  /// Current traveler state as the screen knows it; null lets the service
  /// read it from the stored profile.
  final bool? Function()? isTravelerActive;

  /// true when a pull starts, false when it ended (location + reload).
  final ValueChanged<bool>? onPullStateChanged;

  @visibleForTesting
  final PullLocationRefresher? refresher;
  @visibleForTesting
  final LocationAccessResolver? accessResolver;

  /// Upper bound for the location step; the reload never waits longer.
  final Duration locationTimeout;
  final Color color;
  final Color backgroundColor;

  static const Key snackBarKey = ValueKey('pull-location-snackbar');

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: color,
      backgroundColor: backgroundColor,
      onRefresh: () => _run(context),
      child: child,
    );
  }

  Future<void> _run(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l10n = AppLocalizations.of(context);
    onPullStateChanged?.call(true);
    AppSoundService().play(AppSound.refresh);
    try {
      final result = await _refreshLocation();
      if (messenger != null && l10n != null && context.mounted) {
        _showResult(context, messenger, l10n, result);
      }
      await onReload(result);
    } finally {
      onPullStateChanged?.call(false);
    }
  }

  Future<PullLocationResult> _refreshLocation() async {
    final refresh = refresher ??
        (String uid, {bool? isTravelerActive}) => LocationRefreshService()
            .refreshOnPull(uid, isTravelerActive: isTravelerActive);
    try {
      return await refresh(userId, isTravelerActive: isTravelerActive?.call())
          .timeout(locationTimeout,
              onTimeout: () => const PullLocationResult.skipped(
                  LocationSkipReason.unavailable));
    } catch (_) {
      return const PullLocationResult.skipped(LocationSkipReason.unavailable);
    }
  }

  void _showResult(BuildContext context, ScaffoldMessengerState messenger,
      AppLocalizations l10n, PullLocationResult result) {
    final reason = result.skipReason;
    final city = result.city?.trim() ?? '';
    final String text;
    SnackBarAction? action;
    switch (reason) {
      case null:
        text = !result.written
            ? l10n.pullLocationUpToDate
            : city.isNotEmpty
                ? l10n.pullLocationUpdatedCity(city)
                : l10n.pullLocationUpdated;
      case LocationSkipReason.traveler:
        text = l10n.pullLocationTravelerKept;
      case LocationSkipReason.serviceDisabled:
        text = l10n.pullLocationServiceOff;
        if (!kIsWeb) {
          action = _fixAction(context, l10n.pullLocationOpenSettings,
              LocationSkipReason.serviceDisabled);
        }
      case LocationSkipReason.permissionDenied:
        text = l10n.pullLocationPermissionOff;
        action = _fixAction(context, l10n.pullLocationAllow,
            LocationSkipReason.permissionDenied);
      case LocationSkipReason.permissionDeniedForever:
        text = kIsWeb
            ? l10n.pullLocationBlockedInBrowser
            : l10n.pullLocationPermissionOff;
        if (!kIsWeb) {
          action = _fixAction(context, l10n.pullLocationOpenSettings,
              LocationSkipReason.permissionDeniedForever);
        }
      case LocationSkipReason.unavailable:
        text = l10n.pullLocationUnavailable;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        key: snackBarKey,
        content: Text(text),
        action: action,
        duration: Duration(seconds: action == null ? 3 : 6),
      ));
  }

  SnackBarAction _fixAction(
      BuildContext context, String label, LocationSkipReason reason) {
    return SnackBarAction(
      label: label,
      textColor: color,
      onPressed: () async {
        final usable = await (accessResolver ?? _defaultAccessResolver)(reason);
        // Location just became available: update it and reload again
        // (without the spinner - the user is no longer pulling).
        if (usable && context.mounted) unawaited(_run(context));
      },
    );
  }

  static Future<bool> _defaultAccessResolver(LocationSkipReason reason) async {
    try {
      switch (reason) {
        case LocationSkipReason.serviceDisabled:
          await Geolocator.openLocationSettings();
          return false; // Re-checked on the next pull.
        case LocationSkipReason.permissionDenied:
          // On mobile this shows the system dialog (if the OS still allows
          // it); on web the browser prompt.
          final asked = await Geolocator.requestPermission();
          if (asked == LocationPermission.whileInUse ||
              asked == LocationPermission.always) {
            return true;
          }
          if (asked == LocationPermission.deniedForever && !kIsWeb) {
            await Geolocator.openAppSettings();
          }
          return false;
        case LocationSkipReason.permissionDeniedForever:
          await Geolocator.openAppSettings();
          return false;
        case LocationSkipReason.traveler:
        case LocationSkipReason.unavailable:
          return false;
      }
    } catch (_) {
      return false;
    }
  }
}
