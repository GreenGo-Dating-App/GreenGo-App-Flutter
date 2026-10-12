import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/platform/voice_recording_format.dart';
import 'package:greengo_chat/core/platform/web_media.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:record/record.dart';

/// Storage rules (`isChatAudio`) accept only these bare audio subtypes and
/// match the whole contentType string, so `;codecs=` must never leak through.
final _chatAudio = RegExp(
    r'^audio/(mp4|m4a|x-m4a|aac|mpeg|mp3|ogg|opus|webm|wav|x-wav|wave|3gpp|amr)$');

void main() {
  group('WebMedia.voiceContentType / voiceExtension', () {
    test('mobile recording (no mime) keeps audio/mp4 + .m4a', () {
      final f = XFile('/tmp/voice_1.m4a');
      expect(WebMedia.voiceContentType(f), 'audio/mp4');
      expect(WebMedia.voiceExtension(f), 'm4a');
    });

    test('codec parameters are stripped so storage rules match', () {
      final f = XFile('blob:x', mimeType: 'audio/webm; codecs=opus');
      expect(WebMedia.voiceContentType(f), 'audio/webm');
      expect(WebMedia.voiceExtension(f), 'webm');
      expect(_chatAudio.hasMatch(WebMedia.voiceContentType(f)), isTrue);
    });

    test('wav and mp4 map to their extensions', () {
      expect(WebMedia.voiceExtension(XFile('blob:x', mimeType: 'audio/wav')),
          'wav');
      expect(WebMedia.voiceExtension(XFile('blob:x', mimeType: 'audio/mp4')),
          'm4a');
    });
  });

  group('VoiceRecordingFormat', () {
    test('mobile format is AAC-LC .m4a, allowed by storage rules', () {
      const f = VoiceRecordingFormat.aacM4a;
      expect(f.encoder, AudioEncoder.aacLc);
      expect(f.extension, 'm4a');
      expect(_chatAudio.hasMatch(f.contentType), isTrue);
    });
  });

  test('WebMedia.videoExtension uses the path extension off-web', () {
    expect(WebMedia.videoExtension(XFile('/data/x/clip.mov')), 'mov');
  });
}
