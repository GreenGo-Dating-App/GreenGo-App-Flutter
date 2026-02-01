import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/video_call.dart';

/// Video Call Screen - In-app video dating
class VideoCallScreen extends StatefulWidget {
  final VideoCall call;
  final bool isIncoming;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onEnd;
  final VoidCallback? onToggleVideo;
  final VoidCallback? onToggleAudio;
  final VoidCallback? onSwitchCamera;

  const VideoCallScreen({
    super.key,
    required this.call,
    this.isIncoming = false,
    this.onAccept,
    this.onDecline,
    this.onEnd,
    this.onToggleVideo,
    this.onToggleAudio,
    this.onSwitchCamera,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _callTimer;
  Duration _callDuration = Duration.zero;
  bool _isVideoEnabled = true;
  bool _isAudioEnabled = true;
  bool _isFrontCamera = true;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    if (widget.call.status == VideoCallStatus.connected) {
      _startCallTimer();
    }
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _callDuration = Duration(seconds: timer.tick);
      });
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _callTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          setState(() {
            _showControls = !_showControls;
          });
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Remote Video (Full Screen)
            _buildRemoteVideo(),

            // Local Video (Picture-in-Picture)
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              right: 20,
              child: _buildLocalVideo(),
            ),

            // Call Status/Duration
            if (_showControls)
              Positioned(
                top: MediaQuery.of(context).padding.top + 20,
                left: 20,
                child: _buildCallInfo(),
              ),

            // Incoming Call UI
            if (widget.isIncoming && widget.call.status == VideoCallStatus.ringing)
              _buildIncomingCallUI(),

            // Calling UI
            if (!widget.isIncoming && widget.call.status == VideoCallStatus.ringing)
              _buildCallingUI(),

            // Controls
            if (_showControls && widget.call.status == VideoCallStatus.connected)
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: _buildControls(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemoteVideo() {
    // Placeholder for actual video stream
    return Container(
      color: AppColors.backgroundDark,
      child: Center(
        child: widget.call.status == VideoCallStatus.connected
            ? const Icon(
                Icons.videocam,
                color: AppColors.textTertiary,
                size: 80,
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: widget.isIncoming
                        ? (widget.call.callerPhotoUrl != null
                            ? NetworkImage(widget.call.callerPhotoUrl!)
                            : null)
                        : (widget.call.receiverPhotoUrl != null
                            ? NetworkImage(widget.call.receiverPhotoUrl!)
                            : null),
                    backgroundColor: AppColors.backgroundCard,
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.isIncoming
                        ? widget.call.callerName
                        : widget.call.receiverName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLocalVideo() {
    return GestureDetector(
      onTap: () {
        widget.onSwitchCamera?.call();
        setState(() {
          _isFrontCamera = !_isFrontCamera;
        });
      },
      child: Container(
        width: 100,
        height: 140,
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: _isVideoEnabled
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    // Placeholder for local video stream
                    Container(
                      color: AppColors.backgroundDark,
                      child: const Icon(
                        Icons.face,
                        color: AppColors.textTertiary,
                        size: 40,
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Icon(
                        _isFrontCamera ? Icons.camera_front : Icons.camera_rear,
                        color: Colors.white.withOpacity(0.7),
                        size: 16,
                      ),
                    ),
                  ],
                )
              : Container(
                  color: AppColors.backgroundDark,
                  child: const Icon(
                    Icons.videocam_off,
                    color: AppColors.textTertiary,
                    size: 40,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildCallInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.call.status == VideoCallStatus.connected) ...[
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatDuration(_callDuration),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ] else
            Text(
              widget.call.status == VideoCallStatus.connecting
                  ? 'Connecting...'
                  : 'Calling...',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIncomingCallUI() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1 + (_pulseController.value * 0.1),
                child: CircleAvatar(
                  radius: 70,
                  backgroundImage: widget.call.callerPhotoUrl != null
                      ? NetworkImage(widget.call.callerPhotoUrl!)
                      : null,
                  backgroundColor: AppColors.backgroundCard,
                  child: widget.call.callerPhotoUrl == null
                      ? const Icon(Icons.person, size: 70, color: AppColors.textTertiary)
                      : null,
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            widget.call.callerName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Incoming Video Call',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 60),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Decline Button
              GestureDetector(
                onTap: widget.onDecline,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.call_end,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: 60),
              // Accept Button
              GestureDetector(
                onTap: widget.onAccept,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.videocam,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCallingUI() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1 + (_pulseController.value * 0.1),
                child: CircleAvatar(
                  radius: 70,
                  backgroundImage: widget.call.receiverPhotoUrl != null
                      ? NetworkImage(widget.call.receiverPhotoUrl!)
                      : null,
                  backgroundColor: AppColors.backgroundCard,
                  child: widget.call.receiverPhotoUrl == null
                      ? const Icon(Icons.person, size: 70, color: AppColors.textTertiary)
                      : null,
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            widget.call.receiverName,
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
          const SizedBox(height: 60),
          GestureDetector(
            onTap: widget.onEnd,
            child: Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.call_end,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Mute Audio
        _buildControlButton(
          icon: _isAudioEnabled ? Icons.mic : Icons.mic_off,
          isActive: _isAudioEnabled,
          onTap: () {
            widget.onToggleAudio?.call();
            setState(() {
              _isAudioEnabled = !_isAudioEnabled;
            });
          },
        ),
        const SizedBox(width: 20),
        // Toggle Video
        _buildControlButton(
          icon: _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
          isActive: _isVideoEnabled,
          onTap: () {
            widget.onToggleVideo?.call();
            setState(() {
              _isVideoEnabled = !_isVideoEnabled;
            });
          },
        ),
        const SizedBox(width: 20),
        // Switch Camera
        _buildControlButton(
          icon: Icons.flip_camera_ios,
          isActive: true,
          onTap: () {
            widget.onSwitchCamera?.call();
            setState(() {
              _isFrontCamera = !_isFrontCamera;
            });
          },
        ),
        const SizedBox(width: 20),
        // End Call
        GestureDetector(
          onTap: widget.onEnd,
          child: Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.call_end,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
          size: 24,
        ),
      ),
    );
  }
}

/// Incoming Call Notification Widget
class IncomingCallNotification extends StatelessWidget {
  final VideoCall call;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const IncomingCallNotification({
    super.key,
    required this.call,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: call.callerPhotoUrl != null
                ? NetworkImage(call.callerPhotoUrl!)
                : null,
            backgroundColor: AppColors.backgroundDark,
            child: call.callerPhotoUrl == null
                ? const Icon(Icons.person, color: AppColors.textTertiary)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  call.callerName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Incoming video call...',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDecline,
            icon: const Icon(Icons.call_end, color: Colors.red),
            style: IconButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.2),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onAccept,
            icon: const Icon(Icons.videocam, color: Colors.green),
            style: IconButton.styleFrom(
              backgroundColor: Colors.green.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }
}
