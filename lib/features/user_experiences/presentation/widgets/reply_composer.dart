import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/services/user_directory_service.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/experience_validation.dart';
import '../../domain/mention_parser.dart';
import '../../domain/review_moderation.dart';

/// Reply text with '@Name' mentions highlighted (names resolved live).
///
/// [autoTranslate]: translated into [targetLang] as soon as it appears (same
/// behaviour as `TranslatableText(autoTranslate: true)`, via the shared cached
/// [TranslationService]) with a "Show original" / "Translate" toggle; mention
/// highlighting is applied to whichever text is shown.
class MentionText extends StatefulWidget {
  const MentionText({
    super.key,
    required this.text,
    required this.mentions,
    this.style,
    this.autoTranslate = false,
    this.targetLang,
  });
  final String text;
  final List<String> mentions;
  final TextStyle? style;
  final bool autoTranslate;
  final String? targetLang;

  @override
  State<MentionText> createState() => _MentionTextState();
}

class _MentionTextState extends State<MentionText> {
  String? _translated;
  bool _showTranslation = false;
  bool _translating = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoTranslate) _translate();
  }

  @override
  void didUpdateWidget(MentionText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text || old.targetLang != widget.targetLang) {
      _translated = null;
      _showTranslation = false;
      if (widget.autoTranslate) _translate();
    }
  }

  Future<void> _translate() async {
    final target = widget.targetLang;
    if (target == null || widget.text.trim().isEmpty) return;
    setState(() => _translating = true);
    try {
      final r = await TranslationService().translate(
        text: widget.text,
        sourceLanguage: 'auto',
        targetLanguage: target.replaceAll('_', '-'),
      );
      if (!mounted) return;
      if (r.trim().isNotEmpty && r.trim() != widget.text.trim()) {
        setState(() {
          _translated = r;
          _showTranslation = true;
        });
      }
    } catch (_) {
      // Best effort: keep the original.
    } finally {
      if (mounted) setState(() => _translating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final base = widget.style ??
        const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.35);
    final shown =
        _showTranslation && _translated != null ? _translated! : widget.text;
    final body = widget.mentions.isEmpty
        ? Text(shown, style: base)
        : ListenableBuilder(
            listenable: UserDirectoryService.instance,
            builder: (context, _) {
              final dir = UserDirectoryService.instance;
              final names = <String, String>{};
              final unknown = <String>[];
              for (final uid in widget.mentions) {
                final b = dir.cached(uid);
                if (b == null) {
                  unknown.add(uid);
                } else if (b.name.trim().isNotEmpty) {
                  names[uid] = b.name.trim();
                }
              }
              if (unknown.isNotEmpty) dir.resolve(unknown);
              final segs = MentionParser.segments(shown, names);
              return Text.rich(TextSpan(
                style: base,
                children: [
                  for (final s in segs)
                    TextSpan(
                      text: s.text,
                      style: s.isMention
                          ? const TextStyle(
                              color: AppColors.richGold,
                              fontWeight: FontWeight.w600)
                          : null,
                    ),
                ],
              ));
            },
          );
    final showToggle = widget.autoTranslate && (_translating || _translated != null);
    if (!showToggle) return body;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        body,
        GestureDetector(
          onTap: _translating || _translated == null
              ? null
              : () => setState(() => _showTranslation = !_showTranslation),
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _translating
                  ? l.communitiesTranslating
                  : (_showTranslation
                      ? l.communitiesShowOriginal
                      : l.communitiesTranslate),
              style: const TextStyle(
                  color: AppColors.richGold,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

/// Inline reply box with '@' mention suggestions from [candidates] (review
/// author, host, earlier repliers). [onSend] gets the text and the uids of
/// the people actually tagged in it (≤ 10).
class ReplyComposer extends StatefulWidget {
  const ReplyComposer({
    super.key,
    required this.candidates,
    required this.currentUserId,
    required this.onSend,
    this.initialMention,
    this.busy = false,
  });

  final List<MentionCandidate> candidates;
  final String currentUserId;
  final void Function(String text, List<String> mentions) onSend;

  /// Pre-fills "@Name " (replying to someone specific).
  final MentionCandidate? initialMention;
  final bool busy;

  @override
  State<ReplyComposer> createState() => _ReplyComposerState();
}

class _ReplyComposerState extends State<ReplyComposer> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  List<MentionCandidate> _suggestions = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    final m = widget.initialMention;
    if (m != null && m.name.trim().isNotEmpty && m.uid != widget.currentUserId) {
      _controller.text = '@${m.name.trim()} ';
      _controller.selection =
          TextSelection.collapsed(offset: _controller.text.length);
    }
    _controller.addListener(_onChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged() {
    final sel = _controller.selection;
    final cursor = sel.isValid ? sel.baseOffset : _controller.text.length;
    final q = MentionParser.activeQuery(_controller.text, cursor);
    final next = q == null
        ? const <MentionCandidate>[]
        : MentionParser.suggestions(widget.candidates, q,
            excludeUid: widget.currentUserId);
    if (next.length != _suggestions.length ||
        !next.every((n) => _suggestions.any((s) => s.uid == n.uid)) ||
        _error != null) {
      setState(() {
        _suggestions = next;
        _error = null;
      });
    }
  }

  void _pick(MentionCandidate c) {
    final sel = _controller.selection;
    final cursor = sel.isValid ? sel.baseOffset : _controller.text.length;
    final r = MentionParser.insert(_controller.text, cursor, c.name.trim());
    _controller.value = TextEditingValue(
      text: r.text,
      selection: TextSelection.collapsed(offset: r.cursor),
    );
    setState(() => _suggestions = const []);
  }

  void _send() {
    final l = AppLocalizations.of(context)!;
    final text = _controller.text.trim();
    final verdict =
        ReviewModeration.check(text, maxLength: ExperienceLimits.replyMax);
    String? err;
    switch (verdict) {
      case CommentVerdict.ok:
        break;
      case CommentVerdict.empty:
        return;
      case CommentVerdict.tooLong:
        err = l.uexpErrTooLong(ExperienceLimits.replyMax);
      case CommentVerdict.prohibited:
        err = l.uexpErrProhibited;
      case CommentVerdict.containsLink:
        err = l.uexpErrNoLinks;
      case CommentVerdict.contactInfo:
        err = l.uexpErrContactInfo;
    }
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    final mentions = MentionParser.resolveMentions(
      text,
      widget.candidates.where((c) => c.uid != widget.currentUserId).toList(),
      max: ExperienceLimits.mentionsMax,
    );
    widget.onSend(text, mentions);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: AppColors.backgroundInput,
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: AppColors.richGold.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                for (final c in _suggestions)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.alternate_email,
                        size: 18, color: AppColors.richGold),
                    title: Text(c.name,
                        style: const TextStyle(color: AppColors.textPrimary)),
                    onTap: () => _pick(c),
                  ),
              ],
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                minLines: 1,
                maxLines: 4,
                maxLength: ExperienceLimits.replyMax,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: l.uexpReplyHint,
                  hintStyle: const TextStyle(color: AppColors.textTertiary),
                  errorText: _error,
                  counterText: '',
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.backgroundInput,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              tooltip: l.uexpReply,
              onPressed: widget.busy ? null : _send,
              icon: widget.busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.richGold))
                  : const Icon(Icons.send_rounded, color: AppColors.richGold),
            ),
          ],
        ),
      ],
    );
  }
}
