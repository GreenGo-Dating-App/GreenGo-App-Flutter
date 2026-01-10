import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// Agora SDK disabled for development
// import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../../domain/entities/video_call.dart';
import '../../domain/services/translation_service.dart';
import '../bloc/video_call_bloc.dart';
import '../bloc/video_call_event.dart';
import '../bloc/video_call_state.dart';
import '../widgets/call_controls.dart';
import '../widgets/call_timer.dart';
import '../widgets/connection_quality_indicator.dart';
import '../widgets/subtitle_overlay.dart';

/// Main Video Call Screen
class VideoCallScreen extends StatefulWidget {
  final String callId;
  final String currentUserId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhotoUrl;
  final bool isIncoming;
  final String? currentUserLanguage;
  final String? otherUserLanguage;

  const VideoCallScreen({
    super.key,
    required this.callId,
    required this.currentUserId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhotoUrl,
    this.isIncoming = false,
    this.currentUserLanguage,
    this.otherUserLanguage,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  late TranslationService _translationService;
  bool _translationEnabled = true;
  String _myLanguage = 'en';
  String _theirLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _translationService = TranslationService();
    _myLanguage = widget.currentUserLanguage ?? 'en';
    _theirLanguage = widget.otherUserLanguage ?? 'en';
    _initializeTranslation();
  }

  Future<void> _initializeTranslation() async {
    await _translationService.initialize();
    // Set languages: listen for their speech, translate to my language
    _translationService.setLanguages(
      source: _theirLanguage,
      target: _myLanguage,
    );
  }

  @override
  void dispose() {
    _translationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VideoCallBloc, VideoCallState>(
      listener: (context, state) {
        if (state is VideoCallEnded ||
            state is VideoCallDeclined ||
            state is VideoCallFailure) {
          // Navigate back or show end call screen
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: _buildContent(context, state),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, VideoCallState state) {
    if (state is VideoCallRinging) {
      return _buildIncomingCallUI(context, state);
    } else if (state is VideoCallOutgoing) {
      return _buildOutgoingCallUI(context, state);
    } else if (state is VideoCallConnecting) {
      return _buildConnectingUI(context, state);
    } else if (state is VideoCallActive) {
      return _buildActiveCallUI(context, state);
    } else if (state is VideoCallFailure) {
      return _buildErrorUI(context, state);
    }

    return const Center(
      child: CircularProgressIndicator(color: Colors.white),
    );
  }

  /// Incoming call UI
  Widget _buildIncomingCallUI(BuildContext context, VideoCallRinging state) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.green.shade900,
            Colors.black,
          ],
        ),
      ),
      child: Column(
        children: [
          const Spacer(),
          // Caller info
          CircleAvatar(
            radius: 60,
            backgroundImage: state.callerPhotoUrl != null
                ? NetworkImage(state.callerPhotoUrl!)
                : null,
            child: state.callerPhotoUrl == null
                ? Text(
                    state.callerName.isNotEmpty
                        ? state.callerName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontSize: 48),
                  )
                : null,
          ),
          const SizedBox(height: 24),
          Text(
            state.callerName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Incoming Video Call...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          // Accept/Decline buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Decline button
                _buildCircleButton(
                  onPressed: () {
                    context.read<VideoCallBloc>().add(VideoCallDecline(
                          callId: state.call.callId,
                          userId: widget.currentUserId,
                        ));
                  },
                  icon: Icons.call_end,
                  color: Colors.red,
                  label: 'Decline',
                ),
                // Accept button
                _buildCircleButton(
                  onPressed: () {
                    context.read<VideoCallBloc>().add(VideoCallAnswer(
                          callId: state.call.callId,
                          userId: widget.currentUserId,
                        ));
                  },
                  icon: Icons.videocam,
                  color: Colors.green,
                  label: 'Accept',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Outgoing call UI
  Widget _buildOutgoingCallUI(BuildContext context, VideoCallOutgoing state) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade900,
            Colors.black,
          ],
        ),
      ),
      child: Column(
        children: [
          const Spacer(),
          // Receiver info
          CircleAvatar(
            radius: 60,
            backgroundImage: state.receiverPhotoUrl != null
                ? NetworkImage(state.receiverPhotoUrl!)
                : null,
            child: state.receiverPhotoUrl == null
                ? Text(
                    state.receiverName.isNotEmpty
                        ? state.receiverName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontSize: 48),
                  )
                : null,
          ),
          const SizedBox(height: 24),
          Text(
            state.receiverName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Calling...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white54,
            ),
          ),
          const Spacer(),
          // End call button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
            child: _buildCircleButton(
              onPressed: () {
                context.read<VideoCallBloc>().add(VideoCallEnd(
                      callId: state.call.callId,
                      userId: widget.currentUserId,
                    ));
              },
              icon: Icons.call_end,
              color: Colors.red,
              label: 'Cancel',
            ),
          ),
        ],
      ),
    );
  }

  /// Connecting UI
  Widget _buildConnectingUI(BuildContext context, VideoCallConnecting state) {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 24),
            Text(
              'Connecting...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Active call UI with video
  Widget _buildActiveCallUI(BuildContext context, VideoCallActive state) {
    final bloc = context.read<VideoCallBloc>();
    final engine = bloc.engine;

    // Start translation listening when call becomes active
    if (state.remoteUid != null && _translationEnabled) {
      _translationService.startListening();
    }

    return Stack(
      children: [
        // Remote video (full screen) - Agora disabled for development
        if (state.remoteUid != null && engine != null)
          // Placeholder for AgoraVideoView when SDK is disabled
          Container(
            color: Colors.grey.shade800,
            child: const Center(
              child: Text(
                'Video (Agora SDK disabled)',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          )
        else
          Container(
            color: Colors.grey.shade900,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: widget.otherUserPhotoUrl != null
                        ? NetworkImage(widget.otherUserPhotoUrl!)
                        : null,
                    child: widget.otherUserPhotoUrl == null
                        ? Text(
                            widget.otherUserName.isNotEmpty
                                ? widget.otherUserName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(fontSize: 36),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.otherUserName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Waiting for video...',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Subtitle overlay for real-time translation
        SubtitleOverlay(
          translationService: _translationService,
          showOriginal: true,
        ),

        // Local video (picture-in-picture) - Agora disabled for development
        if (engine != null && !state.isVideoMuted)
          Positioned(
            top: 48,
            right: 16,
            child: Container(
              width: 120,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.grey.shade700,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white30, width: 2),
              ),
              clipBehavior: Clip.antiAlias,
              child: const Center(
                child: Icon(
                  Icons.videocam_off,
                  color: Colors.white54,
                  size: 32,
                ),
              ),
            ),
          ),

        // Top bar with call info
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black54,
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              children: [
                // Back button
                IconButton(
                  onPressed: () {
                    // Minimize to PiP or go back
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const Spacer(),
                // Translation toggle button
                TranslationToggleButton(
                  translationService: _translationService,
                  onTap: () {
                    setState(() {
                      _translationEnabled = _translationService.isEnabled;
                    });
                  },
                ),
                const SizedBox(width: 12),
                // Call timer
                CallTimer(duration: state.callDuration),
                const SizedBox(width: 16),
                // Connection quality
                ConnectionQualityIndicator(quality: state.connectionQuality),
              ],
            ),
          ),
        ),

        // Language selector (shown when translation is enabled)
        if (_translationEnabled)
          Positioned(
            top: 70,
            left: 16,
            child: GestureDetector(
              onTap: () => _showLanguageSettings(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.translate, color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '${SupportedLanguages.getLanguageName(_theirLanguage)} → ${SupportedLanguages.getLanguageName(_myLanguage)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.edit, color: Colors.white54, size: 12),
                  ],
                ),
              ),
            ),
          ),

        // Bottom controls
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: CallControls(
            isAudioMuted: state.isAudioMuted,
            isVideoMuted: state.isVideoMuted,
            isSpeakerOn: state.isSpeakerOn,
            isFrontCamera: state.isFrontCamera,
            onToggleAudio: () {
              context.read<VideoCallBloc>().add(const VideoCallToggleAudio());
            },
            onToggleVideo: () {
              context.read<VideoCallBloc>().add(const VideoCallToggleVideo());
            },
            onSwitchCamera: () {
              context.read<VideoCallBloc>().add(const VideoCallSwitchCamera());
            },
            onToggleSpeaker: () {
              context.read<VideoCallBloc>().add(const VideoCallToggleSpeaker());
            },
            onEndCall: () {
              _translationService.stopListening();
              context.read<VideoCallBloc>().add(VideoCallEnd(
                    callId: state.call.callId,
                    userId: widget.currentUserId,
                  ));
            },
          ),
        ),
      ],
    );
  }

  /// Show language settings dialog
  void _showLanguageSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Translation Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Set the languages for real-time translation',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              // Their language (source)
              _buildLanguageDropdown(
                label: 'They speak',
                value: _theirLanguage,
                onChanged: (value) {
                  setModalState(() {
                    _theirLanguage = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              // My language (target)
              _buildLanguageDropdown(
                label: 'Translate to',
                value: _myLanguage,
                onChanged: (value) {
                  setModalState(() {
                    _myLanguage = value!;
                  });
                },
              ),
              const SizedBox(height: 24),
              // Apply button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _translationService.setLanguages(
                        source: _theirLanguage,
                        target: _myLanguage,
                      );
                    });
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Apply',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageDropdown({
    required String label,
    required String value,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            dropdownColor: Colors.grey[800],
            underline: const SizedBox(),
            style: const TextStyle(color: Colors.white, fontSize: 16),
            items: SupportedLanguages.getAllLanguages()
                .map((e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  /// Error UI
  Widget _buildErrorUI(BuildContext context, VideoCallFailure state) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              state.message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required VoidCallback onPressed,
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon, color: Colors.white, size: 32),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
