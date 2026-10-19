import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart' hide Source;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/platform/web_media.dart';
import '../../../../core/utils/user_error.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../subscription/presentation/screens/membership_screen.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/providers/language_provider.dart';
import '../../../../core/services/app_sound_service.dart';
import '../../domain/message_insights.dart';
import '../../../../core/services/chat_datasets/chat_datasets.dart';
import '../widgets/chat_ideas_sheet.dart';
import '../widgets/listing_chat_widgets.dart';
import '../../domain/entities/conversation_listing_context.dart';
import '../widgets/chat_places_bar.dart';
import '../widgets/attraction_message.dart';
import '../../../attractions/domain/entities/attraction.dart';
import '../../data/chat_settings_prefs.dart';
import '../../domain/chat_places.dart';
import '../../../../core/services/content_filter_service.dart';
import '../../../../core/services/location_share_service.dart';
import '../../../../core/services/place_search_service.dart';
import '../../../../core/widgets/location_picker.dart';
import '../../../../core/services/own_profile_store.dart';
import '../../../../core/services/tier_gate.dart';
import '../../../../core/services/photo_validation_service.dart';
import '../../../../core/services/presence_service.dart';
import '../../../../core/services/pronunciation_service.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/services/usage_limit_service.dart';
import '../../../../core/utils/base_membership_gate.dart';
import '../../../../core/services/free_chat_service.dart';
import '../../../../core/widgets/base_membership_required_dialog.dart';
import '../../../../core/utils/image_compression.dart';
import '../../../../core/utils/safe_navigation.dart';
import '../../../../core/widgets/action_success_dialog.dart';
import '../../../../core/widgets/country_flag_badge.dart';
import '../../../../generated/app_localizations.dart';
import '../../../app_tour/presentation/tour_controller.dart';
import '../../../app_tour/presentation/tour_keys.dart';
import '../../../app_tour/presentation/widgets/gesture_glyphs.dart';
import '../../../app_tour/presentation/widgets/tour_showcase.dart';
import '../../../discovery/domain/entities/match.dart';
import '../../../discovery/presentation/screens/match_detail_screen.dart';
import '../../../discovery/presentation/screens/profile_detail_screen.dart';
import '../../../gamification/domain/utils/week_key.dart';
import '../../../membership/domain/entities/membership.dart';
import '../../../profile/data/datasources/album_access_datasource.dart';
import '../../../profile/data/models/profile_model.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../data/datasources/chat_remote_datasource.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../widgets/forward_message_sheet.dart';
import '../widgets/message_bubble.dart';
import '../../../../core/widgets/voice_record_send_button.dart';
import '../../../../core/widgets/verified_badge.dart';
import '../../../../core/services/ai_consent_service.dart';
import '../../../../core/widgets/ai_consent_sheet.dart';
import '../../../profile/data/private_album.dart';
import '../../../../core/security/private_content_warning.dart';
import '../../../../core/security/app_only_content.dart';
import '../../../../core/security/media_url.dart';
import '../../../../core/security/screen_security_service.dart';
import '../../../../core/security/viewer_watermark.dart';
import '../../data/services/chat_screenshot_notice.dart';
import '../../../safety/presentation/screens/age_assurance_required_screen.dart';
import '../../../safety/presentation/widgets/report_reasons.dart';

/// Chat Screen
///
/// Individual chat conversation with a match
class ChatScreen extends StatefulWidget {

  const ChatScreen({
    required this.matchId, required this.currentUserId, required this.otherUserId, required this.otherUserProfile, super.key,
    this.initialConversation,
  });
  final String matchId;
  final String currentUserId;
  final String otherUserId;
  final Profile otherUserProfile;

  /// Optionally pre-fetched conversation (e.g. one just created by
  /// openConnectChat). When present, the chat opens WITHOUT a network read, so a
  /// brand-new chat never hangs on the loading spinner.
  final Conversation? initialConversation;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final TranslationService _translationService = TranslationService();
  final ContentFilterService _contentFilter = ContentFilterService();
  final UsageLimitService _usageLimitService = UsageLimitService();
  final ImagePicker _imagePicker = ImagePicker();
  late final ChatBloc _chatBloc;
  late final ChatRemoteDataSourceImpl _chatDataSource;
  late final AlbumAccessDatasource _albumAccessDatasource;

  bool _translationLimitShown = false;

  /// Today's translation allowance of the user's plan is used up: say so once
  /// per chat, with a way to a bigger plan (messages show their original).
  void _onTranslationLimit() {
    if (!TranslationService.dailyLimitReached.value || _translationLimitShown || !mounted) return;
    _translationLimitShown = true;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(l10n.translationDailyLimitReached),
      duration: const Duration(seconds: 6),
      action: SnackBarAction(
        label: l10n.translationDailyLimitCta,
        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => MembershipScreen(currentUserId: widget.currentUserId),
        )),
      ),
    ));
  }

  /// What this chat is about (buyer <-> organizer chat), or null.
  ConversationListingContext? get _listingContext {
    final st = _chatBloc.state;
    ConversationListingContext? c;
    if (st is ChatLoaded) {
      c = st.conversation.listingContext;
    } else if (st is ChatSending) {
      c = st.conversation.listingContext;
    }
    return c ?? widget.initialConversation?.listingContext;
  }

  /// Server-verified ticket holder / booked guest chat (`context.buyer`,
  /// written only by the openListingChat callable): both sides may write
  /// on any plan; the rules allow it (`buyerChat`).
  bool get _buyerChat => _listingContext?.buyer ?? false;

  /// The conversation a send goes to (the id the bloc writes to).
  String _conversationIdForSend() {
    final st = _chatBloc.state;
    String? id;
    if (st is ChatLoaded) {
      id = st.conversation.conversationId;
    } else if (st is ChatSending) {
      id = st.conversation.conversationId;
    }
    id ??= widget.initialConversation?.conversationId;
    return (id == null || id.isEmpty) ? widget.matchId : id;
  }

  /// Posts "X took a screenshot" into this conversation (throttled).
  void _postScreenshotNotice() {
    final st = _chatBloc.state;
    String? conversationId;
    if (st is ChatLoaded) {
      conversationId = st.conversation.conversationId;
    } else if (st is ChatSending) {
      conversationId = st.conversation.conversationId;
    }
    conversationId ??= widget.initialConversation?.conversationId;
    if (conversationId == null || conversationId.isEmpty) return;
    unawaited(_screenshotNotice.postToConversation(
      conversationId: conversationId,
      senderId: widget.currentUserId,
      receiverId: widget.otherUserId,
      senderName: _currentUserName ?? '',
    ));
  }

  /// P3-1 age assurance: every send passes this guard. Where strong age
  /// assurance is required and missing, only conversations the user already
  /// wrote in stay open for sending; otherwise the gate screen is shown.
  Future<void> _addSend(ChatEvent event) async {
    final st = _chatBloc.state;
    String? conversationId;
    var wrote = false;
    if (st is ChatLoaded) {
      conversationId = st.conversation.conversationId;
      wrote = st.messages.any((m) => m.senderId == widget.currentUserId);
    } else if (st is ChatSending) {
      conversationId = st.conversation.conversationId;
      wrote = st.messages.any((m) => m.senderId == widget.currentUserId);
    }
    conversationId ??= widget.initialConversation?.conversationId;
    final ok = await AgeAssuranceGuard.ensureCanSend(
      context,
      conversationId: conversationId,
      userId: widget.currentUserId,
      alreadyWrote: wrote,
    );
    if (!ok || !mounted) return;
    _chatBloc.add(event);
  }

  // Cache for translated messages (all messages translated to selected language)
  final Map<String, String> _translatedMessages = {};

  /// One translation Future per (message, language, content) — the list's
  /// FutureBuilders reuse it across rebuilds instead of starting a new async
  /// translation (and a frame of untranslated text) on every build.
  final Map<String, Future<Message>> _translationFutures = {};

  Future<Message> _memoTranslation(Message message) {
    final key =
        '${message.messageId}_${_targetLanguage}_${message.content.hashCode}';
    if (_translationFutures.length > 600) _translationFutures.clear();
    return _translationFutures[key] ??= _translateMessage(message);
  }
  // Cache for detected source languages per message
  final Map<String, String> _detectedLanguages = {};
  bool _hasCheckedModels = false;
  String? _userLanguage;
  // The language the user wants to practice/use in this chat (can be changed per chat)
  String? _chatTargetLanguage;
  final bool _translationEnabled = true; // Translation always active
  bool _isUploadingMedia = false;
  double _uploadProgress = 0.0;

  // Chat learning settings (user-customizable)
  bool _showOriginalText = true;       // Show original text below translation
  bool _showGrammarCheck = true;       // Check grammar before sending
  bool _showCulturalTips = true;       // Show cultural context tooltips
  bool _showIcebreakers = true;        // Ice-breakers icon (+ empty-chat ideas)
  bool _showSentences = true;          // Suggested sentences icon
  bool _showPronunciation = true;      // Double-tap for TTS pronunciation
  bool _ttsReadTranslated = true;     // TTS reads translated text (true) or original (false)
  bool _showLanguageFlags = true;     // Show flag emoji next to translated/original text
  bool _showXpBar = true;             // Show streak & XP progress bar
  bool _showPhraseOfDaySetting = true; // Show phrase of the day banner

  // Media preview state
  XFile? _selectedImageXFile;
  XFile? _selectedVideoXFile;

  // Album photos selected for sending
  List<String> _selectedAlbumPhotos = [];

  // Reply state
  Message? _replyingToMessage;

  // Smart replies

  // Grammar correction

  // One-time chat gesture mini-tour (hold to translate / double-tap to hear)
  bool _chatTourChecked = false;
  bool _showGrammarBanner = false;


  // Chat streak & XP
  int _chatStreak = 0;
  int _sessionXp = 0;
  int _uniqueWordsUsed = 0;

  // Phrase of the Day
  String? _phraseOfTheDay;
  String? _phraseTranslation;
  String? _phraseAuthor;
  bool _showPhraseOfDay = true;

  // Pagination — open on a BOUNDED latest window (Firestore offline persistence
  // serves it from the device cache and only syncs newer messages), then page
  // older messages in on scroll instead of ever loading the whole history.
  static const int _initialMessageWindow = 30;
  static const int _messagePageSize = 30;
  int _messageLimit = _initialMessageWindow;
  int _loadedBeforeLastPage = -1;
  // In-flight upload progress subscription — cancelled in dispose() so an upload
  // finishing after the screen closes can't setState into a disposed widget.
  StreamSubscription<TaskSnapshot>? _uploadSub;
  StreamSubscription<void>? _screenshotSub;
  final ChatScreenshotNotice _screenshotNotice = ChatScreenshotNotice();
  bool _isLoadingMore = false;

  LanguageProvider? _languageProvider;
  String? _currentUserName;
  Profile? _currentUserProfile;

  // Match data for Exchange Details
  Match? _matchData;

  // Push-notification mute state for this conversation (per-user)
  bool _isConversationMuted = false;

  @override
  void initState() {
    super.initState();
    TranslationService.dailyLimitReached.addListener(_onTranslationLimit);
    // "Attractions in <city>" can send an attraction into this chat.
    ChatAttractionShare.sender.value = _sendAttraction;
    // Suppress foreground push notifications for this conversation
    PushNotificationService.activeConversationId = widget.matchId;
    _translationService.initialize();
    _scrollController.addListener(_onScroll);
    _chatBloc = di.sl<ChatBloc>()
      ..add(ChatConversationLoaded(
        matchId: widget.matchId,
        currentUserId: widget.currentUserId,
        otherUserId: widget.otherUserId,
        limit: _messageLimit,
        conversation: widget.initialConversation,
      ));
    _chatDataSource = ChatRemoteDataSourceImpl(
      firestore: FirebaseFirestore.instance,
      blockedUsersService: di.sl(),
    );
    _albumAccessDatasource = AlbumAccessDatasource(firestore: FirebaseFirestore.instance);
    _fetchCurrentUserName();
    // "X took a screenshot" notice (iOS; Android 14+ when FLAG_SECURE is off).
    _screenshotSub = ScreenSecurityService.instance.screenshots
        .listen((_) => _postScreenshotNotice());
    _loadPhraseOfTheDay();
    _loadChatSettings();
    _loadMuteState();
    _fetchMatchData();
    // AI consent (Apple 5.1.2(i)): this chat auto-translates the other
    // person's messages and offers AI features, so ask once before the first
    // use. Bubbles re-translate as soon as the user allows it.
    AiConsentService.instance.statusListenable.addListener(_onAiConsentChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AiConsentGate.maybePromptOnce(context);
    });
  }

  void _onAiConsentChanged() {
    // Granted: bubbles re-translate. Turned off (Account settings > AI
    // services): drop the translations so the originals show again.
    if (!mounted) return;
    setState(() {
      _translationFutures.clear();
      _translatedMessages.clear();
    });
  }

  /// Load whether this conversation is muted for the current user
  Future<void> _loadMuteState() async {
    try {
      final muted = await _chatDataSource.isConversationMutedForUser(
        conversationId: widget.matchId,
        userId: widget.currentUserId,
      );
      if (mounted) setState(() => _isConversationMuted = muted);
    } catch (_) {}
  }

  /// Toggle mute for this conversation (per-user)
  Future<void> _toggleConversationMute() async {
    final newValue = !_isConversationMuted;
    setState(() => _isConversationMuted = newValue);
    try {
      await _chatDataSource.setConversationMutedForUser(
        conversationId: widget.matchId,
        userId: widget.currentUserId,
        isMuted: newValue,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newValue
              ? AppLocalizations.of(context)!.chatNotificationsMutedForChat
              : AppLocalizations.of(context)!.chatNotificationsUnmuted),
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.backgroundCard,
        ),
      );
    } catch (e) {
      // Revert on failure
      if (mounted) setState(() => _isConversationMuted = !newValue);
      debugPrint('Mute toggle error: $e');
    }
  }

  /// Fetch match data to enable "See Exchange Details" option
  Future<void> _fetchMatchData() async {
    try {
      final matchDoc = await FirebaseFirestore.instance
          .collection('matches')
          .doc(widget.matchId)
          .get();
      if (matchDoc.exists && mounted) {
        final data = matchDoc.data()!;
        setState(() {
          _matchData = Match(
            matchId: matchDoc.id,
            userId1: data['userId1'] as String? ?? '',
            userId2: data['userId2'] as String? ?? '',
            matchedAt: (data['matchedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            isActive: data['isActive'] as bool? ?? true,
          );
        });
      }
    } catch (_) {
      // No match found — option won't appear
    }
  }

  /// Load chat settings: per-chat first, then global defaults
  Future<void> _loadChatSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    // Check if this chat has custom settings
    final p = ChatSettingsPrefs.readPrefix(prefs, widget.matchId); // per-chat or global

    // Load per-chat language if set
    final savedLang = prefs.getString('chat_${widget.matchId}_language');
    if (savedLang != null) {
      _chatTargetLanguage = savedLang;
    }

    setState(() {
      _showOriginalText = prefs.getBool('${p}showOriginalText') ?? true;
      _showGrammarCheck = prefs.getBool('${p}showGrammarCheck') ?? true;
      _showCulturalTips = prefs.getBool('${p}showCulturalTips') ?? true;
      _showIcebreakers = prefs.getBool('${p}showIcebreakers') ?? true;
      _showSentences = prefs.getBool('${p}showSentences') ?? true;
      _showPronunciation = prefs.getBool('${p}showPronunciation') ?? true;
      _ttsReadTranslated = prefs.getBool('${p}ttsReadTranslated') ?? true;
      _showLanguageFlags = prefs.getBool('${p}showLanguageFlags') ?? true;
      _showXpBar = prefs.getBool('${p}showXpBar') ?? true;
      _showPhraseOfDaySetting = prefs.getBool('${p}showPhraseOfDay') ?? true;
    });
  }

  /// The current values of every chat display setting.
  Map<String, bool> _settingsValues() => {
        'showOriginalText': _showOriginalText,
        'showGrammarCheck': _showGrammarCheck,
        'showCulturalTips': _showCulturalTips,
        'showIcebreakers': _showIcebreakers,
        'showSentences': _showSentences,
        'showPronunciation': _showPronunciation,
        'ttsReadTranslated': _ttsReadTranslated,
        'showLanguageFlags': _showLanguageFlags,
        'showXpBar': _showXpBar,
        'showPhraseOfDay': _showPhraseOfDaySetting,
      };

  /// Save current chat settings for this specific chat only
  Future<void> _saveSettingsToThisChat() async {
    final prefs = await SharedPreferences.getInstance();
    await ChatSettingsPrefs.saveForChat(prefs, widget.matchId, _settingsValues());
  }

  /// Save current chat settings for ALL chats (also drops every chat's own
  /// override, so the choice really applies everywhere).
  Future<void> _saveSettingsToAllChats() async {
    final prefs = await SharedPreferences.getInstance();
    await ChatSettingsPrefs.saveForAllChats(prefs, _settingsValues());
  }

  Future<void> _fetchCurrentUserName({bool forceServer = false}) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(widget.currentUserId)
          .get(forceServer ? const GetOptions(source: Source.server) : null);
      if (mounted && doc.exists) {
        final data = doc.data()!;
        setState(() {
          _currentUserName = data['displayName'] as String? ?? 'Someone';
          _currentUserProfile = ProfileModel.fromJson({...data, 'userId': doc.id});
        });
      }
    } catch (_) {
      // Silently fail - will use fallback name
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen to language changes for retranslation
    final provider = Provider.of<LanguageProvider>(context, listen: false);
    if (_languageProvider != provider) {
      _languageProvider?.removeListener(_onLanguageChanged);
      _languageProvider = provider;
      _languageProvider!.addListener(_onLanguageChanged);
    }
    // Always set user language from provider so _targetLanguage is correct
    _userLanguage = provider.currentLocale.languageCode;
  }

  void _onLanguageChanged() {
    // Clear caches and retranslate
    _translatedMessages.clear();
    _translationService.clearCache();
    _userLanguage = _languageProvider!.currentLocale.languageCode;
    _hasCheckedModels = false;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  /// Load more messages when user scrolls to the top (oldest messages)
  void _onScroll() {
    if (_isLoadingMore) return;
    // In a reversed ListView, maxScrollExtent is the top (oldest messages)
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      // The last page added nothing = the whole history is already here.
      final st = _chatBloc.state;
      final loaded = st is ChatLoaded ? st.messages.length : 0;
      if (loaded <= _loadedBeforeLastPage) return;
      _loadedBeforeLastPage = loaded;
      setState(() => _isLoadingMore = true);
      _messageLimit += _messagePageSize;
      _chatBloc.add(ChatConversationLoaded(
        matchId: widget.matchId,
        currentUserId: widget.currentUserId,
        otherUserId: widget.otherUserId,
        limit: _messageLimit,
      ));
      // Reset loading flag after a short delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => _isLoadingMore = false);
      });
    }
  }

  @override
  void dispose() {
    TranslationService.dailyLimitReached.removeListener(_onTranslationLimit);
    if (ChatAttractionShare.sender.value == _sendAttraction) ChatAttractionShare.sender.value = null;
    AiConsentService.instance.statusListenable.removeListener(_onAiConsentChanged);
    _scrollController.removeListener(_onScroll);
    // Clear active conversation so notifications resume
    if (PushNotificationService.activeConversationId == widget.matchId) {
      PushNotificationService.activeConversationId = null;
    }
    _languageProvider?.removeListener(_onLanguageChanged);
    _uploadSub?.cancel();
    _screenshotSub?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _chatBloc.close();
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

  /// Get the language the current user wants to read the chat in.
  /// Defaults to the current user's app language.
  String get _targetLanguage {
    return _chatTargetLanguage ?? _userLanguage ?? 'en';
  }

  /// Translate ALL messages to the selected chat language.
  /// The translated text is shown as the main content, with the original below it.
  Future<Message> _translateMessage(Message message) async {
    // Don't translate non-text messages
    if (message.type != MessageType.text) return message;
    if (message.content.trim().isEmpty) return message;
    // A shared attraction renders as a card from its stored i18n texts;
    // attraction content is never sent to a translation service.
    if (ChatAttractionShare.of(message.metadata) != null) return message;

    final selectedLang = _targetLanguage;
    // Google Translate uses hyphens: pt_BR -> pt-BR
    final translateTo = selectedLang.replaceAll('_', '-');

    // Check cache — keyed by messageId+language
    final cacheKey = '${message.messageId}_$selectedLang';
    if (_translatedMessages.containsKey(cacheKey)) {
      final cached = _translatedMessages[cacheKey]!;
      if (cached != message.content) {
        return message.copyWith(
          translatedContent: cached,
          detectedLanguage: _detectedLanguages[message.messageId] ?? message.detectedLanguage,
        );
      }
      return message;
    }

    debugPrint('TRANSLATE: "${message.content.length > 40 ? message.content.substring(0, 40) : message.content}" -> $translateTo');

    // translateDetailed never throws, returns THIS message's detected language
    // (not a service-wide "last detected" value shared with every other
    // bubble), and reports failure separately from "already in your language".
    final result = await _translationService.translateDetailed(
      text: message.content,
      sourceLanguage: 'auto',
      targetLanguage: translateTo,
      message: _messageRef(message),
    );
    return _applyTranslation(message, cacheKey, result);
  }

  /// Server-stored translation fields of [message], so a translation that is
  /// already on the message (or its detected language) costs nothing, and a
  /// miss is translated by id (stored for both participants).
  ChatMessageRef? _messageRef(Message message) {
    final conversationId = message.conversationId.isNotEmpty
        ? message.conversationId
        : (widget.initialConversation?.conversationId ?? '');
    final ref = ChatMessageRef(
      kind: ChatMessageRef.conversation,
      parentId: conversationId,
      messageId: message.messageId,
      lang: message.lang,
      tr: message.tr,
      trHash: message.trHash,
    );
    return ref.isValid ? ref : null;
  }

  /// The translation available without waiting (stored on the message,
  /// memory, phrasebook, nothing to translate): the bubble paints it in its
  /// first frame instead of the original.
  Message? _syncTranslation(Message message) {
    if (message.type != MessageType.text || message.content.trim().isEmpty) {
      return message;
    }
    final r = _translationService.translateSync(
      text: message.content,
      targetLanguage: _targetLanguage.replaceAll('_', '-'),
      message: _messageRef(message),
    );
    if (r == null || r.failed) return null;
    return _applyTranslation(
        message, '${message.messageId}_$_targetLanguage', r);
  }

  Message _applyTranslation(
      Message message, String cacheKey, TranslationResult result) {
    final detectedLang = result.detectedLanguage;

    // No AI consent yet / declined: show the original, no error (not cached;
    // _onAiConsentChanged re-runs it once the user allows translation).
    if (result.consentRequired) return message;

    if (result.failed) {
      // Not cached: the Retry action (or reopening the chat) tries again.
      debugPrint('TRANSLATE FAILED for ${message.messageId}');
      _onTranslationFailed(message);
      return message;
    }

    if (detectedLang != null) {
      _detectedLanguages[message.messageId] = detectedLang;
    }

    if (!result.isTranslated) {
      // Same language (or nothing to change): nothing to show.
      _translatedMessages[cacheKey] = message.content;
      return message.copyWith(detectedLanguage: detectedLang);
    }

    _translatedMessages[cacheKey] = result.text;
    return message.copyWith(
      translatedContent: result.text,
      detectedLanguage: detectedLang ?? message.detectedLanguage,
    );
  }

  /// Memo keys of translations that failed, so Retry re-runs exactly those.
  final Set<String> _failedTranslationKeys = {};
  bool _translationErrorShown = false;

  void _onTranslationFailed(Message message) {
    _failedTranslationKeys.add(
        '${message.messageId}_${_targetLanguage}_${message.content.hashCode}');
    if (_translationErrorShown || !mounted) return;
    _translationErrorShown = true;
    // Post-frame: this runs inside a FutureBuilder's future.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(l10n.chatTranslationFailed),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: l10n.retry,
            onPressed: _retryFailedTranslations,
          ),
        ),
      );
    });
  }

  void _retryFailedTranslations() {
    if (!mounted) return;
    setState(() {
      _failedTranslationKeys.forEach(_translationFutures.remove);
      _failedTranslationKeys.clear();
      _translationErrorShown = false;
    });
  }

  Future<void> _sendMessage(BuildContext _) async {
    // Record activity for online presence
    PresenceService.instance?.recordActivity();
    // A verified buyer <-> organizer chat needs no plan (server-enforced).
    final buyerChat = _buyerChat;
    // Valid-membership gate: a valid GreenGo membership is required to send
    // messages. Active Base (free) stays allowed — only a truly expired
    // membership is blocked (routes to the marketplace to renew).
    if (!buyerChat &&
        _currentUserProfile != null &&
        !await TierGate().ensureValidMembership(context, _currentUserProfile!)) {
      return;
    }
    if (!mounted) return;
    // Base membership gate. Without Base the user may still chat with
    // TierEntitlements.freeDailyChats people a day (server-enforced).
    final wasMember =
        buyerChat || (_currentUserProfile?.isBaseMembershipActive ?? false);
    var freeChat = buyerChat;
    if (!wasMember && _currentUserProfile != null) {
      final claim =
          await FreeChatService.instance.claim(_conversationIdForSend());
      if (!mounted) return;
      if (claim.status == FreeChatStatus.limitReached) {
        final l10n = AppLocalizations.of(context)!;
        await BaseMembershipRequiredDialog.show(
          context,
          userId: widget.currentUserId,
          title: l10n.freeChatLimitTitle,
          body: l10n.freeChatLimitBody(claim.limit),
        );
        return;
      }
      freeChat = claim.canSend;
      if (claim.status == FreeChatStatus.allowed && claim.added) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!
              .freeChatUsedToday(claim.used, claim.limit)),
          duration: const Duration(seconds: 3),
        ));
      }
    }
    if (!freeChat) {
      final allowed = await BaseMembershipGate.checkAndGate(
        context: context,
        profile: _currentUserProfile,
        userId: widget.currentUserId,
      );
      if (!allowed) return;
      // Refresh profile from server after successful purchase so gate won't block again
      if (!wasMember) await _fetchCurrentUserName(forceServer: true);
    }

    // If album photos are selected, send each as a separate image message
    if (_selectedAlbumPhotos.isNotEmpty) {
      final photos = List<String>.from(_selectedAlbumPhotos);
      setState(() {
        _selectedAlbumPhotos = [];
      });
      _messageController.clear();
      _sendAlbumPhotosSequentially(photos);
      return;
    }

    // If media is selected, send media (with optional caption)
    if (_selectedImageXFile != null) {
      _sendImageMessage(context, _selectedImageXFile!);
      _clearSelectedMedia();
      _messageController.clear();
      return;
    }
    if (_selectedVideoXFile != null) {
      _sendVideoMessage(context, _selectedVideoXFile!);
      _clearSelectedMedia();
      _messageController.clear();
      return;
    }

    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    // Check for contact information
    final filterResult = _contentFilter.analyzeContent(content);
    if (filterResult.hasContactInfo) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      showUserErrorMessage(context, l10n.chatMessageBlockedContains(filterResult.localizedViolations(l10n).join(', ')));
      return;
    }

    // Reset grammar banner
    if (_showGrammarBanner) {
      setState(() => _showGrammarBanner = false);
    }

    // Send as reply if replying to a message
    if (_replyingToMessage != null) {
      _addSend(ChatMessageReplied(
        content: content,
        replyToMessageId: _replyingToMessage!.messageId,
      ));
      _clearReplyMessage();
    } else {
      _addSend(ChatMessageSent(
        content: content,
        // Offline keywords + CEFR level for the receiver (MessageInsights).
        metadata: MessageInsights.metadataFor(content, language: _userLanguage),
      ));
    }

    // Play the "message sent" sound effect.
    AppSoundService().play(AppSound.messageSent);

    // Track XP for learning gamification
    _trackMessageXp(content);

    _messageController.clear();

    // Vocabulary tracking is handled async during scheduled stats refresh (3AM UTC)
    // or when user manually refreshes on the Personal Statistics page.

    // Scroll to bottom after sending (post-frame callback for reliable timing)
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    // One shared reason list on every report surface (report_reasons.dart),
    // incl. "Child sexual exploitation" (Terms 19.3 -> server csae P0 path).
    final l10n = AppLocalizations.of(context)!;
    final selectedReason = await showReportReasonDialog(
      context,
      title: l10n.chatReportMessage,
      prompt: l10n.chatWhyReportMessage,
    );

    if (selectedReason == null || !context.mounted) return;

    try {
      await _chatDataSource.reportMessage(
        conversationId: widget.matchId,
        messageId: message.messageId,
        reporterId: widget.currentUserId,
        reportedUserId: message.senderId,
        reason: selectedReason.code,
        reasonLabel: selectedReason.label(l10n),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.chatMessageReported),
            backgroundColor: AppColors.richGold,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        showUserError(context, e);
      }
    }
  }

  /// The location picker opened on the user's own location: the profile's
  /// position at once (no permission prompt), then the device's exact position
  /// when it is available.
  Route<PickedPlace> _locationPickerRoute() {
    final me = OwnProfileStore.instance.peek(widget.currentUserId)?.location;
    final known = me != null && (me.latitude != 0 || me.longitude != 0);
    return LocationPickerScreen.route(
      initialLat: known ? me.latitude : null,
      initialLng: known ? me.longitude : null,
      autoLocate: true,
    );
  }

  /// Sends [a] as an attraction card (text + metadata for older versions).
  Future<void> _sendAttraction(Attraction a, String bucket) async {
    _addSend(ChatMessageSent(
      content: ChatAttractionShare.contentFor(a, Localizations.localeOf(context)),
      type: MessageType.text,
      metadata: ChatAttractionShare.metadataFor(a, bucket),
    ));
  }

  /// Pick a place (search, current location or a pin) and send it.
  Future<void> _sendLocation(BuildContext context) async {
    final picked = await Navigator.of(context)
        .push<PickedPlace>(_locationPickerRoute());
    if (picked == null || !mounted) return;
    _addSend(ChatMessageSent(
      content: '${picked.lat},${picked.lng}',
      type: MessageType.location,
      metadata: LocationShareService.metadataFor(picked.lat, picked.lng,
          address: picked.address),
    ));
  }

  /// Show attachment options bottom sheet
  void _showAttachmentOptions(BuildContext context) {
    final parentContext = context;
    showModalBottomSheet(
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
              AppLocalizations.of(sheetCtx)!.chatSendAttachment,
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
                _buildAttachmentOption(
                  sheetCtx,
                  icon: Icons.collections,
                  label: AppLocalizations.of(sheetCtx)?.albumOption ?? 'Album',
                  color: Colors.teal,
                  onTap: () {
                    // _buildAttachmentOption already pops the sheet
                    // Use post-frame callback to open album after sheet closes
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _showMyAlbumPhotos();
                    });
                  },
                ),
                _buildAttachmentOption(
                  sheetCtx,
                  icon: Icons.photo_library,
                  label: AppLocalizations.of(sheetCtx)!.chatAttachGallery,
                  color: AppColors.richGold,
                  onTap: () => _pickImage(parentContext, ImageSource.gallery),
                ),
                _buildAttachmentOption(
                  sheetCtx,
                  icon: Icons.camera_alt,
                  label: AppLocalizations.of(sheetCtx)!.chatAttachCamera,
                  color: Colors.blue,
                  onTap: () => _pickImage(parentContext, ImageSource.camera),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  sheetCtx,
                  icon: Icons.videocam,
                  label: AppLocalizations.of(sheetCtx)!.chatAttachVideo,
                  color: Colors.purple,
                  onTap: () => _pickVideo(parentContext, ImageSource.gallery),
                ),
                _buildAttachmentOption(
                  sheetCtx,
                  icon: Icons.video_call,
                  label: AppLocalizations.of(sheetCtx)!.chatAttachRecord,
                  color: Colors.red,
                  onTap: () => _pickVideo(parentContext, ImageSource.camera),
                ),
                _buildAttachmentOption(
                  sheetCtx,
                  icon: Icons.location_on,
                  label: AppLocalizations.of(sheetCtx)!.chatShareLocation,
                  color: Colors.green,
                  onTap: () => _sendLocation(parentContext),
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
      final image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        setState(() {
          _selectedImageXFile = image;
          _selectedVideoXFile = null;
        });
      }
    } catch (e) {
      if (context.mounted) {
        showUserError(context, e);
      }
    }
  }

  Future<void> _pickVideo(BuildContext context, ImageSource source) async {
    try {
      final video = await _imagePicker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: 60),
      );

      if (video != null && mounted) {
        setState(() {
          _selectedVideoXFile = video;
          _selectedImageXFile = null;
        });
      }
    } catch (e) {
      if (context.mounted) {
        showUserError(context, e);
      }
    }
  }

  Future<void> _sendImageMessage(BuildContext ctx, XFile image) async {
    if (_isUploadingMedia) return;

    // Check media send limit
    if (!await _checkMediaSendLimit(context)) return;

    setState(() {
      _isUploadingMedia = true;
      _uploadProgress = 0.0;
    });

    try {
      // Compress image before upload to reduce storage costs.
      // Web has no dart:io File: compress the picked bytes instead. The
      // on-device ML Kit check is mobile-only (no ML Kit on web); the backend
      // `moderateChatImage` check below still runs on every platform.
      File? file;
      Uint8List? webBytes;
      if (kIsWeb) {
        webBytes = await image.readAsBytes();
        final compressed = await ImageCompression.compressBytes(
          webBytes,
          quality: ImageCompression.chatImageQuality,
          maxWidth: ImageCompression.chatImageMaxWidth,
          maxHeight: ImageCompression.chatImageMaxHeight,
        );
        if (compressed != null && compressed.isNotEmpty) webBytes = compressed;
      } else {
        file = File(image.path);
        try {
          file = await ImageCompression.compressChatImage(file);
          debugPrint('Chat image compressed for upload');
        } catch (e) {
          debugPrint('Chat image compression failed, using original: $e');
          // Use original if compression fails
        }
      }

      // Validate image for nudity/explicit content BEFORE uploading
      final validationResult = file == null
          ? PhotoValidationResult.valid()
          : await PhotoValidationService().validateImageForSending(file);
      if (!validationResult.isValid) {
        if (mounted) {
          setState(() {
            _isUploadingMedia = false;
            _uploadProgress = 0.0;
            _selectedImageXFile = null;
          });
          showUserErrorMessage(context, AppLocalizations.of(context)?.photoExplicitContent ?? 'This image contains inappropriate content and cannot be sent.',);
        }
        return;
      }

      // Create unique filename
      final uuid = const Uuid().v4();
      final fileName = 'chat_images/${widget.matchId}/$uuid.jpg';

      // Upload to Firebase Storage
      final ref = FirebaseStorage.instance.ref().child(fileName);

      // uploaderId: the path holds the chat, not the user - read by the
      // server-side hash screening (uploadScreening.ts).
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'uploaderId': widget.currentUserId},
      );
      final uploadTask = file != null
          ? ref.putFile(file, metadata)
          : ref.putData(webBytes!, metadata);

      // Track upload progress
      _uploadSub?.cancel();
      _uploadSub = uploadTask.snapshotEvents.listen((snapshot) {
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

      // Backend moderation (second line of defense after on-device check)
      try {
        final moderationResult = await FirebaseFunctions.instance
            .httpsCallable('moderateChatImage')
            .call({
          'imageUrl': downloadUrl,
          'userId': widget.currentUserId,
          'context': 'chat_image',
        });

        final isApproved = moderationResult.data['isApproved'] as bool? ?? false;
        if (!isApproved) {
          // Delete the uploaded image — it was rejected by backend moderation
          await ref.delete().catchError((_) {});
          if (mounted) {
            setState(() {
              _isUploadingMedia = false;
              _uploadProgress = 0.0;
              _selectedImageXFile = null;
            });
            showUserErrorMessage(context, AppLocalizations.of(context)?.photoExplicitContent ?? 'This image contains inappropriate content and cannot be sent.',);
          }
          return;
        }
      } catch (e) {
        // If moderation call fails, still allow (on-device check already passed)
        debugPrint('Backend moderation call failed (allowing): $e');
      }

      if (mounted) {
        // Send message with image URL
        _addSend(ChatMessageSent(
          content: downloadUrl,
          type: MessageType.image,
        ));

        // Record media send usage
        await _usageLimitService.recordUsage(
          userId: widget.currentUserId,
          limitType: UsageLimitType.mediaSends,
        );
      }
    } catch (e) {
      if (mounted) {
        showUserError(context, e);
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

  Future<void> _sendVoiceMessage(XFile voice, Duration duration) async {
    if (_isUploadingMedia) return;
    setState(() => _isUploadingMedia = true);
    try {
      final uuid = const Uuid().v4();
      // Mobile: `.m4a` + audio/mp4 as always. Web: whatever the browser could
      // record (mp4 / webm / wav), read from the blob: URL as bytes.
      final ext = WebMedia.voiceExtension(voice);
      final fileName = 'chat_voice/${widget.matchId}/$uuid.$ext';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      await WebMedia.uploadXFile(
        ref,
        voice,
        contentType: WebMedia.voiceContentType(voice),
      );
      final downloadUrl = await ref.getDownloadURL();
      if (!kIsWeb) {
        try {
          final file = File(voice.path);
          if (file.existsSync()) file.deleteSync();
        } catch (_) {}
      }
      if (mounted) {
        _addSend(ChatMessageSent(
          content: downloadUrl,
          type: MessageType.voiceNote,
          metadata: {'durationMs': duration.inMilliseconds},
        ));
      }
    } catch (e) {
      if (mounted) {
        showUserErrorMessage(context, AppLocalizations.of(context)?.voiceFailedToSend ?? 'Failed to send voice message');
      }
    } finally {
      if (mounted) setState(() => _isUploadingMedia = false);
    }
  }

  Future<void> _sendVideoMessage(BuildContext ctx, XFile video) async {
    if (_isUploadingMedia) return;

    // Check media send limit
    if (!await _checkMediaSendLimit(context)) return;

    setState(() {
      _isUploadingMedia = true;
      _uploadProgress = 0.0;
    });

    try {
      // Check file size (limit to 50MB). XFile.length works on web too.
      final fileSize = await video.length();
      if (fileSize > 50 * 1024 * 1024) {
        if (mounted) {
          showUserErrorMessage(context, AppLocalizations.of(context)!.chatVideoTooLarge);
        }
        return;
      }

      // Create unique filename
      final uuid = const Uuid().v4();
      final extension = WebMedia.videoExtension(video);
      final fileName = 'chat_videos/${widget.matchId}/$uuid.$extension';

      // Upload to Firebase Storage
      final ref = FirebaseStorage.instance.ref().child(fileName);

      // putFile on mobile, putData(bytes) on web.
      final uploadTask = await WebMedia.startXFileUpload(
        ref,
        video,
        contentType: 'video/$extension',
      );

      // Track upload progress
      _uploadSub?.cancel();
      _uploadSub = uploadTask.snapshotEvents.listen((snapshot) {
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

      if (mounted) {
        // Send message with video URL
        _addSend(ChatMessageSent(
          content: downloadUrl,
          type: MessageType.video,
        ));

        // Record media send usage
        await _usageLimitService.recordUsage(
          userId: widget.currentUserId,
          limitType: UsageLimitType.mediaSends,
        );
      }
    } catch (e) {
      if (mounted) {
        showUserError(context, e);
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

  /// Check media send limit before uploading
  Future<bool> _checkMediaSendLimit(BuildContext context) async {
    try {
      // EFFECTIVE tier from profiles/{uid} (the `memberships` mirror drifts
      // and an expired paid tier must count as free).
      final tier = _currentUserProfile?.effectiveTier ??
          await TierGate().resolveTier(widget.currentUserId);

      final rules = MembershipRules.getDefaultsForTier(tier);
      final result = await _usageLimitService.checkLimit(
        userId: widget.currentUserId,
        limitType: UsageLimitType.mediaSends,
        rules: rules,
        currentTier: tier,
      );

      if (!result.isAllowed) {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.backgroundCard,
              title: Text(
                AppLocalizations.of(context)!.chatMediaLimitReached,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              content: Text(
                result.message,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(AppLocalizations.of(context)!.ok),
                ),
              ],
            ),
          );
        }
        return false;
      }
      return true;
    } catch (e) {
      // On error, allow the send (don't block due to limit check failure)
      debugPrint('Media limit check error: $e');
      return true;
    }
  }

  /// Show current user's private album photos for sending in chat
  Future<void> _showMyAlbumPhotos() async {
    try {
      // Own private album: profiles_private (security P1-4).
      final privatePhotos = await PrivateAlbum.own(widget.currentUserId);
      if (!mounted) return;

      if (privatePhotos.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.chatNoPrivatePhotos),
            backgroundColor: AppColors.warningAmber,
          ),
        );
        return;
      }

      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.backgroundCard,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (bottomSheetCtx) {
          final selectedIndices = <int>{};
          return StatefulBuilder(
            builder: (_, setSheetState) => DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.3,
              maxChildSize: 0.9,
              expand: false,
              builder: (_, scrollController) => Column(
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
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)?.shareAlbum ?? 'Share Album',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.chatSelectPhotos,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: privatePhotos.length,
                      itemBuilder: (ctx, index) {
                        final photoUrl = privatePhotos[index];
                        final isSelected = selectedIndices.contains(index);
                        return GestureDetector(
                          onTap: () {
                            setSheetState(() {
                              if (isSelected) {
                                selectedIndices.remove(index);
                              } else {
                                selectedIndices.add(index);
                              }
                            });
                          },
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: photoUrl,
                                    fit: BoxFit.cover,
                                    // Grid thumbnail (~120dp, 3 columns) — decode small.
                                    memCacheWidth: 300,
                                    placeholder: (context, _) {
                                      return Container(
                                        color: AppColors.backgroundDark,
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            color: AppColors.richGold,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.richGold, width: 3),
                                      color: Colors.black.withOpacity(0.3),
                                    ),
                                  ),
                                ),
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected ? AppColors.richGold : Colors.black.withOpacity(0.5),
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  // Select button
                  if (selectedIndices.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            final photosToSelect = selectedIndices
                                .map((i) => privatePhotos[i])
                                .toList();
                            // Close the album bottom sheet
                            Navigator.pop(bottomSheetCtx);
                            // Use post-frame callback to ensure setState runs after pop completes
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() {
                                  _selectedAlbumPhotos = photosToSelect;
                                  _selectedImageXFile = null;
                                  _selectedVideoXFile = null;
                                });
                              }
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.richGold,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.chatAlbumSelectCount(selectedIndices.length),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        showUserError(context, e, title: AppLocalizations.of(context)!.chatFailedToLoadAlbum);
      }
    }
  }

  /// Send a photo from private album — bypasses media limit
  Future<void> _sendAlbumPhotosSequentially(List<String> photoUrls) async {
    for (final photoUrl in photoUrls) {
      if (!mounted) return;
      _addSend(ChatMessageSent(
        content: photoUrl,
        type: MessageType.image,
      ));
      // Wait for the bloc to finish sending before dispatching the next
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  /// View other user's private album (if access granted)
  Future<void> _viewOtherUserAlbum(BuildContext context) async {
    // Other people's private photos are app-only: a browser cannot block
    // screenshots (see ScreenSecurityService).
    if (isAppOnlyContentBlocked()) {
      await showAppOnlyContentSheet(context);
      return;
    }
    try {
      // Check if current user has access to other user's album
      final hasAccess = await _albumAccessDatasource.hasAccess(
        ownerId: widget.otherUserId,
        viewerId: widget.currentUserId,
      );

      if (!mounted) return;

      if (!hasAccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.albumNotShared ?? 'Album not shared with you'),
            backgroundColor: AppColors.warningAmber,
          ),
        );
        return;
      }

      // Terms §16.9(d): accept the private-content warning (proof stored
      // server-side) before any photo of the album is fetched or shown.
      if (!context.mounted) return;
      if (!await ensurePrivateContentWarningAccepted(context)) return;
      if (!mounted || !context.mounted) return;

      // Other user's private album: server-checked grant (getSharedAlbum).
      final privatePhotos = await PrivateAlbum.sharedBy(widget.otherUserId);

      if (!mounted) return;

      if (privatePhotos.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.chatNoPrivatePhotos),
            backgroundColor: AppColors.warningAmber,
          ),
        );
        return;
      }

      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.backgroundCard,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (ctx, scrollController) => Column(
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
              const SizedBox(height: 16),
              Text(
                '${widget.otherUserProfile.displayName}\'s ${AppLocalizations.of(context)?.privateAlbum ?? "Private Album"}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: privatePhotos.length,
                  itemBuilder: (ctx, index) {
                    final photoUrl = privatePhotos[index];
                    return GestureDetector(
                      onTap: () => _openPhotoFullscreen(context, photoUrl, privatePhotos.cast<String>(), index),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: photoUrl,
                          // Signed URLs change on every fetch: cache by object.
                          cacheKey: stableMediaCacheKey(photoUrl),
                          fit: BoxFit.cover,
                          // Grid thumbnail (~120dp, 3 columns) — decode small.
                          memCacheWidth: 300,
                          placeholder: (context, _) {
                            return Container(
                              color: AppColors.backgroundDark,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.richGold,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        showUserError(context, e, title: AppLocalizations.of(context)!.chatFailedToLoadAlbum);
      }
    }
  }

  /// Open a photo in fullscreen with zoom capability
  void _openPhotoFullscreen(BuildContext context, String photoUrl, List<String> allPhotos, int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
                title: Text(
                  '${initialIndex + 1} / ${allPhotos.length}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                centerTitle: true,
              ),
              body: Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: ViewerWatermark.zoomed(
                    child: CachedNetworkImage(
                    imageUrl: photoUrl,
                    cacheKey: stableMediaCacheKey(photoUrl),
                    fit: BoxFit.contain,
                    // Full-screen viewer: full resolution, disk-cached.
                    placeholder: (context, _) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.richGold,
                        ),
                      );
                    },
                  ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Grant access to current user's private album to the other user
  Future<void> _grantAlbumAccess(BuildContext context) async {
    try {
      await _albumAccessDatasource.grantAccess(
        ownerId: widget.currentUserId,
        grantedToId: widget.otherUserId,
      );
      if (mounted) {
        final name = _currentUserName ?? 'Someone';
        _addSend(ChatMessageSent(
          content: '$name shared their private album', // i18n-ignore: stored fallback; bubble localizes by type
          type: MessageType.albumShare,
          metadata: {
            'albumOwnerId': widget.currentUserId,
            'albumOwnerName': name,
          },
        ));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.grantAlbumAccess ?? 'Album shared'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showUserError(context, e, title: AppLocalizations.of(context)!.chatFailedToShareAlbum);
      }
    }
  }

  /// Revoke access to current user's private album from the other user
  Future<void> _revokeAlbumAccess(BuildContext context) async {
    try {
      await _albumAccessDatasource.revokeAccess(
        ownerId: widget.currentUserId,
        grantedToId: widget.otherUserId,
      );
      if (mounted) {
        final name = _currentUserName ?? 'Someone';
        _addSend(ChatMessageSent(
          content: '$name revoked album access', // i18n-ignore: stored fallback; bubble localizes by type
          type: MessageType.albumRevoke,
          metadata: {
            'albumOwnerId': widget.currentUserId,
            'albumOwnerName': name,
          },
        ));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.revokeAccess ?? 'Album access revoked'),
            backgroundColor: AppColors.warningAmber,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showUserError(context, e, title: AppLocalizations.of(context)!.chatFailedToRevokeAccess);
      }
    }
  }

  /// Handle tapping on an album share message
  Future<void> _onAlbumMessageTapped(Message message) async {
    try {
      final albumOwnerId = message.metadata?['albumOwnerId'] as String?;
      if (albumOwnerId == null) return;

      final hasAccess = await _albumAccessDatasource.hasAccess(
        ownerId: albumOwnerId,
        viewerId: widget.currentUserId,
      );

      if (!mounted) return;

      if (!hasAccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.albumNotShared ?? 'Album access has been revoked'),
            backgroundColor: AppColors.warningAmber,
          ),
        );
        return;
      }

      _viewOtherUserAlbum(context);
    } catch (e) {
      if (mounted) {
        showUserError(context, e, title: AppLocalizations.of(context)!.chatFailedToLoadAlbum);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          SafeNavigation.navigateToHome(context, widget.currentUserId);
        }
      },
      child: BlocProvider.value(
        value: _chatBloc,
        child: ShowCaseWidget(
          builder: (showcaseContext) => Scaffold(
          backgroundColor: AppColors.backgroundDark,
          appBar: _buildAppBar(),
        body: Column(
          children: [
            // "About: <listing> · <date>" (buyer <-> organizer chat).
            BlocBuilder<ChatBloc, ChatState>(
              builder: (context, _) {
                final c = _listingContext;
                return c == null
                    ? const SizedBox.shrink()
                    : ListingContextChip(
                        listingContext: c,
                        currentUserId: widget.currentUserId);
              },
            ),
            // Phrase of the Day banner
            if (_showPhraseOfDaySetting) _buildPhraseOfDay(),
            // Chat XP bar
            // Hidden: gamification is not shown in Exchanges (owner decision).
            if (AppConfig.showGamificationInExchanges &&
                _showXpBar &&
                _sessionXp > 0)
              _buildXpBar(),
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

                  if (state is ChatError &&
                      state.message.contains('age-assurance-required')) {
                    // P3-1: opening a NEW conversation while age assurance
                    // is required: show the gate, not an error.
                    return const AgeAssuranceRequiredPanel();
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
                            userErrorMessage(context, state.message),
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

                    final isOtherUserTyping = state is ChatLoaded && state.isOtherUserTyping;

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
                              backgroundImage: _headerPhoto != null
                                  ? CachedNetworkImageProvider(_headerPhoto!,
                                      maxWidth: 200)
                                  : null,
                              child: _headerPhoto == null
                                  ? Icon(
                                      _showBusinessIdentity
                                          ? Icons.storefront
                                          : Icons.person,
                                      size: 50,
                                      color: AppColors.textTertiary,
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              AppLocalizations.of(context)!.chatSayHiTo(_headerName),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                AppLocalizations.of(context)!.chatSendMessageToStart,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_showIcebreakers) _buildEmptyChatIcebreakers(),
                          ],
                        ),
                      );
                    }

                    final hasMoreMessages = messages.length >= _messageLimit;
                    final extraItems = (isOtherUserTyping ? 1 : 0) + (hasMoreMessages ? 1 : 0);

                    // One-time chat tutorial: hold = translate menu,
                    // double-tap = pronunciation (anchored on the newest
                    // received text message), then the languages menu and
                    // chat options in the app bar.
                    final tourBubbleIndex = messages.indexWhere((m) =>
                        m.senderId != widget.currentUserId &&
                        m.type == MessageType.text);
                    if (tourBubbleIndex != -1 && !_chatTourChecked) {
                      _chatTourChecked = true;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        TourController.instance.maybeStartMiniTour(
                          context,
                          tourId: TourController.chatTourId,
                          userId: widget.currentUserId,
                          keys: [
                            TourKeys.chatBubbleHold,
                            TourKeys.chatBubbleDoubleTap,
                            TourKeys.chatLanguageMenu,
                            TourKeys.chatSettings,
                          ],
                        );
                      });
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: messages.length + extraItems,
                      itemBuilder: (context, index) {
                        // Typing indicator at position 0
                        if (index == 0 && isOtherUserTyping) {
                          return _buildTypingIndicator();
                        }

                        // "Load more" indicator at the end (top of chat in reversed list)
                        final loadMoreIndex = messages.length + (isOtherUserTyping ? 1 : 0);
                        if (hasMoreMessages && index == loadMoreIndex) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: _isLoadingMore
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Text(
                                      AppLocalizations.of(context)!.chatScrollUpForOlder,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                            ),
                          );
                        }

                        final messageIndex =
                            isOtherUserTyping ? index - 1 : index;
                        final message = messages[messageIndex];

                        // Apply translation asynchronously
                        return FutureBuilder<Message>(
                          key: ValueKey('${message.messageId}_$_targetLanguage'),
                          future: _memoTranslation(message),
                          builder: (context, snapshot) {
                            // Apply the (memoised) translation onto the
                            // LATEST message so reactions/stars/read state
                            // stay live. Until it resolves, whatever is
                            // known synchronously (stored on the message,
                            // memory, phrasebook) shows in this frame.
                            final t =
                                snapshot.data ?? _syncTranslation(message);
                            final translatedMessage = t == null
                                ? message
                                : message.copyWith(
                                    translatedContent: t.translatedContent,
                                    detectedLanguage: t.detectedLanguage,
                                  );
                            final bubble = MessageBubble(
                              message: translatedMessage,
                              isCurrentUser:
                                  message.senderId == widget.currentUserId,
                              currentUserId: widget.currentUserId,
                              otherUserLanguage: _targetLanguage,
                              showOriginalText: _showOriginalText,
                              showCulturalTips: _showCulturalTips,
                              showPronunciation: _showPronunciation,
                              showLanguageFlags: _showLanguageFlags,
                              ttsReadTranslated: _ttsReadTranslated,
                              userSelectedLanguage: _targetLanguage,
                              otherUserIsMale: widget.otherUserProfile.gender.toLowerCase() != 'female',
                              currentUserIsMale: (_currentUserProfile?.gender ?? 'male').toLowerCase() != 'female',
                              userMembershipTier: _currentUserProfile?.effectiveTier,
                              onReport: (msg) => _reportMessage(context, msg),
                              onStar: (msg, isStarred) => _starMessage(context, msg, isStarred),
                              onReply: _setReplyMessage,
                              onForward: (msg) => _showForwardDialog(context, msg),
                              onAlbumTap: _onAlbumMessageTapped,
                              onReact: _reactToMessage,
                            );
                            if (messageIndex == tourBubbleIndex) {
                              final l10n = AppLocalizations.of(context)!;
                              return TourShowcase(
                                showcaseKey: TourKeys.chatBubbleHold,
                                title: l10n.tourChatHoldTitle,
                                description: l10n.tourChatHoldDesc,
                                gesture: TourGesture.longPress,
                                targetBorderRadius: BorderRadius.circular(16),
                                child: TourShowcase(
                                  showcaseKey: TourKeys.chatBubbleDoubleTap,
                                  title: l10n.tourChatDoubleTapTitle,
                                  description: l10n.tourChatDoubleTapDesc,
                                  gesture: TourGesture.doubleTap,
                                  targetBorderRadius: BorderRadius.circular(16),
                                  child: bubble,
                                ),
                              );
                            }
                            return bubble;
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

            // Grammar correction banner

            // Questions about the place the partner just named (offline, from
            // message metadata; no AI). The places list/map is the map icon.
            if (_showCulturalTips) _buildPlacesBar(),

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
                        Text(
                          AppLocalizations.of(context)!.chatUploading,
                          style: const TextStyle(
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

            // Input field — or, without Base, a "Base required to reply" bar
            // (messages can always be READ; the server refuses the send).
            if (_canReply)
              _buildInputField(context)
            else
              _buildReplyLockedBar(context),
          ],
        ),
        ),
        ),
      ),
    );
  }

  String _formatLastSeen(DateTime lastSeen) {
    final l10n = AppLocalizations.of(context)!;
    final diff = DateTime.now().difference(lastSeen);
    if (diff.inMinutes < 1) return l10n.chatOnlineJustNow;
    if (diff.inMinutes < 60) return l10n.chatOnlineMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.chatOnlineHoursAgo(diff.inHours);
    if (diff.inDays < 5) return l10n.chatOnlineDaysAgo(diff.inDays);
    return l10n.chatOffline;
  }

  /// Whether THIS conversation is a business (user-to-storefront) chat, keyed off
  /// the synthetic id `bizsearch_…` set by openConnectChat. A personal 1:1 chat
  /// with someone who also runs a store uses `search_…` and stays personal.
  bool get _isBusinessChat => widget.matchId.startsWith('bizsearch_');

  /// When this is a BUSINESS chat with a storefront owner, the header shows the
  /// STOREFRONT identity (business name + cover image) instead of the owner's
  /// personal name/photo. A person-to-person chat always shows the person.
  bool get _showBusinessIdentity =>
      _isBusinessChat &&
      widget.otherUserProfile.isBusiness &&
      (widget.otherUserProfile.businessName?.isNotEmpty ?? false);

  String get _headerName => _showBusinessIdentity
      ? widget.otherUserProfile.businessName!
      : widget.otherUserProfile.displayName;

  /// Preferred header/avatar image: storefront cover for a business, else the
  /// first personal photo (may be null).
  String? get _headerPhoto {
    if (_showBusinessIdentity) {
      // Business profile picture first (owner 2026-10-19), then the cover.
      final logo = widget.otherUserProfile.businessLogoOrNull;
      if (logo != null) return logo;
      final cover = widget.otherUserProfile.coverImageUrl;
      if (cover != null && cover.isNotEmpty) return cover;
    }
    final urls = widget.otherUserProfile.photoUrls;
    return urls.isNotEmpty ? urls.first : null;
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.backgroundCard,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => SafeNavigation.pop(context, userId: widget.currentUserId),
      ),
      title: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProfileDetailScreen(
                profile: widget.otherUserProfile,
                currentUserId: widget.currentUserId,
              ),
            ),
          );
        },
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.backgroundDark,
              backgroundImage: _headerPhoto != null
                  ? CachedNetworkImageProvider(_headerPhoto!, maxWidth: 80)
                  : null,
              child: _headerPhoto == null
                  ? Icon(
                      _showBusinessIdentity ? Icons.storefront : Icons.person,
                      size: 20,
                      color: AppColors.textTertiary,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        _headerName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Brief-backed (batched cache): the profile passed in
                    // may be a partial one built from a conversation row.
                    UserVerifiedBadge(uid: widget.otherUserId, size: 15),
                    if (widget.otherUserProfile.languages.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      LanguageFlagBadge(
                        languages: widget.otherUserProfile.languages,
                        fontSize: 12,
                      ),
                    ],
                  ],
                ),
                BlocBuilder<ChatBloc, ChatState>(
                  builder: (context, state) {
                    if (state is ChatLoaded && state.isOtherUserTyping) {
                      return Text(
                        AppLocalizations.of(context)!.chatTyping,
                        style: const TextStyle(
                          color: AppColors.richGold,
                          fontSize: 12,
                        ),
                      );
                    }
                    // Show online status or last seen
                    if (widget.otherUserProfile.isOnline) {
                      return Text(
                        AppLocalizations.of(context)!.chatOnline,
                        style: const TextStyle(
                          color: AppColors.successGreen,
                          fontSize: 12,
                        ),
                      );
                    }
                    if (widget.otherUserProfile.lastSeen != null) {
                      return Text(
                        _formatLastSeen(widget.otherUserProfile.lastSeen!),
                        style: const TextStyle(
                          color: AppColors.textTertiary,
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
      ),
      actions: [
        // Replay the chat guide.
        Builder(
          builder: (btnContext) => IconButton(
            icon: const Icon(Icons.help_outline, color: AppColors.textSecondary),
            tooltip: AppLocalizations.of(context)!.tourReplayGuide,
            onPressed: () => TourController.instance.startMiniTourNow(
              btnContext,
              [
                TourKeys.chatBubbleHold,
                TourKeys.chatBubbleDoubleTap,
                TourKeys.chatLanguageMenu,
                TourKeys.chatSettings,
              ],
            ),
          ),
        ),
        // Languages & learning menu
        TourShowcase(
          showcaseKey: TourKeys.chatLanguageMenu,
          title: AppLocalizations.of(context)!.tourChatLanguageTitle,
          description: AppLocalizations.of(context)!.tourChatLanguageDesc,
          gesture: TourGesture.tap,
          targetShapeBorder: const CircleBorder(),
          child: IconButton(
            icon: const Icon(Icons.translate, color: AppColors.textSecondary),
            tooltip: AppLocalizations.of(context)!.chatLanguages,
            onPressed: _showToolsMenu,
          ),
        ),
        // Chat options menu (admin: delete, block, report)
        TourShowcase(
          showcaseKey: TourKeys.chatSettings,
          title: AppLocalizations.of(context)!.tourChatSettingsTitle,
          description: AppLocalizations.of(context)!.tourChatSettingsDesc,
          gesture: TourGesture.tap,
          targetShapeBorder: const CircleBorder(),
          child: IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
            onPressed: () => _showChatOptionsMenu(context),
          ),
        ),
      ],
    );
  }

  /// Show tools menu with language and learning features
  void _showToolsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.translate, color: AppColors.richGold),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.chatLanguages, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            _buildOptionItem(
              icon: Icons.language,
              label: '${AppLocalizations.of(context)!.chatYourLanguage} (${_targetLanguage.toUpperCase()})',
              color: AppColors.richGold,
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _showLanguagePicker();
              },
            ),
            _buildOptionItem(
              icon: Icons.tune,
              label: AppLocalizations.of(context)!.chatSettingsTitle,
              color: AppColors.textPrimary,
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _showChatSettings();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Show language picker for this chat
  void _showLanguagePicker() {
    const languages = [
      {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
      {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪'},
      {'code': 'es', 'name': 'Español', 'flag': '🇪🇸'},
      {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
      {'code': 'it', 'name': 'Italiano', 'flag': '🇮🇹'},
      {'code': 'pt', 'name': 'Português', 'flag': '🇵🇹'},
      {'code': 'pt_BR', 'name': 'Português (BR)', 'flag': '🇧🇷'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.chatYourLanguage,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context)!.chatLanguagePickerHint,
              style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 250,
              child: ListView.builder(
                itemCount: languages.length,
                itemBuilder: (context, index) {
                  final lang = languages[index];
                  final isSelected = _targetLanguage == lang['code'];
                  return ListTile(
                    leading: Text(lang['flag']!, style: const TextStyle(fontSize: 24)),
                    title: Text(
                      lang['name']!,
                      style: TextStyle(
                        color: isSelected ? AppColors.richGold : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: AppColors.richGold)
                        : null,
                    onTap: () async {
                      setState(() {
                        _chatTargetLanguage = lang['code'];
                        // Clear translation cache to re-translate with new language
                        _translatedMessages.clear();
                      });
                      // Persist chat language for this conversation
                      final prefs = await SharedPreferences.getInstance();
                      if (_chatTargetLanguage != null) {
                        await prefs.setString('chat_${widget.matchId}_language', _chatTargetLanguage!);
                      }
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppLocalizations.of(context)!.chatLanguageSetTo(lang['name']!)),
                          duration: const Duration(seconds: 1),
                          backgroundColor: AppColors.backgroundCard,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
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
            Text(
              AppLocalizations.of(context)!.chatOptions,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildOptionItem(
              icon: Icons.collections,
              label: AppLocalizations.of(context)?.grantAlbumAccess ?? 'Share my album',
              color: Colors.teal,
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _grantAlbumAccess(context);
              },
            ),
            _buildOptionItem(
              icon: Icons.lock_outline,
              label: AppLocalizations.of(context)?.revokeAccess ?? 'Revoke album access',
              color: AppColors.warningAmber,
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _revokeAlbumAccess(context);
              },
            ),
            if (_matchData != null) ...[
              const Divider(color: AppColors.divider, height: 1),
              _buildOptionItem(
                icon: Icons.info_outline,
                label: AppLocalizations.of(context)?.chatSeeExchangeDetails(widget.otherUserProfile.displayName) ?? 'See Exchange Details with ${widget.otherUserProfile.displayName}',
                color: AppColors.richGold,
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MatchDetailScreen(
                        match: _matchData!,
                        profile: widget.otherUserProfile,
                        currentUserId: widget.currentUserId,
                      ),
                    ),
                  );
                },
              ),
            ],
            const Divider(color: AppColors.divider, height: 1),
            _buildOptionItem(
              icon: _isConversationMuted
                  ? Icons.notifications_off_outlined
                  : Icons.notifications_active_outlined,
              label: _isConversationMuted
                  ? AppLocalizations.of(context)!.chatUnmuteNotifications
                  : AppLocalizations.of(context)!.chatMuteNotifications,
              color: _isConversationMuted ? AppColors.richGold : AppColors.textPrimary,
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _toggleConversationMute();
              },
            ),
            const Divider(color: AppColors.divider, height: 1),
            _buildOptionItem(
              icon: Icons.delete_outline,
              label: AppLocalizations.of(context)!.chatDeleteForMe,
              color: AppColors.textSecondary,
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _confirmDeleteChatForMe(context);
              },
            ),
            _buildOptionItem(
              icon: Icons.delete_forever,
              label: AppLocalizations.of(context)!.chatDeleteForBoth,
              color: Colors.orange,
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _confirmDeleteChatForBoth(context);
              },
            ),
            const Divider(color: AppColors.divider, height: 1),
            _buildOptionItem(
              icon: Icons.block,
              label: AppLocalizations.of(context)!.chatBlockUser(widget.otherUserProfile.displayName),
              color: AppColors.errorRed,
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _confirmBlockUser(context);
              },
            ),
            _buildOptionItem(
              icon: Icons.flag_outlined,
              label: AppLocalizations.of(context)!.chatReportUser(widget.otherUserProfile.displayName),
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

  /// Show chat learning settings panel
  void _showChatSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.tune, color: AppColors.richGold),
                  const SizedBox(width: 8),
                  Text(AppLocalizations.of(context)!.chatSettingsTitle, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!.chatSettingsSubtitle,
                style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
              ),
              const SizedBox(height: 16),
              _buildSettingToggle(
                setSheetState,
                icon: Icons.text_fields,
                label: AppLocalizations.of(context)!.chatSettingShowOriginal,
                subtitle: AppLocalizations.of(context)!.chatSettingShowOriginalDesc,
                value: _showOriginalText,
                onChanged: (v) => setState(() => _showOriginalText = v),
              ),
              _buildSettingToggle(
                setSheetState,
                icon: Icons.flag,
                label: AppLocalizations.of(context)!.chatSettingLanguageFlags,
                subtitle: AppLocalizations.of(context)!.chatSettingLanguageFlagsDesc,
                value: _showLanguageFlags,
                inactiveHint: AppLocalizations.of(context)!
                    .chatSettingLanguageFlagsHint,
                onChanged: (v) => setState(() => _showLanguageFlags = v),
              ),
              _buildSettingToggle(
                setSheetState,
                icon: Icons.lightbulb_outline,
                label: AppLocalizations.of(context)!.chatSettingCulturalTips,
                subtitle: AppLocalizations.of(context)!.chatSettingCulturalTipsDesc,
                value: _showCulturalTips,
                onChanged: (v) => setState(() => _showCulturalTips = v),
              ),
              _buildSettingToggle(
                setSheetState,
                icon: Icons.waving_hand_outlined,
                label: AppLocalizations.of(context)!.chatSettingIcebreakers,
                subtitle: AppLocalizations.of(context)!.chatSettingIcebreakersDesc,
                value: _showIcebreakers,
                onChanged: (v) => setState(() => _showIcebreakers = v),
              ),
              _buildSettingToggle(
                setSheetState,
                icon: Icons.format_quote_outlined,
                label: AppLocalizations.of(context)!.chatSettingSentences,
                subtitle: AppLocalizations.of(context)!.chatSettingSentencesDesc,
                value: _showSentences,
                onChanged: (v) => setState(() => _showSentences = v),
              ),
              _buildSettingToggle(
                setSheetState,
                icon: Icons.volume_up,
                label: AppLocalizations.of(context)!.chatSettingPronunciation,
                subtitle: AppLocalizations.of(context)!.chatSettingPronunciationDesc,
                value: _showPronunciation,
                onChanged: (v) => setState(() => _showPronunciation = v),
              ),
              _buildSettingToggle(
                setSheetState,
                icon: Icons.record_voice_over,
                label: AppLocalizations.of(context)!.chatSettingTtsTranslation,
                subtitle: AppLocalizations.of(context)!.chatSettingTtsTranslationDesc,
                value: _ttsReadTranslated,
                onChanged: (v) => setState(() => _ttsReadTranslated = v),
              ),
              if (AppConfig.showGamificationInExchanges)
              _buildSettingToggle(
                setSheetState,
                icon: Icons.local_fire_department,
                label: AppLocalizations.of(context)!.chatSettingXpBar,
                subtitle: AppLocalizations.of(context)!.chatSettingXpBarDesc,
                value: _showXpBar,
                inactiveHint: _sessionXp > 0
                    ? null
                    : AppLocalizations.of(context)!.chatSettingXpBarHint,
                onChanged: (v) => setState(() => _showXpBar = v),
              ),
              _buildSettingToggle(
                setSheetState,
                icon: Icons.today,
                label: AppLocalizations.of(context)!.chatSettingPhraseOfDay,
                subtitle: AppLocalizations.of(context)!.chatSettingPhraseOfDayDesc,
                value: _showPhraseOfDaySetting,
                onChanged: (v) => setState(() => _showPhraseOfDaySetting = v),
              ),
              const SizedBox(height: 16),
              // Save to this chat button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await _saveSettingsToThisChat();
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context)!.chatSettingsSavedThisChat)),
                      );
                    }
                  },
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: Text(AppLocalizations.of(context)!.chatSettingsSaveThisChat),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.richGold,
                    side: const BorderSide(color: AppColors.richGold),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Save to all chats button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await _saveSettingsToAllChats();
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context)!.chatSettingsSavedAllChats)),
                      );
                    }
                  },
                  icon: const Icon(Icons.save, size: 18),
                  label: Text(AppLocalizations.of(context)!.chatSettingsSaveAllChats),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.richGold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// Whether this account can use the tier-gated chat features.
  ///
  /// A profile with no membershipTier field at all reads as free, which is the
  /// case for more than half of the accounts in production.
  bool get _hasPaidTier {
    final tier = _currentUserProfile?.effectiveTier ?? MembershipTier.free;
    return tier != MembershipTier.free;
  }

  Widget _buildSettingToggle(
    StateSetter setSheetState, {
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool locked = false,
    String? inactiveHint,
  }) {
    final l10n = AppLocalizations.of(context)!;
    // Some settings are on but have nothing to render yet because their data
    // does not exist — no XP earned, no translated message. Saying so beats
    // leaving the user to conclude the switch is broken.
    final showHint = !locked && value && inactiveHint != null;
    // A locked row keeps its place in the list but says why it is inert and
    // offers the way out, rather than presenting a switch that silently does
    // nothing.
    final effectiveSubtitle = locked ? l10n.chatSettingSilverPlusOnly : subtitle;
    final tint = locked
        ? AppColors.textTertiary
        : (value ? AppColors.richGold : AppColors.textTertiary);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 20, color: tint),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: locked
                            ? AppColors.textTertiary
                            : AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
                Text(effectiveSubtitle,
                    style: const TextStyle(
                        color: AppColors.textTertiary, fontSize: 11)),
                if (showHint)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(inactiveHint,
                        style: const TextStyle(
                            color: AppColors.warningAmber, fontSize: 11)),
                  ),
              ],
            ),
          ),
          if (locked)
            TextButton.icon(
              onPressed: _openMembership,
              icon: const Icon(Icons.lock_outline,
                  size: 16, color: AppColors.richGold),
              label: Text(l10n.upgrade,
                  style: const TextStyle(
                      color: AppColors.richGold, fontSize: 12)),
            )
          else
            Switch(
              value: value,
              onChanged: (v) {
                setSheetState(() {});
                onChanged(v);
              },
              activeThumbColor: AppColors.richGold,
              inactiveTrackColor: AppColors.backgroundDark,
            ),
        ],
      ),
    );
  }

  /// Close the settings sheet and open the membership screen.
  void _openMembership() {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MembershipScreen(currentUserId: widget.currentUserId),
      ),
    );
  }

  void _trackMessageXp(String content) {
    final words = content.toLowerCase().split(RegExp(r'\s+')).where((w) => w.length > 1).toSet();
    final xpEarned = 5 + (words.length * 2); // Base 5 XP + 2 per word
    setState(() {
      _sessionXp += xpEarned;
      _uniqueWordsUsed += words.length;
      _chatStreak++;
    });

    // Persist XP to Firebase so it reflects on leaderboard
    _persistMessageXp(widget.currentUserId, xpEarned);
  }

  /// Submit message XP to Firestore user_levels (fire-and-forget)
  Future<void> _persistMessageXp(String userId, int xp) async {
    try {
      final userLevelRef = FirebaseFirestore.instance
          .collection('user_levels')
          .doc(userId);
      // Transaction so the weekly leaderboard fields (weekKey/weeklyXP) move
      // atomically with totalXP.
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final doc = await tx.get(userLevelRef);
        if (!doc.exists) return;
        tx.update(userLevelRef, {
          'currentXP': FieldValue.increment(xp),
          'totalXP': FieldValue.increment(xp),
          ...weeklyXpFields(doc.data(), xp),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      });
      // Log XP transaction
      await FirebaseFirestore.instance.collection('xp_transactions').add({
        'userId': userId,
        'actionType': 'message_sent',
        'xpAmount': xp,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('XP persist error: $e');
    }
  }

  Widget _buildXpBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: AppColors.backgroundCard,
      child: Row(
        children: [
          const Icon(Icons.local_fire_department, size: 16, color: Colors.orange),
          const SizedBox(width: 4),
          Text(
            AppLocalizations.of(context)!.chatStreak(_chatStreak),
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.star, size: 14, color: AppColors.richGold),
          const SizedBox(width: 4),
          Text(
            AppLocalizations.of(context)!.chatSessionXp(_sessionXp),
            style: const TextStyle(color: AppColors.richGold, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.abc, size: 14, color: AppColors.textTertiary),
          const SizedBox(width: 4),
          Text(
            AppLocalizations.of(context)!.chatWords(_uniqueWordsUsed),
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
          ),
          const Spacer(),
          // Small XP progress bar
          SizedBox(
            width: 60,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_sessionXp % 100) / 100,
                backgroundColor: AppColors.backgroundDark,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.richGold),
                minHeight: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openIdeas({required bool sentences}) {
    final mine = _userLanguage ?? Localizations.localeOf(context).languageCode;
    ChatIdeasSheet.show(
      context,
      sentences: sentences,
      partnerLanguage: _targetLanguage ?? mine,
      myLanguage: mine,
      onPick: (text) => _messageController.text = text,
    );
  }

  /// Three random offline ice-breakers under "Say hi" in an empty chat.
  Widget _buildEmptyChatIcebreakers() {
    final datasets = ChatDatasets.instance;
    return FutureBuilder<void>(
      future: datasets.ensure('icebreakers'),
      builder: (context, _) {
        final picks = ChatIdeasSheet.randomIcebreakers(3, seed: _headerName.hashCode);
        if (picks.isEmpty) return const SizedBox.shrink();
        final mine = _userLanguage ?? Localizations.localeOf(context).languageCode;
        final theirs = _targetLanguage ?? mine;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              for (final p in picks)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ActionChip(
                    avatar: const Icon(Icons.lightbulb_outline, size: 16, color: AppColors.richGold),
                    label: Text(p.text.of(theirs), maxLines: 2, overflow: TextOverflow.ellipsis),
                    onPressed: () => _messageController.text = p.text.of(theirs),
                  ),
                ),
              TextButton(
                onPressed: () => _openIdeas(sentences: false),
                child: Text(AppLocalizations.of(context)!.chatSuggestionsTooltip),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Phrase of the day: one of the 3,000 verified quotes of the offline
  /// dataset (same quote for everyone on a given day), shown in the chat
  /// partner's language with the user's own language underneath.
  Future<void> _loadPhraseOfTheDay() async {
    final datasets = ChatDatasets.instance;
    await datasets.ensure('quotes');
    final quote = datasets.quoteOfDay(DateTime.now());
    if (quote == null || !mounted) return;
    final mine = _userLanguage ?? Localizations.localeOf(context).languageCode;
    final theirs = _targetLanguage ?? mine;
    final inTheirs = quote.text.of(theirs);
    final inMine = quote.text.of(mine);
    setState(() {
      _phraseOfTheDay = inTheirs;
      _phraseTranslation = inMine == inTheirs ? null : inMine;
      _phraseAuthor = quote.author;
    });
  }

  Widget _buildPhraseOfDay() {
    if (_phraseOfTheDay == null || !_showPhraseOfDay) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: AppColors.backgroundDark,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.format_quote, size: 16, color: AppColors.richGold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              // Practise it: the partner-language text goes into the input.
              onTap: () => _messageController.text = _phraseOfTheDay!,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _phraseOfTheDay!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.richGold, fontSize: 12, fontWeight: FontWeight.w500, height: 1.3),
                  ),
                  if (_phraseTranslation != null)
                    Text(
                      _phraseTranslation!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.textTertiary, fontSize: 11, fontStyle: FontStyle.italic, height: 1.3),
                    ),
                  if (_phraseAuthor != null && _phraseAuthor!.isNotEmpty)
                    Text(
                      l10n.chatQuoteAuthor(_phraseAuthor!),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                    ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _showPhraseOfDay = false),
            child: const Icon(Icons.close, size: 14, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Future<void> _showPronunciationChallenge() async {
    final state = _chatBloc.state;
    if (state is! ChatLoaded) return;

    final receivedMessages = state.messages
        .where((m) => m.senderId != widget.currentUserId && m.type == MessageType.text)
        .take(3)
        .toList();

    if (receivedMessages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.chatNoMessagesToPractice), backgroundColor: AppColors.backgroundCard),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.mic, color: AppColors.richGold),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.chatPronunciationChallenge, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Text(AppLocalizations.of(context)!.chatPronunciationHint, style: const TextStyle(color: AppColors.textTertiary, fontSize: 13)),
            const SizedBox(height: 12),
            ...receivedMessages.map((msg) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () async {
                  if (!await AiConsentGate.ensure(ctx)) return;
                  final lang = msg.detectedLanguage ?? msg.metadata?['language'] ?? 'en';
                  final source = await PronunciationService()
                      .getPronunciationSource(msg.content, lang);
                  if (source != null) {
                    final player = AudioPlayer();
                    await player.play(source);
                    player.onPlayerComplete.first.then((_) => player.dispose());
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.volume_up, color: AppColors.richGold, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          msg.content,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )),
            const SizedBox(height: 8),
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
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(
          l10n.chatDeleteChat,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          l10n.chatDeleteChatForMeMessage,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.delete, style: const TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final bloc = _chatBloc;
      final nav = Navigator.of(this.context);
      // Run delete operation FIRST, then show success dialog
      bloc.add(const ChatDeletedForMe());
      await ActionSuccessDialog.showChatDeletedForMe(this.context, onDismiss: () {
        nav.popUntil((route) => route.isFirst);
      });
    }
  }

  /// Confirm delete chat for both users
  Future<void> _confirmDeleteChatForBoth(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(
          AppLocalizations.of(context)!.chatDeleteChatForEveryone,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          AppLocalizations.of(context)!.chatDeleteChatForBothMessage(widget.otherUserProfile.displayName),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(AppLocalizations.of(context)!.chatDeleteForEveryone, style: const TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final bloc = _chatBloc;
      final nav = Navigator.of(this.context);
      // Run delete operation FIRST, then show success dialog
      bloc.add(const ChatDeletedForBoth());
      await ActionSuccessDialog.showChatDeletedForBoth(this.context, onDismiss: () {
        nav.popUntil((route) => route.isFirst);
      });
    }
  }

  /// Confirm block user
  Future<void> _confirmBlockUser(BuildContext context) async {
    // Check if the other user is an admin - cannot block admin
    if (widget.otherUserProfile.isAdmin) {
      showUserErrorMessage(context, AppLocalizations.of(context)!.chatCannotBlockAdmin);
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(
          l10n.chatBlockUserTitle,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          l10n.chatBlockUserMessage(widget.otherUserProfile.displayName),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.chatBlock, style: const TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final bloc = _chatBloc;
      final nav = Navigator.of(this.context);
      await ActionSuccessDialog.showUserBlocked(this.context, widget.otherUserProfile.displayName, onDismiss: () {
        bloc.add(ChatUserBlocked(widget.otherUserId));
        nav.popUntil((route) => route.isFirst);
      });
    }
  }

  /// Show report user dialog
  Future<void> _showReportUserDialog(BuildContext context) async {
    // Check if the other user is an admin - cannot report admin
    if (widget.otherUserProfile.isAdmin) {
      showUserErrorMessage(context, AppLocalizations.of(context)!.chatCannotReportAdmin);
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    // One shared reason list on every report surface (report_reasons.dart).
    final selectedReason = await showReportReasonDialog(
      context,
      title: l10n.chatReportUserTitle,
      prompt: l10n.chatWhyReportUser(widget.otherUserProfile.displayName),
    );

    if (selectedReason != null && mounted) {
      final bloc = _chatBloc;
      final nav = Navigator.of(this.context);
      await ActionSuccessDialog.showUserReported(this.context, onDismiss: () {
        bloc.add(ChatUserReported(
          userId: widget.otherUserId,
          reason: selectedReason.code,
        ));
        nav.popUntil((route) => route.isFirst);
      });
    }
  }

  /// Star a message
  void _starMessage(BuildContext context, Message message, bool isStarred) {
    _chatBloc.add(ChatMessageStarred(
      messageId: message.messageId,
      isStarred: isStarred,
    ));
  }

  /// Toggle an emoji reaction on a message. Reacting with the emoji the current
  /// user already picked removes it. Returns true if the Firestore write
  /// succeeded (the bubble reverts its optimistic state on false).
  ///
  /// IMPORTANT: reactions live under `conversations/{message.conversationId}`,
  /// NOT `conversations/{matchId}` — the conversation doc id is an auto-id
  /// resolved from the match, so using matchId here wrote to a non-existent doc
  /// and silently failed. Use the message's own conversationId.
  Future<bool> _reactToMessage(Message message, String emoji) async {
    final conversationId = message.conversationId.isNotEmpty
        ? message.conversationId
        : widget.matchId;
    final current = message.getReaction(widget.currentUserId);
    try {
      if (current == emoji) {
        await _chatDataSource.removeReaction(
          messageId: message.messageId,
          conversationId: conversationId,
          userId: widget.currentUserId,
        );
      } else {
        await _chatDataSource.addReaction(
          messageId: message.messageId,
          conversationId: conversationId,
          userId: widget.currentUserId,
          emoji: emoji,
        );
      }
      return true;
    } catch (e) {
      debugPrint('[Chat] Reaction toggle failed: $e');
      return false;
    }
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

  /// Clear selected media
  void _clearSelectedMedia() {
    setState(() {
      _selectedImageXFile = null;
      _selectedVideoXFile = null;
    });
  }

  /// Build media preview widget inside input container
  Widget _buildMediaPreview() {
    // Album photos preview
    if (_selectedAlbumPhotos.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.photo_library, color: AppColors.richGold, size: 16),
                const SizedBox(width: 6),
                Text(
                  AppLocalizations.of(context)!.chatAlbumPhotosSelected(_selectedAlbumPhotos.length),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAlbumPhotos = [];
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.errorRed,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedAlbumPhotos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: _selectedAlbumPhotos[index],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      memCacheWidth: 160,
                      errorWidget: (_, __, ___) => Container(
                        width: 80,
                        height: 80,
                        color: AppColors.backgroundDark,
                        child: const Icon(Icons.broken_image, color: AppColors.textTertiary, size: 24),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    if (_selectedImageXFile == null && _selectedVideoXFile == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _selectedImageXFile != null
                ? Image(
                    image: WebMedia.imageProviderFor(_selectedImageXFile!),
                    height: 120,
                    width: 120,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: 120,
                    width: 120,
                    color: AppColors.backgroundDark,
                    child: const Center(
                      child: Icon(
                        Icons.videocam,
                        color: AppColors.textTertiary,
                        size: 48,
                      ),
                    ),
                  ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: _clearSelectedMedia,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.errorRed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show forward dialog to select recipients
  Future<void> _showForwardDialog(BuildContext context, Message message) async {
    // Get the conversation ID from the bloc state
    final state = _chatBloc.state;
    String? conversationId;
    if (state is ChatLoaded) {
      conversationId = state.conversation.conversationId;
    }

    if (conversationId == null) {
      showUserErrorMessage(context, AppLocalizations.of(context)!.chatUnableToForward);
      return;
    }

    await ForwardMessageSheet.show(
      context,
      message: message,
      currentUserId: widget.currentUserId,
      fromConversationId: conversationId,
    );
  }

  /// Build reply preview widget
  Widget _buildReplyPreview() {
    if (_replyingToMessage == null) return const SizedBox.shrink();

    final replyContent = _replyingToMessage!.content;
    final isCurrentUserMessage = _replyingToMessage!.senderId == widget.currentUserId;
    final senderName = isCurrentUserMessage ? AppLocalizations.of(context)!.chatYou : widget.otherUserProfile.displayName;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
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
                  AppLocalizations.of(context)!.chatReplyingTo(senderName),
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

  /// Replying needs a Base membership (or an active paid tier / TEST — see
  /// [Profile.isBaseMembershipActive]). While the own profile is still
  /// loading the composer stays available; the send path re-checks.
  bool get _canReply =>
      _buyerChat ||
      _currentUserProfile == null ||
      _currentUserProfile!.isBaseMembershipActive ||
      _currentUserProfile!.effectiveTier == MembershipTier.test;

  /// Shown instead of the composer to users without Base: they can read the
  /// conversation; replying opens the membership screen.
  Widget _buildReplyLockedBar(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      key: const ValueKey('chat-reply-locked'),
      decoration: const BoxDecoration(
        color: AppColors.backgroundCard,
        border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              const Icon(Icons.lock_outline, color: AppColors.richGold, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l.chatReplyNeedsBase,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                key: const ValueKey('chat-reply-get-base'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.deepBlack,
                  backgroundColor: AppColors.richGold,
                  minimumSize: const Size(44, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  await Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => MembershipScreen(currentUserId: widget.currentUserId),
                  ));
                  // Bought it? Reload so the composer appears right away.
                  if (mounted) await _fetchCurrentUserName(forceServer: true);
                  if (mounted) setState(() {});
                },
                child: Text(l.participationBaseRequiredCta,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Places named in the chat (message metadata, offline), rebuilt when the
  /// messages or the keyword dataset change.
  Widget _placesBuilder(
      Widget Function(List<ChatPlace> places, List<ChatPlace> partnerPlaces) build) {
    return ValueListenableBuilder<int>(
      // Old messages without stored entities match once the keywords load.
      valueListenable: ChatDatasets.instance.changes,
      builder: (context, _, __) => BlocBuilder<ChatBloc, ChatState>(
        buildWhen: (a, b) => b is ChatLoaded,
        builder: (context, state) {
          if (state is! ChatLoaded) return const SizedBox.shrink();
          final sources = [
            for (final m in state.messages)
              if (m.type == MessageType.text)
                (
                  id: m.messageId,
                  text: m.content,
                  metadata: m.metadata,
                  sentAt: m.sentAt,
                  fromPartner: m.senderId != widget.currentUserId,
                ),
          ];
          final places = ChatPlaces.collect(sources);
          return build(places, ChatPlaces.latestFromPartner(places, sources));
        },
      ),
    );
  }

  /// Questions about the place the other person just named.
  Widget _buildPlacesBar() => _placesBuilder((places, partnerPlaces) => ChatPlacesBar(
        places: places,
        partnerPlaces: partnerPlaces,
        onInsert: (text) {
          _messageController.text = text;
          _messageController.selection = TextSelection.collapsed(offset: text.length);
        },
      ));

  /// A wrongly detected place (false positive): removed from the entities of
  /// every loaded message that names it, for both people. An empty list is
  /// kept (not deleted) so the text is not matched again on the fly.
  Future<void> _removePlace(ChatPlace place) async {
    final st = _chatBloc.state;
    if (st is! ChatLoaded) return;
    final conversationId = st.conversation.conversationId;
    final kw = ChatDatasets.instance.keywords;
    final batch = FirebaseFirestore.instance.batch();
    var n = 0;
    for (final m in st.messages) {
      if (m.type != MessageType.text) continue;
      final matches = MessageInsights.storedEntities(m.metadata, m.content) ?? kw?.match(m.content) ?? const [];
      final kept = [
        for (final k in matches)
          if (k.refs.isNotEmpty && '${k.kind.code}:${k.refs.first}' != place.key) k,
      ];
      if (kept.length == matches.length) continue;
      batch.update(
        FirebaseFirestore.instance
            .collection('conversations')
            .doc(conversationId)
            .collection('messages')
            .doc(m.messageId),
        {'metadata.entities': [for (final k in kept) k.toJson()]},
      );
      n++;
    }
    if (n > 0) await batch.commit();
  }

  /// Ice-breakers, sentences and cultural tips all off: no tools line, the
  /// attachment + goes left of the message field.
  bool get _attachInline => !_showIcebreakers && !_showSentences && !_showCulturalTips;

  /// One of the evenly spaced chat tools (same look as [ChatPlacesButton]).
  Widget _toolButton({
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

  Widget _buildInputField(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundCard,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Media preview INSIDE input container
            _buildMediaPreview(),
            // Tools, one line, evenly spaced: attach, ice-breakers, suggested
            // sentences, places (list + map). With all three ideas tools off,
            // there is no line: + sits left of the message field instead.
            if (!_attachInline)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
              child: Row(
                key: const ValueKey('chat-tools-row'),
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _toolButton(
                    key: const ValueKey('chat-tool-attach'),
                    icon: Icons.add_circle_outline,
                    tooltip: AppLocalizations.of(context)!.chatSendAttachment,
                    onPressed: () => _showAttachmentOptions(context),
                  ),
                  if (_showIcebreakers)
                  _toolButton(
                    key: const ValueKey('chat-tool-icebreakers'),
                    icon: Icons.waving_hand_outlined,
                    tooltip: AppLocalizations.of(context)!.chatIcebreakersTitle,
                    onPressed: () => _openIdeas(sentences: false),
                  ),
                  if (_showSentences)
                  _toolButton(
                    key: const ValueKey('chat-tool-sentences'),
                    icon: Icons.format_quote_outlined,
                    tooltip: AppLocalizations.of(context)!.chatSuggestionsTitle,
                    onPressed: () => _openIdeas(sentences: true),
                  ),
                  if (_showCulturalTips)
                    _placesBuilder((places, _) => ChatPlacesButton(places: places, onRemove: _removePlace)),
                ],
              ),
            ),
            // Input row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  if (_attachInline)
                    _toolButton(
                      key: const ValueKey('chat-tool-attach'),
                      icon: Icons.add_circle_outline,
                      tooltip: AppLocalizations.of(context)!.chatSendAttachment,
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
                        hintText: AppLocalizations.of(context)!.typeMessage,
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
                      maxLength: 200,
                      buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                        if (!isFocused && currentLength == 0) return null;
                        return Text(
                          '$currentLength/$maxLength',
                          style: TextStyle(
                            color: currentLength >= maxLength! ? Colors.red : AppColors.textTertiary,
                            fontSize: 12,
                          ),
                        );
                      },
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Send / voice-record button
                  BlocBuilder<ChatBloc, ChatState>(
                    builder: (context, state) {
                      final isSending = state is ChatSending;

                      return VoiceRecordSendButton(
                        controller: _messageController,
                        isSending: isSending,
                        buttonColor: AppColors.richGold,
                        iconColor: AppColors.deepBlack,
                        onSendText: () => _sendMessage(this.context),
                        onSendVoice: _sendVoiceMessage,
                      );
                    },
                  ),
                ],
              ),
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
