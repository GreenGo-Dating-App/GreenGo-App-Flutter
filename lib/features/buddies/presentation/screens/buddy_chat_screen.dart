import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/app_sound_service.dart';
import '../../../../core/utils/user_error.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/buddy_catalog.dart';
import '../../domain/buddy_exception.dart';
import '../../domain/entities/buddy.dart';
import '../../domain/entities/buddy_message.dart';
import '../../domain/repositories/buddies_repository.dart';
import '../bloc/buddy_chat_bloc.dart';
import '../buddy_labels.dart';
import '../widgets/buddy_avatar.dart';
import '../widgets/buddy_message_bubble.dart';
import '../widgets/buddy_prompts.dart';
import '../widgets/buddy_quick_settings_sheet.dart';

/// A chat with one Buddy (AI chat friend).
class BuddyChatScreen extends StatelessWidget {
  const BuddyChatScreen({
    required this.userId,
    required this.buddyId,
    this.initialBuddy,
    this.locked = false,
    this.repository,
    this.prompts = const BuddyPrompts(),
    super.key,
  });

  final String userId;
  final String buddyId;

  /// Shown in the header until the live Buddy doc arrives.
  final Buddy? initialBuddy;

  /// Known locked on the current plan (from the Buddies list).
  final bool locked;
  final BuddiesRepository? repository;
  final BuddyPrompts prompts;

  static Route<void> route({
    required String userId,
    required String buddyId,
    Buddy? initialBuddy,
    bool locked = false,
  }) =>
      MaterialPageRoute<void>(
        builder: (_) => BuddyChatScreen(
          userId: userId,
          buddyId: buddyId,
          initialBuddy: initialBuddy,
          locked: locked,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final repo = repository ?? di.sl<BuddiesRepository>();
    return BuddyAvatarScope(
      repository: repo,
      child: BlocProvider(
        create: (_) => BuddyChatBloc(repository: repo)
          ..add(BuddyChatStarted(uid: userId, buddyId: buddyId, locked: locked)),
        child: _BuddyChatView(
          userId: userId,
          buddyId: buddyId,
          initialBuddy: initialBuddy,
          repository: repo,
          prompts: prompts,
        ),
      ),
    );
  }
}

class _BuddyChatView extends StatefulWidget {
  const _BuddyChatView({
    required this.userId,
    required this.buddyId,
    required this.initialBuddy,
    required this.repository,
    required this.prompts,
  });

  final String userId;
  final String buddyId;
  final Buddy? initialBuddy;
  final BuddiesRepository repository;
  final BuddyPrompts prompts;

  @override
  State<_BuddyChatView> createState() => _BuddyChatViewState();
}

class _BuddyChatViewState extends State<_BuddyChatView> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final Map<String, String> _translations = {};
  final Set<String> _translating = {};
  Timer? _replySound;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _input.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _replySound?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Reversed list: the top (oldest) is maxScrollExtent.
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
      context.read<BuddyChatBloc>().add(const BuddyChatOlderRequested());
    }
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    context.read<BuddyChatBloc>().add(BuddyChatSendPressed(text));
    _input.clear();
  }

  Future<void> _onError(BuddyChatState state) async {
    final e = state.error;
    if (e == null) return;
    final bloc = context.read<BuddyChatBloc>();
    switch (e.kind) {
      case BuddyErrorKind.insufficientCoins:
        await widget.prompts.showInsufficientCoins(context,
            uid: widget.userId,
            coins: state.status?.coinsNeeded ?? 1,
            repliesPerCoin: state.repliesPerCoin);
        break;
      case BuddyErrorKind.consentRequired:
      case BuddyErrorKind.consentUpdateRequired:
        final ok = await widget.prompts
            .ensureAiConsent(context, update: e.kind == BuddyErrorKind.consentUpdateRequired);
        if (ok && state.errorLocalId != null) {
          bloc.add(BuddyChatRetryPressed(state.errorLocalId!));
        } else if (!ok && mounted) {
          await widget.prompts.showError(context, e);
        }
        break;
      case BuddyErrorKind.tierRequired:
        await widget.prompts.showUpgrade(context,
            uid: widget.userId,
            limit: state.status?.buddyLimit ?? e.limit ?? 1,
            tier: state.status?.tier);
        break;
      default:
        await widget.prompts.showError(context, e);
    }
  }

  void _onReply() {
    // Owner rule: sounds only after success.
    widget.prompts.playSound(AppSound.messageSent);
    _replySound?.cancel();
    _replySound = Timer(const Duration(milliseconds: 350), () {
      if (mounted) widget.prompts.playSound(AppSound.newMessage);
    });
  }

  Future<void> _toggleTranslate(BuddyMessage m) async {
    if (_translations.containsKey(m.id)) {
      setState(() => _translations.remove(m.id));
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final l = Localizations.localeOf(context);
    final target = l.countryCode == 'BR' && l.languageCode == 'pt' ? 'pt-BR' : l.languageCode;
    setState(() => _translating.add(m.id));
    String? out;
    try {
      out = await widget.prompts.translate(context, m.text, target);
    } catch (_) {
      out = null;
    }
    if (!mounted) return;
    setState(() {
      _translating.remove(m.id);
      if (out != null && out.trim() != m.text.trim()) _translations[m.id] = out;
    });
    if (out == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.buddyTranslateFailed)));
    }
  }

  void _openSettings(Buddy buddy) {
    final bloc = context.read<BuddyChatBloc>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      // The sheet is a new route: give it the pictures (cached, no new read).
      builder: (_) => BuddyAvatarScope(
        repository: widget.repository,
        child: BlocProvider.value(
          value: bloc,
          child: BuddyQuickSettingsSheet(
            buddyId: widget.buddyId,
            repository: widget.repository,
            prompts: widget.prompts,
            onDeleted: () {
              if (mounted) Navigator.of(context).maybePop();
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return MultiBlocListener(
      listeners: [
        BlocListener<BuddyChatBloc, BuddyChatState>(
          listenWhen: (a, b) => a.errorSeq != b.errorSeq,
          listener: (_, s) => unawaited(_onError(s)),
        ),
        BlocListener<BuddyChatBloc, BuddyChatState>(
          listenWhen: (a, b) => a.replySeq != b.replySeq,
          listener: (_, __) => _onReply(),
        ),
        BlocListener<BuddyChatBloc, BuddyChatState>(
          listenWhen: (a, b) => !a.buddyDeleted && b.buddyDeleted,
          listener: (ctx, __) {
            if (ModalRoute.of(ctx)?.isCurrent ?? false) Navigator.of(ctx).maybePop();
          },
        ),
      ],
      child: BlocBuilder<BuddyChatBloc, BuddyChatState>(
        builder: (context, state) {
          final buddy = state.buddy ?? widget.initialBuddy;
          final name = buddy?.name ?? '';
          final avatar = buddy?.settings.avatar ?? BuddyCatalog.avatars.first;
          return Scaffold(
            backgroundColor: AppColors.backgroundDark,
            appBar: AppBar(
              backgroundColor: AppColors.backgroundDark,
              foregroundColor: AppColors.textPrimary,
              titleSpacing: 0,
              title: Row(
                children: [
                  BuddyAvatar(avatarId: avatar, size: 38),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(name,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 6),
                            const BuddyAiBadge(),
                          ],
                        ),
                        if (buddy != null)
                          Text(
                            buddyTopicLabel(l10n, buddy.settings.topic),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  key: const ValueKey('buddy-settings-button'),
                  tooltip: l10n.buddyQuickSettings,
                  icon: const Icon(Icons.tune),
                  onPressed: buddy == null ? null : () => _openSettings(buddy),
                ),
              ],
            ),
            body: Column(
              children: [
                Expanded(child: _messages(context, state, name, avatar)),
                if (state.locked) _lockedBar(l10n, state) else _composer(l10n, state, name),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _messages(BuildContext context, BuddyChatState state, String name, String avatar) {
    final l10n = AppLocalizations.of(context)!;
    if (state.loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.richGold));
    }
    if (state.loadError != null && state.messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(userErrorMessage(context, state.loadError),
              textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }
    final msgs = state.messages.reversed.toList();
    final typing = state.waitingReply ? 1 : 0;
    // Reversed list: index 0 = newest (bottom). Extra rows: the typing
    // indicator at the bottom, the AI notice (and a spinner) at the top.
    final count = typing + msgs.length + 1;
    return ListView.builder(
      key: const ValueKey('buddy-messages'),
      controller: _scroll,
      reverse: true,
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      itemCount: count,
      itemBuilder: (context, i) {
        if (typing == 1 && i == 0) {
          return BuddyTypingIndicator(name: name, avatarId: avatar);
        }
        final j = i - typing;
        if (j == msgs.length) {
          return Column(
            children: [
              if (state.loadingOlder)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.richGold)),
                ),
              if (!state.hasMore) _notice(l10n, name, empty: msgs.isEmpty),
            ],
          );
        }
        final m = msgs[j];
        return BuddyMessageBubble(
          key: ValueKey('buddy-msg-${m.id}'),
          message: m,
          avatarId: avatar,
          translation: _translations[m.id],
          translating: _translating.contains(m.id),
          onTranslate: m.isBuddy ? () => _toggleTranslate(m) : null,
          onReport: m.isBuddy && !m.isLocal
              ? () => widget.prompts.report(context,
                  uid: widget.userId, buddyId: widget.buddyId, messageId: m.id, text: m.text)
              : null,
          onRetry: m.delivery == BuddyDelivery.failed
              ? () => context.read<BuddyChatBloc>().add(BuddyChatRetryPressed(m.id))
              : null,
        );
      },
    );
  }

  Widget _notice(AppLocalizations l10n, String name, {required bool empty}) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.smart_toy_outlined, size: 16, color: AppColors.textTertiary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    l10n.buddyAiDisclosure(name),
                    key: const ValueKey('buddy-ai-disclosure'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                  ),
                ),
              ],
            ),
            if (empty) ...[
              const SizedBox(height: 16),
              Text(l10n.buddyChatEmpty(name),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            ],
          ],
        ),
      );

  Widget _lockedBar(AppLocalizations l10n, BuddyChatState state) => SafeArea(
        top: false,
        child: Container(
          key: const ValueKey('buddy-locked-bar'),
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.richGold.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_outline, color: AppColors.richGold),
              const SizedBox(width: 10),
              Expanded(
                child: Text(l10n.buddyLockedBanner,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ),
              TextButton(
                onPressed: () => widget.prompts.showUpgrade(context,
                    uid: widget.userId,
                    limit: state.status?.buddyLimit ?? 1,
                    tier: state.status?.tier),
                child: Text(l10n.buddyUpgrade),
              ),
            ],
          ),
        ),
      );

  Widget _composer(AppLocalizations l10n, BuddyChatState state, String name) {
    final left = state.freeRepliesLeft;
    final length = _input.text.runes.length;
    final canSend = _input.text.trim().isNotEmpty &&
        length <= BuddyCatalog.maxMessageChars &&
        !state.waitingReply &&
        !state.loading;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (left != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  buddyQuotaLine(l10n,
                      freeRepliesLeft: left,
                      coinsPerReply: state.coinsPerReply,
                      repliesPerCoin: state.repliesPerCoin,
                      replyCredits: state.replyCredits),
                  key: const ValueKey('buddy-quota-line'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('buddy-input'),
                    controller: _input,
                    minLines: 1,
                    maxLines: 5,
                    maxLength: BuddyCatalog.maxMessageChars,
                    textInputAction: TextInputAction.newline,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: l10n.buddyInputHint(name),
                      hintStyle: const TextStyle(color: AppColors.textTertiary),
                      counterStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
                      filled: true,
                      fillColor: AppColors.backgroundCard,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 22),
                  child: IconButton.filled(
                    key: const ValueKey('buddy-send'),
                    tooltip: l10n.chatSend,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.richGold,
                      foregroundColor: AppColors.deepBlack,
                      disabledBackgroundColor: AppColors.backgroundCard,
                    ),
                    onPressed: canSend ? _send : null,
                    icon: const Icon(Icons.send),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
