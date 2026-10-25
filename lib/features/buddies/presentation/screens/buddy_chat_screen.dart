import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/app_sound_service.dart';
import '../../../../core/services/chat_datasets/chat_datasets.dart';
import '../../../../core/utils/user_error.dart';
import '../../../../generated/app_localizations.dart';
import '../../../chat/domain/chat_places.dart';
import '../../../chat/domain/entities/message.dart';
import '../../../chat/presentation/widgets/chat_ideas_sheet.dart';
import '../../../chat/presentation/widgets/chat_places_bar.dart';
import '../../../chat/presentation/widgets/message_bubble.dart';
import '../../domain/buddy_catalog.dart';
import '../../domain/buddy_exception.dart';
import '../../domain/entities/buddy.dart';
import '../../domain/entities/buddy_message.dart';
import '../../domain/repositories/buddies_repository.dart';
import '../bloc/buddy_chat_bloc.dart';
import '../buddy_chat_adapter.dart';
import '../buddy_labels.dart';
import '../widgets/buddy_avatar.dart';
import '../widgets/buddy_bubble_parts.dart';
import '../widgets/buddy_chat_settings.dart';
import '../widgets/buddy_prompts.dart';
import '../widgets/buddy_quick_settings_sheet.dart';

/// A chat with one Buddy (AI chat friend): the 1:1 chat enhanced with AI.
///
/// Messages are the 1:1 chat's [MessageBubble] (the server's translation into
/// the Buddy's fixed `chatLanguage` with the original underneath, language
/// flags, keyword highlights, read-aloud). No translation call is made here:
/// every message carries its stored translation (owner 2026-10-24).
/// with the chat's languages menu and settings, ice-breakers, suggested
/// sentences and the places bar. No attachments and no language-level badge.
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
  Timer? _replySound;

  /// The 1:1 chat settings of this Buddy chat (defaults until loaded).
  BuddyChatSettings _settings = const BuddyChatSettings();

  /// Enter sends (web / hardware keyboards); Shift+Enter = new line.
  late final FocusNode _inputFocus = FocusNode(onKeyEvent: _onInputKey);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _input.addListener(() => setState(() {}));
    unawaited(BuddyChatSettings.load(widget.buddyId).then((s) {
      if (mounted) setState(() => _settings = s);
    }));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.prompts.maybePromptAiConsent(context);
    });
  }

  @override
  void dispose() {
    _replySound?.cancel();
    _inputFocus.dispose();
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

  /// The language this chat is translated into: the Buddy's fixed
  /// `chatLanguage` (older Buddies: the app language, display only).
  String get _targetLanguage => buddyChatLanguageOf(
      context, context.read<BuddyChatBloc>().state.buddy ?? widget.initialBuddy);

  bool _canSend(BuddyChatState state) {
    final length = _input.text.runes.length;
    return _input.text.trim().isNotEmpty &&
        length <= BuddyCatalog.maxMessageChars &&
        !state.waitingReply &&
        !state.loading &&
        !state.locked;
  }

  /// Enter (not Shift+Enter, not while an IME is composing) sends, on web
  /// and hardware keyboards. Shift+Enter inserts a new line.
  KeyEventResult _onInputKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key != LogicalKeyboardKey.enter && key != LogicalKeyboardKey.numpadEnter) {
      return KeyEventResult.ignored;
    }
    if (HardwareKeyboard.instance.isShiftPressed) return KeyEventResult.ignored;
    final composing = _input.value.composing;
    if (composing.isValid && !composing.isCollapsed) return KeyEventResult.ignored;
    if (_canSend(context.read<BuddyChatBloc>().state)) _send();
    // Handled either way: a plain Enter never inserts a new line here.
    return KeyEventResult.handled;
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    context
        .read<BuddyChatBloc>()
        .add(BuddyChatSendPressed(text));
    _input.clear();
    if (_scroll.hasClients) {
      unawaited(_scroll.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut));
    }
  }

  /// Puts [text] into the input (ice-breakers, sentences, place questions),
  /// within the 200-character limit.
  void _insert(String text) {
    final runes = text.runes.toList();
    final clipped = runes.length > BuddyCatalog.maxMessageChars
        ? String.fromCharCodes(runes.take(BuddyCatalog.maxMessageChars))
        : text;
    _input.text = clipped;
    _input.selection = TextSelection.collapsed(offset: clipped.length);
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

  // ---------------------------------------------------------------- menus

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

  /// The 1:1 chat's languages menu: the fixed chat language (info) + chat
  /// settings.
  void _openLanguagesMenu() {
    final buddy = context.read<BuddyChatBloc>().state.buddy ?? widget.initialBuddy;
    showBuddyChatLanguagesMenu(
      context,
      chatLanguage: _targetLanguage,
      buddyName: buddy?.settings.name ?? '',
      buddyLanguage: buddy?.settings.language,
      userLanguage: buddy?.settings.userLanguage,
      onSettings: () => showBuddyChatSettingsSheet(
        context,
        buddyId: widget.buddyId,
        settings: _settings,
        onChanged: (s) {
          if (mounted) setState(() => _settings = s);
        },
      ),
    );
  }

  void _openIdeas({required bool sentences, required String buddyLanguage}) {
    ChatIdeasSheet.show(
      context,
      sentences: sentences,
      // The Buddy speaks only its language: ideas in it, yours underneath.
      partnerLanguage: buddyLanguage,
      myLanguage: _targetLanguage,
      onPick: _insert,
    );
  }

  void _copy(Message m) {
    final l10n = AppLocalizations.of(context)!;
    unawaited(Clipboard.setData(ClipboardData(text: m.translatedContent ?? m.content)));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.buddyCopied)));
  }

  // ---------------------------------------------------------------- build

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
          final language = buddy?.settings.language ?? 'en';
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
                // The 1:1 chat's languages & chat settings menu.
                IconButton(
                  key: const ValueKey('buddy-chat-languages'),
                  tooltip: l10n.chatLanguages,
                  icon: const Icon(Icons.translate, color: AppColors.textSecondary),
                  onPressed: _openLanguagesMenu,
                ),
                IconButton(
                  key: const ValueKey('buddy-settings-button'),
                  tooltip: l10n.buddyQuickSettings,
                  icon: const Icon(Icons.tune),
                  onPressed: buddy == null ? null : () => _openSettings(buddy),
                ),
              ],
            ),
            // Rebuilt when the offline keyword index arrives (highlights,
            // places), like the 1:1 chat.
            body: ValueListenableBuilder<int>(
              valueListenable: ChatDatasets.instance.changes,
              builder: (context, _, __) {
                final target = buddyChatLanguageOf(context, buddy);
                final index = ChatDatasets.instance.keywords;
                // Stored translations only (never fetched here). A Buddy
                // bubble shows its translation as the main text from its
                // first frame; the user's own text stays the main text (its
                // translation is a line under it, see _messages).
                final adapted = <(BuddyMessage, Message)>[
                  for (final m in state.visibleMessages)
                    (
                      m,
                      BuddyChatAdapter.toMessage(m,
                          uid: widget.userId,
                          buddyId: widget.buddyId,
                          buddyLanguage: language,
                          translated: m.isBuddy
                              ? BuddyChatAdapter.shownTranslation(m,
                                  chatLanguage: target, buddyLanguage: language)
                              : null,
                          index: index),
                    ),
                ];
                final sources = [
                  for (final (_, msg) in adapted) BuddyChatAdapter.placeSource(msg, widget.userId),
                ];
                final places = _settings.showCulturalTips
                    ? ChatPlaces.collect(sources, index: index)
                    : const <ChatPlace>[];
                return Column(
                  children: [
                    Expanded(child: _messages(context, state, adapted, name, avatar, language, target)),
                    if (!state.locked && _settings.showCulturalTips)
                      ChatPlacesBar(
                        places: places,
                        partnerPlaces: ChatPlaces.latestFromPartner(places, sources),
                        onInsert: _insert,
                      ),
                    if (state.locked)
                      _lockedBar(l10n, state)
                    else
                      _composer(l10n, state, name, language, places),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _messages(BuildContext context, BuddyChatState state,
      List<(BuddyMessage, Message)> adapted, String name, String avatar, String language,
      String target) {
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
    final msgs = adapted.reversed.toList();
    final typing = state.buddyTyping ? 1 : 0;
    // Reversed list: index 0 = newest (bottom). Extra rows: the typing
    // indicator at the bottom, the AI notice (and a spinner) at the top.
    final count = typing + msgs.length + 1;
    return ListView.builder(
      key: const ValueKey('buddy-messages'),
      controller: _scroll,
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: 12),
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
              if (!state.hasMore) _notice(l10n, name, language, empty: msgs.isEmpty),
            ],
          );
        }
        final (m, msg) = msgs[j];
        // Shown once when not really translated (no "original" line).
        final userTranslation = m.isBuddy
            ? null
            : BuddyChatAdapter.shownTranslation(m, chatLanguage: target, buddyLanguage: language);
        return MessageBubble(
          key: ValueKey('buddy-msg-${m.id}'),
          message: msg,
          isCurrentUser: !m.isBuddy,
          currentUserId: widget.userId,
          otherUserLanguage: target,
          userSelectedLanguage: target,
          showOriginalText: _settings.showOriginalText,
          showCulturalTips: _settings.showCulturalTips,
          showPronunciation: _settings.showPronunciation,
          showLanguageFlags: _settings.showLanguageFlags,
          ttsReadTranslated: _settings.ttsReadTranslated,
          header: m.isBuddy ? BuddyBubbleHeader(kind: m.kind) : null,
          contentFooter: !m.isBuddy && userTranslation != null
              ? BuddyUserTranslationLine(
                  messageId: m.id,
                  text: userTranslation,
                  language: target,
                  showFlag: _settings.showLanguageFlags,
                )
              : null,
          footer: buddyBubbleFooter(
            context,
            messageId: m.id,
            onRetry: m.delivery == BuddyDelivery.failed
                ? () => context.read<BuddyChatBloc>().add(BuddyChatRetryPressed(m.id))
                : null,
            onReport: m.isBuddy && !m.isLocal
                ? () => widget.prompts.report(context,
                    uid: widget.userId, buddyId: widget.buddyId, messageId: m.id, text: m.text)
                : null,
          ),
          // No reply / forward / reactions with a Buddy: long-press copies.
          onLongPressOverride: () => _copy(msg),
        );
      },
    );
  }

  Widget _notice(AppLocalizations l10n, String name, String language, {required bool empty}) =>
      Padding(
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
              if (_settings.showIcebreakers) ...[
                const SizedBox(height: 12),
                _emptyChatIcebreakers(l10n, language),
              ],
            ],
          ],
        ),
      );

  /// Three offline ice-breakers in an empty chat, like the 1:1 chat (in the
  /// Buddy's language: it speaks only that one).
  Widget _emptyChatIcebreakers(AppLocalizations l10n, String language) {
    final datasets = ChatDatasets.instance;
    return FutureBuilder<void>(
      future: datasets.icebreakers == null ? datasets.ensure('icebreakers') : null,
      builder: (context, _) {
        final picks = ChatIdeasSheet.randomIcebreakers(3, seed: widget.buddyId.hashCode);
        if (picks.isEmpty) return const SizedBox.shrink();
        return Column(
          key: const ValueKey('buddy-empty-icebreakers'),
          children: [
            for (final p in picks)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ActionChip(
                  avatar: const Icon(Icons.lightbulb_outline, size: 16, color: AppColors.richGold),
                  label: Text(p.text.of(language), maxLines: 2, overflow: TextOverflow.ellipsis),
                  onPressed: () => _insert(p.text.of(language)),
                ),
              ),
            TextButton(
              onPressed: () => _openIdeas(sentences: false, buddyLanguage: language),
              child: Text(l10n.chatSuggestionsTooltip),
            ),
          ],
        );
      },
    );
  }

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

  Widget _tool({
    required Key key,
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) =>
      IconButton(
        key: key,
        tooltip: tooltip,
        icon: Icon(icon),
        color: AppColors.richGold,
        onPressed: onPressed,
      );

  /// The 1:1 chat's input area without attachments (no photo, video, voice
  /// note, location or + button): quota line, tools, text field, send.
  Widget _composer(AppLocalizations l10n, BuddyChatState state, String name, String language,
      List<ChatPlace> places) {
    final left = state.freeRepliesLeft;
    final length = _input.text.runes.length;
    final canSend = _canSend(state);
    final tools =
        _settings.showIcebreakers || _settings.showSentences || _settings.showCulturalTips;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundCard,
        border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (left != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
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
            if (tools)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 2, 8, 0),
                child: Row(
                  key: const ValueKey('buddy-tools-row'),
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (_settings.showIcebreakers)
                      _tool(
                        key: const ValueKey('buddy-tool-icebreakers'),
                        icon: Icons.waving_hand_outlined,
                        tooltip: l10n.chatIcebreakersTitle,
                        onPressed: () => _openIdeas(sentences: false, buddyLanguage: language),
                      ),
                    if (_settings.showSentences)
                      _tool(
                        key: const ValueKey('buddy-tool-sentences'),
                        icon: Icons.format_quote_outlined,
                        tooltip: l10n.chatSuggestionsTitle,
                        onPressed: () => _openIdeas(sentences: true, buddyLanguage: language),
                      ),
                    if (_settings.showCulturalTips) ChatPlacesButton(places: places),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('buddy-input'),
                      controller: _input,
                      focusNode: _inputFocus,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: BuddyCatalog.maxMessageChars,
                      // Hard limit in code points, like the server (Array.from).
                      inputFormatters: const [_MaxRunesFormatter(BuddyCatalog.maxMessageChars)],
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.newline,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                      buildCounter: (context,
                              {required currentLength, required isFocused, maxLength}) =>
                          Text(
                        '$length/${BuddyCatalog.maxMessageChars}',
                        key: const ValueKey('buddy-input-counter'),
                        style: TextStyle(
                          color: length >= BuddyCatalog.maxMessageChars
                              ? Colors.red
                              : AppColors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                      decoration: InputDecoration(
                        hintText: l10n.buddyInputHint(name),
                        hintStyle: const TextStyle(color: AppColors.textTertiary),
                        filled: true,
                        fillColor: AppColors.backgroundDark,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
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
                        disabledBackgroundColor: AppColors.backgroundDark,
                      ),
                      onPressed: canSend ? _send : null,
                      icon: const Icon(Icons.send),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Refuses text longer than [max] code points (the server counts with
/// `Array.from`); a longer paste is cut at [max].
class _MaxRunesFormatter extends TextInputFormatter {
  const _MaxRunesFormatter(this.max);
  final int max;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.runes.length <= max) return newValue;
    final clipped = String.fromCharCodes(newValue.text.runes.take(max));
    return TextEditingValue(
      text: clipped,
      selection: TextSelection.collapsed(offset: clipped.length),
    );
  }
}
