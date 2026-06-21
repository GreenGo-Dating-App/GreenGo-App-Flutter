import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/app_sound_service.dart';
import '../../../../core/services/location_share_service.dart';
import '../../../../core/services/photo_validation_service.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/services/user_directory_service.dart';
import '../../../../core/widgets/voice_message_widget.dart';
import '../../../../core/widgets/voice_record_send_button.dart';
import '../../../events/presentation/widgets/event_message_card.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/entities/message.dart';
import '../bloc/group_chat_bloc.dart';
import '../bloc/group_chat_event.dart';
import '../bloc/group_chat_state.dart';
import 'group_info_screen.dart';

/// Group Chat Screen ("Culture Circle").
///
/// Reuses the [GroupChatBloc] (single message write; server-side fan-out).
/// Messages stream newest-first; the list is rendered reversed so new messages
/// appear at the bottom without re-sorting.
class GroupChatScreen extends StatelessWidget {
  const GroupChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.currentUserId,
    this.groupPhotoUrl,
  });

  final String groupId;
  final String groupName;
  final String currentUserId;
  final String? groupPhotoUrl;

  static Route<void> route({
    required String groupId,
    required String groupName,
    required String currentUserId,
    String? groupPhotoUrl,
  }) {
    return MaterialPageRoute(
      builder: (_) => GroupChatScreen(
        groupId: groupId,
        groupName: groupName,
        currentUserId: currentUserId,
        groupPhotoUrl: groupPhotoUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GroupChatBloc>(
      create: (_) => sl<GroupChatBloc>()
        ..add(GroupChatStarted(groupId: groupId, userId: currentUserId)),
      child: _GroupChatView(
        groupId: groupId,
        groupName: groupName,
        currentUserId: currentUserId,
        groupPhotoUrl: groupPhotoUrl,
      ),
    );
  }
}

class _GroupChatView extends StatefulWidget {
  const _GroupChatView({
    required this.groupId,
    required this.groupName,
    required this.currentUserId,
    this.groupPhotoUrl,
  });

  final String groupId;
  final String groupName;
  final String? groupPhotoUrl;
  final String currentUserId;

  @override
  State<_GroupChatView> createState() => _GroupChatViewState();
}

class _GroupChatViewState extends State<_GroupChatView> {
  final _controller = TextEditingController();
  final Set<String> _resolvingNames = {};

  // Per-user, per-group translation settings (local; scales with no backend).
  bool _translate = true;
  String _targetLang = 'en';
  bool _showOriginal = true;

  static const _languages = [
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
    {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪'},
    {'code': 'es', 'name': 'Español', 'flag': '🇪🇸'},
    {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
    {'code': 'it', 'name': 'Italiano', 'flag': '🇮🇹'},
    {'code': 'pt', 'name': 'Português', 'flag': '🇵🇹'},
    {'code': 'pt_BR', 'name': 'Português (BR)', 'flag': '🇧🇷'},
  ];

  @override
  void initState() {
    super.initState();
    _loadTranslationPrefs();
  }

  Future<void> _loadTranslationPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final deviceLang =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    setState(() {
      _translate = prefs.getBool('group_${widget.groupId}_translate') ?? true;
      _targetLang = prefs.getString('group_${widget.groupId}_language') ??
          (_languages.any((l) => l['code'] == deviceLang) ? deviceLang : 'en');
      _showOriginal =
          prefs.getBool('group_${widget.groupId}_showOriginal') ?? true;
    });
  }

  Future<void> _saveTranslationPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('group_${widget.groupId}_translate', _translate);
    await prefs.setString('group_${widget.groupId}_language', _targetLang);
    await prefs.setBool('group_${widget.groupId}_showOriginal', _showOriginal);
  }

  void _openTranslationSettings() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.groupTranslationSettings,
                    style: Theme.of(ctx).textTheme.titleMedium),
              ),
              SwitchListTile(
                title: Text(l10n.groupTranslateMessages),
                value: _translate,
                onChanged: (v) {
                  setModal(() {});
                  setState(() => _translate = v);
                  _saveTranslationPrefs();
                },
              ),
              SwitchListTile(
                title: Text(l10n.groupShowOriginal),
                value: _showOriginal,
                onChanged: _translate
                    ? (v) {
                        setModal(() {});
                        setState(() => _showOriginal = v);
                        _saveTranslationPrefs();
                      }
                    : null,
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(l10n.chatYourLanguage,
                      style: Theme.of(ctx).textTheme.labelLarge),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: _languages.map((lang) {
                    final code = lang['code']!;
                    return RadioListTile<String>(
                      value: code,
                      groupValue: _targetLang,
                      title: Text('${lang['flag']}  ${lang['name']}'),
                      onChanged: (v) {
                        if (v == null) return;
                        setModal(() {});
                        setState(() => _targetLang = v);
                        _saveTranslationPrefs();
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Resolves display names for any message senders not yet cached, then
  /// rebuilds so the bubbles show names instead of raw user ids.
  void _ensureNames(Iterable<String> ids) {
    final missing = ids
        .toSet()
        .where((id) =>
            id.isNotEmpty &&
            UserDirectoryService.instance.cached(id) == null &&
            !_resolvingNames.contains(id))
        .toList();
    if (missing.isEmpty) return;
    _resolvingNames.addAll(missing);
    UserDirectoryService.instance.resolve(missing).then((_) {
      if (mounted) setState(() => _resolvingNames.removeAll(missing));
    });
  }

  void _send(BuildContext context) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context
        .read<GroupChatBloc>()
        .add(GroupChatMessageSent(content: text));
    _controller.clear();
    // Same "message sent" sound as 1:1 exchanges.
    AppSoundService().play(AppSound.messageSent);
  }

  Future<void> _sendVoice(BuildContext context, File file, Duration duration) async {
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<GroupChatBloc>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final uuid = const Uuid().v4();
      final ref = FirebaseStorage.instance
          .ref()
          .child('group_voice/${widget.groupId}/$uuid.m4a');
      await ref.putFile(file, SettableMetadata(contentType: 'audio/mp4'));
      final url = await ref.getDownloadURL();
      try {
        if (file.existsSync()) file.deleteSync();
      } catch (_) {}
      bloc.add(GroupChatMessageSent(
        content: url,
        type: MessageType.voiceNote,
        metadata: {'durationMs': duration.inMilliseconds},
      ));
    } catch (_) {
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.voiceFailedToSend),
      ));
    }
  }

  Future<String> _uploadGroupFile(
      File f, String ext, String contentType) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('group_media/${widget.groupId}/${const Uuid().v4()}.$ext');
    await ref.putFile(f, SettableMetadata(contentType: contentType));
    return ref.getDownloadURL();
  }

  Future<void> _sendMedia(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<GroupChatBloc>();
    final messenger = ScaffoldMessenger.of(context);
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: Text(l10n.chatPhoto),
              onTap: () => Navigator.pop(ctx, 'photo'),
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: Text(l10n.chatVideo),
              onTap: () => Navigator.pop(ctx, 'video'),
            ),
          ],
        ),
      ),
    );
    if (choice == null) return;
    final picker = ImagePicker();
    try {
      if (choice == 'photo') {
        final x = await picker.pickImage(
            source: ImageSource.gallery, imageQuality: 80);
        if (x == null) return;
        final file = File(x.path);
        final valid =
            await PhotoValidationService().validateImageForSending(file);
        if (!valid.isValid) {
          messenger.showSnackBar(
              SnackBar(content: Text(l10n.photoExplicitContent)));
          return;
        }
        final url = await _uploadGroupFile(file, 'jpg', 'image/jpeg');
        bloc.add(GroupChatMessageSent(content: url, type: MessageType.image));
      } else {
        final x = await picker.pickVideo(source: ImageSource.gallery);
        if (x == null) return;
        final url = await _uploadGroupFile(File(x.path), 'mp4', 'video/mp4');
        bloc.add(GroupChatMessageSent(content: url, type: MessageType.video));
      }
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.voiceFailedToSend)));
    }
  }

  Future<void> _sendLocation(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<GroupChatBloc>();
    final messenger = ScaffoldMessenger.of(context);
    final position = await const LocationShareService().getCurrentPosition();
    if (position == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.chatLocationDenied)));
      return;
    }
    bloc.add(GroupChatMessageSent(
      content: '${position.latitude},${position.longitude}',
      type: MessageType.location,
      metadata:
          LocationShareService.metadataFor(position.latitude, position.longitude),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => Navigator.of(context).push(
            GroupInfoScreen.route(
              groupId: widget.groupId,
              currentUserId: widget.currentUserId,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: (widget.groupPhotoUrl != null &&
                        widget.groupPhotoUrl!.isNotEmpty)
                    ? NetworkImage(widget.groupPhotoUrl!)
                    : null,
                child: (widget.groupPhotoUrl == null ||
                        widget.groupPhotoUrl!.isEmpty)
                    ? Text(
                        widget.groupName.isNotEmpty
                            ? widget.groupName[0].toUpperCase()
                            : '#',
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.groupName,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_translate ? Icons.translate : Icons.translate_outlined,
                color: _translate
                    ? Theme.of(context).colorScheme.primary
                    : null),
            tooltip: AppLocalizations.of(context)!.groupTranslationSettings,
            onPressed: _openTranslationSettings,
          ),
          IconButton(
            icon: const Icon(Icons.group_outlined),
            tooltip: AppLocalizations.of(context)!.groupInfo,
            onPressed: () => Navigator.of(context).push(
              GroupInfoScreen.route(
                groupId: widget.groupId,
                currentUserId: widget.currentUserId,
              ),
            ),
          ),
        ],
      ),
      body: BlocConsumer<GroupChatBloc, GroupChatState>(
        listener: (context, state) {
          if (state is GroupChatActionFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is GroupChatLeftSuccess) {
            Navigator.of(context).popUntil((r) => r.isFirst);
          }
        },
        builder: (context, state) {
          if (state is GroupChatLoading || state is GroupChatInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is GroupChatError) {
            return Center(child: Text(state.message));
          }
          final messages =
              state is GroupChatLoaded ? state.messages : <Message>[];
          _ensureNames(messages.map((m) => m.senderId));
          return Column(
            children: [
              Expanded(
                child: messages.isEmpty
                    ? Center(
                        child: Text(AppLocalizations.of(context)!.groupSayHello))
                    : ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final m = messages[index];
                          return _GroupMessageBubble(
                            message: m,
                            isMine: m.senderId == widget.currentUserId,
                            currentUserId: widget.currentUserId,
                            translate: _translate,
                            targetLang: _targetLang,
                            showOriginal: _showOriginal,
                          );
                        },
                      ),
              ),
              _InputBar(
                controller: _controller,
                onSend: () => _send(context),
                onAttachLocation: () => _sendLocation(context),
                onAttachMedia: () => _sendMedia(context),
                onSendVoice: (file, dur) => _sendVoice(context, file, dur),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GroupMessageBubble extends StatelessWidget {
  const _GroupMessageBubble({
    required this.message,
    required this.isMine,
    required this.currentUserId,
    this.translate = false,
    this.targetLang = 'en',
    this.showOriginal = true,
  });

  final Message message;
  final bool isMine;
  final String currentUserId;
  final bool translate;
  final String targetLang;
  final bool showOriginal;

  @override
  Widget build(BuildContext context) {
    if (message.type == MessageType.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: Text(
            message.content,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMine
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMine)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  UserDirectoryService.instance.nameFor(message.senderId),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            if (message.type == MessageType.location)
              _LocationContent(message: message, isMine: isMine)
            else if (message.type == MessageType.event)
              EventMessageCard(
                metadata: message.metadata,
                currentUserId: currentUserId,
                onDark: isMine,
              )
            else if (message.type == MessageType.voiceNote)
              VoiceMessageWidget(
                isCurrentUser: isMine,
                audioUrl: message.content,
                duration: (message.metadata?['durationMs'] is int)
                    ? Duration(
                        milliseconds: message.metadata!['durationMs'] as int)
                    : null,
              )
            else if (message.type == MessageType.image)
              GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => _FullImageScreen(url: message.content),
                )),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    message.content,
                    width: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image, size: 60),
                  ),
                ),
              )
            else if (message.type == MessageType.video)
              GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => _GroupVideoPlayerScreen(url: message.content),
                )),
                child: Container(
                  width: 200,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(Icons.play_circle_fill,
                        color: Colors.white, size: 48),
                  ),
                ),
              )
            else
              _TranslatableText(
                text: message.content,
                color: isMine
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
                translate: translate,
                targetLang: targetLang,
                showOriginal: showOriginal,
              ),
          ],
        ),
      ),
    );
  }
}

/// Renders a text message, translating it on-device to [targetLang] when
/// [translate] is enabled. The translated text is shown as the main content,
/// with the original underneath (when [showOriginal]). Each user picks their
/// own language, so translation happens per-viewer (no shared backend state).
class _TranslatableText extends StatefulWidget {
  const _TranslatableText({
    required this.text,
    required this.color,
    required this.translate,
    required this.targetLang,
    required this.showOriginal,
  });

  final String text;
  final Color color;
  final bool translate;
  final String targetLang;
  final bool showOriginal;

  @override
  State<_TranslatableText> createState() => _TranslatableTextState();
}

class _TranslatableTextState extends State<_TranslatableText> {
  String? _translated;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _maybeTranslate();
  }

  @override
  void didUpdateWidget(_TranslatableText old) {
    super.didUpdateWidget(old);
    if (old.targetLang != widget.targetLang ||
        old.translate != widget.translate ||
        old.text != widget.text) {
      _translated = null;
      _maybeTranslate();
    }
  }

  Future<void> _maybeTranslate() async {
    if (!widget.translate || widget.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final result = await TranslationService().translate(
      text: widget.text,
      sourceLanguage: 'auto',
      targetLanguage: widget.targetLang.replaceAll('_', '-'),
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      // Only treat as a translation if it actually changed.
      _translated = (result.trim() == widget.text.trim()) ? null : result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!widget.translate || _translated == null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(widget.text, style: TextStyle(color: widget.color)),
          ),
          if (_loading)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                    strokeWidth: 1.5, color: widget.color.withValues(alpha: 0.6)),
              ),
            ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_translated!, style: TextStyle(color: widget.color)),
        if (widget.showOriginal) ...[
          const SizedBox(height: 4),
          Text(
            widget.text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: widget.color.withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}

/// A tappable shared-location card that opens the coordinates in Maps.
class _LocationContent extends StatelessWidget {
  const _LocationContent({required this.message, required this.isMine});

  final Message message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final color =
        isMine ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;
    final loc = LocationShareService.parse(message.content);
    return InkWell(
      onTap: loc == null
          ? null
          : () => launchUrl(
                Uri.parse(LocationShareService.mapsUrl(loc.lat, loc.lng)),
                mode: LaunchMode.externalApplication,
              ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on, size: 18, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.chatLocation,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600)),
              Text(
                l10n.chatOpenInMaps,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color.withValues(alpha: 0.8),
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.onAttachLocation,
    required this.onAttachMedia,
    required this.onSendVoice,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAttachLocation;
  final VoidCallback onAttachMedia;
  final void Function(File file, Duration duration) onSendVoice;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: AppLocalizations.of(context)!.chatPhoto,
              onPressed: onAttachMedia,
            ),
            IconButton(
              icon: const Icon(Icons.location_on_outlined),
              tooltip: AppLocalizations.of(context)!.chatShareLocation,
              onPressed: onAttachLocation,
            ),
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.groupMessageHint,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 6),
            VoiceRecordSendButton(
              controller: controller,
              radius: 22,
              onSendText: onSend,
              onSendVoice: onSendVoice,
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen viewer for a shared group image.
class _FullImageScreen extends StatelessWidget {
  const _FullImageScreen({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(url),
        ),
      ),
    );
  }
}

/// Full-screen player for a shared group video.
class _GroupVideoPlayerScreen extends StatefulWidget {
  const _GroupVideoPlayerScreen({required this.url});
  final String url;

  @override
  State<_GroupVideoPlayerScreen> createState() =>
      _GroupVideoPlayerScreenState();
}

class _GroupVideoPlayerScreenState extends State<_GroupVideoPlayerScreen> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _controller?.play();
        }
      });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black),
      body: Center(
        child: (c != null && c.value.isInitialized)
            ? AspectRatio(
                aspectRatio: c.value.aspectRatio,
                child: VideoPlayer(c),
              )
            : const CircularProgressIndicator(color: Colors.white),
      ),
      floatingActionButton: (c != null && c.value.isInitialized)
          ? FloatingActionButton(
              onPressed: () => setState(() =>
                  c.value.isPlaying ? c.pause() : c.play()),
              child: Icon(c.value.isPlaying ? Icons.pause : Icons.play_arrow),
            )
          : null,
    );
  }
}
