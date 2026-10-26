import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/business_categories.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/user_directory_service.dart';
import '../../../../generated/app_localizations.dart';
import '../../../business/data/services/follow_service.dart';
import '../../../business/presentation/screens/business_storefront_screen.dart';
import '../../../profile/domain/entities/profile.dart';

/// The business accounts the signed-in user follows (own-profile "Stores").
///
/// PRIVATE: only ever for the signed-in user's own uid (the mirror collection
/// is owner-only in the rules). One page = ONE query on the own mirror
/// (`isStore == true`, document-id order, 30 per page, endless scroll); the
/// profiles come from [UserDirectoryService] (cache-first, batched). Tap ->
/// storefront.
class FollowedStoresScreen extends StatefulWidget {
  const FollowedStoresScreen({required this.userId, super.key});

  final String userId;

  static Route<void> route({required String userId}) => MaterialPageRoute<void>(
        builder: (_) => FollowedStoresScreen(userId: userId),
      );

  @override
  State<FollowedStoresScreen> createState() => _FollowedStoresScreenState();
}

class _FollowedStoresScreenState extends State<FollowedStoresScreen> {
  final List<Profile> _stores = [];
  final Set<String> _seen = {};
  final ScrollController _scroll = ScrollController();
  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  bool _loading = false;
  bool _done = false;
  bool _error = false;

  FollowService get _service => di.sl<FollowService>();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 400) {
        _loadMore();
      }
    });
    _loadMore();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadMore() async {
    if (_loading || _done || widget.userId.isEmpty) return;
    setState(() => _loading = true);
    try {
      final page = await _service.followedStoresPage(widget.userId, after: _cursor);
      final ids = page.userIds.where(_seen.add).toList();
      final profiles = ids.isEmpty
          ? const <String, Profile?>{}
          : await UserDirectoryService.instance.resolveProfiles(ids);
      if (!mounted) return;
      setState(() {
        for (final id in ids) {
          final p = profiles[id];
          // A fully hidden store reads as a personal profile: not listed.
          if (p != null && p.isBusiness) _stores.add(p);
        }
        _cursor = page.cursor;
        _done = !page.hasMore;
      });
    } catch (_) {
      if (mounted) setState(() => _error = _done = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final empty = _stores.isEmpty && _done && !_loading;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(l10n.userFollowStoresLabel,
            style: const TextStyle(color: AppColors.textPrimary)),
      ),
      body: empty
          ? Center(
              key: const Key('followed_stores_empty'),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_error ? Icons.cloud_off_outlined : Icons.storefront_outlined,
                        size: 36, color: AppColors.textTertiary),
                    const SizedBox(height: 10),
                    Text(
                      _error ? l10n.userFollowListError : l10n.userFollowEmptyStores,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              controller: _scroll,
              itemCount: _stores.length + (_done ? 0 : 1),
              itemBuilder: (context, i) {
                if (i >= _stores.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.richGold),
                    ),
                  );
                }
                final p = _stores[i];
                final name = (p.businessName ?? '').trim().isNotEmpty
                    ? p.businessName!.trim()
                    : p.displayName;
                final category = p.businessCategory;
                final logo = p.photoUrls.isNotEmpty ? p.photoUrls.first : null;
                return ListTile(
                  key: ValueKey('followed_store_${p.userId}'),
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.backgroundCard,
                    backgroundImage:
                        logo != null ? CachedNetworkImageProvider(logo) : null,
                    child: logo == null
                        ? const Icon(Icons.storefront, color: AppColors.richGold)
                        : null,
                  ),
                  title: Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                  subtitle: category == null || category.isEmpty
                      ? null
                      : Text(localizedBusinessCategory(l10n, category),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.textTertiary, fontSize: 12.5)),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BusinessStorefrontScreen(
                        business: p,
                        currentUserId: widget.userId,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
