import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// The audio format a voice recording is made in, plus where to record it.
///
/// Mobile always records AAC-LC into a `.m4a` temp file (unchanged behaviour).
///
/// Web has no temp directory (`getTemporaryDirectory` is not implemented) and
/// the `record` plugin ignores the path and returns a `blob:` URL from
/// `stop()`. Browsers also differ in what MediaRecorder can encode: Safari
/// (and recent Chrome) can record AAC in MP4, Firefox only Opus/WebM. So on
/// web the first supported of AAC -> Opus -> WAV is chosen; all three content
/// types are on the storage rules' `isChatAudio` / `validUpload` allow-lists.
class VoiceRecordingFormat {
  const VoiceRecordingFormat._(this.encoder, this.contentType, this.extension);

  /// The mobile format: AAC-LC in an MP4 (`.m4a`) container.
  static const VoiceRecordingFormat aacM4a =
      VoiceRecordingFormat._(AudioEncoder.aacLc, 'audio/mp4', 'm4a');
  static const VoiceRecordingFormat _opusWebm =
      VoiceRecordingFormat._(AudioEncoder.opus, 'audio/webm', 'webm');
  static const VoiceRecordingFormat _wav =
      VoiceRecordingFormat._(AudioEncoder.wav, 'audio/wav', 'wav');

  final AudioEncoder encoder;

  /// Bare MIME type (never with `;codecs=`: storage rules match it whole).
  final String contentType;

  /// File extension without the dot.
  final String extension;

  /// The format [recorder] should use on this platform.
  static Future<VoiceRecordingFormat> pick(AudioRecorder recorder) async {
    if (!kIsWeb) return aacM4a;
    for (final f in const [aacM4a, _opusWebm]) {
      try {
        if (await recorder.isEncoderSupported(f.encoder)) return f;
      } catch (_) {}
    }
    return _wav; // the web recorder always supports WAV
  }

  /// The `path` to pass to `AudioRecorder.start`: a temp file named
  /// `<prefix>_<millis>.<extension>` on mobile, empty on web (ignored there).
  Future<String> recordingPath(String prefix) async {
    if (kIsWeb) return '';
    final dir = await getTemporaryDirectory();
    return '${dir.path}/${prefix}_${DateTime.now().millisecondsSinceEpoch}.$extension';
  }
}
