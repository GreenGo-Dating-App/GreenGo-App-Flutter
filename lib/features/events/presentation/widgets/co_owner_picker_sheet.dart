import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/blocked_users_service.dart';
import '../../../../core/services/user_directory_service.dart';
import '../../../../generated/app_localizations.dart';

/// A person who can be added as an event co-owner.
class CoOwnerCandidate {
  const CoOwnerCandidate({
    required this.userId,
    required this.name,
    this.photoUrl,
  });
  final String userId;
  final String name;
  final String? photoUrl;
}

/// Opens the "Add co-owner" picker: a nickname search plus the user's most
/// recent 1:1 chat partners. Resolves to the picked person, or null.
///
/// [excludeIds] (the creator, current co-owners) are never offered; the
/// signed-in user and anyone blocked in either direction are always excluded.
Future<CoOwnerCandidate?> showCoOwnerPicker(
  BuildContext context, {
  required String currentUserId,
  required Set<String> excludeIds,
}) {
  return showModalBottomSheet<CoOwnerCandidate>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.backgroundDark,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.85,
      child: _CoOwnerPickerSheet(
        currentUserId: currentUserId,
        excludeIds: excludeIds,
      ),
    ),
  );
}

class _CoOwnerPickerSheet extends StatefulWidget {
  const _CoOwnerPickerSheet({
    required this.currentUserId,
    required this.excludeIds,
  });

  final String currentUserId;
  final Set<String> excludeIds;

  @override
  State<_CoOwnerPickerSheet> createState() => _CoOwnerPickerSheetState();
}

class _CoOwnerPickerSheetState extends State<_CoOwnerPickerSheet> {
  /// Conversations read per query side (userId1 / userId2) — bounded, one page.
  static const int _recentChatsLimit = 20;

  final _nicknameController = TextEditingController();
  Set<String> _blocked = const {};

  List<CoOwnerCandidate> _recent = const [];
  bool _loadingRecent = true;

  List<CoOwnerCandidate>? _results; // null = no search run yet
  bool _searching = false;
  String? _searchMessage;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  bool _allowed(String uid) =>
      uid.isNotEmpty &&
      uid != widget.currentUserId &&
      !widget.excludeIds.contains(uid) &&
      !_blocked.contains(uid);

  Future<void> _init() async {
    try {
      _blocked =
          await sl<BlockedUsersService>().getBlockedUserIds(widget.currentUserId);
    } catch (_) {/* degrade to "no blocks known" */}
    await _loadRecentChats();
  }

  /// Latest 1:1 chat partners, the same way the create-group screen lists
  /// them: two equality queries (`userId1 == me`, `userId2 == me`) ordered by
  /// `lastMessageAt`, each limited, merged newest-first client-side.
  Future<void> _loadRecentChats() async {
    final me = widget.currentUserId;
    final fs = FirebaseFirestore.instance;
    Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> side(
        String field) async {
      try {
        final snap = await fs
            .collection('conversations')
            .where(field, isEqualTo: me)
            .orderBy('lastMessageAt', descending: true)
            .limit(_recentChatsLimit)
            .get();
        return snap.docs;
      } catch (_) {
        return const [];
      }
    }

    try {
      final sides = await Future.wait([side('userId1'), side('userId2')]);
      final recency = <String, int>{};
      for (final doc in [...sides[0], ...sides[1]]) {
        final data = doc.data();
        if (data['conversationType'] == 'support') continue;
        if (data['isDeleted'] == true) continue;
        final u1 = data['userId1'] as String?;
        final u2 = data['userId2'] as String?;
        final other = u1 == me ? u2 : u1;
        if (other == null || !_allowed(other)) continue;
        final ts = data['lastMessageAt'];
        final millis = ts is Timestamp ? ts.millisecondsSinceEpoch : 0;
        if (millis > (recency[other] ?? -1)) recency[other] = millis;
      }
      final ids = recency.keys.toList()
        ..sort((a, b) => recency[b]!.compareTo(recency[a]!));
      final top = ids.take(_recentChatsLimit).toList();
      final briefs = top.isEmpty
          ? const <String, UserBrief>{}
          : await UserDirectoryService.instance.resolve(top);
      final out = <CoOwnerCandidate>[];
      for (final id in top) {
        final b = briefs[id];
        // Never show a raw id: skip deleted/inactive/nameless users.
        if (b == null || !b.isActive || b.name.trim().isEmpty) continue;
        out.add(CoOwnerCandidate(
            userId: id, name: b.name.trim(), photoUrl: b.photoUrl));
      }
      if (mounted) setState(() => _recent = out);
    } catch (_) {
      // Leave the list empty.
    } finally {
      if (mounted) setState(() => _loadingRecent = false);
    }
  }

  /// Exact nickname lookup — the same bounded query the create-group screen
  /// uses (`nickname whereIn [as typed, lowercased]`, limit 20).
  Future<void> _search() async {
    final l10n = AppLocalizations.of(context)!;
    var raw = _nicknameController.text.trim();
    if (raw.startsWith('@')) raw = raw.substring(1).trim();
    if (raw.isEmpty) return;
    setState(() {
      _searching = true;
      _searchMessage = null;
    });
    try {
      final snap = await FirebaseFirestore.instance
          .collection('profiles')
          .where('nickname', whereIn: <String>{raw, raw.toLowerCase()}.toList())
          .limit(20)
          .get();
      final out = <CoOwnerCandidate>[];
      for (final doc in snap.docs) {
        final data = doc.data();
        if (!_allowed(doc.id)) continue;
        if (data['isGhostMode'] == true) continue;
        final name =
            ((data['displayName'] ?? data['nickname'] ?? '') as String).trim();
        if (name.isEmpty) continue;
        final photos =
            (data['photoUrls'] as List?)?.whereType<String>().toList() ??
                const <String>[];
        out.add(CoOwnerCandidate(
          userId: doc.id,
          name: name,
          photoUrl: photos.isNotEmpty ? photos.first : null,
        ));
      }
      if (!mounted) return;
      setState(() {
        _searching = false;
        _results = out;
        _searchMessage = out.isEmpty ? l10n.eventsCoOwnerNotFound : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _results = const [];
        _searchMessage = l10n.eventsCoOwnerSearchFailed;
      });
    }
  }

  Widget _tile(CoOwnerCandidate c) {
    final hasPhoto = c.photoUrl != null && c.photoUrl!.isNotEmpty;
    return ListTile(
      onTap: () => Navigator.of(context).pop(c),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: AppColors.backgroundCard,
        backgroundImage:
            hasPhoto ? CachedNetworkImageProvider(c.photoUrl!) : null,
        child: hasPhoto
            ? null
            : Text(c.name[0].toUpperCase(),
                style: const TextStyle(color: AppColors.textPrimary)),
      ),
      title: Text(c.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.textPrimary)),
      trailing: const Icon(Icons.person_add_alt_1, color: AppColors.richGold),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(text,
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(l10n.eventsAddCoOwner,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _nicknameController,
              style: const TextStyle(color: AppColors.textPrimary),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: l10n.eventsCoOwnerSearchHint,
                hintStyle: const TextStyle(color: AppColors.textTertiary),
                prefixIcon: const Icon(Icons.alternate_email,
                    color: AppColors.richGold, size: 20),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.richGold),
                        ),
                      )
                    : IconButton(
                        tooltip: l10n.eventsCoOwnerSearch,
                        icon: const Icon(Icons.search,
                            color: AppColors.richGold),
                        onPressed: _search,
                      ),
                filled: true,
                fillColor: AppColors.backgroundCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                if (_searchMessage != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Text(_searchMessage!,
                        style: const TextStyle(
                            color: AppColors.textTertiary, fontSize: 13)),
                  ),
                if (_results != null) ..._results!.map(_tile),
                _sectionTitle(l10n.eventsCoOwnerRecentChats),
                if (_loadingRecent)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.richGold),
                    ),
                  )
                else if (_recent.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Text(l10n.eventsCoOwnerNoRecentChats,
                        style: const TextStyle(
                            color: AppColors.textTertiary, fontSize: 13)),
                  )
                else
                  ..._recent.map(_tile),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
