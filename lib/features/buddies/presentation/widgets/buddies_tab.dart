import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/utils/language_flags.dart';
import '../../../../core/utils/user_error.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/entities/buddy.dart';
import '../../domain/repositories/buddies_repository.dart';
import '../bloc/buddies_list_bloc.dart';
import '../buddy_labels.dart';
import '../screens/buddy_builder_screen.dart';
import '../screens/buddy_chat_screen.dart';
import 'buddy_avatar.dart';
import 'buddy_prompts.dart';

/// Exchanges > Buddies: the user's AI chat friends. Private to the user;
/// Buddies never appear in Discovery, Network or search.
class BuddiesTab extends StatelessWidget {
  const BuddiesTab({
    required this.userId,
    this.repository,
    this.prompts = const BuddyPrompts(),
    super.key,
  });

  final String userId;
  final BuddiesRepository? repository;
  final BuddyPrompts prompts;

  @override
  Widget build(BuildContext context) {
    final repo = repository ?? di.sl<BuddiesRepository>();
    return BuddyAvatarScope(
      repository: repo,
      child: BlocProvider(
        create: (_) => BuddiesListBloc(repository: repo)..add(BuddiesListStarted(userId)),
        child: _BuddiesTabView(userId: userId, repository: repo, prompts: prompts),
      ),
    );
  }
}

class _BuddiesTabView extends StatelessWidget {
  const _BuddiesTabView({required this.userId, required this.repository, required this.prompts});

  final String userId;
  final BuddiesRepository repository;
  final BuddyPrompts prompts;

  Future<void> _create(BuildContext context, BuddiesListState state) async {
    final bloc = context.read<BuddiesListBloc>();
    final status = state.status;
    if (!state.canCreateMore && status != null) {
      await prompts.showUpgrade(context, uid: userId, limit: status.buddyLimit, tier: status.tier);
      return;
    }
    final id = await Navigator.of(context).push<String>(MaterialPageRoute(
      builder: (_) => BuddyBuilderScreen(
        userId: userId,
        repository: repository,
        prompts: prompts,
        buddyLimit: status?.buddyLimit,
        tier: status?.tier,
      ),
    ));
    bloc.add(const BuddiesStatusRequested());
    if (id != null && context.mounted) {
      await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) =>
            BuddyChatScreen(userId: userId, buddyId: id, repository: repository, prompts: prompts),
      ));
      bloc.add(const BuddiesStatusRequested());
    }
  }

  Future<void> _open(BuildContext context, BuddyListItem item) async {
    final bloc = context.read<BuddiesListBloc>();
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => BuddyChatScreen(
        userId: userId,
        buddyId: item.buddy.id,
        initialBuddy: item.buddy,
        locked: item.locked,
        repository: repository,
        prompts: prompts,
      ),
    ));
    bloc.add(const BuddiesStatusRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<BuddiesListBloc, BuddiesListState>(
      builder: (context, state) {
        if (state.loading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.richGold));
        }
        if (state.error != null && state.items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(userErrorMessage(context, state.error),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary)),
            ),
          );
        }
        if (state.isEmpty) return _empty(context, l10n, state);
        return ListView(
          key: const ValueKey('buddies-list'),
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _header(context, l10n, state),
            for (final item in state.items) _tile(context, l10n, item, state),
          ],
        );
      },
    );
  }

  Widget _usageLines(AppLocalizations l10n, BuddiesListState state) {
    final s = state.status;
    if (s == null) return const SizedBox.shrink();
    // Centered horizontally (owner 2026-10-24), in the list header and in
    // the empty state.
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(l10n.buddiesPlanUsage(state.buddyCount, s.buddyLimit),
              key: const ValueKey('buddies-plan-usage'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(
              buddyQuotaLine(l10n,
                  freeRepliesLeft: s.freeRepliesLeft,
                  coinsPerReply: s.coinsPerReply,
                  repliesPerCoin: s.repliesPerCoin,
                  replyCredits: s.replyCredits),
              key: const ValueKey('buddies-free-replies'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, AppLocalizations l10n, BuddiesListState state) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          children: [
            _usageLines(l10n, state),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              key: const ValueKey('buddies-new'),
              // The app theme's infinite minimum width would stretch it.
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 44),
                backgroundColor: AppColors.richGold,
                foregroundColor: AppColors.deepBlack,
              ),
              onPressed: () => _create(context, state),
              icon: Icon(state.canCreateMore ? Icons.add : Icons.lock_outline, size: 18),
              label: Text(l10n.buddiesNewButton),
            ),
          ],
        ),
      );

  Widget _tile(
      BuildContext context, AppLocalizations l10n, BuddyListItem item, BuddiesListState state) {
    final b = item.buddy;
    final subtitle = item.locked
        ? l10n.buddyLockedHint
        : [
            buddyTopicLabel(l10n, b.settings.topic),
            if ((b.lastMessage ?? '').isNotEmpty) b.lastMessage!
          ].join(' · ');
    return Opacity(
      opacity: item.locked ? 0.55 : 1,
      child: ListTile(
        key: ValueKey('buddy-tile-${b.id}'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: BuddyAvatar(
            avatarId: b.settings.avatar, size: 52, showAiBadge: true, greyed: item.locked),
        title: Row(
          children: [
            Flexible(
              child: Text(b.name,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 6),
            const BuddyAiBadge(compact: true),
            if (item.locked) ...[
              const SizedBox(width: 6),
              Text(l10n.buddyLockedBadge,
                  key: ValueKey('buddy-locked-${b.id}'),
                  style: const TextStyle(color: AppColors.richGold, fontSize: 11)),
            ],
          ],
        ),
        subtitle: Text(subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 13)),
        trailing: item.locked
            ? const Icon(Icons.lock_outline, color: AppColors.richGold)
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // The language this chat is translated into (like Exchanges).
                  BuddyChatLanguageFlag(buddy: b),
                  if (b.unansweredCheckIns > 0) ...[
                    const SizedBox(height: 4),
                    Container(
                      width: 10,
                      height: 10,
                      decoration:
                          const BoxDecoration(color: AppColors.richGold, shape: BoxShape.circle),
                    ),
                  ],
                ],
              ),
        // A locked Buddy opens read-only (history + upgrade banner).
        onTap: () => _open(context, item),
      ),
    );
  }

  Widget _empty(BuildContext context, AppLocalizations l10n, BuddiesListState state) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            key: const ValueKey('buddies-empty'),
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  BuddyAvatar(avatarId: 'buddy_03', size: 56),
                  SizedBox(width: 8),
                  BuddyAvatar(avatarId: 'buddy_11', size: 72, showAiBadge: true),
                  SizedBox(width: 8),
                  BuddyAvatar(avatarId: 'buddy_19', size: 56),
                ],
              ),
              const SizedBox(height: 20),
              Text(l10n.buddiesEmptyTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(l10n.buddiesEmptyBody,
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4)),
              const SizedBox(height: 16),
              _usageLines(l10n, state),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                key: const ValueKey('buddies-create'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  backgroundColor: AppColors.richGold,
                  foregroundColor: AppColors.deepBlack,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                onPressed: () => _create(context, state),
                icon: const Icon(Icons.add),
                label: Text(l10n.buddiesCreateButton),
              ),
            ],
          ),
        ),
      );
}

/// Flag of the language a Buddy chat is translated into: the Buddy's fixed
/// `chatLanguage` (older Buddies: the app language).
class BuddyChatLanguageFlag extends StatelessWidget {
  const BuddyChatLanguageFlag({required this.buddy, super.key});

  final Buddy buddy;

  @override
  Widget build(BuildContext context) {
    final code = buddyChatLanguageOf(context, buddy);
    return Text(
      languageFlagEmoji(code),
      key: ValueKey('buddy-flag-${buddy.id}-$code'),
      style: const TextStyle(fontSize: 16),
    );
  }
}
