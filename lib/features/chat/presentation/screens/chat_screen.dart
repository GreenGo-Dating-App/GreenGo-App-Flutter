import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/providers/language_provider.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/services/content_filter_service.dart';
import '../../../../core/utils/image_compression.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../domain/entities/message.dart';
import '../../data/datasources/chat_remote_datasource.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../widgets/message_bubble.dart';

/// Chat Screen
///
/// Individual chat conversation with a match
class ChatScreen extends StatefulWidget {
  final String matchId;
  final String currentUserId;
  final String otherUserId;
  final Profile otherUserProfile;

  const ChatScreen({
    super.key,
    required this.matchId,
    required this.currentUserId,
    required this.otherUserId,
    required this.otherUserProfile,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final TranslationService _translationService = TranslationService();
  final ContentFilterService _contentFilter = ContentFilterService();
  final ImagePicker _imagePicker = ImagePicker();
  late final ChatRemoteDataSourceImpl _chatDataSource;

  // Cache for translated messages
  final Map<String, String> _translatedMessages = {};
  bool _hasCheckedModels = false;
  String? _userLanguage;
  bool _translationEnabled = true; // Translation toggle state
  bool _isUploadingMedia = false;
  double _uploadProgress = 0.0;

  // Reply state
  Message? _replyingToMessage;

  @override
  void initState() {
    super.initState();
    _translationService.initialize();
    _chatDataSource = ChatRemoteDataSourceImpl(firestore: FirebaseFirestore.instance);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Check and download required translation models
  /// Note: Translation only works when both users have DIFFERENT app languages
  /// If both users use the same app language, no translation is needed
  Future<void> _checkAndDownloadModels(BuildContext context) async {
    if (_hasCheckedModels) return;
    _hasCheckedModels = true;

    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    _userLanguage = languageProvider.currentLocale.languageCode;

    // For translation to work, we need to know the OTHER user's APP language setting
    // Currently we only have their spoken languages list, not their app preference
    // So we'll skip automatic model download and only translate if models are already available
    // Translation will happen silently without prompting for downloads

    // Don't show download dialog - ML Kit has issues on emulators
    // Translation will work automatically on real devices where models may already exist
  }

  /// Translate a message to the user's language
  /// Translation is automatic and silent - no error prompts
  Future<Message> _translateMessage(Message message) async {
    // Don't translate if translation is disabled
    if (!_translationEnabled) return message;

    // Don't translate messages from current user
    if (message.senderId == widget.currentUserId) return message;

    // Don't translate non-text messages
    if (message.type != MessageType.text) return message;

    // Don't translate if already translated
    if (message.translatedContent != null) return message;

    // Check if translation is in cache
    if (_translatedMessages.containsKey(message.messageId)) {
      return message.copyWith(
        translatedContent: _translatedMessages[message.messageId],
      );
    }

    if (_userLanguage == null) return message;

    // Try to detect and translate if the message is in a different language
    // This is a best-effort approach - if translation fails, just show original
    try {
      // Use language detection or assume message is in a different language
      // For now, skip translation on emulators (ML Kit issues)
      // Translation will work on real devices with Google Play Services

      // Check if models are available (won't prompt for download)
      final canTranslate = await _translationService.canTranslate('auto', _userLanguage!);
      if (!canTranslate) return message;

      // Translate the message (auto-detect source language)
      final translatedText = await _translationService.translate(
        text: message.content,
        sourceLanguage: 'auto',
        targetLanguage: _userLanguage!,
      );

      // Only cache if translation is different from original
      if (translatedText != message.content) {
        _translatedMessages[message.messageId] = translatedText;
        return message.copyWith(
          translatedContent: translatedText,
        );
      }
    } catch (e) {
      // Silently fail - translation is optional
      // Message will display in original language
    }

    return message;
  }

  void _sendMessage(BuildContext context) {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    // Check for contact information
    final filterResult = _contentFilter.analyzeContent(content);
    if (filterResult.hasContactInfo) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Message blocked: Contains ${filterResult.violations.join(', ')}. For your safety, sharing personal contact details is not allowed.',
          ),
          backgroundColor: AppColors.errorRed,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    // Send as reply if replying to a message
    if (_replyingToMessage != null) {
      context.read<ChatBloc>().add(ChatMessageReplied(
        content: content,
        replyToMessageId: _replyingToMessage!.messageId,
      ));
      _clearReplyMessage();
    } else {
      context.read<ChatBloc>().add(ChatMessageSent(content: content));
    }

    _messageController.clear();

    // Scroll to bottom after sending
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Report a message for review
  Future<void> _reportMessage(BuildContext context, Message message) async {
    // Show reason selection dialog
    final reasons = [
      'Harassment or bullying',
      'Spam or scam',
      'Inappropriate content',
      'Sharing personal information',
      'Threatening behavior',
      'Other',
    ];

    final selectedReason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text(
          'Report Message',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Why are you reporting this message?',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ...reasons.map((reason) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                reason,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              ),
              onTap: () => Navigator.pop(dialogContext, reason),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedReason == null || !context.mounted) return;

    try {
      await _chatDataSource.reportMessage(
        conversationId: widget.matchId,
        messageId: message.messageId,
        reporterId: widget.currentUserId,
        reportedUserId: message.senderId,
        reason: selectedReason,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message reported. We will review it shortly.'),
            backgroundColor: AppColors.richGold,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to report message: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  /// Show attachment options bottom sheet
  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
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
            const Text(
              'Send Attachment',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  context,
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  color: AppColors.richGold,
                  onTap: () => _pickImage(context, ImageSource.gallery),
                ),
                _buildAttachmentOption(
                  context,
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  color: Colors.blue,
                  onTap: () => _pickImage(context, ImageSource.camera),
                ),
                _buildAttachmentOption(
                  context,
                  icon: Icons.videocam,
                  label: 'Video',
                  color: Colors.purple,
                  onTap: () => _pickVideo(context, ImageSource.gallery),
                ),
                _buildAttachmentOption(
                  context,
                  icon: Icons.video_call,
                  label: 'Record',
                  color: Colors.red,
                  onTap: () => _pickVideo(context, ImageSource.camera),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(
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
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null && context.mounted) {
        _sendImageMessage(context, image);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _pickVideo(BuildContext context, ImageSource source) async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: 60),
      );

      if (video != null && context.mounted) {
        _sendVideoMessage(context, video);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick video: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _sendImageMessage(BuildContext context, XFile image) async {
    if (_isUploadingMedia) return;

    setState(() {
      _isUploadingMedia = true;
      _uploadProgress = 0.0;
    });

    try {
      // Compress image before upload to reduce storage costs
      File file = File(image.path);
      try {
        file = await ImageCompression.compressChatImage(file);
        debugPrint('Chat image compressed for upload');
      } catch (e) {
        debugPrint('Chat image compression failed, using original: $e');
        // Use original if compression fails
      }

      // Create unique filename
      final uuid = const Uuid().v4();
      final fileName = 'chat_images/${widget.matchId}/${uuid}.jpg';

      // Upload to Firebase Storage
      final ref = FirebaseStorage.instance.ref().child(fileName);

      final uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Track upload progress
      uploadTask.snapshotEvents.listen((snapshot) {
        if (mounted) {
          setState(() {
            _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
          });
        }
      });

      // Wait for upload to complete
      await uploadTask;

      // Get download URL
      final downloadUrl = await ref.getDownloadURL();

      if (context.mounted) {
        // Send message with image URL
        context.read<ChatBloc>().add(ChatMessageSent(
          content: downloadUrl,
          type: MessageType.image,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingMedia = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  Future<void> _sendVideoMessage(BuildContext context, XFile video) async {
    if (_isUploadingMedia) return;

    setState(() {
      _isUploadingMedia = true;
      _uploadProgress = 0.0;
    });

    try {
      // Check file size (limit to 50MB)
      final file = File(video.path);
      final fileSize = await file.length();
      if (fileSize > 50 * 1024 * 1024) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Video too large. Maximum size is 50MB.'),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
        return;
      }

      // Create unique filename
      final uuid = const Uuid().v4();
      final extension = video.path.split('.').last;
      final fileName = 'chat_videos/${widget.matchId}/${uuid}.$extension';

      // Upload to Firebase Storage
      final ref = FirebaseStorage.instance.ref().child(fileName);

      final uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: 'video/$extension'),
      );

      // Track upload progress
      uploadTask.snapshotEvents.listen((snapshot) {
        if (mounted) {
          setState(() {
            _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
          });
        }
      });

      // Wait for upload to complete
      await uploadTask;

      // Get download URL
      final downloadUrl = await ref.getDownloadURL();

      if (context.mounted) {
        // Send message with video URL
        context.read<ChatBloc>().add(ChatMessageSent(
          content: downloadUrl,
          type: MessageType.video,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload video: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingMedia = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<ChatBloc>()
        ..add(ChatConversationLoaded(
          matchId: widget.matchId,
          currentUserId: widget.currentUserId,
          otherUserId: widget.otherUserId,
        )),
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            // Messages list
            Expanded(
              child: BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  if (state is ChatLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.richGold,
                      ),
                    );
                  }

                  if (state is ChatError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: AppColors.errorRed,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            state.message,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is ChatLoaded || state is ChatSending) {
                    final messages = state is ChatLoaded
                        ? state.messages
                        : (state as ChatSending).messages;

                    final isOtherUserTyping = state is ChatLoaded
                        ? state.isOtherUserTyping
                        : false;

                    // Check and download models on first load
                    if (!_hasCheckedModels && messages.isNotEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _checkAndDownloadModels(context);
                      });
                    }

                    if (messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: AppColors.backgroundCard,
                              backgroundImage: widget
                                      .otherUserProfile.photoUrls.isNotEmpty
                                  ? NetworkImage(
                                      widget.otherUserProfile.photoUrls.first)
                                  : null,
                              child: widget
                                      .otherUserProfile.photoUrls.isEmpty
                                  ? const Icon(
                                      Icons.person,
                                      size: 50,
                                      color: AppColors.textTertiary,
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Say hi to ${widget.otherUserProfile.displayName}!',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                'Send a message to start the conversation',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: messages.length + (isOtherUserTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        // Typing indicator
                        if (index == 0 && isOtherUserTyping) {
                          return _buildTypingIndicator();
                        }

                        final messageIndex =
                            isOtherUserTyping ? index - 1 : index;
                        final message = messages[messageIndex];

                        // Apply translation asynchronously
                        return FutureBuilder<Message>(
                          future: _translateMessage(message),
                          builder: (context, snapshot) {
                            final translatedMessage = snapshot.data ?? message;
                            return MessageBubble(
                              message: translatedMessage,
                              isCurrentUser:
                                  message.senderId == widget.currentUserId,
                              currentUserId: widget.currentUserId,
                              onReport: (msg) => _reportMessage(context, msg),
                              onStar: (msg, isStarred) => _starMessage(context, msg, isStarred),
                              onReply: (msg) => _setReplyMessage(msg),
                              onForward: (msg) => _showForwardDialog(context, msg),
                            );
                          },
                        );
                      },
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),

            // Reply preview
            _buildReplyPreview(),

            // Upload progress indicator
            if (_isUploadingMedia)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppColors.backgroundCard,
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.cloud_upload,
                          color: AppColors.richGold,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Uploading...',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${(_uploadProgress * 100).toInt()}%',
                          style: const TextStyle(
                            color: AppColors.richGold,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: _uploadProgress,
                      backgroundColor: AppColors.backgroundDark,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.richGold),
                    ),
                  ],
                ),
              ),

            // Input field
            _buildInputField(context),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.backgroundCard,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.backgroundDark,
            backgroundImage:
                widget.otherUserProfile.photoUrls.isNotEmpty
                    ? NetworkImage(widget.otherUserProfile.photoUrls.first)
                    : null,
            child: widget.otherUserProfile.photoUrls.isEmpty
                ? const Icon(
                    Icons.person,
                    size: 20,
                    color: AppColors.textTertiary,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.otherUserProfile.displayName,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  if (state is ChatLoaded && state.isOtherUserTyping) {
                    return const Text(
                      'typing...',
                      style: TextStyle(
                        color: AppColors.richGold,
                        fontSize: 12,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Translation toggle button
        IconButton(
          icon: Icon(
            _translationEnabled ? Icons.translate : Icons.translate_outlined,
            color: _translationEnabled ? AppColors.richGold : AppColors.textSecondary,
          ),
          tooltip: _translationEnabled ? 'Disable translation' : 'Enable translation',
          onPressed: () {
            setState(() {
              _translationEnabled = !_translationEnabled;
              // Clear translation cache when toggling
              if (!_translationEnabled) {
                _translatedMessages.clear();
              }
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _translationEnabled
                      ? 'Translation enabled'
                      : 'Translation disabled',
                ),
                duration: const Duration(seconds: 1),
                backgroundColor: AppColors.backgroundCard,
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
          onPressed: () => _showChatOptionsMenu(context),
        ),
      ],
    );
  }

  /// Show chat options menu
  void _showChatOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) => SafeArea(
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
            const Text(
              'Chat Options',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildOptionItem(
              icon: Icons.delete_outline,
              label: 'Delete chat for me',
              color: AppColors.textSecondary,
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _confirmDeleteChatForMe(context);
              },
            ),
            _buildOptionItem(
              icon: Icons.delete_forever,
              label: 'Delete chat for both',
              color: Colors.orange,
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _confirmDeleteChatForBoth(context);
              },
            ),
            const Divider(color: AppColors.divider, height: 1),
            _buildOptionItem(
              icon: Icons.block,
              label: 'Block ${widget.otherUserProfile.displayName}',
              color: AppColors.errorRed,
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _confirmBlockUser(context);
              },
            ),
            _buildOptionItem(
              icon: Icons.flag_outlined,
              label: 'Report ${widget.otherUserProfile.displayName}',
              color: AppColors.errorRed,
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _showReportUserDialog(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: TextStyle(color: color, fontSize: 16),
      ),
      onTap: onTap,
    );
  }

  /// Confirm delete chat for current user
  Future<void> _confirmDeleteChatForMe(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text(
          'Delete Chat',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'This will delete the chat from your device only. The other person will still see the messages.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<ChatBloc>().add(const ChatDeletedForMe());
      Navigator.of(context).pop(); // Go back to chat list
    }
  }

  /// Confirm delete chat for both users
  Future<void> _confirmDeleteChatForBoth(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text(
          'Delete Chat for Everyone',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'This will delete all messages for both you and ${widget.otherUserProfile.displayName}. This action cannot be undone.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete for Everyone', style: TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<ChatBloc>().add(const ChatDeletedForBoth());
      Navigator.of(context).pop(); // Go back to chat list
    }
  }

  /// Confirm block user
  Future<void> _confirmBlockUser(BuildContext context) async {
    // Check if the other user is an admin - cannot block admin
    if (widget.otherUserProfile.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot block an administrator.'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text(
          'Block User',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to block ${widget.otherUserProfile.displayName}? They will no longer be able to contact you.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Block', style: TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<ChatBloc>().add(ChatUserBlocked(widget.otherUserId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.otherUserProfile.displayName} has been blocked'),
          backgroundColor: AppColors.richGold,
        ),
      );
      Navigator.of(context).pop(); // Go back to chat list
    }
  }

  /// Show report user dialog
  Future<void> _showReportUserDialog(BuildContext context) async {
    // Check if the other user is an admin - cannot report admin
    if (widget.otherUserProfile.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot report an administrator.'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    final reasons = [
      'Harassment or bullying',
      'Fake profile / Catfishing',
      'Spam or scam',
      'Inappropriate content',
      'Threatening behavior',
      'Underage user',
      'Other',
    ];

    final selectedReason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text(
          'Report User',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Why are you reporting ${widget.otherUserProfile.displayName}?',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ...reasons.map((reason) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                reason,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              ),
              onTap: () => Navigator.pop(dialogContext, reason),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedReason != null && context.mounted) {
      context.read<ChatBloc>().add(ChatUserReported(
        userId: widget.otherUserId,
        reason: selectedReason,
      ));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User reported. We will review your report shortly.'),
          backgroundColor: AppColors.richGold,
        ),
      );
    }
  }

  /// Star a message
  void _starMessage(BuildContext context, Message message, bool isStarred) {
    context.read<ChatBloc>().add(ChatMessageStarred(
      messageId: message.messageId,
      isStarred: isStarred,
    ));
  }

  /// Set message to reply to
  void _setReplyMessage(Message message) {
    setState(() {
      _replyingToMessage = message;
    });
  }

  /// Clear reply message
  void _clearReplyMessage() {
    setState(() {
      _replyingToMessage = null;
    });
  }

  /// Show forward dialog to select recipients
  Future<void> _showForwardDialog(BuildContext context, Message message) async {
    // TODO: Implement conversation list selection
    // For now, show a placeholder dialog
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text(
          'Forward Message',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Forward functionality will be available soon. You can forward messages to other conversations.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Build reply preview widget
  Widget _buildReplyPreview() {
    if (_replyingToMessage == null) return const SizedBox.shrink();

    final replyContent = _replyingToMessage!.content;
    final isCurrentUserMessage = _replyingToMessage!.senderId == widget.currentUserId;
    final senderName = isCurrentUserMessage ? 'You' : widget.otherUserProfile.displayName;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        border: Border(
          top: BorderSide(color: AppColors.richGold, width: 2),
          bottom: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.richGold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Replying to $senderName',
                  style: const TextStyle(
                    color: AppColors.richGold,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  replyContent.length > 60 ? '${replyContent.substring(0, 60)}...' : replyContent,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textTertiary, size: 20),
            onPressed: _clearReplyMessage,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.backgroundCard,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Attach button
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              color: AppColors.textSecondary,
              onPressed: () => _showAttachmentOptions(context),
            ),

            // Text input
            Expanded(
              child: TextField(
                controller: _messageController,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: const TextStyle(
                    color: AppColors.textTertiary,
                  ),
                  filled: true,
                  fillColor: AppColors.backgroundDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),

            const SizedBox(width: 8),

            // Send button
            BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                final isSending = state is ChatSending;

                return CircleAvatar(
                  backgroundColor: AppColors.richGold,
                  radius: 24,
                  child: isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.deepBlack,
                            strokeWidth: 2,
                          ),
                        )
                      : IconButton(
                          icon: const Icon(
                            Icons.send,
                            color: AppColors.deepBlack,
                            size: 20,
                          ),
                          onPressed: () => _sendMessage(context),
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTypingDot(0),
          const SizedBox(width: 4),
          _buildTypingDot(1),
          const SizedBox(width: 4),
          _buildTypingDot(2),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 100)),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: (value * 2) % 1.0,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.textTertiary,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
      onEnd: () {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }
}
