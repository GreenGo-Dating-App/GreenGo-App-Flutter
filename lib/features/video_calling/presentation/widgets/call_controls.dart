import 'package:flutter/material.dart';

/// Call Controls Widget - Bottom control bar for video calls
class CallControls extends StatelessWidget {
  final bool isAudioMuted;
  final bool isVideoMuted;
  final bool isSpeakerOn;
  final bool isFrontCamera;
  final VoidCallback onToggleAudio;
  final VoidCallback onToggleVideo;
  final VoidCallback onSwitchCamera;
  final VoidCallback onToggleSpeaker;
  final VoidCallback onEndCall;

  const CallControls({
    super.key,
    required this.isAudioMuted,
    required this.isVideoMuted,
    required this.isSpeakerOn,
    required this.isFrontCamera,
    required this.onToggleAudio,
    required this.onToggleVideo,
    required this.onSwitchCamera,
    required this.onToggleSpeaker,
    required this.onEndCall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black87,
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute/Unmute Audio
          _buildControlButton(
            onPressed: onToggleAudio,
            icon: isAudioMuted ? Icons.mic_off : Icons.mic,
            backgroundColor: isAudioMuted ? Colors.red : Colors.white24,
            iconColor: Colors.white,
            label: isAudioMuted ? 'Unmute' : 'Mute',
          ),
          // Toggle Video
          _buildControlButton(
            onPressed: onToggleVideo,
            icon: isVideoMuted ? Icons.videocam_off : Icons.videocam,
            backgroundColor: isVideoMuted ? Colors.red : Colors.white24,
            iconColor: Colors.white,
            label: isVideoMuted ? 'Start Video' : 'Stop Video',
          ),
          // End Call (center, larger)
          _buildEndCallButton(),
          // Switch Camera
          _buildControlButton(
            onPressed: onSwitchCamera,
            icon: Icons.cameraswitch,
            backgroundColor: Colors.white24,
            iconColor: Colors.white,
            label: 'Flip',
          ),
          // Toggle Speaker
          _buildControlButton(
            onPressed: onToggleSpeaker,
            icon: isSpeakerOn ? Icons.volume_up : Icons.volume_down,
            backgroundColor: isSpeakerOn ? Colors.green : Colors.white24,
            iconColor: Colors.white,
            label: isSpeakerOn ? 'Speaker' : 'Earpiece',
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required VoidCallback onPressed,
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon, color: iconColor, size: 24),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildEndCallButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.4),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: IconButton(
            onPressed: onEndCall,
            icon: const Icon(Icons.call_end, color: Colors.white, size: 32),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'End',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
