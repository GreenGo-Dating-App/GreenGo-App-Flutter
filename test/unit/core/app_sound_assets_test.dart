import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/app_sound_service.dart';

/// Every sound the app can play must ship (a missing asset fails silently at
/// runtime), and the push sound / channel ids must match the server.
void main() {
  test('every AppSound has its asset file', () {
    final missing = AppSound.values
        .where((s) => !File('assets/${s.assetPath}').existsSync())
        .map((s) => '${s.name} -> ${s.assetPath}')
        .toList();
    expect(missing, isEmpty);
  });

  test('the push sound ships on Android and iOS', () {
    expect(File('android/app/src/main/res/raw/greengo_push.mp3').existsSync(), isTrue);
    expect(File('android/app/src/main/res/raw/keep.xml').readAsStringSync(),
        contains('@raw/greengo_push'));
    expect(File('ios/Runner/greengo_push.wav').existsSync(), isTrue);
    expect(File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync(),
        contains('greengo_push.wav in Resources'));
  });

  test('server push channels / sounds match the app', () {
    final server = File('functions/src/notifications/pushSound.ts').readAsStringSync();
    final client = File('lib/core/services/push_notification_service.dart').readAsStringSync();
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    for (final id in ['greengo_push_v2', 'greengo_broadcasts_v2']) {
      expect(server, contains("'$id'"));
      expect(client, contains("'$id'"));
    }
    expect(server, contains("PUSH_SOUND_ANDROID = 'greengo_push'"));
    expect(server, contains("PUSH_SOUND_IOS = 'greengo_push.wav'"));
    expect(manifest, contains('android:value="greengo_push_v2"'));
  });
}
