import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/safe_navigation.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../generated/app_localizations.dart';

/// A single follower row's display data (name + avatar), resolved from the
/// follower's public profile.
class _Follower {
  const _Follower({required this.uid, required this.name, this.photoUrl});
  final String uid;
  final String name;
  final String? photoUrl;
}

/// Business Followers screen.
///
/// Shows the people who follow this business — a BOUNDED list read straight
/// from `business_followers/{businessId}/followers` (newest first, capped),
/// with each follower's name/avatar loaded from their public profile in
/// batched `whereIn` reads. Glass, Apple-safe, index-light: a single ordered
/// subcollection read plus batched profile lookups, no composite index and no
/// unbounded fan-out (see [FollowService] for the denormalized follow model).
class FollowersScreen extends StatefulWidget {
  const FollowersScreen({required this.businessId, super.key});

  final String businessId;

  /// How many followers we surface at most — keeps the screen bounded.
  static const int kMaxFollowers = 100;

  static Route<void> route({required String businessId}) {
    return MaterialPageRoute<void>(
      builder: (_) => FollowersScreen(businessId: businessId),
    );
  }

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Future<List<_Follower>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadFollowers();
  }

  /// Bounded load: newest followers first, then their profiles in batches of 10.
  Future<List<_Follower>> _loadFollowers() async {
    final orderedUids = <String>[];
    try {
      final snap = await _firestore
          .collection('business_followers')
          .doc(widget.businessId)
          .collection('followers')
          .orderBy('createdAt', descending: true)
          .limit(FollowersScreen.kMaxFollowers)
          .get();
      for (final d in snap.docs) {
        orderedUids.add(d.id);
      }
    } catch (_) {
      // Some followers may lack a createdAt (legacy) — fall back to an
      // unordered, still-bounded read so the list is never empty on error.
      try {
        final snap = await _firestore
            .collection('business_followers')
            .doc(widget.businessId)
            .collection('followers')
            .limit(FollowersScreen.kMaxFollowers)
            .get();
        for (final d in snap.docs) {
          orderedUids.add(d.id);
        }
      } catch (_) {
        return const [];
      }
    }

    // Resolve names/avatars from public profiles in batches of 10 (whereIn cap).
    final profiles = <String, Map<String, dynamic>>{};
    for (var i = 0; i < orderedUids.length; i += 10) {
      final batch = orderedUids.skip(i).take(10).toList();
      if (batch.isEmpty) break;
      try {
        final snap = await _firestore
            .collection('profiles')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        for (final d in snap.docs) {
          profiles[d.id] = d.data();
        }
      } catch (_) {
        // Skip this batch; those rows degrade to a placeholder name.
      }
    }

    return [
      for (final uid in orderedUids)
        _Follower(
          uid: uid,
          name: (profiles[uid]?['displayName'] as String?)?.trim().isNotEmpty ==
                  true
              ? profiles[uid]!['displayName'] as String
              : 'GreenGo member',
          photoUrl: _firstPhoto(profiles[uid]),
        ),
    ];
  }

  String? _firstPhoto(Map<String, dynamic>? data) {
    if (data == null) return null;
    final urls = (data['photoUrls'] ?? data['photos']);
    if (urls is List && urls.isNotEmpty) {
      final first = urls.first;
      if (first is String && first.isNotEmpty) return first;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => SafeNavigation.pop(context),
        ),
        title: Text(
          l10n.businessFollowersTitle,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: FutureBuilder<List<_Follower>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.richGold),
              ),
            );
          }
          final followers = snapshot.data ?? const [];
          if (followers.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                child: Text(
                  l10n.businessNoFollowers,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            itemCount: followers.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    l10n.businessFollowersCount(followers.length),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }
              return _followerTile(followers[index - 1]);
            },
          );
        },
      ),
    );
  }

  Widget _followerTile(_Follower f) {
    return GlassContainer(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.richGold.withOpacity(0.15),
            backgroundImage:
                (f.photoUrl != null) ? NetworkImage(f.photoUrl!) : null,
            child: (f.photoUrl == null)
                ? const Icon(Icons.person, color: AppColors.richGold)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              f.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
