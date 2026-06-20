import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../generated/app_localizations.dart';

/// WhatsApp-style send / voice-record button used by both 1:1 and group chats.
///
/// Behaviour:
/// * When the text field has content it shows a **send (airplane)** icon and a
///   tap dispatches [onSendText].
/// * When the text field is empty it shows a **microphone** icon. Long-pressing
///   starts a voice recording; releasing stops it and — if the clip is at least
///   [minDuration] (1 second) — invokes [onSendVoice] with the recorded file and
///   its duration. Sliding left past the cancel threshold while pressing
///   discards the recording.
///
/// Recording/upload follows the existing `record` + `m4a` pattern already used
/// by the profile voice intro, so playback works through `VoiceMessageWidget`.
class VoiceRecordSendButton extends StatefulWidget {
  const VoiceRecordSendButton({
    super.key,
    required this.controller,
    required this.onSendText,
    required this.onSendVoice,
    this.isSending = false,
    this.buttonColor,
    this.iconColor,
    this.radius = 24,
    this.minDuration = const Duration(seconds: 1),
  });

  final TextEditingController controller;
  final VoidCallback onSendText;
  final void Function(File file, Duration duration) onSendVoice;
  final bool isSending;
  final Color? buttonColor;
  final Color? iconColor;
  final double radius;
  final Duration minDuration;

  @override
  State<VoiceRecordSendButton> createState() => _VoiceRecordSendButtonState();
}

class _VoiceRecordSendButtonState extends State<VoiceRecordSendButton> {
  final AudioRecorder _recorder = AudioRecorder();

  bool _hasText = false;
  bool _isRecording = false;
  bool _cancelZone = false;
  DateTime? _startedAt;
  String? _path;
  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  OverlayEntry? _hud;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.trim().isNotEmpty;
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _ticker?.cancel();
    _removeHud();
    _recorder.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final has = widget.controller.text.trim().isNotEmpty;
    if (has != _hasText && mounted) setState(() => _hasText = has);
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _start() async {
    if (_isRecording) return;
    final l10n = AppLocalizations.of(context);
    if (!await _recorder.hasPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.voiceMicrophonePermissionRequired ??
                'Microphone permission is required'),
          ),
        );
      }
      return;
    }
    final dir = await getTemporaryDirectory();
    _path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: _path!,
    );
    _startedAt = DateTime.now();
    _cancelZone = false;
    _elapsed = Duration.zero;
    await HapticFeedback.mediumImpact();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (_startedAt == null) return;
      _elapsed = DateTime.now().difference(_startedAt!);
      _hud?.markNeedsBuild();
    });
    if (mounted) setState(() => _isRecording = true);
    _showHud();
  }

  Future<void> _stop({required bool cancel}) async {
    if (!_isRecording) return;
    _ticker?.cancel();
    _ticker = null;
    final elapsed =
        _startedAt == null ? Duration.zero : DateTime.now().difference(_startedAt!);
    _startedAt = null;
    String? path;
    try {
      path = await _recorder.stop();
    } catch (_) {}
    _removeHud();
    if (mounted) setState(() => _isRecording = false);

    final shouldCancel = cancel || _cancelZone;
    if (shouldCancel || path == null) {
      _deleteFile(path ?? _path);
      return;
    }
    if (elapsed < widget.minDuration) {
      _deleteFile(path);
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.voiceMessageTooShort ??
                'Hold to record, release to send'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
      return;
    }
    widget.onSendVoice(File(path), elapsed);
  }

  void _deleteFile(String? path) {
    if (path == null) return;
    try {
      final f = File(path);
      if (f.existsSync()) f.deleteSync();
    } catch (_) {}
  }

  void _showHud() {
    final overlay = Overlay.of(context);
    _hud = OverlayEntry(
      builder: (_) {
        final cs = Theme.of(context).colorScheme;
        final l10n = AppLocalizations.of(context);
        return Positioned(
          left: 12,
          right: 12,
          bottom: 80,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 8),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.mic, color: _cancelZone ? Colors.grey : Colors.red),
                  const SizedBox(width: 10),
                  Text(_fmt(_elapsed),
                      style: const TextStyle(fontFeatures: [])),
                  const Spacer(),
                  Text(
                    _cancelZone
                        ? (l10n?.voiceReleaseToCancel ?? 'Release to cancel')
                        : (l10n?.voiceSlideToCancel ?? '‹ Slide to cancel'),
                    style: TextStyle(
                      color: _cancelZone ? Colors.red : Colors.grey,
                      fontWeight:
                          _cancelZone ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(_hud!);
  }

  void _removeHud() {
    _hud?.remove();
    _hud = null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = widget.buttonColor ?? cs.primary;
    final fg = widget.iconColor ?? cs.onPrimary;

    if (widget.isSending) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: bg,
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(color: fg, strokeWidth: 2),
        ),
      );
    }

    if (_hasText) {
      return GestureDetector(
        onTap: widget.onSendText,
        child: CircleAvatar(
          radius: widget.radius,
          backgroundColor: bg,
          child: Icon(Icons.send, color: fg, size: 20),
        ),
      );
    }

    // Empty text → microphone, long-press to record.
    return GestureDetector(
      onLongPressStart: (_) => _start(),
      onLongPressEnd: (_) => _stop(cancel: false),
      onLongPressCancel: () => _stop(cancel: true),
      onLongPressMoveUpdate: (details) {
        final inCancel = details.localOffsetFromOrigin.dx < -80;
        if (inCancel != _cancelZone) {
          _cancelZone = inCancel;
          _hud?.markNeedsBuild();
        }
      },
      child: CircleAvatar(
        radius: widget.radius,
        backgroundColor: _isRecording ? Colors.red : bg,
        child: Icon(Icons.mic, color: fg, size: 20),
      ),
    );
  }
}
