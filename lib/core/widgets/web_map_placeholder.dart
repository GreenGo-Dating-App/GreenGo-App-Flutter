import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../../generated/app_localizations.dart';

/// Graceful fallback shown in place of a `GoogleMap` on the web build.
///
/// The web target has no Google Maps JS key configured, so `GoogleMap`
/// renders a broken tile area. On web we swap it for this clean placeholder;
/// the surrounding search/confirm controls stay fully functional, matching the
/// mobile experience as closely as the web platform allows.
class WebMapPlaceholder extends StatelessWidget {
  const WebMapPlaceholder({super.key, this.compact = false});

  /// Tighter layout for small preview tiles (hides the body text).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: AppColors.backgroundCard,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.map_outlined,
              size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          Text(
            l10n.webMapUnavailableTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 6),
            Text(
              l10n.webMapUnavailableBody,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}
