import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/widgets/glass_container.dart';
import '../../../../generated/app_localizations.dart';
import '../../../explore/presentation/screens/network_discovery_screen.dart';
import '../../data/saved_searches_service.dart';
import '../../domain/entities/saved_search.dart';

/// Lists the user's saved discovery searches (glass), each with:
///  • Run    — re-opens the Network Discovery grid seeded with the saved
///             preferences + private people-tags + nickname query.
///  • Alerts — a toggle-only opt-in that persists `alertsEnabled` (see the
///             TODO(saved-search-alerts) note on the toggle handler).
///  • Delete — removes the saved search.
class SavedSearchesScreen extends StatelessWidget {
  const SavedSearchesScreen({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final service = di.sl<SavedSearchesService>();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          l10n.savedSearchesTitle,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: StreamBuilder<List<SavedSearch>>(
          stream: service.watch(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.richGold),
              );
            }
            final searches = snapshot.data ?? const <SavedSearch>[];
            if (searches.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    l10n.savedSearchEmpty,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              itemCount: searches.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _SavedSearchCard(
                userId: userId,
                search: searches[index],
                service: service,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SavedSearchCard extends StatelessWidget {
  const _SavedSearchCard({
    required this.userId,
    required this.search,
    required this.service,
  });

  final String userId;
  final SavedSearch search;
  final SavedSearchesService service;

  /// A short, human-readable summary of what this search filters by. Built from
  /// the saved data itself (interests, distance, languages, tags, query) so it
  /// needs no extra translated strings.
  String _summary() {
    final p = search.preferences;
    final parts = <String>[];
    if (search.query.trim().isNotEmpty) {
      parts.add('"${search.query.trim()}"');
    }
    if (search.tags.isNotEmpty) {
      parts.add('#${search.tags.join(' #')}');
    }
    if (p.preferredInterests.isNotEmpty) {
      parts.add(p.preferredInterests.join(', '));
    }
    if (p.preferredCountries.isNotEmpty) {
      parts.add(p.preferredCountries.join(', '));
    }
    if (p.languageFilter != null && p.languageFilter!.isNotEmpty) {
      parts.add(p.languageFilter!);
    }
    if (p.maxDistanceKm != null) {
      parts.add('≤ ${p.maxDistanceKm} km');
    }
    if (p.onlyOnlineNow) parts.add('online');
    if (p.onlyVerified) parts.add('verified');
    if (p.travelersOnly) parts.add('travelers');
    if (p.localGuidesOnly) parts.add('local guides');
    if (p.showMyNetwork) parts.add('my network');
    return parts.isEmpty ? '—' : parts.join(' · ');
  }

  void _run(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NetworkDiscoveryScreen(
          userId: userId,
          initialPreferences: search.preferences,
          initialTags: search.tags,
          initialQuery: search.query,
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      await service.delete(userId: userId, id: search.id);
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.somethingWentWrong)),
      );
    }
  }

  Future<void> _toggleAlerts(BuildContext context, bool enabled) async {
    // TODO(saved-search-alerts): This toggle only persists the opt-in flag. To
    // actually notify a user of "new matches" for a saved search, add a
    // scheduled Cloud Function (e.g. `notifySavedSearchMatches`) that, for each
    // `saved_searches/{userId}/searches/{id}` with `alertsEnabled == true`,
    // re-runs the saved `preferences` (+ tags/query) against the candidate pool,
    // diffs the result against a stored `lastSeenMatchIds`/`lastCheckedAt`
    // watermark, and sends an FCM push via the existing notifications pipeline
    // when new people appear — then advances the watermark. Client stays as-is.
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      await service.setAlerts(userId: userId, id: search.id, enabled: enabled);
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.somethingWentWrong)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GlassContainer(
      active: search.alertsEnabled,
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      search.name.isEmpty ? l10n.savedSearchesTitle : search.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _summary(),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: AppColors.textTertiary),
                tooltip: l10n.delete,
                onPressed: () => _delete(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              // Alerts toggle — persists the opt-in flag only (see TODO above).
              Icon(
                search.alertsEnabled
                    ? Icons.notifications_active
                    : Icons.notifications_off_outlined,
                size: 18,
                color: search.alertsEnabled
                    ? AppColors.richGold
                    : AppColors.textTertiary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.savedSearchAlertsToggle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Switch(
                value: search.alertsEnabled,
                activeColor: AppColors.richGold,
                onChanged: (v) => _toggleAlerts(context, v),
              ),
              const SizedBox(width: 4),
              TextButton.icon(
                onPressed: () => _run(context),
                icon: const Icon(Icons.play_arrow_rounded,
                    color: AppColors.richGold, size: 20),
                label: Text(
                  l10n.savedSearchRun,
                  style: const TextStyle(
                    color: AppColors.richGold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
