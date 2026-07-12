import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:audioplayers/audioplayers.dart' as ap show DeviceFileSource;
import 'package:audioplayers/audioplayers.dart' hide Source;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/app_sound_service.dart';
import '../../../../core/services/location_share_service.dart';
import '../../../../core/services/photo_validation_service.dart';
import '../../../../core/services/pronunciation_service.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/services/user_directory_service.dart';
import '../../../../core/utils/language_flags.dart';
import '../../../coins/data/datasources/coin_remote_datasource.dart';
import '../../../coins/domain/entities/coin_transaction.dart';
import '../../../../core/widgets/voice_message_widget.dart';
import '../../../../core/widgets/voice_record_send_button.dart';
import '../../../events/presentation/widgets/event_message_card.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/chat_constants.dart';
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
  // Double-tap TTS reads the translated (true) or original (false) text.
  bool _ttsReadTranslated = true;

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
      _ttsReadTranslated =
          prefs.getBool('group_${widget.groupId}_ttsReadTranslated') ?? true;
    });
  }

  Future<void> _saveTranslationPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('group_${widget.groupId}_translate', _translate);
    await prefs.setString('group_${widget.groupId}_language', _targetLang);
    await prefs.setBool('group_${widget.groupId}_showOriginal', _showOriginal);
    await prefs.setBool(
        'group_${widget.groupId}_ttsReadTranslated', _ttsReadTranslated);
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
              // Double-tap a message to hear it. This chooses which text is read:
              // ON = translation (your language), OFF = original.
              SwitchListTile(
                title: Text(l10n.groupTtsReadTranslated),
                subtitle: Text(l10n.groupTtsReadTranslatedHint),
                value: _ttsReadTranslated,
                onChanged: (v) {
                  setModal(() {});
                  setState(() => _ttsReadTranslated = v);
                  _saveTranslationPrefs();
                },
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
    if (text.length > kMaxMessageLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.messageTooLong)),
      );
      return;
    }
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

  /// Attachment menu — same layout/options as the 1:1 exchange chat.
  void _showAttachmentOptions(BuildContext context) {
    final parentContext = context;
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.chatSendAttachment,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _attachmentOption(
                  sheetCtx,
                  icon: Icons.photo_library,
                  label: l10n.chatAttachGallery,
                  color: AppColors.richGold,
                  onTap: () => _sendImage(parentContext, ImageSource.gallery),
                ),
                _attachmentOption(
                  sheetCtx,
                  icon: Icons.camera_alt,
                  label: l10n.chatAttachCamera,
                  color: Colors.blue,
                  onTap: () => _sendImage(parentContext, ImageSource.camera),
                ),
                _attachmentOption(
                  sheetCtx,
                  icon: Icons.location_on,
                  label: l10n.chatShareLocation,
                  color: Colors.green,
                  onTap: () => _sendLocation(parentContext),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _attachmentOption(
                  sheetCtx,
                  icon: Icons.videocam,
                  label: l10n.chatAttachVideo,
                  color: Colors.purple,
                  onTap: () => _sendVideo(parentContext, ImageSource.gallery),
                ),
                _attachmentOption(
                  sheetCtx,
                  icon: Icons.video_call,
                  label: l10n.chatAttachRecord,
                  color: Colors.red,
                  onTap: () => _sendVideo(parentContext, ImageSource.camera),
                ),
                _attachmentOption(
                  sheetCtx,
                  icon: Icons.collections,
                  label: l10n.shareAlbum,
                  color: Colors.teal,
                  onTap: () => _shareAlbum(parentContext),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _attachmentOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _sendImage(BuildContext context, ImageSource source) async {
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<GroupChatBloc>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final x = await ImagePicker().pickImage(source: source, imageQuality: 80);
      if (x == null) return;
      final file = File(x.path);
      final valid =
          await PhotoValidationService().validateImageForSending(file);
      if (!valid.isValid) {
        messenger
            .showSnackBar(SnackBar(content: Text(l10n.photoExplicitContent)));
        return;
      }
      final url = await _uploadGroupFile(file, 'jpg', 'image/jpeg');
      bloc.add(GroupChatMessageSent(content: url, type: MessageType.image));
      AppSoundService().play(AppSound.messageSent);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.voiceFailedToSend)));
    }
  }

  Future<void> _sendVideo(BuildContext context, ImageSource source) async {
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<GroupChatBloc>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final x = await ImagePicker().pickVideo(source: source);
      if (x == null) return;
      final url = await _uploadGroupFile(File(x.path), 'mp4', 'video/mp4');
      bloc.add(GroupChatMessageSent(content: url, type: MessageType.video));
      AppSoundService().play(AppSound.messageSent);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.voiceFailedToSend)));
    }
  }

  /// Share photos from the user's private album into the group (album URLs are
  /// already hosted, so we send them directly as image messages).
  Future<void> _shareAlbum(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<GroupChatBloc>();
    final messenger = ScaffoldMessenger.of(context);
    final doc = await FirebaseFirestore.instance
        .collection('profiles')
        .doc(widget.currentUserId)
        .get();
    final photos =
        (doc.data()?['privatePhotoUrls'] as List<dynamic>? ?? []).cast<String>();
    if (!mounted) return;
    if (photos.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.chatNoPrivatePhotos)));
      return;
    }
    final selected = <String>{};
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheet) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, sc) => Column(
            children: [
              const SizedBox(height: 12),
              Text(l10n.shareAlbum,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              Expanded(
                child: GridView.builder(
                  controller: sc,
                  padding: const EdgeInsets.all(12),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8),
                  itemCount: photos.length,
                  itemBuilder: (_, i) {
                    final url = photos[i];
                    final sel = selected.contains(url);
                    return GestureDetector(
                      onTap: () => setSheet(() =>
                          sel ? selected.remove(url) : selected.add(url)),
                      child: Stack(fit: StackFit.expand, children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image(
                              image: CachedNetworkImageProvider(url),
                              fit: BoxFit.cover),
                        ),
                        if (sel)
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.richGold.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.check_circle,
                                color: Colors.white),
                          ),
                      ]),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.richGold,
                      foregroundColor: AppColors.deepBlack,
                    ),
                    onPressed: selected.isEmpty
                        ? null
                        : () {
                            for (final url in selected) {
                              bloc.add(GroupChatMessageSent(
                                  content: url, type: MessageType.image));
                            }
                            AppSoundService().play(AppSound.messageSent);
                            Navigator.pop(sheetCtx);
                          },
                    child: Text('${l10n.eventShare} (${selected.length})'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('groups')
                    .doc(widget.groupId)
                    .snapshots(),
                builder: (context, snap) {
                  final liveUrl = (snap.data?.data()?['groupInfo']
                          as Map<String, dynamic>?)?['photoUrl'] as String?;
                  final photo = (liveUrl != null && liveUrl.isNotEmpty)
                      ? liveUrl
                      : widget.groupPhotoUrl;
                  return CircleAvatar(
                    radius: 16,
                    backgroundImage: (photo != null && photo.isNotEmpty)
                        ? CachedNetworkImageProvider(photo)
                        : null,
                    child: (photo == null || photo.isEmpty)
                        ? Text(
                            widget.groupName.isNotEmpty
                                ? widget.groupName[0].toUpperCase()
                                : '#',
                          )
                        : null,
                  );
                },
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
                            ttsReadTranslated: _ttsReadTranslated,
                          );
                        },
                      ),
              ),
              _InputBar(
                controller: _controller,
                onSend: () => _send(context),
                onAttach: () => _showAttachmentOptions(context),
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
    this.ttsReadTranslated = true,
  });

  final Message message;
  final bool isMine;
  final String currentUserId;
  final bool translate;
  final String targetLang;
  final bool showOriginal;
  final bool ttsReadTranslated;

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
                child: Builder(builder: (context) {
                  final brief =
                      UserDirectoryService.instance.cached(message.senderId);
                  final flag = languageFlagEmoji(brief?.language);
                  final name = brief?.name ??
                      UserDirectoryService.instance.nameFor(message.senderId);
                  return Text(
                    flag.isNotEmpty ? '$flag  $name' : name,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  );
                }),
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
                ttsReadTranslated: ttsReadTranslated,
                currentUserId: currentUserId,
                sourceLang: message.detectedLanguage ??
                    languageCode(UserDirectoryService.instance
                        .cached(message.senderId)
                        ?.language),
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
    this.ttsReadTranslated = true,
    this.currentUserId = '',
    this.sourceLang,
  });

  final String text;
  final Color color;
  final bool translate;
  final String targetLang;
  final bool showOriginal;

  /// Double-tap reads the translation (true) or the original (false).
  final bool ttsReadTranslated;
  final String currentUserId;

  /// Best-effort language code of the original text (for original-text TTS).
  final String? sourceLang;

  @override
  State<_TranslatableText> createState() => _TranslatableTextState();
}

class _TranslatableTextState extends State<_TranslatableText> {
  String? _translated;
  bool _loading = false;
  bool _ttsBusy = false;
  final AudioPlayer _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _maybeTranslate();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  /// Double-tap TTS: reads the translation (your language) or the original,
  /// per the group setting. Costs 5 coins like the 1:1 chat.
  Future<void> _playTts() async {
    if (_ttsBusy) {
      await _player.stop();
      if (mounted) setState(() => _ttsBusy = false);
      return;
    }
    final readTranslated =
        widget.ttsReadTranslated && _translated != null && _translated!.isNotEmpty;
    final text = readTranslated ? _translated! : widget.text;
    final lang = readTranslated
        ? widget.targetLang.replaceAll('_', '-')
        : (widget.sourceLang ?? widget.targetLang).replaceAll('_', '-');
    if (text.trim().isEmpty || widget.currentUserId.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    final notEnoughMsg = AppLocalizations.of(context)!.ttsNotEnoughCoins;
    try {
      final coinDs = sl<CoinRemoteDataSource>();
      final balance = await coinDs.getBalance(widget.currentUserId);
      if (balance.totalCoins < 5) {
        messenger.showSnackBar(SnackBar(content: Text(notEnoughMsg)));
        return;
      }
      await coinDs.updateBalance(
        userId: widget.currentUserId,
        amount: 5,
        type: CoinTransactionType.debit,
        reason: CoinTransactionReason.featurePurchase,
        metadata: const {'feature': 'tts_listen_group'},
      );
    } catch (_) {
      // Allow playback even if the coin deduction fails (e.g. emulator).
    }

    setState(() => _ttsBusy = true);
    try {
      final path = await PronunciationService()
          .getPronunciationFilePath(text, lang, isMale: false);
      if (path != null && mounted) {
        _player.onPlayerComplete.first.then((_) {
          if (mounted) setState(() => _ttsBusy = false);
        });
        await _player.setVolume(1.0);
        await _player.play(ap.DeviceFileSource(path));
      } else if (mounted) {
        setState(() => _ttsBusy = false);
      }
    } catch (_) {
      if (mounted) setState(() => _ttsBusy = false);
    }
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
    final Widget content;
    if (!widget.translate || _translated == null) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(widget.text, style: TextStyle(color: widget.color)),
          ),
          if (_loading || _ttsBusy)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: _ttsBusy
                  ? Icon(Icons.volume_up,
                      size: 14, color: widget.color.withValues(alpha: 0.7))
                  : SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: widget.color.withValues(alpha: 0.6)),
                    ),
            ),
        ],
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                  child:
                      Text(_translated!, style: TextStyle(color: widget.color))),
              if (_ttsBusy)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Icon(Icons.volume_up,
                      size: 14, color: widget.color.withValues(alpha: 0.7)),
                ),
            ],
          ),
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
    // Double-tap to hear it (target or source text, per the group setting).
    return GestureDetector(onDoubleTap: _playTts, child: content);
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
    required this.onAttach,
    required this.onSendVoice,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAttach;
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
              tooltip: AppLocalizations.of(context)!.chatSendAttachment,
              onPressed: onAttach,
            ),
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                maxLength: kMaxMessageLength,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(kMaxMessageLength),
                ],
                buildCounter: (context,
                        {required currentLength,
                        required isFocused,
                        maxLength}) =>
                    null,
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
